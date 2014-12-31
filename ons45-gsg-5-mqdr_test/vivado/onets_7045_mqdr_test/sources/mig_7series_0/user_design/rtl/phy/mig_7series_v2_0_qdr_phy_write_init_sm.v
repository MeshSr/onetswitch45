//*****************************************************************************
//(c) Copyright 2009 - 2013 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is noot a license and does not grant any
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

////////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : %version 
//  \   \         Application        : MIG
//  /   /         Filename           : qdr_phy_write_init_sm.v
// /___/   /\     Date Last Modified : $date$
// \   \  /  \    Date Created       : Nov 12, 2008 
//  \___\/\___\
//
//Device: 7 Series
//Design: QDRII+ SRAM
//
//Purpose:
//    This module
//  1. Is the initialization state machine for delay calibration before regular
//     memory transactions begin.
//  2. This sm generates control, address, and data.
//
//Revision History: 6/8/2012  Added SIM_BYPASS for OCLK_Delay Calibration logic.
//                                      8/10/2012 Added write path deskew logic.
//                  12/12/2012 Fixed Vivado warnings
//                  5/15/2013  Improved K clock error correction algorithm logic
//                             by using PO stage 2 delay line of non-K byte lane. 
//
////////////////////////////////////////////////////////////////////////////////


`timescale 1ps/1ps

module mig_7series_v2_0_qdr_phy_write_init_sm #
(
  parameter CLK_PERIOD      = 2500,   //Memory Clk Period (in ps)  
  parameter CLK_STABLE      = 2048,   //Cycles till CQ/CQ# are stable 
  parameter BYTE_LANE_WITH_DK = 4'h00,// BYTE vector that shows which byte lane has K clock.
                                      // "1000" : byte group 3
                                      // "0001" : byte group 0
  parameter N_DATA_LANES    = 4,
  parameter RST_ACT_LOW     = 1,      //sys reset is active low   
  parameter BURST_LEN       = 4,    //Burst Length
  parameter CK_WIDTH        = 1,
  parameter ADDR_WIDTH      = 19,   //Address Width
  parameter DATA_WIDTH      = 72,   //Data Width  
  parameter BW_WIDTH        = 8,     
  parameter SIMULATION      = "TRUE",
  parameter SIM_BYPASS_INIT_CAL = "OFF",
  parameter PO_ADJ_GAP     = 7,    //Time to wait between PO adj
  parameter TCQ            = 100   //Register Delay
)
(
  input                          clk,              //main system half freq clk
  input                          sys_rst,
  input                          rst_wr_clk,       //main write path reset  
  input                          ck_addr_cmd_delay_done,  // 90 degree offset on address/cmd done     
  input                          edge_adv_cal_done,//phase alignment done, proceed to latency calibration.
  input                          rdlvl_stg1_done,  // first stage centering done
  input                          read_cal_done,    // Read calibration done 

  output reg                     init_cal_done,    // Init calibration done 
  output wire                    edge_adv_cal_start,
  output reg                     rdlvl_stg1_start,
  output reg                     cal_stage2_start,
  
  input [N_DATA_LANES-1:0]       phase_valid,
  
  //  
  output                         rst_clk,
  
  //Initialization signals
  
  output reg                     init_done,        //init done, cal can begin
  output reg  [DATA_WIDTH*2-1:0] init_wr_data0,    //init sm write data 0
  output reg  [DATA_WIDTH*2-1:0] init_wr_data1,    //init sm write data 1
  output reg  [ADDR_WIDTH-1:0]   init_wr_addr0,    //init sm write addr 0
  output reg  [ADDR_WIDTH-1:0]   init_wr_addr1,    //init sm write addr 1
  output reg  [ADDR_WIDTH-1:0]   init_rd_addr0,    //init sm read addr 0
  output reg  [ADDR_WIDTH-1:0]   init_rd_addr1,    //init sma read addr 1
  output reg  [1:0]              init_rd_cmd,      //init sm read command
  output reg  [1:0]              init_wr_cmd,      //init sm write command
  output reg                    mem_dll_off_n,

  //write calibration signals to adjust PO's stage 2 and stage 3 delays 
  input [8:0]                    po_counter_read_val,  
  output reg                     cal1_rdlvl_restart,
  output reg                     wrcal_en,
  output reg                     wrlvl_po_f_inc,
  output reg                        wrlvl_po_f_dec,
  output reg                     wrlvl_calib_in_common,
  output wire [1:0]              wrcal_byte_sel,
  output reg                     po_sel_fine_oclk_delay,
  
  //Debug Signals
  input [2:0]                    dbg_MIN_STABLE_EDGE_CNT,
  output wire [255:0]            dbg_wr_init,
  input                          dbg_phy_init_wr_only,
  input                          dbg_phy_init_rd_only ,    
  input                          dbg_SM_No_Pause,

  input                          dbg_SM_en


);

// need to bring out initialization command, data, mem_dll_off_n,

  //Local Parameter Declarations
  //Four states in the init sm, one-hot encoded
  localparam CAL_INIT                    =  21'b000000000000000000001;
  localparam CAL1_WRITE                  =  21'b000000000000000000010; 
  localparam CAL1_READ                   =  21'b000000000000000000100; 
  localparam CAL2_WRITE                  =  21'b000000000000000001000; 
  localparam CAL2_READ_CONT              =  21'b000000000000000010000; 
  localparam CAL2_READ                   =  21'b000000000000000100000; 
  localparam OCLK_RECAL                  =  21'b000000000000001000000; 
  localparam PO_ADJ                      =  21'b000000000000010000000; 
  localparam CAL2_READ_WAIT              =  21'b000000000000100000000; 
  localparam CAL_DONE                    =  21'b000000000001000000000; 
  localparam CAL_DONE_WAIT               =  21'b000000000010000000000; 
  localparam PO_ADJ_WAIT                 =  21'b000000000100000000000; 
  localparam PO_STG2_INC_TO_RIGHT_EDGE   =  21'b000000001000000000000; 
  localparam STG2_SHIFT_90               =  21'b000000010000000000000; 
  localparam NEXT_BYTE_DESKEW            =  21'b000000100000000000000; 
  localparam BACK2RIGHT_EDGE             =  21'b000001000000000000000; 
  localparam K_CENTER_SEARCH             =  21'b000010000000000000000; 
  localparam K_CENTER_SEARCH_WAIT        =  21'b000100000000000000000; 
  localparam MOVE_K_TO_CENTER            =  21'b001000000000000000000; 
  localparam NON_K_CENTERING             =  21'b010000000000000000000; 
  localparam RECORD_PO_TAP_VALUE         =  21'b100000000000000000000; 

  //Stage 1 Calibration Pattern
  //00FF_FF00
  //00FF_00FF
  // Based on Timing analysis, stage1 data can use PRBS similar to DDR3 or the same pattern in V6
  localparam [DATA_WIDTH*8-1:0] DATA_STAGE1 = 
                                {{DATA_WIDTH{1'b0}}, {DATA_WIDTH{1'b1}},
                                 {DATA_WIDTH{1'b0}}, {DATA_WIDTH{1'b1}},
                                 {DATA_WIDTH{1'b1}}, {DATA_WIDTH{1'b0}},
                                 {DATA_WIDTH{1'b0}}, {DATA_WIDTH{1'b1}}};
                                 

  //Stage 2 Calibration Pattern 
  //AAAA_AAAA
  localparam  PATTERN_5 = 9'h155;
  localparam  PATTERN_A = 9'h0AA;
  
  // stage2 - F-0-5_A pattern
  
  // R0_F0_R1_F1 data pattern                                            
  localparam [DATA_WIDTH*4-1:0] DATA_STAGE2 = { {BW_WIDTH{PATTERN_A}},{BW_WIDTH{PATTERN_5}},
                                                {DATA_WIDTH{1'b0}},{DATA_WIDTH{1'b1}}};  
                                                
  
  // # of clock cycles to delay deassertion of reset. Needs to be a fairly
  // high number not so much for metastability protection, but to give time
  // for reset (i.e. stable clock cycles) to propagate through all state
  // machines and to all control signals (i.e. not all control signals have
  // resets, instead they rely on base state logic being reset, and the effect
  // of that reset propagating through the logic). Need this because we may not
  // be getting stable clock cycles while reset asserted (i.e. since reset
  // depends on DCM lock status)
  localparam RST_SYNC_NUM = 5;  //*FIXME*
   
  //Calculate the number of cycles needed for 200 us.  This is used to
  //initialize the memory device and turn off the dll signal to it.
  localparam INIT_DONE_CNT = (SIM_BYPASS_INIT_CAL != "OFF") 
                          ? (4*1000*1000/(CLK_PERIOD*2)) : (200*1000*1000/(CLK_PERIOD*2));
 
  localparam INIT_DATA_PATTERN = "CLK_PATTERN" ; // PRBS_PATTERN      
  localparam INIT_ADDR_WIDTH = 3;                  
  localparam INIT_WR_ADDR_CNT = (INIT_DATA_PATTERN == "CLK_PATTERN" )? 9'h002 : 9'h100;

  //Wire Declarations
  reg   [20:0]              phy_init_cs;
  reg   [20:0]              phy_init_cs_reg;
  reg   [20:0]              phy_init_ns;
  reg   [6:0]              rst_delayed = 0;
  reg                      cal_stage2_start_r;
  reg   [2:0]              addr_cntr; 
  reg   [1:0]              init_wr_cmd_d;
  reg   [1:0]              init_rd_cmd_d;
  reg                      incr_addr;
                           
  wire                     sys_rst_act_hi;
  
  // initialization signals
  reg                     init_cnt_done;
  reg                     init_cnt_done_r;
  reg                     cq_stable;
  reg     [14:0]          cq_cnt;
  reg     [16:0]          init_cnt;
  (* shreg_extract = "no" *)
  (* max_fanout = "50" *)
  reg [RST_SYNC_NUM-1:0]  rst_clk_sync_r     = -1;
  reg                     rdlvl_stg1_done_r;
  reg                     found_an_edge;
  reg [11:0]           rdlvl_timeout_counter;
  reg                  cal2_rdwait_cnt_done;
  reg [4:0]            cal2_rdwait_cnt;
  reg                  rdlvl_timeout_error;
  reg                  rdlvl_timeout_error_r;
  reg wrlvl_po_f_counter_en;
  reg [8:0] wrlvl_po_f_inc_counter;
  reg [8:0] last_po_counter_rd_value;
  reg [8:0] found_edge_po_rdvalue,oclk_found_edge_value;
  reg [8:0] lost_edge_po_rdvalue;
  reg [8:0]  right_edge_adjusted_counts;
  reg [8:0] calibrated_po_value;
  wire oclk_window_found_status;
  reg       wrlvl_po_f_counter_en_r;
  reg found_an_edge_r;
  reg       oclk_window_found;
  reg       po_oclk_dly_adjust_direction;
  reg       oclk_window_found_r;
  reg       found_an_edge_rising;
  reg [5:0] found_edge_counts;
  reg       edge_adv_cal_done_r;
  reg       inc_byte_lane_cnt;
  reg       first_deskew_attempt;
  reg       push_until_fail;
  reg       current_byte_Rdeskewed;
  reg [5:0] deskew_counts;
  reg [N_DATA_LANES-1:0] phase_valid_r;
  reg [1:0] byte_lane_cnt;
  reg [1:0] wrcal_stg;
  reg [1:0] lane_with_K;
  reg [1:0] bytes_deskewing;
  reg       kclk_finished_adjust;
  reg [1:0]      select_k_lane;		   
  reg [8:0]  po_fine_taps;
  
  reg       byte_lane0_valid_at_stg0_found_edge;
  reg       byte_lane1_valid_at_stg0_found_edge;
  reg       byte_lane2_valid_at_stg0_found_edge;
  reg       byte_lane3_valid_at_stg0_found_edge;
  reg       byte_lane0_valid_at_stg0_right_edge;
  reg       byte_lane1_valid_at_stg0_right_edge;
  reg       byte_lane2_valid_at_stg0_right_edge;
  reg       byte_lane3_valid_at_stg0_right_edge;
  reg [8:0]      current_right_edge_taps;
  reg [8:0]      byte_lane0_right_edge_taps;
  reg [8:0]      byte_lane1_right_edge_taps;
  reg [8:0]      byte_lane2_right_edge_taps;
  reg [8:0]      byte_lane3_right_edge_taps;
  
  reg [8:0]      byte_lane3_Ldelta_taps;
  reg [8:0]      byte_lane2_Ldelta_taps;
  reg [8:0]      byte_lane1_Ldelta_taps;
  reg [8:0]      byte_lane0_Ldelta_taps;
  
  reg cal1_rdlvl_restart_grp1,cal1_rdlvl_restart_grp2;
  
  reg [8:0]      stage2_taps_count;
  reg       right_lanes_alignment;
  reg       moving_k_left, right_edging;
  reg       all_left_edges_found;
  reg [5:0]    wait_cnt;    // counter to wait for the PO taps value
  reg          wait_cnt_done;
  reg            k_err_adjusted_enable;
  reg [1:0]      selected_byte_for_K_cehck;
 reg all_bytes_R_deskewed;
 
 reg  left_aligning_bytes;
  reg current_byte_Ldeskewed,current_byte_Ldeskewed_r;
  reg all_bytes_L_deskewed;
reg [8:0] byte_lane0_REdge_taps;
reg [8:0] byte_lane1_REdge_taps;
reg [8:0] byte_lane2_REdge_taps;
reg [8:0] byte_lane3_REdge_taps;
   
reg [8:0] byte_lane0_LEdge_taps;
reg [8:0] byte_lane1_LEdge_taps;
reg [8:0] byte_lane2_LEdge_taps;
reg [8:0] byte_lane3_LEdge_taps;
reg [3:0] current_delta_taps_to_move;
reg [3:0] center_tap_move_counts;



 reg current_byte_Rdeskewed_r;
 reg k_error_checking, k_error_checking_r;
 reg k_clock_left_aligned_r,k_clk_at_left_edge_r;
 reg [2:0] k_err_adjusted_counts;
  reg       po_inc_right_edge_done;
  reg [3:0] phase_valid_cnt;
  reg dbg_SM_en_r3,dbg_SM_en_r2,dbg_SM_en_r1;
  reg cal_stage2_PO_ADJ,cal_stage2_PO_ADJ_r;
  reg SM_Run_enable;
reg [8:0] po_dec_counter;
  reg kclk_finished_adjust_r;
  reg byte_shiftedback_redge, byte_shiftedback_redge_r;
  reg [1:0] k_clk_adjusted_counts;
  reg  [3:0] po_gap_enforcer;   
  wire     po_adjust_rdy;
  reg      po_adjust_rdy_r;
  reg      po_adj,po_adj_r,po_adj_pulse;
  reg      fully_adjusted;
  reg sm_trigger;
  reg k_clk_at_left_edge;
  reg [8:0] K_stage3_tap_position;
  reg [9:0] margin_check_counts;
  
  reg [3:0] tstptB;
reg current_byte_centered;
reg current_byte_centered_r;
reg K_is_centered;
reg wrlvl_po_f_counter_en_pre;

reg non_K_centering, non_K_centering_r;
reg all_bytes_R_deskewed_r;
reg k_clock_left_aligned;
 reg [9:0] K_error_check_counts;
 reg [9:0] K_error_found_counts;
 reg       K_error_stage_checked;
 reg       edge_adv_cal_done_pulse;
 reg [5:0] my_k_taps, k_center_tap;
 reg [3:0] lane_with_K_adjusted;
 reg all_bytes_centered;
 reg record_po_tap_value;
 reg  move_K_centering,move_K_centering_r;
 reg move_K_centering_pulse;
 reg current_byte_Ldeskewed_pulse;
 reg all_bytes_L_deskewed_pulse;
 reg kclk_finished_adjust_pulse;
 reg my_k_taps_at_center;
 wire [3:0] left_edge_status;
 
 reg my_k_taps_at_found_edge_value;
 wire sm_trigger2;
 wire [8:0] STG2_CHECK_TAPS;
 reg r_back2right_edge,r_stg2_shift_90;
 reg all_bytes_L_deskewed_r;
  assign STG2_CHECK_TAPS = 20;
  


// Signals start here



  assign dbg_wr_init[255:98]  = 'b0;   
  assign dbg_wr_init[97]       = k_clk_at_left_edge;      
  assign dbg_wr_init[96]        = k_error_checking;       

  assign dbg_wr_init[90 +: 6]   = my_k_taps;      
  assign dbg_wr_init[84+:6]     = k_center_tap;    //Calibrated K center tap value.

  assign dbg_wr_init[83]       = fully_adjusted;

  assign dbg_wr_init[79+:4 ]   = current_delta_taps_to_move;


  assign dbg_wr_init[78]       = byte_lane3_valid_at_stg0_found_edge;
  assign dbg_wr_init[77]       = byte_lane2_valid_at_stg0_found_edge;
  assign dbg_wr_init[76]       = byte_lane1_valid_at_stg0_found_edge;
  assign dbg_wr_init[75]       = byte_lane0_valid_at_stg0_found_edge;
  
  assign dbg_wr_init[74]       = byte_lane3_valid_at_stg0_right_edge; // Byte 0 right edge valid status when right edge is lost.
  assign dbg_wr_init[73]       = byte_lane2_valid_at_stg0_right_edge; // Byte 1 right edge valid status when right edge is lost.
  assign dbg_wr_init[72]       = byte_lane1_valid_at_stg0_right_edge; // Byte 2 right edge valid status when right edge is lost.
  assign dbg_wr_init[71]       = byte_lane0_valid_at_stg0_right_edge; // Byte 3 right edge valid status when right edge is lost.
  assign dbg_wr_init[67 +:4]    = phase_valid;
  
  assign dbg_wr_init[66:65]     = wrcal_byte_sel;              //current byte that under calibration
  assign dbg_wr_init[64]        = po_sel_fine_oclk_delay;
  assign dbg_wr_init[63]        = wrlvl_po_f_dec;
  assign dbg_wr_init[62]        = wrlvl_po_f_inc;           
  assign dbg_wr_init[61]        = wrcal_en;
  assign dbg_wr_init[52 +:9]    = po_counter_read_val;       // Input from PO COUNTER Read value.
  assign dbg_wr_init[51]        = push_until_fail; 
  
  assign dbg_wr_init[50]        = found_an_edge;
  assign dbg_wr_init[49]        = oclk_window_found;    
  assign dbg_wr_init[40+:9]     = found_edge_po_rdvalue;
  assign dbg_wr_init[31+:9]     = lost_edge_po_rdvalue;
  
  assign dbg_wr_init[27:7]      = phy_init_cs[20:0];         // initialization state machine
  assign dbg_wr_init[6]         = cal_stage2_start;          // latency calculation stage start
  assign dbg_wr_init[5]         = edge_adv_cal_done;         // edge adv settings to Phaser_in done    
  assign dbg_wr_init[4]         = rdlvl_stg1_done;           // stage1 calibration completed               
  assign dbg_wr_init[3]         = rdlvl_stg1_start;          // stage1 calibration start
  assign dbg_wr_init[2]         = rdlvl_stg1_done;           // 
  assign dbg_wr_init[1]         = cq_stable;                 // cq clocks from memory are stable, can start issuing commands
//  assign dbg_wr_init[0]         = init_cnt_done;             // initialization count done   //294
  assign dbg_wr_init[0]         = 1'b0 ;             // initialization count done   //294
  
  


// debugging 


  always @(posedge clk)
  begin
  
   phy_init_cs_reg <= phy_init_cs;
   
   if (phy_init_cs_reg != phy_init_cs)
   
      sm_trigger <= 1'b1;
   else
      sm_trigger <= 1'b0;
   
  end
 
 
 
 
 
   //Start edge adv cal after stage 1 is done with calibration
  assign edge_adv_cal_start = rdlvl_stg1_done;
  
  //---------------------------------------------------------------------------
  //Initialization Logic for Memory
  //The counters below are used to determine when the CQ/CQ# clocks are stable
  //and memory initialization is complete.
  //This logic operates on the same clock and rst_wr_clk to
  //ensure the counters are in sync to that of driving the K/K# clocks.  They
  //should remain in sync as CQ/CQ# are echos of K/K#
  //---------------------------------------------------------------------------

  //De-activate mem_dll_off_n signal to SRAM after stable K/K# clock
  always @ (posedge clk)
    begin
      if (rst_wr_clk)
        mem_dll_off_n <=#TCQ 0;
      else
        mem_dll_off_n <=#TCQ 1;
     end

  // Count CLK_STABLE cycles to determine that CQ/CQ# clocks are stable.  When
  // ready, both RST_CLK and RST_CLK_RD can come out of reset.  
  always @(posedge clk)
    begin
      if (rst_wr_clk)
        cq_cnt <= 0;
      else if (cq_cnt != CLK_STABLE)
        cq_cnt <= cq_cnt + 1;
    end

  always @(posedge clk)
    begin
      if (rst_wr_clk) 
        cq_stable   <=#TCQ 1'b0;
      else if (SIM_BYPASS_INIT_CAL != "OFF"  ||  SIMULATION == "TRUE") 
         cq_stable   <=#TCQ 1'b1;
      else if (cq_cnt == CLK_STABLE) 
        cq_stable   <=#TCQ 1'b1;
      
    end
      
  // RST_CLK - This reset is sync. to CLK and should be held as long as
  // clocks CQ/CQ# coming back from the memory device is not yet stable.  
  // It is assumed stable based on the parameter CLK_STABLE taken from the
  // memory spec.    
     
  assign sys_rst_act_hi   = RST_ACT_LOW ? ~sys_rst: sys_rst;  
  assign rst_clk_tmp      = ~cq_stable   | sys_rst_act_hi;
  
  always @(posedge clk , posedge rst_clk_tmp)
    if (rst_clk_tmp)
      rst_clk_sync_r <= #TCQ {RST_SYNC_NUM{1'b1}};
    else
      rst_clk_sync_r <= #TCQ rst_clk_sync_r << 1;
  
  assign rst_clk = rst_clk_sync_r[RST_SYNC_NUM-1]; 
  
   always @ (posedge clk) 
    begin
      rst_delayed[0] <=#TCQ rst_clk;
      rst_delayed[1] <=#TCQ rst_delayed[0];
      rst_delayed[2] <=#TCQ rst_delayed[1];
      rst_delayed[3] <=#TCQ rst_delayed[2];
      rst_delayed[4] <=#TCQ rst_delayed[3];
      rst_delayed[5] <=#TCQ rst_delayed[4];
      rst_delayed[6] <=#TCQ rst_delayed[5];
    end 

//  //Signals to the read path that initialization can begin 

// init_done could also be tied to rst_clk
// signals the init_wait time as well as cq stable count has been met, so calibration can begin

  always @ (posedge clk)
    begin
      if (rst_clk) begin
        init_done <=#TCQ 1'b0;
      end else if (rst_delayed[6] & ~rst_delayed[5]) begin 
        init_done <=#TCQ 1'b1;
      end
    end 
    
  always @ (posedge clk)
    begin
      if (rst_clk)
         rdlvl_stg1_start <= #TCQ 1'b0;
      else if (( phy_init_cs == CAL1_READ)   || (SIM_BYPASS_INIT_CAL != "OFF" && ck_addr_cmd_delay_done))
         rdlvl_stg1_start <= #TCQ 1'b1;               
    end
    
  always @ (posedge clk)
    begin
      if (rst_clk)
         cal_stage2_start <= #TCQ 1'b0;
      else if ( phy_init_cs == CAL2_READ)   
         cal_stage2_start <= #TCQ 1'b1;               
    end
  always @ (posedge clk)
    begin
       dbg_SM_en_r1 <= dbg_SM_en;
       dbg_SM_en_r2 <= dbg_SM_en_r1;
       dbg_SM_en_r3 <= dbg_SM_en_r2;
       
    end
    
  always @ (posedge clk)
    begin
      if (rst_clk)
         cal_stage2_PO_ADJ <= #TCQ 1'b0;
      else if ( phy_init_cs == PO_ADJ)   
         cal_stage2_PO_ADJ <= #TCQ 1'b1; 
     else
         cal_stage2_PO_ADJ <= #TCQ 1'b0;
    end
  always @ (posedge clk)
    begin
         cal_stage2_PO_ADJ_r <= cal_stage2_PO_ADJ;
    end
  always @ (posedge clk)
    begin
      if (rst_clk)
         SM_Run_enable <= #TCQ 1'b1;
      else if (phy_init_cs == PO_ADJ)   
         SM_Run_enable <= #TCQ 1'b0; 
     else if (dbg_SM_en_r2 && ~dbg_SM_en_r3)
         SM_Run_enable <= #TCQ 1'b1;
         
     else
         SM_Run_enable <= SM_Run_enable;
    end
    
 // Adjusting a new either OCLKD Delay / FINE_DELAY tap position .
 // Need to reset the read_calibration with the new settings.
 
 
 always @ (posedge clk)
 begin
   if (rst_clk)
       cal1_rdlvl_restart_grp1 <= 1'b0;
   else if (phy_init_cs == NEXT_BYTE_DESKEW  || (move_K_centering_pulse) || phy_init_cs == BACK2RIGHT_EDGE  || phy_init_cs == PO_ADJ_WAIT || (phy_init_cs == CAL_INIT && (k_error_checking || fully_adjusted)))
       cal1_rdlvl_restart_grp1 <= 1'b1;
   else
       cal1_rdlvl_restart_grp1 <= 1'b0;
 end   

 always @ (posedge clk)
 begin
   if (rst_clk)
       cal1_rdlvl_restart_grp2 <= 1'b0;
   else if ((phy_init_cs == PO_ADJ || move_K_centering_pulse || phy_init_cs == PO_STG2_INC_TO_RIGHT_EDGE ) &&  wrlvl_po_f_counter_en_r && ~wrlvl_po_f_counter_en )//|| phy_init_cs == CAL_INIT_WAIT)
       cal1_rdlvl_restart_grp2 <= 1'b1;
   else
       cal1_rdlvl_restart_grp2 <= 1'b0;
 end   
 
 always @ (posedge clk)
    begin
      if (rst_clk)
         cal1_rdlvl_restart <= 1'b0;
      else if (cal1_rdlvl_restart_grp1 || cal1_rdlvl_restart_grp2)
         cal1_rdlvl_restart <= 1'b1;
      
      else
         cal1_rdlvl_restart <= 1'b0;
    end
    
  //Depending on the configuration we need to wait enough time to ensure we
  //check all the data that has been written
  localparam PO_WAIT_CNT   = 3;

  // -------------------------------------------------------------------------
  // Generic Counter to be used when you don't want to transition right away
  // -------------------------------------------------------------------------
  always @ (posedge clk)
  begin
    if (rst_clk || ~wrcal_en)
	  wait_cnt <= #TCQ 'b0;
    else if (phy_init_cs == K_CENTER_SEARCH && wait_cnt == 3)
	  wait_cnt <= #TCQ 'b0;
    
    else if (wait_cnt != PO_WAIT_CNT)
	    wait_cnt <= #TCQ wait_cnt + 1;
    else
	  wait_cnt <= #TCQ wait_cnt;
  end
  
  always @ (posedge clk)
  begin
    if (rst_clk || ~wrcal_en)
	  wait_cnt_done <= #TCQ 'b0;
    else if (wait_cnt >= (PO_WAIT_CNT-1))
	  wait_cnt_done <= #TCQ 'b1;
    else
	  wait_cnt_done <= #TCQ 'b0;
  end





  // generating timeout error flag when read calibration path fail to return calibration pattern
  always @ (posedge clk)
    begin
      if (rst_clk)
         rdlvl_timeout_error <= #TCQ 'b0;
      else if (phy_init_cs == OCLK_RECAL)
         rdlvl_timeout_error <= #TCQ 'b0;      
      else if ( phy_init_cs == CAL2_READ_CONT && ~rdlvl_timeout_error)   
         if ( rdlvl_timeout_counter >= 512)
               rdlvl_timeout_error <= #TCQ  1'b1; 
          else
               rdlvl_timeout_error <= #TCQ 'b0;   
      else
         rdlvl_timeout_error <= #TCQ 'b0;      
    end

  always @ (posedge clk)
    begin
      if (rst_clk || (phy_init_cs == OCLK_RECAL) || (phy_init_cs == CAL_INIT))
         rdlvl_timeout_counter <= #TCQ 'b0;
      else if ( phy_init_cs == CAL2_READ_CONT)   
         if (rdlvl_timeout_counter == 512)
            rdlvl_timeout_counter <= #TCQ rdlvl_timeout_counter;
         else
            rdlvl_timeout_counter <= #TCQ rdlvl_timeout_counter + 1'b1;   
    end
    
   //****************** end of "timeout error"
   
   
   
  always @ (posedge clk)
    begin
      if (rst_clk)
         last_po_counter_rd_value <= #TCQ 'b0;
      else if (phy_init_cs == CAL_INIT  )
         last_po_counter_rd_value <= #TCQ po_counter_read_val;      
    end
  always @ (posedge clk)
    begin
      if (rst_clk)
         found_an_edge_rising <= #TCQ 1'd0;
      else if (found_an_edge && ~found_an_edge_r)
         found_an_edge_rising <= #TCQ 1'b1;      
      else if (~wrlvl_po_f_counter_en && wrlvl_po_f_counter_en_r)
         found_an_edge_rising <= #TCQ 1'b0;      
    end
  always @ (posedge clk)
    begin
      if (rst_clk)
         found_edge_po_rdvalue <= #TCQ 8'd0;
      else if (CK_WIDTH == 2 && bytes_deskewing == 1 && phy_init_cs ==  NEXT_BYTE_DESKEW)
      begin
      
         found_edge_po_rdvalue <= #TCQ 8'd0;
      
      end
      else if (found_an_edge_rising && ~wrlvl_po_f_counter_en && wrlvl_po_f_counter_en_r && ~oclk_window_found)
      //*************************** debug ***************************
         found_edge_po_rdvalue <= #TCQ po_counter_read_val + 1;//     
    end


  always @ (posedge clk)
    begin
      if (rst_clk)
         found_edge_counts <= #TCQ 'b0;
      else if (~found_an_edge && found_an_edge_r )//&& found_edge_counts < 1 )
         found_edge_counts <= #TCQ 'b0;      
      else if ( ~edge_adv_cal_done_r && edge_adv_cal_done)
         found_edge_counts <= #TCQ found_edge_counts + 1;      
    end
    
  
   always @ (posedge clk)
     begin
       if (rst_clk)
             found_an_edge <= 1'b0;
      else if (CK_WIDTH == 2 &&  kclk_finished_adjust && ~kclk_finished_adjust_r)
             found_an_edge <= 1'b0;
             
       else if (phy_init_cs == OCLK_RECAL)       
          if (phase_valid[lane_with_K] )

             found_an_edge <= 1'b1;
          else
             found_an_edge <= 1'b0;
    end
 
  assign  oclk_window_found_status = (SIM_BYPASS_INIT_CAL == "FAST" || SIM_BYPASS_INIT_CAL == "SKIP") ?  1'b1 : 1'b0;
    
    
  always @ (posedge clk)
    begin
      if (rst_clk)
      begin
         oclk_window_found    <= #TCQ oclk_window_found_status;
         lost_edge_po_rdvalue <= #TCQ 'b0;
      end
      else if (CK_WIDTH == 2 &&  kclk_finished_adjust && ~kclk_finished_adjust_r)
      begin
          oclk_window_found    <= #TCQ 1'b0;
         lost_edge_po_rdvalue <= #TCQ 'b0;
      end
      else if ((~found_an_edge && found_an_edge_r && found_edge_counts >= 4  
              // the following condition is possible if stg3 tap resolution is small and no second
              // edge is found. 
              || (found_an_edge && last_po_counter_rd_value == 63 && bytes_deskewing > 0)) && ~oclk_window_found)
      begin
          oclk_window_found    <= #TCQ 1'b1;
         lost_edge_po_rdvalue <= #TCQ last_po_counter_rd_value - 1;   
      end
    end
     
  always @ (posedge clk)
    begin
      if (rst_clk)
          calibrated_po_value <= 'b0;
     else if(k_error_checking &&  phase_valid[selected_byte_for_K_cehck]  && phy_init_cs == OCLK_RECAL)
          calibrated_po_value <= my_k_taps ;
    end
  
  
  
  //***************************************************************************************************
  // select either  PO stage 2 or stage 3 control signal which depends on the write calibration stage;
  
  
  always @ (posedge clk)
    begin
      if (rst_clk)
         po_sel_fine_oclk_delay <= #TCQ 'b0;	  

      else if (   wrcal_byte_sel  == lane_with_K  && ck_addr_cmd_delay_done)
         po_sel_fine_oclk_delay <= #TCQ 'b1;
      
     else 
  
           po_sel_fine_oclk_delay <= #TCQ  1'b0; 
    end
 
   

   
  //***************************************************************************************************
    
    
  always @ (posedge clk)
    begin
      if (rst_clk)
         wrlvl_calib_in_common <= #TCQ 1'b0;
      else if ( phy_init_cs == OCLK_RECAL)   
         wrlvl_calib_in_common <= #TCQ  1'b1;     
      else if ( phy_init_cs == CAL_INIT)
         wrlvl_calib_in_common <= #TCQ 1'b0;
    end
 always @ (posedge clk)
 begin
   if (rst_clk)
     po_oclk_dly_adjust_direction <= 1'b0;
   else if (oclk_window_found  & ~oclk_window_found_r)
   begin
      if (calibrated_po_value > last_po_counter_rd_value)
         po_oclk_dly_adjust_direction <= 1'b1;  // need to do fine_dec
      else
         po_oclk_dly_adjust_direction <= 1'b0; // need to do fine_inc
   end
 end
 

 
  // -------------------------------------------------------------------------
  // Simple inc/dec of the PO
  // Two options, either the simple state for doing a single inc/dec or the last
  // setting where the final value is computed and we need to hit that value
  // -------------------------------------------------------------------------
  //Counter used to adjust the time between decrements
  always @ (posedge clk) begin
    if (rst_clk || wrlvl_po_f_dec || wrlvl_po_f_inc) begin
          po_gap_enforcer <= #TCQ PO_ADJ_GAP; //8 clocks between adjustments for HW
        end else if (po_gap_enforcer != 'b0 && phy_init_cs != CAL_INIT && ~init_cal_done) begin
          po_gap_enforcer <= #TCQ po_gap_enforcer - 1;
        end else begin
          po_gap_enforcer <= #TCQ po_gap_enforcer; //hold value
        end
  end
   
  assign po_adjust_rdy = (po_gap_enforcer == 'b0) ? 1'b1 : 1'b0;


 
  always @ (posedge clk)
    begin
      if (rst_clk) begin
         wrlvl_po_f_dec <=#TCQ  1'b0;
         wrlvl_po_f_inc <= #TCQ 1'b0;
      end
      else if (phy_init_cs == CAL_DONE )
      begin
         wrlvl_po_f_dec <=#TCQ  1'b0;
         wrlvl_po_f_inc <= #TCQ 1'b0;
         
      end
              
      else if (wrcal_byte_sel != lane_with_K &&  wrlvl_po_f_counter_en  && po_adjust_rdy && ~all_bytes_R_deskewed)  // STEP 2
        // below code is for deskewing RIGHT edges
         begin

               if (wrlvl_po_f_inc_counter >0 || current_byte_Rdeskewed)
                        begin
                        wrlvl_po_f_dec <=#TCQ  1'b0;
                        wrlvl_po_f_inc <= #TCQ 1'b0;
                      
                    end
                        
               else if ( wrcal_byte_sel == 0)
                   if (~byte_lane0_valid_at_stg0_right_edge ||   ~phase_valid[byte_lane_cnt] && push_until_fail)
                      begin
                        wrlvl_po_f_inc <=#TCQ  1'b1;
                        wrlvl_po_f_dec <= #TCQ 1'b0;
                        
                      end
                   else
                      begin
                        wrlvl_po_f_inc <=#TCQ  1'b0;
                        wrlvl_po_f_dec <=#TCQ  1'b1;
                      
                      end
               else if ( wrcal_byte_sel == 1)
                   if (~byte_lane1_valid_at_stg0_right_edge ||   ~phase_valid[byte_lane_cnt] && push_until_fail)
                      begin
                        wrlvl_po_f_inc <= #TCQ 1'b1;
                        wrlvl_po_f_dec <= #TCQ  1'b0;
                        
                      end
                   else
                      begin
                        wrlvl_po_f_inc <= #TCQ 1'b0;
                        wrlvl_po_f_dec <= #TCQ 1'b1;
                        
                      end
               else if ( wrcal_byte_sel == 2)
                   if (~byte_lane2_valid_at_stg0_right_edge ||   ~phase_valid[byte_lane_cnt] && push_until_fail)
                      begin
                        wrlvl_po_f_inc <=#TCQ  1'b1;
                        wrlvl_po_f_dec <=#TCQ  1'b0;
                        
                      end
                   else
                      begin
                        wrlvl_po_f_inc <= #TCQ 1'b0;
                        wrlvl_po_f_dec <= #TCQ 1'b1;

                        
                      end
                   
               else if ( wrcal_byte_sel == 3)
                   if (~byte_lane3_valid_at_stg0_right_edge ||   ~phase_valid[byte_lane_cnt] && push_until_fail)
                      begin
                        wrlvl_po_f_inc <=#TCQ  1'b1;
                        wrlvl_po_f_dec <=#TCQ  1'b0;
                        
                        
                      end
                   else
                      begin
                        wrlvl_po_f_inc <= #TCQ 1'b0;
                        wrlvl_po_f_dec <=#TCQ  1'b1;
                        
                      end
                   


         end // *** end deskewing RIGHT edges
         
      else if ( phy_init_cs == STG2_SHIFT_90 &&  wrlvl_po_f_counter_en  && po_adjust_rdy)  // step 3
      begin        // use stage 2 to pull the non-k byte lane for 20 taps to measure the K position
                 
                        wrlvl_po_f_dec <= #TCQ ~wrlvl_po_f_dec;
                
                 
              
              end
              
      else if (phy_init_cs == K_CENTER_SEARCH && k_err_adjusted_enable)// Step 4

         begin
         // 
         wrlvl_po_f_inc <= #TCQ 1'b0;
         wrlvl_po_f_dec <= #TCQ ~wrlvl_po_f_dec;
         
         end
     
         
              
      else if ( phy_init_cs == BACK2RIGHT_EDGE &&  wrlvl_po_f_counter_en  && po_adjust_rdy)  // step 5a
            begin     // use stage 2 to put back the the non0k byte lane back to the deskewed postion
                  wrlvl_po_f_dec <= #TCQ 1'b0;
                  wrlvl_po_f_inc <= #TCQ ~wrlvl_po_f_inc;
                        
              end
              
         
     else if (po_adj_pulse && moving_k_left &&  po_adjust_rdy) // Step 5 b or Step 6
         begin
         wrlvl_po_f_dec <= #TCQ  ~wrlvl_po_f_dec;// 1'b1;
         wrlvl_po_f_inc <= #TCQ 1'b0;
         
         end

      else if (phy_init_cs == PO_ADJ && wrlvl_po_f_counter_en && po_adjust_rdy && k_clk_at_left_edge)// is used during STEP 1 for K-Byte edges detection

         // CALSTATE 0
         if ( ~phase_valid[wrcal_byte_sel] )
         begin
         wrlvl_po_f_inc <= #TCQ 1'b0;
         wrlvl_po_f_dec <= #TCQ ~wrlvl_po_f_dec;
         
         end
         else
         begin
         wrlvl_po_f_inc <= #TCQ 1'b0;
         wrlvl_po_f_dec <= #TCQ 1'b0;  
         
         
         end

         
      else if (phy_init_cs == PO_ADJ && wrlvl_po_f_counter_en && po_adjust_rdy && wrcal_byte_sel == lane_with_K )// is used during STEP 1 for K-Byte edges detection

         // CALSTATE 0
         if ( ~oclk_window_found )
         begin
         wrlvl_po_f_inc <=#TCQ  ~wrlvl_po_f_inc;
         wrlvl_po_f_dec <= #TCQ 1'b0;
         
         end
         else
         begin
         wrlvl_po_f_inc <= #TCQ 1'b0;
         wrlvl_po_f_dec <= #TCQ ~wrlvl_po_f_dec; // hacking to go back 1 tap after oclkwindwo found; should only come here 1 time only
         
         
         
         end
      
      else if (phy_init_cs == NON_K_CENTERING && wrlvl_po_f_counter_en && po_adjust_rdy ) 
          begin
          wrlvl_po_f_inc <= #TCQ ~wrlvl_po_f_inc;
          wrlvl_po_f_dec <= #TCQ 1'b0;
          
          end
      
      else if (phy_init_cs == MOVE_K_TO_CENTER   && wrlvl_po_f_counter_en && po_adjust_rdy ) 
          begin
          wrlvl_po_f_inc <= #TCQ ~wrlvl_po_f_inc;
          wrlvl_po_f_dec <= #TCQ 1'b0;
          
          end

      else 
         begin
         wrlvl_po_f_inc <= #TCQ 1'b0;
         wrlvl_po_f_dec <= #TCQ 1'b0;
         
         end
    end



  always @ (posedge clk)
    begin
    
      if (rst_clk) 
         k_err_adjusted_counts   <= #TCQ 'b0;
      else if (phy_init_cs == K_CENTER_SEARCH && wrlvl_po_f_dec) 
         k_err_adjusted_counts   <= #TCQ k_err_adjusted_counts + 1 ;
         
    end


 
 always @ (posedge clk)
 begin
 if (rst_clk)
     kclk_finished_adjust <= #TCQ 1'b0;
 
 else if (move_K_centering_pulse)  // finish 

     kclk_finished_adjust <= #TCQ 1'b1;
    else if (k_clk_adjusted_counts == 1 && phy_init_cs == CAL_INIT  && CK_WIDTH == 2)
     kclk_finished_adjust <= #TCQ 1'b0;
 else 
    
     kclk_finished_adjust <= #TCQ kclk_finished_adjust;
 end     

 
 
 // k_clk_adjusted_counts  is used to keep track how many K clocks have been calibrated.
 always @ (posedge clk)
 begin
 if (rst_clk)
     k_clk_adjusted_counts <= #TCQ 'b0;
 else if (kclk_finished_adjust && ~kclk_finished_adjust_r)
     k_clk_adjusted_counts <= #TCQ k_clk_adjusted_counts + 1'b1;
 end     
 
  
  
always @ (posedge clk) 
begin   
if (rst_wr_clk)
    wrlvl_po_f_counter_en_pre <= #TCQ 1'b0;

else if (phy_init_cs == PO_ADJ||  phy_init_cs == PO_STG2_INC_TO_RIGHT_EDGE
             || phy_init_cs == STG2_SHIFT_90 
             || phy_init_cs == MOVE_K_TO_CENTER || phy_init_cs == NON_K_CENTERING
             || phy_init_cs == K_CENTER_SEARCH  || phy_init_cs == BACK2RIGHT_EDGE || record_po_tap_value )  //0x80
 
    wrlvl_po_f_counter_en_pre <= #TCQ 1'b1;
else
    wrlvl_po_f_counter_en_pre <= #TCQ 1'b0;
end

always @ (posedge clk)
    begin
      if (rst_clk )
         wrlvl_po_f_counter_en <= #TCQ 'b0;
      else if (wrlvl_po_f_counter_en &&  ~po_adjust_rdy_r && po_adjust_rdy)
         wrlvl_po_f_counter_en <= #TCQ 'b0;
      
      
      else if (phy_init_cs == K_CENTER_SEARCH && wrlvl_po_f_inc_counter == 6)
           wrlvl_po_f_counter_en <= #TCQ 'b0;
      
      else if ((wrlvl_po_f_inc_counter >=5 && (!oclk_window_found || wrcal_byte_sel != lane_with_K || (phy_init_cs == CAL_INIT) )) || 
                ((wrlvl_po_f_inc_counter >= 6) && (oclk_window_found && wrcal_byte_sel == lane_with_K)) )

         wrlvl_po_f_counter_en <= #TCQ 1'b0;
         
      else if (wrlvl_po_f_counter_en_pre )  
         wrlvl_po_f_counter_en <= #TCQ 1'b1;
      else
         wrlvl_po_f_counter_en <= #TCQ wrlvl_po_f_counter_en;
    end
    
    
  always @ (posedge clk)
    begin
      if (rst_clk)
         wrlvl_po_f_inc_counter <= #TCQ 'b0;
      else if (phy_init_cs == CAL_INIT ||  (~wrlvl_po_f_counter_en && wrlvl_po_f_counter_en_r))
         wrlvl_po_f_inc_counter <= #TCQ 'b0;
      else if (wrlvl_po_f_counter_en )//&& po_adjust_rdy)
         wrlvl_po_f_inc_counter <= #TCQ wrlvl_po_f_inc_counter + 1;
      else 
         wrlvl_po_f_inc_counter <= #TCQ wrlvl_po_f_inc_counter;
    end



  always @ (posedge clk) 
    begin
      if (rst_wr_clk) begin
        cal_stage2_start_r <=#TCQ 1'b0;
        rdlvl_stg1_done_r  <=#TCQ 1'b0;
      end else begin
        cal_stage2_start_r <=#TCQ edge_adv_cal_done;
        rdlvl_stg1_done_r  <=#TCQ rdlvl_stg1_done;
      end
    end
    
    
    
    
    
    
 // rewrite incr_addr to avoid combinational logic to drive gated clock .  12/2012

   always @ (posedge clk)
    begin
      if (rst_wr_clk ) 
        incr_addr <=#TCQ 1'b0;
      else if (phy_init_cs == CAL_INIT && ck_addr_cmd_delay_done)
        incr_addr <=#TCQ 1'b1;
      else if (phy_init_cs == PO_ADJ && wrlvl_po_f_counter_en_r && ~wrlvl_po_f_counter_en ||
               phy_init_cs == CAL_DONE_WAIT)
        incr_addr <=#TCQ 1'b0;
    end

  //addr_cntr is used to select the data for initalization writes and
  //addressing.  The LSB is used to index data while [ADDR_WIDTH-1:1] is used
  //as the address therefore it is incremented by 2.
  always @ (posedge clk) 
    begin
      if (rst_wr_clk | cal1_rdlvl_restart) begin
        addr_cntr <=#TCQ 3'b000;

      end else if ( ( rdlvl_stg1_done && (BURST_LEN == 4))||
                    ( ~rdlvl_stg1_done_r & rdlvl_stg1_done && (BURST_LEN ==2))
                    && !dbg_phy_init_wr_only && !dbg_phy_init_rd_only)  begin
      //end else if (rdlvl_stg1_done) begin
          addr_cntr <= #TCQ 3'b000;

      end else if (incr_addr) begin
        addr_cntr[1:0] <=#TCQ addr_cntr + 2;
        addr_cntr[2]   <=#TCQ 1'b0;

      end
    end
    
  always @ (posedge clk)
    begin
      if (rst_wr_clk  || cal1_rdlvl_restart) begin
         cal2_rdwait_cnt <=  #TCQ 5'b11111;  //for debug 5'b00011;
      end else if (edge_adv_cal_done && cal2_rdwait_cnt != 0) begin
         cal2_rdwait_cnt <= #TCQ cal2_rdwait_cnt -1;
      end
    end
    
  always @ (posedge clk)
    begin
      if (rst_wr_clk || cal1_rdlvl_restart) begin
         cal2_rdwait_cnt_done <= #TCQ 1'b0;
      end else if (edge_adv_cal_done && cal2_rdwait_cnt == 0) begin
         cal2_rdwait_cnt_done <= #TCQ 1'b1;
      end
    end
  

  //Register the State Machine Outputs
  always @(posedge clk)
    begin
      if (rst_wr_clk) begin
        init_wr_cmd   <=#TCQ 2'b00;
        init_rd_cmd   <=#TCQ 2'b00;
        init_wr_addr0 <=#TCQ 0;
        init_wr_addr1 <=#TCQ 0;
        init_rd_addr0 <=#TCQ 0;
        init_rd_addr1 <=#TCQ 0;        
        
        init_wr_data0 <=#TCQ 0;
        init_wr_data1 <=#TCQ 0;
        phy_init_cs   <=#TCQ CAL_INIT;


      end else begin
        init_wr_cmd   <=#TCQ init_wr_cmd_d;
        init_rd_cmd   <=#TCQ init_rd_cmd_d;

        //init_wr_addr0/init_rd_addr1 are only used in BL2 mode.  Because of
        //this, we use all the address bits to maintain using even numbers for
        //the address' on the rising edge.  For BL2 the rising edge address 
        //should cycle through values 0,2,4, and 6.  On the falling edge where
        //'*addr1' is used the address should be rising edge +1 ('*addr0' +1).  
        //To save resources, instead of adding a +1, a 1 is concatinated
        //onto the rising edge address.
        //In BL4 mode, since reads only occur on the rising edge, and writes
        //on the falling edge, we uses everything but the LSB of addr_cntr 
        //since the LSB is only used to index the data register.  For BL4, 
        //the address should access 0x0 - 0x3 in stage one and 0x0 in stage 2.
        
        init_wr_addr0 <=#TCQ addr_cntr[1:0];          //Not used in BL4 - X
        init_wr_addr1 <=#TCQ (BURST_LEN == 4) ? addr_cntr[2:1] : 
                                                {addr_cntr[1:1], 1'b1};
        init_rd_addr0 <=#TCQ (BURST_LEN == 4) ? addr_cntr[2:1] : 
                                                addr_cntr[1:0];
        init_rd_addr1 <=#TCQ {addr_cntr[1:1], 1'b1};  //Not used in BL4 - X
                

           //based on the address a bit-select is used to select 2 Data Words for
           //the pre-defined arrary of data for read calibration.
           init_wr_data0 <=#TCQ ((rdlvl_stg1_done) || ((SIM_BYPASS_INIT_CAL == "SKIP"  )  & ~edge_adv_cal_done)) ?
                        // R0_F0 pattern
                        DATA_STAGE2[(DATA_WIDTH*4)-1:(DATA_WIDTH*2)]:  
                       // DATA_STAGE2[(DATA_WIDTH*2)-1:0] :
                        DATA_STAGE1[(addr_cntr*DATA_WIDTH*2)+:(DATA_WIDTH*2)];
           
           init_wr_data1 <=#TCQ ((rdlvl_stg1_done) || ((SIM_BYPASS_INIT_CAL == "SKIP") & ~edge_adv_cal_done)) ? 
                            //DATA_STAGE2[(DATA_WIDTH*4)-1:(DATA_WIDTH*2)]:
                            // R1_F1 pattern
                            DATA_STAGE2[(DATA_WIDTH*2)-1:0] :
           DATA_STAGE1[((addr_cntr+1)*DATA_WIDTH*2)+:(DATA_WIDTH*2)];
 

        phy_init_cs   <=#TCQ phy_init_ns;
      end
    end


   // ************************************************************************
   // State Machine Flow
   // 
   //  1. K-Byte edge detection to find the left and right edge tap value.
   //             K-Edge Detection States:
   //
   //                                      CAL_INIT         
   //                                      CAL1_WRITE       
   //                                      CAL1_READ        
   //                                      CAL2_WRITE       
   //                                      CAL2_READ_CONT   
   //                                      CAL2_READ        
   //                                      OCLK_RECAL       
   //                                      PO_ADJ           
   // 2. Right Edge alginment of non-K byte lanes.
   // 3. Shift a non-K byte lane by 90 degree from its right alginment position.
   // 4. K_Center_Search and record the center K-tap value.
   // 5. Move the shifte non-K byte back to its right aligned position.
   // 6. Move K clock to its left tap position relative to K-Byte lane.
   // 7. Left Edge alignment of non-K byte lanes.
   // 8. Center algin the non-K byte lane if needed.
   // 9. Return K tap to the center K-tap position.              

  //Initialization State Machine
  always @ *
    begin
      case (phy_init_cs)
        //In the init state, wait for ck_addr_cmd_delay_done to be asserted from the
        //read path to begin read/write transactions
        //Throughout this state machine, all outputs are registered except for 
        //incr_addr.  This is because that signal is used to set the address
        //which should be in line with the rest of the signals so it is used
        //immediately.
        
        CAL_INIT : begin
          init_wr_cmd_d   = 2'b00;
          init_rd_cmd_d   = 2'b00;
          init_cal_done   = 0;
          wrcal_en        = 0;

          if (ck_addr_cmd_delay_done ) 
             if ((SIM_BYPASS_INIT_CAL == "SKIP" )) 
                 phy_init_ns = CAL2_WRITE;
              else 
                 phy_init_ns = CAL1_WRITE;
          else 
            phy_init_ns = CAL_INIT;
          
          end
        

        //Send a write command.  For BL2 mode two writes are issued to write
        //4 Data Words, in BL4 mode, only write on the falling edge by using
        //bit [1] of init_wr_cmd.
        CAL1_WRITE  :  begin
          init_wr_cmd_d   = (BURST_LEN == 4) ? 2'b10 : 2'b11;
          init_rd_cmd_d   = 2'b00;
          init_cal_done   = 0;
          wrcal_en        = 0;
          
          //On the last two data words we are done writing in stage1
          //For stage two only one write is necessary
          //if ((cal_stage2_start_r & cal_stage2_start) || 
          //    (addr_cntr == 4'b0010))
          if (addr_cntr == INIT_WR_ADDR_CNT && !dbg_phy_init_wr_only)
            phy_init_ns = CAL1_READ;
           else
            phy_init_ns =  CAL1_WRITE; 
          
        end

        //Send a write command.  For BL2 mode two reads are issued to read
        //back 4 Data Words, in BL4 mode, only read on the rising edge by using
        //bit [0] of init_rd_cmd.
        CAL1_READ   : begin
          init_wr_cmd_d   = 2'b00;
          init_rd_cmd_d   = (BURST_LEN == 4) ? 2'b01 : 2'b11;
          init_cal_done   = 0;
          wrcal_en        = 0;

          //In stage 1 calibration, continuously read back data until stage 2 is
          //ready to begin.  in stage 2 read once then calibration is complete.
          //Only exit the read state when an entire sequence is complete (ie
          //on the last address of a sequence)
          
          // stage1 calibration complete.
          //if (~rdlvl_stg1_done_r & rdlvl_stg1_done & addr_cntr[2:0] == 3'b010)
           
          //if ( (BURST_LEN == 4) &&  ~rdlvl_stg1_done_r & rdlvl_stg1_done )
           if ( ~rdlvl_stg1_done_r & rdlvl_stg1_done && !dbg_phy_init_rd_only)
            phy_init_ns = CAL2_WRITE;
           else
            phy_init_ns =  CAL1_READ;    
                  

        end
        
        //Send a write command.  For BL2 mode two writes are issued to write
        //4 Data Words, in BL4 mode, only write on the falling edge by using
        //bit [1] of init_wr_cmd.
        CAL2_WRITE  :  begin
          init_wr_cmd_d   = (BURST_LEN == 4) ? 2'b10 : 2'b11;
          init_rd_cmd_d   = 2'b00;
          init_cal_done   = 0;
          wrcal_en        = 0;
           
          if ((BURST_LEN == 4) || (BURST_LEN == 2 && addr_cntr[2:0] == 3'b010)) begin
             //incr_addr = 1;
             phy_init_ns = CAL2_READ_CONT;
          end else begin               
             phy_init_ns =  CAL2_WRITE;
          end
          
         end
         
         CAL2_READ_CONT: begin  //0x0010
          // continuous reads for phase alignment
          init_wr_cmd_d   = 2'b00;
          init_rd_cmd_d   = (BURST_LEN == 4) ? 2'b01 : 2'b11;
          init_cal_done   = 0;
          wrcal_en        = 0;
          
          if ((SIM_BYPASS_INIT_CAL == "SKIP" || SIM_BYPASS_INIT_CAL == "FAST") && edge_adv_cal_done)
                phy_init_ns =  CAL2_READ_WAIT;
          
          else if (CLK_PERIOD <= 2500)
            if ( fully_adjusted && edge_adv_cal_done)
                    phy_init_ns =  CAL2_READ_WAIT;    //0x100
            else if ( all_bytes_R_deskewed && (stage2_taps_count != 20))
                    phy_init_ns = STG2_SHIFT_90;//was  BACK2RIGHT_EDGE;    //0x40000    *** debugging LEFT EDGING alignmnet
               
            else if ((rdlvl_timeout_error_r || (~oclk_window_found && edge_adv_cal_done) ||(k_error_checking && edge_adv_cal_done)) )  //*** for fast SIMULATION and HW
               begin
                wrcal_en        = 1;
                phy_init_ns =  OCLK_RECAL;        //0x40
               end
            else
                phy_init_ns =  CAL2_READ_CONT;

          else if (CLK_PERIOD > 2500)
            if (edge_adv_cal_done)
                phy_init_ns =  CAL2_READ_WAIT;    //0x100
            else
                phy_init_ns =  CAL2_READ_CONT;
         end
       
         OCLK_RECAL  : begin //0x40
          init_wr_cmd_d   = 2'b00;
          init_rd_cmd_d   = 2'b00;
         
          init_cal_done   = 0;
            wrcal_en        = 1;
          
          if (k_error_checking &&  (~phase_valid[selected_byte_for_K_cehck] ))    // Step 4   if return byte is not valid, need to error the K clock. Very likely

                 phy_init_ns = K_CENTER_SEARCH;        
                 

          else if(k_error_checking &&  phase_valid[selected_byte_for_K_cehck] ) //   Step 5a  no need to adjust.

                 phy_init_ns = BACK2RIGHT_EDGE   ;     
         else if (all_bytes_L_deskewed )

          
                 phy_init_ns = NON_K_CENTERING;        
 
          else if (all_bytes_centered && (&phase_valid))
          
                 phy_init_ns = MOVE_K_TO_CENTER;        
                 
          else if (k_clk_at_left_edge &&   phase_valid[wrcal_byte_sel] )// Step 6; left edge same as K byte when K is at left edge
          
                 phy_init_ns = RECORD_PO_TAP_VALUE;//;          
                 

          else if (current_byte_Rdeskewed   &&  right_edging)  // Step 2 Right alignment
          
                  phy_init_ns = RECORD_PO_TAP_VALUE;//;       
 
          else     
             if (dbg_SM_No_Pause)
               phy_init_ns = PO_ADJ;
             else
               phy_init_ns = PO_ADJ_WAIT;
           
         end       

         PO_ADJ_WAIT : begin
          init_wr_cmd_d   = 2'b00;
          init_rd_cmd_d   = 2'b00;
         
          init_cal_done   = 0;
          wrcal_en        = 0;
          if (SM_Run_enable)
           phy_init_ns = PO_ADJ;
          else 
           phy_init_ns = PO_ADJ_WAIT;
         end

         PO_ADJ : begin  //0x080
          init_wr_cmd_d   = 2'b00;
          init_rd_cmd_d   = 2'b00;
         
          init_cal_done   = 0;
            wrcal_en        = 1;

          if ( wrlvl_po_f_counter_en_r && ~wrlvl_po_f_counter_en)

            if (oclk_window_found && wrcal_byte_sel ==  lane_with_K)
               phy_init_ns = NEXT_BYTE_DESKEW;//PO_STG2_INC_TO_RIGHT_EDGE;//_WAIT;
            
            else
               phy_init_ns = CAL_INIT;//_WAIT;
          else
            phy_init_ns = PO_ADJ;
         end

         RECORD_PO_TAP_VALUE: begin  
          init_wr_cmd_d   = 2'b00;
          init_rd_cmd_d   = 2'b00;
         
          init_cal_done   = 0;
            wrcal_en        = 1;

          if ( wrlvl_po_f_counter_en_r && ~wrlvl_po_f_counter_en)
               phy_init_ns = NEXT_BYTE_DESKEW;//PO_STG2_INC_TO_RIGHT_EDGE;//_WAIT;
          else
               phy_init_ns = RECORD_PO_TAP_VALUE;
            
            
         end


         NEXT_BYTE_DESKEW: begin  //0x2000
              wrcal_en        = 1;
              init_cal_done   = 0;
         
          init_wr_cmd_d   = 2'b00;
          init_rd_cmd_d   = 2'b00;
                  phy_init_ns = CAL_INIT;
         
         
         end
         
         
         PO_STG2_INC_TO_RIGHT_EDGE : begin 
            init_cal_done   = 0;
            wrcal_en        = 1;
          init_wr_cmd_d   = 2'b00;
          init_rd_cmd_d   = 2'b00;
            
               phy_init_ns = NEXT_BYTE_DESKEW;

         end


         CAL2_READ_WAIT: begin //0x100
          // wait time, before a single read is issued for latency calculation and read valid signal generation
          init_wr_cmd_d   = 2'b00;
          init_rd_cmd_d   = 2'b00;
          init_cal_done   = 0;
          wrcal_en        = 0;

           if (cal2_rdwait_cnt_done && ((BURST_LEN == 4) || (BURST_LEN ==2 && addr_cntr[2:0] == 3'b010))) 
                 phy_init_ns = CAL2_READ;
           else
             phy_init_ns =  CAL2_READ_WAIT;    
         end
         
         CAL2_READ: begin
          // one read command for valid & latency determination
          init_wr_cmd_d   = 2'b00;
          init_rd_cmd_d   = (BURST_LEN == 4) ? 2'b01 : 2'b11;
          init_cal_done   = 0;
          wrcal_en        = 0;

          if ((SIM_BYPASS_INIT_CAL == "SKIP" || SIM_BYPASS_INIT_CAL == "FAST") && edge_adv_cal_done)
                phy_init_ns =  CAL_DONE_WAIT;    //0x100
          
          else if (addr_cntr == 'b0) begin
             if (CLK_PERIOD > 2500)
                phy_init_ns = CAL_DONE_WAIT;
             else if (fully_adjusted == 1 )
                phy_init_ns = CAL_DONE_WAIT;
             else
                phy_init_ns = CAL_INIT;
          end else begin
             phy_init_ns = CAL2_READ;
          end               
         end  

        BACK2RIGHT_EDGE: begin  //0x40000
          init_wr_cmd_d   = 2'b00;
          init_rd_cmd_d   = 2'b00;
        
          init_cal_done   = 0;
          wrcal_en        = 1;
        
          if (  right_edge_adjusted_counts == STG2_CHECK_TAPS)
               phy_init_ns = CAL_INIT;
          else
               phy_init_ns = BACK2RIGHT_EDGE;
        
        
        
        end
        
        
        
        

       STG2_SHIFT_90: begin
          init_wr_cmd_d   = 2'b00;
          init_rd_cmd_d   = 2'b00;
       
          init_cal_done   = 0;
          wrcal_en        = 1;
       
          if (  stage2_taps_count == STG2_CHECK_TAPS)//STG2_CHECK_TAPS)  // dec the non-k byte lane by x taps to check the
               phy_init_ns = CAL_INIT;   // linearity of oclk delay taps
          else
               phy_init_ns = STG2_SHIFT_90;
       
       
       
       end
       K_CENTER_SEARCH: begin
          init_wr_cmd_d   = 2'b00;
          init_rd_cmd_d   = 2'b00;
       
          init_cal_done   = 0;
          wrcal_en        = 1;
       
          if ( wrlvl_po_f_counter_en_r && ~wrlvl_po_f_counter_en  )
          
               phy_init_ns = CAL_INIT;
          else
               phy_init_ns = K_CENTER_SEARCH;
       
       

          end
        
        
       NON_K_CENTERING: begin
          init_wr_cmd_d   = 2'b00;
          init_rd_cmd_d   = 2'b00;
       
          init_cal_done   = 0;
          wrcal_en        = 1;
       
          if (all_bytes_centered )
          
               phy_init_ns = MOVE_K_TO_CENTER;
          else
               phy_init_ns = NON_K_CENTERING;
       
       

          end       
       MOVE_K_TO_CENTER: begin
          init_wr_cmd_d   = 2'b00;
          init_rd_cmd_d   = 2'b00;
       
          init_cal_done   = 0;
          wrcal_en        = 1;
       
          if ( my_k_taps == k_center_tap)
          
               phy_init_ns = CAL_INIT;
          else
               phy_init_ns = MOVE_K_TO_CENTER;
       
       

          end                 
        CAL_DONE_WAIT: begin
          // Stays here if all conditions met except read_cal_done
          // before asserting calibration complete
          init_wr_cmd_d   = 2'b00;
          init_rd_cmd_d   = 2'b00;
          init_cal_done   = 0;
          wrcal_en        = 0;
         
          if (read_cal_done) begin
             phy_init_ns = CAL_DONE; 
          end else begin
             phy_init_ns = CAL_DONE_WAIT; 
          end               
        end
  
        //Calibration Complete
        CAL_DONE : begin
          init_wr_cmd_d   = 2'b00;
          init_rd_cmd_d   = 2'b00;
          init_cal_done   = 1;
          phy_init_ns     = CAL_DONE;
          wrcal_en        = 0;
        end
           
        default:   begin
          init_wr_cmd_d   = 2'bXX;
          init_rd_cmd_d   = 2'bXX;
          init_cal_done   = 0;
          phy_init_ns     = CAL_INIT;
          wrcal_en        = 0;
        end
      endcase

    end //end init sm
    
reg first_found_edge;


always @ (posedge clk)
begin
if (rst_wr_clk  || kclk_finished_adjust && CK_WIDTH == 2 )
   my_k_taps <= #TCQ 1;  
else if ( wrcal_en && po_sel_fine_oclk_delay )
   if (my_k_taps == 63)
      my_k_taps <= #TCQ my_k_taps;
   else if (wrlvl_po_f_inc)
      my_k_taps <= #TCQ my_k_taps + 1;
   else if (wrlvl_po_f_dec)
      my_k_taps <= #TCQ my_k_taps - 1;
      
else
    my_k_taps <= #TCQ my_k_taps;

end

//  The chosen non-K byte lane needs to be returned to its orginal right edge algined position after K final taps has been positioned.
//  "fullly_adjusted" is to tell SM that both K clock taps and non-K bytes lanes have finished final adjustment . THis  enables the final stage
//    of latency valid check.

  
   always @ (posedge clk)
   begin
   if (rst_clk)
      fully_adjusted <= #TCQ 1'b0;
   
      else if ( K_is_centered)
         if (CK_WIDTH == 1  || (CK_WIDTH == 2 && k_clk_adjusted_counts == 2))
         fully_adjusted <= #TCQ 1'b1; //
    end    
    
   // keep track how many stage 2 has been incremented during BACK2RIGHT_EDGE stage.

   always @ (posedge clk)
   begin
      if (rst_wr_clk  || kclk_finished_adjust)
   
          right_edge_adjusted_counts <= #TCQ 'b0;
      else if (phy_init_cs == BACK2RIGHT_EDGE && wrlvl_po_f_inc)
          right_edge_adjusted_counts <= #TCQ right_edge_adjusted_counts + 1'b1;
      else
          right_edge_adjusted_counts <= #TCQ right_edge_adjusted_counts;
   end




// keep track how many stage 2 has been decremented to prepare for STG2_SHIFT_90. The algorithm calls for 32 taps decrement
// for 90 degree left shift from its right edge. 

   always @ (posedge clk)
   begin
      if (rst_wr_clk  || kclk_finished_adjust_pulse && CK_WIDTH == 2)
   
          stage2_taps_count <= #TCQ 'b0;
      else if (phy_init_cs == STG2_SHIFT_90 && wrlvl_po_f_dec)
          stage2_taps_count <= #TCQ stage2_taps_count + 1'b1;
      else
          stage2_taps_count <= #TCQ stage2_taps_count;
   end

  
  
// flags to track the byte lane status when the phase_valid of the byte with K clock is valid.



reg first_found_edge0, first_found_edge1, first_found_edge2, first_found_edge3;
//  Left Edge Skew detection logic: ***************************

//  Intialize the byte lanes left found edges to '1' because it is possible the very first K tap 0 has valid data already.
//  In this case , there will be no left edge and force to be zero. If the intial tap K has invalid data returned, these
//  status flag will be reset to zero. THe non-K byte status is latched with respect to the lane with K clock.

   always @ (posedge clk)
   begin
      if (rst_wr_clk)
        first_found_edge0 <= #TCQ 'b1;
      else if (phase_valid[lane_with_K]   && wrcal_byte_sel == lane_with_K )
        first_found_edge0 <= #TCQ 'b0;
   end

   always @ (posedge clk)
   begin
      if (rst_wr_clk)
        first_found_edge1 <= #TCQ 'b1;
      else if (phase_valid[lane_with_K]   && wrcal_byte_sel == lane_with_K )
        first_found_edge1 <= #TCQ 'b0;
   end
   
   generate 
   if (N_DATA_LANES > 2) begin: fnd_edge2
     always @ (posedge clk)
     begin
        if (rst_wr_clk)
          first_found_edge2 <= #TCQ 'b1;
        else if (phase_valid[lane_with_K]  && wrcal_byte_sel == lane_with_K )
          first_found_edge2 <= #TCQ 'b0;
     end
   
     always @ (posedge clk)
     begin
        if (rst_wr_clk)
          first_found_edge3 <= #TCQ 'b1;
        else if (phase_valid[lane_with_K]   && wrcal_byte_sel == lane_with_K )
          first_found_edge3 <= #TCQ 'b0;
     end
   end
   endgenerate
  
  // byte status during Left Edge detected
   always @ (posedge clk)
   begin
      if (rst_wr_clk)
        byte_lane0_valid_at_stg0_found_edge <= #TCQ 'b0;
      else if ( first_found_edge0 && phase_valid[lane_with_K]   && wrcal_byte_sel == lane_with_K )
           byte_lane0_valid_at_stg0_found_edge <=#TCQ  phase_valid[0];
   end  

   always @ (posedge clk)
   begin
      if (rst_wr_clk)
        byte_lane1_valid_at_stg0_found_edge <= #TCQ 'b0;
      else if ( first_found_edge1 && phase_valid[lane_with_K]   && wrcal_byte_sel == lane_with_K )
           byte_lane1_valid_at_stg0_found_edge <= #TCQ phase_valid[1];
   end  

   generate 
   if (N_DATA_LANES > 2) begin: fnd_edge2_3

     always @ (posedge clk)
     begin
        if (rst_wr_clk)
          byte_lane2_valid_at_stg0_found_edge <= #TCQ 'b0;
        else if ( first_found_edge2 && phase_valid[lane_with_K]   && wrcal_byte_sel == lane_with_K )
             byte_lane2_valid_at_stg0_found_edge <=#TCQ  phase_valid[2];
     end  

     always @ (posedge clk)
     begin
        if (rst_wr_clk)
          byte_lane3_valid_at_stg0_found_edge <= #TCQ 'b0;
        else if ( first_found_edge3 && phase_valid[lane_with_K]  && wrcal_byte_sel == lane_with_K )
             byte_lane3_valid_at_stg0_found_edge <=#TCQ  phase_valid[3];
     end  
   end
   endgenerate
assign left_edge_status = { byte_lane3_valid_at_stg0_found_edge,byte_lane2_valid_at_stg0_found_edge,byte_lane1_valid_at_stg0_found_edge,byte_lane0_valid_at_stg0_found_edge};

//  ************************************************************************************************************


//  Right Edge Skew detection logic: ***************************
 
//  THe non-K byte status is latched with respect to the lane with K clock when K is at right edge of K-byte lane..

   always @ (posedge clk)
   begin
      if (rst_wr_clk)
        byte_lane0_valid_at_stg0_right_edge <= #TCQ 'b0;
      else if ( found_an_edge_r && ~found_an_edge && phase_valid[0]  && wrcal_byte_sel == lane_with_K )
         if (phase_valid[0])
           byte_lane0_valid_at_stg0_right_edge <= #TCQ 1'b1;
         else
           byte_lane0_valid_at_stg0_right_edge <=#TCQ  1'b0;
   end  

   always @ (posedge clk)
   begin
      if (rst_wr_clk)
        byte_lane1_valid_at_stg0_right_edge <= #TCQ 'b0;
      else if (  found_an_edge_r && ~found_an_edge && phase_valid[1]  && wrcal_byte_sel == lane_with_K )
         if (phase_valid[1])
           byte_lane1_valid_at_stg0_right_edge <= #TCQ 1'b1;
         else
           byte_lane1_valid_at_stg0_right_edge <= #TCQ 1'b0;
   end  

   generate 
   if (N_DATA_LANES > 2) begin: fnd_right_edge2_3

     always @ (posedge clk)
     begin
        if (rst_wr_clk)
          byte_lane2_valid_at_stg0_right_edge <= #TCQ 'b0;
        else if (  found_an_edge_r && ~found_an_edge && phase_valid[2]   && wrcal_byte_sel == lane_with_K )
           if (phase_valid[2])
             byte_lane2_valid_at_stg0_right_edge <= #TCQ 1'b1;
           else
             byte_lane2_valid_at_stg0_right_edge <= #TCQ 1'b0;
     end  

     always @ (posedge clk)
     begin
        if (rst_wr_clk)
          byte_lane3_valid_at_stg0_right_edge <= #TCQ 'b0;
        else if (  found_an_edge_r && ~found_an_edge && phase_valid[3]  && wrcal_byte_sel == lane_with_K )
           if (phase_valid[3])
             byte_lane3_valid_at_stg0_right_edge <=#TCQ  1'b1;
           else
             byte_lane3_valid_at_stg0_right_edge <=#TCQ  1'b0;
     end  
   end
   endgenerate
  
//  ************************************************************************************************************


// right alignment status. 
 always @ (posedge clk)
 begin
   if (rst_wr_clk )
     right_lanes_alignment <=#TCQ  1'b0;
//   else if (found_an_edge_r && ~found_an_edge)//  (phy_init_cs == PO_STG2_INC_TO_RIGHT_EDGE)
   else if (phy_init_cs == PO_STG2_INC_TO_RIGHT_EDGE)
     right_lanes_alignment <= #TCQ 1'b1;
   else if (k_clk_at_left_edge)
     right_lanes_alignment <= #TCQ 1'b0;
   else
     right_lanes_alignment <= #TCQ right_lanes_alignment;  
   
 end
  

// set up deskew conditions for bytes without K clock
// Base on each non-K byte lane valid status when K was at the edge adn determine what 
// action needs to be taken during byte lane alignment stages.
    always @ (posedge clk)
    begin
    if (rst_wr_clk || phy_init_cs == NEXT_BYTE_DESKEW)
       push_until_fail <= #TCQ 1'b0;     
    else begin
       case(wrcal_byte_sel) 
         0 : push_until_fail <= #TCQ (right_lanes_alignment) ? ~byte_lane0_valid_at_stg0_right_edge :byte_lane0_valid_at_stg0_found_edge ;
         1 : push_until_fail <= #TCQ (right_lanes_alignment) ? ~byte_lane1_valid_at_stg0_right_edge :byte_lane1_valid_at_stg0_found_edge ;
         2 : push_until_fail <= #TCQ (right_lanes_alignment) ? ~byte_lane2_valid_at_stg0_right_edge :byte_lane2_valid_at_stg0_found_edge ;
         3 : push_until_fail <= #TCQ (right_lanes_alignment) ? ~byte_lane3_valid_at_stg0_right_edge :byte_lane3_valid_at_stg0_found_edge ;

         default:push_until_fail <= #TCQ 1'b0;  
       endcase
      end
    end  

// Need to keep track how many bytes have been deskewed to determine when to exit the deskew stage.
   always @ (posedge clk)
   begin
      if (rst_wr_clk || phy_init_cs == K_CENTER_SEARCH || moving_k_left)
            bytes_deskewing <= #TCQ 'b0;
      else if ( all_bytes_L_deskewed_pulse  || (CK_WIDTH == 2 && move_K_centering_pulse))

           bytes_deskewing <= #TCQ 'b0;
      else if (non_K_centering && current_delta_taps_to_move == center_tap_move_counts && CK_WIDTH == 1)
           if (bytes_deskewing < N_DATA_LANES - 1 )
            bytes_deskewing <= #TCQ bytes_deskewing + 1;
           else
              bytes_deskewing <= #TCQ bytes_deskewing ;


      else if (non_K_centering && current_delta_taps_to_move == center_tap_move_counts && CK_WIDTH == 2)
           if (bytes_deskewing < 1  )
              bytes_deskewing <=#TCQ  bytes_deskewing + 1;
           else
              bytes_deskewing <=#TCQ  bytes_deskewing ;
      
      else if ((phy_init_cs == NEXT_BYTE_DESKEW ) || (moving_k_left && ~phase_valid[wrcal_byte_sel] && rdlvl_timeout_error_r ))
          if (  CK_WIDTH == 2 && bytes_deskewing == 1)
            bytes_deskewing <= #TCQ bytes_deskewing;
          else
            bytes_deskewing <= #TCQ bytes_deskewing + 1;
      else
            bytes_deskewing <= #TCQ bytes_deskewing;
   end
   
   
   always @  (posedge clk)
   begin
      if (rst_wr_clk)
         all_bytes_R_deskewed <= #TCQ 1'b0;
      else if ( CK_WIDTH == 2 &&  kclk_finished_adjust && ~kclk_finished_adjust_r)
            all_bytes_R_deskewed <=#TCQ  1'b0;
      else if ( CK_WIDTH == 1 && bytes_deskewing == 3 && phy_init_cs == NEXT_BYTE_DESKEW && ~k_clk_at_left_edge)
         all_bytes_R_deskewed <=#TCQ  1'b1;
      else if ( CK_WIDTH == 1 && (DATA_WIDTH == 18) && bytes_deskewing == 1 && phy_init_cs == NEXT_BYTE_DESKEW && ~k_clk_at_left_edge)
         all_bytes_R_deskewed <=#TCQ  1'b1;
      else if ( CK_WIDTH == 2 && bytes_deskewing == 1 && phy_init_cs == NEXT_BYTE_DESKEW  && ~k_clk_at_left_edge) 
         all_bytes_R_deskewed <= #TCQ 1'b1;

   end
   
   // when all non K bytes are right edge aligned, we need to memorize the taps for later centering.
   


   always @  (posedge clk)
   begin
      if (rst_wr_clk) begin
      
         byte_lane0_REdge_taps  <= #TCQ 'b0;
         byte_lane1_REdge_taps  <= #TCQ 'b0;
         byte_lane2_REdge_taps  <= #TCQ 'b0;
         byte_lane3_REdge_taps  <= #TCQ 'b0;
         
         
         end
      else if ( current_byte_Rdeskewed  && (record_po_tap_value))
       begin  
        if (wrcal_byte_sel == 0)
             byte_lane0_REdge_taps  <=#TCQ  po_counter_read_val;
        else
             byte_lane0_REdge_taps  <= #TCQ byte_lane0_REdge_taps;
        
        if (wrcal_byte_sel == 1)
             byte_lane1_REdge_taps  <=#TCQ  po_counter_read_val ;
        else
             byte_lane1_REdge_taps  <=#TCQ  byte_lane1_REdge_taps;

        if (wrcal_byte_sel == 2)
             byte_lane2_REdge_taps  <= #TCQ po_counter_read_val ;
        else
             byte_lane2_REdge_taps  <= #TCQ byte_lane2_REdge_taps;

        if (wrcal_byte_sel == 3)
             byte_lane3_REdge_taps  <= #TCQ po_counter_read_val ;
        else
             byte_lane3_REdge_taps  <=#TCQ  byte_lane3_REdge_taps;
         end
         
   end
   

   
   always @  (posedge clk)
   begin
      if (rst_wr_clk) begin
      
         byte_lane0_LEdge_taps  <= #TCQ 'b0;
         byte_lane1_LEdge_taps  <= #TCQ 'b0;
         byte_lane2_LEdge_taps  <= #TCQ 'b0;
         byte_lane3_LEdge_taps  <= #TCQ 'b0;
         
         
         end
      else if ( current_byte_Ldeskewed_pulse && (record_po_tap_value))
      begin  
        if (wrcal_byte_sel == 0)
             byte_lane0_LEdge_taps  <= #TCQ po_counter_read_val- 1;
        else
             byte_lane0_LEdge_taps  <= #TCQ byte_lane0_LEdge_taps;
        
        if (wrcal_byte_sel == 1)
             byte_lane1_LEdge_taps  <= #TCQ po_counter_read_val- 1;
        else
             byte_lane1_LEdge_taps  <= #TCQ byte_lane1_LEdge_taps;

        if (wrcal_byte_sel == 2)
             byte_lane2_LEdge_taps  <= #TCQ po_counter_read_val- 1;
        else
             byte_lane2_LEdge_taps  <= #TCQ byte_lane2_LEdge_taps;

        if (wrcal_byte_sel == 3)
             byte_lane3_LEdge_taps  <= #TCQ po_counter_read_val- 1;
        else
             byte_lane3_LEdge_taps  <= #TCQ byte_lane3_LEdge_taps;
         
        end
   end   
  




  always @ (posedge clk)
     begin
        byte_lane3_Ldelta_taps <= #TCQ byte_lane3_REdge_taps - byte_lane3_LEdge_taps;
        byte_lane2_Ldelta_taps <= #TCQ byte_lane2_REdge_taps - byte_lane2_LEdge_taps;
        byte_lane1_Ldelta_taps <=#TCQ byte_lane1_REdge_taps - byte_lane1_LEdge_taps;
        byte_lane0_Ldelta_taps <= #TCQ byte_lane0_REdge_taps - byte_lane0_LEdge_taps;
     end



   
// modifed for RIGHT EDGE aligned logic
// need to come back for LEFT EDGE contion

// Decide if the byte lane that under deskewing has finsihed deskewing or not.
   always @ (posedge clk)
   begin
      if (rst_wr_clk)
            current_byte_Rdeskewed <= #TCQ 1'b0;
            
      else if (phy_init_cs == NEXT_BYTE_DESKEW )
            current_byte_Rdeskewed <= #TCQ 1'b0;
      else if (CK_WIDTH == 2 &&  kclk_finished_adjust && ~kclk_finished_adjust_r)
            current_byte_Rdeskewed <= #TCQ 1'b0;
            
      else if (phy_init_cs == OCLK_RECAL && ~push_until_fail && ~phase_valid[wrcal_byte_sel] && wrcal_byte_sel !=  lane_with_K  && ~k_clk_at_left_edge && oclk_window_found)       
            current_byte_Rdeskewed <= #TCQ 1'b1;
            
      else if (phy_init_cs == OCLK_RECAL && push_until_fail && phase_valid[wrcal_byte_sel] && wrcal_byte_sel !=  lane_with_K && ~k_clk_at_left_edge && oclk_window_found)        

            current_byte_Rdeskewed <= #TCQ 1'b1;
      else
            current_byte_Rdeskewed <= #TCQ current_byte_Rdeskewed;
   end
   
   always @ (posedge clk)
   begin
      if (rst_wr_clk)
            current_byte_Rdeskewed_r <= #TCQ 1'b0;
      else
            current_byte_Rdeskewed_r <= #TCQ current_byte_Rdeskewed;
   end
 
    always @ (posedge clk)
    begin
       if (rst_wr_clk)
             current_byte_Ldeskewed <= #TCQ 1'b0;
             
       else if (phy_init_cs == NEXT_BYTE_DESKEW  || phy_init_cs == MOVE_K_TO_CENTER)  //0x4000
             current_byte_Ldeskewed <= #TCQ 1'b0;
      else if (CK_WIDTH == 2 &&  kclk_finished_adjust && ~kclk_finished_adjust_r)
            current_byte_Ldeskewed <= #TCQ 1'b0;
             
       else if (phy_init_cs == OCLK_RECAL && k_clk_at_left_edge && phase_valid[wrcal_byte_sel] && wrcal_byte_sel !=  lane_with_K && k_clk_at_left_edge  && oclk_window_found)        
             current_byte_Ldeskewed <= #TCQ 1'b1;
             
       else
             current_byte_Ldeskewed <= #TCQ current_byte_Ldeskewed;
    end
    
    always @ (posedge clk)
    begin
       if (rst_wr_clk)
             current_byte_Ldeskewed_r <= #TCQ 1'b0;
       else
             current_byte_Ldeskewed_r <=#TCQ  current_byte_Ldeskewed;
   end
   
   
   always @  (posedge clk)
   begin
      if (rst_wr_clk)
         all_bytes_L_deskewed <= #TCQ 1'b0;
      else if ( CK_WIDTH == 2 &&  kclk_finished_adjust && ~kclk_finished_adjust_r)
         all_bytes_L_deskewed <= #TCQ 1'b0;
      else if ( CK_WIDTH == 1 && bytes_deskewing == 2 && phy_init_cs == NEXT_BYTE_DESKEW && k_clk_at_left_edge)      // can only deskew 3 non_K byte lanes
         all_bytes_L_deskewed <= #TCQ 1'b1;                                                                          // so set bytes_deskewsing == 2 instead of 3
      else if ( CK_WIDTH == 1 && (DATA_WIDTH == 18) && bytes_deskewing == 0 && phy_init_cs == NEXT_BYTE_DESKEW && k_clk_at_left_edge) // can only deskew 1 non_K byte lanes
         all_bytes_L_deskewed <= #TCQ 1'b1;                                                                                           // so set bytes_deskewsing == 0 instead of 1
      else if ( CK_WIDTH == 2 && bytes_deskewing == 1 && phy_init_cs == NEXT_BYTE_DESKEW && k_clk_at_left_edge)
         all_bytes_L_deskewed <= #TCQ 1'b1;
   end


    always @ (posedge clk)
    begin
       if (rst_wr_clk)
             current_byte_centered <= #TCQ 1'b0;
       else if (phy_init_cs == NON_K_CENTERING && (center_tap_move_counts == 0 || center_tap_move_counts == current_delta_taps_to_move) )        
             current_byte_centered <=#TCQ 1'b1;
       else
             current_byte_centered <= #TCQ 1'b0;
    end
    
    always @ (posedge clk)
    begin
       if (rst_wr_clk)
          current_byte_centered_r <= #TCQ 1'b0;
       else
          current_byte_centered_r <= #TCQ current_byte_centered;
   end
   
   
   always @  (posedge clk)
   begin
      if (rst_wr_clk)
         all_bytes_centered <= #TCQ 1'b0;
      else if (CK_WIDTH == 2 &&  kclk_finished_adjust && ~kclk_finished_adjust_r)
         all_bytes_centered <= #TCQ 1'b0;
         
      else if ( CK_WIDTH == 1 && bytes_deskewing == 3 && DATA_WIDTH == 36 && current_byte_centered ) 
         all_bytes_centered <= #TCQ 1'b1;  
      else if ( CK_WIDTH == 1 && bytes_deskewing == 1 && DATA_WIDTH == 18 && current_byte_centered ) 
         all_bytes_centered <= #TCQ 1'b1;                                                                          // so set bytes_deskewsing == 2 instead of 3
         // so set bytes_deskewsing == 2 instead of 3
      else if ( CK_WIDTH == 2 && bytes_deskewing == 1 && current_byte_centered )
         all_bytes_centered <= #TCQ 1'b1;

   end


   always @  (posedge clk)
   begin
      if (rst_wr_clk)
         K_is_centered <= #TCQ 1'b0;
      else if ( move_K_centering_pulse ) 
         K_is_centered <= #TCQ 1'b1;                                                                          // so set bytes_deskewsing == 2 instead of 3
      else if ( K_is_centered &&  po_sel_fine_oclk_delay && wrcal_en)
         K_is_centered <= #TCQ 1'b0;

   end


//reg move_K_centering,move_K_centering_r;
always @ (posedge clk)
begin
if (rst_wr_clk)
   non_K_centering <= #TCQ 1'b0;
else if (phy_init_cs == NON_K_CENTERING)
   non_K_centering <= #TCQ 1'b1;
else
   non_K_centering <= #TCQ 1'b0;
end


always @ (posedge clk)
begin
if (rst_wr_clk)
   move_K_centering <= #TCQ 1'b0;
else if (phy_init_cs == MOVE_K_TO_CENTER)
   move_K_centering <= #TCQ 1'b1;
else
   move_K_centering <= #TCQ 1'b0;
end

always @ (posedge clk)
begin
if (rst_wr_clk)
   current_delta_taps_to_move <= #TCQ 'b0;
    else begin
       case(wrcal_byte_sel) 
         0 : current_delta_taps_to_move[3:0] <= #TCQ byte_lane0_Ldelta_taps[3:1] ;  // need to check warning message here
         1 : current_delta_taps_to_move[3:0] <= #TCQ byte_lane1_Ldelta_taps[3:1]  ;
         2 : current_delta_taps_to_move[3:0] <= #TCQ byte_lane2_Ldelta_taps[3:1]  ;
         3 : current_delta_taps_to_move[3:0] <= #TCQ byte_lane3_Ldelta_taps[3:1]  ;

         default:current_delta_taps_to_move <= #TCQ 'b0;  
       endcase
      end
    end  
    
    
    
always @ (posedge clk)
begin
if (rst_wr_clk)
   center_tap_move_counts <= #TCQ 'b0;  // *** 
else if ( non_K_centering && ~non_K_centering_r || (center_tap_move_counts == current_delta_taps_to_move ))
      center_tap_move_counts <= #TCQ 0;
else if (wrlvl_po_f_inc && non_K_centering)
      center_tap_move_counts <=#TCQ  center_tap_move_counts + 1;

      
else
    center_tap_move_counts <= #TCQ center_tap_move_counts;

end    
   
//  ************************************************************************************************************
 
   always @(posedge clk)
   begin
   if (rst_wr_clk)
      k_err_adjusted_enable <= #TCQ 1'b0;
   else if (phy_init_cs == K_CENTER_SEARCH && wrlvl_po_f_inc_counter == 1)
      k_err_adjusted_enable <= #TCQ 1'b1;
   else
      k_err_adjusted_enable <= #TCQ 1'b0;

   end
 
 
   always @(posedge clk)
   begin
   if (rst_wr_clk)
      k_error_checking <= #TCQ 1'b0;
   else if (phy_init_cs == STG2_SHIFT_90)
      k_error_checking <= #TCQ 1'b1;
   else if (phy_init_cs == OCLK_RECAL &&  k_error_checking &&  phase_valid[selected_byte_for_K_cehck])
      k_error_checking <= #TCQ 1'b0;
   end 



//****** record the K center tap position


   always @(posedge clk)
   begin
   if (rst_wr_clk)
      k_center_tap <= #TCQ 1'b0;
   else if (~k_error_checking && k_error_checking_r)
      k_center_tap <= #TCQ my_k_taps;
   else
      k_center_tap <= #TCQ k_center_tap;
   end 



   always @(posedge clk)
   begin
   if (rst_wr_clk)
      k_clk_at_left_edge <= #TCQ 1'b0;
   else if (~k_error_checking && oclk_window_found && my_k_taps == found_edge_po_rdvalue)
      k_clk_at_left_edge <= #TCQ 1'b1;
   else
      k_clk_at_left_edge <= #TCQ 1'b0;
   end 



// not used logic ****************************************************************     
    always @(posedge clk)
    begin
    if (rst_wr_clk) begin
    
       byte_lane0_right_edge_taps <= #TCQ 'b0;
       byte_lane1_right_edge_taps <= #TCQ 'b0;
       byte_lane2_right_edge_taps <= #TCQ 'b0;
       byte_lane3_right_edge_taps <= #TCQ 'b0;
       
       end
    else if (current_byte_Rdeskewed && right_lanes_alignment && phy_init_cs == NEXT_BYTE_DESKEW)
     begin
      case(wrcal_byte_sel)
      
      2'b00 : byte_lane3_right_edge_taps <=  #TCQ last_po_counter_rd_value ;
      2'b01 : byte_lane2_right_edge_taps <=  #TCQ last_po_counter_rd_value ;
      2'b10 : byte_lane1_right_edge_taps <= #TCQ  last_po_counter_rd_value ;
      2'b11 : byte_lane0_right_edge_taps <= #TCQ  last_po_counter_rd_value ;
      default :byte_lane0_right_edge_taps <=  #TCQ last_po_counter_rd_value ; 
      endcase
    end
    
    end



    always @(posedge clk)
    begin
    if (rst_wr_clk) begin
       current_right_edge_taps <=#TCQ  'b0;

    end else begin
      case(wrcal_byte_sel)
      
      2'b00: current_right_edge_taps  <=  #TCQ byte_lane3_right_edge_taps ;
      2'b01: current_right_edge_taps  <= #TCQ  byte_lane2_right_edge_taps ;
      2'b10: current_right_edge_taps  <= #TCQ  byte_lane1_right_edge_taps ;
      2'b11: current_right_edge_taps  <= #TCQ  byte_lane0_right_edge_taps ;
      default :current_right_edge_taps <= #TCQ  byte_lane0_right_edge_taps ; 
      endcase
    end
    
    end
    

    
    always @ (posedge clk)
    begin
    if (rst_wr_clk)

       deskew_counts <= #TCQ 'b0;
  //  else if (phy_init_cs == NEXT_BYTE_DESKEW )
  //     deskew_counts <= 0;
       
    else if ((phy_init_cs == OCLK_RECAL || (moving_k_left && ~phase_valid[wrcal_byte_sel] && rdlvl_timeout_error_r)) && current_byte_Rdeskewed)
       deskew_counts <= #TCQ deskew_counts + 1;
    else
       deskew_counts <= #TCQ deskew_counts ;
    
    end

    always @ (posedge clk)
    begin
    if (rst_wr_clk)

       moving_k_left <= #TCQ 1'b0;
    else if (phy_init_cs == BACK2RIGHT_EDGE )
       moving_k_left <= #TCQ 1'b1;
    else if (my_k_taps == found_edge_po_rdvalue )
       moving_k_left <= #TCQ 1'b0;
    else
       moving_k_left <= #TCQ moving_k_left;
    
    end


    always @ (posedge clk)
    begin
    if (rst_wr_clk)

       left_aligning_bytes <= #TCQ 1'b0;
    else if (k_clk_at_left_edge && ~k_clk_at_left_edge_r )
       left_aligning_bytes <= #TCQ 1'b1;
    else if (my_k_taps == found_edge_po_rdvalue )
       left_aligning_bytes <= #TCQ 1'b0;
    else
       left_aligning_bytes <= #TCQ left_aligning_bytes;
    
    end




    always @ (posedge clk)
    begin
    if (rst_wr_clk)

       right_edging <= #TCQ 1'b0;
    else if (oclk_window_found  & ~oclk_window_found_r )
       right_edging <= #TCQ 1'b1;
    else if (phy_init_cs == STG2_SHIFT_90 )
       right_edging <= #TCQ 1'b0;
    else
       right_edging <= #TCQ right_edging;
    
    end



//*****************************************************
//counter to keep track of what byte lane we are calibrating
//Also used to adjust calib_sel
//This counter is reset also at the start of a new mode
    
  always @ (posedge clk)
  begin
     if (rst_wr_clk)
        inc_byte_lane_cnt <= #TCQ 1'b0;
     else if (phy_init_cs == NEXT_BYTE_DESKEW  && ( ~kclk_finished_adjust || k_clk_at_left_edge))
        inc_byte_lane_cnt <= #TCQ 1'b1;
     
     else
        inc_byte_lane_cnt <= #TCQ 1'b0;
  end  
  
  
  
  always @ (posedge clk)
  begin
  if (rst_wr_clk || kclk_finished_adjust)
      byte_shiftedback_redge <= #TCQ 1'b0;
  else if (  right_edge_adjusted_counts == STG2_CHECK_TAPS)
      byte_shiftedback_redge <= #TCQ 1'b1;

  end
  
// byte_lane_count/wrcal_byte_sel  is used to direct the mc_phy which byte calibration is working on.
// The po_counter_read_val is a mux output from layers under mc_phy module and is determined by the 
// wrcal_byte_sel value.


   always @ (posedge clk)
   begin
   
     select_k_lane  <=  #TCQ BYTE_LANE_WITH_DK[0] && ~lane_with_K_adjusted[0] ? 0 :
                        BYTE_LANE_WITH_DK[1] && ~lane_with_K_adjusted[1] ? 1 :
                        BYTE_LANE_WITH_DK[2] && ~lane_with_K_adjusted[2] ? 2 :
                        BYTE_LANE_WITH_DK[3] && ~lane_with_K_adjusted[3] ? 3 : 0;                       
    
   end


   always @ (posedge clk)
   begin
     if (rst_wr_clk )
           byte_lane_cnt <= #TCQ select_k_lane ;
     else if (kclk_finished_adjust && ~kclk_finished_adjust_r)
              byte_lane_cnt <=  #TCQ select_k_lane;
     else if (phy_init_cs == STG2_SHIFT_90 ) begin                  // left shift 90 degree on a non-K byte lane
              byte_lane_cnt <=  #TCQ selected_byte_for_K_cehck;
     end
     else if ( all_bytes_R_deskewed && ~all_bytes_R_deskewed_r) begin 
              byte_lane_cnt <= #TCQ lane_with_K;
     end
     else if (phy_init_cs == BACK2RIGHT_EDGE) begin                 // K is at left edge now...force to select the next byte for left alignment process
              byte_lane_cnt <= #TCQ selected_byte_for_K_cehck;
     end
     else if (~byte_shiftedback_redge_r && byte_shiftedback_redge) begin  // the shifted non-K byte lane is back to its right alignment position...
                                                                          // force the byte_lane_cnt to K-lane to move the K to left edge of K byte window.
              byte_lane_cnt <= #TCQ lane_with_K ;
     end
     else if (phy_init_cs == NON_K_CENTERING && CK_WIDTH == 1) begin
        if (non_K_centering && ~non_K_centering_r)
              byte_lane_cnt <= #TCQ lane_with_K + 1;
        else if (center_tap_move_counts == current_delta_taps_to_move || current_delta_taps_to_move == 0 )
              byte_lane_cnt <= #TCQ byte_lane_cnt + 1;
     end
     else if ( ~phase_valid[wrcal_byte_sel] && rdlvl_timeout_error_r && moving_k_left && k_clk_at_left_edge || (k_clk_at_left_edge && ~k_clk_at_left_edge_r))begin
              if (CK_WIDTH == 2 && BYTE_LANE_WITH_DK[1] && byte_lane_cnt == 1)
                     byte_lane_cnt <= #TCQ lane_with_K - 1;
              else if (CK_WIDTH == 2 && BYTE_LANE_WITH_DK[3] && byte_lane_cnt == 3)
                     byte_lane_cnt <= #TCQ lane_with_K - 1;
              else if (DATA_WIDTH == 18 && BYTE_LANE_WITH_DK[1] && byte_lane_cnt == 1)
                     byte_lane_cnt <= #TCQ byte_lane_cnt - 1;
              else
                     byte_lane_cnt <= #TCQ byte_lane_cnt + 1;
     end
     else if (phy_init_cs == MOVE_K_TO_CENTER  || phy_init_cs == K_CENTER_SEARCH )begin
            byte_lane_cnt <= #TCQ lane_with_K;
     end
     else if ((inc_byte_lane_cnt  && right_edging && ~all_bytes_R_deskewed)  || (~current_byte_Ldeskewed && current_byte_Ldeskewed_r && CK_WIDTH == 1))begin		// only during detecting edges of K byte lane
        if (byte_lane_cnt == N_DATA_LANES - 1 && CK_WIDTH == 1)
             byte_lane_cnt <= #TCQ 0;
        else if (CK_WIDTH == 2) begin
             if (BYTE_LANE_WITH_DK[0] || BYTE_LANE_WITH_DK[2])
                   byte_lane_cnt <= #TCQ byte_lane_cnt + 1;
             else
                   byte_lane_cnt <= #TCQ byte_lane_cnt - 1;
        end 
        else
             byte_lane_cnt <= #TCQ byte_lane_cnt + 1;
     end
     else begin
        byte_lane_cnt <= #TCQ byte_lane_cnt;
     end
   end
   
   assign wrcal_byte_sel = byte_lane_cnt[1:0];

   always @ (posedge clk)
   begin
      if (rst_wr_clk)
         if (CK_WIDTH == 1)
            begin
                    lane_with_K <=  #TCQ  BYTE_LANE_WITH_DK[0]  ? 0 :
                                     BYTE_LANE_WITH_DK[1]  ? 1 :
                                     (BYTE_LANE_WITH_DK[2] && N_DATA_LANES > 2 && CK_WIDTH == 1) ? 2 :
                                     (BYTE_LANE_WITH_DK[3] && N_DATA_LANES > 2 && CK_WIDTH == 1) ? 3 : 0;
            end
         else
            begin
            
                    lane_with_K <= #TCQ  (BYTE_LANE_WITH_DK[0]  && bytes_deskewing  < 1) ? 0 :
                                    (BYTE_LANE_WITH_DK[1]  && bytes_deskewing  < 1) ? 1 :
                                    (BYTE_LANE_WITH_DK[2]  && N_DATA_LANES > 2 && bytes_deskewing  > 1 ) ? 2 :
                                    (BYTE_LANE_WITH_DK[3]  && N_DATA_LANES > 2 && bytes_deskewing  >  1) ? 3 : 0;                       
                                            
            end
       else if (kclk_finished_adjust && ~kclk_finished_adjust_r)
   
                    lane_with_K <=  #TCQ  BYTE_LANE_WITH_DK[0] && ~lane_with_K_adjusted[0] ? 0 :
                                     BYTE_LANE_WITH_DK[1] && ~lane_with_K_adjusted[1] ? 1 :
                                     BYTE_LANE_WITH_DK[2] && ~lane_with_K_adjusted[2] ? 2 :
                                     BYTE_LANE_WITH_DK[3] && ~lane_with_K_adjusted[3] ? 3 : 0;
   end
   
   
   always @ (posedge clk)
   begin
   if (rst_wr_clk)
      lane_with_K_adjusted <= #TCQ 'b0;
   else if (move_K_centering && ~move_K_centering_r) begin
         case(wrcal_byte_sel)
         
         2'b00: lane_with_K_adjusted[0]  <= #TCQ 1'b1 ;
         2'b01: lane_with_K_adjusted[1]  <= #TCQ  1'b1 ;
         2'b10: lane_with_K_adjusted[2]  <= #TCQ  1'b1 ;
         2'b11: lane_with_K_adjusted[3]  <= #TCQ  1'b1 ;
         default :lane_with_K_adjusted <=  #TCQ 1'b0 ; 
         endcase
       end
   
   end



    // Pick a non-K byte lane to use stage 2 to calibrate the stage 3 non-linearity.

    always @ (posedge clk)
    begin
    if (rst_wr_clk)
        selected_byte_for_K_cehck <= #TCQ 'b0;
     else if (oclk_window_found && ~oclk_window_found_r)
       if (BYTE_LANE_WITH_DK[0] == 1 || BYTE_LANE_WITH_DK[2] == 1)
        selected_byte_for_K_cehck <= #TCQ lane_with_K + 1;
       else
        selected_byte_for_K_cehck <= #TCQ lane_with_K - 1;
       
    
    end    

  // -------------------------------------------------------------------------
  // Keep track of what mode we are in
  // For now just support the first mode (CK-to-DK)
  // -------------------------------------------------------------------------
  always @ (posedge clk)
  begin
    if (rst_wr_clk) begin
          wrcal_stg <= #TCQ 'b0;
        end else if (CK_WIDTH == 2 && phy_init_cs == CAL_INIT && bytes_deskewing == 2)
          wrcal_stg <= #TCQ 'b0;
        
        else if (phy_init_cs == CAL_INIT && oclk_window_found) begin
          if (wrcal_stg < 1)
             wrcal_stg <= #TCQ wrcal_stg + 1;
          else
             wrcal_stg <= #TCQ wrcal_stg;
          
        end else begin
          wrcal_stg <= #TCQ wrcal_stg;
        end
  end
  
  always @ (posedge clk)
  begin
    if (rst_wr_clk) 
          po_adj <= #TCQ 1'b0;
    else if (phy_init_cs == PO_ADJ)
          po_adj <= #TCQ 1'b1;
    else
          po_adj <= #TCQ 1'b0;
  end
  
  
  always @ (posedge clk)
  begin
    if (rst_wr_clk) 
          record_po_tap_value <= #TCQ 1'b0;
    else if (phy_init_cs == RECORD_PO_TAP_VALUE)
          record_po_tap_value <= #TCQ 1'b1;
    else
          record_po_tap_value <= #TCQ 1'b0;
  end
  
 always @ (posedge clk)
 begin
 if (rst_clk)
     move_K_centering_pulse <= #TCQ 1'b0;
 else if (~move_K_centering && move_K_centering_r)  // finish 
     move_K_centering_pulse <= #TCQ 1'b1;
 else
     move_K_centering_pulse <= #TCQ 1'b0;
 
 
 end     

 
 always @ (posedge clk)
 begin
 if (rst_clk)
     all_bytes_L_deskewed_pulse <= #TCQ 1'b0;
 else if (all_bytes_L_deskewed && ~all_bytes_L_deskewed_r)  // finish 
     all_bytes_L_deskewed_pulse <= #TCQ 1'b1;
 else
     all_bytes_L_deskewed_pulse <= #TCQ 1'b0;
 
 
 end     
 
 

 always @ (posedge clk)
 begin
 if (rst_clk)
     current_byte_Ldeskewed_pulse <= #TCQ 1'b0;
 else if (current_byte_Ldeskewed && ~current_byte_Ldeskewed_r)  // finish 
     current_byte_Ldeskewed_pulse <= #TCQ 1'b1;
 else
     current_byte_Ldeskewed_pulse <= #TCQ 1'b0;
 
 
 end     
  
  

        
always @ (posedge clk)
if (rst_wr_clk)
   my_k_taps_at_found_edge_value <= #TCQ 1'b0;
else if (   my_k_taps == found_edge_po_rdvalue - 1)
   my_k_taps_at_found_edge_value <= #TCQ 1'b1;
else
   my_k_taps_at_found_edge_value <= #TCQ 1'b0;


 always @ (posedge clk)
 begin
 if (rst_clk)
     my_k_taps_at_center <= #TCQ 1'b0;
 else if (my_k_taps_at_center)
     my_k_taps_at_center <= #TCQ 1'b1;
 else
     my_k_taps_at_center <= #TCQ 1'b0;

 end 
  
  
 always @ (posedge clk)
 begin
 if (rst_clk)
     kclk_finished_adjust_pulse <= #TCQ 1'b0;
 else if (kclk_finished_adjust && ~kclk_finished_adjust_r)
     kclk_finished_adjust_pulse <= #TCQ 1'b1;
 else
     kclk_finished_adjust_pulse <= #TCQ 1'b0;

 end 
  
  
  
  
  
  
  always @ (posedge clk)
  begin
	kclk_finished_adjust_r <= kclk_finished_adjust;
    po_adj_r        <= #TCQ po_adj;
    po_adj_pulse    <= #TCQ po_adj & ~po_adj_r;
    po_adjust_rdy_r <= #TCQ po_adjust_rdy;
    k_error_checking_r <= #TCQ k_error_checking;
    all_bytes_R_deskewed_r <= #TCQ all_bytes_R_deskewed;
    k_clk_at_left_edge_r <= #TCQ k_clk_at_left_edge;
    byte_shiftedback_redge_r <= #TCQ byte_shiftedback_redge;
    non_K_centering_r <= #TCQ non_K_centering;
    move_K_centering_r <= #TCQ move_K_centering;
    edge_adv_cal_done_r <= #TCQ edge_adv_cal_done;
    rdlvl_timeout_error_r <= #TCQ rdlvl_timeout_error;
    phase_valid_r <= #TCQ phase_valid;
    wrlvl_po_f_counter_en_r <= #TCQ wrlvl_po_f_counter_en;
    oclk_window_found_r <= #TCQ oclk_window_found;
    all_bytes_L_deskewed_r <= #TCQ all_bytes_L_deskewed;
    if ( kclk_finished_adjust && ~kclk_finished_adjust_r)
    
       found_an_edge_r <= #TCQ 1'b0;
    else
       found_an_edge_r <= #TCQ found_an_edge;
    
    
    
  end
    
    


// following is for simulation purpose
// not syntehsizable
    reg [8*50:0] phy_init_sm;
    always @(phy_init_cs)begin
       casex(phy_init_cs)
         21'b000000000000000000001 : begin phy_init_sm = "CAL_INIT"                   ; end
         21'b000000000000000000010 : begin phy_init_sm = "CAL1_WRITE"                 ; end
         21'b000000000000000000100 : begin phy_init_sm = "CAL1_READ"                  ; end     
         21'b000000000000000001000 : begin phy_init_sm = "CAL2_WRITE"                 ; end    
         21'b000000000000000010000 : begin phy_init_sm = "CAL2_READ_CONT"             ; end    
         21'b000000000000000100000 : begin phy_init_sm = "CAL2_READ"                  ; end
         21'b000000000000001000000 : begin phy_init_sm = "OCLK_RECAL"                 ; end
         21'b000000000000010000000 : begin phy_init_sm = "PO_ADJ"                     ; end
         21'b000000000000100000000 : begin phy_init_sm = "CAL2_READ_WAIT"             ; end
         21'b000000000001000000000 : begin phy_init_sm = "CAL_DONE "                  ; end
         21'b000000000010000000000 : begin phy_init_sm = "CAL_DONE_WAIT"              ; end 
         21'b000000000100000000000 : begin phy_init_sm = "PO_ADJ_WAIT"                ; end  //
         21'b000000001000000000000 : begin phy_init_sm = "PO_STG2_INC_TO_RIGHTT_EDGE" ;end
         21'b000000010000000000000 : begin phy_init_sm = "STG2_SHIFT_90"              ; end
         21'b000000100000000000000 : begin phy_init_sm = "NEXT_BYTE_DESKEW"           ; end  //
       	 21'b000001000000000000000 : begin phy_init_sm = "BACK2RIGHT_EDGE"            ; end   
       	 21'b000010000000000000000 : begin phy_init_sm = "K_CENTER_SEARCH"            ; end 
       	 21'b000100000000000000000 : begin phy_init_sm = "K_CENTER_SEARCH_WAIT"       ; end 
	     21'b001000000000000000000 : begin phy_init_sm = "MOVE_K_TO_CENTER"           ; end 
	     21'b010000000000000000000 : begin phy_init_sm = "NON_K_CENTERING"           ; end 
	     21'b100000000000000000000 : begin phy_init_sm = "RECORD_PO_TAP_VALUE"           ; end
       endcase
       
       
    end
          

endmodule

