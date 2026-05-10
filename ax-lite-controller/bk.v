`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.01.2026 14:42:53
// Design Name: 
// Module Name: bk
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

module pg_generator(input a, input b, output p, output g);
    xor x1(p, a, b); 
    and a1(g, a, b); 
endmodule

module black_cell(input p_top, g_top, input p_prev, g_prev, output p_out, g_out);
    wire w1;
    and a1(w1, p_top, g_prev);
    or  o1(g_out, g_top, w1);
    and a2(p_out, p_top, p_prev);
endmodule

module gray_cell(input p_top, g_top, input g_prev, output g_out);
    wire w1;
    and a1(w1, p_top, g_prev);
    or  o1(g_out, g_top, w1);
endmodule

module bk_adder_32(input [31:0] a,input [31:0] b,input cin,output [31:0] sum,output cout);

    wire [31:0] p [0:10];
    wire [31:0] g [0:10];

    genvar i;
   
    generate
        for (i = 0; i < 32; i = i + 1) begin : stage_0
            if (i == 0) begin
                wire p_temp, g_temp, p_and_cin;
                
                pg_generator pg0(a[0], b[0], p_temp, g_temp);
                
                and a_cin(p_and_cin, p_temp, cin);
                or  o_cin(g[0][0], g_temp, p_and_cin);
                
                assign p[0][0] = p_temp;
            end 
            else begin
                pg_generator pg_inst(a[i], b[i], p[0][i], g[0][i]);
            end
        end
    endgenerate
    
    generate
        for (i = 0; i < 32; i = i + 2) begin : level_1_logic
            assign p[1][i] = p[0][i];
            assign g[1][i] = g[0][i];
            black_cell bc_1(p[0][i+1], g[0][i+1], p[0][i], g[0][i], p[1][i+1], g[1][i+1]);
        end
    endgenerate

    generate
        for (i = 0; i < 32; i = i + 4) begin : level_2_logic
            assign p[2][i]   = p[1][i];   assign g[2][i]   = g[1][i];
            assign p[2][i+1] = p[1][i+1]; assign g[2][i+1] = g[1][i+1];
            assign p[2][i+2] = p[1][i+2]; assign g[2][i+2] = g[1][i+2];

            black_cell bc_2(p[1][i+3], g[1][i+3], p[1][i+1], g[1][i+1], p[2][i+3], g[2][i+3]);
        end
    endgenerate

    generate
        for (i = 0; i < 32; i = i + 8) begin : level_3_logic
             genvar j;
             for(j=0; j<7; j=j+1) begin : pass_l3
                 assign p[3][i+j] = p[2][i+j];
                 assign g[3][i+j] = g[2][i+j];
             end
             black_cell bc_3(p[2][i+7], g[2][i+7], p[2][i+3], g[2][i+3], p[3][i+7], g[3][i+7]);
        end
    endgenerate

    generate
        for (i = 0; i < 32; i = i + 16) begin : level_4_logic
             genvar k;
             for(k=0; k<15; k=k+1) begin : pass_l4
                 assign p[4][i+k] = p[3][i+k];
                 assign g[4][i+k] = g[3][i+k];
             end
             black_cell bc_4(p[3][i+15], g[3][i+15], p[3][i+7], g[3][i+7], p[4][i+15], g[4][i+15]);
        end
    endgenerate

    generate
         genvar m;
         for(m=0; m<31; m=m+1) begin : pass_l5
             assign p[5][m] = p[4][m];
             assign g[5][m] = g[4][m];
         end
         black_cell bc_5(p[4][31], g[4][31], p[4][15], g[4][15], p[5][31], g[5][31]);
    endgenerate

    generate
        for(i=0; i<32; i=i+1) begin : inv_1
            if(i == 23) begin
                gray_cell gc_inv1(p[5][i], g[5][i], g[5][15], g[6][i]);
                assign p[6][i] = p[5][i]; 
            end else begin
                assign p[6][i] = p[5][i];
                assign g[6][i] = g[5][i];
            end
        end
    endgenerate

    generate
        for(i=0; i<32; i=i+1) begin : inv_2
            if(i == 11) begin      
                gray_cell gc_inv2a(p[6][i], g[6][i], g[6][7],  g[7][i]);
                assign p[7][i] = p[6][i];
            end
            else if(i == 19) begin 
                gray_cell gc_inv2b(p[6][i], g[6][i], g[6][15], g[7][i]);
                assign p[7][i] = p[6][i];
            end
            else if(i == 27) begin 
                gray_cell gc_inv2c(p[6][i], g[6][i], g[6][23], g[7][i]);
                assign p[7][i] = p[6][i];
            end
            else begin
                assign p[7][i] = p[6][i];
                assign g[7][i] = g[6][i];
            end
        end
    endgenerate

    generate
        for(i=0; i<32; i=i+1) begin : inv_3
            if(i == 5  || i == 9  || i == 13 || i == 17 || 
               i == 21 || i == 25 || i == 29) begin
                gray_cell gc_inv3(p[7][i], g[7][i], g[7][i-2], g[8][i]);
                assign p[8][i] = p[7][i];
            end else begin
                assign p[8][i] = p[7][i];
                assign g[8][i] = g[7][i];
            end
        end
    endgenerate

    generate
        for(i=0; i<32; i=i+1) begin : inv_4
            if(i > 0 && (i[0] == 1'b0)) begin
                gray_cell gc_inv4(p[8][i], g[8][i], g[8][i-1], g[9][i]);
                assign p[9][i] = p[8][i];
            end else begin
                assign p[9][i] = p[8][i];
                assign g[9][i] = g[8][i];
            end
        end
    endgenerate

    assign cout = g[9][31];

    xor sum0(sum[0], p[0][0], cin);

    generate
        for(i=1; i<32; i=i+1) begin : sum_gen
            xor sum_i(sum[i], p[0][i], g[9][i-1]);
        end
    endgenerate

endmodule