`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.01.2026 11:54:56
// Design Name: 
// Module Name: bk_add_sub_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module bk_add_sub_tb();


    reg  [31:0] a, b;
    reg         mode;
    wire [31:0] sum;
    wire        cout;

    reg  [32:0] expected;

    bk_add_sub dut (
        .a(a),
        .b(b),
        .mode(mode),
        .sum(sum),
        .cout(cout)
    );

    initial begin
        mode = 0;

        a=32'h00000005; b=32'h00000003; expected = a + b;
        #10;
        a=32'hAAAAAAAA; b=32'h55555555; expected = a + b;
        #10;
        a=32'hFFFFFFFF; b=32'h00000001; expected = a + b;
        #10;
        mode = 1;

        a=32'h00000005; b=32'h00000003; expected = a - b;
        #10;
        a=32'h00000003; b=32'h00000005; expected = a - b;
        #10;
        a=32'h80000000; b=32'h00000001; expected = a - b;
        #10;
        $finish;
    end

endmodule
