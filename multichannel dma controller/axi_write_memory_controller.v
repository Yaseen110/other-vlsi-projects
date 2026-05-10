`timescale 1ns/1ps
// =============================================================
// axi_write_memory_controller.v
// AXI4 write slave controller in front of simple byte RAM.
// Converts AXI AW/W/B channels into simple RAM write signals.
// Supports bursts: WLAST only on final beat from DMA.
// =============================================================
module axi_write_memory_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4
)(
    input  wire                      aclk,
    input  wire                      aresetn,

    input  wire [ID_WIDTH-1:0]       s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  wire [7:0]                s_axi_awlen,
    input  wire [2:0]                s_axi_awsize,
    input  wire [1:0]                s_axi_awburst,
    input  wire                      s_axi_awvalid,
    output reg                       s_axi_awready,

    input  wire [DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                      s_axi_wlast,
    input  wire                      s_axi_wvalid,
    output reg                       s_axi_wready,

    output reg  [ID_WIDTH-1:0]       s_axi_bid,
    output reg  [1:0]                s_axi_bresp,
    output reg                       s_axi_bvalid,
    input  wire                      s_axi_bready,

    output reg                       mem_en,
    output reg                       mem_we,
    output reg  [ADDR_WIDTH-1:0]     mem_addr,
    output reg  [DATA_WIDTH-1:0]     mem_wdata,
    output reg  [(DATA_WIDTH/8)-1:0] mem_wstrb,
    input  wire [DATA_WIDTH-1:0]     mem_rdata
);

localparam ST_IDLE      = 2'd0;
localparam ST_W         = 2'd1;
localparam ST_MEM_WRITE = 2'd2;
localparam ST_B         = 2'd3;

reg [1:0] state;
reg [ADDR_WIDTH-1:0] cur_addr;
reg [7:0] beats_left;
reg [ID_WIDTH-1:0] cur_id;

reg [ADDR_WIDTH-1:0] beat_addr;
reg [DATA_WIDTH-1:0] beat_data;
reg [(DATA_WIDTH/8)-1:0] beat_strb;
reg beat_last;

// Combinational outputs
always @(*) begin
    s_axi_awready = 1'b0;
    s_axi_wready  = 1'b0;
    s_axi_bvalid  = 1'b0;
    s_axi_bresp   = 2'b00;
    s_axi_bid     = cur_id;

    mem_en    = 1'b0;
    mem_we    = 1'b0;
    mem_addr  = beat_addr;
    mem_wdata = beat_data;
    mem_wstrb = beat_strb;

    case (state)
        ST_IDLE: begin
            s_axi_awready = 1'b1;
        end

        ST_W: begin
            s_axi_wready = 1'b1;
        end

        ST_MEM_WRITE: begin
            // Stable RAM write request for this full cycle.
            mem_en    = 1'b1;
            mem_we    = 1'b1;
            mem_addr  = beat_addr;
            mem_wdata = beat_data;
            mem_wstrb = beat_strb;
        end

        ST_B: begin
            s_axi_bvalid = 1'b1;
            s_axi_bresp  = 2'b00;
            s_axi_bid    = cur_id;
        end
    endcase
end

always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        state      <= ST_IDLE;
        cur_addr   <= {ADDR_WIDTH{1'b0}};
        beats_left <= 8'd0;
        cur_id     <= {ID_WIDTH{1'b0}};
        beat_addr  <= {ADDR_WIDTH{1'b0}};
        beat_data  <= {DATA_WIDTH{1'b0}};
        beat_strb  <= {(DATA_WIDTH/8){1'b0}};
        beat_last  <= 1'b0;
    end else begin
        case (state)
            ST_IDLE: begin
                if (s_axi_awvalid && s_axi_awready) begin
                    cur_addr   <= s_axi_awaddr;
                    beats_left <= s_axi_awlen + 1'b1;
                    cur_id     <= s_axi_awid;
                    state      <= ST_W;
                end
            end

            ST_W: begin
                if (s_axi_wvalid && s_axi_wready) begin
                    beat_addr <= cur_addr;
                    beat_data <= s_axi_wdata;
                    beat_strb <= s_axi_wstrb;
                    beat_last <= s_axi_wlast || (beats_left == 8'd1);

                    cur_addr   <= cur_addr + 32'd4; // next 32-bit word byte address
                    beats_left <= beats_left - 1'b1;
                    state      <= ST_MEM_WRITE;
                end
            end

            ST_MEM_WRITE: begin
                // RAM writes during this state.
                if (beat_last)
                    state <= ST_B;
                else
                    state <= ST_W;
            end

            ST_B: begin
                if (s_axi_bready)
                    state <= ST_IDLE;
            end

            default: begin
                state <= ST_IDLE;
            end
        endcase
    end
end

endmodule
