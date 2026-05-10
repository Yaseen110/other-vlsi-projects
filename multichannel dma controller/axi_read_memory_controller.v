`timescale 1ns/1ps
// =============================================================
// axi_read_memory_controller.v
// AXI4 read slave controller in front of simple byte RAM.
// Converts AXI AR/R channel into simple RAM read signals.
// Correctly handles synchronous RAM one-cycle read latency.
// =============================================================
module axi_read_memory_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4
)(
    input  wire                     aclk,
    input  wire                     aresetn,

    input  wire [ID_WIDTH-1:0]      s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire [7:0]               s_axi_arlen,
    input  wire [2:0]               s_axi_arsize,
    input  wire [1:0]               s_axi_arburst,
    input  wire                     s_axi_arvalid,
    output reg                      s_axi_arready,

    output reg  [ID_WIDTH-1:0]      s_axi_rid,
    output reg  [DATA_WIDTH-1:0]    s_axi_rdata,
    output reg  [1:0]               s_axi_rresp,
    output reg                      s_axi_rlast,
    output reg                      s_axi_rvalid,
    input  wire                     s_axi_rready,

    output reg                      mem_en,
    output reg                      mem_we,
    output reg  [ADDR_WIDTH-1:0]    mem_addr,
    output reg  [DATA_WIDTH-1:0]    mem_wdata,
    output reg  [(DATA_WIDTH/8)-1:0] mem_wstrb,
    input  wire [DATA_WIDTH-1:0]    mem_rdata
);

localparam ST_IDLE    = 2'd0;
localparam ST_MEM_REQ = 2'd1;
localparam ST_RDATA   = 2'd2;

reg [1:0] state;
reg [ADDR_WIDTH-1:0] cur_addr;
reg [7:0] beats_left;
reg [ID_WIDTH-1:0] cur_id;

// Combinational outputs
always @(*) begin
    s_axi_arready = 1'b0;
    s_axi_rvalid  = 1'b0;
    s_axi_rid     = cur_id;
    s_axi_rdata   = mem_rdata;
    s_axi_rresp   = 2'b00;
    s_axi_rlast   = (beats_left == 8'd1);

    mem_en    = 1'b0;
    mem_we    = 1'b0;
    mem_addr  = cur_addr;
    mem_wdata = {DATA_WIDTH{1'b0}};
    mem_wstrb = {(DATA_WIDTH/8){1'b0}};

    case (state)
        ST_IDLE: begin
            s_axi_arready = 1'b1;
        end

        ST_MEM_REQ: begin
            // Present stable RAM read request for this full cycle.
            mem_en   = 1'b1;
            mem_we   = 1'b0;
            mem_addr = cur_addr;
        end

        ST_RDATA: begin
            // RAM data is now valid because RAM was requested in previous state.
            s_axi_rvalid = 1'b1;
            s_axi_rdata  = mem_rdata;
        end
    endcase
end

always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        state      <= ST_IDLE;
        cur_addr   <= {ADDR_WIDTH{1'b0}};
        beats_left <= 8'd0;
        cur_id     <= {ID_WIDTH{1'b0}};
    end else begin
        case (state)
            ST_IDLE: begin
                if (s_axi_arvalid && s_axi_arready) begin
                    cur_addr   <= s_axi_araddr;
                    beats_left <= s_axi_arlen + 1'b1;
                    cur_id     <= s_axi_arid;
                    state      <= ST_MEM_REQ;
                end
            end

            ST_MEM_REQ: begin
                // RAM samples mem_addr in this cycle. Next cycle mem_rdata is valid.
                state <= ST_RDATA;
            end

            ST_RDATA: begin
                if (s_axi_rvalid && s_axi_rready) begin
                    if (beats_left == 8'd1) begin
                        state <= ST_IDLE;
                    end else begin
                        cur_addr   <= cur_addr + 32'd4; // next 32-bit word byte address
                        beats_left <= beats_left - 1'b1;
                        state      <= ST_MEM_REQ;
                    end
                end
            end

            default: begin
                state <= ST_IDLE;
            end
        endcase
    end
end

endmodule
