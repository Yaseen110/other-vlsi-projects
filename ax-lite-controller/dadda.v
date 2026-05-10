module multiplier(result,a,b);

    input signed [15:0]a, b ;
    output signed [31:0]result ;
    

    wire COUT ;
    wire [31:0]x , y ;

    wire p[0:15][31:0] ;
    wire d6[0:12][31:0] ;
    wire d5[0:8][31:0] ;
    wire d4[0:5][31:0] ;
    wire d3[0:3][31:0] ;
    wire d2[0:2][31:0] ;
    wire d1[0:1][31:0] ;

    genvar i,j, i1 , i2 , i3 ,i4 ,i5 ,i6 ,i7 ,i8 ,i9 ,i10 ,i11 ,i12 ,i13 ,i14 ,i15 ,i16 ;


// Partial products generation
    generate

    for (i=0 ; i<=14 ; i=i+1) begin : row

    // for(j=i ; j<= (i+14)  ; j= j+1) begin
    //     and an1 (p[i][j] , b[i] , a[j] ) ;      ///////   saare fasaad ki jad
    // end

    for(j=i ; j<= (i+14)  ; j= j+1) begin : col
        and an1 (p[i][j] , b[i] , a[j-i] ) ;        
    end

    end

    //and an2 ( p[15][15] , b[15] , a[15] ) ;        ///////  saare fasaad ki dusri jad

    and an2 ( p[15][30] , b[15] , a[15] ) ;


    for(i1=0 ; i1<=14 ; i1 = i1 + 1) begin : may

    nand an3 (p[i1][i1 + 15] , b[i1] , a[15] ) ;
    nand an4 (p[15][i1 + 15] , b[15] , a[i1] ) ;
    
    end

    endgenerate 



// d6 making

    generate
    for(i= 0 ; i<=12 ; i=i+1)begin
    
    for (j=i ; j <=12 ; j=j+1)           // right triangle of p copied to d6
        assign d6[i][j] = p[i][j] ;

    end
    endgenerate

    generate
    for(j= 20 ; j<=30 ; j=j+1)begin
    
    for (i=(j-15) ; i <= 15 ; i=i+1)       // left triangle of p copied to d6
        assign d6[i-3][j] = p[i][j] ;

    end
    endgenerate


// genearting the middile columns for d6 from p
    generate

    half_adder a1(d6[1][14] , d6[0][13] , p[0][13] , p[1][13]) ;
    half_adder a2(d6[3][15] , d6[2][14] , p[3][14] , p[4][14]) ;
    half_adder a3(d6[5][16] , d6[4][15] , p[6][15] , p[7][15]) ;


    full_adder a4(d6[1][15] , d6[0][14] , p[0][14] , p[1][14] , p[2][14]) ;

    full_adder a5(d6[1][16] , d6[0][15] , p[0][15] , p[1][15] , p[2][15]) ;
    full_adder a6(d6[3][16] , d6[2][15] , p[3][15] , p[4][15] , p[5][15]) ;

    full_adder a7(d6[1][17] , d6[0][16] , p[1][16] , p[2][16] , p[3][16]) ;
    full_adder a8(d6[3][17] , d6[2][16] , p[4][16] , p[5][16] , p[6][16]) ;
    full_adder a9(d6[5][17] , d6[4][16] , p[7][16] , p[8][16] , p[9][16]) ;  


    // for(i=0 ; i<=4 ; i=i+2)
    //     full_adder a1(d6[i+1][17] , d6[i][16] , p[((3*i)/2) + 1][16] , p[((3*i)/2) + 2][16] , p[((3*i)/2) + 3][16]) ;


    full_adder a10(d6[1][18] , d6[0][17] , p[2][17] , p[3][17] , p[4][17]) ;
    full_adder a11(d6[3][18] , d6[2][17] , p[5][17] , p[6][17] , p[7][17]) ;        

    full_adder a12(d6[1][19] , d6[0][18] , p[3][18] , p[4][18] , p[5][18]) ;        

    endgenerate

    generate

    assign d6[4][17] = p[8][17] ;
    assign d6[2][18] = p[6][18] ;
    assign d6[0][19] = p[4][19] ;


    for(j=17 ; j<=19 ; j = j+1 ) begin

        for(i=(43 - (2*j)) ; i<=15 ; i=i+1) begin
            assign d6[i-3][j] = p[i][j] ;  
        end      
    end
    endgenerate

    generate
    for(i=2 ; i<=13 ; i=i+1) begin     
        assign d6[i-1][13] = p[i][13] ;
    end


    for(i=5 ; i<=14 ; i=i+1) begin
        assign d6[i-2][14] = p[i][14] ;
    end


    for(i1=8 ; i1<=15 ; i1=i1+1) begin
        assign d6[i1-3][15] = p[i1][15] ;
    end


    for(i2=10 ; i2<=15 ; i2=i2+1)begin
        assign d6[i2-4][16] = p[i2][16] ;
    end

    assign d6[12][16] = 1'b1 ;

    endgenerate
    



// generating  d5 from d6
    generate
    for(i= 0 ; i<=8 ; i=i+1)begin
    
    for (j=i ; j <=8 ; j=j+1)                      //right triangle of d6 copied to d5 as it is
        assign d5[i][j] = d6[i][j] ;
    end    
    endgenerate

    generate
    for(j= 24 ; j<=30 ; j=j+1)begin
    
    for (i=(j-18) ; i <= 12 ; i=i+1)               //left triangle of d6 copied to d5 as it is
        assign d5[i-4][j] = d6[i][j] ;
    end
    endgenerate


    generate
        
    half_adder a13(d5[1][10] , d5[0][9] , d6[0][9] , d6[1][9]) ;
    half_adder a14(d5[3][11] , d5[2][10] , d6[3][10] , d6[4][10]) ;

    half_adder a15(d5[5][12] , d5[4][11] , d6[6][11] , d6[7][11]) ;
    half_adder a16(d5[7][13] , d5[6][12] , d6[9][12] , d6[10][12]) ;


    full_adder a17(d5[1][11] , d5[0][10] , d6[0][10] , d6[1][10] , d6[2][10]) ;

    full_adder a18(d5[1][12] , d5[0][11] , d6[0][11] , d6[1][11] , d6[2][11]) ;
    full_adder a19(d5[3][12] , d5[2][11] , d6[3][11] , d6[4][11] , d6[5][11]) ;

    full_adder a20(d5[1][13] , d5[0][12] , d6[0][12] , d6[1][12] , d6[2][12]) ;
    full_adder a21(d5[3][13] , d5[2][12] , d6[3][12] , d6[4][12] , d6[5][12]) ;
    full_adder a22(d5[5][13] , d5[4][12] , d6[6][12] , d6[7][12] , d6[8][12]) ;


    for(j=13 ; j<=19 ; j=j+1)begin

    for(i=0 ; i<=9 ; i=i+3)begin
        full_adder x1(d5[((2*i)/3) + 1 ][j+1] , d5[((2*i)/3)][j] , d6[i][j] , d6[i+1][j] , d6[i+2][j]) ;             //middle chunk generation
    end

    assign d5[8][j] = d6[12][j]  ;

    end

    endgenerate


    generate
    for(j=23 ; j>=20 ; j= j-1)begin

    assign d5[46 -  (2*j)][j] = d6[51 -  (2*j)][j] ;

    for(i=(52 -  (2*j)) ; i<=12 ; i=i+1) begin
        assign d5[i-4][j] = d6[i][j] ;
    end

    end
    endgenerate


    generate
    
    full_adder a93(d5[1][21] , d5[0][20] , d6[2][20] , d6[3][20] , d6[4][20]) ;
    full_adder a30(d5[3][21] , d5[2][20] , d6[5][20] , d6[6][20] , d6[7][20]) ;
    full_adder a31(d5[5][21] , d5[4][20] , d6[8][20] , d6[9][20] , d6[10][20]) ;

    full_adder a32(d5[1][22] , d5[0][21] , d6[3][21] , d6[4][21] , d6[5][21]) ;
    full_adder a34(d5[3][22] , d5[2][21] , d6[6][21] , d6[7][21] , d6[8][21]) ;

    //full_adder a36(d5[1][23] , d5[0][22] , d6[4][20] , d6[5][20] , d6[6][20]) ;                     ////// sabse main fassad jisne carry ko 22nd column me ripple nhi hone diya tha , and i was getiing 1111111....0008  even for 2*4
    
    full_adder a36(d5[1][23] , d5[0][22] , d6[4][22] , d6[5][22] , d6[6][22]) ;
    
    
    endgenerate


    generate
    
    for(i=2 ; i<=9 ; i=i+1)begin
        assign d5[i-1][9] = d6[i][9] ;
    end

    for(i1=5 ; i1<=10 ; i1=i1+1)begin
        assign d5[i1-2][10] = d6[i1][10] ;
    end

    for(i2=8 ; i2<=11 ; i2=i2+1)begin
        assign d5[i2-3][11] = d6[i2][11] ;
    end
 
    for(i3=11 ; i3<=12 ; i3=i3 +1)begin
        assign d5[i3 -4][12] = d6[i3][12] ;
    end

    endgenerate





// d4  generation  from d5

    generate
    for(i= 0 ; i<=5 ; i=i+1)begin
    
    for (j=i ; j <=5 ; j=j+1) begin       //right triangle of d6 copied to d5 as it is
        assign d4[i][j] = d5[i][j] ;
    end
    end
    endgenerate

    generate
    for(j= 27 ; j<=30 ; j=j+1)begin
    
    for (i=(j-22) ; i <= 8 ; i=i+1) begin           //left triangle of d6 copied to d5 as it is
        assign d4[i-3][j] = d5[i][j] ;
    end
    end
    endgenerate

    generate
    for(j=9 ; j<=23 ; j=j+1)begin

    for(i=0 ; i<=6 ; i=i+3)
        full_adder x23(d4[((2*i)/3) + 1 ][j+1] , d4[((2*i)/3)][j] , d5[i][j] , d5[i+1][j] , d5[i+2][j]) ;             //middle chunk generation

    end    
    endgenerate


    generate

    half_adder a123(d4[1][7] , d4[0][6] , d5[0][6] , d5[1][6]) ;
    half_adder a145(d4[3][8] , d4[2][7] , d5[3][7] , d5[4][7]) ;
    half_adder a100(d4[5][9] , d4[4][8] , d5[6][8] , d5[7][8]) ;
    
    full_adder a110(d4[1][8] , d4[0][7] , d5[0][7] , d5[1][7] , d5[2][7]) ;

    full_adder a1001(d4[1][9] , d4[0][8] , d5[0][8] , d5[1][8] , d5[2][8]) ;

    full_adder a121(d4[3][9] , d4[2][8] , d5[3][8] , d5[4][8] , d5[5][8]) ;


    for(i=2 ; i<=6 ; i=i+1)begin
        assign d4[i-1][6] = d5[i][6] ;
    end
    
    for(i1=5 ; i1<=7 ; i1=i1 +1)begin
        assign d4[i1 -2][7] = d5[i1][7] ;
    end

    assign d4[5][8] = d5[8][8] ;


    full_adder a65(d4[1][25] , d4[0][24] , d5[2][24] , d5[3][24] , d5[4][24]) ;
    full_adder a66(d4[3][25] , d4[2][24] , d5[5][24] , d5[6][24] , d5[7][24]) ;

    full_adder a67(d4[1][26] , d4[0][25] , d5[3][25] , d5[4][25] , d5[5][25]) ;

    assign d4[0][26] = d5[4][26] ;
    assign d4[2][25] = d5[6][25] ;
    assign d4[4][24] = d5[8][24] ;

    for(i2=5 ; i2<=8 ; i2=i2 +1)begin
        assign d4[i2 -3][26] = d5[i2][26] ;
    end

    for(i3=7 ; i3 <=8 ; i3 =i3 +1)begin
        assign d4[i3 -3][25] = d5[i3][25] ;
    end
    
    endgenerate




//  d3  from d4

    generate
    for(i= 0 ; i<=3 ; i=i+1)begin
    
    for (j=i ; j <=3 ; j=j+1) begin       //right triangle of d6 copied to d5 as it is
        assign d3[i][j] = d4[i][j] ;
    end
    end
    endgenerate


    generate
    for(j= 29 ; j<=30 ; j=j+1)begin
    
    for (i=(j-25) ; i <= 5 ; i=i+1) begin           //left triangle of d6 copied to d5 as it is
        assign d3[i-2][j] = d4[i][j] ;
    end
    end
    endgenerate





    generate
    for(j=6 ; j<=26 ; j=j+1)begin

    for(i=0 ; i<=3 ; i=i+3)
        full_adder xx1(d3[((2*i)/3) + 1 ][j+1] , d3[((2*i)/3)][j] , d4[i][j] , d4[i+1][j] , d4[i+2][j]) ;             //middle chunk generation

    end
    endgenerate



    generate

    half_adder a71(d3[1][5] , d3[0][4] , d4[0][4] , d4[1][4]) ;
    half_adder a771(d3[3][6] , d3[2][5] , d4[3][5] , d4[4][5]) ;

    full_adder a72(d3[1][6] , d3[0][5] , d4[0][5] , d4[1][5] , d4[2][5]) ;

    full_adder a79(d3[1][28] , d3[0][27] , d4[2][27] , d4[3][27] , d4[4][27]) ;

    endgenerate



    generate

    assign d3[0][28] = d4[3][28] ;
    assign d3[2][28] = d4[4][28] ;
    assign d3[3][28] = d4[5][28] ;

    assign d3[2][27] = d4[5][27] ;

    assign d3[3][5] = d4[5][5] ;


    for(i=2 ; i<=4 ; i=i+1)begin
        assign d3[i-1][4] = d4[i][4] ;
    end
    
    endgenerate




//  d2 from d3

    generate

    for(i= 0 ; i<=2 ; i=i+1)begin
    
    for (j=i ; j <=2 ; j=j+1) begin       //right triangle of copied 
        assign d2[i][j] = d3[i][j] ;
    end
    end        
    endgenerate


    generate

    for(j=4 ; j<=28 ; j=j+1)begin
        full_adder xy1(d2[1][j+1] , d2[0][j] , d3[0][j] , d3[1][j] , d3[2][j]) ;             //middle chunk generation
        assign d2[2][j] = d3[3][j]  ;

    end
    endgenerate


    generate
    assign d2[2][29] = d3[3][29] ;
    assign d2[2][30] = d3[3][30] ;

    assign d2[0][29] = d3[2][29] ;


    assign d2[1][3] = d3[2][3] ;
    assign d2[2][3] = d3[3][3] ;

    half_adder a41 (d2[1][4] , d2[0][3] , d3[0][3] , d3[1][3]) ;
        
    endgenerate





//  d1  from  d2

    generate
    for(i= 0 ; i<=1 ; i=i+1)begin
    
    for (j=i ; j <=1 ; j=j+1) begin       //right triangle of d2 copied to d1 as it is
        assign d1[i][j] = d2[i][j] ;
    end
    end     
    endgenerate



    generate
    for(j=3 ; j<=29 ; j=j+1)begin
        full_adder xp1(d1[1][j+1] , d1[0][j] , d2[0][j] , d2[1][j] , d2[2][j]) ;             //middle chunk generation
    end
    endgenerate


    generate
    assign d1[1][2] = d2[2][2] ;

    assign d1[0][30] = d2[2][30] ;

    half_adder ab1 (d1[1][3] , d1[0][2] , d2[0][2] , d2[1][2]) ;



    //  now we preparing it to go in a 32 bit adder

    assign d1[1][31] = 1'b1 ;

    assign d1[0][31] = 1'b0 ;

    assign d1[1][0] = 1'b0 ;
        
    endgenerate




// setting the inputs for the 32 bit tree adder

    generate

    for(j=0 ; j<=31 ; j=j+1) begin
        assign x[j] = d1[0][j];
        assign y[j] = d1[1][j];
    end
    endgenerate

    generate
    adder f1 (COUT, result, x , y , 1'b0) ;                                 // brent kung adder                      ( cin = 0 )


    endgenerate


endmodule








module full_adder(cout, sum , a , b , cin);

    output cout , sum ;
    input a , b , cin;
    wire p , q ,r;

    xor x1 (p, a,b);
    xor x2 (sum, p , cin) ;

    and an5 (q, a ,b) ;
    and an6 (r, p ,cin) ;

    or o1 (cout, r ,q) ;

endmodule


module half_adder(cout, sum , a , b);

    output cout , sum ;
    input a , b ;

    xor x1 (sum, a,b);
    and an5 (cout, a ,b) ;

endmodule



module adder (cout,sum,a,b,cin);                   //brent kung

    //  t=0
    input [31:0]a,b ;
    input cin ;
    output cout ;
    output [31:0]sum ;

    wire [32:0]c ;

    wire p[0:5][31:0] ;
    wire g[0:5][31:0] ;

    assign cout = c[32];
    assign c[0]=cin ;

    genvar i1 , i2 , i3 , i4 , i5 , i6 , i7 , i8 , i9 , i10 , i11 , i12  ;

    generate
    
    // t=1     (Generation  of  p0  and g0   and  c[1] happens together)
    for (i1 = 0; i1 < 32; i1 = i1 + 1) begin
    assign p[0][i1] = a[i1] ^ b[i1];
    assign g[0][i1] = a[i1] & b[i1];
    end

    assign c[1] = (a[0]&b[0]) | ((c[0])&(a[0] | b[0])) ;

    // t=2
    for (i2 = 0; i2 < 32; i2 = i2 + 2) begin
    assign p[1][i2] = p[0][(i2) + 1] & p[0][i2];
    assign g[1][i2] = g[0][(i2) + 1] | (p[0][(i2) + 1] & g[0][i2]);
    end

    assign c[2] = g[1][0] | (p[1][0] & c[0]) ;


    // t=3
    for (i3 = 0; i3 < 32; i3 = i3 + 4) begin
    assign p[2][i3] = p[1][(i3) + 2] & p[1][i3];
    assign g[2][i3] = g[1][(i3) + 2] | (p[1][(i3) + 2] & g[1][i3]);
    end

    assign c[4] = g[2][0] | (p[2][0] & c[0]) ;

    assign c[3] = g[0][2] | (p[0][2] & c[2]) ;


    // t=4
    for (i4 = 0; i4 < 32; i4 = i4 + 8) begin
    assign p[3][i4] = p[2][(i4) + 4] & p[2][i4];
    assign g[3][i4] = g[2][(i4) + 4] | (p[2][(i4) + 4] & g[2][i4]);
    end

    assign c[8] = g[3][0] | (p[3][0] & c[0]) ;

    for(i5=0 ; i5 <=1 ; i5 = i5 +1)
        assign c[i5 +5] = g[i5][4] | (p[i5][4] & c[4]) ;

    
    // t=5            
    for(i6=0 ; i6<32 ; i6 = i6+16 )begin
        assign p[4][i6] = p[3][(i6) + 8] & p[3][i6] ;
        assign g[4][i6] = g[3][(i6) + 8] | ( p[3][(i6) + 8] & g[3][i6]) ;
    end

    assign c[16] = g[4][0] | (p[4][0] & c[0]) ;

    assign c[7] = g[0][6] | (p[0][6] & c[6]) ;

    for(i7=0; i7<=1 ; i7=i7 +1)
        assign c[ i7 +9 ] = g[i7][8] | (p[i7][8] & c[8]) ;
        
    assign c[12] = g[2][8] | (p[2][8] & c[8]) ;

    
    //t=6   & t=7
    for (i8 = 0; i8 < 1; i8 = i8 + 1) begin
    assign p[5][i8] = p[4][(i8) + 16] & p[4][i8];
    assign g[5][i8] = g[4][(i8) + 16] | (p[4][(i8) + 16] & g[4][i8]);
    end

    assign c[32] = g[5][0] | (p[5][0] & c[0]) ;


    for(i9=10; i9<=30 ; i9=i9 +2)
        assign c[1 + i9] = g[0][i9] | (p[0][i9] & c[i9]) ;

    for(i10 =12; i10 <=28 ; i10 = i10 +4)
        assign c[2+i10] = g[1][i10] | (p[1][i10] & c[i10]) ;

    for(i11 =16; i11 <=24 ; i11 = i11 +8)
        assign c[4+i11] = g[2][i11] | (p[2][i11] & c[i11]) ;
    
    assign c[24] = g[3][16] | (p[3][16] & c[16]) ;
    assign c[31] = g[0][30] | (p[0][30] & c[30]) ;

    // sum

    for(i12 =0; i12 <32; i12 = i12 +1)
        assign sum[i12] = p[0][i12] ^ (c[i12]) ;
    
    endgenerate

endmodule
