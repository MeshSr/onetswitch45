//*****************************************************************************
//(c) Copyright 2009 - 2013 Xilinx, Inc. All rights reserved.
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
// by a third party) even if such damage  or loss was
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
//  /   /         Filename           : qdr_rld_phy_read_top.v
// /___/   /\     Date Last Modified : $Date: 2011/06/02 08:36:30 $
// \   \  /  \    Date Created       : Nov 17, 2008
//  \___\/\___\
//
//Device: 7 Series
//Design: QDRII+ SRAM / RLDRAM II SDRAM
//
//Purpose:
//  This module
//  1. Instantiates all the read path submodules
//
//Revision History:	9/14/2012 - Fixed CR 678451.
//Revision History:	12/10/2012  -Improved CQ_CQB capturing clock scheme.  
//
////////////////////////////////////////////////////////////////////////////////
`timescale 1ps/1ps

module mig_7series_v2_0_qdr_rld_phy_read_top #
(
  parameter BURST_LEN           = 4,              // 4 = Burst Length 4, 2 = Burst Length 2
  parameter DATA_WIDTH          = 72,             // Total data width across all memories
  parameter BW_WIDTH            = 8,             //Byte Write Width
  parameter N_DATA_LANES        = 4,
  parameter MEMORY_IO_DIR        = "UNIDIR",
  parameter CPT_CLK_CQ_ONLY     = "TRUE",
  parameter FIXED_LATENCY_MODE  = 0,              // 0 = minimum latency mode, 1 = fixed latency mode
  parameter PHY_LATENCY         = 16,             // Indicates the desired latency for fixed latency mode
  parameter CLK_PERIOD          = 2500,           // Memory clock period in ps
  parameter REFCLK_FREQ         = 200.0,          // Indicates the IDELAYCTRL reference clock frequency
  //parameter DEVICE_TAPS         = 32,             // Number of taps in target IODELAY
  parameter TAP_BITS            = 5,              // Number of bits needed to represent DEVICE_TAPS
  //parameter IODELAY_GRP         = "IODELAY_MIG",  // May be assigned unique name when mult IP cores in design
  parameter SIM_BYPASS_INIT_CAL = "OFF",         // Skip various calibration steps - "NONE, "FAST_CAL", "SKIP_CAL"
  parameter PI_ADJ_GAP          = 7,             // Time to wait between PI adjustments
  parameter RTR_CALIBRATION     = "OFF",         // For memories that provide a read training register
  parameter PER_BIT_DESKEW      = "OFF",
  parameter RD_DATA_RISE_FALL   = "FALSE",      //Parameter to control how we present read data back to user
                                                // {rise, fall}, TRUE case
                                                // {fall, rise}, FALSE case
  parameter MEM_TYPE            = "QDR2PLUS",     // Memory Type (QDR2PLUS, QDR2)
  parameter CQ_BITS             = 1,              //clog2(NUM_BYTE_LANES - 1)   
  parameter Q_BITS              = 7,              //clog2(DATA_WIDTH - 1) 
  parameter nCK_PER_CLK         = 2,
  parameter DEBUG_PORT          = "ON",           // Debug using Chipscope controls 
  parameter TCQ                 = 100             // Register delay
)
(
   // System Signals
   input                                  clk,              // main system half freq clk
   input                                  rst_stg1,
   input                                  rst_stg2,
   input                                  rst_wr_clk, 
   input                                  if_empty,
   input                                  rtr_cal_done,
   
   input       [nCK_PER_CLK*DATA_WIDTH-1:0] iserdes_rd,   // ISERDES output - rise data
   input       [nCK_PER_CLK*DATA_WIDTH-1:0] iserdes_fd,   // ISERDES output - fall data
   output wire                            if_rden,
  
   // Stage 1 calibration inputs/outputs
   input   [5:0]                           pi_counter_read_val,
   output reg                              pi_dec_done,
   output wire                             pi_en_stg2_f,
   output wire                             pi_stg2_f_incdec,
   output wire                             pi_stg2_load,
   output wire [5:0]                       pi_stg2_reg_l,
   output wire [CQ_BITS-1:0]               pi_stg2_rdlvl_cnt,
   // Phaser OUT calibration signals - to control CQ# PHASER delay
   input [8:0]                             po_counter_read_val,
   
   output wire                             po_en_stg2_f,
   output wire                             po_stg2_f_incdec,
   output wire                             po_stg2_load,
   output wire [5:0]                       po_stg2_reg_l,
   output wire [CQ_BITS-1:0]               po_stg2_rdlvl_cnt, 
   output wire                             pi_edge_adv,
   output wire [2:0]                       byte_cnt,
   
   // Only output if Per-bit de-skew enabled
   output wire [5*DATA_WIDTH-1:0]          dlyval_dq,
//   output wire                           idelay_inc,
//   output wire                           idelay_ce,
   

   // User Interface
   output wire                                read_cal_done,   // Read calibration done
   output wire [2*nCK_PER_CLK*DATA_WIDTH-1:0] rd_data,         // user read data
   output wire [nCK_PER_CLK-1:0]              rd_valid,        // user read data valid
                                       
   // Write Path Interface                
   input                                  init_done,        // initialization complete
   input                                  rdlvl_stg1_start,
   output wire                            rdlvl_stg1_done,
   input                                  edge_adv_cal_start,
   input                                  cal_stage2_start, 
   output wire                            edge_adv_cal_done ,
   input  wire  [nCK_PER_CLK-1:0]         int_rd_cmd_n,     // internal rd cmd
   output wire  [N_DATA_LANES-1:0]        phase_valid,
   output wire                            error_adj_latency,  // stage 2 cal latency adjustment error  

 //ChipScope Debug Signals
  output wire [255:0]                     dbg_rd_stage1_cal,      // stage 1 cal debug
  output wire [127:0]                     dbg_stage2_cal,         // stage 2 cal debug
  output wire [4:0]                       dbg_valid_lat,          // latency of the system
  input                                   dbg_SM_en,
  input [CQ_BITS-1:0]                     dbg_byte_sel, 
  output wire [31:0]                      dbg_rdphy_top,
  output wire                             dbg_next_byte,
  output wire [nCK_PER_CLK*DATA_WIDTH-1:0]dbg_align_rd,
  output wire [nCK_PER_CLK*DATA_WIDTH-1:0]dbg_align_fd,
 
  output wire [N_DATA_LANES-1:0]           dbg_inc_latency,        // increase latency for dcb
  output wire [N_DATA_LANES-1:0]           dbg_error_max_latency  // stage 2 cal max latency error

 
);


  localparam integer BYTE_LANE_WIDTH = 9; 
  localparam SIM_CAL_OPTION =  (SIM_BYPASS_INIT_CAL == "SKIP")? "SKIP_CAL" : // SKIP_CAL, FAST_CAL, FAST_WIN_DETECT, NONE
                                 (SIM_BYPASS_INIT_CAL == "FAST")? "FAST_CAL" : "NONE" ;
  localparam MEMORY_TYPE_CAL = (CLK_PERIOD <= 2500)? MEMORY_IO_DIR : "BIDIR";

  wire [nCK_PER_CLK*DATA_WIDTH-1:0]       rise_data;
  wire [nCK_PER_CLK*DATA_WIDTH-1:0]       fall_data;
  wire [N_DATA_LANES-1 :0]                inc_latency;
  wire [4:0]                              valid_latency;
                                          
  wire  [5*N_DATA_LANES-1:0]              dbg_cpt_first_edge_cnt;
  wire  [5*N_DATA_LANES-1:0]              dbg_cpt_second_edge_cnt;
  wire                                    dbg_idel_up_all;
  wire                                    dbg_idel_down_all;
  wire                                    dbg_idel_up_cpt;
  wire                                    dbg_idel_down_cpt;
  wire                                    dbg_sel_all_idel_cpt;
  wire  [255:0]                           dbg_phy_rdlvl; 
  wire [N_DATA_LANES-1:0]                 error_max_latency;
  wire [2*nCK_PER_CLK*DATA_WIDTH-1:0]     iserdes_rd_data;
  wire                                    rdlvl_pi_en_stg2_f;
  wire                                    rdlvl_pi_stg2_f_incdec;
  wire                                    rdlvl_po_en_stg2_f;
  wire                                    rdlvl_po_stg2_f_incdec;
  wire [CQ_BITS-1:0]                      rdlvl_pi_stg2_cnt;
  wire [nCK_PER_CLK*DATA_WIDTH-1:0]       iserdes_rd_byte;
  wire [nCK_PER_CLK*DATA_WIDTH-1:0]       iserdes_fd_byte;
  wire [nCK_PER_CLK*DATA_WIDTH-1:0]       rise_data_byte;
  wire [nCK_PER_CLK*DATA_WIDTH-1:0]       fall_data_byte;
  wire                                    bitslip;
  wire [N_DATA_LANES-1:0]                 bitslip_byte_lane;
  
  reg                                     if_empty_r;
  reg                                     if_empty_2r;
  
  reg [8:0]                               rdlvl_stg1_start_r; //start signal
  reg [5:0]                               pi_rdval_cnt;
  reg                                     pi_cnt_dec;
  reg [2:0]                               pi_dec_done_r;
  reg [CQ_BITS:0]                         pi_byte_cnt; //extra bit used
  wire                                    next_byte;
  reg [2:0]                               pi_gap_enforcer;
  reg [2:0]                               po_gap_enforcer;
  
  wire                                    pi_adjust_rdy;
  reg [5:0]                               po_rdval_cnt;

  reg next_byte_f;
  reg next_byte_r;  
  reg  po_cnt_dec;
  reg [2:0] po_dec_done_r;
  reg  po_dec_done;
  wire po_adjust_rdy;

  wire rdlvl_stg1_rank_done;
  wire rdlvl_stg1_err;
  wire rdlvl_prech_req;
  wire max_lat_done_r;

  // iserdes output data
  //assign iserdes_rd_data     = {iserdes_fd1, iserdes_rd1, iserdes_fd0, iserdes_rd0};
  generate
    if (nCK_PER_CLK == 4) begin: iserdes_rd_data_div4
	  assign iserdes_rd_data = {iserdes_fd[4*DATA_WIDTH-1:3*DATA_WIDTH], 
	                            iserdes_rd[4*DATA_WIDTH-1:3*DATA_WIDTH],
								iserdes_fd[3*DATA_WIDTH-1:2*DATA_WIDTH], 
	                            iserdes_rd[3*DATA_WIDTH-1:2*DATA_WIDTH],
	                            iserdes_fd[2*DATA_WIDTH-1:1*DATA_WIDTH], 
	                            iserdes_rd[2*DATA_WIDTH-1:1*DATA_WIDTH],
	                            iserdes_fd[DATA_WIDTH-1:0], 
								iserdes_rd[DATA_WIDTH-1:0]};
	  // read data to backend (UI)
	  assign rd_data         = (RD_DATA_RISE_FALL == "TRUE") ? 
	                           {rise_data[4*DATA_WIDTH-1:3*DATA_WIDTH], 
	                            fall_data[4*DATA_WIDTH-1:3*DATA_WIDTH],
								rise_data[3*DATA_WIDTH-1:2*DATA_WIDTH], 
	                            fall_data[3*DATA_WIDTH-1:2*DATA_WIDTH],
								rise_data[2*DATA_WIDTH-1:1*DATA_WIDTH], 
	                            fall_data[2*DATA_WIDTH-1:1*DATA_WIDTH],
								rise_data[DATA_WIDTH-1:0], 
	                            fall_data[DATA_WIDTH-1:0]} :
							   {fall_data[4*DATA_WIDTH-1:3*DATA_WIDTH], 
	                            rise_data[4*DATA_WIDTH-1:3*DATA_WIDTH],
								fall_data[3*DATA_WIDTH-1:2*DATA_WIDTH], 
	                            rise_data[3*DATA_WIDTH-1:2*DATA_WIDTH],
								fall_data[2*DATA_WIDTH-1:1*DATA_WIDTH], 
	                            rise_data[2*DATA_WIDTH-1:1*DATA_WIDTH],
								fall_data[DATA_WIDTH-1:0], 
	                            rise_data[DATA_WIDTH-1:0]};
    end else begin: iserdes_rd_data_div2
      assign iserdes_rd_data = {iserdes_fd[2*DATA_WIDTH-1:DATA_WIDTH], 
	                            iserdes_rd[2*DATA_WIDTH-1:DATA_WIDTH],
	                            iserdes_fd[DATA_WIDTH-1:0], 
								iserdes_rd[DATA_WIDTH-1:0]};
	  // read data to backend (UI)
	  assign rd_data         = (RD_DATA_RISE_FALL == "TRUE") ? 
	                           {rise_data[2*DATA_WIDTH-1:1*DATA_WIDTH], 
	                            fall_data[2*DATA_WIDTH-1:1*DATA_WIDTH],
								rise_data[DATA_WIDTH-1:0], 
	                            fall_data[DATA_WIDTH-1:0]} :
							   {fall_data[2*DATA_WIDTH-1:1*DATA_WIDTH], 
	                            rise_data[2*DATA_WIDTH-1:1*DATA_WIDTH],
								fall_data[DATA_WIDTH-1:0], 
	                            rise_data[DATA_WIDTH-1:0]};
    end
  endgenerate
    
  //debug signals
  assign dbg_align_rd       = rise_data;
  assign dbg_align_fd       = fall_data;
  assign dbg_next_byte      = next_byte;
  assign dbg_rdphy_top      = {26'h0000000,pi_rdval_cnt};
  
 // assign po_en_stg2_f        =  pi_en_stg2_f;
 // assign po_stg2_f_incdec    =  pi_stg2_f_incdec;
 // assign po_stg2_load        =  po_stg2_load;
 // assign po_stg2_reg_l       =  po_stg2_reg_l;
 // assign po_stg2_rdlvl_cnt   =  po_stg2_rdlvl_cnt;
  
  assign pi_en_stg2_f     = (pi_dec_done) ? rdlvl_pi_en_stg2_f : pi_cnt_dec;
  assign pi_stg2_f_incdec = (pi_dec_done) ? rdlvl_pi_stg2_f_incdec : 1'b0;

  assign po_en_stg2_f     = (po_dec_done) ? rdlvl_po_en_stg2_f    : po_cnt_dec; // ???? bug here...assumption is skew and
  assign po_stg2_f_incdec = (po_dec_done) ? rdlvl_po_stg2_f_incdec : 1'b0;

  assign pi_stg2_rdlvl_cnt= (pi_dec_done) ? rdlvl_pi_stg2_cnt : 
                                            pi_byte_cnt[CQ_BITS-1:0];
  
  // Instantiate valid generator logic that retimes the valids for the out
  // going data.
  mig_7series_v2_0_qdr_rld_phy_read_vld_gen #
    (   
    .BURST_LEN                (BURST_LEN),
	.nCK_PER_CLK              (nCK_PER_CLK),
    .TCQ                      (TCQ)    
    ) 
    u_qdr_rld_phy_read_vld_gen
    (
    .clk                      (clk),
    .rst_clk                  (rst_stg2),
    .int_rd_cmd_n             (int_rd_cmd_n),
    .valid_latency            (valid_latency),
    .cal_done                 (read_cal_done),
    .data_valid               (rd_valid),
    .dbg_valid_lat            (dbg_valid_lat)
  );
  
  mig_7series_v2_0_qdr_rld_phy_rdlvl #
    (
     .TCQ                      (TCQ),
     .MEMORY_IO_DIR              (MEMORY_TYPE_CAL),
     .CPT_CLK_CQ_ONLY          (CPT_CLK_CQ_ONLY),
     .nCK_PER_CLK              (nCK_PER_CLK),
     .CLK_PERIOD               (CLK_PERIOD),
     .REFCLK_FREQ               (REFCLK_FREQ),  
     .DQ_WIDTH                 (DATA_WIDTH),
     //.DQS_CNT_WIDTH            (CQ_BITS-1),
     .DQS_CNT_WIDTH            (CQ_BITS),
     .DQS_WIDTH                (DATA_WIDTH/9), 
     .DRAM_WIDTH               (9),
     .RANKS                    (1),
	 .PI_ADJ_GAP               (PI_ADJ_GAP),
	 .RTR_CALIBRATION          (RTR_CALIBRATION),
     .PER_BIT_DESKEW           ("OFF"),
     .SIM_CAL_OPTION           (SIM_CAL_OPTION),
     .DEBUG_PORT               (DEBUG_PORT)
     )
    u_qdr_rld_phy_rdlvl
      (
       .clk                     (clk),
       .rst                     (rst_stg1),
       .rdlvl_stg1_start        (rdlvl_stg1_start & pi_dec_done),
       .rdlvl_stg1_done         (rdlvl_stg1_done),
       .rdlvl_stg1_rnk_done     (rdlvl_stg1_rank_done),
       .rdlvl_stg1_err          (rdlvl_stg1_err),
       .rdlvl_prech_req         (rdlvl_prech_req),
       .prech_done              (1'b1),
	   .rtr_cal_done            (rtr_cal_done),
       .rd_data                 (iserdes_rd_data),
       .pi_en_stg2_f            (rdlvl_pi_en_stg2_f), //pi_en_stg2_f
       .pi_stg2_f_incdec        (rdlvl_pi_stg2_f_incdec), //pi_stg2_f_incdec
       .pi_stg2_load            (pi_stg2_load),
       .pi_stg2_reg_l           (pi_stg2_reg_l),
       .pi_stg2_rdlvl_cnt       (rdlvl_pi_stg2_cnt), //pi_stg2_rdlvl_cnt
//       .idelay_ce               (idelay_ce), //idelay_ce
//       .idelay_inc              (idelay_inc), //idelay_ce
       .po_en_stg2_f            (rdlvl_po_en_stg2_f),     
       .po_stg2_f_incdec        (rdlvl_po_stg2_f_incdec), 
       .po_stg2_load            (po_stg2_load),     
       .po_stg2_reg_l           (po_stg2_reg_l),    
       .po_stg2_rdlvl_cnt       (po_stg2_rdlvl_cnt),
       .dlyval_dq               (dlyval_dq),
       .dbg_cpt_first_edge_cnt  (dbg_cpt_first_edge_cnt),
       .dbg_cpt_second_edge_cnt (dbg_cpt_second_edge_cnt),
       .dbg_idel_up_all         (dbg_idel_up_all),
       .dbg_SM_en               (dbg_SM_en),
       .dbg_idel_down_all       (dbg_idel_down_all),
       .dbg_idel_up_cpt         (dbg_idel_up_cpt),
       .dbg_idel_down_cpt       (dbg_idel_down_cpt),
       .dbg_sel_all_idel_cpt    (dbg_sel_all_idel_cpt),
       .dbg_phy_rdlvl           (dbg_rd_stage1_cal)
       );

  // Instantiate the stage 2 calibration logic which resolves latencies in the
  // system and calibrates the valids.
  mig_7series_v2_0_qdr_rld_phy_read_stage2_cal #
     (
     .BURST_LEN               (BURST_LEN),
     .MEM_TYPE                (MEM_TYPE),
     .nCK_PER_CLK             (nCK_PER_CLK),
     .DATA_WIDTH              (DATA_WIDTH),
     .BW_WIDTH                (BW_WIDTH),
     .N_DATA_LANES            (N_DATA_LANES), // no. of byte lanes
     .BYTE_LANE_WIDTH         (BYTE_LANE_WIDTH), //width of each byte lane
     .FIXED_LATENCY_MODE      (FIXED_LATENCY_MODE),
     .PHY_LATENCY             (PHY_LATENCY),
     .TCQ                     (TCQ)    
     ) 
     u_qdr_rld_phy_read_stage2_cal 
     (
     .clk                     (clk),
     .rst_clk                 (rst_stg2),
     .edge_adv_cal_start      (edge_adv_cal_start),
     .cal_stage2_start        (cal_stage2_start),
     .edge_adv_cal_done       (edge_adv_cal_done),
     .int_rd_cmd_n            (int_rd_cmd_n),
	 .iserdes_rd              (rise_data),
	 .iserdes_fd              (fall_data),
     .phase_valid             (phase_valid),
     .inc_latency             (inc_latency),
     .valid_latency           (valid_latency),
     .pi_edge_adv             (pi_edge_adv),
	 .bitslip                 (bitslip),
     .byte_cnt                (byte_cnt),
     .cal_done                (read_cal_done),
     .max_lat_done_r	      (max_lat_done_r),
     .error_max_latency       (error_max_latency),
     .error_adj_latency       (error_adj_latency),
     .dbg_byte_sel            (dbg_byte_sel),
     .dbg_stage2_cal          (dbg_stage2_cal)
     );
  
 // adjust latency in fixed latency mode or to align data bytes
 genvar nd_i;
  generate
    for (nd_i=0; nd_i < N_DATA_LANES; nd_i=nd_i+1) begin : nd_io_inst
	
	  //break up data into chunks per byte
	  if (nCK_PER_CLK == 4) begin: nd_io_inst_div4
	    assign iserdes_rd_byte[nd_i*4*BYTE_LANE_WIDTH+:4*BYTE_LANE_WIDTH] = 
		   {iserdes_rd[(nd_i*BYTE_LANE_WIDTH)+(3*DATA_WIDTH)+:BYTE_LANE_WIDTH],
		    iserdes_rd[(nd_i*BYTE_LANE_WIDTH)+(2*DATA_WIDTH)+:BYTE_LANE_WIDTH],
		    iserdes_rd[(nd_i*BYTE_LANE_WIDTH)+(1*DATA_WIDTH)+:BYTE_LANE_WIDTH],
		    iserdes_rd[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH]};
	    assign iserdes_fd_byte[nd_i*4*BYTE_LANE_WIDTH+:4*BYTE_LANE_WIDTH] = 
		   {iserdes_fd[(nd_i*BYTE_LANE_WIDTH)+(3*DATA_WIDTH)+:BYTE_LANE_WIDTH],
		    iserdes_fd[(nd_i*BYTE_LANE_WIDTH)+(2*DATA_WIDTH)+:BYTE_LANE_WIDTH],
		    iserdes_fd[(nd_i*BYTE_LANE_WIDTH)+(1*DATA_WIDTH)+:BYTE_LANE_WIDTH],
		    iserdes_fd[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH]};
		
		assign rise_data[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] = 
		    rise_data_byte[nd_i*4*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH];
		assign rise_data[nd_i*BYTE_LANE_WIDTH+(1*DATA_WIDTH)+:BYTE_LANE_WIDTH] = 
		    rise_data_byte[nd_i*4*BYTE_LANE_WIDTH+(1*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH];
		assign rise_data[nd_i*BYTE_LANE_WIDTH+(2*DATA_WIDTH)+:BYTE_LANE_WIDTH] = 
		    rise_data_byte[nd_i*4*BYTE_LANE_WIDTH+(2*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH];
		assign rise_data[nd_i*BYTE_LANE_WIDTH+(3*DATA_WIDTH)+:BYTE_LANE_WIDTH] = 
		    rise_data_byte[nd_i*4*BYTE_LANE_WIDTH+(3*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH];
			
	    assign fall_data[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] = 
		    fall_data_byte[nd_i*4*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH];
		assign fall_data[nd_i*BYTE_LANE_WIDTH+(1*DATA_WIDTH)+:BYTE_LANE_WIDTH] = 
		    fall_data_byte[nd_i*4*BYTE_LANE_WIDTH+(1*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH];
		assign fall_data[nd_i*BYTE_LANE_WIDTH+(2*DATA_WIDTH)+:BYTE_LANE_WIDTH] = 
		    fall_data_byte[nd_i*4*BYTE_LANE_WIDTH+(2*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH];
		assign fall_data[nd_i*BYTE_LANE_WIDTH+(3*DATA_WIDTH)+:BYTE_LANE_WIDTH] = 
		    fall_data_byte[nd_i*4*BYTE_LANE_WIDTH+(3*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH];
	  end else begin: nd_io_inst_div2
	    assign iserdes_rd_byte[nd_i*2*BYTE_LANE_WIDTH+:2*BYTE_LANE_WIDTH] = 
		   {iserdes_rd[(nd_i*BYTE_LANE_WIDTH)+DATA_WIDTH+:BYTE_LANE_WIDTH],
		    iserdes_rd[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH]};
	    assign iserdes_fd_byte[nd_i*2*BYTE_LANE_WIDTH+:2*BYTE_LANE_WIDTH] = 
		   {iserdes_fd[(nd_i*BYTE_LANE_WIDTH)+DATA_WIDTH+:BYTE_LANE_WIDTH],
		    iserdes_fd[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH]};
			
	    assign rise_data[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] = 
		    rise_data_byte[nd_i*2*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH];
		assign rise_data[nd_i*BYTE_LANE_WIDTH+DATA_WIDTH+:BYTE_LANE_WIDTH] = 
		    rise_data_byte[nd_i*2*BYTE_LANE_WIDTH+BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH];
			
	    assign fall_data[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] = 
		    fall_data_byte[nd_i*2*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH];
		assign fall_data[nd_i*BYTE_LANE_WIDTH+DATA_WIDTH+:BYTE_LANE_WIDTH] = 
		    fall_data_byte[nd_i*2*BYTE_LANE_WIDTH+BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH];
	  end

      // Instantiate the data align logic which realigns the data from the
      // ISERDES as needed.
      // will be needed if edge_adv does not work
	  
	  assign bitslip_byte_lane[nd_i] = (nd_i == byte_cnt) ? bitslip : 1'b0;
      
      mig_7series_v2_0_qdr_rld_phy_read_data_align #
       (
        .BYTE_LANE_WIDTH     (BYTE_LANE_WIDTH),
        .nCK_PER_CLK         (nCK_PER_CLK),
        .TCQ                 (TCQ)    
       ) 
       u_qdr_rld_phy_read_data_align 
       (
        .clk                 (clk),
        .rst_clk             (rst_stg2),
        .iserdes_rd          (iserdes_rd_byte[nd_i*nCK_PER_CLK*BYTE_LANE_WIDTH+:nCK_PER_CLK*BYTE_LANE_WIDTH]),
        .iserdes_fd          (iserdes_fd_byte[nd_i*nCK_PER_CLK*BYTE_LANE_WIDTH+:nCK_PER_CLK*BYTE_LANE_WIDTH]),
        .rise_data           (rise_data_byte[nd_i*nCK_PER_CLK*BYTE_LANE_WIDTH+:nCK_PER_CLK*BYTE_LANE_WIDTH]),
        .fall_data           (fall_data_byte[nd_i*nCK_PER_CLK*BYTE_LANE_WIDTH+:nCK_PER_CLK*BYTE_LANE_WIDTH]),
        .bitslip             (bitslip_byte_lane[nd_i]),
        .inc_latency         (inc_latency [nd_i]),
        .max_lat_done        (max_lat_done_r)
       );           
    end
  endgenerate
  
   
 always @ (posedge clk) begin
     if (rst_wr_clk) begin
        if_empty_r <= #TCQ 0;
        if_empty_2r <= #TCQ 0;
     end else begin
        if_empty_r <= #TCQ if_empty;
        if_empty_2r <= #TCQ if_empty_r;
     end
   end
   
   // Always read from input data FIFOs when not empty
   assign if_rden = ~if_empty_2r;
   
  //**************************************************************************
  // Decrement all phaser_ins to starting position
  //**************************************************************************
  //Need to do this one byte lane at a time as they can all have different
  //starting values when re-starting read leveling
  
  always @(posedge clk) begin
    if (rst_stg1 || next_byte) begin
       rdlvl_stg1_start_r <= #TCQ 'b0;
    end else begin
       rdlvl_stg1_start_r[0] <= #TCQ rdlvl_stg1_start;
       rdlvl_stg1_start_r[1] <= #TCQ rdlvl_stg1_start_r[0];
       rdlvl_stg1_start_r[2] <= #TCQ rdlvl_stg1_start_r[1];
       rdlvl_stg1_start_r[3] <= #TCQ rdlvl_stg1_start_r[2];
       rdlvl_stg1_start_r[4] <= #TCQ rdlvl_stg1_start_r[3];
       rdlvl_stg1_start_r[5] <= #TCQ rdlvl_stg1_start_r[4];	
       rdlvl_stg1_start_r[6] <= #TCQ rdlvl_stg1_start_r[5];	
       rdlvl_stg1_start_r[7] <= #TCQ rdlvl_stg1_start_r[6];	
       rdlvl_stg1_start_r[8] <= #TCQ rdlvl_stg1_start_r[7];	
     end
  end

  //
  // Start of PHASER_IN taps decrement logic
  //

  //signal to restart the decrementing of the PI taps
  always @(posedge clk) begin
    if (rst_stg1)
      next_byte_r <= #TCQ 'b0;
    else if (pi_dec_done_r[1] && !pi_dec_done_r[2] && !pi_dec_done && !next_byte_r)
      next_byte_r <= #TCQ 'b1;
    else if (next_byte_r)
      next_byte_r <= #TCQ 'b0;
  end
  
  //byte counter to keep track of what byte we are adjusting
  //this goes through other logic to select the byte lane
  //need to allow for some settling time from when we select a new byte to when
  //the pi_counter_read_val is valid
  always @(posedge clk) begin
    if (rst_stg1) begin
	  pi_byte_cnt <= #TCQ 'b0;
	end else if (next_byte && pi_byte_cnt != N_DATA_LANES) begin
      pi_byte_cnt <= #TCQ pi_byte_cnt + 1; //increment the byte counter
	end else begin
      pi_byte_cnt <= #TCQ pi_byte_cnt; //hold the value
	end
  end
  
  //counter to determine how much to decrement
  always @(posedge clk) begin
    if (rst_stg1 || next_byte) begin
      pi_rdval_cnt    <= #TCQ 'd0;
    end else if (rdlvl_stg1_start_r[7] && 
                ~rdlvl_stg1_start_r[8]) begin
      pi_rdval_cnt    <= #TCQ pi_counter_read_val;
    end else if (pi_rdval_cnt > 'd0) begin
      if (pi_cnt_dec)
        pi_rdval_cnt  <= #TCQ pi_rdval_cnt - 1;
      else            
        pi_rdval_cnt  <= #TCQ pi_rdval_cnt;
    end else if (pi_rdval_cnt == 'd0) begin
      pi_rdval_cnt    <= #TCQ pi_rdval_cnt;
    end
  end
  
  //Counter used to adjust the time between decrements
  always @ (posedge clk) begin
    if (rst_stg1 || pi_cnt_dec) begin
      pi_gap_enforcer <= #TCQ PI_ADJ_GAP; //8 clocks between adjustments for HW
    end else if (pi_gap_enforcer != 'b0) begin
      pi_gap_enforcer <= #TCQ pi_gap_enforcer - 1;
    end else begin
      pi_gap_enforcer <= #TCQ pi_gap_enforcer; //hold value
    end
  end

  assign pi_adjust_rdy = (pi_gap_enforcer == 'b0) ? 1'b1 : 1'b0;
  
  //decrement signal
  always @(posedge clk) begin
    if (rst_stg1 || next_byte) begin
      pi_cnt_dec      <= #TCQ 1'b0;
    end else if (rdlvl_stg1_start_r[8] && (pi_rdval_cnt > 'd0) && 
	              pi_adjust_rdy) begin
      pi_cnt_dec      <= #TCQ ~pi_cnt_dec;
    end else if (pi_rdval_cnt == 'd0) begin
      pi_cnt_dec      <= #TCQ 1'b0;
    end
  end
  
  //indicate when finished
  always @(posedge clk) begin
    if (rst_stg1 || next_byte) begin
      pi_dec_done_r[0] <= #TCQ 1'b0;
    end else if (((pi_cnt_dec == 'd1) && (pi_rdval_cnt == 'd1)) ||
                 (rdlvl_stg1_start_r[8] && (pi_rdval_cnt == 'd0))) begin
      pi_dec_done_r[0] <= #TCQ 1'b1;
    end
  end
  
  //extra registers to make sure timing is met
  always @(posedge clk) begin
    if (rst_stg1 || next_byte) begin
      pi_dec_done_r[2:1] <= #TCQ 'b0;
    end else begin
      pi_dec_done_r[1] <= #TCQ pi_dec_done_r[0];
      pi_dec_done_r[2] <= #TCQ pi_dec_done_r[1];
    end
  end
  
  //Determine if we are done decrementing all the byte lanes
  always @(posedge clk) begin
    if (rst_stg1) begin
      pi_dec_done        <= #TCQ 'b0;
    end else if (pi_dec_done_r[2] && pi_byte_cnt == N_DATA_LANES) begin
      pi_dec_done      <= #TCQ 1'b1;
    end else begin
      pi_dec_done      <= #TCQ pi_dec_done;
    end
  end

  //
  // The entire PHASER_OUT taps decrement logic should be enabled only
  // for CQ_CQB capturing method
  //

  generate
  if (CPT_CLK_CQ_ONLY == "FALSE") begin: cq_cqb_capture

     always @(posedge clk) begin
       if (rst_stg1)
         next_byte_f <= #TCQ 'b0;
       else if (po_dec_done_r[1] && !po_dec_done_r[2] && !po_dec_done && !next_byte_f)
         next_byte_f <= #TCQ 'b1;
       else if (next_byte_f)
         next_byte_f <= #TCQ 'b0;
     end  

     //counter to determine how much to decrement
     always @(posedge clk) begin
       if (rst_stg1 || next_byte) begin
         po_rdval_cnt    <= #TCQ 'd0;
       end else if (rdlvl_stg1_start_r[7] && 
                   ~rdlvl_stg1_start_r[8]) begin
         po_rdval_cnt    <= #TCQ po_counter_read_val;
       end else if (po_rdval_cnt > 'd0) begin
         if (po_cnt_dec)
           po_rdval_cnt  <= #TCQ po_rdval_cnt - 1;
         else            
           po_rdval_cnt  <= #TCQ po_rdval_cnt;
       end else if (po_rdval_cnt == 'd0) begin
         po_rdval_cnt    <= #TCQ po_rdval_cnt;
       end
     end

     always @ (posedge clk) begin
       if (rst_stg1 || po_cnt_dec) begin
           po_gap_enforcer <= #TCQ PI_ADJ_GAP; //8 clocks between adjustments for HW
       end else if (po_gap_enforcer != 'b0) begin
         po_gap_enforcer <= #TCQ po_gap_enforcer - 1;
       end else begin
         po_gap_enforcer <= #TCQ po_gap_enforcer; //hold value
       end
     end

     assign po_adjust_rdy = (po_gap_enforcer == 'b0) ? 1'b1 : 1'b0;

     //decrement signal
     always @(posedge clk) begin
       if (rst_stg1 || next_byte) begin
         po_cnt_dec      <= #TCQ 1'b0;
       end else if (rdlvl_stg1_start_r[8] && (po_rdval_cnt > 'd0) && 
                         po_adjust_rdy) begin
         po_cnt_dec      <= #TCQ ~po_cnt_dec;
       end else if (po_rdval_cnt == 'd0) begin
         po_cnt_dec      <= #TCQ 1'b0;
       end
     end
     
     //indicate when finished
     always @(posedge clk) begin
       if (rst_stg1 || next_byte) begin
         po_dec_done_r[0] <= #TCQ 1'b0;
       end else if (((po_cnt_dec == 'd1) && (po_rdval_cnt == 'd1)) ||
                    (rdlvl_stg1_start_r[8] && (po_rdval_cnt == 'd0))) begin
         po_dec_done_r[0] <= #TCQ 1'b1;
       end
     end
     
     //extra registers to make sure timing is met
     always @(posedge clk) begin
       if (rst_stg1 || next_byte) begin
         po_dec_done_r[2:1] <= #TCQ 'b0;
       end else begin
         po_dec_done_r[1] <= #TCQ po_dec_done_r[0];
         po_dec_done_r[2] <= #TCQ po_dec_done_r[1];
       end
     end
     
     //Determine if we are done decrementing all the byte lanes
     always @(posedge clk) begin
       if (rst_stg1) begin
         po_dec_done        <= #TCQ 'b0;
           end else if (po_dec_done_r[2] && pi_byte_cnt == N_DATA_LANES) begin
             po_dec_done      <= #TCQ 1'b1;
       end else begin
         po_dec_done      <= #TCQ po_dec_done;
       end
     end

     //Combine the taps calculation of both PI and PO for the byte
     //increment when cq & cqb are used for capturing the read data
     assign next_byte = (next_byte_r || next_byte_f);

  end else begin: cq_only_capture

     //Use only the PI taps calculation for the byte increment
     assign next_byte = next_byte_r;

  end
  endgenerate
 
  // Debug signals
  assign dbg_inc_latency       = inc_latency;
  assign dbg_error_max_latency = error_max_latency;


endmodule
