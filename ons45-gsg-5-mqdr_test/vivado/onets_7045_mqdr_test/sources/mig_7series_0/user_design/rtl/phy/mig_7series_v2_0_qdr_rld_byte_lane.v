//*****************************************************************************
// (c) Copyright 2009 - 2013 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//*****************************************************************************
//
//  Owner:        Jayant Mittal
//  Revision:     $Id: qdr_rld_byte_lane.v,v 1.2 2012/05/08 01:03:44 rodrigoa Exp $
//                $Author: rodrigoa $
//                $DateTime: 2010/09/21 18:05:17 $
//                $Change: 490882 $
//  Description:
//    This verilog file is a parameterizable single 10 or 12 bit byte lane.
//
//  History:
//  Date        Engineer    Description
//  10/01/2010  J. Mittal   Initial Checkin.  
//  07/30/2013              Added PO_COARSE_BYPASS for QDR2+ design.
//
//////////////////////////////////////////////////////////////////////////////
`timescale 1ps/1ps

module mig_7series_v2_0_qdr_rld_byte_lane #(
// these are used to scale the index into phaser,calib,scan,mc vectors
// to access fields used in this instance
      parameter MEMORY_TYPE                     = "SRAM",
      parameter SIMULATION                      = "FALSE",
      parameter PO_COARSE_BYPASS                = "OFF",

      parameter CPT_CLK_CQ_ONLY                 = "TRUE",
      parameter INTERFACE_TYPE                  = "UNIDIR",
	  parameter BUFG_FOR_OUTPUTS                = "OFF",
	  parameter REFCLK_FREQ                     = 300.0,//Reference Clk Feq for IODELAYs
	  parameter CLK_PERIOD                      = 0,
	  parameter PC_CLK_RATIO                    = 2,
      
      // placement parameters
      parameter ABCD                            = "A", 
      parameter PRE_FIFO                        = "TRUE",
      parameter BITLANES_IN                     = 12'b0000_0000_0000,
      parameter BITLANES_OUT                    = 12'b0000_0000_0000,
      parameter CK_P_OUT                        = 12'b0000_0000_0000,
      parameter DATA_CTL_N                      = 1,
      parameter GENERATE_DDR_CK                 = 1,
      parameter GENERATE_DDR_DK                 = 0,
      parameter DIFF_CK                         = 1,
      parameter DIFF_DK                         = 1,
      parameter CK_VALUE_D1                     = 1'b0,
      parameter DK_VALUE_D1                     = 1'b0,
      parameter BYTE_GROUP_TYPE                 = "IN",
      parameter BUS_WIDTH                       = 12,   
      
      // IO parameters 
      parameter IODELAY_GRP                     = "IODELAY_MIG", //May be assigned unique name when mult IP cores in design
      parameter IODELAY_HP_MODE                 = "ON",
      
      parameter PO_FINE_DELAY                   = 0,
      parameter PO_FINE_SKEW_DELAY              = 0,
      parameter PO_COARSE_SKEW_DELAY            = 0,
      parameter PO_OCLK_DELAY                   = 00,
      parameter PO_OCLKDELAY_INV                = "TRUE",      
      parameter real PO_REFCLK_PERIOD           = 2.5,
      parameter PI_FREQ_REF_DIV                 = "NONE",
      parameter real PI_REFCLK_PERIOD           = 2.5,
      parameter real MEMREFCLK_PERIOD           = 2.5,
      parameter TCQ                             = 100 ,           //Register Delay
          
      // hardcoded: not passed down from phy_4lanes
      
      //OUT_FIFO
      parameter OF_ALMOST_EMPTY_VALUE           = 1,
      parameter OF_ALMOST_FULL_VALUE            = 1,
      parameter OF_ARRAY_MODE                   = "UNDECLARED",
      parameter OF_OUTPUT_DISABLE               = "TRUE",
      parameter OF_SYNCHRONOUS_MODE             = "FALSE",
      
      //IN_FIFO
      parameter IF_ARRAY_MODE                  = "UNDECLARED",//"ARRAY_MODE_4_X_4",
      parameter IF_ALMOST_EMPTY_VALUE          =  1,
      parameter IF_ALMOST_FULL_VALUE           =  1,
      parameter IF_SYNCHRONOUS_MODE            = "FALSE",
      
      //PHASER_OUT
      parameter PO_CLKOUT_DIV                   = (DATA_CTL_N == 0) ? PC_CLK_RATIO :  2,
      parameter PO_COARSE_DELAY                 = 0,
      parameter PO_EN_OSERDES_RST               = "TRUE",
      // parameter PO_OUTPUT_CLK_SRC               = "DELAYED_REF",  use L_PO_OUTPUT_CLK_SRC
      parameter PO_SYNC_IN_DIV_RST              = "TRUE",
                                    
      //PHASER_IN
      parameter PI_CLKOUT_DIV                   = 2,     
      parameter PI_FINE_DELAY                   = 1,
      parameter PI_EN_ISERDES_RST               = "TRUE",
      parameter PI_OUTPUT_CLK_SRC               = "DELAYED_PHASE_REF",      
      parameter PI_SYNC_IN_DIV_RST              = "TRUE",
      
      // phy control block parameters
      parameter MSB_BURST_PEND_PO               =  3,
      parameter MSB_BURST_PEND_PI               =  7,
      parameter MSB_RANK_SEL_I                  =  MSB_BURST_PEND_PI+ 8,
      parameter MSB_RANK_SEL_O                  =  MSB_RANK_SEL_I   + 8,
      parameter MSB_DIV_RST                     =  MSB_RANK_SEL_O   + 1,
      parameter MSB_PHASE_SELECT                =  MSB_DIV_RST      + 1,
      parameter MSB_BURST_PI                    =  MSB_PHASE_SELECT + 4,
      parameter PHASER_CTL_BUS_WIDTH            =  MSB_RANK_SEL_I + 1
      


    )(
      input                        rst,
      input                        phy_clk,
	  input                        phy_clk_fast,
      input                        freq_refclk,
      input                        mem_refclk,
      input                        sync_pulse,
      output wire [BUS_WIDTH-1:0]  O, 
      input       [11:0]           I,
      input                       out_fifos_full ,   
      output wire [BUS_WIDTH-1:0]  mem_dq_ts,
      output wire [1:0]            ddr_ck_out,
      output wire                  if_a_empty,
      output wire                  if_empty,
      output wire                  if_a_full,
      output wire                  if_full,
      output wire                  of_a_empty,
      output wire                  of_empty,
      output wire                  of_a_full,
      output wire                  of_full,
      output wire [79:0]           phy_din,    // Due to Array_Mode_4_x_4 
      input  [79:0]                phy_dout,   // Due to Array_Mode_4_x_4 
      input                        phy_cmd_wr_en,
      input                        phy_data_wr_en,
      input                        phy_rd_en,
      input                        idelay_ld,
      input [BUS_WIDTH-1:0]        idelay_ce,
      input [BUS_WIDTH-1:0]        idelay_inc,
      input [59:0]                 idelay_cnt_in,
      output wire [59:0]           idelay_cnt_out,
      
      // phy control block updates:
      input [PHASER_CTL_BUS_WIDTH-1:0] phaser_ctl_bus,

      output wire                  po_coarse_overflow,
      output wire                  po_fine_overflow,
      output wire [8:0]            po_counter_read_val,
      input                        po_fine_enable,
      input                        po_coarse_enable,
      input                        po_edge_adv,
      input                        po_fine_inc,
      input                        po_coarse_inc,
      input                        po_counter_load_en,
      input                        po_counter_read_en,
      input                        po_sel_fine_oclk_delay,
      input  [8:0]                 po_counter_load_val,
      input                        po_dec_done,
      input                        po_inc_done,
      output reg                   po_delay_done,

      input                        pi_edge_adv,
      input                        pi_fine_enable,
      input                        pi_fine_inc,
      input                        pi_counter_load_en,
      input                        pi_counter_read_en,
      input  [5:0]                 pi_counter_load_val,
      input                        sys_rst,       // new driven by fabric in absence of phy_control
      input                        rst_rd_clk,
      input                        cq_buf_clk,    // cq clock net
      input                        cqn_buf_clk,   // cq_n clock net

      output wire                  pi_fine_overflow,
      output wire [5:0]            pi_counter_read_val,
      output [255:0]               dbg_byte_lane
);

localparam  PHASER_INDEX =
                      (ABCD=="B" ? 1 : (ABCD == "C") ? 2 : (ABCD == "D" ? 3 : 0));
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
localparam   L_OF_ARRAY_MODE =
              (OF_ARRAY_MODE != "UNDECLARED") ? OF_ARRAY_MODE : 
			  (DATA_CTL_N == 0 || PC_CLK_RATIO == 2) ?   "ARRAY_MODE_4_X_4" : "ARRAY_MODE_8_X_4";
			  //(PC_CLK_RATIO == 2) ? "ARRAY_MODE_4_X_4" : "ARRAY_MODE_8_X_4";
localparam   L_OSERDES_DATA_RATE  = (DATA_CTL_N == 0 && 
                                     PC_CLK_RATIO == 4)  ? "SDR" : "DDR" ;

localparam   L_IF_ARRAY_MODE = (IF_ARRAY_MODE != "UNDECLARED") ? IF_ARRAY_MODE :  
                                 (PC_CLK_RATIO == 2) ? "ARRAY_MODE_4_X_4" : "ARRAY_MODE_4_X_8";
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Phaser OUT attributes
localparam L_PO_DATA_CTL_N = (DATA_CTL_N == 0 && 
                              PC_CLK_RATIO == 4) ? "FALSE" : "TRUE";

// For the PHASER_OUT used for routing CQ#, OUTPUT_CLK_SRC is set to "DELAYED_PHASE_REF"
localparam   L_PO_OUTPUT_CLK_SRC    = ((BYTE_GROUP_TYPE == "IN") && (MEMORY_TYPE == "SRAM"))? "DELAYED_PHASE_REF" : "DELAYED_REF";

// for PHASER_OUTs used for routing CQ#, coarse delay of PHASER_OUT is bypassed.

localparam   L_PO_COARSE_BYPASS         = ((BYTE_GROUP_TYPE == "IN") && (MEMORY_TYPE == "QDR2PLUS")) ?  "TRUE" : 
                                           ((BYTE_GROUP_TYPE == "OUT") && (PO_COARSE_BYPASS == "TRUE") &&  (MEMORY_TYPE == "QDR2PLUS")) ?  "TRUE" : "FALSE";


localparam  L_PO_FINE_DELAY = ((BYTE_GROUP_TYPE == "OUT")  && PO_COARSE_BYPASS == "TRUE" ) ?  0 : PO_FINE_DELAY;
localparam WAIT_CNT_VAL = 4'b1111;

localparam ODELAY_TAP_RES          = 1/(32.0 * 2 * REFCLK_FREQ)*1000000;
localparam ODELAY_90_SHIFT_RAW     = (CLK_PERIOD/4)/ODELAY_TAP_RES;
//make sure our calculation doesn't overflow
localparam ODELAY_90_SHIFT         = (ODELAY_90_SHIFT_RAW > 31) ? 31 : 
                                                           ODELAY_90_SHIFT_RAW;
localparam OUTPUT_CLK_ODELAY_VALUE = (BUFG_FOR_OUTPUTS == "ON") ? 
                                                           ODELAY_90_SHIFT : 0;
														   
localparam PO_DCD_CORRECTION    = "ON";
localparam [2:0] PO_DCD_SETTING = (PO_DCD_CORRECTION == "ON") ? 3'b111 : 3'b000;

wire [3:0]      of_q9;
wire [3:0]      of_q8;
wire [3:0]      of_q7;
wire [7:0]      of_q6;
wire [7:0]      of_q5;
wire [3:0]      of_q4;
wire [3:0]      of_q3;
wire [3:0]      of_q2;
wire [3:0]      of_q1;
wire [3:0]      of_q0;
wire [7:0]      of_d9;
wire [7:0]      of_d8;
wire [7:0]      of_d7;
wire [7:0]      of_d6;
wire [7:0]      of_d5;
wire [7:0]      of_d4;
wire [7:0]      of_d3;
wire [7:0]      of_d2;
wire [7:0]      of_d1;
wire [7:0]      of_d0;
                
wire [7:0]      if_q9;
wire [7:0]      if_q8;
wire [7:0]      if_q7;
wire [7:0]      if_q6;
wire [7:0]      if_q5;
wire [7:0]      if_q4;
wire [7:0]      if_q3;
wire [7:0]      if_q2;
wire [7:0]      if_q1;
wire [7:0]      if_q0;
                
wire [3:0]      if_d9;
wire [3:0]      if_d8;
wire [3:0]      if_d7;
wire [7:0]      if_d6;
wire [7:0]      if_d5;
wire [3:0]      if_d4;
wire [3:0]      if_d3;
wire [3:0]      if_d2;
wire [3:0]      if_d1;
wire [3:0]      if_d0;
                
wire [3:0]      dummy_i5;
wire [3:0]      dummy_i6;
wire [3:0]      dummy_if_q;

wire [1:0]      oserdes_dqts_in;
wire [48-1:0]   of_dbus;
wire [12*4-1:0] iserdes_dout;

wire             phy_wr_en = ( DATA_CTL_N == 0 ) ? phy_cmd_wr_en  : phy_data_wr_en;
wire             phaseref_clk_cq  = (BYTE_GROUP_TYPE == "IN" || 
                                     BYTE_GROUP_TYPE == "BIDIR") ? cq_buf_clk : 1'b0;   
wire             phaseref_clk_cqn = (BYTE_GROUP_TYPE == "IN" ||
                                     BYTE_GROUP_TYPE == "BIDIR") ? cqn_buf_clk : 1'b0;   
wire             if_empty_;
wire             if_a_empty_;
wire             if_full_;
wire             if_a_full_;
wire             is_rst;
wire             os_rst;
wire             oserdes_clk;
wire             iserdes_clkdiv;
wire             iserdes_clk /* synthesis syn_insert_buffer="NONE" */; 
wire             oserdes_clk_delayed;             
wire             oserdes_clk_delayed_d;
wire             oserdes_clkdiv;
reg              phaseref_clk_delayed;
wire             phaseref_clk;
wire             iserdes_clkb;
wire [1:0]       ddr_ck_out_q;
wire [1:0]       ddr_dk_out_q;
wire             ddr_clock_delayed;
wire             ddr_clock_out_sel;               
wire             po_rd_enable;
wire             of_rden;
wire             of_wren;
wire             phy_rd_en_;
wire [79:0]      rd_data;
reg  [79:0]      rd_data_r;
reg              if_empty_r;
wire             empty_post_fifo;
wire             if_wr_en;
reg  [2:0] 	     coarse_delay_cnt;
reg  [5:0]       fine_delay_cnt;
reg              po_fine_skew_delay_inc;
reg 	         po_fine_skew_delay_en;
reg              po_coarse_skew_delay_inc;
reg 	         po_coarse_skew_delay_en;
reg [3:0] 	     wait_cnt;
reg              po_fine_inc_w;
reg              po_fine_enable_w;
reg              po_coarse_enable_w;
reg              po_coarse_inc_w;
   

generate
if ( (DATA_CTL_N == 0) || 
     (BITLANES_IN == 0)) begin : if_empty_null
	assign if_empty = 0;
	assign if_a_empty = 0;
    assign if_full = 0;
    assign if_a_full = 0;
end
else begin : if_empty_gen
    assign if_empty   = empty_post_fifo;
    assign if_a_empty = if_a_empty_;
    assign if_full    = if_full_;
    assign if_a_full  = if_a_full_;
end
endgenerate        

// input path : IN_FIFO -> post_FIFO -> controller
// continuously assert the wr_en to IN_FIFO, since the fabric does not have access to the PHASER_IN.ICLKDIV
assign if_wr_en = 1'b1;

generate                                                     
   if ((BYTE_GROUP_TYPE == "IN" || BYTE_GROUP_TYPE == "BIDIR") &&  (BITLANES_IN != 0)) begin : PHASER_IN_inst
   
     `ifdef FUJI_BLH
       B_PHASER_IN #(
     `else
       PHASER_IN #(
     `endif
     //PHASER_IN #(
       .CLKOUT_DIV                       ( PI_CLKOUT_DIV),
       .EN_ISERDES_RST                   ( PI_EN_ISERDES_RST), 
       .FINE_DELAY                       ( PI_FINE_DELAY),
       .FREQ_REF_DIV                     ( PI_FREQ_REF_DIV),
       .OUTPUT_CLK_SRC                   ( PI_OUTPUT_CLK_SRC),
       .REFCLK_PERIOD                    ( PI_REFCLK_PERIOD),
       .MEMREFCLK_PERIOD                 ( MEMREFCLK_PERIOD),
       .PHASEREFCLK_PERIOD               ( MEMREFCLK_PERIOD),
       .SYNC_IN_DIV_RST                  ( PI_SYNC_IN_DIV_RST)
     ) phaser_in (
       .FINEOVERFLOW                     (pi_fine_overflow),
       .ICLKDIV                          (iserdes_clkdiv),
       .ICLK                             (iserdes_clk),
       .COUNTERREADVAL                   (pi_counter_read_val),
       .RCLK                             (),
       .FINEENABLE                       (pi_fine_enable),
       .DIVIDERST                        (1'b0),  
       .EDGEADV                          (pi_edge_adv),  
       .FREQREFCLK                       (freq_refclk),
       .MEMREFCLK                        (mem_refclk),
       .PHASEREFCLK                      (phaseref_clk_cq),
       .RANKSEL                          (2'b0), 
       .RST                              (rst_rd_clk), //sys_rst
       .ISERDESRST                       (is_rst),
       .FINEINC                          (pi_fine_inc),
       .COUNTERLOADEN                    (pi_counter_load_en),
       .COUNTERREADEN                    (pi_counter_read_en),
       .COUNTERLOADVAL                   (pi_counter_load_val),
       .SYNCIN                           (sync_pulse),
       .SYSCLK                           (phy_clk)
     );
    end
 endgenerate
 
 generate                                                     
   if ((BYTE_GROUP_TYPE == "IN") && (CPT_CLK_CQ_ONLY == "FALSE")) begin : PHASER_OUT_inst       
           
    `ifdef FUJI_BLH
       B_PHASER_OUT #(
    `else
       PHASER_OUT #(
    `endif  
   //PHASER_OUT #(
   
     .CLKOUT_DIV                        ( PO_CLKOUT_DIV),
     .COARSE_DELAY                      ( PO_COARSE_DELAY),
     .EN_OSERDES_RST                    ( PO_EN_OSERDES_RST), 
     .FINE_DELAY                        ( PI_FINE_DELAY),
     .OCLK_DELAY                        ( PO_OCLK_DELAY),
     .OCLKDELAY_INV                     ( PO_OCLKDELAY_INV),
     .OUTPUT_CLK_SRC                    ( L_PO_OUTPUT_CLK_SRC),
     .REFCLK_PERIOD                     ( PO_REFCLK_PERIOD),
     .MEMREFCLK_PERIOD                  ( MEMREFCLK_PERIOD),
     .PHASEREFCLK_PERIOD                ( MEMREFCLK_PERIOD),
     .COARSE_BYPASS                     ( L_PO_COARSE_BYPASS), 
     .SYNC_IN_DIV_RST                   ( PO_SYNC_IN_DIV_RST),
	 .PO                                ( 3'b000) //DCD correction turned OFF for CQ/CQ# capture
	                                              //to ensure latency through PO does not change
												  //compared to PI
   ) phaser_out (
     .COARSEOVERFLOW                    (po_coarse_overflow),
     .COUNTERREADVAL                    (po_counter_read_val),
     .FINEOVERFLOW                      (po_fine_overflow),
     .OCLKDIV                           (oserdes_clkdiv),
     .OCLK                              (oserdes_clk), 
     .OCLKDELAYED                       (oserdes_clk_delayed),
     .DIVIDERST                         (1'b0),  
     .EDGEADV                           (1'b0),  
     .COARSEENABLE                      (1'b0),
     .FINEENABLE                        (po_fine_enable_w),
     .FREQREFCLK                        (freq_refclk),
     .MEMREFCLK                         (mem_refclk),
     .PHASEREFCLK                       (phaseref_clk_cqn),
     .RST                               (sys_rst),
     .OSERDESRST                        (os_rst),
     .COARSEINC                         (1'b0),
     .FINEINC                           (po_fine_inc_w),
     .SELFINEOCLKDELAY                  (po_sel_fine_oclk_delay),
     .COUNTERLOADEN                     (po_counter_load_en),
     .COUNTERREADEN                     (1'b1),
     .COUNTERLOADVAL                    (po_counter_load_val),
     .SYNCIN                            (sync_pulse),
     .SYSCLK                            (phy_clk)
   );

end else if ((BYTE_GROUP_TYPE == "OUT" || BYTE_GROUP_TYPE == "BIDIR") && 
             (PRE_FIFO == "TRUE") && (BUFG_FOR_OUTPUTS == "OFF")) begin : PHASER_OUT_inst    

 `ifdef FUJI_BLH
     B_PHASER_OUT_PHY #(
 `else
     PHASER_OUT_PHY #( 
 `endif  
  .CLKOUT_DIV                        ( PO_CLKOUT_DIV),
  .DATA_CTL_N                        ( L_PO_DATA_CTL_N), //"TRUE"
  .FINE_DELAY                        ( L_PO_FINE_DELAY),
  .COARSE_DELAY                      ( PO_COARSE_DELAY),
  .OCLK_DELAY                        ( PO_OCLK_DELAY),
  .OCLKDELAY_INV                     ( PO_OCLKDELAY_INV),
  .OUTPUT_CLK_SRC                    ( L_PO_OUTPUT_CLK_SRC),
  .COARSE_BYPASS                     ( L_PO_COARSE_BYPASS),   
  
  .REFCLK_PERIOD                     ( PO_REFCLK_PERIOD),
  .MEMREFCLK_PERIOD                  ( MEMREFCLK_PERIOD),
  .PHASEREFCLK_PERIOD                ( MEMREFCLK_PERIOD),                    
  .SYNC_IN_DIV_RST                   ( PO_SYNC_IN_DIV_RST),
  .PO                                ( PO_DCD_SETTING)
) phaser_out (
  .COARSEOVERFLOW                    (po_coarse_overflow),
  .CTSBUS                            (), //oserdes_dqs_ts
  .DQSBUS                            (), //oserdes_dqs
  .DTSBUS                            (oserdes_dqts_in),
  .FINEOVERFLOW                      (po_fine_overflow),
  .OCLKDIV                           (oserdes_clkdiv),
  .OCLK                              (oserdes_clk),
  .OCLKDELAYED                       (oserdes_clk_delayed),
  .COUNTERREADVAL                    (po_counter_read_val),
  .BURSTPENDINGPHY                   (phaser_ctl_bus[MSB_BURST_PEND_PO -3 + PHASER_INDEX]),
  .ENCALIBPHY                        (2'b00), //po_en_calib),
  .RDENABLE                          (po_rd_enable),
  .FREQREFCLK                        (freq_refclk),
  .MEMREFCLK                         (mem_refclk),
  .PHASEREFCLK                       (phaseref_clk_cqn),
  .RST                               (sys_rst),
  .OSERDESRST                        (os_rst),
  .COARSEENABLE                      (po_coarse_enable_w),
  .FINEENABLE                        (po_fine_enable_w),
  .COARSEINC                         (po_coarse_inc_w),
  .FINEINC                           (po_fine_inc_w),
  .SELFINEOCLKDELAY                  (po_sel_fine_oclk_delay),
  .COUNTERLOADEN                     (po_counter_load_en),
  .COUNTERREADEN                     (po_counter_read_en),
  .COUNTERLOADVAL                    (po_counter_load_val),
  .SYNCIN                            (sync_pulse),
  .SYSCLK                            (phy_clk)
);

end else if ((BYTE_GROUP_TYPE == "OUT" || BYTE_GROUP_TYPE == "BIDIR") && 
             (PRE_FIFO != "TRUE") && (BUFG_FOR_OUTPUTS == "OFF")) begin : PHASER_OUT_inst    

`ifdef FUJI_BLH
  B_PHASER_OUT #(
`else
  PHASER_OUT #(
`endif  
//PHASER_OUT #(

  .CLKOUT_DIV                        ( PO_CLKOUT_DIV),
  .DATA_CTL_N                        ( "TRUE"), 
  .COARSE_DELAY                      ( PO_COARSE_DELAY),
  .EN_OSERDES_RST                    ( PO_EN_OSERDES_RST), 
  .FINE_DELAY                        ( L_PO_FINE_DELAY),
  .OCLK_DELAY                        ( PO_OCLK_DELAY),
  .OCLKDELAY_INV                     ( PO_OCLKDELAY_INV),
  .OUTPUT_CLK_SRC                    ( L_PO_OUTPUT_CLK_SRC),
  .REFCLK_PERIOD                     ( PO_REFCLK_PERIOD),
  .MEMREFCLK_PERIOD                  ( MEMREFCLK_PERIOD),
  .PHASEREFCLK_PERIOD                ( MEMREFCLK_PERIOD),
  .COARSE_BYPASS                     ( L_PO_COARSE_BYPASS), 
  .SYNC_IN_DIV_RST                   ( PO_SYNC_IN_DIV_RST),
  .PO                                ( PO_DCD_SETTING)
) phaser_out (
  .COARSEOVERFLOW                    (po_coarse_overflow),
  .COUNTERREADVAL                    (po_counter_read_val),
  .FINEOVERFLOW                      (po_fine_overflow),
  .OCLKDIV                           (oserdes_clkdiv),
  .OCLK                              (oserdes_clk),
  .OCLKDELAYED                       (oserdes_clk_delayed),
  .DIVIDERST                         (1'b0),
  .EDGEADV                           (1'b0),
  .COARSEENABLE                      (po_coarse_enable_w),
  .FINEENABLE                        (po_fine_enable_w),
  .FREQREFCLK                        (freq_refclk),
  .MEMREFCLK                         (mem_refclk),
  .PHASEREFCLK                       (phaseref_clk_cqn),
  .RST                               (sys_rst),
  .OSERDESRST                        (os_rst),
  .COARSEINC                         (po_coarse_inc_w),
  .FINEINC                           (po_fine_inc_w),
  .SELFINEOCLKDELAY                  (po_sel_fine_oclk_delay),
  .COUNTERLOADEN                     (po_counter_load_en),
  .COUNTERREADEN                     (1'b0),
  .COUNTERLOADVAL                    (po_counter_load_val),
  .SYNCIN                            (sync_pulse),
  .SYSCLK                            (phy_clk)
);

end else if (BUFG_FOR_OUTPUTS == "ON") begin : GEN_BYPASS_PO
  assign oserdes_clk         = phy_clk_fast;//full frequency clock from the PLL (NEW)
  assign oserdes_clkdiv      = phy_clk;
  assign oserdes_clk_delayed = phy_clk_fast;
  assign po_counter_read_val = 'b0;
  assign po_fine_overflow    = 1'b0;
  assign po_coarse_overflow  = 1'b0;
  assign os_rst              = sys_rst;
end
endgenerate

// output path: controller -> pre_fifo -> OUT_FIFO

//**********************************************************************
// Add a "pre-fifo" (actually it's a real synchronous FIFO, but the
// final implementation may be a somewhat optimized synchronous
// FIFO-like block) prior to OUT_FIFO to provide additional buffering
// in case the OUT_FIFO ever goes full during "constant synchronizer"
// operation because of write-read clock drift
//**********************************************************************

wire        of_wren_tmp;
wire [79:0] pre_fifo_dout;
wire        pre_fifo_full;  
wire        pre_fifo_rden;
wire        rst_n;

assign    rst_n = ~rst;

generate
  if (BUFG_FOR_OUTPUTS == "OFF") begin : GEN_PRE_FIFO
    mig_7series_v2_0_qdr_rld_of_pre_fifo #
      (
       .DEPTH (8),     // depth - may reduce later
       .WIDTH (80)     // width
       )
      u_qdr_rld_pre_fifo 
        (
         .clk       (phy_clk),
         .rst       (~rst_n),
         .d_out     (pre_fifo_dout),
         .wr_en_out (of_wren_tmp),
         .d_in      (phy_dout),
         .full_in   (of_full), //out_fifos_full), //of_full
         .wr_en_in  (phy_wr_en)
       );
  end
endgenerate
        
generate 
  if (PRE_FIFO == "TRUE" && BUFG_FOR_OUTPUTS == "OFF") begin : PHY_CONTROL_INST
     //assign {of_d6[7:4], of_d5[7:4], of_d9, of_d8, of_d7, of_d6[3:0], of_d5[3:0], of_d4, of_d3, of_d2, of_d1, of_d0} = pre_fifo_dout;
     assign {of_d9, of_d8, of_d7, of_d6, of_d5, of_d4, of_d3, of_d2, of_d1, of_d0} = pre_fifo_dout;
     assign of_rden = po_rd_enable;
     assign of_wren = of_wren_tmp;
     
  end else begin : NO_PHY_CONTROL_INST
        
    //assign {of_d6[7:4], of_d5[7:4], of_d9, of_d8, of_d7, of_d6[3:0], of_d5[3:0], of_d4, of_d3, of_d2, of_d1, of_d0} = phy_dout;
    assign {of_d9, of_d8, of_d7, of_d6, of_d5, of_d4, of_d3, of_d2, of_d1, of_d0} = phy_dout;
    assign of_rden = ! of_empty;
    assign of_wren = phy_wr_en;
    
  end
endgenerate


//**********************************************************************
// Model skew going to individual OUT_FIFOs - enabled only if
// TEST_MODE is define
reg skewd_ofifo_wr_enable;
reg skewd_ofifo_rd_en;
reg [7:0] skewd_of_d0;
reg [7:0] skewd_of_d1;
reg [7:0] skewd_of_d2;
reg [7:0] skewd_of_d3;
reg [7:0] skewd_of_d4;
reg [7:0] skewd_of_d5;
reg [7:0] skewd_of_d6;
reg [7:0] skewd_of_d7;
reg [7:0] skewd_of_d8;
reg [7:0] skewd_of_d9;
reg skewd_oserdes_clkdiv;       
reg skewd_oserdes_clk_delayed;
reg skewd_oserdes_clk;
reg skewd_of_phy_clk;

reg [4:0] of_incr_cntr;
reg of_update_skews;

`ifdef TEST_MODE
   int unsigned of_temp ;
   int signed of_rd_random_num;
   int signed of_wr_random_num;
   int unsigned of_rd_inc_dec_random_num;
   bit of_rd_inc; 
   parameter CLK_SKEW_MIN = qdriiplus_tb_top.CLK_SKEW_MIN;
   parameter CLK_SKEW_MAX = qdriiplus_tb_top.CLK_SKEW_MAX;
   parameter CLK_SKEW_INC_MAX = qdriiplus_tb_top.CLK_SKEW_INC_MAX;
   parameter ENABLE_SKEW  = qdriiplus_tb_top.ENABLE_SKEW ;
   parameter DATA_SKEW   =  qdriiplus_tb_top.DATA_SKEW   ; 

  initial begin
    of_incr_cntr = 5'h0;
    of_rd_inc = 1'b1;
  end   
  //initial
  always @(qdriiplus_tb_top.cal_done, of_update_skews)
  begin
     if(qdriiplus_tb_top.cal_done && of_update_skews) begin
       of_temp = $random();
       //of_rd_random_num = (of_temp % (CLK_SKEW_MAX - CLK_SKEW_MIN)) + CLK_SKEW_MIN  ; //$urandom_range(CLK_SKEW_MIN,CLK_SKEW_MAX);
       of_rd_inc_dec_random_num = (of_temp % (CLK_SKEW_INC_MAX - CLK_SKEW_MIN)) + CLK_SKEW_MIN  ; //$urandom_range(CLK_SKEW_MIN,CLK_SKEW_MAX);
       of_temp = $random();
       of_wr_random_num = 0 ; //$urandom_range(CLK_SKEW_MIN,CLK_SKEW_MAX);
       if(of_rd_random_num == CLK_SKEW_MAX) begin
         of_rd_inc = 1'b0;
       end else if(of_rd_random_num == 0) begin
         of_rd_inc = 1'b1;
       end
       if(of_rd_inc) begin
         of_rd_random_num = of_rd_random_num + of_rd_inc_dec_random_num;
       end else begin          
         of_rd_random_num = of_rd_random_num - of_rd_inc_dec_random_num;
       end
      
       if(of_rd_random_num > CLK_SKEW_MAX)
         of_rd_random_num = CLK_SKEW_MAX;
       else  if(of_rd_random_num <= 0)
         of_rd_random_num = 0;
       $display("%m @%tps: VALUE OF RD_CLK_SKEW    = %d",$time, of_rd_random_num);
     end
  end
  
  assign of_update_skews = &of_incr_cntr; 
  
  // write path
  // delay data from pre_fifo, wren and wrclk(fabric clock)
  
  // delay write clock to OUT_FIFO   
   always @(phy_clk)
   begin
     skewd_of_phy_clk <=   #(of_wr_random_num) phy_clk;
   end
  
  // delay wr_en to OUT_FIFO
   always @(skewd_of_phy_clk)
   begin
     #(ENABLE_SKEW) skewd_ofifo_wr_enable  =  of_wren; // from pre_fifo
   end
   
   // delay input write data to OUT_FIFO   
   always @(skewd_of_phy_clk)
   begin
     #(DATA_SKEW) skewd_of_d0  =  of_d0; // from pre_fifo
                  skewd_of_d1  =  of_d1;
                  skewd_of_d2  =  of_d2;
                  skewd_of_d3  =  of_d3;
                  skewd_of_d4  =  of_d4;
                  skewd_of_d5  =  of_d5;
                  skewd_of_d6  =  of_d6;
                  skewd_of_d7  =  of_d7;
                  skewd_of_d8  =  of_d8;
                  skewd_of_d9  =  of_d9;
   end
   
   
   
   // READ PATH
   // delay read enable from Phaser out phy and rdclk (oserdes_clkdiv from Phaser out Phy)
   
   // delay read clock to OUT_FIFO
   always @(oserdes_clkdiv)
   begin
     skewd_oserdes_clkdiv        <=   #(of_rd_random_num) oserdes_clkdiv;
     
   end
   
   always @(oserdes_clk)
   begin
     skewd_oserdes_clk        <=   #(of_rd_random_num) oserdes_clk;
     
   end
   
   always @(oserdes_clk_delayed)
    begin
     skewd_oserdes_clk_delayed        <=   #(of_rd_random_num) oserdes_clk_delayed;
     
   end
   
   
   
   // delay rd_en to OUT_FIFO
   always @(skewd_oserdes_clkdiv)
   begin
     # (ENABLE_SKEW) skewd_ofifo_rd_en  =  of_rden; 
     of_incr_cntr = of_incr_cntr + 1'b1;
   end

`else
   always @(*)
   begin
     skewd_oserdes_clkdiv = oserdes_clkdiv;
     skewd_oserdes_clk = oserdes_clk;
     skewd_oserdes_clk_delayed = oserdes_clk_delayed;
     skewd_of_phy_clk        = phy_clk       ;
     skewd_ofifo_rd_en     = of_rden   ; //phy_rd_en;
     skewd_of_d0          = of_d0;
     skewd_of_d1          = of_d1;
     skewd_of_d2          = of_d2;
     skewd_of_d3          = of_d3;
     skewd_of_d4          = of_d4;
     skewd_of_d5          = of_d5;
     skewd_of_d6          = of_d6;
     skewd_of_d7          = of_d7;
     skewd_of_d8          = of_d8;
     skewd_of_d9          = of_d9;
     skewd_ofifo_wr_enable  = of_wren;
   end 
`endif
//**********************************************************************

generate
if  ( (BYTE_GROUP_TYPE == "OUT" || BYTE_GROUP_TYPE == "BIDIR") &&
      (BUFG_FOR_OUTPUTS == "OFF")) begin : out_fifo_inst

`ifdef FUJI_BLH
  B_OUT_FIFO #(
`else
  OUT_FIFO #(
`endif   
//OUT_FIFO #(

  .ALMOST_EMPTY_VALUE             (OF_ALMOST_EMPTY_VALUE),
  .ALMOST_FULL_VALUE              (OF_ALMOST_FULL_VALUE),
  .ARRAY_MODE                     (L_OF_ARRAY_MODE), //OF_ARRAY_MODE
  .OUTPUT_DISABLE                 (OF_OUTPUT_DISABLE),
  .SYNCHRONOUS_MODE               (OF_SYNCHRONOUS_MODE) 
  ) out_fifo (
  .ALMOSTEMPTY                    (of_a_empty),
  .ALMOSTFULL                     (of_a_full),
  .EMPTY                          (of_empty),
  .FULL                           (of_full),
  .Q0                             (of_q0),
  .Q1                             (of_q1),
  .Q2                             (of_q2),
  .Q3                             (of_q3),
  .Q4                             (of_q4),
  .Q5                             (of_q5),
  .Q6                             (of_q6),
  .Q7                             (of_q7),
  .Q8                             (of_q8),
  .Q9                             (of_q9),
  .D0                             (skewd_of_d0),
  .D1                             (skewd_of_d1),
  .D2                             (skewd_of_d2),
  .D3                             (skewd_of_d3),
  .D4                             (skewd_of_d4),
  .D5                             (skewd_of_d5),   
  .D6                             (skewd_of_d6),
  .D7                             (skewd_of_d7),
  .D8                             (skewd_of_d8),
  .D9                             (skewd_of_d9),
  .RDCLK                          (skewd_oserdes_clkdiv),
  .RDEN                           (skewd_ofifo_rd_en), 
  .RESET                          (os_rst), 
  .WRCLK                          (skewd_of_phy_clk),
  .WREN                           (skewd_ofifo_wr_enable)
);

end else begin : no_out_fifo_inst
 
    assign of_a_empty = 1'b0;
    assign of_a_full  = 1'b0;
    assign of_empty   = 1'b0;
    assign of_full    = 1'b0;
    
 end
endgenerate

// output assignments
generate
  if (BUFG_FOR_OUTPUTS == "ON") begin : GEN_BYPASS_OUT_FIFO
    //This is only supported for Div2 mode, going to Div4 We would lose some signals
	//and don't want to expand the bus for that
    assign of_dbus[48-1:0] = {skewd_of_d6[7:4], skewd_of_d5[7:4], skewd_of_d9[3:0],
	                          skewd_of_d8[3:0], skewd_of_d7[3:0], skewd_of_d6[3:0],
							  skewd_of_d5[3:0], skewd_of_d4[3:0], skewd_of_d3[3:0],
							  skewd_of_d2[3:0], skewd_of_d1[3:0], skewd_of_d0[3:0]};
  end else begin : GEN_ASSIGN_OUT_FIFO
    assign of_dbus[48-1:0] = {of_q6[7:4], of_q5[7:4], of_q9, of_q8, of_q7, of_q6[3:0], of_q5[3:0], of_q4, of_q3, of_q2, of_q1, of_q0};
  end
endgenerate


// input path : IN_FIFO -> post_FIFO -> controller

// IN_FIFO EMPTY->RDEN TIMING FIX:
// Always read from IN_FIFO - it doesn't hurt to read from an empty FIFO
// since the IN_FIFO read pointers are not incr'ed when the FIFO is empty
assign  phy_rd_en_ = 1'b1;
// Input assignments
//assign phy_din =  {if_q6[7:4], if_q5[7:4], if_q9, if_q8, if_q7, if_q6[3:0], if_q5[3:0], if_q4, if_q3, if_q2, if_q1, if_q0};
assign {if_d6[7:4], if_d5[7:4], if_d9,if_d8, if_d7, if_d6[3:0], if_d5[3:0], if_d4, if_d3, if_d2, if_d1, if_d0} = iserdes_dout;
//assign { if_d9, if_d8, if_d7, if_d6, if_d5, if_d4, if_d3, if_d2, if_d1, if_d0} = iserdes_dout;


// Model skew going to individual IN_FIFOs - enabled only if
// TEST_MODE is define
reg skewd_ififo_wr_enable;
reg skewd_phy_rd_en_;
reg [3:0] skewd_if_d0;
reg [3:0] skewd_if_d1;
reg [3:0] skewd_if_d2;
reg [3:0] skewd_if_d3;
reg [3:0] skewd_if_d4;
reg [7:0] skewd_if_d5;
reg [7:0] skewd_if_d6;
reg [3:0] skewd_if_d7;
reg [3:0] skewd_if_d8;
reg [3:0] skewd_if_d9;
reg skewd_iserdes_clkdiv;
reg skewd_iserdes_clk;
reg skewd_iserdes_clkb;
reg skewd_phy_clk;
reg [4:0] incr_cntr;
reg update_skews;

`ifdef TEST_MODE
   int unsigned temp ;
   int signed rd_random_num;
   int signed wr_random_num;
   int unsigned wr_inc_dec_random_num;
   bit wr_inc;
   //parameter CLK_SKEW_MIN = qdriiplus_tb_top.CLK_SKEW_MIN;
   //parameter CLK_SKEW_MAX = qdriiplus_tb_top.CLK_SKEW_MAX;
   //parameter ENABLE_SKEW  = qdriiplus_tb_top.ENABLE_SKEW ;
   //parameter DATA_SKEW   =  qdriiplus_tb_top.DATA_SKEW   ; 
   
    initial begin
    incr_cntr = 5'h0;
    wr_inc = 1'b1;
  end 

  //initial
  always @(qdriiplus_tb_top.cal_done, update_skews)
  begin
     if(qdriiplus_tb_top.cal_done && update_skews) begin
       temp = $random();
       //wr_random_num = (temp % (CLK_SKEW_MAX - CLK_SKEW_MIN)) + CLK_SKEW_MIN  ; //$urandom_range(CLK_SKEW_MIN,CLK_SKEW_MAX);
       wr_inc_dec_random_num = (temp % (CLK_SKEW_INC_MAX - CLK_SKEW_MIN)) + CLK_SKEW_MIN  ; //$urandom_range(CLK_SKEW_MIN,CLK_SKEW_MAX);
       temp = $random();
       rd_random_num = 0 ; //$urandom_range(CLK_SKEW_MIN,CLK_SKEW_MAX);
       if(wr_random_num == CLK_SKEW_MAX) begin
         wr_inc = 1'b0;
       end else if(wr_random_num == 0) begin
         wr_inc = 1'b1;
       end
       if(wr_inc) begin
         wr_random_num = wr_random_num + wr_inc_dec_random_num;
       end else begin          
         wr_random_num = wr_random_num - wr_inc_dec_random_num;
       end
      
       if(wr_random_num > CLK_SKEW_MAX)
         wr_random_num = CLK_SKEW_MAX;
       else  if(wr_random_num <= 0)
         wr_random_num = 0;
       $display("%m @%tps: VALUE OF WR_CLK_SKEW    = %d",$time, wr_random_num);
     end
  end
  
  assign update_skews = &incr_cntr; 
  // delay wr_en to IN_FIFO
   always @(skewd_iserdes_clkdiv)
   begin
     #(ENABLE_SKEW) skewd_ififo_wr_enable  =  if_wr_en; //ififo_wr_enable;
     incr_cntr = incr_cntr + 1'b1;
   end
   
   // delay input write data to IN_FIFO   
   always @(skewd_iserdes_clkdiv)
   begin
     #(DATA_SKEW) skewd_if_d0  =  if_d0;
             skewd_if_d1  =  if_d1;
             skewd_if_d2  =  if_d2;
             skewd_if_d3  =  if_d3;
             skewd_if_d4  =  if_d4;
             skewd_if_d5  =  if_d5;
             skewd_if_d6  =  if_d6;
             skewd_if_d7  =  if_d7;
             skewd_if_d8  =  if_d8;
             skewd_if_d9  =  if_d9;
   end
   
   // delay write clock to IN_FIFO   
   always @(iserdes_clkdiv)
   begin
     skewd_iserdes_clkdiv <=   #(wr_random_num) iserdes_clkdiv;
   end
   
    // delay write clock to IN_FIFO   
   always @(iserdes_clk)
   begin
     skewd_iserdes_clk <=   #(wr_random_num) iserdes_clk;
   end
   
    // delay write clock to IN_FIFO   
   always @(iserdes_clkb)
   begin
     skewd_iserdes_clkb <=   #(wr_random_num) iserdes_clkb;
   end
   
   // delay read clock to IN_FIFO
   always @(phy_clk)
   begin
     skewd_phy_clk        <=   #(rd_random_num) phy_clk;
   end
   
   // delay rd_en to IN_FIFO
   always @(skewd_phy_clk)
   begin
     # (ENABLE_SKEW) skewd_phy_rd_en_  =  phy_rd_en_; //phy_rd_en;
   end

`else
   always @(*)
   begin
     skewd_iserdes_clkdiv = iserdes_clkdiv;
     skewd_iserdes_clk    = iserdes_clk;
     skewd_iserdes_clkb   = iserdes_clkb;
     skewd_phy_clk        = phy_clk       ;
     skewd_phy_rd_en_     = phy_rd_en_   ; //phy_rd_en;
     skewd_if_d0          = if_d0;
     skewd_if_d1          = if_d1;
     skewd_if_d2          = if_d2;
     skewd_if_d3          = if_d3;
     skewd_if_d4          = if_d4;
     skewd_if_d5          = if_d5;
     skewd_if_d6          = if_d6;
     skewd_if_d7          = if_d7;
     skewd_if_d8          = if_d8;
     skewd_if_d9          = if_d9;
     skewd_ififo_wr_enable  = if_wr_en;
   end 
`endif

generate
 if  ( BYTE_GROUP_TYPE == "IN" || 
     (BYTE_GROUP_TYPE == "BIDIR" && BITLANES_IN != 0)) begin : in_fifo_inst

`ifdef FUJI_BLH
  B_IN_FIFO #(
`else
  IN_FIFO #(
`endif  
//IN_FIFO #(

  .ALMOST_EMPTY_VALUE                ( IF_ALMOST_EMPTY_VALUE ),
  .ALMOST_FULL_VALUE                 ( IF_ALMOST_FULL_VALUE ),
  .ARRAY_MODE                        ( L_IF_ARRAY_MODE), //IF_ARRAY_MODE
  .SYNCHRONOUS_MODE                  ( IF_SYNCHRONOUS_MODE)
) in_fifo  (
  .ALMOSTEMPTY                       (if_a_empty_),
  .ALMOSTFULL                        (if_a_full_),
  .EMPTY                             (if_empty_),
  .FULL                              (if_full_),
  .Q0                                (if_q0),
  .Q1                                (if_q1),
  .Q2                                (if_q2),
  .Q3                                (if_q3),
  .Q4                                (if_q4),
  .Q5                                (if_q5),
  .Q6                                (if_q6),
  .Q7                                (if_q7),
  .Q8                                (if_q8),
  .Q9                                (if_q9),
  //===
  .D0                                (skewd_if_d0),
  .D1                                (skewd_if_d1),
  .D2                                (skewd_if_d2),
  .D3                                (skewd_if_d3),
  .D4                                (skewd_if_d4),
  .D5                                (skewd_if_d5),
  .D6                                (skewd_if_d6),
  .D7                                (skewd_if_d7),
  .D8                                (skewd_if_d8),
  .D9                                (skewd_if_d9),
  .RDCLK                             (skewd_phy_clk),
  .RDEN                              (skewd_phy_rd_en_),
  .RESET                             (is_rst),
  .WRCLK                             (skewd_iserdes_clkdiv),
  .WREN                              (skewd_ififo_wr_enable)
  );
  
  
 end else  begin : no_in_fifo_inst
 
    assign if_a_empty_ = 1'b1;
    assign if_a_full_  = 1'b0;
    assign if_empty_   = 1'b1;
    assign if_full_    = 1'b0;
    
 end
endgenerate



generate
  if ( DATA_CTL_N == 0 ) begin : no_post_fifo
     assign phy_din =  80'h0;
  end
  else begin : post_fifo
  
     // IN_FIFO EMPTY->RDEN TIMING FIX:
     //assign rd_data =  {if_q6[7:4], if_q5[7:4], if_q9, if_q8, if_q7, if_q6[3:0], if_q5[3:0], if_q4, if_q3, if_q2, if_q1, if_q0};
     assign rd_data =  {if_q9, if_q8, if_q7, if_q6, if_q5, if_q4, if_q3, if_q2, if_q1, if_q0};
     //assign phy_din =  {if_q6[7:4], if_q5[7:4], if_q9, if_q8, if_q7, if_q6[3:0], if_q5[3:0], if_q4, if_q3, if_q2, if_q1, if_q0};
    
     always @(posedge phy_clk) begin
        rd_data_r   <= #(025) rd_data;
        if_empty_r  <= #(025) if_empty_;
     end
  
     mig_7series_v2_0_qdr_rld_if_post_fifo #
       (
        .TCQ   (TCQ),    // simulation CK->Q delay
        .DEPTH (4),     // depth - account for up to 2 cycles of skew
        .WIDTH (80)     // width
        )
       qdr_rld_if_post_fifo 
         (
          .clk       (phy_clk),
          .rst       (rst), 
          .empty_in  (if_empty_),//(if_empty_r),
          .rd_en_in  (phy_rd_en),
          .d_in      (rd_data), //rd_data_r),
          .empty_out (empty_post_fifo),
          .d_out     (phy_din)
          );
    
  end
endgenerate

generate
  if ((CPT_CLK_CQ_ONLY == "TRUE")&& (MEMORY_TYPE == "SRAM")) begin : gen_qdr_cq_only_capture
     assign iserdes_clkb = ~iserdes_clk; // use only CQ and ~CQ for data capture              
  end else begin : gen_hw_iserdes_clkb
    assign iserdes_clkb = (MEMORY_TYPE != "SRAM") ? ~iserdes_clk : oserdes_clk;
  end
endgenerate

mig_7series_v2_0_qdr_rld_byte_group_io   #
   (
   .MEMORY_TYPE              (MEMORY_TYPE),
   .BITLANES_IN              (BITLANES_IN),
   .BITLANES_OUT             (BITLANES_OUT),
   .CK_P_OUT                 (CK_P_OUT),
   .CK_VALUE_D1              (CK_VALUE_D1),
   .DATA_CTL_N               (DATA_CTL_N),
   .OSERDES_DATA_RATE        (L_OSERDES_DATA_RATE),
   .ABCD                     (ABCD),
   .BYTE_GROUP_TYPE          (BYTE_GROUP_TYPE),
   .BUFG_FOR_OUTPUTS         (BUFG_FOR_OUTPUTS),
   .IODELAY_GRP              (IODELAY_GRP),
   .IODELAY_HP_MODE          (IODELAY_HP_MODE),
   .REFCLK_FREQ              (REFCLK_FREQ),
   .ODELAY_90_SHIFT          (ODELAY_90_SHIFT)
   )
   qdr_rld_byte_group_io
   (
   .O                        ( O[BUS_WIDTH-1:0] /* obuf terminated signals to memory */),
   .I                        ( I[11:0] /* ibuf terminated signals to memory */),
   .mem_dq_ts                (mem_dq_ts),
   .phy_clk                  (phy_clk),
   .oserdes_rst              (os_rst),
   .iserdes_rst              (is_rst),
   .iserdes_q                (iserdes_dout),
   .iserdes_clk              (skewd_iserdes_clk),
   .iserdes_clkb             (skewd_iserdes_clkb),
   .iserdes_clkdiv           (skewd_iserdes_clkdiv),
   .idelay_ld                (idelay_ld),
   .idelay_ce                (idelay_ce),
   .idelay_inc               (idelay_inc),
   .idelay_cnt_in            (idelay_cnt_in),
   .idelay_cnt_out           (idelay_cnt_out),
   .oserdes_clk              (skewd_oserdes_clk),
   .oserdes_clkdiv           (skewd_oserdes_clkdiv),
   .oserdes_d                (of_dbus),
   .oserdes_dqts_in          (oserdes_dqts_in)
    );

//We can only generate one clock type per byte lane
//invalid to have both CK and DK options selected for a given byte lane

generate
  if  ( GENERATE_DDR_CK == 1) begin : gen_ddr_ck
    if (DIFF_CK == 1) begin: gen_diff_ddr_ck
      ODDR #
	  (
	   .DDR_CLK_EDGE ("SAME_EDGE")
	  )
	  ddr_ck (
        .C    (oserdes_clk),
        .R    (1'b0),
        .S    (),
        .D1   (CK_VALUE_D1),
        .D2   (~CK_VALUE_D1),
        .CE   (1'b1),
        .Q    (ddr_ck_out_q[0])
      );
	  
	  //check if we use an ODELAY
	  assign ddr_clock_out_sel = (BUFG_FOR_OUTPUTS == "OFF") ? ddr_ck_out_q[0] : 
	                                                           ddr_clock_delayed;
      
      OBUFDS ddr_ck_obuf  (.I(ddr_clock_out_sel), //ddr_ck_out_q[0]
                           .O(ddr_ck_out[0]), .OB(ddr_ck_out[1]));
      
    end else begin: gen_se_ddr_ck
      ODDR  #
	  (
	   .DDR_CLK_EDGE ("SAME_EDGE")
	  )
	  ddr_ck_p (
        .C    (oserdes_clk),
        .R    (1'b0),
        .S    (),
        .D1   (CK_VALUE_D1),
        .D2   (~CK_VALUE_D1),
        .CE   (1'b1),
        .Q    (ddr_ck_out_q[0])
      );
     
      ODDR ddr_ck_n (
        .C    (oserdes_clk),
        .R    (1'b0),
        .S    (),
        .D1   (CK_VALUE_D1),
        .D2   (~CK_VALUE_D1),
        .CE   (1'b1),
        .Q    (ddr_ck_out_q[1])
      );
      
      OBUFT ddr_ck_p_obuf (.I(ddr_ck_out_q[0]), .O(ddr_ck_out[0]), .T(1'b0) );
      OBUFT ddr_ck_n_obuf (.I(ddr_ck_out_q[1]), .O(ddr_ck_out[1]), .T(1'b0) );
    end
  end else if ( GENERATE_DDR_DK == 1) begin : gen_ddr_dk //original QDR case
    if (DIFF_DK == 1) begin: gen_diff_ddr_dk
      ODDR  #
	  (
	   .DDR_CLK_EDGE ("SAME_EDGE")
	  )ddr_dk (
        .C    (skewd_oserdes_clk_delayed), 
        .R    (1'b0),
        .S    (),
        .D1   (DK_VALUE_D1),
        .D2   (~DK_VALUE_D1),
        .CE   (1'b1),
        .Q    (ddr_dk_out_q[0])
      );
	  
	  //check if we use an ODELAY
	  assign ddr_clock_out_sel = (BUFG_FOR_OUTPUTS == "OFF") ? ddr_dk_out_q[0] : 
	                                                           ddr_clock_delayed;
      
      OBUFDS ddr_ck_obuf  (.I(ddr_clock_out_sel), //ddr_dk_out_q[0]
                           .O(ddr_ck_out[0]), .OB(ddr_ck_out[1]));
                           
    end else begin: gen_se_ddr_dk
      ODDR ddr_dk_p (
        .C    (skewd_oserdes_clk_delayed),
        .R    (1'b0),
        .S    (),
        .D1   (DK_VALUE_D1),
        .D2   (~DK_VALUE_D1),
        .CE   (1'b1),
        .Q    (ddr_dk_out_q[0])
      );
     
      ODDR ddr_dk_n (
        .C    (skewd_oserdes_clk_delayed),
        .R    (1'b0),
        .S    (),
        .D1   (~DK_VALUE_D1),
        .D2   (DK_VALUE_D1),
        .CE   (1'b1),
        .Q    (ddr_dk_out_q[1])
      );
      
      OBUFT ddr_dk_p_obuf (.I(ddr_dk_out_q[0]), .O(ddr_ck_out[0]), .T(1'b0) );
      OBUFT ddr_dk_n_obuf (.I(ddr_dk_out_q[1]), .O(ddr_ck_out[1]), .T(1'b0) );
      
    end
  end else begin : ddr_ck_null
      assign ddr_ck_out = 2'bz;
  end
endgenerate

//Generate an ODELAY for the output CK/DK clock path when using a BUFG scheme
//for now only generate a single one (assume only used for differential clocks)
//add support for QDR2+ later if needed
generate
  if (BUFG_FOR_OUTPUTS == "ON" && 
     (GENERATE_DDR_CK == 1 || GENERATE_DDR_DK == 1)) begin : GEN_CLOCK_ODELAY
    (* IODELAY_GROUP = IODELAY_GRP *) ODELAYE2 #(
      .CINVCTRL_SEL             ( "FALSE"),
      .DELAY_SRC                ( "ODATAIN"), //ODATAIN or CLKIN
      .HIGH_PERFORMANCE_MODE    ((IODELAY_HP_MODE=="ON") ? "TRUE": "FALSE"),
      .ODELAY_TYPE              ( "FIXED"),
      .ODELAY_VALUE             ( OUTPUT_CLK_ODELAY_VALUE ),
      .PIPE_SEL                 ( "FALSE"),
      .REFCLK_FREQUENCY         ( REFCLK_FREQ ),
      .SIGNAL_PATTERN           ( "CLOCK")
      )
      u_odelaye2
      (
      .CNTVALUEOUT              (),
      .DATAOUT                  (ddr_clock_delayed), //delayed clock
      .C                        (oserdes_clkdiv),
      .CE                       (1'b0),
      .CINVCTRL                 (1'b0),
      .CLKIN                    ( ),
	  .CNTVALUEIN               (5'b0),
      .INC                      (1'b0),
      .LD                       (1'b0),
      .LDPIPEEN                 (1'b0),
	  .ODATAIN                  ((GENERATE_DDR_CK == 1) ? ddr_ck_out_q[0] : 
	                                                      ddr_dk_out_q[0]),
      .REGRST                   (os_rst) 
  );
  end
endgenerate

   always @ (posedge phy_clk)
       begin
	 if (rst) begin
              po_fine_skew_delay_inc <= #TCQ 1'b1;
              po_fine_skew_delay_en  <= #TCQ 1'b0;  
         end else if (po_dec_done && (fine_delay_cnt != 0) && (wait_cnt == WAIT_CNT_VAL)) begin
              po_fine_skew_delay_inc <= #TCQ 1'b1;
              po_fine_skew_delay_en  <= #TCQ 1'b1;   
         end else begin
              po_fine_skew_delay_inc <= #TCQ 1'b1;
              po_fine_skew_delay_en  <= #TCQ 1'b0;   
         end
      end

  always @ (posedge phy_clk)
	 begin
	    if (rst)
	      fine_delay_cnt <= PO_FINE_SKEW_DELAY;
	    else if (po_inc_done && (fine_delay_cnt != 0) && (wait_cnt == WAIT_CNT_VAL) && PO_COARSE_BYPASS == "TRUE")
              fine_delay_cnt <= fine_delay_cnt -1;
	    else if (po_dec_done && (fine_delay_cnt != 0) && (wait_cnt == WAIT_CNT_VAL) && PO_COARSE_BYPASS == "FALSE")
              fine_delay_cnt <= fine_delay_cnt -1;

          end

  always @ (posedge phy_clk )
     begin
	 if (rst || !po_dec_done) begin
              po_coarse_skew_delay_inc <= #TCQ 1'b1;
              po_coarse_skew_delay_en  <= #TCQ 1'b0;  
         end else if ((coarse_delay_cnt != 0) && (wait_cnt == WAIT_CNT_VAL)) begin
              po_coarse_skew_delay_inc <= #TCQ 1'b1;
              po_coarse_skew_delay_en  <= #TCQ 1'b1;
         end else begin
              po_coarse_skew_delay_inc <= #TCQ 1'b1;
              po_coarse_skew_delay_en  <= #TCQ 1'b0;      
         end
      end

  always @ (posedge phy_clk)
	 begin
	    if (rst)
	      coarse_delay_cnt <= PO_COARSE_SKEW_DELAY;
	    else if (po_dec_done && (coarse_delay_cnt != 0) && (wait_cnt == WAIT_CNT_VAL)) 
              coarse_delay_cnt <= coarse_delay_cnt -1;
          end

   always @ (posedge phy_clk)
	 begin
	    if (rst)
	      wait_cnt <= 'b0;
	    else if (po_dec_done && (!po_delay_done)) 
              wait_cnt <= wait_cnt+1;
         end	      

// if an input byte group, no delay adjustment needed. FOr other bytegroups (OUT or BIDIR),
//            po_delay_done is high when all the output delays have been provided

always @ (posedge phy_clk)
	    begin
	      if (rst)
	          po_delay_done <= #TCQ 1'b0;
	      else if ((BYTE_GROUP_TYPE == "IN") && (MEMORY_TYPE == "SRAM"))
	          po_delay_done <= #TCQ 1'b1;
	      else if (BUFG_FOR_OUTPUTS == "ON")
		      po_delay_done <= #TCQ 1'b1;
	      else if  (po_dec_done && (fine_delay_cnt == 'b0) && (coarse_delay_cnt == 'b0))
	          po_delay_done <= #TCQ 1'b1;
	      else
	          po_delay_done <= #TCQ 1'b0;
	      end // always @ (posedge phy_clk)

always @ (posedge phy_clk)
	      begin
	          if (rst) begin
	             po_fine_enable_w   <= #TCQ 1'b0;
	             po_fine_inc_w      <= #TCQ 1'b1;
	             po_coarse_enable_w <= #TCQ 1'b0;
	             po_coarse_inc_w    <= #TCQ 1'b1;
	      end else if ((BYTE_GROUP_TYPE == "IN") && (MEMORY_TYPE == "QDR2PLUS" || MEMORY_TYPE == "SRAM")) begin
	             po_fine_enable_w   <= #TCQ po_fine_enable;
	             po_fine_inc_w      <= #TCQ po_fine_inc;
	             po_coarse_enable_w <= #TCQ po_coarse_enable;
	             po_coarse_inc_w    <= #TCQ po_coarse_inc;
	      end else if ((po_dec_done && !po_delay_done && (MEMORY_TYPE != "QDR2PLUS"))
	                   || (po_dec_done && !po_delay_done  && (MEMORY_TYPE == "QDR2PLUS") && PO_COARSE_BYPASS == "FALSE")
                       || (po_inc_done && !po_delay_done  && (MEMORY_TYPE == "QDR2PLUS") && PO_COARSE_BYPASS == "TRUE")) begin
	             po_fine_enable_w   <= #TCQ po_fine_skew_delay_en;
	             po_fine_inc_w      <= #TCQ po_fine_skew_delay_inc;
	             po_coarse_enable_w <= #TCQ po_coarse_skew_delay_en;
	             po_coarse_inc_w    <= #TCQ po_coarse_skew_delay_inc;
	      end else begin
	              po_fine_enable_w   <= #TCQ po_fine_enable;
	             po_fine_inc_w      <= #TCQ po_fine_inc;
	             po_coarse_enable_w <= #TCQ po_coarse_enable;
	             po_coarse_inc_w    <= #TCQ po_coarse_inc;
	      end // else: !if(po_dec_done && !po_delay_done)
	      end
	           
	      
//assign po_delay_done = ((BYTE_GROUP_TYPE == "IN") && (MEMORY_TYPE == "SRAM"))? 1'b1 :
//                            (po_dec_done && fine_delay_cnt == 'b0 && coarse_delay_cnt == 'b0)? 1'b1 : 1'b0;

/*   
assign po_fine_enable_w = ((BYTE_GROUP_TYPE == "IN") && (MEMORY_TYPE == "SRAM"))? po_fine_enable :
	      (po_dec_done && !po_delay_done)? po_fine_skew_delay_en : po_fine_enable;

assign po_fine_inc_w = ((BYTE_GROUP_TYPE == "IN") && (MEMORY_TYPE == "SRAM"))? po_fine_inc :
	      (po_dec_done && !po_delay_done)? po_fine_skew_delay_inc : po_fine_inc;

assign po_coarse_enable_w = ((BYTE_GROUP_TYPE == "IN") && (MEMORY_TYPE == "SRAM"))? po_coarse_enable :
	      (po_dec_done && !po_delay_done)? po_coarse_skew_delay_en : po_coarse_enable;

assign po_coarse_inc_w = ((BYTE_GROUP_TYPE == "IN") && (MEMORY_TYPE == "SRAM"))? po_coarse_inc :
	      (po_dec_done && !po_delay_done)? po_coarse_skew_delay_inc : po_coarse_inc;
 */
	        
  //debug signals declared for read data bank
  //tied off for outputs to ensure tools do not try to route when not needed
  assign dbg_byte_lane[0]   = (BYTE_GROUP_TYPE == "OUT") ? 1'b0 : skewd_phy_rd_en_;
  assign dbg_byte_lane[1]   = (BYTE_GROUP_TYPE == "OUT") ? 1'b0 : if_empty_;
  assign dbg_byte_lane[2]   = (BYTE_GROUP_TYPE == "OUT") ? 1'b0 : pi_fine_overflow;
  assign dbg_byte_lane[3]   = (BYTE_GROUP_TYPE == "OUT") ? 1'b0 : pi_fine_inc;       
  assign dbg_byte_lane[4]   = (BYTE_GROUP_TYPE == "OUT") ? 1'b0 : pi_fine_enable;    
  assign dbg_byte_lane[5]   = (BYTE_GROUP_TYPE == "OUT") ? 1'b0 : pi_counter_load_en;
  assign dbg_byte_lane[6]   = (BYTE_GROUP_TYPE == "OUT") ? 1'b0 : pi_counter_read_en;

endmodule 
