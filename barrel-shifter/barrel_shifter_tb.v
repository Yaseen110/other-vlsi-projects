`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.01.2026 00:27:51
// Design Name: 
// Module Name: barrel_shifter_tb
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


module barrel_shifter_tb();
    reg direction;
    reg  [2:0] sel;
    reg  [7:0] inp;
    wire [7:0] op;

    barrel_shifter dut (
        .direction(direction),
        .sel(sel),
        .inp(inp),
        .op(op)
    );

    initial begin
        $display("L  B   A        Y");
        $monitor("%b %b %b %b", direction, sel, inp, op);
	$dumpfile("wave.vcd");
	$dumpvars(0,barrel_shifter_tb);

        inp = 8'b10110011;

        // left rotate
        direction = 0; sel = 3'b001; #10;
        direction = 0; sel = 3'b010; #10;
        direction = 0; sel = 3'b011; #10;
	direction = 0; sel = 3'b100; #10;
        direction = 0; sel = 3'b101; #10;
        direction = 0; sel = 3'b110; #10;	
	direction = 0; sel = 3'b111; #10

        // right rotate
        direction = 1; sel = 3'b001; #10;
        direction = 1; sel = 3'b010; #10;
        direction = 1; sel = 3'b011; #10;
	direction = 1; sel = 3'b100; #10;
        direction = 1; sel = 3'b101; #10;
        direction = 1; sel = 3'b110; #10;
	direction = 1; sel = 3'b111; #10
        $finish;
    end

endmodule
