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
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version:
//  \   \         Application: MIG
//  /   /         Filename: qdr_rld_phy_rdlvl.v
// /___/   /\     Date Last Modified: $Date: 2011/06/02 08:36:29 $
// \   \  /  \    Date Created:
//  \___\/\___\
//
//Device: 7 Series
//Design Name: QDRII+ SRAM / RLDRAM II SDRAM
//Purpose:
//  Read leveling Stage1 calibration logic
//  NOTES:
//    1. Window detection with PRBS pattern.
//Reference:
//Revision History:	12/10/2012  -Improved CQ_CQB capturing clock scheme.  
//Revision History:  11/29/2011  Updates to support CQ/CQ# calibration .
//*****************************************************************************

/******************************************************************************
**$Id: qdr_rld_phy_rdlvl.v,v 1.1 2011/06/02 08:36:29 mishra Exp $
**$Date: 2011/06/02 08:36:29 $
**$Author: mishra $
**$Revision: 1.1 $
**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_7series_v1_3/data/dlib/7series/qdriiplus_sram/verilog/rtl/phy/qdr_rld_phy_rdlvl.v,v $
******************************************************************************/
`timescale 1ps/1ps

module mig_7series_v2_0_qdr_rld_phy_rdlvl #
   (
   parameter TCQ             = 100,    // clk->out delay (sim only)
   parameter MEMORY_IO_DIR     = "UNIDIR",
   parameter CPT_CLK_CQ_ONLY = "TRUE",
   parameter nCK_PER_CLK     = 2,      // # of memory clocks per CLK
   parameter CLK_PERIOD      = 3333,   // Internal clock period (in ps)
   parameter REFCLK_FREQ     = 300.0,          // Indicates the IDELAYCTRL reference clock frequency
   parameter DQ_WIDTH        = 64,     // # of DQ (data)
   parameter DQS_CNT_WIDTH   = 3,      // = ceil(log2(DQS_WIDTH))
   parameter DQS_WIDTH       = 8,      // # of DQS (strobe)
   parameter DRAM_WIDTH      = 8,      // # of DQ per DQS
   parameter RANKS           = 1,      // # of DRAM ranks
   parameter PI_ADJ_GAP      = 7,      // Time to wait between PI adjustments
   parameter RTR_CALIBRATION = "OFF",  // Read-Training Register Calibration
   parameter PER_BIT_DESKEW  = "ON",   // Enable per-bit DQ deskew
   parameter SIM_CAL_OPTION  = "NONE", // Skip various calibration steps
   parameter DEBUG_PORT      = "OFF"   // Enable debug port
   )
  (
   input                        clk,
   input                        rst,
   // Calibration status, control signals
   input                        rdlvl_stg1_start,
   output reg                   rdlvl_stg1_done,
   output                       rdlvl_stg1_rnk_done,
   output reg                   rdlvl_stg1_err,
   output reg                   rdlvl_prech_req,
   input                        prech_done,
   input                        rtr_cal_done,
   // Captured data in fabric clock domain
   input [2*nCK_PER_CLK*DQ_WIDTH-1:0] rd_data,
   // Stage 1 calibration outputs
   output reg                   pi_en_stg2_f,
   output reg                   pi_stg2_f_incdec,
   output reg                   pi_stg2_load,
   output reg [5:0]             pi_stg2_reg_l,
   //output [DQS_CNT_WIDTH:0]     pi_stg2_rdlvl_cnt,
   output [DQS_CNT_WIDTH-1:0]   pi_stg2_rdlvl_cnt,

   output reg                   po_en_stg2_f,   
   output reg                   po_stg2_f_incdec,
   output reg                   po_stg2_load,
   output reg [5:0]              po_stg2_reg_l,
   //output [DQS_CNT_WIDTH:0]     po_stg2_rdlvl_cnt,
   output [DQS_CNT_WIDTH-1:0]    po_stg2_rdlvl_cnt,
   
//   output reg                      idelay_ce,
//   output reg                      idelay_inc,
   // Only output if Per-bit de-skew enabled
   output reg [5*RANKS*DQ_WIDTH-1:0] dlyval_dq,
   // Debug Port
   output [5*DQS_WIDTH-1:0]     dbg_cpt_first_edge_cnt,
   output [5*DQS_WIDTH-1:0]     dbg_cpt_second_edge_cnt,
   input                        dbg_SM_en,
   input                        dbg_idel_up_all,
   input                        dbg_idel_down_all,
   input                        dbg_idel_up_cpt,
   input                        dbg_idel_down_cpt,
   input                        dbg_sel_all_idel_cpt,
   output [255:0]               dbg_phy_rdlvl
   );

  // minimum time (in IDELAY taps) for which capture data must be stable for
  // algorithm to consider a valid data eye to be found. The read leveling 
  // logic will ignore any window found smaller than this value. Limitations
  // on how small this number can be is determined by: (1) the algorithmic
  // limitation of how many taps wide the data eye can be (3 taps), and (2)
  // how wide regions of "instability" that occur around the edges of the
  // read valid window can be (i.e. need to be able to filter out "false"
  // windows that occur for a short # of taps around the edges of the true
  // data window, although with multi-sampling during read leveling, this is
  // not as much a concern) - the larger the value, the more protection 
  // against "false" windows  
  localparam MIN_EYE_SIZE = 5;
  // minimum idelay taps of valid window to be seen, to help differentiate any false positives
  // while the clock samples the uncertainty region.
  localparam MIN_Q_VALID_TAPS = 3;
  // # of clock cycles to wait after changing IDELAY value or read data MUX
  // to allow both IDELAY chain to settle, and for delayed input to
  // propagate thru ISERDES
  localparam PIPE_WAIT_CNT = 24;
  // Length of calibration sequence (in # of words)
  localparam CAL_PAT_LEN = (nCK_PER_CLK == 2) ? 4 : 8;
  // Read data shift register length
  localparam RD_SHIFT_LEN = CAL_PAT_LEN/(nCK_PER_CLK);

  // # of read data samples to examine when detecting whether an edge has 
  // occured during stage 1 calibration. Width of local param must be
  // changed as appropriate. Note that there are two counters used, each
  // counter can be changed independently of the other - they are used in
  // cascade to create a larger counter
  localparam [11:0] DETECT_EDGE_SAMPLE_CNT0 = 12'h001; //12'hFFF;
  localparam [11:0] DETECT_EDGE_SAMPLE_CNT1 = 12'h000; //12'h001;
  // # of taps in IDELAY chain. When the phase detector taps are reserved
  // before the start of calibration, reduce half that amount from the
  // total available taps.

  // clogb2 function - ceiling of log base 2
  function integer clogb2 (input integer size);
    begin
      size = size - 1;
      for (clogb2=1; size>1; clogb2=clogb2+1)
        size = size >> 1;
    end
  endfunction // clogb2
 
  localparam DQ_CNT_WIDTH   = clogb2(DQ_WIDTH);
  localparam DRAM_WIDTH_P2  = clogb2(DRAM_WIDTH-1);
  localparam DRAM_WIDTH_R2  = ( DRAM_WIDTH % 2 );
  
  localparam [5:0] CAL1_IDLE                 = 6'h00;
  localparam [5:0] CAL1_NEW_DQS_WAIT         = 6'h01;
  localparam [5:0] CAL1_STORE_FIRST_WAIT     = 6'h02;
  localparam [5:0] CAL1_DETECT_EDGE          = 6'h03;
  localparam [5:0] CAL1_IDEL_STORE_OLD       = 6'h04;
  localparam [5:0] CAL1_IDEL_INC_CPT         = 6'h05;
  localparam [5:0] CAL1_IDEL_INC_CPT_WAIT    = 6'h06;
  localparam [5:0] CAL1_CALC_IDEL            = 6'h07;
  localparam [5:0] CAL1_IDEL_DEC_CPT         = 6'h08;
  localparam [5:0] CAL1_IDEL_DEC_CPT_WAIT    = 6'h09;
  localparam [5:0] CAL1_NEXT_DQS             = 6'h0A;
  localparam [5:0] CAL1_DONE                 = 6'h0B;
  localparam [5:0] CAL1_PB_STORE_FIRST_WAIT  = 6'h0C;
  localparam [5:0] CAL1_PB_DETECT_EDGE       = 6'h0D;
  localparam [5:0] CAL1_PB_INC_CPT           = 6'h0E;
  localparam [5:0] CAL1_PB_INC_CPT_WAIT      = 6'h0F;
  localparam [5:0] CAL1_PB_DEC_CPT_LEFT      = 6'h10;
  localparam [5:0] CAL1_PB_DEC_CPT_LEFT_WAIT = 6'h11;
  localparam [5:0] CAL1_PB_DETECT_EDGE_DQ    = 6'h12;
  localparam [5:0] CAL1_PB_INC_DQ            = 6'h13;
  localparam [5:0] CAL1_PB_INC_DQ_WAIT       = 6'h14;
  localparam [5:0] CAL1_PB_DEC_CPT           = 6'h15;
  localparam [5:0] CAL1_PB_DEC_CPT_WAIT      = 6'h16;
  localparam [5:0] CAL1_DETECT_EDGE_Q        = 6'h17;
  localparam [5:0] CAL1_IDEL_INC_Q           = 6'h18;
  localparam [5:0] CAL1_IDEL_INC_Q_WAIT      = 6'h19;
  localparam [5:0] CAL1_IDEL_STORE_OLD_Q     = 6'h1A;   
  localparam [5:0] CAL1_REGL_LOAD            = 6'h1B;  
  localparam [5:0] CAL1_IDEL_DEC_Q           = 6'h1C;
  localparam [5:0] CAL1_IDEL_DEC_Q_WAIT      = 6'h1D;
  localparam [5:0] CAL1_IDEL_DEC_Q_ALL       = 6'h1E;
  localparam [5:0] CAL1_IDEL_DEC_Q_ALL_WAIT  = 6'h1F;
  localparam [5:0] CAL1_CALC_IDEL_WAIT       = 6'h20;
  localparam [5:0] CAL1_FALL_DETECT_EDGE        = 6'h21;
  localparam [5:0] CAL1_FALL_IDEL_STORE_OLD     = 6'h22;   
  localparam [5:0] CAL1_FALL_INC_CPT            = 6'h23;
  localparam [5:0] CAL1_FALL_INC_CPT_WAIT       = 6'h24;
  localparam [5:0] CAL1_FALL_CALC_DELAY         = 6'h25;
  localparam [5:0] CAL1_FALL_FINAL_DEC_TAP      = 6'h26;
  localparam [5:0] CAL1_FALL_FINAL_DEC_TAP_WAIT = 6'h27;
  localparam [5:0] CAL1_FALL_DETECT_EDGE_WAIT   = 6'h28;
  localparam [5:0] CAL1_IDEL_FALL_DEC_CPT       = 6'h29;
  localparam [5:0] CAL1_IDEL_FALL_DEC_CPT_WAIT  = 6'h30;
  localparam [5:0] CAL1_FALL_IDEL_INC_Q         = 6'h31;
  localparam [5:0] CAL1_FALL_IDEL_INC_Q_WAIT    = 6'h32;
  localparam [5:0] CAL1_FALL_IDEL_RESTORE_Q     = 6'h33;
  localparam [5:0] CAL1_FALL_IDEL_RESTORE_Q_WAIT  = 6'h34;
  
  //Work around for now, RLD3 numbers at 533MHz for simple setup using nCK_PER_CLK == 4
  localparam [5:0] SKIP_DLY_VAL    = (nCK_PER_CLK == 2) ? 6'd31 : 6'd25;//(CLK_PERIOD > 2500) ?  6'd31 : 6'd00; //edited by RA
  localparam [4:0] SKIP_DLY_VAL_DQ = (nCK_PER_CLK == 2) ? 5'd13 : (CLK_PERIOD < 1250) ? 5'd15 : 5'd2;
  
  localparam [7:0] DATA_WIDTH   = DRAM_WIDTH;
  
  //localparam [DATA_WIDTH*8-1:0] DATA_STAGE1 = 
  //                              {{DATA_WIDTH{1'b0}}, {DATA_WIDTH{1'b1}},
  //                               {DATA_WIDTH{1'b0}}, {DATA_WIDTH{1'b1}},
  //                               {DATA_WIDTH{1'b1}}, {DATA_WIDTH{1'b0}},
  //                               {DATA_WIDTH{1'b0}}, {DATA_WIDTH{1'b1}}}; 
                                 
  localparam integer IODELAY_TAP_RES  = 1000000 / (REFCLK_FREQ * 64); // IDELAY tap resolution in ps   
  
  //DIV1: MemRefClk >= 400 MHz, DIV2: 200 <= MemRefClk < 400, DIV4: MemRefClk < 200 MHz  - //DIV4 not supported  
  
  localparam PHY_FREQ_REF_MODE = CLK_PERIOD > 2500 ? "DIV2": "NONE";  

  localparam FREQ_REF_DIV = PHY_FREQ_REF_MODE == "DIV2" ? 2 : 1; 

  //FreqRefClk (MHz) is 1,2,4 times faster than MemRefClk  
  localparam real FREQ_REF_MHZ =  1.0/((CLK_PERIOD/FREQ_REF_DIV/1000.0) / 1000) ;
  
  localparam integer PHASER_TAP_RES   = 1000000 / (FREQ_REF_MHZ * 128) ;               
  
  //localparam DELAY_CENTER_MODE = CLK_DATA; //CLK_DATA - look for window by delaying clk and data, use only data taps if needed.
                                              // CLK - use data delay on the data to only align clk and data. centering is done only using Phaser taps on the clock.
                                 
                                
   // expected data could be one of the two depending on the iserdes clkdiv alignment
   
   // R0  0-1-0-1   (OR)     0-0-0-0
   // F0  1-0-1-0            1-1-1-1
   // R1  0-0-0-0            0-1-0-1
   // F1  1-1-1-1            1-0-1-0
   
  
  integer    i;
  integer    j;
  integer    k;
  integer    l;
  integer    m;
  integer    n;
  integer    r;
  integer    p;
  integer    q;
  genvar     x;
  genvar     z;
  
  reg [DQS_CNT_WIDTH:0]   cal1_cnt_cpt_r;   
  reg [DQS_CNT_WIDTH:0]   cal1_cnt_cpt_2r;               
  wire [DQS_CNT_WIDTH+2:0]cal1_cnt_cpt_timing;  
  reg                     cal1_dlyce_cpt_r;
  reg                     cal1_dlyinc_cpt_r;
  reg                     cal1_dlyce_dq_r;
  reg                     cal1_dlyinc_dq_r;
  reg                     cal1_wait_cnt_en_r;  
  reg [4:0]               cal1_wait_cnt_r;                
  reg                     cal1_wait_r;
  reg [DQ_WIDTH-1:0]      dlyce_dq_r;
  reg                     dlyinc_dq_r;  
  reg [5*DQ_WIDTH*RANKS-1:0] dlyval_dq_reg_r;
  reg                     cal1_prech_req_r;
  reg [5:0]               cal1_state_r;
  reg [5:0]               cal1_state_r1;
  reg [5:0]               cnt_idel_dec_cpt_r; // capture how many taps need to decrement down to PI's final tap position
  reg [5:0]               fall_dec_taps_r;
  reg [5:0]               cnt_rise_center_taps;
  reg [5:0]               fall_win_det_end_taps_r;
  reg [5:0]               fall_win_det_start_taps_r;
  reg                     phaser_taps_meet_fall_window;
  reg [2:0]               pi_gap_enforcer;
   
  reg [5:0]               idel_dec_cntr;
  reg [5:0]               idelay_inc_taps_r;
  reg [11:0]              idelay_tap_delay;
  wire [11:0]             idelay_tap_delay_sl_clk;
  wire [11:0]             phaser_tap_delay;
  reg [11:0]              phaser_tap_delay_sl_clk;
  reg [3:0]               cnt_shift_r;
  reg                     detect_edge_done_r;  
  reg [5:0]               first_edge_taps_r;  // first edge tap position during rising bit window
  reg                     found_edge_r;
  reg                     found_first_edge_r;
  reg                     found_second_edge_r;
  reg                     found_stable_eye_r;
  reg                     found_stable_eye_last_r;
  reg                     found_edge_all_r;
  reg [5:0]               tap_cnt_cpt_r;
  reg                     tap_limit_cpt_r;
   reg                     cqn_tap_limit_cpt_r;
  reg [4:0]               idel_tap_cnt_dq_pb_r;
  reg                     idel_tap_limit_dq_pb_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_fall0_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_fall1_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_rise0_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_rise1_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_fall2_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_fall3_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_rise2_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_rise3_r;
  reg                     new_cnt_cpt_r;
  reg [RD_SHIFT_LEN-1:0]  old_sr_fall0_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  old_sr_fall1_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  old_sr_rise0_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  old_sr_rise1_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  old_sr_fall2_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  old_sr_fall3_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  old_sr_rise2_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  old_sr_rise3_r [DRAM_WIDTH-1:0];      
  wire [3:0]               rd_window      [DRAM_WIDTH-1:0];
  wire [3:0]               fd_window      [DRAM_WIDTH-1:0]; 
  reg [DRAM_WIDTH-1:0]    rise_data_valid_r;
  reg [DRAM_WIDTH-1:0]    fall_data_valid_r;
  wire                     rise_data_valid;
  //wire                    fall_data_valid;   
  wire                    data_valid;
  
  
  reg [DRAM_WIDTH-1:0]    old_sr_match_fall0_r;
  reg [DRAM_WIDTH-1:0]    old_sr_match_fall1_r;
  reg [DRAM_WIDTH-1:0]    old_sr_match_rise0_r;
  reg [DRAM_WIDTH-1:0]    old_sr_match_rise1_r;
  reg [DRAM_WIDTH-1:0]    old_sr_match_fall2_r;
  reg [DRAM_WIDTH-1:0]    old_sr_match_fall3_r;
  reg [DRAM_WIDTH-1:0]    old_sr_match_rise2_r;
  reg [DRAM_WIDTH-1:0]    old_sr_match_rise3_r;
  reg [2:0]               pb_cnt_eye_size_r [DRAM_WIDTH-1:0];
  reg [DRAM_WIDTH-1:0]    pb_detect_edge_done_r;
  reg [DRAM_WIDTH-1:0]    pb_found_edge_last_r;  
  reg [DRAM_WIDTH-1:0]    pb_found_edge_r;
  reg [DRAM_WIDTH-1:0]    pb_found_first_edge_r;  
  reg [DRAM_WIDTH-1:0]    pb_found_stable_eye_r;
  reg [DRAM_WIDTH-1:0]    pb_last_tap_jitter_r;
  wire [RD_SHIFT_LEN-1:0] pat_fall0 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat_fall1 [3:0];
  reg [DRAM_WIDTH-1:0]    pat_match_fall0_r;
  reg                     pat_match_fall0_and_r;
  reg [DRAM_WIDTH-1:0]    pat_match_fall1_r;
  reg                     pat_match_fall1_and_r;
  reg [DRAM_WIDTH-1:0]    pat_match_fall2_r;
  reg                     pat_match_fall2_and_r;
  reg [DRAM_WIDTH-1:0]    pat_match_fall3_r;
  reg                     pat_match_fall3_and_r;
  reg [DRAM_WIDTH-1:0]    pat_match_rise0_r;
  reg                     pat_match_rise0_and_r;
  reg [DRAM_WIDTH-1:0]    pat_match_rise1_r;
  reg                     pat_match_rise1_and_r;
  reg [DRAM_WIDTH-1:0]    pat_match_rise2_r;
  reg                     pat_match_rise2_and_r;
  reg [DRAM_WIDTH-1:0]    pat_match_rise3_r;
  reg                     pat_match_rise3_and_r;
  wire [RD_SHIFT_LEN-1:0] pat_rise0 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat_rise1 [3:0];
  reg [DRAM_WIDTH-1:0]    prev_sr_diff_r;
  reg [DRAM_WIDTH-1:0]    prev_rise_sr_diff_r; 
  reg [DRAM_WIDTH-1:0]    prev_fall_sr_diff_r; 
  reg [RD_SHIFT_LEN-1:0]  prev_sr_fall0_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  prev_sr_fall1_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  prev_sr_rise0_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  prev_sr_rise1_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  prev_sr_fall2_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  prev_sr_fall3_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  prev_sr_rise2_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  prev_sr_rise3_r [DRAM_WIDTH-1:0];
  reg [DRAM_WIDTH-1:0]    prev_sr_match_cyc2_r;
  reg [DRAM_WIDTH-1:0]    prev_rise_sr_match_cyc2_r;   
  reg [DRAM_WIDTH-1:0]    prev_fall_sr_match_cyc2_r;   
  reg [DRAM_WIDTH-1:0]    prev_sr_match_fall0_r;
  reg [DRAM_WIDTH-1:0]    prev_sr_match_fall1_r;
  reg [DRAM_WIDTH-1:0]    prev_sr_match_rise0_r;
  reg [DRAM_WIDTH-1:0]    prev_sr_match_rise1_r;
  reg [DRAM_WIDTH-1:0]    prev_sr_match_fall2_r;
  reg [DRAM_WIDTH-1:0]    prev_sr_match_fall3_r;
  reg [DRAM_WIDTH-1:0]    prev_sr_match_rise2_r;
  reg [DRAM_WIDTH-1:0]    prev_sr_match_rise3_r;
  wire [RD_SHIFT_LEN-1:0] pat0_rise0 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat0_rise1 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat0_rise2 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat0_rise3 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat1_rise0 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat1_rise1 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat1_rise2 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat1_rise3 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat2_rise0 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat2_rise1 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat2_rise2 [3:0];    
  wire [RD_SHIFT_LEN-1:0] pat2_rise3 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat3_rise0 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat3_rise1 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat3_rise2 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat3_rise3 [3:0];
  reg                     pat0_data_match_r; 
  reg                     pat1_data_match_r;
  reg                     pat2_data_match_r;
  reg                     pat3_data_match_r;
  reg                     pat0_data_rise_match_r;
  reg                     pat1_data_rise_match_r;
  reg                     pat2_data_rise_match_r;
  reg                     pat3_data_rise_match_r;
  reg                     pat0_data_fall_match_r;
  reg                     pat1_data_fall_match_r;
  reg                     pat2_data_fall_match_r;
  reg                     pat3_data_fall_match_r;
  wire                    rise_match;
  wire                    fall_match;
  wire                    pat_match;
  wire [RD_SHIFT_LEN-1:0] pat0_fall0 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat0_fall1 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat0_fall2 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat0_fall3 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat1_fall0 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat1_fall1 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat1_fall2 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat1_fall3 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat2_fall0 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat2_fall1 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat2_fall2 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat2_fall3 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat3_fall0 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat3_fall1 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat3_fall2 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat3_fall3 [3:0];
  reg [DRAM_WIDTH-1:0]    pat0_match_fall0_r;
  reg                     pat0_match_fall0_and_r;
  reg [DRAM_WIDTH-1:0]    pat0_match_fall1_r;
  reg                     pat0_match_fall1_and_r;
  reg [DRAM_WIDTH-1:0]    pat0_match_fall2_r;
  reg                     pat0_match_fall2_and_r;
  reg [DRAM_WIDTH-1:0]    pat0_match_fall3_r;
  reg                     pat0_match_fall3_and_r;
  reg [DRAM_WIDTH-1:0]    pat0_match_rise0_r;
  reg                     pat0_match_rise0_and_r;
  reg [DRAM_WIDTH-1:0]    pat0_match_rise1_r;
  reg                     pat0_match_rise1_and_r;   
  reg [DRAM_WIDTH-1:0]    pat0_match_rise2_r;
  reg                     pat0_match_rise2_and_r;
  reg [DRAM_WIDTH-1:0]    pat0_match_rise3_r;
  reg                     pat0_match_rise3_and_r;
   
  reg [DRAM_WIDTH-1:0]    pat1_match_fall0_r;
  reg                     pat1_match_fall0_and_r;
  reg [DRAM_WIDTH-1:0]    pat1_match_fall1_r;
  reg                     pat1_match_fall1_and_r;
  reg [DRAM_WIDTH-1:0]    pat1_match_fall2_r;
  reg                     pat1_match_fall2_and_r;
  reg [DRAM_WIDTH-1:0]    pat1_match_fall3_r;
  reg                     pat1_match_fall3_and_r;
  reg [DRAM_WIDTH-1:0]    pat1_match_rise0_r;
  reg                     pat1_match_rise0_and_r;
  reg [DRAM_WIDTH-1:0]    pat1_match_rise1_r;
  reg                     pat1_match_rise1_and_r;
  reg [DRAM_WIDTH-1:0]    pat1_match_rise2_r;
  reg                     pat1_match_rise2_and_r;
  reg [DRAM_WIDTH-1:0]    pat1_match_rise3_r;
  reg                     pat1_match_rise3_and_r;
  
  reg [DRAM_WIDTH-1:0]    pat2_match_fall0_r;
  reg                     pat2_match_fall0_and_r;
  reg [DRAM_WIDTH-1:0]    pat2_match_fall1_r;
  reg                     pat2_match_fall1_and_r;
  reg [DRAM_WIDTH-1:0]    pat2_match_fall2_r;
  reg                     pat2_match_fall2_and_r;
  reg [DRAM_WIDTH-1:0]    pat2_match_fall3_r;
  reg                     pat2_match_fall3_and_r;
  reg [DRAM_WIDTH-1:0]    pat2_match_rise0_r;
  reg                     pat2_match_rise0_and_r;
  reg [DRAM_WIDTH-1:0]    pat2_match_rise1_r;
  reg                     pat2_match_rise1_and_r;
  reg [DRAM_WIDTH-1:0]    pat2_match_rise2_r;
  reg                     pat2_match_rise2_and_r;
  reg [DRAM_WIDTH-1:0]    pat2_match_rise3_r;
  reg                     pat2_match_rise3_and_r;
  
  reg [DRAM_WIDTH-1:0]    pat3_match_fall0_r;
  reg                     pat3_match_fall0_and_r;
  reg [DRAM_WIDTH-1:0]    pat3_match_fall1_r;
  reg                     pat3_match_fall1_and_r;
  reg [DRAM_WIDTH-1:0]    pat3_match_fall2_r;
  reg                     pat3_match_fall2_and_r;
  reg [DRAM_WIDTH-1:0]    pat3_match_fall3_r;
  reg                     pat3_match_fall3_and_r;
  reg [DRAM_WIDTH-1:0]    pat3_match_rise0_r;
  reg                     pat3_match_rise0_and_r;
  reg [DRAM_WIDTH-1:0]    pat3_match_rise1_r;
  reg                     pat3_match_rise1_and_r;
  reg [DRAM_WIDTH-1:0]    pat3_match_rise2_r;
  reg                     pat3_match_rise2_and_r;
  reg [DRAM_WIDTH-1:0]    pat3_match_rise3_r;
  reg                     pat3_match_rise3_and_r;

  reg [DQ_WIDTH-1:0]     rd_data_rise0;
  reg [DQ_WIDTH-1:0]     rd_data_fall0;
  reg [DQ_WIDTH-1:0]     rd_data_rise1;
  reg [DQ_WIDTH-1:0]     rd_data_fall1;
  reg [DQ_WIDTH-1:0]     rd_data_rise2;
  reg [DQ_WIDTH-1:0]     rd_data_fall2;
  reg [DQ_WIDTH-1:0]     rd_data_rise3;
  reg [DQ_WIDTH-1:0]     rd_data_fall3;
//  reg [4:0]               right_edge_taps_r;
  reg                     samp_cnt_done_r;
  reg                     samp_edge_cnt0_en_r;
  reg [11:0]              samp_edge_cnt0_r;
  reg                     samp_edge_cnt1_en_r;
  reg [11:0]              samp_edge_cnt1_r;
//  reg [4:0]               second_edge_dq_taps_r;
  reg [5:0]               second_edge_taps_r;
  reg [RD_SHIFT_LEN-1:0]  sr_fall0_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_fall1_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_rise0_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_rise1_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_fall2_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_fall3_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_rise2_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_rise3_r [DRAM_WIDTH-1:0];   
  /*reg [DRAM_WIDTH-1 :0]   sr0_rise0_r;      //Not used, remove
  reg [DRAM_WIDTH-1 :0]   sr0_fall0_r; 
  reg [DRAM_WIDTH-1 :0]   sr0_rise1_r; 
  reg [DRAM_WIDTH-1 :0]   sr0_fall1_r;
  reg [DRAM_WIDTH-1 :0]   sr0_rise2_r;      
  reg [DRAM_WIDTH-1 :0]   sr0_fall2_r; 
  reg [DRAM_WIDTH-1 :0]   sr0_rise3_r; 
  reg [DRAM_WIDTH-1 :0]   sr0_fall3_r;   
  reg [DRAM_WIDTH-1 :0]   sr1_rise0_r;      
  reg [DRAM_WIDTH-1 :0]   sr1_fall0_r; 
  reg [DRAM_WIDTH-1 :0]   sr1_rise1_r; 
  reg [DRAM_WIDTH-1 :0]   sr1_fall1_r;  
  reg [DRAM_WIDTH-1 :0]   sr1_rise2_r;      
  reg [DRAM_WIDTH-1 :0]   sr1_fall2_r; 
  reg [DRAM_WIDTH-1 :0]   sr1_rise3_r; 
  reg [DRAM_WIDTH-1 :0]   sr1_fall3_r; */
  
  reg                     store_sr_done_r;
  reg                     store_sr_r;
  reg                     store_sr_req_r;
  reg                     sr_valid_r;
  reg                     sr_valid_r1;
  reg                     sr_valid_r2;
  reg [DRAM_WIDTH-1:0]    old_sr_diff_r;
  reg [DRAM_WIDTH-1:0]    old_rise_sr_diff_r; 
  reg [DRAM_WIDTH-1:0]    old_fall_sr_diff_r;   
  
  reg [DRAM_WIDTH-1:0]    old_sr_match_cyc2_r;
  //reg [DRAM_WIDTH-1:0]    old_rise_sr_match_cyc2_r;
  //reg [DRAM_WIDTH-1:0]    old_fall_sr_match_cyc2_r;
  reg [6*DQS_WIDTH*RANKS-1:0] pi_rdlvl_dqs_tap_cnt_r;
  reg [6*DQS_WIDTH*RANKS-1:0] po_rdlvl_dqs_tap_cnt_r;
   
  reg [DRAM_WIDTH-1:0]    old_rise_sr_match_cyc2_r;
  reg [DRAM_WIDTH-1:0]    old_fall_sr_match_cyc2_r;
  
  reg [6*DQS_WIDTH*RANKS-1:0] rdlvl_dqs_tap_cnt_r;
  reg [1:0]               rnk_cnt_r;
  reg                     rdlvl_rank_done_r;
  
  reg [3:0]               done_cnt;
  reg [1:0]               regl_rank_cnt;
  reg [DQS_CNT_WIDTH:0]   regl_dqs_cnt;
  wire [DQS_CNT_WIDTH+2:0]regl_dqs_cnt_timing;
  reg                     regl_rank_done_r;
  
  reg [23:0] rdlvl_start_r  ;
  reg set_fall_capture_clock_at_tap0;
  /*reg rdlvl_start_2r ;
  reg rdlvl_start_3r ;
  reg rdlvl_start_4r ;
  reg rdlvl_start_5r ;
  reg rdlvl_start_6r ;
  reg rdlvl_start_7r ;
  reg rdlvl_start_8r ;
  reg rdlvl_start_9r ;
  reg rdlvl_start_10r;
  reg rdlvl_start_11r;
  reg rdlvl_start_12r;
  reg rdlvl_start_13r;
  reg rdlvl_start_14r;
  reg rdlvl_start_15r;
  reg rdlvl_start_16r;
  reg rdlvl_start_17r;
  reg rdlvl_start_18r;
  reg rdlvl_start_19r;
  reg rdlvl_start_20r;
  reg rdlvl_start_21r;
  reg rdlvl_start_22r;
  reg rdlvl_start_23r;
  reg rdlvl_start_24r;*/
  wire rdlvl_start;
  
  reg        cal1_dlyce_q_r;
  reg        cal1_dlyinc_q_r;
  reg [5:0]  idel_tap_cnt_cpt_r;
  reg [5:0]  stored_idel_tap_cnt_cpt_r;
  reg        idel_tap_limit_cpt_r;
  reg        qdly_inc_done_r;
  reg        start_win_detect;
  reg        end_win_detect;
  reg [5:0]  start_win_taps;
  reg [5:0]  end_win_taps;
  reg [5:0]  idelay_taps;
  reg        clk_in_vld_win;
  reg        idelay_ce;
  reg        idelay_inc;
  reg        idel_gt_phaser_delay;       
  reg [11:0] idel_minus_phaser_delay;
  reg [11:0] phaser_minus_idel_delay;    
  reg [5:0]  phaser_dec_taps;

  reg        cal1_dec_cnt;
  reg        rise_detect_done;
  reg        fall_first_edge_det_done;    // assert fall_first_edge_det_done if window is valid for at least some taps, 
                                           // continue to increment until edge found
(* KEEP = "TRUE" *)  reg [DQ_CNT_WIDTH:0]    rd_mux_sel_r_mult_r /* synthesis syn_keep=1 */;
(* KEEP = "TRUE" *)  reg [DQ_CNT_WIDTH:0]    rd_mux_sel_r_mult_f /* synthesis syn_keep=1 */;
  wire [DQ_CNT_WIDTH:0]   rd_mux_sel_r_p2;

  // Debug
  reg [4:0]               dbg_cpt_first_edge_taps [0:DQS_WIDTH-1];
  reg [4:0]               dbg_cpt_second_edge_taps [0:DQS_WIDTH-1];
  reg [3:0]               dbg_stg1_calc_edge;  
  reg [DQS_WIDTH-1:0]     dbg_phy_rdlvl_err;

  wire pb_detect_edge_setup;
  wire pb_detect_edge;
  //***************************************************************************
  // Debug
  //***************************************************************************

  assign dbg_phy_rdlvl[0]        = rdlvl_stg1_start;  //72
  assign dbg_phy_rdlvl[1]        = rdlvl_start;
  assign dbg_phy_rdlvl[2]        = found_edge_r;     
  assign dbg_phy_rdlvl[3]        = pat0_data_match_r;
  assign dbg_phy_rdlvl[4]        = pat1_data_match_r;
  assign dbg_phy_rdlvl[5]        = data_valid;
  assign dbg_phy_rdlvl[6]        = cal1_wait_r;
  assign dbg_phy_rdlvl[7]        = rise_match;
  assign dbg_phy_rdlvl[13:8]     = cal1_state_r[5:0]; //85:81
  assign dbg_phy_rdlvl[20:14]    = cnt_idel_dec_cpt_r;// 92:86
  assign dbg_phy_rdlvl[21]       = found_first_edge_r;
  assign dbg_phy_rdlvl[22]       = found_second_edge_r;//94
  assign dbg_phy_rdlvl[23]       = fall_match;
  assign dbg_phy_rdlvl[24]       = store_sr_r;//96
  assign dbg_phy_rdlvl[32:25]    = {sr_fall1_r[0][1:0], sr_rise1_r[0][1:0],
                                    sr_fall0_r[0][1:0], sr_rise0_r[0][1:0]};  //104:
  assign dbg_phy_rdlvl[40:33]    = {old_sr_fall1_r[0][1:0],
                                    old_sr_rise1_r[0][1:0],
                                    old_sr_fall0_r[0][1:0],
                                    old_sr_rise0_r[0][1:0]};  //  112:105
  assign dbg_phy_rdlvl[41]       = sr_valid_r;
  assign dbg_phy_rdlvl[42]       = found_stable_eye_r;
  assign dbg_phy_rdlvl[48:43]    = tap_cnt_cpt_r;             // 120:115
  assign dbg_phy_rdlvl[54:49]    = first_edge_taps_r;         //  126:121
  assign dbg_phy_rdlvl[60:55]    = second_edge_taps_r;        //132:127
  assign dbg_phy_rdlvl[64:61]    = cal1_cnt_cpt_r;            // 136:133
  assign dbg_phy_rdlvl[65]       = cal1_dlyce_cpt_r;
  assign dbg_phy_rdlvl[66]       = cal1_dlyinc_cpt_r;
  assign dbg_phy_rdlvl[67]       = rise_detect_done;
  assign dbg_phy_rdlvl[68]       = found_stable_eye_last_r;  //140
  assign dbg_phy_rdlvl[74:69]    = idelay_taps[5:0];          //146:141
  assign dbg_phy_rdlvl[80:75]    = start_win_taps[5:0];
  assign dbg_phy_rdlvl[81]       = idel_tap_limit_cpt_r;       
  assign dbg_phy_rdlvl[82]       = qdly_inc_done_r;
  assign dbg_phy_rdlvl[83]       = start_win_detect;
  assign dbg_phy_rdlvl[84]       = detect_edge_done_r;
  assign dbg_phy_rdlvl[90:85]    = idel_tap_cnt_cpt_r[5:0]; 
  assign dbg_phy_rdlvl[96:91]    = idelay_inc_taps_r[5:0];
  assign dbg_phy_rdlvl[102:97]   = idel_dec_cntr[5:0];   
  assign dbg_phy_rdlvl[103]      = tap_limit_cpt_r;   
  assign dbg_phy_rdlvl[115:104]  = idelay_tap_delay[11:0]; 
  assign dbg_phy_rdlvl[127:116]  = phaser_tap_delay[11:0]; 
  assign dbg_phy_rdlvl[128 +: 6] = fall_win_det_start_taps_r[5:0]; //398
  assign dbg_phy_rdlvl[134 +: 6] = fall_win_det_end_taps_r[5:0]; 
  assign dbg_phy_rdlvl[140 +: 24]= dbg_cpt_first_edge_cnt;   //270  410
  assign dbg_phy_rdlvl[164 +: 20]= dbg_cpt_second_edge_cnt;
  assign dbg_phy_rdlvl[187:184]  = dbg_stg1_calc_edge;
  assign dbg_phy_rdlvl[195:188]  = dbg_phy_rdlvl_err;
  assign dbg_phy_rdlvl[255:196]  = 'b0;
  
   always @(posedge clk ) begin
     //only reset if we are skipping calibration. Reset doesn't last long enough
	 //to clear these registers when we are re-starting
	 if ((SIM_CAL_OPTION == "SKIP_CAL") && rst) begin
	   rdlvl_start_r   <= #TCQ 'b0;
	 end else begin
       rdlvl_start_r[0]    <= #TCQ rdlvl_stg1_start;
	   rdlvl_start_r[23:1] <= #TCQ {rdlvl_start_r[22:1], rdlvl_start_r[0]};
	 end
   end
 
   assign rdlvl_start =  rdlvl_start_r[23];

   generate
     if (CLK_PERIOD > 2500) begin : clk_less_than_400_MHz
  
       assign idelay_tap_delay_sl_clk = { 6'h0, idelay_taps };
        
       //always @ (posedge clk) begin
       always @ (*) begin
         case (first_edge_taps_r)
           6'h 0_0 :  phaser_tap_delay_sl_clk = (0  * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 0_1 :  phaser_tap_delay_sl_clk = (1  * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 0_2 :  phaser_tap_delay_sl_clk = (2  * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 0_3 :  phaser_tap_delay_sl_clk = (3  * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 0_4 :  phaser_tap_delay_sl_clk = (4  * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 0_5 :  phaser_tap_delay_sl_clk = (5  * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 0_6 :  phaser_tap_delay_sl_clk = (6  * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 0_7 :  phaser_tap_delay_sl_clk = (7  * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 0_8 :  phaser_tap_delay_sl_clk = (8  * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 0_9 :  phaser_tap_delay_sl_clk = (9  * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 0_A :  phaser_tap_delay_sl_clk = (10 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 0_B :  phaser_tap_delay_sl_clk = (11 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 0_C :  phaser_tap_delay_sl_clk = (12 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 0_D :  phaser_tap_delay_sl_clk = (13 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 0_E :  phaser_tap_delay_sl_clk = (14 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 0_F :  phaser_tap_delay_sl_clk = (15 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 1_0 :  phaser_tap_delay_sl_clk = (16 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 1_1 :  phaser_tap_delay_sl_clk = (17 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 1_2 :  phaser_tap_delay_sl_clk = (18 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 1_3 :  phaser_tap_delay_sl_clk = (19 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 1_4 :  phaser_tap_delay_sl_clk = (20 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 1_5 :  phaser_tap_delay_sl_clk = (21 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 1_6 :  phaser_tap_delay_sl_clk = (22 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 1_7 :  phaser_tap_delay_sl_clk = (23 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 1_8 :  phaser_tap_delay_sl_clk = (24 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 1_9 :  phaser_tap_delay_sl_clk = (25 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 1_A :  phaser_tap_delay_sl_clk = (26 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 1_B :  phaser_tap_delay_sl_clk = (27 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 1_C :  phaser_tap_delay_sl_clk = (28 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 1_D :  phaser_tap_delay_sl_clk = (29 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 1_E :  phaser_tap_delay_sl_clk = (30 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 1_F :  phaser_tap_delay_sl_clk = (31 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 2_0 :  phaser_tap_delay_sl_clk = (32 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 2_1 :  phaser_tap_delay_sl_clk = (33 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 2_2 :  phaser_tap_delay_sl_clk = (34 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 2_3 :  phaser_tap_delay_sl_clk = (35 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 2_4 :  phaser_tap_delay_sl_clk = (36 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 2_5 :  phaser_tap_delay_sl_clk = (37 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 2_6 :  phaser_tap_delay_sl_clk = (38 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 2_7 :  phaser_tap_delay_sl_clk = (39 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 2_8 :  phaser_tap_delay_sl_clk = (40 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 2_9 :  phaser_tap_delay_sl_clk = (41 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 2_A :  phaser_tap_delay_sl_clk = (42 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 2_B :  phaser_tap_delay_sl_clk = (43 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 2_C :  phaser_tap_delay_sl_clk = (44 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 2_D :  phaser_tap_delay_sl_clk = (45 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 2_E :  phaser_tap_delay_sl_clk = (46 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 2_F :  phaser_tap_delay_sl_clk = (47 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 3_0 :  phaser_tap_delay_sl_clk = (48 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 3_1 :  phaser_tap_delay_sl_clk = (49 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 3_2 :  phaser_tap_delay_sl_clk = (50 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 3_3 :  phaser_tap_delay_sl_clk = (51 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 3_4 :  phaser_tap_delay_sl_clk = (52 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 3_5 :  phaser_tap_delay_sl_clk = (53 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 3_6 :  phaser_tap_delay_sl_clk = (54 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 3_7 :  phaser_tap_delay_sl_clk = (55 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 3_8 :  phaser_tap_delay_sl_clk = (56 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 3_9 :  phaser_tap_delay_sl_clk = (57 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 3_A :  phaser_tap_delay_sl_clk = (58 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 3_B :  phaser_tap_delay_sl_clk = (59 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 3_C :  phaser_tap_delay_sl_clk = (60 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 3_D :  phaser_tap_delay_sl_clk = (61 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 3_E :  phaser_tap_delay_sl_clk = (62 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           6'h 3_F :  phaser_tap_delay_sl_clk = (63 * PHASER_TAP_RES)/IODELAY_TAP_RES; 
           default :  phaser_tap_delay_sl_clk = 'b0; 
         endcase
       end
       
       always @ (posedge clk) begin 
         idel_minus_phaser_delay <=  (idelay_tap_delay_sl_clk - phaser_tap_delay_sl_clk);  
       end

     end
   endgenerate
                   
   //always @ (posedge clk) begin
   always @ (*) begin
      case (idelay_taps)
          6'h 0_0 :  idelay_tap_delay = (0   * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 0_1 :  idelay_tap_delay = (1   * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 0_2 :  idelay_tap_delay = (2   * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 0_3 :  idelay_tap_delay = (3   * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 0_4 :  idelay_tap_delay = (4   * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 0_5 :  idelay_tap_delay = (5   * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 0_6 :  idelay_tap_delay = (6   * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 0_7 :  idelay_tap_delay = (7   * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 0_8 :  idelay_tap_delay = (8   * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 0_9 :  idelay_tap_delay = (9   * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 0_A :  idelay_tap_delay = (10  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 0_B :  idelay_tap_delay = (11  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 0_C :  idelay_tap_delay = (12  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 0_D :  idelay_tap_delay = (13  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 0_E :  idelay_tap_delay = (14  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 0_F :  idelay_tap_delay = (15  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 1_0 :  idelay_tap_delay = (16  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 1_1 :  idelay_tap_delay = (17  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 1_2 :  idelay_tap_delay = (18  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 1_3 :  idelay_tap_delay = (19  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 1_4 :  idelay_tap_delay = (20  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 1_5 :  idelay_tap_delay = (21  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 1_6 :  idelay_tap_delay = (22  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 1_7 :  idelay_tap_delay = (23  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 1_8 :  idelay_tap_delay = (24  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 1_9 :  idelay_tap_delay = (25  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 1_A :  idelay_tap_delay = (26  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 1_B :  idelay_tap_delay = (27  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 1_C :  idelay_tap_delay = (28  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 1_D :  idelay_tap_delay = (29  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 1_E :  idelay_tap_delay = (30  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          6'h 1_F :  idelay_tap_delay = (31  * IODELAY_TAP_RES)/PHASER_TAP_RES; 
          default :  idelay_tap_delay = 'b0; 
      endcase
    end
    
   assign phaser_tap_delay = { 6'h0, first_edge_taps_r };                    
    
   always @ (posedge clk) begin 
     idel_gt_phaser_delay    <=  (idelay_tap_delay > phaser_tap_delay) ? 1'b1 : 1'b0;
     phaser_dec_taps         <=  (phaser_tap_delay - idelay_tap_delay)>>1;
   end 
          
          
  // assign idelay_tap_delay = idelay_taps * IODELAY_TAP_RES;  
  // assign phaser_tap_delay = first_edge_taps_r * PHASER_TAP_RES;
   assign po_stg2_rdlvl_cnt  = pi_stg2_rdlvl_cnt;
           
  //***************************************************************************
  // Debug output
  //***************************************************************************
          
  // Record first and second edges found during CPT calibration
  generate
    genvar ce_i;
    for (ce_i = 0; ce_i < DQS_WIDTH; ce_i = ce_i + 1) begin: gen_dbg_cpt_edge
      assign dbg_cpt_first_edge_cnt[(5*ce_i)+4:(5*ce_i)]
               = dbg_cpt_first_edge_taps[ce_i];
      assign dbg_cpt_second_edge_cnt[(5*ce_i)+4:(5*ce_i)]
               = dbg_cpt_second_edge_taps[ce_i];
      always @(posedge clk)
        if (rst) begin
          dbg_cpt_first_edge_taps[ce_i]  <= #TCQ 'b0;
          dbg_cpt_second_edge_taps[ce_i] <= #TCQ 'b0;
        end else begin
          // Record tap counts of first and second edge edges during
          // CPT calibration for each DQS group. If neither edge has
          // been found, then those taps will remain 0
          if (cal1_state_r == CAL1_CALC_IDEL) begin
            if (found_first_edge_r && (cal1_cnt_cpt_r == ce_i))
              dbg_cpt_first_edge_taps[ce_i]  
                <= #TCQ first_edge_taps_r;
            if (found_second_edge_r && (cal1_cnt_cpt_r == ce_i))
              dbg_cpt_second_edge_taps[ce_i] 
                <= #TCQ second_edge_taps_r;
          end
        end
    end
  endgenerate

  assign rdlvl_stg1_rnk_done = rdlvl_rank_done_r ;//|| regl_rank_done_r;
  
   //**************************************************************************
   // DQS count to hard PHY during write calibration using Phaser_OUT Stage2
   // coarse delay 
   //**************************************************************************
   assign pi_stg2_rdlvl_cnt = (cal1_state_r == CAL1_REGL_LOAD) ? regl_dqs_cnt : cal1_cnt_cpt_r;

  //***************************************************************************
  // Data mux to route appropriate bit to calibration logic - i.e. calibration
  // is done sequentially, one bit (or DQS group) at a time
  //***************************************************************************
  
//   generate
//    if (nCK_PER_CLK == 4) begin: rd_data_div4_logic_clk
//      assign rd_data_rise0 = rd_data[DQ_WIDTH-1:0];
//      assign rd_data_fall0 = rd_data[2*DQ_WIDTH-1:DQ_WIDTH];
//      assign rd_data_rise1 = rd_data[3*DQ_WIDTH-1:2*DQ_WIDTH];
//      assign rd_data_fall1 = rd_data[4*DQ_WIDTH-1:3*DQ_WIDTH];
//      assign rd_data_rise2 = rd_data[5*DQ_WIDTH-1:4*DQ_WIDTH];
//      assign rd_data_fall2 = rd_data[6*DQ_WIDTH-1:5*DQ_WIDTH];
//      assign rd_data_rise3 = rd_data[7*DQ_WIDTH-1:6*DQ_WIDTH];
//      assign rd_data_fall3 = rd_data[8*DQ_WIDTH-1:7*DQ_WIDTH];
//    end else begin: rd_data_div2_logic_clk
//      assign rd_data_rise0 = rd_data[DQ_WIDTH-1:0];
//      assign rd_data_fall0 = rd_data[2*DQ_WIDTH-1:DQ_WIDTH];
//      assign rd_data_rise1 = rd_data[3*DQ_WIDTH-1:2*DQ_WIDTH];
//      assign rd_data_fall1 = rd_data[4*DQ_WIDTH-1:3*DQ_WIDTH];
//      assign rd_data_rise2 = 'b0;   
//      assign rd_data_fall2 = 'b0;  
//      assign rd_data_rise3 = 'b0;   
//      assign rd_data_fall3 = 'b0;   
//   
//
//    end
//  endgenerate
  
  generate
    if (nCK_PER_CLK == 4) begin: rd_data_div4_logic_clk
      always @ (posedge clk) begin
         rd_data_rise0 <= #TCQ rd_data[DQ_WIDTH-1:0];
         rd_data_fall0 <= #TCQ rd_data[2*DQ_WIDTH-1:DQ_WIDTH];
         rd_data_rise1 <= #TCQ rd_data[3*DQ_WIDTH-1:2*DQ_WIDTH];
         rd_data_fall1 <= #TCQ rd_data[4*DQ_WIDTH-1:3*DQ_WIDTH];
         rd_data_rise2 <= #TCQ rd_data[5*DQ_WIDTH-1:4*DQ_WIDTH];
         rd_data_fall2 <= #TCQ rd_data[6*DQ_WIDTH-1:5*DQ_WIDTH];
         rd_data_rise3 <= #TCQ rd_data[7*DQ_WIDTH-1:6*DQ_WIDTH];
         rd_data_fall3 <= #TCQ rd_data[8*DQ_WIDTH-1:7*DQ_WIDTH];
      end
    end else begin: rd_datadiv2_logic_clk 
      always @ (posedge clk) begin 
        rd_data_rise0 <= #TCQ rd_data[DQ_WIDTH-1:0];
        rd_data_fall0 <= #TCQ rd_data[2*DQ_WIDTH-1:DQ_WIDTH];
        rd_data_rise1 <= #TCQ rd_data[3*DQ_WIDTH-1:2*DQ_WIDTH];
        rd_data_fall1 <= #TCQ rd_data[4*DQ_WIDTH-1:3*DQ_WIDTH];
        rd_data_rise2 <= #TCQ 'b0;   
        rd_data_fall2 <= #TCQ 'b0;  
        rd_data_rise3 <= #TCQ 'b0;   
        rd_data_fall3 <= #TCQ 'b0; 
      end 

    end
  endgenerate

  // Register outputs for improved timing.
  // NOTE: Will need to change when per-bit DQ deskew is supported.
  //       Currenly all bits in DQS group are checked in aggregate
  assign rd_mux_sel_r_p2 = cal1_cnt_cpt_r << DRAM_WIDTH_P2;

  always @(posedge clk) begin
    rd_mux_sel_r_mult_r <= #TCQ rd_mux_sel_r_p2 + cal1_cnt_cpt_r;
    rd_mux_sel_r_mult_f <= #TCQ rd_mux_sel_r_p2 + cal1_cnt_cpt_r;
  end

  generate
    genvar mux_i;
    for (mux_i = 0; mux_i < DRAM_WIDTH; mux_i = mux_i + 1) begin: gen_mux_rd
      always @(posedge clk) begin
        mux_rd_rise0_r[mux_i] <= #TCQ rd_data_rise0[rd_mux_sel_r_mult_r + mux_i];
        mux_rd_fall0_r[mux_i] <= #TCQ rd_data_fall0[rd_mux_sel_r_mult_f + mux_i];
        mux_rd_rise1_r[mux_i] <= #TCQ rd_data_rise1[rd_mux_sel_r_mult_r + mux_i];
        mux_rd_fall1_r[mux_i] <= #TCQ rd_data_fall1[rd_mux_sel_r_mult_f + mux_i];
        mux_rd_rise2_r[mux_i] <= #TCQ rd_data_rise2[rd_mux_sel_r_mult_r + mux_i];
        mux_rd_fall2_r[mux_i] <= #TCQ rd_data_fall2[rd_mux_sel_r_mult_f + mux_i];
        mux_rd_rise3_r[mux_i] <= #TCQ rd_data_rise3[rd_mux_sel_r_mult_r + mux_i];
        mux_rd_fall3_r[mux_i] <= #TCQ rd_data_fall3[rd_mux_sel_r_mult_f + mux_i];
      end
    end
  endgenerate

  //***************************************************************************
  // Demultiplexor to control Phaser_IN delay values
  //***************************************************************************

  // Read DQS
  always @(posedge clk) begin
    if (rst) begin
      pi_en_stg2_f     <= #TCQ 'b0;
      pi_stg2_f_incdec <= #TCQ 'b0;
      
    end else if (cal1_dlyce_cpt_r && ~rise_detect_done) begin

      if ((SIM_CAL_OPTION == "NONE") ||
          (SIM_CAL_OPTION == "FAST_WIN_DETECT")) begin 
        // Change only specified DQS
        pi_en_stg2_f     <= #TCQ 1'b1;  
        pi_stg2_f_incdec <= #TCQ cal1_dlyinc_cpt_r;
       
      
      end else if (SIM_CAL_OPTION == "FAST_CAL") begin 
        // if simulating, and "shortcuts" for calibration enabled, apply 
        // results to all DQSs (i.e. assume same delay on all 
        // DQSs).
        pi_en_stg2_f     <= #TCQ 1'b1;
        pi_stg2_f_incdec <= #TCQ cal1_dlyinc_cpt_r;
        
      end
    end else begin
      pi_en_stg2_f     <= #TCQ 'b0;
      pi_stg2_f_incdec <= #TCQ 'b0;
     
    end
  end // always @ (posedge clk)

    // Read DQS
  always @(posedge clk) begin
    if (rst) begin
      po_en_stg2_f     <= #TCQ 'b0;
      po_stg2_f_incdec <= #TCQ 'b0;
      
    end else if (cal1_dlyce_cpt_r && rise_detect_done ) begin
      if ((SIM_CAL_OPTION == "NONE") ||
          (SIM_CAL_OPTION == "FAST_WIN_DETECT")) begin 
        // Change only specified DQS
        po_en_stg2_f     <= #TCQ 1'b1;  
        po_stg2_f_incdec <= #TCQ cal1_dlyinc_cpt_r;
       
      
      end else if (SIM_CAL_OPTION == "FAST_CAL") begin 
        // if simulating, and "shortcuts" for calibration enabled, apply 
        // results to all DQSs (i.e. assume same delay on all 
        // DQSs).
        po_en_stg2_f     <= #TCQ 1'b1;
        po_stg2_f_incdec <= #TCQ cal1_dlyinc_cpt_r;
        
      end
    end else begin
      po_en_stg2_f     <= #TCQ 'b0;
      po_stg2_f_incdec <= #TCQ 'b0;
     
    end
    //end else if (DEBUG_PORT == "ON") begin
    //  // simultaneously inc/dec all DQSs
    //  if (dbg_idel_up_all || dbg_idel_down_all || dbg_sel_all_idel_cpt) begin
    //    pi_en_stg2_f  <= #TCQ {DQS_WIDTH{dbg_idel_up_all | dbg_idel_down_all |
    //                                   dbg_idel_up_cpt | dbg_idel_down_cpt}};
    //    pi_stg2_f_incdec <= #TCQ dbg_idel_up_all | dbg_idel_up_cpt; 
    //  end else begin 
    //    // select specific DQS for adjustment
    //    pi_en_stg2_f[dbg_sel_idel_cpt]     <= #TCQ dbg_idel_up_cpt |
    //                                               dbg_idel_down_cpt;
    //    pi_stg2_f_incdec[dbg_sel_idel_cpt] <= #TCQ dbg_idel_up_cpt;
    //  end       
    //end
  end 
  
   // Read Q idelay tap
  always @(posedge clk) begin
    if (rst) begin
      idelay_ce        <= #TCQ 'b0;
      idelay_inc       <= #TCQ 'b0;
    end else if (cal1_dlyce_q_r) begin
      if ((SIM_CAL_OPTION == "NONE") ||
          (SIM_CAL_OPTION == "FAST_WIN_DETECT")) begin 
        // Change only specified DQS
        idelay_ce        <= #TCQ 1'b1;
        idelay_inc       <= #TCQ cal1_dlyinc_q_r;
      
      end else if (SIM_CAL_OPTION == "FAST_CAL") begin 
        // if simulating, and "shortcuts" for calibration enabled, apply 
        // results to all DQSs (i.e. assume same delay on all 
        // DQSs).
        idelay_ce        <= #TCQ cal1_dlyce_q_r;
        idelay_inc       <= #TCQ cal1_dlyinc_q_r;
      end
    end else begin
      
      idelay_ce        <= #TCQ 'b0;
      idelay_inc       <= #TCQ 'b0;
    end
  end
  
   // This counter used to implement settling time between
   // Phaser_IN rank register loads to different DQSs
   always @(posedge clk) begin
     if (rst)
       done_cnt <= #TCQ 'b0;
     else if (  ((cal1_state_r == CAL1_REGL_LOAD) && (cal1_state_r1 == CAL1_IDLE) && (SIM_CAL_OPTION == "SKIP_CAL")) ||  
                ((cal1_state_r == CAL1_REGL_LOAD) && (cal1_state_r1 == CAL1_NEXT_DQS) && (SIM_CAL_OPTION != "SKIP_CAL")) || 
                ((done_cnt == 4'd1) && (cal1_state_r != CAL1_DONE))  )
       done_cnt <= #TCQ 4'b1010;
     else if (done_cnt > 'b0)
       done_cnt <= #TCQ done_cnt - 1;
   end

   // During rank register loading the rank count must be sent to
   // Phaser_IN via the phy_ctl_wd?? If so phy_init will have to 
   // issue NOPs during rank register loading with the appropriate
   // rank count
   always @(posedge clk) begin
     if (rst || (regl_rank_done_r == 1'b1))
       regl_rank_done_r <= #TCQ 1'b0;
     else if ((regl_dqs_cnt == DQS_WIDTH-1) &&
              (regl_rank_cnt != RANKS-1) &&
              (done_cnt == 4'd1))
       regl_rank_done_r <= #TCQ 1'b1;
   end
   
   // Temp wire for timing.
   // The following in the always block below causes timing issues
   // due to DSP block inference
   // 6*regl_dqs_cnt.
   // replacing this with two left shifts + 1 left shift to avoid
   // DSP multiplier. 
   assign regl_dqs_cnt_timing = {2'd0, regl_dqs_cnt};
   
   // Load Phaser_OUT rank register with rdlvl delay value
   // for each DQS per rank.
   always @(posedge clk) begin
     if (rst || (done_cnt == 4'd0)) begin
       pi_stg2_load    <= #TCQ 'b0;
       pi_stg2_reg_l   <= #TCQ 'b0;
     end else if ((cal1_state_r == CAL1_REGL_LOAD) && 
                  (regl_dqs_cnt <= DQS_WIDTH-1) && (done_cnt == 4'd1)) begin
       pi_stg2_load  <= #TCQ 'b1;
       pi_stg2_reg_l <= #TCQ 
         pi_rdlvl_dqs_tap_cnt_r[(((regl_dqs_cnt_timing<<2) + (regl_dqs_cnt_timing<<1))
         +(rnk_cnt_r*DQS_WIDTH*6))+:6];
     end else begin
       pi_stg2_load  <= #TCQ 'b0;
       pi_stg2_reg_l <= #TCQ 'b0;
     end
   end

      // Load Phaser_OUT rank register with rdlvl delay value
   // for each DQS per rank.
   always @(posedge clk) begin
     if (rst || (done_cnt == 4'd0)) begin
       po_stg2_load    <= #TCQ 'b0;
       po_stg2_reg_l   <= #TCQ 'b0;
     end else if ((cal1_state_r == CAL1_REGL_LOAD) && 
                  (regl_dqs_cnt <= DQS_WIDTH-1) && (done_cnt == 4'd1)) begin
       po_stg2_load  <= #TCQ 'b1;
       po_stg2_reg_l <= #TCQ //6'h1B;
         po_rdlvl_dqs_tap_cnt_r[(((regl_dqs_cnt_timing<<2) + (regl_dqs_cnt_timing<<1))
                         +(rnk_cnt_r*DQS_WIDTH*6))+:6];
//3;
     end else begin
       po_stg2_load  <= #TCQ 'b0;
       po_stg2_reg_l <= #TCQ 'b0;
     end
   end
 
   always @(posedge clk) begin
     if (rst || (done_cnt == 4'd0))
       regl_rank_cnt   <= #TCQ 2'b00;
     else if ((cal1_state_r == CAL1_REGL_LOAD) && 
              (regl_dqs_cnt == DQS_WIDTH-1) && (done_cnt == 4'd1)) begin
       if (regl_rank_cnt == RANKS-1)
         regl_rank_cnt  <= #TCQ regl_rank_cnt;
       else
         regl_rank_cnt <= #TCQ regl_rank_cnt + 1;
     end
   end
   
   always @(posedge clk) begin
     if (rst || (done_cnt == 4'd0))
       regl_dqs_cnt    <= #TCQ {DQS_CNT_WIDTH+1{1'b0}};
     else if ((cal1_state_r == CAL1_REGL_LOAD) && 
              (regl_dqs_cnt == DQS_WIDTH-1) && (done_cnt == 4'd1)) begin
       if (regl_rank_cnt == RANKS-1)
         regl_dqs_cnt  <= #TCQ regl_dqs_cnt;
       else
         regl_dqs_cnt  <= #TCQ 'b0;
     end else if ((cal1_state_r == CAL1_REGL_LOAD) && (regl_dqs_cnt != DQS_WIDTH-1)
                  && (done_cnt == 4'd1))
       regl_dqs_cnt  <= #TCQ regl_dqs_cnt + 1;
     else
       regl_dqs_cnt  <= #TCQ regl_dqs_cnt;
   end

  //*****************************************************************
  // DQ Stage 1 CALIBRATION INCREMENT/DECREMENT LOGIC:
  // The actual IDELAY elements for each of the DQ bits is set via the
  // DLYVAL parallel load port. However, the stage 1 calibration
  // algorithm (well most of it) only needs to increment or decrement the DQ
  // IDELAY value by 1 at any one time.
  //*****************************************************************

  // Chip-select generation for each of the individual counters tracking
  // IDELAY tap values for each DQ
  generate
    for (z = 0; z < DQS_WIDTH; z = z + 1) begin: gen_dlyce_dq
      always @(posedge clk)
        if (rst)
          dlyce_dq_r[DRAM_WIDTH*z+:DRAM_WIDTH] <= #TCQ 'b0;
        else
          if (SIM_CAL_OPTION == "SKIP_CAL")
            // If skipping calibration altogether (only for simulation), no
            // need to set DQ IODELAY values - they are hardcoded
            dlyce_dq_r[DRAM_WIDTH*z+:DRAM_WIDTH] <= #TCQ 'b0;
          else if (SIM_CAL_OPTION == "FAST_CAL")
            // If fast calibration option (simulation only) selected, DQ
            // IODELAYs across all bytes are updated simultaneously
            // (although per-bit deskew within DQS[0] is still supported)
            //dlyce_dq_r[DRAM_WIDTH*z+:DRAM_WIDTH] <= #TCQ cal1_dlyce_dq_r;
            dlyce_dq_r[DRAM_WIDTH*z+:DRAM_WIDTH] <= #TCQ {DRAM_WIDTH{idelay_ce}}; //idelay_ce;     {BW_WIDTH{PATTERN_A}}
          else if ((SIM_CAL_OPTION == "NONE") ||
                   (SIM_CAL_OPTION == "FAST_WIN_DETECT")) begin 
            if (cal1_cnt_cpt_r == z)
              dlyce_dq_r[DRAM_WIDTH*z+:DRAM_WIDTH] 
                <= #TCQ {DRAM_WIDTH{idelay_ce}}; //idelay_ce; //cal1_dlyce_dq_r;
            else
              dlyce_dq_r[DRAM_WIDTH*z+:DRAM_WIDTH] <= #TCQ 'b0;
          end
    end
  endgenerate

  // Also delay increment/decrement control to match delay on DLYCE
  always @(posedge clk)
    if (rst)
      dlyinc_dq_r <= #TCQ 1'b0;
    else
      dlyinc_dq_r <= #TCQ idelay_inc; //cal1_dlyinc_dq_r;  
  

//  // Each DQ has a counter associated with it to record current read-leveling
//  // delay value
//  always @(posedge clk)
//    // Reset or skipping calibration all together
//    if (rst | (SIM_CAL_OPTION == "SKIP_CAL")) begin
//      dlyval_dq_reg_r <= #TCQ 'b0;
//    end else if (SIM_CAL_OPTION == "FAST_CAL") begin
//      for (n = 0; n < RANKS; n = n + 1) begin: gen_dlyval_dq_reg_rnk
//        for (r = 0; r < DQ_WIDTH; r = r + 1) begin: gen_dlyval_dq_reg
//          if (dlyce_dq_r[r]) begin     
//            if (dlyinc_dq_r)
//              dlyval_dq_reg_r[((5*r)+(n*DQ_WIDTH*5))+:5] 
//              <= #TCQ dlyval_dq_reg_r[((5*r)+(n*DQ_WIDTH*5))+:5] + 1;
//            else
//              dlyval_dq_reg_r[((5*r)+(n*DQ_WIDTH*5))+:5] 
//              <= #TCQ dlyval_dq_reg_r[((5*r)+(n*DQ_WIDTH*5))+:5] - 1;
//          end
//        end
//      end
//    end else begin
//      if (dlyce_dq_r[cal1_cnt_cpt_r]) begin     
//        if (dlyinc_dq_r)
//          dlyval_dq_reg_r[((5*cal1_cnt_cpt_r)+(rnk_cnt_r*5*DQ_WIDTH))+:5] 
//          <= #TCQ 
//          dlyval_dq_reg_r[((5*cal1_cnt_cpt_r)+(rnk_cnt_r*5*DQ_WIDTH))+:5] + 1;
//        else
//          dlyval_dq_reg_r[((5*cal1_cnt_cpt_r)+(rnk_cnt_r*5*DQ_WIDTH))+:5] 
//          <= #TCQ 
//          dlyval_dq_reg_r[((5*cal1_cnt_cpt_r)+(rnk_cnt_r*5*DQ_WIDTH))+:5] - 1;
//      end
//    end


  // Each DQ has a counter associated with it to record current read-leveling
  // delay value
  always @(posedge clk)
    // Reset or skipping calibration all together
    if (rst) begin
      dlyval_dq_reg_r <= #TCQ 'b0;
        end else if (SIM_CAL_OPTION == "SKIP_CAL") begin
          dlyval_dq_reg_r <= #TCQ {5*RANKS*DQ_WIDTH{SKIP_DLY_VAL_DQ}};
    end else begin
      for (n = 0; n < RANKS; n = n + 1) begin: gen_dlyval_dq_reg_rnk
        for (r = 0; r < DQ_WIDTH; r = r + 1) begin: gen_dlyval_dq_reg
          if (dlyce_dq_r[r]) begin     
            if (dlyinc_dq_r)
              dlyval_dq_reg_r[((5*r)+(n*DQ_WIDTH*5))+:5] 
              <= #TCQ dlyval_dq_reg_r[((5*r)+(n*DQ_WIDTH*5))+:5] + 1;
            else
              dlyval_dq_reg_r[((5*r)+(n*DQ_WIDTH*5))+:5] 
              <= #TCQ dlyval_dq_reg_r[((5*r)+(n*DQ_WIDTH*5))+:5] - 1;
          end
        end
      end
    end 
    
   

  // Register for timing (help with logic placement)
        always @(posedge clk) begin 
          dlyval_dq <= #TCQ dlyval_dq_reg_r;
        end


  
  //***************************************************************************
  // Generate signal used to delay calibration state machine - used when:
  //  (1) IDELAY value changed
  //  (2) RD_MUX_SEL value changed
  // Use when a delay is necessary to give the change time to propagate
  // through the data pipeline (through IDELAY and ISERDES, and fabric
  // pipeline stages)
  //***************************************************************************

      
  // List all the stage 1 calibration wait states here.
  always @(posedge clk)
  begin
    case (cal1_state_r)
	  CAL1_NEW_DQS_WAIT,
	  CAL1_PB_STORE_FIRST_WAIT,
	  CAL1_PB_INC_CPT_WAIT,
	  CAL1_PB_DEC_CPT_LEFT_WAIT,
	  CAL1_PB_INC_DQ_WAIT,
	  CAL1_PB_DEC_CPT_WAIT,
	  CAL1_IDEL_INC_CPT_WAIT,
	  CAL1_IDEL_INC_Q_WAIT,
	  CAL1_IDEL_DEC_Q_WAIT,
	  CAL1_IDEL_DEC_Q_ALL_WAIT,
	  CAL1_CALC_IDEL_WAIT,
	  CAL1_STORE_FIRST_WAIT,
	  CAL1_FALL_IDEL_INC_Q_WAIT,
	  CAL1_FALL_IDEL_RESTORE_Q_WAIT,
	  CAL1_FALL_INC_CPT_WAIT,
	  CAL1_FALL_FINAL_DEC_TAP_WAIT: begin
	    cal1_wait_cnt_en_r <= #TCQ 1'b1;
	  end
	  default: begin
	    cal1_wait_cnt_en_r <= #TCQ 1'b0;
	  end
	endcase
  end

  always @(posedge clk)
    if (!cal1_wait_cnt_en_r) begin
      cal1_wait_cnt_r <= #TCQ 5'b00000;
      cal1_wait_r     <= #TCQ 1'b1;
    end else begin
      if (cal1_wait_cnt_r != PIPE_WAIT_CNT - 1) begin
        cal1_wait_cnt_r <= #TCQ cal1_wait_cnt_r + 1;
        cal1_wait_r     <= #TCQ 1'b1;
      end else begin
        // Need to reset to 0 to handle the case when there are two
        // different WAIT states back-to-back
        cal1_wait_cnt_r <= #TCQ 5'b00000;        
        cal1_wait_r     <= #TCQ 1'b0;
      end
    end  

  //***************************************************************************
  // generate request to PHY_INIT logic to issue precharged. Required when
  // calibration can take a long time (during which there are only constant
  // reads present on this bus). In this case need to issue perioidic
  // precharges to avoid tRAS violation. This signal must meet the following
  // requirements: (1) only transition from 0->1 when prech is first needed,
  // (2) stay at 1 and only transition 1->0 when RDLVL_PRECH_DONE asserted
  //***************************************************************************

  always @(posedge clk)
    if (rst)
      rdlvl_prech_req <= #TCQ 1'b0;
    else
      rdlvl_prech_req <= #TCQ cal1_prech_req_r;

  //***************************************************************************
  // Serial-to-parallel register to store last RDDATA_SHIFT_LEN cycles of 
  // data from ISERDES. The value of this register is also stored, so that
  // previous and current values of the ISERDES data can be compared while
  // varying the IODELAY taps to see if an "edge" of the data valid window
  // has been encountered since the last IODELAY tap adjustment 
  //***************************************************************************

  //***************************************************************************
  // Shift register to store last RDDATA_SHIFT_LEN cycles of data from ISERDES
  // NOTE: Written using discrete flops, but SRL can be used if the matching
  //   logic does the comparison sequentially, rather than parallel
  //***************************************************************************

  generate
    genvar rd_i;
    for (rd_i = 0; rd_i < DRAM_WIDTH; rd_i = rd_i + 1) begin: gen_sr
      always @(posedge clk) begin
        sr_rise0_r[rd_i] <= #TCQ {sr_rise0_r[rd_i][RD_SHIFT_LEN-2:0],
                                   mux_rd_rise0_r[rd_i]};
        sr_fall0_r[rd_i] <= #TCQ {sr_fall0_r[rd_i][RD_SHIFT_LEN-2:0],
                                   mux_rd_fall0_r[rd_i]};
        sr_rise1_r[rd_i] <= #TCQ {sr_rise1_r[rd_i][RD_SHIFT_LEN-2:0],
                                   mux_rd_rise1_r[rd_i]};
        sr_fall1_r[rd_i] <= #TCQ {sr_fall1_r[rd_i][RD_SHIFT_LEN-2:0],
                                   mux_rd_fall1_r[rd_i]};
        sr_rise2_r[rd_i] <= #TCQ {sr_rise2_r[rd_i][RD_SHIFT_LEN-2:0],
                                   mux_rd_rise2_r[rd_i]};
        sr_fall2_r[rd_i] <= #TCQ {sr_fall2_r[rd_i][RD_SHIFT_LEN-2:0],
                                   mux_rd_fall2_r[rd_i]};
        sr_rise3_r[rd_i] <= #TCQ {sr_rise3_r[rd_i][RD_SHIFT_LEN-2:0],
                                   mux_rd_rise3_r[rd_i]};
        sr_fall3_r[rd_i] <= #TCQ {sr_fall3_r[rd_i][RD_SHIFT_LEN-2:0],
                                   mux_rd_fall3_r[rd_i]};						   
								   
      
      end
    end 
  endgenerate
 
   /*generate //NOT USED, remove
    genvar rd0_i;
    for (rd0_i = 0; rd0_i < DRAM_WIDTH; rd0_i = rd0_i + 1) begin: gen_sr0
      always @(posedge clk) begin
        sr0_rise0_r[rd0_i] <= #TCQ  mux_rd_rise0_r[rd0_i];
        sr0_fall0_r[rd0_i] <= #TCQ  mux_rd_fall0_r[rd0_i];
        sr0_rise1_r[rd0_i] <= #TCQ  mux_rd_rise1_r[rd0_i];
        sr0_fall1_r[rd0_i] <= #TCQ  mux_rd_fall1_r[rd0_i];
        sr0_rise2_r[rd0_i] <= #TCQ  mux_rd_rise2_r[rd0_i];
        sr0_fall2_r[rd0_i] <= #TCQ  mux_rd_fall2_r[rd0_i];
        sr0_rise3_r[rd0_i] <= #TCQ  mux_rd_rise3_r[rd0_i];
        sr0_fall3_r[rd0_i] <= #TCQ  mux_rd_fall3_r[rd0_i];
      end
    end
  endgenerate
  
  generate
    genvar rd1_i;
    for (rd1_i = 0; rd1_i < DRAM_WIDTH; rd1_i = rd1_i + 1) begin: gen_sr1
      always @(posedge clk) begin
        sr1_rise0_r[rd1_i] <= #TCQ  sr0_rise0_r[rd1_i];
        sr1_fall0_r[rd1_i] <= #TCQ  sr0_fall0_r[rd1_i];
        sr1_rise1_r[rd1_i] <= #TCQ  sr0_rise1_r[rd1_i];
        sr1_fall1_r[rd1_i] <= #TCQ  sr0_fall1_r[rd1_i];
        sr1_rise2_r[rd1_i] <= #TCQ  sr0_rise2_r[rd1_i];
        sr1_fall2_r[rd1_i] <= #TCQ  sr0_fall2_r[rd1_i];
        sr1_rise3_r[rd1_i] <= #TCQ  sr0_rise3_r[rd1_i];
        sr1_fall3_r[rd1_i] <= #TCQ  sr0_fall3_r[rd1_i];
      end
    end
  endgenerate*/

 
  
//  assign rd_window = { sr0_rise0_r, sr0_rise1_r,  sr1_rise0_r, sr1_rise1_r};
//  assign fd_window = { sr0_fall0_r, sr0_fall1_r,  sr1_fall0_r, sr1_fall1_r};

  //*****************************************************************
  // Expected data pattern when properly aligned through bitslip
  // Based on pattern of ({rise,fall}) =
  //   0xF, 0x0, 0xA, 0x5, 0x5, 0xA, 0x9, 0x6
  // Examining only the LSb of each DQS group, pattern is =
  //   bit3: 1, 0, 1, 0, 0, 1, 1, 0
  //   bit2: 1, 0, 0, 1, 1, 0, 0, 1
  //   bit1: 1, 0, 1, 0, 0, 1, 0, 1
  //   bit0: 1, 0, 0, 1, 1, 0, 1, 0
  // Change the hard-coded pattern below accordingly as RD_SHIFT_LEN
  // and the actual training pattern contents change
  //*****************************************************************
  
  // expected data pattern : bit 3:0 for 2 clkdiv cycles is
  
  //R0 - 0000   (OR)  R0 - 0000
  //F0 - 1111         F0 - 1111
  //R1 - 0000         R1 - 0000
  //F1 - 1111         F1 - 1111
                               
  //R0 - 1111         R0 - 0000
  //F0 - 0000         F0 - 1111
  //R1 - 0000         R1 - 1111
  //F1 - 1111         F1 - 0000
  
  generate
    if (nCK_PER_CLK == 2) begin : gen_pat_div2
      assign pat0_rise0[3] = 2'b00;
      assign pat0_fall0[3] = 2'b11;
      assign pat0_rise1[3] = 2'b10;
      assign pat0_fall1[3] = 2'b01;

      assign pat0_rise0[2] = 2'b00;
      assign pat0_fall0[2] = 2'b11;
      assign pat0_rise1[2] = 2'b10;
      assign pat0_fall1[2] = 2'b01;

      assign pat0_rise0[1] = 2'b00;
      assign pat0_fall0[1] = 2'b11;
      assign pat0_rise1[1] = 2'b10;
      assign pat0_fall1[1] = 2'b01;

      assign pat0_rise0[0] = 2'b00;
      assign pat0_fall0[0] = 2'b11;
      assign pat0_rise1[0] = 2'b10;
      assign pat0_fall1[0] = 2'b01;
  
      assign pat1_rise0[3] = 2'b10;
      assign pat1_fall0[3] = 2'b01;
      assign pat1_rise1[3] = 2'b00;
      assign pat1_fall1[3] = 2'b11;
            
      assign pat1_rise0[2] = 2'b10;
      assign pat1_fall0[2] = 2'b01;
      assign pat1_rise1[2] = 2'b00;
      assign pat1_fall1[2] = 2'b11;

      assign pat1_rise0[1] = 2'b10;
      assign pat1_fall0[1] = 2'b01;
      assign pat1_rise1[1] = 2'b00;
      assign pat1_fall1[1] = 2'b11;

      assign pat1_rise0[0] = 2'b10;
      assign pat1_fall0[0] = 2'b01;
      assign pat1_rise1[0] = 2'b00;
      assign pat1_fall1[0] = 2'b11;
    end else begin : gen_pat_div4
  
      //Due to later doing bitslip our pattern can be only of 4 possabilities.
      //Just make sure we are properly set for rise/fall and using the correct edge.
      assign pat0_rise0[3] = (RTR_CALIBRATION == "ON" && !rtr_cal_done) ? 2'b00 : 2'b00;//2'b11;
      assign pat0_fall0[3] = (RTR_CALIBRATION == "ON" && !rtr_cal_done) ? 2'b11 : 2'b11;//2'b00;
      assign pat0_rise1[3] = (RTR_CALIBRATION == "ON" && !rtr_cal_done) ? 2'b00 : 2'b00;//2'b11;
      assign pat0_fall1[3] = (RTR_CALIBRATION == "ON" && !rtr_cal_done) ? 2'b11 : 2'b11;//2'b00;
      assign pat0_rise2[3] = (RTR_CALIBRATION == "ON" && !rtr_cal_done) ? 2'b00 : 2'b00;
      assign pat0_fall2[3] = (RTR_CALIBRATION == "ON" && !rtr_cal_done) ? 2'b11 : 2'b11;
      assign pat0_rise3[3] = (RTR_CALIBRATION == "ON" && !rtr_cal_done) ? 2'b00 : 2'b11;
      assign pat0_fall3[3] = (RTR_CALIBRATION == "ON" && !rtr_cal_done) ? 2'b11 : 2'b00;

      assign pat0_rise0[2] = pat0_rise0[3];
      assign pat0_fall0[2] = pat0_fall0[3];
      assign pat0_rise1[2] = pat0_rise1[3];
      assign pat0_fall1[2] = pat0_fall1[3];
      assign pat0_rise2[2] = pat0_rise2[3];
      assign pat0_fall2[2] = pat0_fall2[3];
      assign pat0_rise3[2] = pat0_rise3[3];
      assign pat0_fall3[2] = pat0_fall3[3];
  
      assign pat0_rise0[1] = pat0_rise0[3];
      assign pat0_fall0[1] = pat0_fall0[3];
      assign pat0_rise1[1] = pat0_rise1[3];
      assign pat0_fall1[1] = pat0_fall1[3];
      assign pat0_rise2[1] = pat0_rise2[3];
      assign pat0_fall2[1] = pat0_fall2[3];
      assign pat0_rise3[1] = pat0_rise3[3];
      assign pat0_fall3[1] = pat0_fall3[3];
	  
	  assign pat0_rise0[0] = pat0_rise0[3];
      assign pat0_fall0[0] = pat0_fall0[3];
      assign pat0_rise1[0] = pat0_rise1[3];
      assign pat0_fall1[0] = pat0_fall1[3];
      assign pat0_rise2[0] = pat0_rise2[3];
      assign pat0_fall2[0] = pat0_fall2[3];
      assign pat0_rise3[0] = pat0_rise3[3];
      assign pat0_fall3[0] = pat0_fall3[3];
	  
	  assign pat1_rise0[3] = 2'b11;//2'b11;
      assign pat1_fall0[3] = 2'b00;//2'b00;
      assign pat1_rise1[3] = 2'b00;//2'b11;
      assign pat1_fall1[3] = 2'b11;//2'b00;
      assign pat1_rise2[3] = 2'b00;//2'b11;
      assign pat1_fall2[3] = 2'b11;//2'b00;
      assign pat1_rise3[3] = 2'b00;//2'b00;
      assign pat1_fall3[3] = 2'b11;//2'b11;

      assign pat1_rise0[2] = pat1_rise0[3];
      assign pat1_fall0[2] = pat1_fall0[3];
      assign pat1_rise1[2] = pat1_rise1[3];
      assign pat1_fall1[2] = pat1_fall1[3];
      assign pat1_rise2[2] = pat1_rise2[3];
      assign pat1_fall2[2] = pat1_fall2[3];
      assign pat1_rise3[2] = pat1_rise3[3];
      assign pat1_fall3[2] = pat1_fall3[3];
  
      assign pat1_rise0[1] = pat1_rise0[3];
      assign pat1_fall0[1] = pat1_fall0[3];
      assign pat1_rise1[1] = pat1_rise1[3];
      assign pat1_fall1[1] = pat1_fall1[3];
      assign pat1_rise2[1] = pat1_rise2[3];
      assign pat1_fall2[1] = pat1_fall2[3];
      assign pat1_rise3[1] = pat1_rise3[3];
      assign pat1_fall3[1] = pat1_fall3[3];
	  
	  assign pat1_rise0[0] = pat1_rise0[3];
      assign pat1_fall0[0] = pat1_fall0[3];
      assign pat1_rise1[0] = pat1_rise1[3];
      assign pat1_fall1[0] = pat1_fall1[3];
      assign pat1_rise2[0] = pat1_rise2[3];
      assign pat1_fall2[0] = pat1_fall2[3];
      assign pat1_rise3[0] = pat1_rise3[3];
      assign pat1_fall3[0] = pat1_fall3[3];
	  
	  assign pat2_rise0[3] = 2'b00;//2'b00;
      assign pat2_fall0[3] = 2'b11;//2'b11;
      assign pat2_rise1[3] = 2'b11;//2'b11;
      assign pat2_fall1[3] = 2'b00;//2'b00;
      assign pat2_rise2[3] = 2'b00;//2'b11;
      assign pat2_fall2[3] = 2'b11;//2'b00;
      assign pat2_rise3[3] = 2'b00;//2'b11;
      assign pat2_fall3[3] = 2'b11;//2'b00;

      assign pat2_rise0[2] = pat2_rise0[3];
      assign pat2_fall0[2] = pat2_fall0[3];
      assign pat2_rise1[2] = pat2_rise1[3];
      assign pat2_fall1[2] = pat2_fall1[3];
      assign pat2_rise2[2] = pat2_rise2[3];
      assign pat2_fall2[2] = pat2_fall2[3];
      assign pat2_rise3[2] = pat2_rise3[3];
      assign pat2_fall3[2] = pat2_fall3[3];
  
      assign pat2_rise0[1] = pat2_rise0[3];
      assign pat2_fall0[1] = pat2_fall0[3];
      assign pat2_rise1[1] = pat2_rise1[3];
      assign pat2_fall1[1] = pat2_fall1[3];
      assign pat2_rise2[1] = pat2_rise2[3];
      assign pat2_fall2[1] = pat2_fall2[3];
      assign pat2_rise3[1] = pat2_rise3[3];
      assign pat2_fall3[1] = pat2_fall3[3];
	  
	  assign pat2_rise0[0] = pat2_rise0[3];
      assign pat2_fall0[0] = pat2_fall0[3];
      assign pat2_rise1[0] = pat2_rise1[3];
      assign pat2_fall1[0] = pat2_fall1[3];
      assign pat2_rise2[0] = pat2_rise2[3];
      assign pat2_fall2[0] = pat2_fall2[3];
      assign pat2_rise3[0] = pat2_rise3[3];
      assign pat2_fall3[0] = pat2_fall3[3];
	  
	  assign pat3_rise0[3] = 2'b00;//2'b11;
      assign pat3_fall0[3] = 2'b11;//2'b00;
      assign pat3_rise1[3] = 2'b00;//2'b00;
      assign pat3_fall1[3] = 2'b11;//2'b11;
      assign pat3_rise2[3] = 2'b11;//2'b11;
      assign pat3_fall2[3] = 2'b00;//2'b00;
      assign pat3_rise3[3] = 2'b00;//2'b11;
      assign pat3_fall3[3] = 2'b11;//2'b00;

      assign pat3_rise0[2] = pat3_rise0[3];
      assign pat3_fall0[2] = pat3_fall0[3];
      assign pat3_rise1[2] = pat3_rise1[3];
      assign pat3_fall1[2] = pat3_fall1[3];
      assign pat3_rise2[2] = pat3_rise2[3];
      assign pat3_fall2[2] = pat3_fall2[3];
      assign pat3_rise3[2] = pat3_rise3[3];
      assign pat3_fall3[2] = pat3_fall3[3];
  
      assign pat3_rise0[1] = pat3_rise0[3];
      assign pat3_fall0[1] = pat3_fall0[3];
      assign pat3_rise1[1] = pat3_rise1[3];
      assign pat3_fall1[1] = pat3_fall1[3];
      assign pat3_rise2[1] = pat3_rise2[3];
      assign pat3_fall2[1] = pat3_fall2[3];
      assign pat3_rise3[1] = pat3_rise3[3];
      assign pat3_fall3[1] = pat3_fall3[3];
	  
	  assign pat3_rise0[0] = pat3_rise0[3];
      assign pat3_fall0[0] = pat3_fall0[3];
      assign pat3_rise1[0] = pat3_rise1[3];
      assign pat3_fall1[0] = pat3_fall1[3];
      assign pat3_rise2[0] = pat3_rise2[3];
      assign pat3_fall2[0] = pat3_fall2[3];
      assign pat3_rise3[0] = pat3_rise3[3];
      assign pat3_fall3[0] = pat3_fall3[3];
	  
    end
  endgenerate
  
   generate
    genvar pt_i;
    for (pt_i = 0; pt_i < DRAM_WIDTH; pt_i = pt_i + 1) begin: gen_pat_match
      always @(posedge clk) begin
	    //Pattern 0 ------------------------------------------------------------
        if (sr_rise0_r[pt_i] == pat0_rise0[pt_i%4])
          pat0_match_rise0_r[pt_i] <= #TCQ 1'b1;
        else
          pat0_match_rise0_r[pt_i] <= #TCQ 1'b0;

        if (sr_fall0_r[pt_i] == pat0_fall0[pt_i%4])
          pat0_match_fall0_r[pt_i] <= #TCQ 1'b1;
        else
          pat0_match_fall0_r[pt_i] <= #TCQ 1'b0;

        if ((sr_rise1_r[pt_i] == pat0_rise1[pt_i%4]) || 
		    (nCK_PER_CLK == 2 && sr_rise1_r[pt_i] == pat0_fall1[pt_i%4]) )      
          pat0_match_rise1_r[pt_i] <= #TCQ 1'b1;
        else
          pat0_match_rise1_r[pt_i] <= #TCQ 1'b0;

        if ((sr_fall1_r[pt_i] == pat0_fall1[pt_i%4])  || 
		    (nCK_PER_CLK == 2 && sr_fall1_r[pt_i] == pat0_rise1[pt_i%4]))
          pat0_match_fall1_r[pt_i] <= #TCQ 1'b1;
        else
          pat0_match_fall1_r[pt_i] <= #TCQ 1'b0;
		
		//The following only used for nCK_PER_CLK == 4
		if (sr_rise2_r[pt_i] == pat0_rise2[pt_i%4])
          pat0_match_rise2_r[pt_i] <= #TCQ 1'b1;
        else
          pat0_match_rise2_r[pt_i] <= #TCQ 1'b0;
		  
		if (sr_fall2_r[pt_i] == pat0_fall2[pt_i%4])
          pat0_match_fall2_r[pt_i] <= #TCQ 1'b1;
        else
          pat0_match_fall2_r[pt_i] <= #TCQ 1'b0;
		  
		if (sr_rise3_r[pt_i] == pat0_rise3[pt_i%4])
          pat0_match_rise3_r[pt_i] <= #TCQ 1'b1;
        else
          pat0_match_rise3_r[pt_i] <= #TCQ 1'b0;
		  
		if (sr_fall3_r[pt_i] == pat0_fall3[pt_i%4])
          pat0_match_fall3_r[pt_i] <= #TCQ 1'b1;
        else
          pat0_match_fall3_r[pt_i] <= #TCQ 1'b0;
        
        //Pattern 1 ------------------------------------------------------------
        if ((sr_rise0_r[pt_i] == pat1_rise0[pt_i%4]) || 
		    (nCK_PER_CLK == 2 && sr_rise0_r[pt_i] == pat1_fall0[pt_i%4]) ) 
          pat1_match_rise0_r[pt_i] <= #TCQ 1'b1;
        else
          pat1_match_rise0_r[pt_i] <= #TCQ 1'b0;

        if ((sr_fall0_r[pt_i] == pat1_fall0[pt_i%4]) || 
		    (nCK_PER_CLK == 2 && sr_fall0_r[pt_i] == pat1_rise0[pt_i%4]))    
          pat1_match_fall0_r[pt_i] <= #TCQ 1'b1;
        else
          pat1_match_fall0_r[pt_i] <= #TCQ 1'b0;

        if (sr_rise1_r[pt_i] == pat1_rise1[pt_i%4])
          pat1_match_rise1_r[pt_i] <= #TCQ 1'b1;
        else
          pat1_match_rise1_r[pt_i] <= #TCQ 1'b0;

        if (sr_fall1_r[pt_i] == pat1_fall1[pt_i%4])
          pat1_match_fall1_r[pt_i] <= #TCQ 1'b1;
        else
          pat1_match_fall1_r[pt_i] <= #TCQ 1'b0;
		  
		//The following only used for nCK_PER_CLK == 4
		if (sr_rise2_r[pt_i] == pat1_rise2[pt_i%4])
          pat1_match_rise2_r[pt_i] <= #TCQ 1'b1;
        else
          pat1_match_rise2_r[pt_i] <= #TCQ 1'b0;
		  
		if (sr_fall2_r[pt_i] == pat1_fall2[pt_i%4])
          pat1_match_fall2_r[pt_i] <= #TCQ 1'b1;
        else
          pat1_match_fall2_r[pt_i] <= #TCQ 1'b0;
		  
		if (sr_rise3_r[pt_i] == pat1_rise3[pt_i%4])
          pat1_match_rise3_r[pt_i] <= #TCQ 1'b1;
        else
          pat1_match_rise3_r[pt_i] <= #TCQ 1'b0;
		  
		if (sr_fall3_r[pt_i] == pat1_fall3[pt_i%4])
          pat1_match_fall3_r[pt_i] <= #TCQ 1'b1;
        else
          pat1_match_fall3_r[pt_i] <= #TCQ 1'b0;
		  
		//Pattern 2 ------------------------------------------------------------
        if (sr_rise0_r[pt_i] == pat2_rise0[pt_i%4]) 
          pat2_match_rise0_r[pt_i] <= #TCQ 1'b1;
        else
          pat2_match_rise0_r[pt_i] <= #TCQ 1'b0;

        if (sr_fall0_r[pt_i] == pat2_fall0[pt_i%4])    
          pat2_match_fall0_r[pt_i] <= #TCQ 1'b1;
        else
          pat2_match_fall0_r[pt_i] <= #TCQ 1'b0;

        if (sr_rise1_r[pt_i] == pat2_rise1[pt_i%4])
          pat2_match_rise1_r[pt_i] <= #TCQ 1'b1;
        else
          pat2_match_rise1_r[pt_i] <= #TCQ 1'b0;

        if (sr_fall1_r[pt_i] == pat2_fall1[pt_i%4])
          pat2_match_fall1_r[pt_i] <= #TCQ 1'b1;
        else
          pat2_match_fall1_r[pt_i] <= #TCQ 1'b0;
		  
		//The following only used for nCK_PER_CLK == 4
		if (sr_rise2_r[pt_i] == pat2_rise2[pt_i%4])
          pat2_match_rise2_r[pt_i] <= #TCQ 1'b1;
        else
          pat2_match_rise2_r[pt_i] <= #TCQ 1'b0;
		  
		if (sr_fall2_r[pt_i] == pat2_fall2[pt_i%4])
          pat2_match_fall2_r[pt_i] <= #TCQ 1'b1;
        else
          pat2_match_fall2_r[pt_i] <= #TCQ 1'b0;
		  
		if (sr_rise3_r[pt_i] == pat2_rise3[pt_i%4])
          pat2_match_rise3_r[pt_i] <= #TCQ 1'b1;
        else
          pat2_match_rise3_r[pt_i] <= #TCQ 1'b0;
		  
		if (sr_fall3_r[pt_i] == pat2_fall3[pt_i%4])
          pat2_match_fall3_r[pt_i] <= #TCQ 1'b1;
        else
          pat2_match_fall3_r[pt_i] <= #TCQ 1'b0;
		  
		//Pattern 3 ------------------------------------------------------------
        if (sr_rise0_r[pt_i] == pat3_rise0[pt_i%4]) 
          pat3_match_rise0_r[pt_i] <= #TCQ 1'b1;
        else
          pat3_match_rise0_r[pt_i] <= #TCQ 1'b0;

        if (sr_fall0_r[pt_i] == pat3_fall0[pt_i%4])    
          pat3_match_fall0_r[pt_i] <= #TCQ 1'b1;
        else
          pat3_match_fall0_r[pt_i] <= #TCQ 1'b0;

        if (sr_rise1_r[pt_i] == pat3_rise1[pt_i%4])
          pat3_match_rise1_r[pt_i] <= #TCQ 1'b1;
        else
          pat3_match_rise1_r[pt_i] <= #TCQ 1'b0;

        if (sr_fall1_r[pt_i] == pat3_fall1[pt_i%4])
          pat3_match_fall1_r[pt_i] <= #TCQ 1'b1;
        else
          pat3_match_fall1_r[pt_i] <= #TCQ 1'b0;
		  
		//The following only used for nCK_PER_CLK == 4
		if (sr_rise2_r[pt_i] == pat3_rise2[pt_i%4])
          pat3_match_rise2_r[pt_i] <= #TCQ 1'b1;
        else
          pat3_match_rise2_r[pt_i] <= #TCQ 1'b0;
		  
		if (sr_fall2_r[pt_i] == pat3_fall2[pt_i%4])
          pat3_match_fall2_r[pt_i] <= #TCQ 1'b1;
        else
          pat3_match_fall2_r[pt_i] <= #TCQ 1'b0;
		  
		if (sr_rise3_r[pt_i] == pat3_rise3[pt_i%4])
          pat3_match_rise3_r[pt_i] <= #TCQ 1'b1;
        else
          pat3_match_rise3_r[pt_i] <= #TCQ 1'b0;
		  
		if (sr_fall3_r[pt_i] == pat3_fall3[pt_i%4])
          pat3_match_fall3_r[pt_i] <= #TCQ 1'b1;
        else
          pat3_match_fall3_r[pt_i] <= #TCQ 1'b0;  
		  
      end
    end
  endgenerate

  //Pattern 0 ------------------------------------------------------------
  always @(posedge clk) begin
    pat0_match_rise0_and_r <= #TCQ &pat0_match_rise0_r;
    pat0_match_fall0_and_r <= #TCQ &pat0_match_fall0_r;
    pat0_match_rise1_and_r <= #TCQ &pat0_match_rise1_r;
    pat0_match_fall1_and_r <= #TCQ &pat0_match_fall1_r;
	pat0_match_rise2_and_r <= #TCQ &pat0_match_rise2_r;
    pat0_match_fall2_and_r <= #TCQ &pat0_match_fall2_r;
	pat0_match_rise3_and_r <= #TCQ &pat0_match_rise3_r;
    pat0_match_fall3_and_r <= #TCQ &pat0_match_fall3_r;
	if (nCK_PER_CLK == 2) begin
      pat0_data_match_r <= #TCQ (pat0_match_rise0_and_r &&
                                 pat0_match_fall0_and_r &&
                                 pat0_match_rise1_and_r &&
                                 pat0_match_fall1_and_r);
								 
	  pat0_data_rise_match_r <= #TCQ (pat0_match_rise0_and_r &&
	                                  pat0_match_rise1_and_r);
      pat0_data_fall_match_r <= #TCQ (pat0_match_fall0_and_r &&
	                                  pat0_match_fall1_and_r);
	end else begin
	  pat0_data_match_r <= #TCQ (pat0_match_rise0_and_r &&
                                 pat0_match_fall0_and_r &&
                                 pat0_match_rise1_and_r &&
                                 pat0_match_fall1_and_r &&
								 pat0_match_rise2_and_r &&
								 pat0_match_fall2_and_r &&
								 pat0_match_rise3_and_r &&
								 pat0_match_fall3_and_r);
	  pat0_data_rise_match_r <= #TCQ (pat0_match_rise0_and_r &&
	                                  pat0_match_rise1_and_r &&
									  pat0_match_rise2_and_r &&
									  pat0_match_rise3_and_r);
      pat0_data_fall_match_r <= #TCQ (pat0_match_fall0_and_r &&
	                                  pat0_match_fall1_and_r &&
									  pat0_match_fall2_and_r &&
									  pat0_match_fall3_and_r);
	end
  end
  
  //Pattern 1 ------------------------------------------------------------
  always @(posedge clk) begin
    pat1_match_rise0_and_r <= #TCQ &pat1_match_rise0_r;
    pat1_match_fall0_and_r <= #TCQ &pat1_match_fall0_r;
    pat1_match_rise1_and_r <= #TCQ &pat1_match_rise1_r;
    pat1_match_fall1_and_r <= #TCQ &pat1_match_fall1_r;
	pat1_match_rise2_and_r <= #TCQ &pat1_match_rise2_r;
    pat1_match_fall2_and_r <= #TCQ &pat1_match_fall2_r;
	pat1_match_rise3_and_r <= #TCQ &pat1_match_rise3_r;
    pat1_match_fall3_and_r <= #TCQ &pat1_match_fall3_r;
	if (nCK_PER_CLK == 2) begin
      pat1_data_match_r <= #TCQ (pat1_match_rise0_and_r &&
                                 pat1_match_fall0_and_r &&
                                 pat1_match_rise1_and_r &&
                                 pat1_match_fall1_and_r);
      pat1_data_rise_match_r <= #TCQ (pat1_match_rise0_and_r && 
	                                  pat1_match_rise1_and_r);
      pat1_data_fall_match_r <= #TCQ (pat1_match_fall0_and_r && 
	                                  pat1_match_fall1_and_r);
    end else begin
	  pat1_data_match_r <= #TCQ (pat1_match_rise0_and_r &&
                                 pat1_match_fall0_and_r &&
                                 pat1_match_rise1_and_r &&
                                 pat1_match_fall1_and_r &&
								 pat1_match_rise2_and_r &&
                                 pat1_match_fall2_and_r &&
                                 pat1_match_rise3_and_r &&
                                 pat1_match_fall3_and_r);
      pat1_data_rise_match_r <= #TCQ (pat1_match_rise0_and_r && 
	                                  pat1_match_rise1_and_r &&
									  pat1_match_rise2_and_r &&
									  pat1_match_rise3_and_r);
      pat1_data_fall_match_r <= #TCQ (pat1_match_fall0_and_r && 
	                                  pat1_match_fall1_and_r &&
									  pat1_match_fall2_and_r &&
									  pat1_match_fall3_and_r);
	end
  end
  
  //Pattern 2 ------------------------------------------------------------
  always @(posedge clk) begin
    pat2_match_rise0_and_r <= #TCQ &pat2_match_rise0_r;
    pat2_match_fall0_and_r <= #TCQ &pat2_match_fall0_r;
    pat2_match_rise1_and_r <= #TCQ &pat2_match_rise1_r;
    pat2_match_fall1_and_r <= #TCQ &pat2_match_fall1_r;
	pat2_match_rise2_and_r <= #TCQ &pat2_match_rise2_r;
    pat2_match_fall2_and_r <= #TCQ &pat2_match_fall2_r;
	pat2_match_rise3_and_r <= #TCQ &pat2_match_rise3_r;
    pat2_match_fall3_and_r <= #TCQ &pat2_match_fall3_r;
	if (nCK_PER_CLK == 2) begin
      pat2_data_match_r <= #TCQ (pat2_match_rise0_and_r &&
                                 pat2_match_fall0_and_r &&
                                 pat2_match_rise1_and_r &&
                                 pat2_match_fall1_and_r);
      pat2_data_rise_match_r <= #TCQ (pat2_match_rise0_and_r && 
	                                  pat2_match_rise1_and_r);
      pat2_data_fall_match_r <= #TCQ (pat2_match_fall0_and_r && 
	                                  pat2_match_fall1_and_r);
    end else begin
	  pat2_data_match_r <= #TCQ (pat2_match_rise0_and_r &&
                                 pat2_match_fall0_and_r &&
                                 pat2_match_rise1_and_r &&
                                 pat2_match_fall1_and_r &&
								 pat2_match_rise2_and_r &&
                                 pat2_match_fall2_and_r &&
                                 pat2_match_rise3_and_r &&
                                 pat2_match_fall3_and_r);
      pat2_data_rise_match_r <= #TCQ (pat2_match_rise0_and_r && 
	                                  pat2_match_rise1_and_r &&
									  pat2_match_rise2_and_r &&
									  pat2_match_rise3_and_r);
      pat2_data_fall_match_r <= #TCQ (pat2_match_fall0_and_r && 
	                                  pat2_match_fall1_and_r &&
									  pat2_match_fall2_and_r &&
									  pat2_match_fall3_and_r);
	end
  end
  
  //Pattern 3 ------------------------------------------------------------
  always @(posedge clk) begin
    pat3_match_rise0_and_r <= #TCQ &pat3_match_rise0_r;
    pat3_match_fall0_and_r <= #TCQ &pat3_match_fall0_r;
    pat3_match_rise1_and_r <= #TCQ &pat3_match_rise1_r;
    pat3_match_fall1_and_r <= #TCQ &pat3_match_fall1_r;
	pat3_match_rise2_and_r <= #TCQ &pat3_match_rise2_r;
    pat3_match_fall2_and_r <= #TCQ &pat3_match_fall2_r;
	pat3_match_rise3_and_r <= #TCQ &pat3_match_rise3_r;
    pat3_match_fall3_and_r <= #TCQ &pat3_match_fall3_r;
	if (nCK_PER_CLK == 2) begin
      pat3_data_match_r <= #TCQ (pat3_match_rise0_and_r &&
                                 pat3_match_fall0_and_r &&
                                 pat3_match_rise1_and_r &&
                                 pat3_match_fall1_and_r);
      pat3_data_rise_match_r <= #TCQ (pat3_match_rise0_and_r && 
	                                  pat3_match_rise1_and_r);
      pat3_data_fall_match_r <= #TCQ (pat3_match_fall0_and_r && 
	                                  pat3_match_fall1_and_r);
    end else begin
	  pat3_data_match_r <= #TCQ (pat3_match_rise0_and_r &&
                                 pat3_match_fall0_and_r &&
                                 pat3_match_rise1_and_r &&
                                 pat3_match_fall1_and_r &&
								 pat3_match_rise2_and_r &&
                                 pat3_match_fall2_and_r &&
                                 pat3_match_rise3_and_r &&
                                 pat3_match_fall3_and_r);
      pat3_data_rise_match_r <= #TCQ (pat3_match_rise0_and_r && 
	                                  pat3_match_rise1_and_r &&
									  pat3_match_rise2_and_r &&
									  pat3_match_rise3_and_r);
      pat3_data_fall_match_r <= #TCQ (pat3_match_fall0_and_r && 
	                                  pat3_match_fall1_and_r &&
									  pat3_match_fall2_and_r &&
									  pat3_match_fall3_and_r);
	end
  end
  
  //Following used to check both rise/fall together
  assign pat_match = (nCK_PER_CLK == 2) ? 
                       (pat0_data_match_r || pat1_data_match_r) :
					   (pat0_data_match_r || pat1_data_match_r || 
					    pat2_data_match_r || pat3_data_match_r);
						
  //seperate out rise/fall for seperate checking (QDR2+)
  assign rise_match = (nCK_PER_CLK == 2) ? 
                       (pat0_data_rise_match_r || pat1_data_rise_match_r) :
					   (pat0_data_rise_match_r || pat1_data_rise_match_r || 
					    pat2_data_rise_match_r || pat3_data_rise_match_r);
						
  assign fall_match = (nCK_PER_CLK == 2) ? 
                       (pat0_data_fall_match_r || pat1_data_fall_match_r) :
					   (pat0_data_fall_match_r || pat1_data_fall_match_r || 
					    pat2_data_fall_match_r || pat3_data_fall_match_r);
  
  assign data_valid = (MEMORY_IO_DIR != "UNIDIR")? pat_match :
                          (~rise_detect_done)? rise_match:fall_match;
    
//   generate
//    genvar nd_i;
//    for (nd_i = 0; nd_i < DRAM_WIDTH; nd_i = nd_i + 1) begin: gen_valid
//     
//      assign rd_window[nd_i] = { sr0_rise0_r[nd_i], sr0_rise1_r[nd_i],  sr1_rise0_r[nd_i], sr1_rise1_r[nd_i]}; 
//      assign fd_window[nd_i] = { sr0_fall0_r[nd_i], sr0_fall1_r[nd_i],  sr1_fall0_r[nd_i], sr1_fall1_r[nd_i]};  
//      
//      always @(posedge clk) begin
//        if ((rd_window[nd_i] == 4'b0010) || (rd_window[nd_i] == 4'b1000) || (rd_window[nd_i] == 4'b0100) || (rd_window[nd_i] == 4'b0001)) begin
//            rise_data_valid_r[nd_i] <= #TCQ 1'b1;
//        end else begin
//            rise_data_valid_r[nd_i] <= #TCQ 1'b0;
//        end
//        
//        if ((fd_window[nd_i] == 4'b1101) || (fd_window[nd_i] == 4'b0111) || (fd_window[nd_i] == 4'b1110) || (fd_window[nd_i] == 4'b1011)) begin
//            fall_data_valid_r[nd_i] <= #TCQ 1'b1;
//        end else begin
//            fall_data_valid_r[nd_i] <= #TCQ 1'b0;
//        end
//               
//      end
//    end
//  endgenerate
//  
//  assign rise_data_valid = &rise_data_valid_r;
//  assign fall_data_valid = &fall_data_valid_r;
  
 

  //***************************************************************************
  // First stage calibration: Capture clock
  //***************************************************************************

  //*****************************************************************
  // Free-running counter to keep track of when to do parallel load of
  // data from memory
  //*****************************************************************

  always @(posedge clk)
    //if (rst) begin
    if (rst || ~rdlvl_stg1_start) begin
      cnt_shift_r <= #TCQ 'b0;
      sr_valid_r  <= #TCQ 1'b0;
    end else begin
      if (cnt_shift_r == RD_SHIFT_LEN-1) begin
        sr_valid_r <= #TCQ 1'b1;
        cnt_shift_r <= #TCQ 'b0;
      end else begin
        sr_valid_r <= #TCQ 1'b0;
        cnt_shift_r <= #TCQ cnt_shift_r + 1;
      end
    end

  //*****************************************************************
  // Logic to determine when either edge of the data eye encountered
  // Pre- and post-IDELAY update data pattern is compared, if they
  // differ, than an edge has been encountered. Currently no attempt
  // made to determine if the data pattern itself is "correct", only
  // whether it changes after incrementing the IDELAY (possible
  // future enhancement)
  //*****************************************************************

  // Simple handshaking - when CAL1 state machine wants the OLD SR
  // value to get loaded, it requests for it to be loaded. On the
  // next sr_valid_r pulse, it does get loaded, and store_sr_done_r
  // is then pulsed asserted to indicate this, and we all go on our
  // merry way
  always @(posedge clk)
    if (rst) begin
      store_sr_done_r <= #TCQ 1'b0;
      store_sr_r      <= #TCQ 1'b0;
    end else begin
      store_sr_done_r <= sr_valid_r & store_sr_r;
      if (store_sr_req_r)
        store_sr_r <= #TCQ 1'b1;
      else if (sr_valid_r && store_sr_r)
        store_sr_r <= #TCQ 1'b0;
    end


 
  // Transfer current data to old data, prior to incrementing delay
  // Also store data from current sampling window - so that we can detect
  // if the current delay tap yields data that is "jittery"
  generate
    for (z = 0; z < DRAM_WIDTH; z = z + 1) begin: gen_old_sr
      always @(posedge clk) begin
        if (sr_valid_r) begin
          // Load last sample (i.e. from current sampling interval)
          prev_sr_rise0_r[z] <= #TCQ sr_rise0_r[z];
          prev_sr_fall0_r[z] <= #TCQ sr_fall0_r[z];
          prev_sr_rise1_r[z] <= #TCQ sr_rise1_r[z];
          prev_sr_fall1_r[z] <= #TCQ sr_fall1_r[z];
          prev_sr_rise2_r[z] <= #TCQ sr_rise2_r[z];
          prev_sr_fall2_r[z] <= #TCQ sr_fall2_r[z];
          prev_sr_rise3_r[z] <= #TCQ sr_rise3_r[z];
          prev_sr_fall3_r[z] <= #TCQ sr_fall3_r[z];         
        end
        if (sr_valid_r && store_sr_r) begin
          old_sr_rise0_r[z] <= #TCQ sr_rise0_r[z];
          old_sr_fall0_r[z] <= #TCQ sr_fall0_r[z];
          old_sr_rise1_r[z] <= #TCQ sr_rise1_r[z];
          old_sr_fall1_r[z] <= #TCQ sr_fall1_r[z];
          old_sr_rise2_r[z] <= #TCQ sr_rise2_r[z];
          old_sr_fall2_r[z] <= #TCQ sr_fall2_r[z];
          old_sr_rise3_r[z] <= #TCQ sr_rise3_r[z];
          old_sr_fall3_r[z] <= #TCQ sr_fall3_r[z];
        end
      end
    end
  endgenerate

  //*******************************************************
  // Match determination occurs over 3 cycles - pipelined for better timing
  //*******************************************************

  // Match valid with # of cycles of pipelining in match determination
  always @(posedge clk) begin
    sr_valid_r1 <= #TCQ sr_valid_r;
    sr_valid_r2 <= #TCQ sr_valid_r1;
  end
  
  generate
    for (z = 0; z < DRAM_WIDTH; z = z + 1) begin: gen_sr_match
      always @(posedge clk) begin
        // CYCLE1: Compare all bits in DQS grp, generate separate term for 
        //  each bit over four bit times. For example, if there are 8-bits
        //  per DQS group, 32 terms are generated on cycle 1
        // NOTE: Structure HDL such that X on data bus will result in a 
        //  mismatch. This is required for memory models that can drive the 
        //  bus with X's to model uncertainty regions (e.g. Denali)
        if (data_valid && sr_rise0_r[z] == old_sr_rise0_r[z])
          old_sr_match_rise0_r[z] <= #TCQ 1'b1;
        else
          old_sr_match_rise0_r[z] <= #TCQ 1'b0;
        
        if (data_valid && sr_fall0_r[z] == old_sr_fall0_r[z])
          old_sr_match_fall0_r[z] <= #TCQ 1'b1;
        else
          old_sr_match_fall0_r[z] <= #TCQ 1'b0;
        
        if (data_valid && sr_rise1_r[z] == old_sr_rise1_r[z])
          old_sr_match_rise1_r[z] <= #TCQ 1'b1;
        else
          old_sr_match_rise1_r[z] <= #TCQ 1'b0;
        
        if (data_valid && sr_fall1_r[z] == old_sr_fall1_r[z])
          old_sr_match_fall1_r[z] <= #TCQ 1'b1;
        else
          old_sr_match_fall1_r[z] <= #TCQ 1'b0;

        if (sr_rise2_r[z] == old_sr_rise2_r[z])
          old_sr_match_rise2_r[z] <= #TCQ 1'b1;
        else
          old_sr_match_rise2_r[z] <= #TCQ 1'b0;
        
        if (sr_fall2_r[z] == old_sr_fall2_r[z])
          old_sr_match_fall2_r[z] <= #TCQ 1'b1;
        else
          old_sr_match_fall2_r[z] <= #TCQ 1'b0;
        
        if (sr_rise3_r[z] == old_sr_rise3_r[z])
          old_sr_match_rise3_r[z] <= #TCQ 1'b1;
        else
          old_sr_match_rise3_r[z] <= #TCQ 1'b0;
        
        if (sr_fall3_r[z] == old_sr_fall3_r[z])
          old_sr_match_fall3_r[z] <= #TCQ 1'b1;
        else
          old_sr_match_fall3_r[z] <= #TCQ 1'b0;
        
        if (data_valid && sr_rise0_r[z] == prev_sr_rise0_r[z])
          prev_sr_match_rise0_r[z] <= #TCQ 1'b1;
        else
          prev_sr_match_rise0_r[z] <= #TCQ 1'b0;
        
        if (data_valid && sr_fall0_r[z] == prev_sr_fall0_r[z])
          prev_sr_match_fall0_r[z] <= #TCQ 1'b1;
        else
          prev_sr_match_fall0_r[z] <= #TCQ 1'b0;
        
        if (data_valid && sr_rise1_r[z] == prev_sr_rise1_r[z])
          prev_sr_match_rise1_r[z] <= #TCQ 1'b1;
        else
          prev_sr_match_rise1_r[z] <= #TCQ 1'b0;
        
        if (data_valid && sr_fall1_r[z] == prev_sr_fall1_r[z])
          prev_sr_match_fall1_r[z] <= #TCQ 1'b1;
        else
          prev_sr_match_fall1_r[z] <= #TCQ 1'b0;
          
        if (sr_rise2_r[z] == prev_sr_rise2_r[z])
          prev_sr_match_rise2_r[z] <= #TCQ 1'b1;
        else
          prev_sr_match_rise2_r[z] <= #TCQ 1'b0;
        
        if (sr_fall2_r[z] == prev_sr_fall2_r[z])
          prev_sr_match_fall2_r[z] <= #TCQ 1'b1;
        else
          prev_sr_match_fall2_r[z] <= #TCQ 1'b0;
        
        if (sr_rise3_r[z] == prev_sr_rise3_r[z])
          prev_sr_match_rise3_r[z] <= #TCQ 1'b1;
        else
          prev_sr_match_rise3_r[z] <= #TCQ 1'b0;
        
        if (sr_fall3_r[z] == prev_sr_fall3_r[z])
          prev_sr_match_fall3_r[z] <= #TCQ 1'b1;
        else
          prev_sr_match_fall3_r[z] <= #TCQ 1'b0;
 
        // CYCLE2: Combine all the comparisons for every 8 words (rise0, 
        //  fall0,rise1, fall1) in the calibration sequence. Now we're down 
        //  to DRAM_WIDTH terms
		if (nCK_PER_CLK == 2) begin
		  //Only check rise0/fall0
		  //Our pattern is such that we only need to check one of the outputs
          old_sr_match_cyc2_r[z] <= #TCQ old_sr_match_rise0_r[z] &
                                         old_sr_match_fall0_r[z];
          prev_sr_match_cyc2_r[z] <= #TCQ prev_sr_match_rise0_r[z] &
                                          prev_sr_match_fall0_r[z];
										  
		  old_rise_sr_match_cyc2_r[z] <= #TCQ old_sr_match_rise0_r[z];
          old_fall_sr_match_cyc2_r[z] <= #TCQ old_sr_match_fall0_r[z];

          prev_rise_sr_match_cyc2_r[z] <= #TCQ prev_sr_match_rise0_r[z];
          prev_fall_sr_match_cyc2_r[z] <= #TCQ prev_sr_match_fall0_r[z];// &
		  
		end else begin
		  old_sr_match_cyc2_r[z] <= #TCQ old_sr_match_rise0_r[z] &
                                         old_sr_match_fall0_r[z] &
                                         old_sr_match_rise1_r[z] &
                                         old_sr_match_fall1_r[z] &
                                         old_sr_match_rise2_r[z] &
                                         old_sr_match_fall2_r[z] &
                                         old_sr_match_rise3_r[z] &
                                         old_sr_match_fall3_r[z];
          prev_sr_match_cyc2_r[z] <= #TCQ prev_sr_match_rise0_r[z] &
                                          prev_sr_match_fall0_r[z] &
                                          prev_sr_match_rise1_r[z] &
                                          prev_sr_match_fall1_r[z] &
                                          prev_sr_match_rise2_r[z] &
                                          prev_sr_match_fall2_r[z] &
                                          prev_sr_match_rise3_r[z] &
                                          prev_sr_match_fall3_r[z];
										  
		  old_rise_sr_match_cyc2_r[z] <= #TCQ old_sr_match_rise0_r[z] &
		                                      old_sr_match_rise1_r[z] &
											  old_sr_match_rise2_r[z] &
											  old_sr_match_rise3_r[z];
          old_fall_sr_match_cyc2_r[z] <= #TCQ old_sr_match_fall0_r[z] &
                                              old_sr_match_fall1_r[z] &
											  old_sr_match_fall2_r[z] &
											  old_sr_match_fall3_r[z];
          prev_rise_sr_match_cyc2_r[z] <= #TCQ prev_sr_match_rise0_r[z] &
		                                       prev_sr_match_rise1_r[z] &
											   prev_sr_match_rise2_r[z] &
											   prev_sr_match_rise3_r[z];
          prev_fall_sr_match_cyc2_r[z] <= #TCQ prev_sr_match_fall0_r[z] &
		                                       prev_sr_match_fall1_r[z] &
											   prev_sr_match_fall2_r[z] &
											   prev_sr_match_fall3_r[z];
		end

        // CYCLE3: Invert value (i.e. assert when DIFFERENCE in value seen),
        //  and qualify with pipelined valid signal) - probably don't need
        //  a cycle just do do this....
        if (sr_valid_r2) begin 
          old_sr_diff_r[z]       <= #TCQ ~old_sr_match_cyc2_r[z];
          prev_sr_diff_r[z]      <= #TCQ ~prev_sr_match_cyc2_r[z];
          old_rise_sr_diff_r[z]  <= #TCQ ~old_rise_sr_match_cyc2_r[z];
          prev_rise_sr_diff_r[z] <= #TCQ ~prev_rise_sr_match_cyc2_r[z];     
          old_fall_sr_diff_r[z]  <= #TCQ ~old_fall_sr_match_cyc2_r[z];
          prev_fall_sr_diff_r[z] <= #TCQ ~prev_fall_sr_match_cyc2_r[z];
        end else begin 
          old_sr_diff_r[z]       <= #TCQ 'b0;
          prev_sr_diff_r[z]      <= #TCQ 'b0;
          old_rise_sr_diff_r[z]  <= #TCQ 'b0;
          prev_rise_sr_diff_r[z] <= #TCQ 'b0;
          old_fall_sr_diff_r[z]  <= #TCQ 'b0;
          prev_fall_sr_diff_r[z] <= #TCQ 'b0;
        end

     end
    end
  endgenerate
  
  //***************************************************************************
  // First stage calibration: DQS Capture
  //***************************************************************************
  

  //*******************************************************
  // Counters for tracking # of samples compared
  // For each comparision point (i.e. to determine if an edge has
  // occurred after each IODELAY increment when read leveling),
  // multiple samples are compared in order to average out the effects
  // of jitter. If any one of these samples is different than the "old"
  // sample corresponding to the previous IODELAY value, then an edge
  // is declared to be detected. 
  //*******************************************************
  
  // Two cascaded counters are used to keep track of # of samples compared, 
  // in order to make it easier to meeting timing on these paths. Once 
  // optimal sampling interval is determined, it may be possible to remove 
  // the second counter 

  always @(posedge clk)
    samp_edge_cnt0_en_r <= #TCQ 
                          (cal1_state_r == CAL1_DETECT_EDGE) ||
                          (cal1_state_r == CAL1_PB_DETECT_EDGE) ||
                          (cal1_state_r == CAL1_DETECT_EDGE_Q) || //added for Q delay
                           (cal1_state_r == CAL1_FALL_DETECT_EDGE) || 
                          (cal1_state_r == CAL1_PB_DETECT_EDGE_DQ);
//                          || (cal1_state_r == CAL1_LF_DETECT_EDGE);
  
  // First counter counts the number of samples directly
  // MIG 3.3: Change this to increment every clock cycle, rather than once
  //  every RD_SHIFT_LEN clock cycles, because of the changes to the
  //  comparison logic. In order to make this comparable to MIG 3.2, the 
  //  counter width must be increased by 1-bit (for MIG 3.2, RD_SHIFT_LEN = 2)
  always @(posedge clk)
    if (rst)
      samp_edge_cnt0_r <= #TCQ 'b0;
    else 
      if (!samp_edge_cnt0_en_r)
        samp_edge_cnt0_r <= #TCQ 'b0;
      else
        samp_edge_cnt0_r <= #TCQ samp_edge_cnt0_r + 1;

  always @(posedge clk)
    if (rst)
      samp_edge_cnt1_en_r <= #TCQ 1'b0;
    else begin 
      if (((SIM_CAL_OPTION == "FAST_CAL") ||
           (SIM_CAL_OPTION == "FAST_WIN_DETECT")) && 
           (samp_edge_cnt0_r == 12'h003)) 
        // Bypass multi-sampling for stage 1 when simulating with
        // either fast calibration option, or with multi-sampling
        // disabled        
        samp_edge_cnt1_en_r <= #TCQ 1'b1;
      else if (samp_edge_cnt0_r == DETECT_EDGE_SAMPLE_CNT0)
        samp_edge_cnt1_en_r <= #TCQ 1'b1;
      else
        samp_edge_cnt1_en_r <= #TCQ 1'b0;
    end
  
  // Counter #2
  always @(posedge clk)
    if (rst)
      samp_edge_cnt1_r <= #TCQ 'b0;
    else 
      if (!samp_edge_cnt0_en_r)
        samp_edge_cnt1_r <= #TCQ 'b0;
      else if (samp_edge_cnt1_en_r)
        samp_edge_cnt1_r <= #TCQ samp_edge_cnt1_r + 1;
      
  always @(posedge clk)
    if (rst)
      samp_cnt_done_r <= #TCQ 1'b0;
    else begin 
      if (!samp_edge_cnt0_en_r)
        samp_cnt_done_r <= #TCQ 'b0;
      else if (((SIM_CAL_OPTION == "FAST_CAL") ||
                (SIM_CAL_OPTION == "FAST_WIN_DETECT")) &&
               (samp_edge_cnt1_r == 12'h003)) 
        // Bypass multi-sampling for stage 1 when simulating with
        // either fast calibration option, or with multi-sampling
        // disabled
        samp_cnt_done_r <= #TCQ 1'b1;      
      else if (samp_edge_cnt1_r == DETECT_EDGE_SAMPLE_CNT1) 
        samp_cnt_done_r <= #TCQ 1'b1;
    end

  //*****************************************************************
  // Logic to keep track of (on per-bit basis):
  //  1. When a region of stability preceded by a known edge occurs
  //  2. If for the current tap, the read data jitters
  //  3. If an edge occured between the current and previous tap
  //  4. When the current edge detection/sampling interval can end
  // Essentially, these are a series of status bits - the stage 1
  // calibration FSM monitors these to determine when an edge is
  // found. Additional information is provided to help the FSM
  // determine if a left or right edge has been found. 
  //****************************************************************

/*  assign pb_detect_edge_setup 
    = (cal1_state_r == CAL1_STORE_FIRST_WAIT) ||
      (cal1_state_r == CAL1_PB_STORE_FIRST_WAIT) ||
      (cal1_state_r == CAL1_PB_DEC_CPT_LEFT_WAIT) || 
       (cal1_state_r == CAL1_IDEL_DEC_Q_WAIT) ||(cal1_state_r == CAL1_IDEL_DEC_Q_ALL_WAIT) ; // added for Q delay

  assign pb_detect_edge
    = (cal1_state_r == CAL1_DETECT_EDGE) ||
      (cal1_state_r == CAL1_PB_DETECT_EDGE) ||
      (cal1_state_r == CAL1_PB_DETECT_EDGE_DQ) ||
      (cal1_state_r == CAL1_DETECT_EDGE_Q);  // added for Q delay
 */

   assign pb_detect_edge_setup 
    = (cal1_state_r == CAL1_STORE_FIRST_WAIT) ||
      (cal1_state_r == CAL1_PB_STORE_FIRST_WAIT) ||
      (cal1_state_r == CAL1_PB_DEC_CPT_LEFT_WAIT) || 
       (cal1_state_r == CAL1_IDEL_DEC_Q_WAIT) ||(cal1_state_r == CAL1_IDEL_DEC_Q_ALL_WAIT)|| (cal1_state_r == CAL1_FALL_INC_CPT_WAIT) || (cal1_state_r == CAL1_IDEL_FALL_DEC_CPT) ||
       (cal1_state_r ==  CAL1_FALL_DETECT_EDGE_WAIT)   ; // added for Q delay
 
  assign pb_detect_edge
    = (cal1_state_r == CAL1_DETECT_EDGE) ||
      (cal1_state_r == CAL1_PB_DETECT_EDGE) ||
      (cal1_state_r == CAL1_PB_DETECT_EDGE_DQ) ||
      (cal1_state_r == CAL1_DETECT_EDGE_Q)|| // added for Q delay
      (cal1_state_r == CAL1_FALL_DETECT_EDGE);
        
  generate
    for (z = 0; z < DRAM_WIDTH; z = z + 1) begin: gen_track_left_edge  
      always @(posedge clk) begin 
        if (pb_detect_edge_setup) begin
          // Reset eye size, stable eye marker, and jitter marker before
          // starting new edge detection iteration
          pb_cnt_eye_size_r[z]     <= #TCQ 3'b111;
          pb_detect_edge_done_r[z] <= #TCQ 1'b0;
          pb_found_stable_eye_r[z] <= #TCQ 1'b0;      
          pb_last_tap_jitter_r[z]  <= #TCQ 1'b0;
          pb_found_edge_last_r[z]  <= #TCQ 1'b0;
          pb_found_edge_r[z]       <= #TCQ 1'b0;
          pb_found_first_edge_r[z] <= #TCQ 1'b0;
        end else if (pb_detect_edge) begin 
          // Save information on which DQ bits are already out of the
          // data valid window - those DQ bits will later not have their
          // IDELAY tap value incremented
          pb_found_edge_last_r[z] <= #TCQ pb_found_edge_r[z];

          if (!pb_detect_edge_done_r[z]) begin 
            if (samp_cnt_done_r) begin
              // If we've reached end of sampling interval, no jitter on 
              // current tap has been found (although an edge could have 
              // been found between the current and previous taps), and 
              // the sampling interval is complete. Increment the stable 
              // eye counter if no edge found, and always clear the jitter 
              // flag in preparation for the next tap. 
              pb_last_tap_jitter_r[z]  <= #TCQ 1'b0;
              pb_detect_edge_done_r[z] <= #TCQ 1'b1;
              if (!pb_found_edge_r[z] && !pb_last_tap_jitter_r[z]) begin
                // If the data was completely stable during this tap and
                // no edge was found between this and the previous tap
                // then increment the stable eye counter "as appropriate" 
                if (pb_cnt_eye_size_r[z] != MIN_EYE_SIZE-1)
                  pb_cnt_eye_size_r[z] <= #TCQ pb_cnt_eye_size_r[z] + 1;
                else if (pb_found_first_edge_r[z])
                  // We've reached minimum stable eye width
                  pb_found_stable_eye_r[z] <= #TCQ 1'b1;
              end else begin 
                // Otherwise, an edge was found, either because of a
                // difference between this and the previous tap's read 
                // data, and/or because the previous tap's data jittered 
                // (but not the current tap's data), then just set the 
                // edge found flag, and enable the stable eye counter
                pb_cnt_eye_size_r[z]     <= #TCQ 3'b000;
                pb_found_stable_eye_r[z] <= #TCQ 1'b0;          
                pb_found_edge_r[z]       <= #TCQ 1'b1;
                pb_detect_edge_done_r[z] <= #TCQ 1'b1;          
              end
            end else if ((prev_sr_diff_r[z] && MEMORY_IO_DIR != "UNIDIR") ||
                          (prev_rise_sr_diff_r[z] && MEMORY_IO_DIR == "UNIDIR")) begin
              // If we find that the current tap read data jitters, then
              // set edge and jitter found flags, "enable" the eye size
              // counter, and stop sampling interval for this bit
              pb_cnt_eye_size_r[z]     <= #TCQ 3'b000;
              pb_found_stable_eye_r[z] <= #TCQ 1'b0;      
              pb_last_tap_jitter_r[z]  <= #TCQ 1'b1;          
              pb_found_edge_r[z]       <= #TCQ 1'b1;
              pb_found_first_edge_r[z] <= #TCQ 1'b1;          
              pb_detect_edge_done_r[z] <= #TCQ 1'b1;  
           
            end else if ( ((old_sr_diff_r[z] && MEMORY_IO_DIR != "UNIDIR") ||
                          (old_rise_sr_diff_r[z] && MEMORY_IO_DIR == "UNIDIR")) ||
                        pb_last_tap_jitter_r[z]) begin
              // If either an edge was found (i.e. difference between
              // current tap and previous tap read data), or the previous
              // tap exhibited jitter (which means by definition that the
              // current tap cannot match the previous tap because the
              // previous tap gave unstable data), then set the edge found
              // flag, and "enable" eye size counter. But do not stop 
              // sampling interval - we still need to check if the current 
              // tap exhibits jitter
              pb_cnt_eye_size_r[z]     <= #TCQ 3'b000;
              pb_found_stable_eye_r[z] <= #TCQ 1'b0;      
              pb_found_edge_r[z]       <= #TCQ 1'b1;
              pb_found_first_edge_r[z] <= #TCQ 1'b1;          
            end
          end
        end else begin
          // Before every edge detection interval, reset "intra-tap" flags
          pb_found_edge_r[z]       <= #TCQ 1'b0;
          pb_detect_edge_done_r[z] <= #TCQ 1'b0;
        end
      end          
    end
  endgenerate

  // Combine the above per-bit status flags into combined terms when
  // performing deskew on the aggregate data window
  always @(posedge clk) begin
    detect_edge_done_r <= #TCQ &pb_detect_edge_done_r;
    found_edge_r       <= #TCQ |pb_found_edge_r;
    found_edge_all_r   <= #TCQ &pb_found_edge_r;
    found_stable_eye_r <= #TCQ &pb_found_stable_eye_r;
  end

  // last IODELAY "stable eye" indicator is updated only after 
  // detect_edge_done_r is asserted - so that when we do find the "right edge" 
  // of the data valid window, found_edge_r = 1, AND found_stable_eye_r = 1 
  // when detect_edge_done_r = 1 (otherwise, if found_stable_eye_r updates
  // immediately, then it never possible to have found_stable_eye_r = 1
  // when we detect an edge - and we'll never know whether we've found
  // a "right edge")
  always @(posedge clk)
    if (pb_detect_edge_setup)
      found_stable_eye_last_r <= #TCQ 1'b0;
    else if (detect_edge_done_r)
      found_stable_eye_last_r <= #TCQ found_stable_eye_r;
  
  //*****************************************************************
  // keep track of edge tap counts found, and current capture clock
  // tap count
  //*****************************************************************

  always @(posedge clk)
    if (rst || new_cnt_cpt_r)
      tap_cnt_cpt_r   <= #TCQ 'b0;
    else if (cal1_dlyce_cpt_r) begin
      if (cal1_dlyinc_cpt_r)
        tap_cnt_cpt_r <= #TCQ tap_cnt_cpt_r + 1;
      else
        tap_cnt_cpt_r <= #TCQ tap_cnt_cpt_r - 1;
    end

  always @(posedge clk)
  begin
    if (rst)
      phaser_taps_meet_fall_window <= #TCQ 1'b0;
    else if (tap_cnt_cpt_r - fall_win_det_start_taps_r >= 14) begin
      if (cal1_dlyce_cpt_r && cal1_dlyinc_cpt_r)
        phaser_taps_meet_fall_window <= #TCQ 1'b1;
    end else
      phaser_taps_meet_fall_window <= #TCQ 1'b0;
  end
    
  always @(posedge clk)
    if (rst || new_cnt_cpt_r)
      tap_limit_cpt_r <= #TCQ 1'b0;
    else if (tap_cnt_cpt_r == 6'd63) 
        // (cal1_state_r == CAL1_IDEL_STORE_OLD))
      tap_limit_cpt_r <= #TCQ 1'b1;

    always @(posedge clk)
    if (rst || new_cnt_cpt_r)
      cqn_tap_limit_cpt_r <= #TCQ 1'b0;
    else if (tap_cnt_cpt_r == 6'd63  && rise_detect_done) 
        // (cal1_state_r == CAL1_IDEL_STORE_OLD))
      cqn_tap_limit_cpt_r <= #TCQ 1'b1;
      
   always @(posedge clk)
    if (rst || new_cnt_cpt_r)
      idel_tap_cnt_cpt_r   <= #TCQ 'b0;
    else if (cal1_dlyce_q_r) begin
      if (cal1_dlyinc_q_r)
        idel_tap_cnt_cpt_r <= #TCQ idel_tap_cnt_cpt_r + 1;
      else
        idel_tap_cnt_cpt_r <= #TCQ idel_tap_cnt_cpt_r - 1;
    end
  
   always @(posedge clk)
    if (rst || new_cnt_cpt_r)
      idel_tap_limit_cpt_r <= #TCQ 1'b0;
    else if (idel_tap_cnt_cpt_r == 6'd31) 
        // (cal1_state_r == CAL1_IDEL_STORE_OLD))
      idel_tap_limit_cpt_r <= #TCQ 1'b1;

   always @(posedge clk)
    if (rst || new_cnt_cpt_r)
      cnt_rise_center_taps   <= #TCQ 'b0;
    else if (cal1_state_r == CAL1_FALL_DETECT_EDGE_WAIT) begin
      cnt_rise_center_taps   <= #TCQ tap_cnt_cpt_r;
    end
       
        
   always @(posedge clk)
     if (rst)
         cal1_cnt_cpt_2r        <= #TCQ 'b0;
     else    
         cal1_cnt_cpt_2r        <= #TCQ cal1_cnt_cpt_r;
         
   
   // Temp wire for timing.
   // The following in the always block below causes timing issues
   // due to DSP block inference
   // 6*cal1_cnt_cpt_r.
   // replacing this with two left shifts + one left shift  to avoid
   // DSP multiplier.

  assign cal1_cnt_cpt_timing = {2'd0, cal1_cnt_cpt_2r};

    // Storing DQS tap values at the end of each DQS read leveling
   always @(posedge clk) begin
     if (rst) begin
       pi_rdlvl_dqs_tap_cnt_r <= #TCQ 'b0;
     end else if (
             (SIM_CAL_OPTION == "FAST_CAL") & 
             ( ((MEMORY_IO_DIR == "UNIDIR") && (cal1_state_r1 == CAL1_FALL_DETECT_EDGE_WAIT)) ||
               ((MEMORY_IO_DIR == "BIDIR")  && (cal1_state_r1 == CAL1_NEXT_DQS)))) begin
       for (p = 0; p < RANKS; p = p +1) begin: pi_rdlvl_dqs_tap_rank_cnt   
         for(q = 0; q < DQS_WIDTH; q = q +1) begin: rdlvl_dqs_tap_cnt
           pi_rdlvl_dqs_tap_cnt_r[((6*q)+(p*DQS_WIDTH*6))+:6] <= #TCQ tap_cnt_cpt_r;
         end
       end
     end else if (SIM_CAL_OPTION == "SKIP_CAL") begin
       for (j = 0; j < RANKS; j = j +1) begin: pi_rdlvl_dqs_tap_rnk_cnt   
         for(i = 0; i < DQS_WIDTH; i = i +1) begin: rdlvl_dqs_cnt
           pi_rdlvl_dqs_tap_cnt_r[((6*i)+(j*DQS_WIDTH*6))+:6] <= #TCQ SKIP_DLY_VAL ; //6'd31;
         end
       end
     end else if ( ((MEMORY_IO_DIR == "UNIDIR") && (cal1_state_r1 == CAL1_FALL_DETECT_EDGE_WAIT)) ||
                   ((MEMORY_IO_DIR == "BIDIR")  && (cal1_state_r1 == CAL1_NEXT_DQS)) ) begin
     //end else if (cal1_state_r1 == CAL1_FALL_DETECT_EDGE_WAIT) begin
         pi_rdlvl_dqs_tap_cnt_r[(((cal1_cnt_cpt_timing <<2) + (cal1_cnt_cpt_timing <<1))
         +(rnk_cnt_r*DQS_WIDTH*6))+:6]
           <= #TCQ tap_cnt_cpt_r;
     end
   end

       // Storing DQS tap values at the end of each DQS read leveling
   always @(posedge clk) begin
     if (rst) begin
       po_rdlvl_dqs_tap_cnt_r <= #TCQ 'b0;
     end else if ((SIM_CAL_OPTION == "FAST_CAL") && (cal1_state_r1 == CAL1_NEXT_DQS)) begin
       for (p = 0; p < RANKS; p = p +1) begin: po_rdlvl_dqs_tap_rank_cnt   
         for(q = 0; q < DQS_WIDTH; q = q +1) begin: rdlvl_dqs_tap_cnt
           po_rdlvl_dqs_tap_cnt_r[((6*q)+(p*DQS_WIDTH*6))+:6] <= #TCQ tap_cnt_cpt_r;
         end
       end
     end else if (SIM_CAL_OPTION == "SKIP_CAL") begin
       for (j = 0; j < RANKS; j = j +1) begin: po_rdlvl_dqs_tap_rnk_cnt   
         for(i = 0; i < DQS_WIDTH; i = i +1) begin: rdlvl_dqs_cnt
           po_rdlvl_dqs_tap_cnt_r[((6*i)+(j*DQS_WIDTH*6))+:6] <= #TCQ SKIP_DLY_VAL ; //6'd31;
         end
       end
     end else if (cal1_state_r1 == CAL1_NEXT_DQS) begin
         po_rdlvl_dqs_tap_cnt_r[(((cal1_cnt_cpt_timing <<2) + (cal1_cnt_cpt_timing <<1))
         +(rnk_cnt_r*DQS_WIDTH*6))+:6]
           <= #TCQ tap_cnt_cpt_r ;
     end
   end // always @ (posedge clk)

   /*
 
   // Storing DQS tap values at the end of each DQS read leveling
   always @(posedge clk) begin
     if (rst) begin
       rdlvl_dqs_tap_cnt_r <= #TCQ 'b0;
     end else if ((SIM_CAL_OPTION == "FAST_CAL") & (cal1_state_r1 == CAL1_NEXT_DQS)) begin
       for (p = 0; p < RANKS; p = p +1) begin: rdlvl_dqs_tap_rank_cnt   
         for(q = 0; q < DQS_WIDTH; q = q +1) begin: rdlvl_dqs_tap_cnt
           rdlvl_dqs_tap_cnt_r[((6*q)+(p*DQS_WIDTH*6))+:6] <= #TCQ tap_cnt_cpt_r;
         end
       end
     end else if (SIM_CAL_OPTION == "SKIP_CAL") begin
       for (j = 0; j < RANKS; j = j +1) begin: rdlvl_dqs_tap_rnk_cnt   
         for(i = 0; i < DQS_WIDTH; i = i +1) begin: rdlvl_dqs_cnt
           rdlvl_dqs_tap_cnt_r[((6*i)+(j*DQS_WIDTH*6))+:6] <= #TCQ SKIP_DLY_VAL ; //6'd31;
         end
       end
     end else if (cal1_state_r1 == CAL1_NEXT_DQS) begin
         rdlvl_dqs_tap_cnt_r[(((cal1_cnt_cpt_timing <<2) + (cal1_cnt_cpt_timing <<1))
         +(rnk_cnt_r*DQS_WIDTH*6))+:6]
           <= #TCQ tap_cnt_cpt_r;
     end
   end
    
    */


  // Counter to track maximum DQ IODELAY tap usage during the per-bit 
  // deskew portion of stage 1 calibration
  always @(posedge clk)
    if (rst) begin
      idel_tap_cnt_dq_pb_r   <= #TCQ 'b0;
      idel_tap_limit_dq_pb_r <= #TCQ 1'b0;
    end else 
      if (new_cnt_cpt_r) begin
        idel_tap_cnt_dq_pb_r   <= #TCQ 'b0;
        idel_tap_limit_dq_pb_r <= #TCQ 1'b0;
      end else if (|cal1_dlyce_dq_r) begin
        if (cal1_dlyinc_dq_r)
          idel_tap_cnt_dq_pb_r <= #TCQ idel_tap_cnt_dq_pb_r + 1;
        else
          idel_tap_cnt_dq_pb_r <= #TCQ idel_tap_cnt_dq_pb_r - 1;         

        if (idel_tap_cnt_dq_pb_r == 31)
          idel_tap_limit_dq_pb_r <= #TCQ 1'b1;
        else
          idel_tap_limit_dq_pb_r <= #TCQ 1'b0;
      end


  
  //*****************************************************************
  
  always @(posedge clk)
    cal1_state_r1 <= #TCQ cal1_state_r;
  
  always @(posedge clk)
    if (rst) begin
      cal1_cnt_cpt_r        <= #TCQ 'b0;
      cal1_dlyce_cpt_r      <= #TCQ 1'b0;
      cal1_dlyinc_cpt_r     <= #TCQ 1'b0;
      cal1_dlyce_q_r        <= #TCQ 1'b0;
      cal1_dlyinc_q_r        <= #TCQ 1'b0;
      cal1_prech_req_r      <= #TCQ 1'b0;
      cal1_state_r          <= #TCQ CAL1_IDLE;
      cnt_idel_dec_cpt_r    <= #TCQ 6'bxxxxxx;
      found_first_edge_r    <= #TCQ 1'b0;
      found_second_edge_r   <= #TCQ 1'b0;
      first_edge_taps_r     <= #TCQ 6'bxxxxx;
      new_cnt_cpt_r         <= #TCQ 1'b0;
      rdlvl_stg1_done       <= #TCQ 1'b0;
      rdlvl_stg1_err        <= #TCQ 1'b0;
      second_edge_taps_r    <= #TCQ 6'bxxxxx;
      store_sr_req_r        <= #TCQ 1'b0;
      rnk_cnt_r             <= #TCQ 2'b00;
      rdlvl_rank_done_r     <= #TCQ 1'b0;
      start_win_detect      <= #TCQ 1'b0;
      end_win_detect       <= #TCQ 1'b0;
      qdly_inc_done_r      <= #TCQ 1'b0;
      idelay_taps          <= #TCQ 'b0;
      start_win_taps       <= #TCQ 'b0;
      end_win_taps         <= #TCQ 'b0;
      idelay_inc_taps_r    <= #TCQ 'b0;
      clk_in_vld_win       <= #TCQ 1'b0;
      idel_dec_cntr        <= #TCQ 'b0;
      rise_detect_done     <= #TCQ 'b0;
      set_fall_capture_clock_at_tap0 <=#TCQ 1'b0;
      
      fall_first_edge_det_done  <= 1'b0;
      fall_win_det_start_taps_r <= #TCQ 'b0;
      fall_win_det_end_taps_r   <= #TCQ 'b0;
      //cnt_rise_center_taps      <= #TCQ 'b0;
      dbg_stg1_calc_edge        <= #TCQ 'b0;
      
    end else begin
           
      case (cal1_state_r)
        
        CAL1_IDLE: begin
          rdlvl_rank_done_r <= #TCQ 1'b0;
		  pi_gap_enforcer   <= #TCQ PI_ADJ_GAP;
          if (rdlvl_start) begin
            if (SIM_CAL_OPTION == "SKIP_CAL") begin
               cal1_state_r  <= #TCQ CAL1_REGL_LOAD;
            end else begin
              new_cnt_cpt_r <= #TCQ 1'b1;             
              cal1_state_r  <= #TCQ CAL1_NEW_DQS_WAIT;
            end
          end
        end
        // Wait for the new DQS group to change
        // also gives time for the read data IN_FIFO to
        // output the updated data for the new DQS group
        CAL1_NEW_DQS_WAIT: begin
          rdlvl_rank_done_r <= #TCQ 1'b0;
          cal1_prech_req_r  <= #TCQ 1'b0;
          if (!cal1_wait_r) begin
            // Store "previous tap" read data. Technically there is no 
            // "previous" read data, since we are starting a new DQS 
            // group, so we'll never find an edge at tap 0 unless the 
            // data is fluctuating/jittering
            store_sr_req_r <= #TCQ 1'b1;
            // If per-bit deskew is disabled, then skip the first
            // portion of stage 1 calibration
            if (PER_BIT_DESKEW == "OFF")
              cal1_state_r <= #TCQ CAL1_STORE_FIRST_WAIT;
            else if (PER_BIT_DESKEW == "ON")
              cal1_state_r <= #TCQ CAL1_PB_STORE_FIRST_WAIT;
          end
        end
        //*****************************************************************
        // Per-bit deskew states
        //*****************************************************************
//        
//        // Wait state following storage of initial read data 
//        CAL1_PB_STORE_FIRST_WAIT:
//          if (!cal1_wait_r) 
//            cal1_state_r <= #TCQ CAL1_PB_DETECT_EDGE;
//          
//        // Look for an edge on all DQ bits in current DQS group
//        CAL1_PB_DETECT_EDGE:
//          if (detect_edge_done_r) begin
//            if (found_stable_eye_r) begin 
//              // If we've found the left edge for all bits (or more precisely, 
//              // we've found the left edge, and then part of the stable 
//              // window thereafter), then proceed to positioning the CPT clock 
//              // right before the left margin
//              cnt_idel_dec_cpt_r <= #TCQ MIN_EYE_SIZE + 1;
//              cal1_state_r       <= #TCQ CAL1_PB_DEC_CPT_LEFT; 
//            end else begin
//              // If we've reached the end of the sampling time, and haven't 
//              // yet found the left margin of all the DQ bits, then:
//              if (!tap_limit_cpt_r) begin 
//                // If we still have taps left to use, then store current value 
//                // of read data, increment the capture clock, and continue to
//                // look for (left) edges
//                store_sr_req_r <= #TCQ 1'b1;
//                cal1_state_r    <= #TCQ CAL1_PB_INC_CPT;
//              end else begin
//                // If we ran out of taps moving the capture clock, and we
//                // haven't finished edge detection, then reset the capture 
//                // clock taps to 0 (gradually, gradually, one tap at a time... 
//                // we don't want to piss anybody off), then exit the per-bit 
//                // portion of the algorithm - i.e. proceed to adjust the 
//                // capture clock and DQ IODELAYs as
//                cnt_idel_dec_cpt_r <= #TCQ 6'd63; 
//                cal1_state_r       <= #TCQ CAL1_PB_DEC_CPT;
//              end
//            end
//          end
//            
//        // Increment delay for DQS
//        CAL1_PB_INC_CPT: begin
//          cal1_dlyce_cpt_r  <= #TCQ 1'b1;
//          cal1_dlyinc_cpt_r <= #TCQ 1'b1;
//          cal1_state_r      <= #TCQ CAL1_PB_INC_CPT_WAIT;
//        end
//        
//        // Wait for IODELAY for both capture and internal nodes within 
//        // ISERDES to settle, before checking again for an edge 
//        CAL1_PB_INC_CPT_WAIT: begin
//          cal1_dlyce_cpt_r  <= #TCQ 1'b0;
//          cal1_dlyinc_cpt_r <= #TCQ 1'b0;
//          if (!cal1_wait_r)
//            cal1_state_r <= #TCQ CAL1_PB_DETECT_EDGE;       
//        end 
//        // We've found the left edges of the windows for all DQ bits 
//        // (actually, we found it MIN_EYE_SIZE taps ago) Decrement capture 
//        // clock IDELAY to position just outside left edge of data window
//        CAL1_PB_DEC_CPT_LEFT:
//          if (cnt_idel_dec_cpt_r == 6'b000000)
//            cal1_state_r <= #TCQ CAL1_PB_DEC_CPT_LEFT_WAIT;
//          else begin 
//            cal1_dlyce_cpt_r   <= #TCQ 1'b1;
//            cal1_dlyinc_cpt_r  <= #TCQ 1'b0;
//            cnt_idel_dec_cpt_r <= #TCQ cnt_idel_dec_cpt_r - 1;
//          end       
//
//        CAL1_PB_DEC_CPT_LEFT_WAIT:
//          if (!cal1_wait_r)
//            cal1_state_r <= #TCQ CAL1_PB_DETECT_EDGE_DQ;
//
//        // If there is skew between individual DQ bits, then after we've
//        // positioned the CPT clock, we will be "in the window" for some
//        // DQ bits ("early" DQ bits), and "out of the window" for others
//        // ("late" DQ bits). Increase DQ taps until we are out of the 
//        // window for all DQ bits
//        CAL1_PB_DETECT_EDGE_DQ:
//          if (detect_edge_done_r)
//            if (found_edge_all_r) begin 
//              // We're out of the window for all DQ bits in this DQS group
//              // We're done with per-bit deskew for this group - now decr
//              // capture clock IODELAY tap count back to 0, and proceed
//              // with the rest of stage 1 calibration for this DQS group
//              cnt_idel_dec_cpt_r <= #TCQ tap_cnt_cpt_r;
//              cal1_state_r       <= #TCQ CAL1_PB_DEC_CPT;
//            end else
//              if (!idel_tap_limit_dq_pb_r)               
//                // If we still have DQ taps available for deskew, keep 
//                // incrementing IODELAY tap count for the appropriate DQ bits
//                cal1_state_r <= #TCQ CAL1_PB_INC_DQ;
//              else begin 
//                // Otherwise, stop immediately (we've done the best we can)
//                // and proceed with rest of stage 1 calibration
//                cnt_idel_dec_cpt_r <= #TCQ tap_cnt_cpt_r;
//                cal1_state_r <= #TCQ CAL1_PB_DEC_CPT;
//              end
//              
//        CAL1_PB_INC_DQ: begin
//          // Increment only those DQ for which an edge hasn't been found yet
//          cal1_dlyce_dq_r  <= #TCQ ~pb_found_edge_last_r;
//          cal1_dlyinc_dq_r <= #TCQ 1'b1;
//          cal1_state_r     <= #TCQ CAL1_PB_INC_DQ_WAIT;
//        end
//
//        CAL1_PB_INC_DQ_WAIT:
//          if (!cal1_wait_r)
//            cal1_state_r <= #TCQ CAL1_PB_DETECT_EDGE_DQ;
//
//        // Decrement capture clock taps back to initial value
//        CAL1_PB_DEC_CPT:
//          if (cnt_idel_dec_cpt_r == 6'b000000)
//            cal1_state_r <= #TCQ CAL1_PB_DEC_CPT_WAIT;
//          else begin
//            cal1_dlyce_cpt_r   <= #TCQ 1'b1;
//            cal1_dlyinc_cpt_r  <= #TCQ 1'b0;
//            cnt_idel_dec_cpt_r <= #TCQ cnt_idel_dec_cpt_r - 1;
//          end
//
//        // Wait for capture clock to settle, then proceed to rest of
//        // state 1 calibration for this DQS group
//        CAL1_PB_DEC_CPT_WAIT:
//          if (!cal1_wait_r) begin 
//            store_sr_req_r <= #TCQ 1'b1;
//            cal1_state_r    <= #TCQ CAL1_STORE_FIRST_WAIT;      
//          end
//
        // When first starting calibration for a DQS group, save the
        // current value of the read data shift register, and use this
        // as a reference. Note that for the first iteration of the
        // edge detection loop, we will in effect be checking for an edge
        // at IODELAY taps = 0 - normally, we are comparing the read data
        // for IODELAY taps = N, with the read data for IODELAY taps = N-1
        // An edge can only be found at IODELAY taps = 0 if the read data
        // is changing during this time (possible due to jitter)
        CAL1_STORE_FIRST_WAIT:  //0x02 
          if (!cal1_wait_r)
            cal1_state_r <= #TCQ CAL1_DETECT_EDGE_Q;
            
        // look for data window using Q IDELAY taps
        CAL1_DETECT_EDGE_Q: begin  //0x17
           //if (detect_edge_done_r) begin
            if (detect_edge_done_r && (idelay_taps > MIN_Q_VALID_TAPS) && (CLK_PERIOD > 2500) && (start_win_taps > 0) && idel_tap_limit_cpt_r ) begin
                   cal1_state_r <= #TCQ CAL1_IDEL_DEC_Q_ALL;  // decrement to the center of the start_win_taps and end_win_taps
                   //clk_in_vld_win <= 1'b1;
                   idel_dec_cntr <= #TCQ ((idel_tap_cnt_cpt_r-1) - start_win_taps) >>1;                   
                   end_win_taps <= #TCQ idel_tap_cnt_cpt_r-1;
                   qdly_inc_done_r <= #TCQ 1;
           
            end else if (idel_tap_limit_cpt_r)
              // Only one edge detected and ran out of taps since only one
              // bit time worth of taps available for window detection. This
              // can happen if at tap 0 DQS is in previous window which results
              // in only left edge being detected. Or at tap 0 DQS is in the
              // current window resulting in only right edge being detected.
              // Depending on the frequency this case can also happen if at
              // tap 0 DQS is in the left noise region resulting in only left
              // edge being detected.
              cal1_state_r <= #TCQ CAL1_IDEL_DEC_Q;  //0x1C
            else if (qdly_inc_done_r)   
              cal1_state_r <= #TCQ CAL1_IDEL_DEC_Q;   
            else if (~qdly_inc_done_r)
               // start for valid window check
               if (data_valid && ~start_win_detect) begin
                   start_win_detect <= #TCQ 1'b1;
                   start_win_taps <= #TCQ idel_tap_cnt_cpt_r;
                   idelay_taps     <= #TCQ idelay_taps +1; // only computes no. of data taps in valid window
                   cal1_state_r <= #TCQ CAL1_IDEL_STORE_OLD_Q; 
               // if in the valid window region, continue to increment idelay taps until an edge is detected
               end else if (start_win_detect && data_valid && ~detect_edge_done_r) begin
                   cal1_state_r <= #TCQ CAL1_IDEL_STORE_OLD_Q; 
                   idelay_taps     <= #TCQ idelay_taps + 1;
                   
               // when edge is detected : case where clock was in valid window to begin with
               end else if (detect_edge_done_r && (idelay_taps > MIN_Q_VALID_TAPS) && (CLK_PERIOD > 2500) && (start_win_taps == 0) ) begin
                   cal1_state_r <= #TCQ CAL1_IDEL_DEC_Q_ALL;  
                   idel_dec_cntr <= #TCQ idel_tap_cnt_cpt_r; // decrement all the data taps to 0, proceed to find clk taps
                   end_win_taps <= #TCQ idel_tap_cnt_cpt_r-1;
                   qdly_inc_done_r <= #TCQ 1;
                   
                // when edge is detected : case where clock was in invalid window at start
               end else if (detect_edge_done_r && (idelay_taps > MIN_Q_VALID_TAPS) && (CLK_PERIOD > 2500) && (start_win_taps > 0) ) begin
                   cal1_state_r <= #TCQ CAL1_IDEL_DEC_Q_ALL;  // decrement to the center of the start_win_taps and end_win_taps
                   //clk_in_vld_win <= 1'b1;
                   idel_dec_cntr <= #TCQ ((idel_tap_cnt_cpt_r-1) - start_win_taps) >>1;                   
                   end_win_taps <= #TCQ idel_tap_cnt_cpt_r-1;
                   qdly_inc_done_r <= #TCQ 1;
                   
               // when edge is detected
               end else if (detect_edge_done_r && idelay_taps > MIN_Q_VALID_TAPS) begin
                   cal1_state_r <= #TCQ CAL1_IDEL_DEC_Q;  //1C
                   end_win_taps <= #TCQ idel_tap_cnt_cpt_r-1;
                   qdly_inc_done_r <= #TCQ 1;
                   
               // when edge is detected, but possibly in the uncertainty region, reset start of window, continue to increment
               end else if (~data_valid && idelay_taps <= MIN_Q_VALID_TAPS) begin
                   cal1_state_r <= #TCQ CAL1_IDEL_STORE_OLD_Q; //0x1A
                   start_win_detect <= #TCQ 1'b0;
                   idelay_taps     <= #TCQ 0;
               // if rising edge falls in the fall window, continue to increment idelay taps
               end else if (~data_valid && ~start_win_detect ) begin
                    cal1_state_r <= #TCQ CAL1_IDEL_STORE_OLD_Q; 
                    idelay_taps     <= #TCQ 0;
               end
             
        end
        
         // Store the current read data into the read data shift register
        // before incrementing the tap count and doing this again 
        CAL1_IDEL_STORE_OLD_Q: begin
          store_sr_req_r <= #TCQ 1'b1;
          if (store_sr_done_r)begin
            cal1_state_r <= #TCQ CAL1_IDEL_INC_Q;
            new_cnt_cpt_r <= #TCQ 1'b0;
          end
        end
        
         
         // Increment Idelay 
        CAL1_IDEL_INC_Q: begin  //0x18
          cal1_state_r        <= #TCQ CAL1_IDEL_INC_Q_WAIT;
          if (~idel_tap_limit_cpt_r) begin
            cal1_dlyce_q_r    <= #TCQ 1'b1;
            cal1_dlyinc_q_r   <= #TCQ 1'b1;
          end else begin
            cal1_dlyce_q_r    <= #TCQ 1'b0;
            cal1_dlyinc_q_r   <= #TCQ 1'b0;
          end
        end

        // Wait for Phaser_In to settle, before checking again for an edge 
        CAL1_IDEL_INC_Q_WAIT: begin  //0x19
          cal1_dlyce_q_r    <= #TCQ 1'b0;
          cal1_dlyinc_q_r   <= #TCQ 1'b0; 
          if (!cal1_wait_r) 
             if (idelay_inc_taps_r > 0) begin  // case where idelay taps sufficient to center clock and data.
                if (idel_tap_cnt_cpt_r == idelay_inc_taps_r) 
                   cal1_state_r <= #TCQ CAL1_IDEL_DEC_CPT; // 0x08 idelay tap increment is done, proceed to decrement phaser taps to 0.
                else 
                   cal1_state_r <= #TCQ CAL1_IDEL_INC_Q;
             end else begin 
                cal1_state_r <= #TCQ CAL1_DETECT_EDGE_Q;  //0x17
             end
        end
        
          // Increment Phaser_IN delay for DQS
        CAL1_IDEL_DEC_Q_ALL: begin
            cal1_state_r        <= #TCQ CAL1_IDEL_DEC_Q_ALL_WAIT;
            idel_dec_cntr      <= idel_dec_cntr -1;
            cal1_dlyce_q_r    <= #TCQ 1'b1;
            cal1_dlyinc_q_r   <= #TCQ 1'b0;
          
        end

        // Wait for Phaser_In to settle, before checking again for an edge 
        CAL1_IDEL_DEC_Q_ALL_WAIT: begin
          cal1_dlyce_q_r    <= #TCQ 1'b0;
          cal1_dlyinc_q_r   <= #TCQ 1'b0; 
          if (!cal1_wait_r) begin
              if ((idel_dec_cntr == 6'h00) && (start_win_taps == 0))
                    cal1_state_r <= #TCQ CAL1_DETECT_EDGE;
                    
              else  if ((idel_dec_cntr == 6'h00) && (start_win_taps > 0))
                    cal1_state_r <= #TCQ CAL1_NEXT_DQS;
                    
              else 
                    cal1_state_r <= #TCQ CAL1_IDEL_DEC_Q_ALL;
          end 
        end

         // Increment Phaser_IN delay for DQS
         // CQ_CQB capturing scheme in QDR2+
        CAL1_IDEL_DEC_Q: begin
            cal1_state_r        <= #TCQ CAL1_IDEL_DEC_Q_WAIT;
            cal1_dlyce_q_r    <= #TCQ 1'b1;
            cal1_dlyinc_q_r   <= #TCQ 1'b0;
          
        end

        // Wait for Phaser_In to settle, before checking again for an edge 
        CAL1_IDEL_DEC_Q_WAIT: begin
          cal1_dlyce_q_r    <= #TCQ 1'b0;
          cal1_dlyinc_q_r   <= #TCQ 1'b0; 
          if (!cal1_wait_r)
            cal1_state_r <= #TCQ CAL1_DETECT_EDGE;
        end
     
        // Check for presence of data eye edge
        CAL1_DETECT_EDGE: begin//0x03
          if (detect_edge_done_r) begin
             if (tap_limit_cpt_r) begin
                if (~found_first_edge_r) begin 
                   first_edge_taps_r <= #TCQ tap_cnt_cpt_r; // if no edge previously detected, treat this as an edge,inorder to calculate tap delays.  
                end
                
                cal1_state_r <= #TCQ CAL1_CALC_IDEL_WAIT;  //0x20
             end else if (found_edge_r && ~data_valid) begin 
                   // Sticky bit - asserted after we encounter an edge, although
                   // the current edge may not be considered the "first edge" this
                   // just means we found at least one edge
                   found_first_edge_r <= #TCQ 1'b1;
                 
                   
                   // Both edges of data valid window found:
                   // If we've found a second edge after a region of stability
                   // then we must have just passed the second ("right" edge of
                   // the window. Record this second_edge_taps = current tap-1, 
                   // because we're one past the actual second edge tap, where 
                   // the edge taps represent the extremes of the data valid 
                   // window (i.e. smallest & largest taps where data still valid
                   if (found_first_edge_r && found_stable_eye_last_r) begin
                     found_second_edge_r <= #TCQ 1'b1;
                     second_edge_taps_r <= #TCQ tap_cnt_cpt_r - 1;
                     cal1_state_r <= #TCQ CAL1_CALC_IDEL_WAIT;    
                   end else if ((CLK_PERIOD <= 2500) && (tap_cnt_cpt_r < MIN_EYE_SIZE)) begin
                      first_edge_taps_r <= #TCQ tap_cnt_cpt_r;
                      cal1_state_r <= #TCQ CAL1_IDEL_STORE_OLD;
  
                   end else begin
                      first_edge_taps_r <= #TCQ tap_cnt_cpt_r;
                      cal1_state_r <= #TCQ CAL1_CALC_IDEL_WAIT;  //0x20
                   end
                 
             end else begin
              // Otherwise, if we haven't found an edge.... 
              // If we still have taps left to use, then keep incrementing
              cal1_state_r <= #TCQ CAL1_IDEL_STORE_OLD;
             end
          end
        end
        
              
        // Store the current read data into the read data shift register
        // before incrementing the tap count and doing this again 
        CAL1_IDEL_STORE_OLD: begin
          store_sr_req_r <= #TCQ 1'b1;
          if (store_sr_done_r)begin
            cal1_state_r <= #TCQ CAL1_IDEL_INC_CPT;
            new_cnt_cpt_r <= #TCQ 1'b0;
          end
        end
        
           
        // Increment Phaser_IN delay for DQS
        // for both PI and PO in QDR+
        CAL1_IDEL_INC_CPT: begin  //0x5
          cal1_state_r        <= #TCQ CAL1_IDEL_INC_CPT_WAIT;
          if (~tap_limit_cpt_r) begin
            cal1_dlyce_cpt_r    <= #TCQ 1'b1;
            cal1_dlyinc_cpt_r   <= #TCQ 1'b1;
          end else begin
            cal1_dlyce_cpt_r    <= #TCQ 1'b0;
            cal1_dlyinc_cpt_r   <= #TCQ 1'b0;
          end
        end

        // Wait for Phaser_In to settle, before checking again for an edge 
        CAL1_IDEL_INC_CPT_WAIT: begin  //0x6
          cal1_dlyce_cpt_r    <= #TCQ 1'b0;
          cal1_dlyinc_cpt_r   <= #TCQ 1'b0; 
          if (!cal1_wait_r)
            cal1_state_r <= #TCQ CAL1_DETECT_EDGE;
        end
        
         // allow for delay calculations to settle down.
        CAL1_CALC_IDEL_WAIT: begin  //0x20
          if (!cal1_wait_r)
            cal1_state_r <= #TCQ CAL1_CALC_IDEL;
        end
            
        // Calculate final value of Phaser_IN taps. At this point, one or both
        // edges of data eye have been found, and/or all taps have been
        // exhausted looking for the edges
        // NOTE: We're calculating the amount to decrement by, not the
        //  absolute setting for DQS.
        CAL1_CALC_IDEL: begin //0x07
          if (CLK_PERIOD > 2500 && (start_win_taps == 0) ) begin 
                    // if clk was in the correct window, but setup margin > hold margin, add delay to data to center. Make sure the delay difference is not within the per idelay tap delay range, 
                    // when q taps increments are not needed. 
                    //if (idelay_tap_delay > phaser_tap_delay) begin
                    if (idel_gt_phaser_delay) begin
                         // Divided both sides of the condition by IODELAY_TAP_RES
                         // if ((idel_minus_phaser_delay) < (2*IODELAY_TAP_RES))  begin
                         if (idel_minus_phaser_delay < 2)  begin   
                             idelay_inc_taps_r  <= #TCQ 0; 
                             cnt_idel_dec_cpt_r <= #TCQ tap_cnt_cpt_r; // reset the clock taps back   
                             cal1_state_r       <= #TCQ CAL1_IDEL_DEC_CPT;
                         end else begin
                            //idelay_inc_taps_r <= ((idel_minus_phaser_delay >>1 )/IODELAY_TAP_RES);
                            idelay_inc_taps_r <= (idel_minus_phaser_delay >> 1); 
                            cnt_idel_dec_cpt_r <= #TCQ tap_cnt_cpt_r; // reset the clock taps back    
                            cal1_state_r      <= #TCQ CAL1_IDEL_INC_Q;   
                         end  
                       
                    //if  clk was in the correct window, but setup margin < hold margin , add delay to clock.             
                    end else begin 
                    
                         // no idelay tap increments
                         // for frequencies greater than 400 Mhz, no taps to decrement. 64 taps of fine delay should place the clock close to the center of the window
                          idelay_inc_taps_r <=  #TCQ 0; 
                          cnt_idel_dec_cpt_r  <= #TCQ tap_cnt_cpt_r - phaser_dec_taps;
                          cal1_state_r <= #TCQ CAL1_IDEL_DEC_CPT;        
                    end    
                 //end      
                        
          // CASE1: If 2 edges found.
          end else begin          
          
             if (found_second_edge_r) begin 
                  cnt_idel_dec_cpt_r <=  #TCQ ((second_edge_taps_r - first_edge_taps_r)>>1) + 1;   
                  dbg_stg1_calc_edge[2] <= #TCQ 'b1;
             // first_edge_taps_r is indeed the start of the window
             end else if (first_edge_taps_r <= MIN_EYE_SIZE) begin
                    cnt_idel_dec_cpt_r <=  #TCQ (32 - first_edge_taps_r);
                    dbg_stg1_calc_edge[0] <= #TCQ 'b1;
             // firs edge detected is not the start but instead the end of the window.. THis can only happen when the initial data alignment ends up positioning 
             // the lock inside the valid window.
             
             end else if (first_edge_taps_r > MIN_EYE_SIZE) begin
                    cnt_idel_dec_cpt_r <=  #TCQ ((tap_cnt_cpt_r - first_edge_taps_r) + (first_edge_taps_r)>>1) ;
                    dbg_stg1_calc_edge[1] <= #TCQ 'b1;
             end else begin
                    // No edges detected 
                    cnt_idel_dec_cpt_r  <=  #TCQ ((tap_cnt_cpt_r)>>1) + 1;     
                    dbg_stg1_calc_edge[3] <= #TCQ 'b1;
             end  
             
             
            // Now use the value we just calculated to decrement CPT taps
            // to the desired calibration point
            cal1_state_r <= #TCQ CAL1_IDEL_DEC_CPT; //0x08 
          end
        end
         
        
        // decrement capture clock for final adjustment - center
        // capture clock in middle of data eye. This adjustment will occur
        // only when both the edges are found usign CPT taps. Must do this
        // incrementally to avoid clock glitching (since CPT drives clock
        // divider within each ISERDES)
        CAL1_IDEL_DEC_CPT: begin  //0x08
          cal1_dlyce_cpt_r  <= #TCQ 1'b1;
          cal1_dlyinc_cpt_r <= #TCQ 1'b0;
		  pi_gap_enforcer   <= #TCQ PI_ADJ_GAP;
          // once adjustment is complete, we're done with calibration for
          // this DQS, repeat for next DQS
          cnt_idel_dec_cpt_r <= #TCQ cnt_idel_dec_cpt_r - 1;

          if ((cnt_idel_dec_cpt_r == 6'b000001)  && 
                     ((MEMORY_IO_DIR == "BIDIR") || ((MEMORY_IO_DIR == "UNIDIR") &&  (CLK_PERIOD > 2500)))) begin
                     
             if (CPT_CLK_CQ_ONLY == "FALSE")  // this only apply to QDR2 memory.
                 cal1_state_r <= #TCQ CAL1_FALL_DETECT_EDGE_WAIT;
             else
                 cal1_state_r <= #TCQ CAL1_NEXT_DQS;// CAL1_NEXT_DQS;  //0x0A	 
                                                            //CAL1_FALL_DETECT_EDGE_WAIT for CQ_CQB
             rise_detect_done <= #TCQ 1'b1;
            
          end else if ((cnt_idel_dec_cpt_r == 6'b000001)  && (CLK_PERIOD <= 2500)) begin
             // finish decrement PI's tap to its final calculated position; jump to deal with FALL data bit window.
          
          
             rise_detect_done <= #TCQ 1'b1;

             //fall_win_det_start_taps_r <= #TCQ tap_cnt_cpt_r;
             cal1_state_r <= #TCQ CAL1_FALL_DETECT_EDGE_WAIT;   //0x28
          end else begin
            cal1_state_r <= #TCQ CAL1_IDEL_DEC_CPT_WAIT;  //0x09
          end        end
           
      /*    if (cnt_idel_dec_cpt_r == 6'b000001)
            cal1_state_r <= #TCQ CAL1_NEXT_DQS;
          else
            cal1_state_r <= #TCQ CAL1_IDEL_DEC_CPT_WAIT;
        end*/

        CAL1_IDEL_DEC_CPT_WAIT: begin  //0x09
          cal1_dlyce_cpt_r  <= #TCQ 1'b0;
          cal1_dlyinc_cpt_r <= #TCQ 1'b0;
          //Decrement our counter, then once it hits zero we can move on
		  if (pi_gap_enforcer != 'b0)
		    pi_gap_enforcer   <= #TCQ pi_gap_enforcer - 1;
		  else
		    pi_gap_enforcer   <= #TCQ pi_gap_enforcer;
		  
		  if (pi_gap_enforcer == 'b0)
            cal1_state_r <= #TCQ CAL1_IDEL_DEC_CPT;
		  else
		    cal1_state_r <= #TCQ CAL1_IDEL_DEC_CPT_WAIT;
        end
        
        // wait state to determine cq center taps.
        CAL1_FALL_DETECT_EDGE_WAIT: begin  //0x28
          cal1_dlyce_cpt_r  <= #TCQ 1'b0;
          cal1_dlyinc_cpt_r <= #TCQ 1'b0;
          //Decrement our counter, then once it hits zero we can move on
		  if (pi_gap_enforcer != 'b0)
		    pi_gap_enforcer   <= #TCQ pi_gap_enforcer - 1;
		  else
		    pi_gap_enforcer   <= #TCQ pi_gap_enforcer;
		  
		  if (pi_gap_enforcer == 'b0)
            cal1_state_r <= #TCQ CAL1_IDEL_FALL_DEC_CPT;
		  else
		    cal1_state_r <= #TCQ CAL1_FALL_DETECT_EDGE_WAIT;
        end 
        
        
       CAL1_IDEL_FALL_DEC_CPT: begin  //0x29
          cal1_dlyce_cpt_r  <= #TCQ 1'b1;
          cal1_dlyinc_cpt_r <= #TCQ 1'b0;
		  pi_gap_enforcer   <= #TCQ PI_ADJ_GAP;
          // once adjustment is complete, we're done with calibration for
          // this DQS, repeat for next DQS
          //cnt_idel_dec_cpt_r <= #TCQ cnt_idel_dec_cpt_r - 1;
          if (tap_cnt_cpt_r == 6'h03) 
              cal1_state_r <= CAL1_FALL_DETECT_EDGE;
          else 
            cal1_state_r <= #TCQ CAL1_IDEL_FALL_DEC_CPT_WAIT;
          
        end
        
        CAL1_IDEL_FALL_DEC_CPT_WAIT: begin
          cal1_dlyce_cpt_r  <= #TCQ 1'b0;
          cal1_dlyinc_cpt_r <= #TCQ 1'b0;
          //Decrement our counter, then once it hits zero we can move on
		  if (pi_gap_enforcer != 'b0)
		    pi_gap_enforcer   <= #TCQ pi_gap_enforcer - 1;
		  else
		    pi_gap_enforcer   <= #TCQ pi_gap_enforcer;
			
		  if (pi_gap_enforcer == 'b0)
            cal1_state_r <= #TCQ CAL1_IDEL_FALL_DEC_CPT;
		  else
		    cal1_state_r <= #TCQ CAL1_IDEL_FALL_DEC_CPT_WAIT;
        end  
        
                // since cq# is always delayed along with cq so far, the cq# phaser taps should be non-zero and it should be in the fall window to begin with.
       // if the data is not in the valid window, then continue to decrement the cq# phaser taps.
       
      CAL1_FALL_DETECT_EDGE : begin  //0x21
          cal1_dlyce_cpt_r  <= #TCQ 1'b0;
          cal1_dlyinc_cpt_r <= #TCQ 1'b0;
          
          if (detect_edge_done_r) begin
            if (cqn_tap_limit_cpt_r) begin
                fall_win_det_end_taps_r <= #TCQ tap_cnt_cpt_r;
                cal1_state_r <= #TCQ CAL1_FALL_CALC_DELAY;
                
                          
            // second edge of fall window - stop incrementing              
            //end else if  (fall_first_edge_det_done && found_edge_r && ~data_valid && found_stable_eye_last_r && ((tap_cnt_cpt_r - fall_win_det_start_taps_r) > 6'h10)) begin    
            end else if  (fall_first_edge_det_done && ~data_valid && ((tap_cnt_cpt_r - fall_win_det_start_taps_r) > 8)) begin   
               // decide if the rising edge of falling capture clock is close to PO's tap 0.
               //  Assume PI found 32 bits tap window for rising bit, ideally PO should also find 32 bits tap window for falling bit.
               //
               //
               //                  PO's tap 0                 16                32               
               //                           |........:........:........:........:........:........:
               //
               //             Fall bit valid window
               //case 1 : X--------:--------:--------:--------X                    detect edge when PO taps is at 16
			   //
               //case 2 :      X--------:--------:--------:--------X               detect edge when PO taps is at 20
			   //
               //
               //case 3:                X--------:--------:--------:--------X      detect edge when PO taps is at 28
			   //
               //case 4:                         X--------:--------:--------:--------X      detect edges when PO taps is at 4 and 36
               //
               // "first_edge_taps_r" latches the rising edge window size.
                //if ((first_edge_taps_r - tap_cnt_cpt_r) > 10) begin
                  if ((tap_cnt_cpt_r - 4 ) <= first_edge_taps_r[5:1]) begin
                
                     cal1_state_r <= #TCQ CAL1_FALL_IDEL_INC_Q;
                     stored_idel_tap_cnt_cpt_r <= idel_tap_cnt_cpt_r;
                     end
                else begin
                     cal1_state_r <= #TCQ CAL1_FALL_CALC_DELAY;
                end
                     fall_win_det_end_taps_r <= #TCQ tap_cnt_cpt_r - 1;
                     
          
            // first edge detection - the first valid data, continue to increment         
           end else if (~fall_first_edge_det_done && data_valid && fall_win_det_start_taps_r == 6'h00) begin
               // Otherwise, if we haven't found an edge.... 
               // If we still have taps left to use, then keep incrementing
               fall_win_det_start_taps_r <= #TCQ tap_cnt_cpt_r;
               fall_first_edge_det_done  <= 1'b0;
               cal1_state_r <= #TCQ CAL1_FALL_IDEL_STORE_OLD;   //0x22
                     
            // assert fall_first_edge_det_done if window is valid for atleast 15 taps, continue to increment until edge found      
            //                                                                                                   was F
           end else if (~fall_first_edge_det_done && data_valid && ((tap_cnt_cpt_r - fall_win_det_start_taps_r) >= 6'h0A)) begin
                // Otherwise, if we haven't found an edge.... 
                // If we still have taps left to use, then keep incrementing
                fall_first_edge_det_done  <= 1'b1;
                cal1_state_r <= #TCQ CAL1_FALL_IDEL_STORE_OLD;   //0x22
             
             // smaller window seen, reset flag and start again.
           end else if (~fall_first_edge_det_done && ~data_valid && ((tap_cnt_cpt_r - fall_win_det_start_taps_r) < 6'h0A)) begin
                // Otherwise, if we haven't found an edge.... 
                // If we still have taps left to use, then keep incrementing
                fall_win_det_start_taps_r <= #TCQ 6'h00;// reset start of window.
                fall_first_edge_det_done  <= 1'b0;
                cal1_state_r <= #TCQ CAL1_FALL_IDEL_STORE_OLD;     //0x22           
                    
                                  
            end else begin
                // Otherwise, if we haven't found an edge.... 
                // If we still have taps left to use, then keep incrementing
                cal1_state_r <= #TCQ CAL1_FALL_IDEL_STORE_OLD;      //0x22  
            end
         end
       end
        
  
       CAL1_FALL_IDEL_STORE_OLD : begin
                 store_sr_req_r <= #TCQ 1'b1;
                 if (store_sr_done_r)begin
                         cal1_state_r <= #TCQ CAL1_FALL_INC_CPT;
                         new_cnt_cpt_r <= #TCQ 1'b0;
                 end
        end
                                                                           
       
       CAL1_FALL_INC_CPT: begin  //0x23
           cal1_state_r          <= #TCQ CAL1_FALL_INC_CPT_WAIT;
          if (~cqn_tap_limit_cpt_r) begin
            cal1_dlyce_cpt_r    <= #TCQ 1'b1;
            cal1_dlyinc_cpt_r   <= #TCQ 1'b1;
          end else begin
            cal1_dlyce_cpt_r    <= #TCQ 1'b0;
            cal1_dlyinc_cpt_r   <= #TCQ 1'b0;
          end
        end
          
         // Wait for Phaser_In to settle, before checking again for an edge 
       CAL1_FALL_INC_CPT_WAIT: begin  //0x24
          cal1_dlyce_cpt_r    <= #TCQ 1'b0;
          cal1_dlyinc_cpt_r   <= #TCQ 1'b0; 
          if (!cal1_wait_r)
            cal1_state_r <= #TCQ CAL1_FALL_DETECT_EDGE;
        end
        
       CAL1_FALL_CALC_DELAY:  begin //0x25 cnt_rise_center_taps
             
            // if (( fall_win_det_end_taps_r - fall_win_det_start_taps_r) > cnt_rise_center_taps) begin
            //       //fall_dec_taps_r <= tap_cnt_cpt_r - ( fall_win_det_end_taps_r - (fall_win_det_start_taps_r + cnt_rise_center_taps)); // no. of taps to increment cq# by
            //       fall_dec_taps_r <= tap_cnt_cpt_r - ( fall_win_det_end_taps_r -  cnt_rise_center_taps); // no. of taps to increment cq# by
            //       cal1_state_r <= #TCQ CAL1_FALL_FINAL_DEC_TAP;
            // end else  if (( fall_win_det_end_taps_r - fall_win_det_start_taps_r) < cnt_rise_center_taps) begin
            //       fall_dec_taps_r <= tap_cnt_cpt_r  -  cnt_rise_center_taps;// no. of taps to decrement cq# by
            //       cal1_state_r <= #TCQ CAL1_FALL_FINAL_DEC_TAP;
            // end else begin
            //       fall_dec_taps_r <= 'b0;
            //       cal1_state_r <=  #TCQ CAL1_NEXT_DQS;
            // end  
            
//            if (fall_win_det_start_taps_r > 6'd54)   // ??? **** is this a good assumption		
            if (fall_win_det_start_taps_r > 6'h28) 

               fall_dec_taps_r <= 6'h01;
            else if (set_fall_capture_clock_at_tap0)
                 fall_dec_taps_r <= #TCQ fall_win_det_end_taps_r;
               
            else begin  
               fall_dec_taps_r <= ( fall_win_det_end_taps_r - fall_win_det_start_taps_r) >> 1;
            end
            
            cal1_state_r <= #TCQ CAL1_FALL_FINAL_DEC_TAP;
            
         end
        
              
        CAL1_FALL_FINAL_DEC_TAP: begin //0x26
          cal1_dlyce_cpt_r  <= #TCQ 1'b1;
          cal1_dlyinc_cpt_r <= #TCQ 1'b0;
		  pi_gap_enforcer   <= #TCQ PI_ADJ_GAP;
          // once adjustment is complete, we're done with calibration for
          // this DQS, repeat for next DQS
          fall_dec_taps_r <= #TCQ fall_dec_taps_r - 1;
              
          if (fall_dec_taps_r == 6'b000001)  begin
            cal1_state_r <= #TCQ CAL1_NEXT_DQS;   //0xA
          end else begin
            cal1_state_r <= #TCQ CAL1_FALL_FINAL_DEC_TAP_WAIT;  //0x27
          end
        end
        
        CAL1_FALL_FINAL_DEC_TAP_WAIT: begin  //0x27
          cal1_dlyce_cpt_r  <= #TCQ 1'b0;
          cal1_dlyinc_cpt_r <= #TCQ 1'b0;
          //Decrement our counter, then once it hits zero we can move on
		  if (pi_gap_enforcer != 'b0)
		    pi_gap_enforcer   <= #TCQ pi_gap_enforcer - 1;
		  else
		    pi_gap_enforcer   <= #TCQ pi_gap_enforcer;
			
		  if (pi_gap_enforcer == 'b0)
            cal1_state_r <= #TCQ CAL1_FALL_FINAL_DEC_TAP;
		  else
		    cal1_state_r <= #TCQ CAL1_FALL_FINAL_DEC_TAP_WAIT;
       end         
       
       // STATE 31,32,33 and 34 are new added states for case that the falling data capture clock edge is far away
       // from rising data capture clock edge. There is variation of skew between PHASERS.
       // Rising window taps could have enough taps e.g. 36 taps. And the falling bit time has valid data at tap 0 of
       // PO and end at e.g. 14 taps. In this case, the tap 0 is roughly actual center of the falling bit time. And the
       // PO tap should set to zero. The new added states is to adjust the IDELAY taps temporary when we detects 
       // end tap of falling data  .  If valid data appears again for two IDELAY taps, for sure tap 0 is not
       // left edge of falling bit data. We can safely set the PO tap at ZERO.
       
       
        CAL1_FALL_IDEL_INC_Q: begin  //0x31m he 
          cal1_state_r        <= #TCQ CAL1_FALL_IDEL_INC_Q_WAIT;
          if (~idel_tap_limit_cpt_r) begin
            cal1_dlyce_q_r    <= #TCQ 1'b1;
            cal1_dlyinc_q_r   <= #TCQ 1'b1;
          end else begin
            cal1_dlyce_q_r    <= #TCQ 1'b0;
            cal1_dlyinc_q_r   <= #TCQ 1'b0;
          end
        end

        // Wait for Phaser_In to settle, before checking again for an edge 
        CAL1_FALL_IDEL_INC_Q_WAIT: begin  //0x32
          cal1_dlyce_q_r    <= #TCQ 1'b0;
          cal1_dlyinc_q_r   <= #TCQ 1'b0; 
          if (!cal1_wait_r) 				 
             // For 400 MHz and above design, each idelay tap is equivalent about 80 ps. 
             // Temporary move the idelay taps for the Q input and test if getting valid
             // falling valid data pattern. After the test, the idelay tap value is restored.

             if (fall_match &&  ( idel_tap_cnt_cpt_r - stored_idel_tap_cnt_cpt_r) < 2 ) begin  // 
             // 
                   cal1_state_r <= #TCQ CAL1_FALL_IDEL_INC_Q;  //31
             end else begin 
                if (fall_match)
                    set_fall_capture_clock_at_tap0 <= 1'b1;
                else
                    set_fall_capture_clock_at_tap0 <= 1'b0;
            
                cal1_state_r <= #TCQ CAL1_FALL_IDEL_RESTORE_Q;  //0x33
             end
        end
        
       
       
        CAL1_FALL_IDEL_RESTORE_Q: begin  //0x33
          cal1_state_r        <= #TCQ CAL1_FALL_IDEL_RESTORE_Q_WAIT;
          if (~idel_tap_limit_cpt_r) begin
            cal1_dlyce_q_r    <= #TCQ 1'b1;
            cal1_dlyinc_q_r   <= #TCQ 1'b0;
          end else begin
            cal1_dlyce_q_r    <= #TCQ 1'b0;
            cal1_dlyinc_q_r   <= #TCQ 1'b0;
          end
        end
       
       
         CAL1_FALL_IDEL_RESTORE_Q_WAIT: begin  //0x34
          cal1_dlyce_q_r    <= #TCQ 1'b0;
          cal1_dlyinc_q_r   <= #TCQ 1'b0; 
          if (!cal1_wait_r) 
             if (idel_tap_cnt_cpt_r != stored_idel_tap_cnt_cpt_r) begin  // case where idelay taps sufficient to center clock and data.
                   cal1_state_r <= #TCQ CAL1_FALL_IDEL_RESTORE_Q;  //19
             end else begin 
                cal1_state_r <= #TCQ CAL1_FALL_CALC_DELAY;  //0x25
             end
        end
      
       
       
       
       
       

        // Determine whether we're done, or have more DQS's to calibrate
        // Also request precharge after every byte, as appropriate
        CAL1_NEXT_DQS: begin
          cal1_prech_req_r  <= #TCQ 1'b1;
          cal1_dlyce_cpt_r  <= #TCQ 1'b0;
          cal1_dlyinc_cpt_r <= #TCQ 1'b0;
          // Prepare for another iteration with next DQS group
          found_first_edge_r  <= #TCQ 1'b0;
          found_second_edge_r <= #TCQ 1'b0;
          first_edge_taps_r <= #TCQ 'd0;
          second_edge_taps_r <= #TCQ 'd0;
           
          // Wait until precharge that occurs in between calibration of
          // DQS groups is finished
          if (prech_done) begin
            if (SIM_CAL_OPTION == "FAST_CAL") begin
              //rdlvl_rank_done_r <= #TCQ 1'b1;
              cal1_state_r <= #TCQ CAL1_REGL_LOAD;
            end else if (cal1_cnt_cpt_r >= DQS_WIDTH-1) begin
              // All DQS groups in a rank done
              rdlvl_rank_done_r <= #TCQ 1'b1;
              if (rnk_cnt_r == RANKS-1) begin
                // All DQS groups in all ranks done
                cal1_state_r <= #TCQ CAL1_REGL_LOAD;
              end else begin
                // Process DQS groups in next rank
                rnk_cnt_r      <= #TCQ rnk_cnt_r + 1;
                new_cnt_cpt_r  <= #TCQ 1'b1;
                cal1_cnt_cpt_r <= #TCQ 'b0;
                cal1_state_r   <= #TCQ CAL1_NEW_DQS_WAIT;
              end         
            end else begin
              // Process next DQS group
              new_cnt_cpt_r     <= #TCQ 1'b1;
              qdly_inc_done_r   <= #TCQ 1'b0;   
              start_win_taps    <= #TCQ 'b0;
              end_win_taps      <= #TCQ 'b0;
              idelay_taps       <= #TCQ 'b0;
              idelay_inc_taps_r <= #TCQ 'b0;
              idel_dec_cntr     <= #TCQ 'b0;
              rise_detect_done  <= #TCQ 'b0;
              fall_first_edge_det_done  <= 1'b0;
              fall_win_det_start_taps_r <= #TCQ 'b0;
              fall_win_det_end_taps_r   <= #TCQ 'b0;
              cal1_cnt_cpt_r    <= #TCQ cal1_cnt_cpt_r + 1;
              dbg_stg1_calc_edge <= #TCQ 0; //clear our flag for each byte
              cal1_state_r      <= #TCQ CAL1_NEW_DQS_WAIT;
            end
          end
        end

        // Load rank registers in Phaser_IN
        CAL1_REGL_LOAD: begin
          rdlvl_rank_done_r <= #TCQ 1'b0;
          cal1_prech_req_r  <= #TCQ 1'b0;
          rnk_cnt_r         <= #TCQ 2'b00;
          
          if ((regl_rank_cnt == RANKS-1) && 
              ((regl_dqs_cnt == DQS_WIDTH-1) && (done_cnt == 4'd1)))
             cal1_state_r <= #TCQ CAL1_DONE;
          else
             cal1_state_r <= #TCQ CAL1_REGL_LOAD;
        end
        
        // Done with this stage of calibration
        // if used, allow DEBUG_PORT to control taps
        CAL1_DONE: begin
          rdlvl_stg1_done   <= #TCQ 1'b1;
        end
        
       default : begin
          cal1_state_r <= #TCQ CAL1_IDLE;
       end

      endcase
    end

  // generate an error signal for each byte lane in the event no window found
  genvar nd_i;
  generate
    for (nd_i=0; nd_i < DQS_WIDTH; nd_i=nd_i+1) begin : nd_rdlvl_err
      always @ (posedge clk)
      begin	
	    if (rst)
	      dbg_phy_rdlvl_err[nd_i] <= #TCQ 'b0;
	    else if (nd_i == cal1_cnt_cpt_r)
	      dbg_phy_rdlvl_err[nd_i] <= #TCQ dbg_stg1_calc_edge[0];
        else
	      dbg_phy_rdlvl_err[nd_i] <= #TCQ dbg_phy_rdlvl_err[nd_i];
      end
	end
  endgenerate 
 
 


endmodule
