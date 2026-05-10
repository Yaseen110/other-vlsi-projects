`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.01.2026 00:25:52
// Design Name: 
// Module Name: barrel_shifter
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
module mux(input a,input b,input sel,output op);
// direction = 0 left shift else right shift
wire x,y,z;

not g1(x,sel);
and g2(y,x,a);
and g3(z,sel,b);
or g4(op,y,z);

endmodule

module barrel_shifter(
    input direction,
    input [2:0] sel,
    input [7:0] inp,
    output [7:0] op
    );
    wire [7:0] s1,s2,s3,s4;
    genvar i;
    
    generate
        for(i=0;i<8;i=i+1) begin: bit_rev
            mux m1(inp[7-i],inp[i],direction,s1[i]);
        end
    endgenerate
    
    generate
        for(i=0;i<8;i=i+1) begin: level_sel2
            if(i < 4) 
                mux m3(s1[i],s1[i+4],sel[2],s2[i]);
            else
                mux m4(s1[i],1'b0,sel[2],s2[i]);
        end
    endgenerate
    
    generate
        for(i=0;i<8;i=i+1) begin: level_sel1
            if(i < 6) 
                mux m3(s2[i],s2[i+2],sel[1],s3[i]);
            else
                mux m4(s2[i],1'b0,sel[1],s3[i]);
        end
    endgenerate
    
    generate
        for(i=0;i<8;i=i+1) begin: level_sel0
            if(i < 7) 
                mux m3(s3[i],s3[i+1],sel[0],s4[i]);
            else
                mux m4(s3[i],1'b0,sel[0],s4[i]);
        end
    endgenerate
    
    generate
        for(i=0;i<8;i=i+1) begin: bit_rev_2
            mux m2(s4[7-i],s4[i],direction,op[i]);
        end
    endgenerate
    
endmodule
