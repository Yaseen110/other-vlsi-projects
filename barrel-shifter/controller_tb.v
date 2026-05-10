`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 19.01.2026 00:45:33
//// Design Name: 
//// Module Name: controller_tb
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// 
//// Dependencies: 
//// 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////

module controller_tb();

    reg clk = 0;
    reg start_stop = 0;
    reg left_right = 0;

    wire [3:0] addra;
    wire ena;
    reg  [10:0] douta;

    wire [7:0] inp; 
    wire [2:0] sel;
    wire direction;

    // Clock
    always #5 clk = ~clk;

    // DUT
    controller dut (
        .clk(clk),
        .start_stop(start_stop),
        .left_right(left_right),
        .douta(douta),
        .addra(addra),
        .ena(ena),
        .inp(inp),
        .sel(sel),
        .direction(direction)
    );

    // BRAM model
    reg [10:0] mem [0:15];

    initial begin
        mem[0] = 11'b00010110011;
        mem[1] = 11'b00110110011;
        mem[2] = 11'b01010110011;
        mem[3] = 11'b01110110011;
        mem[4] = 11'b10010110011;
        mem[5] = 11'b10110110011;
        mem[6] = 11'b11010110011;
        mem[7] = 11'b11110110011;
        mem[8] = 11'b00010100011;
        mem[9] = 11'b00110100011;
        mem[10] = 11'b01010100011;
        mem[11] = 11'b01110100011;
        mem[12] = 11'b10010100011;
        mem[13] = 11'b10110100011;
        mem[14] = 11'b11010100011;
        mem[15] = 11'b11110100011;
    end

    // synchronous BRAM read (1-cycle latency)
    always @(posedge clk) begin
        if (ena)
            douta <= mem[addra];
    end

    initial begin
        #20 start_stop = 1;
        #200 start_stop = 0;
        #50 $finish;
    end

endmodule