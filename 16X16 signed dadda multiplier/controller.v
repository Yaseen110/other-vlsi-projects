`timescale 1ns / 1ps

module controller(
    input clk,
    input start_stop,
    input [31:0] douta,
    output reg [3:0] addra,
    output ena,
    output [15:0] a,
    output [15:0] b
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
    
     assign a = douta[31:16];
     assign b = douta[15:0];    
     
endmodule
