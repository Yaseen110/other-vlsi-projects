`timescale 1ns/1ps
// =============================================================
// simple_byte_ram.v
// Byte-addressable simple RAM.
// No AXI logic here. No word_index/divide/multiply.
// Controller supplies byte address directly.
// 32-bit access is formed from 4 consecutive bytes.
// =============================================================
module simple_byte_ram #(
    parameter MEM_BYTES = 4096
)(
    input  wire        clk,
    input  wire        mem_en,
    input  wire        mem_we,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    input  wire [3:0]  mem_wstrb,
    output reg  [31:0] mem_rdata
);

reg [7:0] mem [0:MEM_BYTES-1];
integer i;

initial begin
    for (i = 0; i < MEM_BYTES; i = i + 1)
        mem[i] = 8'h00;
    mem_rdata = 32'h00000000;
end

// Synchronous read/write RAM.
// Byte-addressable: mem_addr points to byte 0 of the 32-bit word.
always @(posedge clk) begin
    if (mem_en) begin
        if (mem_we) begin
            if (mem_wstrb[0]) mem[mem_addr + 0] <= mem_wdata[7:0];
            if (mem_wstrb[1]) mem[mem_addr + 1] <= mem_wdata[15:8];
            if (mem_wstrb[2]) mem[mem_addr + 2] <= mem_wdata[23:16];
            if (mem_wstrb[3]) mem[mem_addr + 3] <= mem_wdata[31:24];
        end

        mem_rdata <= {mem[mem_addr + 3], mem[mem_addr + 2], mem[mem_addr + 1], mem[mem_addr + 0]};
    end
end

// Simulation helper: initialize byte pattern.
task init_pattern;
    input integer start_byte;
    input integer num_bytes;
    input [7:0] seed;
    integer k;
    begin
        for (k = 0; k < num_bytes; k = k + 1)
            mem[start_byte + k] = seed + k[7:0];
    end
endtask

// Simulation helper: clear byte range.
task clear_region;
    input integer start_byte;
    input integer num_bytes;
    input [7:0] value;
    integer k;
    begin
        for (k = 0; k < num_bytes; k = k + 1)
            mem[start_byte + k] = value;
    end
endtask

endmodule
