module half_adder(output cout,output sum ,input a ,input b);
    xor a1 (sum, a,b);
    and a2 (cout, a ,b);
endmodule

module full_adder(output cout,output sum ,input a ,input b ,input cin);
    wire sum_1, cout_1, cout_2;
    half_adder g1(cout_1,sum_1,a, b);
    half_adder g2(cout_2, sum, sum_1, cin);
    or g3(cout, cout_1, cout_2);
endmodule

module dadda(output signed [31:0] y,input signed [15:0] a,input signed [15:0] b);

    wire cout_temp;
    wire [31:0]stage_1_0,stage_1_1;
    wire [31:0] pp [15:0];
    wire [31:0] stage_6 [12:0];
    wire [31:0] stage_5 [8:0];
    wire [31:0] stage_4 [5:0];
    wire [31:0] stage_3 [3:0];
    wire [31:0] stage_2 [2:0];
    wire [31:0] stage_1 [1:0];
    genvar i,j,k;

    generate
        for (i=0; i<=14; i=i+1) begin : row
            for(j=i; j<= (i+14) ; j= j+1) begin : col
                and an1 (pp[i][j] , b[i] , a[j-i] );        
            end
        end
        and an2 ( pp[15][30] , b[15] , a[15] );
        for(k=0; k<=14; k = k + 1) begin : may
            nand an3 (pp[k][k + 15] , b[k] , a[15] );
            nand an4 (pp[15][k + 15] , b[15] , a[k] );
        end
    endgenerate 

    generate
        for(i= 0; i<=12; i=i+1)begin
            for (j=i; j <=12; j=j+1)
                assign stage_6[i][j] = pp[i][j];
        end
    endgenerate

    generate
        for(j= 20; j<=30; j=j+1)begin    
            for (i=(j-15); i <= 15; i=i+1)
                assign stage_6[i-3][j] = pp[i][j];
        end
    endgenerate

    half_adder a1(stage_6[1][14] , stage_6[0][13] , pp[0][13] , pp[1][13]);
    half_adder a2(stage_6[3][15] , stage_6[2][14] , pp[3][14] , pp[4][14]);
    half_adder a3(stage_6[5][16] , stage_6[4][15] , pp[6][15] , pp[7][15]);
    full_adder a4(stage_6[1][15] , stage_6[0][14] , pp[0][14] , pp[1][14] , pp[2][14]);
    full_adder a5(stage_6[1][16] , stage_6[0][15] , pp[0][15] , pp[1][15] , pp[2][15]);
    full_adder a6(stage_6[3][16] , stage_6[2][15] , pp[3][15] , pp[4][15] , pp[5][15]);
    full_adder a7(stage_6[1][17] , stage_6[0][16] , pp[1][16] , pp[2][16] , pp[3][16]);
    full_adder a8(stage_6[3][17] , stage_6[2][16] , pp[4][16] , pp[5][16] , pp[6][16]);
    full_adder a9(stage_6[5][17] , stage_6[4][16] , pp[7][16] , pp[8][16] , pp[9][16]);  
    full_adder a10(stage_6[1][18] , stage_6[0][17] , pp[2][17] , pp[3][17] , pp[4][17]);
    full_adder a11(stage_6[3][18] , stage_6[2][17] , pp[5][17] , pp[6][17] , pp[7][17]);        
    full_adder a12(stage_6[1][19] , stage_6[0][18] , pp[3][18] , pp[4][18] , pp[5][18]);        

    generate
        assign stage_6[4][17] = pp[8][17];
        assign stage_6[2][18] = pp[6][18];
        assign stage_6[0][19] = pp[4][19];
        for(j=17; j<=19; j = j+1 ) begin
            for(i=(43 - (2*j)); i<=15; i=i+1) begin
                assign stage_6[i-3][j] = pp[i][j];  
            end      
        end
    endgenerate
    genvar i2; 
    generate
        for(i=2; i<=13; i=i+1) begin     
            assign stage_6[i-1][13] = pp[i][13];
        end
        for(i=5; i<=14; i=i+1) begin
            assign stage_6[i-2][14] = pp[i][14];
        end
        for(k=8; k<=15; k=k+1) begin
            assign stage_6[k-3][15] = pp[k][15];
        end
        for(i2=10; i2<=15; i2=i2+1)begin
            assign stage_6[i2-4][16] = pp[i2][16];
        end
        assign stage_6[12][16] = 1'b1;
    endgenerate
    
    generate
        for(i= 0; i<=8; i=i+1)begin
            for (j=i; j <=8; j=j+1)
                assign stage_5[i][j] = stage_6[i][j];
        end    
    endgenerate

    generate
        for(j= 24; j<=30; j=j+1)begin
            for (i=(j-18); i <= 12; i=i+1)
                assign stage_5[i-4][j] = stage_6[i][j];
        end
    endgenerate

    generate
        half_adder a13(stage_5[1][10] , stage_5[0][9] , stage_6[0][9] , stage_6[1][9]);
        half_adder a14(stage_5[3][11] , stage_5[2][10] , stage_6[3][10] , stage_6[4][10]);
        half_adder a15(stage_5[5][12] , stage_5[4][11] , stage_6[6][11] , stage_6[7][11]);
        half_adder a16(stage_5[7][13] , stage_5[6][12] , stage_6[9][12] , stage_6[10][12]);
        full_adder a17(stage_5[1][11] , stage_5[0][10] , stage_6[0][10] , stage_6[1][10] , stage_6[2][10]);
        full_adder a18(stage_5[1][12] , stage_5[0][11] , stage_6[0][11] , stage_6[1][11] , stage_6[2][11]);
        full_adder a19(stage_5[3][12] , stage_5[2][11] , stage_6[3][11] , stage_6[4][11] , stage_6[5][11]);
        full_adder a20(stage_5[1][13] , stage_5[0][12] , stage_6[0][12] , stage_6[1][12] , stage_6[2][12]);
        full_adder a21(stage_5[3][13] , stage_5[2][12] , stage_6[3][12] , stage_6[4][12] , stage_6[5][12]);
        full_adder a22(stage_5[5][13] , stage_5[4][12] , stage_6[6][12] , stage_6[7][12] , stage_6[8][12]);
        for(j=13; j<=19; j=j+1)begin
            for(i=0; i<=9; i=i+3)begin
                full_adder x1(stage_5[((2*i)/3) + 1 ][j+1] , stage_5[((2*i)/3)][j] , stage_6[i][j] , stage_6[i+1][j] , stage_6[i+2][j]);
            end
        assign stage_5[8][j] = stage_6[12][j] ;
        end
    endgenerate
    
    generate
        for(j=23; j>=20; j= j-1)begin
            assign stage_5[46 -  (2*j)][j] = stage_6[51 -  (2*j)][j];
            for(i=(52 -  (2*j)); i<=12; i=i+1) begin
                assign stage_5[i-4][j] = stage_6[i][j];
            end
        end
    endgenerate

    full_adder a93(stage_5[1][21] , stage_5[0][20] , stage_6[2][20] , stage_6[3][20] , stage_6[4][20]);
    full_adder a30(stage_5[3][21] , stage_5[2][20] , stage_6[5][20] , stage_6[6][20] , stage_6[7][20]);
    full_adder a31(stage_5[5][21] , stage_5[4][20] , stage_6[8][20] , stage_6[9][20] , stage_6[10][20]);
    full_adder a32(stage_5[1][22] , stage_5[0][21] , stage_6[3][21] , stage_6[4][21] , stage_6[5][21]);
    full_adder a34(stage_5[3][22] , stage_5[2][21] , stage_6[6][21] , stage_6[7][21] , stage_6[8][21]);
    full_adder a36(stage_5[1][23] , stage_5[0][22] , stage_6[4][22] , stage_6[5][22] , stage_6[6][22]);    
    
    genvar i3;
    generate        
        for(i=2; i<=9; i=i+1)begin
            assign stage_5[i-1][9] = stage_6[i][9];
        end
        for(k=5; k<=10; k=k+1)begin
            assign stage_5[k-2][10] = stage_6[k][10];
        end    
        for(i2=8; i2<=11; i2=i2+1)begin
            assign stage_5[i2-3][11] = stage_6[i2][11];
        end
        for(i3=11; i3<=12; i3=i3 +1)begin
            assign stage_5[i3 -4][12] = stage_6[i3][12];
        end
    endgenerate
    
    generate
        for(i= 0; i<=5; i=i+1)begin
            for (j=i; j <=5; j=j+1) begin
                assign stage_4[i][j] = stage_5[i][j];
            end
        end
    endgenerate

    generate
        for(j= 27; j<=30; j=j+1) begin
            for (i=(j-22); i <= 8; i=i+1) begin
                assign stage_4[i-3][j] = stage_5[i][j];
            end
        end
    endgenerate

    generate
        for(j=9; j<=23; j=j+1)begin
            for(i=0; i<=6; i=i+3)
                full_adder x23(stage_4[((2*i)/3) + 1 ][j+1] , stage_4[((2*i)/3)][j] , stage_5[i][j] , stage_5[i+1][j] , stage_5[i+2][j]);
        end    
    endgenerate


    generate
        half_adder a123(stage_4[1][7] , stage_4[0][6] , stage_5[0][6] , stage_5[1][6]);
        half_adder a145(stage_4[3][8] , stage_4[2][7] , stage_5[3][7] , stage_5[4][7]);
        half_adder a100(stage_4[5][9] , stage_4[4][8] , stage_5[6][8] , stage_5[7][8]);    
        full_adder a110(stage_4[1][8] , stage_4[0][7] , stage_5[0][7] , stage_5[1][7] , stage_5[2][7]);
        full_adder a1001(stage_4[1][9] , stage_4[0][8] , stage_5[0][8] , stage_5[1][8] , stage_5[2][8]);
        full_adder a121(stage_4[3][9] , stage_4[2][8] , stage_5[3][8] , stage_5[4][8] , stage_5[5][8]);

        for(i=2; i<=6; i=i+1)begin
            assign stage_4[i-1][6] = stage_5[i][6];
        end
        
        for(k=5; k<=7; k=k +1)begin
            assign stage_4[k -2][7] = stage_5[k][7];
        end
    
        assign stage_4[5][8] = stage_5[8][8];
        full_adder a65(stage_4[1][25] , stage_4[0][24] , stage_5[2][24] , stage_5[3][24] , stage_5[4][24]);
        full_adder a66(stage_4[3][25] , stage_4[2][24] , stage_5[5][24] , stage_5[6][24] , stage_5[7][24]);
        full_adder a67(stage_4[1][26] , stage_4[0][25] , stage_5[3][25] , stage_5[4][25] , stage_5[5][25]);
        assign stage_4[0][26] = stage_5[4][26];
        assign stage_4[2][25] = stage_5[6][25];
        assign stage_4[4][24] = stage_5[8][24];
    
        for(i2=5; i2<=8; i2=i2 +1)begin
            assign stage_4[i2 -3][26] = stage_5[i2][26];
        end
    
        for(i3=7; i3 <=8; i3 =i3 +1)begin
            assign stage_4[i3 -3][25] = stage_5[i3][25];
        end
    endgenerate

    generate
        for(i= 0; i<=3; i=i+1)begin
            for (j=i; j <=3; j=j+1) begin
                assign stage_3[i][j] = stage_4[i][j];
            end
        end
    endgenerate
    
    generate
        for(j= 29; j<=30; j=j+1)begin
            for (i=(j-25); i <= 5; i=i+1) begin
                assign stage_3[i-2][j] = stage_4[i][j];
            end
        end
    endgenerate

    generate
        for(j=6; j<=26; j=j+1)begin
            for(i=0; i<=3; i=i+3)
                full_adder xx1(stage_3[((2*i)/3) + 1 ][j+1] , stage_3[((2*i)/3)][j] , stage_4[i][j] , stage_4[i+1][j] , stage_4[i+2][j]);
        end
    endgenerate

    half_adder a71(stage_3[1][5] , stage_3[0][4] , stage_4[0][4] , stage_4[1][4]);
    half_adder a771(stage_3[3][6] , stage_3[2][5] , stage_4[3][5] , stage_4[4][5]);
    full_adder a72(stage_3[1][6] , stage_3[0][5] , stage_4[0][5] , stage_4[1][5] , stage_4[2][5]);
    full_adder a79(stage_3[1][28] , stage_3[0][27] , stage_4[2][27] , stage_4[3][27] , stage_4[4][27]);

    generate
        assign stage_3[0][28] = stage_4[3][28];
        assign stage_3[2][28] = stage_4[4][28];
        assign stage_3[3][28] = stage_4[5][28];
        assign stage_3[2][27] = stage_4[5][27];
        assign stage_3[3][5] = stage_4[5][5];
        for(i=2; i<=4; i=i+1)begin
            assign stage_3[i-1][4] = stage_4[i][4];
        end
    endgenerate

    generate
        for(i= 0; i<=2; i=i+1)begin
            for (j=i; j <=2; j=j+1) begin
                assign stage_2[i][j] = stage_3[i][j];
            end
        end        
    endgenerate

    generate
        for(j=4; j<=28; j=j+1)begin
            full_adder xy1(stage_2[1][j+1] , stage_2[0][j] , stage_3[0][j] , stage_3[1][j] , stage_3[2][j]);
            assign stage_2[2][j] = stage_3[3][j] ;
        end
    endgenerate

    assign stage_2[2][29] = stage_3[3][29];
    assign stage_2[2][30] = stage_3[3][30];
    assign stage_2[0][29] = stage_3[2][29];
    assign stage_2[1][3] = stage_3[2][3];
    assign stage_2[2][3] = stage_3[3][3];
    half_adder a41 (stage_2[1][4] , stage_2[0][3] , stage_3[0][3] , stage_3[1][3]);
    
    generate
        for(i= 0; i<=1; i=i+1)begin
            for (j=i; j <=1; j=j+1) begin
                assign stage_1[i][j] = stage_2[i][j];
            end
        end     
    endgenerate

    generate
        for(j=3; j<=29; j=j+1)begin
            full_adder xp1(stage_1[1][j+1] , stage_1[0][j] , stage_2[0][j] , stage_2[1][j] , stage_2[2][j]);
        end
    endgenerate

    assign stage_1[1][2] = stage_2[2][2];
    assign stage_1[0][30] = stage_2[2][30];
    half_adder ab1 (stage_1[1][3] , stage_1[0][2] , stage_2[0][2] , stage_2[1][2]);
    assign stage_1[1][31] = 1'b1;
    assign stage_1[0][31] = 1'b0;
    assign stage_1[1][0] = 1'b0;
        
    generate
        for(j=0; j<=31; j=j+1) begin
            assign stage_1_0[j] = stage_1[0][j];
            assign stage_1_1[j] = stage_1[1][j];
        end
    endgenerate
    
    bk_adder_32 b1( stage_1_0 , stage_1_1, 1'b0, y, cout_temp);

endmodule


