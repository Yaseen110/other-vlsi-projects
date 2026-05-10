`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 19.01.2026 00:40:41
//// Design Name: 
//// Module Name: controller
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

module controller(
    input clk,
    input start_stop,
    input left_right,
    input [10:0] douta,
    output reg [3:0] addra,
    output ena,
    output [7:0] inp,
    output [2:0] sel,
    output direction
    );
     initial
        addra = 4'd0;
     assign ena = start_stop;
     always @(posedge clk) begin
        if (start_stop) begin
            if (addra == 4'd15)
                addra <= 4'd0;
            else
                addra <= addra + 1'b1;
        end
     end
    
     assign inp = douta[7:0];
     assign sel = douta[10:8];    
     assign direction = left_right;
     
endmodule
