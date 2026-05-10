`timescale 1ns/1ps
// =============================================================
// tb_cpu_only_dma_streamburst.v
// CPU-only testbench.
// Memory is byte-addressable RAM behind AXI controllers.
// =============================================================
module tb_cpu_only_dma_streamburst;

localparam ADDR_WIDTH = 32;
localparam DATA_WIDTH = 32;
localparam ID_WIDTH   = 4;
localparam BURST_LEN  = 16;
localparam FIFO_DEPTH = 32;
localparam MEM_BYTES  = 4096;
localparam CLK_HALF   = 5;

localparam REG_SRC  = 6'h00;
localparam REG_DST  = 6'h04;
localparam REG_LEN  = 6'h08;
localparam REG_CTRL = 6'h0C;
localparam REG_STAT = 6'h10;

reg aclk = 0;
reg aresetn = 0;
always #CLK_HALF aclk = ~aclk;

// CPU AXI4-Lite
reg  [5:0]  s_axil_awaddr  = 0;
reg         s_axil_awvalid = 0;
wire        s_axil_awready;
reg  [31:0] s_axil_wdata   = 0;
reg  [3:0]  s_axil_wstrb   = 4'hF;
reg         s_axil_wvalid  = 0;
wire        s_axil_wready;
wire [1:0]  s_axil_bresp;
wire        s_axil_bvalid;
reg         s_axil_bready  = 1;
reg  [5:0]  s_axil_araddr  = 0;
reg         s_axil_arvalid = 0;
wire        s_axil_arready;
wire [31:0] s_axil_rdata;
wire [1:0]  s_axil_rresp;
wire        s_axil_rvalid;
reg         s_axil_rready  = 1;

// Source AXI read wires
wire [ID_WIDTH-1:0]   src_arid;
wire [ADDR_WIDTH-1:0] src_araddr;
wire [7:0]            src_arlen;
wire [2:0]            src_arsize;
wire [1:0]            src_arburst;
wire                  src_arvalid;
wire                  src_arready;
wire [ID_WIDTH-1:0]   src_rid;
wire [DATA_WIDTH-1:0] src_rdata;
wire [1:0]            src_rresp;
wire                  src_rlast;
wire                  src_rvalid;
wire                  src_rready;

// Destination AXI write wires
wire [ID_WIDTH-1:0]   dst_awid;
wire [ADDR_WIDTH-1:0] dst_awaddr;
wire [7:0]            dst_awlen;
wire [2:0]            dst_awsize;
wire [1:0]            dst_awburst;
wire                  dst_awvalid;
wire                  dst_awready;
wire [DATA_WIDTH-1:0] dst_wdata;
wire [3:0]            dst_wstrb;
wire                  dst_wlast;
wire                  dst_wvalid;
wire                  dst_wready;
wire [ID_WIDTH-1:0]   dst_bid;
wire [1:0]            dst_bresp;
wire                  dst_bvalid;
wire                  dst_bready;

wire irq;
reg [31:0] stat;

// DUT
dma_controller_streamburst #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .ID_WIDTH(ID_WIDTH),
    .BURST_LEN(BURST_LEN),
    .FIFO_DEPTH(FIFO_DEPTH)
) dut (
    .aclk(aclk),
    .aresetn(aresetn),
    .s_axil_awaddr(s_axil_awaddr),
    .s_axil_awvalid(s_axil_awvalid),
    .s_axil_awready(s_axil_awready),
    .s_axil_wdata(s_axil_wdata),
    .s_axil_wstrb(s_axil_wstrb),
    .s_axil_wvalid(s_axil_wvalid),
    .s_axil_wready(s_axil_wready),
    .s_axil_bresp(s_axil_bresp),
    .s_axil_bvalid(s_axil_bvalid),
    .s_axil_bready(s_axil_bready),
    .s_axil_araddr(s_axil_araddr),
    .s_axil_arvalid(s_axil_arvalid),
    .s_axil_arready(s_axil_arready),
    .s_axil_rdata(s_axil_rdata),
    .s_axil_rresp(s_axil_rresp),
    .s_axil_rvalid(s_axil_rvalid),
    .s_axil_rready(s_axil_rready),
    .m_src_arid(src_arid),
    .m_src_araddr(src_araddr),
    .m_src_arlen(src_arlen),
    .m_src_arsize(src_arsize),
    .m_src_arburst(src_arburst),
    .m_src_arvalid(src_arvalid),
    .m_src_arready(src_arready),
    .m_src_rid(src_rid),
    .m_src_rdata(src_rdata),
    .m_src_rresp(src_rresp),
    .m_src_rlast(src_rlast),
    .m_src_rvalid(src_rvalid),
    .m_src_rready(src_rready),
    .m_dst_awid(dst_awid),
    .m_dst_awaddr(dst_awaddr),
    .m_dst_awlen(dst_awlen),
    .m_dst_awsize(dst_awsize),
    .m_dst_awburst(dst_awburst),
    .m_dst_awvalid(dst_awvalid),
    .m_dst_awready(dst_awready),
    .m_dst_wdata(dst_wdata),
    .m_dst_wstrb(dst_wstrb),
    .m_dst_wlast(dst_wlast),
    .m_dst_wvalid(dst_wvalid),
    .m_dst_wready(dst_wready),
    .m_dst_bid(dst_bid),
    .m_dst_bresp(dst_bresp),
    .m_dst_bvalid(dst_bvalid),
    .m_dst_bready(dst_bready),
    .irq(irq)
);

source_memory_subsystem #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .ID_WIDTH(ID_WIDTH),
    .MEM_BYTES(MEM_BYTES)
) src_subsys (
    .aclk(aclk),
    .aresetn(aresetn),
    .s_axi_arid(src_arid),
    .s_axi_araddr(src_araddr),
    .s_axi_arlen(src_arlen),
    .s_axi_arsize(src_arsize),
    .s_axi_arburst(src_arburst),
    .s_axi_arvalid(src_arvalid),
    .s_axi_arready(src_arready),
    .s_axi_rid(src_rid),
    .s_axi_rdata(src_rdata),
    .s_axi_rresp(src_rresp),
    .s_axi_rlast(src_rlast),
    .s_axi_rvalid(src_rvalid),
    .s_axi_rready(src_rready)
);

destination_memory_subsystem #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .ID_WIDTH(ID_WIDTH),
    .MEM_BYTES(MEM_BYTES)
) dst_subsys (
    .aclk(aclk),
    .aresetn(aresetn),
    .s_axi_awid(dst_awid),
    .s_axi_awaddr(dst_awaddr),
    .s_axi_awlen(dst_awlen),
    .s_axi_awsize(dst_awsize),
    .s_axi_awburst(dst_awburst),
    .s_axi_awvalid(dst_awvalid),
    .s_axi_awready(dst_awready),
    .s_axi_wdata(dst_wdata),
    .s_axi_wstrb(dst_wstrb),
    .s_axi_wlast(dst_wlast),
    .s_axi_wvalid(dst_wvalid),
    .s_axi_wready(dst_wready),
    .s_axi_bid(dst_bid),
    .s_axi_bresp(dst_bresp),
    .s_axi_bvalid(dst_bvalid),
    .s_axi_bready(dst_bready)
);

// CPU AXI-Lite write
task cpu_write;
    input [5:0] addr;
    input [31:0] data;
    begin
        @(posedge aclk);
        s_axil_awaddr  <= addr;
        s_axil_awvalid <= 1'b1;
        s_axil_wdata   <= data;
        s_axil_wstrb   <= 4'hF;
        s_axil_wvalid  <= 1'b1;

        while (s_axil_awvalid || s_axil_wvalid) begin
            @(posedge aclk);
            if (s_axil_awready) s_axil_awvalid <= 1'b0;
            if (s_axil_wready)  s_axil_wvalid  <= 1'b0;
        end

        while (!s_axil_bvalid) @(posedge aclk);
        @(posedge aclk);
    end
endtask

// CPU AXI-Lite read
task cpu_read;
    input  [5:0] addr;
    output [31:0] data;
    begin
        @(posedge aclk);
        s_axil_araddr  <= addr;
        s_axil_arvalid <= 1'b1;
        while (!s_axil_arready) @(posedge aclk);
        s_axil_arvalid <= 1'b0;
        while (!s_axil_rvalid) @(posedge aclk);
        data = s_axil_rdata;
        @(posedge aclk);
    end
endtask

task start_dma;
    input [31:0] src;
    input [31:0] dst;
    input [31:0] len;
    input irq_en;
    begin
        cpu_write(REG_SRC,  src);
        cpu_write(REG_DST,  dst);
        cpu_write(REG_LEN,  len);
        cpu_write(REG_CTRL, {30'd0, irq_en, 1'b1});
    end
endtask

task wait_irq;
    input integer max_cycles;
    integer cyc;
    begin
        cyc = 0;
        while (!irq && cyc < max_cycles) begin
            @(posedge aclk);
            cyc = cyc + 1;
        end
        if (cyc >= max_cycles) begin
            $display("[%0t] ERROR: IRQ timeout", $time);
            $finish;
        end
        $display("[%0t] IRQ received after %0d cycles", $time, cyc);
    end
endtask

task wait_poll;
    input integer max_cycles;
    integer cyc;
    begin
        cyc = 0;
        stat = 32'h1;
        while (stat[0] && cyc < max_cycles) begin
            cpu_read(REG_STAT, stat);
            repeat (5) @(posedge aclk);
            cyc = cyc + 5;
        end
        if (cyc >= max_cycles) begin
            $display("[%0t] ERROR: poll timeout", $time);
            $finish;
        end
        $display("[%0t] Poll done. STATUS=%08h", $time, stat);
    end
endtask

task check_bytes;
    input integer start_byte;
    input integer num_bytes;
    integer k;
    integer errors;
    begin
        errors = 0;
        for (k = 0; k < num_bytes; k = k + 1) begin
            if (src_subsys.ram.mem[start_byte+k] !== dst_subsys.ram.mem[start_byte+k]) begin
                if (errors < 8)
                    $display("MISMATCH byte[%0d]: src=%02h dst=%02h", start_byte+k,
                             src_subsys.ram.mem[start_byte+k], dst_subsys.ram.mem[start_byte+k]);
                errors = errors + 1;
            end
        end
        if (errors == 0)
            $display("[%0t] DATA CHECK PASS: %0d bytes", $time, num_bytes);
        else begin
            $display("[%0t] DATA CHECK FAIL: %0d byte errors", $time, errors);
            $finish;
        end
    end
endtask

initial begin
    $dumpfile("dma_streamburst_byteaddr.vcd");
    $dumpvars(0, tb_cpu_only_dma_streamburst);

    $display("====================================================");
    $display(" DMA stream-burst with byte-addressable RAM");
    $display("====================================================");

    aresetn = 1'b0;
    repeat (10) @(posedge aclk);
    aresetn = 1'b1;
    repeat (5) @(posedge aclk);

    $display("\nTEST 1: 32-byte transfer with IRQ");
    src_subsys.ram.init_pattern(0, 32, 8'hA0);
    dst_subsys.ram.clear_region(0, 32, 8'hAA);
    start_dma(32'h0000_0000, 32'h0000_0000, 32'd32, 1'b1);
    wait_irq(3000);
    check_bytes(0, 32);

    $display("\nTEST 2: 256-byte transfer with polling");
    src_subsys.ram.init_pattern(256, 256, 8'hB0);
    dst_subsys.ram.clear_region(256, 256, 8'h55);
    start_dma(32'h0000_0100, 32'h0000_0100, 32'd256, 1'b0);
    wait_poll(10000);
    check_bytes(256, 256);

    $display("\nTEST 3: invalid length, should set ERR");
    start_dma(32'h0000_0000, 32'h0000_0000, 32'd10, 1'b0);
    repeat (10) @(posedge aclk);
    cpu_read(REG_STAT, stat);
    if (stat[2])
        $display("[%0t] INVALID LENGTH PASS: STATUS=%08h", $time, stat);
    else begin
        $display("[%0t] INVALID LENGTH FAIL: STATUS=%08h", $time, stat);
        $finish;
    end

    $display("\n====================================================");
    $display(" ALL TESTS PASSED");
    $display("====================================================");
    repeat (20) @(posedge aclk);
    $finish;
end

always @(posedge aclk) begin
    if (src_arvalid && src_arready)
        $display("[%0t] SRC AR addr=%08h len=%0d", $time, src_araddr, src_arlen);
    if (src_rvalid && src_rready)
        $display("[%0t] SRC R  data=%08h last=%0d", $time, src_rdata, src_rlast);
    if (dst_awvalid && dst_awready)
        $display("[%0t] DST AW addr=%08h len=%0d", $time, dst_awaddr, dst_awlen);
    if (dst_wvalid && dst_wready)
        $display("[%0t] DST W  data=%08h last=%0d", $time, dst_wdata, dst_wlast);
    if (dst_bvalid && dst_bready)
        $display("[%0t] DST B  resp=%0d", $time, dst_bresp);
    if (irq)
        $display("[%0t] IRQ pulse", $time);
end

endmodule
