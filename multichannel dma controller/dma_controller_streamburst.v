`timescale 1ns/1ps
// =============================================================
// dma_controller_streamburst.v
// Single-channel AXI DMA.
// AXI4-Lite slave: CPU config/status.
// AXI4 read master: source memory subsystem.
// AXI4 write master: destination memory subsystem.
//
// Stream-burst behavior:
//   - Write side starts as soon as FIFO has one word.
//   - AW burst length is chosen from remaining transfer length.
//   - If FIFO becomes empty during a burst, WVALID pauses.
//   - WLAST is asserted only on the final beat of the declared burst.
//
// Assumptions:
//   - 32-bit data width.
//   - Addresses and length are 4-byte aligned.
// =============================================================
module dma_controller_streamburst #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4,
    parameter BURST_LEN  = 16,
    parameter FIFO_DEPTH = 32
)(
    input  wire                   aclk,
    input  wire                   aresetn,

    // AXI4-Lite slave
    input  wire [5:0]             s_axil_awaddr,
    input  wire                   s_axil_awvalid,
    output reg                    s_axil_awready,
    input  wire [DATA_WIDTH-1:0]  s_axil_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axil_wstrb,
    input  wire                   s_axil_wvalid,
    output reg                    s_axil_wready,
    output reg  [1:0]             s_axil_bresp,
    output reg                    s_axil_bvalid,
    input  wire                   s_axil_bready,

    input  wire [5:0]             s_axil_araddr,
    input  wire                   s_axil_arvalid,
    output reg                    s_axil_arready,
    output reg  [DATA_WIDTH-1:0]  s_axil_rdata,
    output reg  [1:0]             s_axil_rresp,
    output reg                    s_axil_rvalid,
    input  wire                   s_axil_rready,

    // AXI4 read master
    output reg  [ID_WIDTH-1:0]    m_src_arid,
    output reg  [ADDR_WIDTH-1:0]  m_src_araddr,
    output reg  [7:0]             m_src_arlen,
    output reg  [2:0]             m_src_arsize,
    output reg  [1:0]             m_src_arburst,
    output reg                    m_src_arvalid,
    input  wire                   m_src_arready,
    input  wire [ID_WIDTH-1:0]    m_src_rid,
    input  wire [DATA_WIDTH-1:0]  m_src_rdata,
    input  wire [1:0]             m_src_rresp,
    input  wire                   m_src_rlast,
    input  wire                   m_src_rvalid,
    output reg                    m_src_rready,

    // AXI4 write master
    output reg  [ID_WIDTH-1:0]    m_dst_awid,
    output reg  [ADDR_WIDTH-1:0]  m_dst_awaddr,
    output reg  [7:0]             m_dst_awlen,
    output reg  [2:0]             m_dst_awsize,
    output reg  [1:0]             m_dst_awburst,
    output reg                    m_dst_awvalid,
    input  wire                   m_dst_awready,
    output reg  [DATA_WIDTH-1:0]  m_dst_wdata,
    output reg  [(DATA_WIDTH/8)-1:0] m_dst_wstrb,
    output reg                    m_dst_wlast,
    output reg                    m_dst_wvalid,
    input  wire                   m_dst_wready,
    input  wire [ID_WIDTH-1:0]    m_dst_bid,
    input  wire [1:0]             m_dst_bresp,
    input  wire                   m_dst_bvalid,
    output reg                    m_dst_bready,

    output reg                    irq
);

localparam REG_SRC  = 4'h0;
localparam REG_DST  = 4'h1;
localparam REG_LEN  = 4'h2;
localparam REG_CTRL = 4'h3;
localparam REG_STAT = 4'h4;

localparam RD_IDLE = 2'd0;
localparam RD_AR   = 2'd1;
localparam RD_R    = 2'd2;

localparam WR_IDLE = 3'd0;
localparam WR_WAIT = 3'd1;
localparam WR_AW   = 3'd2;
localparam WR_W    = 3'd3;
localparam WR_B    = 3'd4;
localparam WR_DONE = 3'd5;

reg [31:0] reg_src;
reg [31:0] reg_dst;
reg [31:0] reg_len;
reg        reg_irq_en;
reg        start_req;
reg        reg_busy;
reg        reg_done;
reg        reg_err;

// =============================================================
// AXI4-Lite write, safe AW/W independent capture
// =============================================================
reg        aw_captured;
reg        w_captured;
reg [5:0]  awaddr_latched;
reg [31:0] wdata_latched;
reg [3:0]  wstrb_latched;

wire axil_write_commit = aw_captured && w_captured && !s_axil_bvalid;
wire start_pulse = start_req && !reg_busy;

always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        s_axil_awready <= 1'b0;
        s_axil_wready  <= 1'b0;
        s_axil_bvalid  <= 1'b0;
        s_axil_bresp   <= 2'b00;
        aw_captured    <= 1'b0;
        w_captured     <= 1'b0;
        awaddr_latched <= 6'd0;
        wdata_latched  <= 32'd0;
        wstrb_latched  <= 4'd0;
        reg_src        <= 32'd0;
        reg_dst        <= 32'd0;
        reg_len        <= 32'd0;
        reg_irq_en     <= 1'b0;
        start_req      <= 1'b0;
    end else begin
        s_axil_awready <= 1'b0;
        s_axil_wready  <= 1'b0;

        if (!aw_captured && !s_axil_bvalid && s_axil_awvalid) begin
            aw_captured    <= 1'b1;
            awaddr_latched <= s_axil_awaddr;
            s_axil_awready <= 1'b1;
        end

        if (!w_captured && !s_axil_bvalid && s_axil_wvalid) begin
            w_captured    <= 1'b1;
            wdata_latched <= s_axil_wdata;
            wstrb_latched <= s_axil_wstrb;
            s_axil_wready <= 1'b1;
        end

        if (axil_write_commit) begin
            case (awaddr_latched[5:2])
                REG_SRC:  if (!reg_busy) reg_src <= wdata_latched;
                REG_DST:  if (!reg_busy) reg_dst <= wdata_latched;
                REG_LEN:  if (!reg_busy) reg_len <= wdata_latched;
                REG_CTRL: begin
                    reg_irq_en <= wdata_latched[1];
                    if (wdata_latched[0])
                        start_req <= 1'b1;
                end
                default: ;
            endcase

            aw_captured   <= 1'b0;
            w_captured    <= 1'b0;
            s_axil_bvalid <= 1'b1;
            s_axil_bresp  <= 2'b00;
        end else if (s_axil_bvalid && s_axil_bready) begin
            s_axil_bvalid <= 1'b0;
        end

        if (start_pulse)
            start_req <= 1'b0;
    end
end

// =============================================================
// AXI4-Lite read
// =============================================================
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        s_axil_arready <= 1'b0;
        s_axil_rvalid  <= 1'b0;
        s_axil_rresp   <= 2'b00;
        s_axil_rdata   <= 32'd0;
    end else begin
        s_axil_arready <= 1'b0;

        if (!s_axil_rvalid && s_axil_arvalid) begin
            s_axil_arready <= 1'b1;
            s_axil_rvalid  <= 1'b1;
            s_axil_rresp   <= 2'b00;
            case (s_axil_araddr[5:2])
                REG_SRC:  s_axil_rdata <= reg_src;
                REG_DST:  s_axil_rdata <= reg_dst;
                REG_LEN:  s_axil_rdata <= reg_len;
                REG_CTRL: s_axil_rdata <= {30'd0, reg_irq_en, 1'b0};
                REG_STAT: s_axil_rdata <= {29'd0, reg_err, reg_done, reg_busy};
                default:  s_axil_rdata <= 32'hDEAD_BEEF;
            endcase
        end else if (s_axil_rvalid && s_axil_rready) begin
            s_axil_rvalid <= 1'b0;
        end
    end
end

// =============================================================
// FIFO
// =============================================================
reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
reg [$clog2(FIFO_DEPTH):0] fifo_wptr;
reg [$clog2(FIFO_DEPTH):0] fifo_rptr;

wire fifo_empty = (fifo_wptr == fifo_rptr);
wire fifo_full  = (fifo_wptr[$clog2(FIFO_DEPTH)] != fifo_rptr[$clog2(FIFO_DEPTH)]) &&
                  (fifo_wptr[$clog2(FIFO_DEPTH)-1:0] == fifo_rptr[$clog2(FIFO_DEPTH)-1:0]);
wire [$clog2(FIFO_DEPTH):0] fifo_level = fifo_wptr - fifo_rptr;

reg [1:0] rd_state;
reg [2:0] wr_state;

reg [31:0] rd_addr;
reg [31:0] wr_addr;
reg [31:0] rd_beats_left;
reg [31:0] wr_beats_left;
reg [7:0]  rd_burst_beats;
reg [7:0]  wr_burst_beats;
reg [7:0]  wr_burst_left;

wire aligned_ok = (reg_src[1:0] == 2'b00) && (reg_dst[1:0] == 2'b00) && (reg_len[1:0] == 2'b00);
wire len_nonzero = (reg_len != 32'd0);
wire [31:0] total_beats = reg_len >> 2;
wire write_can_start = (wr_beats_left != 32'd0) && !fifo_empty;

function [7:0] min_burst;
    input [31:0] beats_left;
    begin
        if (beats_left >= BURST_LEN)
            min_burst = BURST_LEN[7:0];
        else
            min_burst = beats_left[7:0];
    end
endfunction

// =============================================================
// DMA FSMs and AXI master ports
// =============================================================
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        rd_state       <= RD_IDLE;
        wr_state       <= WR_IDLE;
        reg_busy       <= 1'b0;
        reg_done       <= 1'b0;
        reg_err        <= 1'b0;
        irq            <= 1'b0;

        rd_addr        <= 32'd0;
        wr_addr        <= 32'd0;
        rd_beats_left  <= 32'd0;
        wr_beats_left  <= 32'd0;
        rd_burst_beats <= 8'd0;
        wr_burst_beats <= 8'd0;
        wr_burst_left  <= 8'd0;

        fifo_wptr      <= 0;
        fifo_rptr      <= 0;

        m_src_arid     <= 0;
        m_src_araddr   <= 0;
        m_src_arlen    <= 0;
        m_src_arsize   <= 3'd2; // 4 bytes per beat
        m_src_arburst  <= 2'b01;
        m_src_arvalid  <= 1'b0;
        m_src_rready   <= 1'b0;

        m_dst_awid     <= {ID_WIDTH{1'b1}};
        m_dst_awaddr   <= 0;
        m_dst_awlen    <= 0;
        m_dst_awsize   <= 3'd2; // 4 bytes per beat
        m_dst_awburst  <= 2'b01;
        m_dst_awvalid  <= 1'b0;
        m_dst_wdata    <= 0;
        m_dst_wstrb    <= 4'hF;
        m_dst_wlast    <= 1'b0;
        m_dst_wvalid   <= 1'b0;
        m_dst_bready   <= 1'b1;
    end else begin
        irq <= 1'b0;

        if (start_pulse) begin
            fifo_wptr     <= 0;
            fifo_rptr     <= 0;
            reg_done      <= 1'b0;
            reg_err       <= 1'b0;
            m_src_arvalid <= 1'b0;
            m_src_rready  <= 1'b0;
            m_dst_awvalid <= 1'b0;
            m_dst_wvalid  <= 1'b0;
            m_dst_wlast   <= 1'b0;

            if (!aligned_ok || !len_nonzero) begin
                reg_busy <= 1'b0;
                reg_done <= 1'b1;
                reg_err  <= 1'b1;
                if (reg_irq_en)
                    irq <= 1'b1;
            end else begin
                reg_busy      <= 1'b1;
                rd_addr       <= reg_src;
                wr_addr       <= reg_dst;
                rd_beats_left <= total_beats;
                wr_beats_left <= total_beats;
                rd_state      <= RD_AR;
                wr_state      <= WR_WAIT;
            end
        end

        // ---------------- READ FSM ----------------
        case (rd_state)
            RD_IDLE: begin
            end

            RD_AR: begin
                if (!m_src_arvalid) begin
                    rd_burst_beats <= min_burst(rd_beats_left);
                    m_src_arid     <= {ID_WIDTH{1'b0}};
                    m_src_araddr   <= rd_addr;
                    m_src_arlen    <= min_burst(rd_beats_left) - 1'b1;
                    m_src_arsize   <= 3'd2;
                    m_src_arburst  <= 2'b01;
                    m_src_arvalid  <= 1'b1;
                end

                if (m_src_arvalid && m_src_arready) begin
                    m_src_arvalid <= 1'b0;
                    m_src_rready  <= !fifo_full;
                    rd_state      <= RD_R;
                end
            end

            RD_R: begin
                m_src_rready <= !fifo_full;
                if (m_src_rvalid && m_src_rready && !fifo_full) begin
                    fifo_mem[fifo_wptr[$clog2(FIFO_DEPTH)-1:0]] <= m_src_rdata;
                    fifo_wptr <= fifo_wptr + 1'b1;

                    if (m_src_rresp != 2'b00)
                        reg_err <= 1'b1;

                    rd_addr       <= rd_addr + 32'd4;
                    rd_beats_left <= rd_beats_left - 1'b1;

                    if (m_src_rlast) begin
                        m_src_rready <= 1'b0;
                        if (rd_beats_left == 32'd1)
                            rd_state <= RD_IDLE;
                        else
                            rd_state <= RD_AR;
                    end
                end
            end
        endcase

        // ---------------- WRITE FSM ----------------
        case (wr_state)
            WR_IDLE: begin
            end

            WR_WAIT: begin
                if (write_can_start) begin
                    wr_burst_beats <= min_burst(wr_beats_left);
                    wr_burst_left  <= min_burst(wr_beats_left);
                    wr_state       <= WR_AW;
                end
            end

            WR_AW: begin
                if (!m_dst_awvalid) begin
                    m_dst_awid    <= {ID_WIDTH{1'b1}};
                    m_dst_awaddr  <= wr_addr;
                    m_dst_awlen   <= wr_burst_beats - 1'b1;
                    m_dst_awsize  <= 3'd2;
                    m_dst_awburst <= 2'b01;
                    m_dst_awvalid <= 1'b1;
                end

                if (m_dst_awvalid && m_dst_awready) begin
                    m_dst_awvalid <= 1'b0;
                    wr_state      <= WR_W;
                end
            end

            WR_W: begin
                // If W channel empty and FIFO has data, send next beat.
                // If FIFO empty, WVALID stays 0 and burst pauses safely.
                if (!m_dst_wvalid && !fifo_empty && wr_burst_left != 8'd0) begin
                    m_dst_wdata  <= fifo_mem[fifo_rptr[$clog2(FIFO_DEPTH)-1:0]];
                    m_dst_wstrb  <= 4'hF;
                    m_dst_wlast  <= (wr_burst_left == 8'd1);
                    m_dst_wvalid <= 1'b1;
                end

                if (m_dst_wvalid && m_dst_wready) begin
                    fifo_rptr     <= fifo_rptr + 1'b1;
                    wr_addr       <= wr_addr + 32'd4;
                    wr_beats_left <= wr_beats_left - 1'b1;
                    wr_burst_left <= wr_burst_left - 1'b1;
                    m_dst_wvalid  <= 1'b0;

                    if (m_dst_wlast) begin
                        m_dst_wlast <= 1'b0;
                        wr_state    <= WR_B;
                    end else begin
                        m_dst_wlast <= 1'b0;
                    end
                end
            end

            WR_B: begin
                if (m_dst_bvalid && m_dst_bready) begin
                    if (m_dst_bresp != 2'b00)
                        reg_err <= 1'b1;

                    if (wr_beats_left == 32'd0)
                        wr_state <= WR_DONE;
                    else
                        wr_state <= WR_WAIT;
                end
            end

            WR_DONE: begin
                reg_busy <= 1'b0;
                reg_done <= 1'b1;
                if (reg_irq_en)
                    irq <= 1'b1;
                wr_state <= WR_IDLE;
                rd_state <= RD_IDLE;
            end

            default: begin
                wr_state <= WR_IDLE;
            end
        endcase
    end
end

endmodule
