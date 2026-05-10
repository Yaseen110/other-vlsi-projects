//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
//Date        : Fri Feb  6 16:53:17 2026
//Host        : LAPTOP-GOFQCHQB running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (reset_rtl,
    sys_clock);
  input reset_rtl;
  input sys_clock;

  wire reset_rtl;
  wire sys_clock;

  design_1 design_1_i
       (.reset_rtl(reset_rtl),
        .sys_clock(sys_clock));
endmodule
