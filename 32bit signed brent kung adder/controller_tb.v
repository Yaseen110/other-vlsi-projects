`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.01.2026 00:12:53
// Design Name: 
// Module Name: controller_tb
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


module controller_tb();

    reg clk = 0;
    reg start_stop = 0;
    reg add_sub = 0;

    wire [3:0] addra;
    wire ena;
    reg  [63:0] douta;

    wire [31:0] a, b;
    wire cin;

    // Clock
    always #5 clk = ~clk;

    // DUT
    controller dut (
        .clk(clk),
        .start_stop(start_stop),
        .add_sub(add_sub),
        .douta(douta),
        .addra(addra),
        .ena(ena),
        .a(a),
        .b(b),
        .cin(cin)
    );

    // BRAM model
    reg [63:0] mem [0:15];

    initial begin
        mem[0] = 64'd7653632258061;
        mem[1] = 64'd2310692405260;
        mem[2] = 64'd77309411353;
        mem[3] = 64'd68719476741;
        mem[4] = 64'd433791696916;
        mem[5] = 64'd7653632258061;
        mem[6] = 64'd2310692405260;
        mem[7] = 64'd77309411353;
        mem[8] = 64'd68719476741;
        mem[9] = 64'd433791696916;
        mem[10] = 64'd7653632258061;
        mem[11] = 64'd2310692405260;
        mem[12] = 64'd77309411353;
        mem[13] = 64'd68719476741;
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
