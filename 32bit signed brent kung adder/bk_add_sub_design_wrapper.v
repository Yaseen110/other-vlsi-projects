//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
//Date        : Fri Jan 16 00:25:31 2026
//Host        : LAPTOP-GOFQCHQB running 64-bit major release  (build 9200)
//Command     : generate_target bk_add_sub_design_wrapper.bd
//Design      : bk_add_sub_design_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module bk_add_sub_design_wrapper
   (reset_rtl,
    sys_clock);
  input reset_rtl;
  input sys_clock;

  wire reset_rtl;
  wire sys_clock;

  bk_add_sub_design bk_add_sub_design_i
       (.reset_rtl(reset_rtl),
        .sys_clock(sys_clock));
endmodule
