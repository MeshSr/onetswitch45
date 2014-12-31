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
//  Revision:     $Id: qdr_rld_phy_4lanes.v,v 1.2 2012/05/08 01:03:44 rodrigoa Exp $
//                $Author: rodrigoa $
//                $DateTime: 2010/09/27 18:05:17 $
//                $Change: 490882 $
//  Description:
//    This verilog file is the parameterizable 4-byte lane phy primitive top
//    This module may be ganged to create an N-lane phy.
//
//  History:
//  Date        Engineer    Description
//  04/01/2010  J. Mittal   Initial Checkin.  
//  07/30/2013              Added PO_COARSE_BYPASS for QDR2+ design.
//
//////////////////////////////////////////////////////////////////////////////
`timescale 1ps/1ps

module mig_7series_v2_0_qdr_rld_phy_4lanes #(
parameter  MEMORY_TYPE          = "SRAM",
parameter  SIMULATION           = "FALSE",
parameter PO_COARSE_BYPASS   = "FALSE",

parameter  CPT_CLK_CQ_ONLY      = "TRUE",
parameter  INTERFACE_TYPE       = "UNIDIR",
parameter  PRE_FIFO             = "TRUE",
parameter  IODELAY_GRP          = "IODELAY_MIG", //May be assigned unique name 
                                                // when mult IP cores in design
parameter  IODELAY_HP_MODE      = "ON", //IODELAY High Performance Mode
parameter  BYTE_GROUP_TYPE      = 4'b1111,
parameter  GENERATE_CQ          = 4'b0000,
// next three parameter fields correspond to byte lanes for lane order DCBA
parameter  BYTE_LANES           = 4'b1111, // lane existence, one per lane
parameter  BITLANES_IN          = 48'h000_000_000_000,
parameter  BITLANES_OUT         = 48'h000_000_000_000,
parameter  CK_P_OUT             = 48'h000_000_000_000,
parameter  DATA_CTL_N           = 4'b1111, // data or control, per lane
parameter  CPT_CLK_SEL          = 32'h12_12_11_11,
parameter  PO_FINE_DELAY        = 0,
parameter  PI_FINE_DELAY        = 0,

parameter  A_PO_COARSE_DELAY    = 0,
parameter  B_PO_COARSE_DELAY    = 0,
parameter  C_PO_COARSE_DELAY    = 0,
parameter  D_PO_COARSE_DELAY    = 0,

parameter  A_PO_FINE_DELAY      = 0,
parameter  B_PO_FINE_DELAY      = 0,
parameter  C_PO_FINE_DELAY      = 0,
parameter  D_PO_FINE_DELAY      = 0,			 

parameter  BUFMR_DELAY          = 500,
parameter  GENERATE_DDR_CK      = 4'b1111,
parameter  GENERATE_DDR_DK      = 4'b0000,
parameter  DIFF_CK              = 1'b1,
parameter  DIFF_DK              = 1'b1,
parameter  DIFF_CQ              = 1'b0,
parameter  CK_VALUE_D1          = 1'b0,
parameter  DK_VALUE_D1          = 1'b0,
parameter  LANE_REMAP           = 16'h3210,// 4-bit index
                                        // used to rewire to one of four
                                        // input/output buss lanes
                                        // example: 0321 remaps lanes as:
                                        //  D->A
                                        //  C->D
                                        //  B->C
                                        //  A->B
parameter   LAST_BANK              = "FALSE",



//phaser_in parameters
parameter  A_PI_FREQ_REF_DIV       = "NONE",
parameter  A_PI_FINE_DELAY         = PI_FINE_DELAY,
parameter  real A_PI_REFCLK_PERIOD = 2.5,
parameter  real MEMREFCLK_PERIOD   = 2.5,

parameter  B_PI_FREQ_REF_DIV       = A_PI_FREQ_REF_DIV,
parameter  B_PI_FINE_DELAY         = A_PI_FINE_DELAY,
parameter  real B_PI_REFCLK_PERIOD = 2.5,

parameter  C_PI_FREQ_REF_DIV       = A_PI_FREQ_REF_DIV,
parameter  C_PI_FINE_DELAY         = A_PI_FINE_DELAY,
parameter  real C_PI_REFCLK_PERIOD = 2.5,

parameter  D_PI_FREQ_REF_DIV       = A_PI_FREQ_REF_DIV,
parameter  D_PI_FINE_DELAY         = A_PI_FINE_DELAY,
parameter  real D_PI_REFCLK_PERIOD = 2.5,

//phaser_out parameters
//parameter  A_PO_FINE_DELAY         = PO_FINE_DELAY,
parameter  A_PO_OCLK_DELAY         = 5,
parameter  A_PO_OCLKDELAY_INV      = "TRUE",
parameter  real A_PO_REFCLK_PERIOD = 2.5,

//parameter  B_PO_FINE_DELAY         = PO_FINE_DELAY,
parameter  B_PO_OCLK_DELAY         = A_PO_OCLK_DELAY,
parameter  B_PO_OCLKDELAY_INV      = A_PO_OCLKDELAY_INV,
parameter  real B_PO_REFCLK_PERIOD = A_PO_REFCLK_PERIOD,

//parameter  C_PO_FINE_DELAY         = PO_FINE_DELAY,
parameter  C_PO_OCLK_DELAY         = A_PO_OCLK_DELAY,
parameter  C_PO_OCLKDELAY_INV      = A_PO_OCLKDELAY_INV,
parameter  real C_PO_REFCLK_PERIOD = A_PO_REFCLK_PERIOD,

//parameter  D_PO_FINE_DELAY         = PO_FINE_DELAY,
parameter  D_PO_OCLK_DELAY         = A_PO_OCLK_DELAY,
parameter  D_PO_OCLKDELAY_INV      = A_PO_OCLKDELAY_INV,
parameter  real D_PO_REFCLK_PERIOD = A_PO_REFCLK_PERIOD,


// phy_control parameters

parameter PC_BURST_MODE           = "TRUE",
parameter PC_CLK_RATIO            = 2,
//parameter PC_DATA_CTL_N           =  DATA_CTL_N,
parameter PC_CMD_OFFSET           = 0,
parameter PC_RD_CMD_OFFSET_0      = 0,
parameter PC_RD_CMD_OFFSET_1      = 0,
parameter PC_RD_CMD_OFFSET_2      = 0,
parameter PC_RD_CMD_OFFSET_3      = 0,
parameter PC_CO_DURATION          = 1,
parameter PC_DI_DURATION          = 1,
parameter PC_DO_DURATION          = 1,
parameter PC_RD_DURATION_0        = 0,
parameter PC_RD_DURATION_1        = 0,
parameter PC_RD_DURATION_2        = 0,
parameter PC_RD_DURATION_3        = 0,
parameter PC_WR_CMD_OFFSET_0      = 5,
parameter PC_WR_CMD_OFFSET_1      = 5,
parameter PC_WR_CMD_OFFSET_2      = 5,
parameter PC_WR_CMD_OFFSET_3      = 5,
parameter PC_WR_DURATION_0        = 6,
parameter PC_WR_DURATION_1        = 6,
parameter PC_WR_DURATION_2        = 6,
parameter PC_WR_DURATION_3        = 6,
parameter PC_AO_WRLVL_EN          = 0,
parameter PC_AO_TOGGLE            = 4'b0101, // odd bits are toggle (CKE)
parameter PC_FOUR_WINDOW_CLOCKS   = 63,
parameter PC_EVENTS_DELAY         = 18,
parameter PC_PHY_COUNT_EN         = "TRUE",
parameter PC_SYNC_MODE            = "FALSE",
parameter PC_DISABLE_SEQ_MATCH    = "TRUE",
parameter PC_MULTI_REGION         = "FALSE",

parameter HIGHEST_LANE            =  LAST_BANK == "FALSE" ? 4 : (BYTE_LANES[3] ? 4 : BYTE_LANES[2] ? 3 : BYTE_LANES[1] ? 2 : 1),   
parameter N_CTL_LANES             = ((0+(!DATA_CTL_N[0]) & BYTE_LANES[0]) + (0+(!DATA_CTL_N[1]) & BYTE_LANES[1]) + (0+(!DATA_CTL_N[2]) & BYTE_LANES[2]) + (0+(!DATA_CTL_N[3]) & BYTE_LANES[3])),
                            
parameter N_BYTE_LANES            = (0+BYTE_LANES[0]) + (0+BYTE_LANES[1]) + (0+BYTE_LANES[2]) + (0+BYTE_LANES[3]),
                          
parameter N_DATA_LANES            = N_BYTE_LANES - N_CTL_LANES,
parameter REFCLK_FREQ             = 300.0,    //Reference Clk Feq for IODELAYs
parameter BUFG_FOR_OUTPUTS        = "OFF",
parameter CLK_PERIOD              = 0,
parameter TCQ                     = 100
)                         
(

      input                       rst,
      input                       phy_clk,
	  input                       phy_clk_fast,
      input                       freq_refclk,
      input                       mem_refclk,
      //input                       mem_refclk_div4,
      input                       sync_pulse,
      input                       phy_ctl_mstr_empty,
      input [HIGHEST_LANE*80-1:0] phy_dout,
      input                       phy_cmd_wr_en,
      input                       phy_data_wr_en,
      input                       phy_rd_en,
      input                       out_fifos_full ,    
      
      // phy control word
      input                       phy_ctl_clk,
      input                       pll_lock,
      input [31:0]                phy_ctl_wd,
      input                       phy_ctl_wr,
      //input                       input_sink,
      output                      phy_ctl_a_full,
      output                      phy_ctl_full,
      //output reg                  mcGo,
      output                      phy_ctl_empty,
      output                      phy_ctl_ready,
      input                       phy_read_calib,
      input                       phy_write_calib,

      output  [7:0]               ddr_clk,  // to memory
      output                      if_a_empty,
      output                      if_empty,
      output                      if_full,
      output                      of_empty,
      output                      of_ctl_a_full,
      output                      of_data_a_full,
      output                      of_ctl_full,
      output                      of_data_full,
      output [HIGHEST_LANE*80-1:0]phy_din,   // array_mode 4x4
      output [HIGHEST_LANE*12-1:0]O,
      input  [HIGHEST_LANE*12-1:0]I,
      output wire [HIGHEST_LANE*12-1:0] mem_dq_ts,
      input                        sys_rst,
      input                        rst_rd_clk,
      input  [3:0]                 Q_clk,
      input  [3:0]                 Qn_clk,
      input  [1:0]                 cpt_clk_above, //read clock from bank above
      input  [1:0]                 cpt_clk_n_above, //read clock from bank above
      input  [1:0]                 cpt_clk_below, //read clock from bank below
      input  [1:0]                 cpt_clk_n_below, //read clock from bank below
      output [1:0]                 cpt_clk,
      output [1:0]                 cpt_clk_n,
      input                        idelay_ld,
      input  [47:0]                idelay_ce,
      input  [47:0]                idelay_inc,
      input  [HIGHEST_LANE*5*12-1:0] idelay_cnt_in,
      output wire  [HIGHEST_LANE*5*12-1:0] idelay_cnt_out,
      input  [2:0]                 calib_sel,
      input                        calib_in_common,
      input  [3:0]                 drive_on_calib_in_common,
      input                        po_edge_adv,
      input                        po_fine_enable,
      input                        po_coarse_enable,
      input                        po_fine_inc,
      input                        po_coarse_inc,
      input                        po_counter_load_en,
      input                        po_counter_read_en,
      input  [8:0]                 po_counter_load_val,
      input                        po_sel_fine_oclk_delay,
      output reg                   po_coarse_overflow,
      output reg                   po_fine_overflow,
      output reg [8:0]             po_counter_read_val,
      output wire                  po_delay_done,
      input                        po_dec_done,
      input                        po_inc_done,
      
      input                        pi_edge_adv,
      input                        pi_fine_enable,
      input                        pi_fine_inc,
      input                        pi_counter_load_en,
      input                        pi_counter_read_en,
      input  [5:0]                 pi_counter_load_val,
      output reg                   pi_fine_overflow,
      output reg [5:0]             pi_counter_read_val,
      output wire                  ref_dll_lock,
      input                        rst_phaser_ref,
      output [1023:0]              dbg_byte_lane,  // RC
      output [255:0]               dbg_phy_4lanes  // RC

);

localparam  DATA_CTL_A       = (~DATA_CTL_N[0]);
localparam  DATA_CTL_B       = (~DATA_CTL_N[1]);
localparam  DATA_CTL_C       = (~DATA_CTL_N[2]);
localparam  DATA_CTL_D       = (~DATA_CTL_N[3]);

localparam  PRESENT_DATA_A   = BYTE_LANES[0] &&  DATA_CTL_N[0];
localparam  PRESENT_DATA_B   = BYTE_LANES[1] &&  DATA_CTL_N[1];
localparam  PRESENT_DATA_C   = BYTE_LANES[2] &&  DATA_CTL_N[2];
localparam  PRESENT_DATA_D   = BYTE_LANES[3] &&  DATA_CTL_N[3];

// OUTPUT_BANK is true when the byte lane has atleast one output byte lane. 

localparam OUTPUT_BANK = ((BYTE_LANES[0] && ~BYTE_GROUP_TYPE[0]) ||
                          (BYTE_LANES[1] && ~BYTE_GROUP_TYPE[1]) ||
                          (BYTE_LANES[2] && ~BYTE_GROUP_TYPE[2]) || 
                          (BYTE_LANES[3] && ~BYTE_GROUP_TYPE[3]) ) ? "TRUE" : "FALSE";
						  
localparam INPUT_BANK =  ((BYTE_LANES[0] && DATA_CTL_N[0]) ||
                          (BYTE_LANES[1] && DATA_CTL_N[1]) ||
                          (BYTE_LANES[2] && DATA_CTL_N[2]) || 
                          (BYTE_LANES[3] && DATA_CTL_N[3]) ) ? "TRUE" : "FALSE";
                             
                                                               
localparam  PC_DATA_CTL_A    = (MEMORY_TYPE == "RLD3" && DATA_CTL_A) ? "FALSE" : "TRUE";
localparam  PC_DATA_CTL_B    = (MEMORY_TYPE == "RLD3" && DATA_CTL_B) ? "FALSE" : "TRUE";
localparam  PC_DATA_CTL_C    = (MEMORY_TYPE == "RLD3" && DATA_CTL_C) ? "FALSE" : "TRUE";
localparam  PC_DATA_CTL_D    = (MEMORY_TYPE == "RLD3" && DATA_CTL_D) ? "FALSE" : "TRUE";

localparam MSB_BURST_PEND_PO             =  3;
localparam MSB_BURST_PEND_PI             =  7;
localparam MSB_RANK_SEL_I                =  MSB_BURST_PEND_PI+ 8;
localparam MSB_RANK_SEL_O                =  MSB_RANK_SEL_I   + 8;
localparam MSB_DIV_RST                   =  MSB_RANK_SEL_O   + 1;
localparam MSB_PHASE_SELECT              =  MSB_DIV_RST      + 1;
localparam MSB_BURST_PI                  =  MSB_PHASE_SELECT + 4;
localparam PHASER_CTL_BUS_WIDTH          =  MSB_BURST_PI     + 1;

localparam A_BYTE_GROUP_TYPE = ((BYTE_LANES[0] != 1) ? "DC" :
                                (INTERFACE_TYPE == "BIDIR") ? 
                                  ((DATA_CTL_N[0] == 1) ? "BIDIR" : "OUT") : 
                                (BYTE_GROUP_TYPE[0] == 1'b1)? "IN" : "OUT");
                                     
localparam B_BYTE_GROUP_TYPE = ((BYTE_LANES[1] != 1) ? "DC" :
                                 (INTERFACE_TYPE == "BIDIR") ? 
                                   ((DATA_CTL_N[1] == 1) ? "BIDIR" : "OUT"): 
                                 (BYTE_GROUP_TYPE[1] == 1'b1)? "IN" : "OUT");
                                     
localparam C_BYTE_GROUP_TYPE = ((BYTE_LANES[2] != 1) ? "DC" :
                                 (INTERFACE_TYPE == "BIDIR") ? 
                                   ((DATA_CTL_N[2] == 1) ? "BIDIR" : "OUT") : 
                                 (BYTE_GROUP_TYPE[2] == 1'b1)? "IN" : "OUT");                                  

localparam D_BYTE_GROUP_TYPE = ((BYTE_LANES[3] != 1) ? "DC" :
                                 (INTERFACE_TYPE == "BIDIR") ? 
                                   ((DATA_CTL_N[3] == 1) ? "BIDIR" : "OUT") : 
                                 (BYTE_GROUP_TYPE[3] == 1'b1)? "IN" : "OUT");
                                     
wire [PHASER_CTL_BUS_WIDTH-1:0] phaser_ctl_bus;

wire [7:0]  in_rank;
wire [7:0]  out_rank;
wire [11:0] IO_A;
wire [11:0] IO_B;
wire [11:0] IO_C;
wire [11:0] IO_D;

wire [319:0] phy_din_remap;

reg        A_po_counter_read_en;
wire [8:0] A_po_counter_read_val;
reg        A_pi_counter_read_en;
wire [5:0] A_pi_counter_read_val;
wire       A_pi_fine_overflow;
wire       A_po_coarse_overflow;
wire       A_po_fine_overflow;
reg        A_pi_edge_adv;
reg        A_pi_fine_enable;
reg        A_pi_fine_inc;
reg        A_pi_counter_load_en;
reg [5:0]  A_pi_counter_load_val;


reg        A_po_fine_enable;
reg        A_po_edge_adv;
reg        A_po_coarse_enable;
reg        A_po_fine_inc;
reg        A_po_sel_fine_oclk_delay;
reg        A_po_coarse_inc;
reg        A_po_counter_load_en;
reg [8:0]  A_po_counter_load_val;
wire	   A_po_delay_done;
   

reg        B_po_counter_read_en;
wire [8:0] B_po_counter_read_val;
reg        B_pi_counter_read_en;
wire [5:0] B_pi_counter_read_val;
wire       B_pi_fine_overflow;
wire       B_po_coarse_overflow;
wire       B_po_fine_overflow;
reg        B_pi_edge_adv;
reg        B_pi_fine_enable;
reg        B_pi_fine_inc;
reg        B_pi_counter_load_en;
reg [5:0]  B_pi_counter_load_val;
wire	   B_po_delay_done;
   


reg        B_po_fine_enable;
reg        B_po_edge_adv;
reg        B_po_coarse_enable;
reg        B_po_fine_inc;
reg        B_po_coarse_inc;
reg        B_po_sel_fine_oclk_delay;
reg        B_po_counter_load_en;
reg [8:0]  B_po_counter_load_val;

reg        C_pi_fine_inc;
reg        D_pi_fine_inc;
reg        C_pi_fine_enable;
reg        D_pi_fine_enable;
reg        C_pi_edge_adv;
reg        D_pi_edge_adv;
reg        C_po_counter_load_en;
reg        D_po_counter_load_en;
reg        C_po_coarse_inc;
reg        D_po_coarse_inc;
reg        C_po_fine_inc;
reg        D_po_fine_inc;
reg        C_po_sel_fine_oclk_delay;
reg        D_po_sel_fine_oclk_delay;
reg [5:0]  C_pi_counter_load_val;
reg [5:0]  D_pi_counter_load_val;
reg [8:0]  C_po_counter_load_val;
reg [8:0]  D_po_counter_load_val;
reg        C_po_edge_adv;
reg        C_po_coarse_enable;
reg        D_po_edge_adv;
reg        D_po_coarse_enable;
reg        C_po_fine_enable;
reg        D_po_fine_enable;
wire       C_po_coarse_overflow;
wire       D_po_coarse_overflow;
wire       C_po_fine_overflow;
wire       D_po_fine_overflow;
wire [8:0] C_po_counter_read_val;
wire [8:0] D_po_counter_read_val;
reg        C_po_counter_read_en;
reg        D_po_counter_read_en;
wire       C_pi_fine_overflow;
wire       D_pi_fine_overflow;
reg        C_pi_counter_read_en;
reg        D_pi_counter_read_en;
reg        C_pi_counter_load_en;
reg        D_pi_counter_load_en;
wire [5:0] C_pi_counter_read_val;
wire [5:0] D_pi_counter_read_val;
wire 	   C_po_delay_done;
wire       D_po_delay_done;
   
  

wire       A_if_empty;
wire       B_if_empty;
wire       C_if_empty;
wire       D_if_empty;
wire       A_if_a_empty;
wire       B_if_a_empty;
wire       C_if_a_empty;
wire       D_if_a_empty;
wire       A_if_full;
wire       B_if_full;
wire       C_if_full;
wire       D_if_full;
//wire       A_if_a_full;
//wire       B_if_a_full;
//wire       C_if_a_full;
//wire       D_if_a_full;
wire       A_of_empty;
wire       B_of_empty;
wire       C_of_empty;
wire       D_of_empty;
wire       A_of_full;
wire       B_of_full;
wire       C_of_full;
wire       D_of_full; 
wire       A_of_ctl_full;
wire       B_of_ctl_full;
wire       C_of_ctl_full;
wire       D_of_ctl_full;
wire       A_of_data_full;
wire       B_of_data_full;
wire       C_of_data_full;
wire       D_of_data_full;
wire       A_of_a_full;
wire       B_of_a_full;
wire       C_of_a_full;
wire       D_of_a_full;
wire       A_of_ctl_a_full;
wire       B_of_ctl_a_full;
wire       C_of_ctl_a_full;
wire       D_of_ctl_a_full;
wire       A_of_data_a_full;
wire       B_of_data_a_full;
wire       C_of_data_a_full;
wire       D_of_data_a_full;
reg        A_cq_clk;
reg        B_cq_clk;
reg        C_cq_clk;
reg        D_cq_clk;
reg        A_cqn_clk;
reg        B_cqn_clk;
reg        C_cqn_clk;
reg        D_cqn_clk;
wire  [1:0]  A_ddr_clk;  // for generation
wire  [1:0]  B_ddr_clk;  // 
wire  [1:0]  C_ddr_clk;  // 
wire  [1:0]  D_ddr_clk;  //

wire [1:0] cq_buf_clk;
wire [1:0] cqn_buf_clk;
wire [3:0] cq_clk;
wire [3:0] cqn_clk;
wire       cq_capt_clk;
wire       cqn_capt_clk;
wire [3:0] aux_out;
wire [1:0] phy_encalib; 


wire       dangling_outputs;  // this reduces all constant 0 values to 1 signal
                              // which can be tied to an unused input. The purpose
                              // is to fake the tools into ignoring dangling outputs.
                              // Because it is anded with 1'b0, the contributing signals
                              // are folded as constants or trimmed.
                      
assign dbg_phy_4lanes[3:0] = {D_if_empty, C_if_empty, B_if_empty, A_if_empty};
					  
wire [255:0] A_dbg_byte_lane;
wire [255:0] B_dbg_byte_lane;
wire [255:0] C_dbg_byte_lane;
wire [255:0] D_dbg_byte_lane;

assign dbg_byte_lane = {D_dbg_byte_lane,
                          C_dbg_byte_lane,
                          B_dbg_byte_lane,
                          A_dbg_byte_lane};

assign     dangling_outputs = (& idelay_cnt_in) & ( &phy_dout) ;

assign      if_empty = A_if_empty | B_if_empty | C_if_empty | D_if_empty;
assign      if_a_empty = A_if_a_empty & B_if_a_empty & C_if_a_empty & D_if_a_empty;
assign      if_full  = A_if_full  | B_if_full  | C_if_full  | D_if_full ;
//assign      if_a_full  = A_if_a_full  | B_if_a_full  | C_if_a_full  | D_if_a_full ;
assign      of_empty = A_of_empty & B_of_empty & C_of_empty & D_of_empty;
assign      of_ctl_full     = A_of_ctl_full  | B_of_ctl_full  | C_of_ctl_full  | D_of_ctl_full ;
assign      of_data_full    = A_of_data_full  | B_of_data_full  | C_of_data_full  | D_of_data_full ;
assign      of_ctl_a_full   = A_of_ctl_a_full  | B_of_ctl_a_full  | C_of_ctl_a_full  | D_of_ctl_a_full ;
assign      of_data_a_full  = A_of_data_a_full  | B_of_data_a_full  | C_of_data_a_full  | D_of_data_a_full ;
assign      po_delay_done   = A_po_delay_done & B_po_delay_done & C_po_delay_done & D_po_delay_done;
   
function [47:0] part_select_48;
input [191:0] vector;
input [1:0]  select;
begin
     case (select)
     2'b00 : part_select_48[47:0] = vector[1*48-1:0*48];
     2'b01 : part_select_48[47:0] = vector[2*48-1:1*48];
     2'b10 : part_select_48[47:0] = vector[3*48-1:2*48];
     2'b11 : part_select_48[47:0] = vector[4*48-1:3*48];
     endcase
end
endfunction

function [79:0] part_select_80;
input [319:0] vector;
input [1:0]  select;
begin
     case (select)
     2'b00 : part_select_80[79:0] = vector[1*80-1:0*80];
     2'b01 : part_select_80[79:0] = vector[2*80-1:1*80];
     2'b10 : part_select_80[79:0] = vector[3*80-1:2*80];
     2'b11 : part_select_80[79:0] = vector[4*80-1:3*80];
     endcase
end
endfunction

wire [319:0]     phy_dout_remap;

assign ddr_clk = {D_ddr_clk, C_ddr_clk, B_ddr_clk, A_ddr_clk};

generate
  if (~BYTE_LANES[0]) begin
      assign A_of_ctl_full      = 0;
      assign A_of_data_full     = 0;
      assign A_of_ctl_a_full    = 0;
      assign A_of_data_a_full   = 0;
  end else if (PRESENT_DATA_A) begin
      assign A_of_data_full     = A_of_full;
      assign A_of_ctl_full      = 0;
      assign A_of_data_a_full   = A_of_a_full;
      assign A_of_ctl_a_full    = 0;
  end  else  begin
      assign A_of_ctl_full      = A_of_full;
      assign A_of_data_full     = 0;
      assign A_of_ctl_a_full    = A_of_a_full;
      assign A_of_data_a_full   = 0;
  end
  
  if (~BYTE_LANES[1]) begin
      assign B_of_ctl_full      = 0;
      assign B_of_data_full     = 0;
      assign B_of_ctl_a_full    = 0;
      assign B_of_data_a_full   = 0;
  end else if (PRESENT_DATA_B) begin
      assign B_of_data_full     = B_of_full;
      assign B_of_ctl_full      = 0;
      assign B_of_data_a_full   = B_of_a_full;
      assign B_of_ctl_a_full    = 0;
  end else  begin
      assign B_of_ctl_full      = B_of_full;
      assign B_of_data_full     = 0;
      assign B_of_ctl_a_full    = B_of_a_full;
      assign B_of_data_a_full   = 0;
  end
  
  if (~BYTE_LANES[2]) begin
      assign C_of_ctl_full      = 0;
      assign C_of_data_full     = 0;
      assign C_of_ctl_a_full    = 0;
      assign C_of_data_a_full   = 0;
  end else if (PRESENT_DATA_C) begin
      assign C_of_data_full     = C_of_full;
      assign C_of_ctl_full      = 0;
      assign C_of_data_a_full   = C_of_a_full;
      assign C_of_ctl_a_full    = 0;
  end else  begin
      assign C_of_ctl_full       = C_of_full;
      assign C_of_data_full      = 0;
      assign C_of_ctl_a_full     = C_of_a_full;
      assign C_of_data_a_full    = 0;
  end
  
  if (~BYTE_LANES[3]) begin
      assign D_of_ctl_full      = 0;
      assign D_of_data_full     = 0;
      assign D_of_ctl_a_full    = 0;
      assign D_of_data_a_full   = 0;
  end else if (PRESENT_DATA_D) begin
      assign D_of_data_full      = D_of_full;
      assign D_of_ctl_full       = 0;
      assign D_of_data_a_full    = D_of_a_full;
      assign D_of_ctl_a_full     = 0;
  end else  begin
      assign D_of_ctl_full       = D_of_full;
      assign D_of_data_full      = 0;
      assign D_of_ctl_a_full     = D_of_a_full;
      assign D_of_data_a_full    = 0;
  end
// byte lane must exist and be data lane.
  if (PRESENT_DATA_A )
      case ( LANE_REMAP[1:0]   )
      2'b00 : assign phy_din[1*80-1:0]   = phy_din_remap[79:0];
      2'b01 : assign phy_din[2*80-1:80]  = phy_din_remap[79:0];
      2'b10 : assign phy_din[3*80-1:160] = phy_din_remap[79:0];
      2'b11 : assign phy_din[4*80-1:240] = phy_din_remap[79:0];
      endcase
  else
      case ( LANE_REMAP[1:0]   )
      2'b00 : assign phy_din[1*80-1:0]   = 80'h0;
      2'b01 : assign phy_din[2*80-1:80]  = 80'h0;
      2'b10 : assign phy_din[3*80-1:160] = 80'h0;
      2'b11 : assign phy_din[4*80-1:240] = 80'h0;
      endcase

  if (PRESENT_DATA_B )
      case ( LANE_REMAP[5:4]  )
      2'b00 : assign phy_din[1*80-1:0]   = phy_din_remap[159:80];
      2'b01 : assign phy_din[2*80-1:80]  = phy_din_remap[159:80];
      2'b10 : assign phy_din[3*80-1:160] = phy_din_remap[159:80];
      2'b11 : assign phy_din[4*80-1:240] = phy_din_remap[159:80];
      endcase
   else
     if (HIGHEST_LANE > 1)
        case ( LANE_REMAP[5:4]   )
        2'b00 : assign phy_din[1*80-1:0]   = 80'h0;
        2'b01 : assign phy_din[2*80-1:80]  = 80'h0;
        2'b10 : assign phy_din[3*80-1:160] = 80'h0;
        2'b11 : assign phy_din[4*80-1:240] = 80'h0;
        endcase
// byte lane must exist and be data lane.
  if (PRESENT_DATA_C)
      case ( LANE_REMAP[9:8]  )
      2'b00 : assign phy_din[1*80-1:0]   = phy_din_remap[239:160];
      2'b01 : assign phy_din[2*80-1:80]  = phy_din_remap[239:160];
      2'b10 : assign phy_din[3*80-1:160] = phy_din_remap[239:160];
      2'b11 : assign phy_din[4*80-1:240] = phy_din_remap[239:160];
      endcase
  else
     if (HIGHEST_LANE > 2)
        case ( LANE_REMAP[9:8]   )
        2'b00 : assign phy_din[1*80-1:0]   = 80'h0;
        2'b01 : assign phy_din[2*80-1:80]  = 80'h0;
        2'b10 : assign phy_din[3*80-1:160] = 80'h0;
        2'b11 : assign phy_din[4*80-1:240] = 80'h0;
        endcase

  if (PRESENT_DATA_D )
      case ( LANE_REMAP[13:12]  )
      2'b00 : assign phy_din[1*80-1:0]   = phy_din_remap[319:240];
      2'b01 : assign phy_din[2*80-1:80]  = phy_din_remap[319:240];
      2'b10 : assign phy_din[3*80-1:160] = phy_din_remap[319:240];
      2'b11 : assign phy_din[4*80-1:240] = phy_din_remap[319:240];
      endcase
  else
     if (HIGHEST_LANE > 3)
        case ( LANE_REMAP[13:12]   )
        2'b00 : assign phy_din[1*80-1:0]   = 80'h0;
        2'b01 : assign phy_din[2*80-1:80]  = 80'h0;
        2'b10 : assign phy_din[3*80-1:160] = 80'h0;
        2'b11 : assign phy_din[4*80-1:240] = 80'h0;
      endcase
endgenerate   

assign phaser_ctl_bus[MSB_RANK_SEL_I : MSB_RANK_SEL_I - 7] = in_rank;


generate 
if  (OUTPUT_BANK == "TRUE" && BUFG_FOR_OUTPUTS == "OFF") begin : PHY_CONTROL_INST 

    `ifdef FUJI_BLH
       B_PHY_CONTROL #(
    `else
       PHY_CONTROL #(
    `endif
//B_PHY_CONTROL #(
  .AO_WRLVL_EN          ( PC_AO_WRLVL_EN),
  .AO_TOGGLE            ( PC_AO_TOGGLE),
  .BURST_MODE           ( PC_BURST_MODE),
  .CO_DURATION          ( PC_CO_DURATION ),
  .CLK_RATIO            ( PC_CLK_RATIO),
  .DATA_CTL_A_N         ( PC_DATA_CTL_A),
  .DATA_CTL_B_N         ( PC_DATA_CTL_B),
  .DATA_CTL_C_N         ( PC_DATA_CTL_C),
  .DATA_CTL_D_N         ( PC_DATA_CTL_D),
  .DI_DURATION          ( PC_DI_DURATION ),
  .DO_DURATION          ( PC_DO_DURATION ),
  .EVENTS_DELAY         ( PC_EVENTS_DELAY),
  .FOUR_WINDOW_CLOCKS   ( PC_FOUR_WINDOW_CLOCKS),
  .MULTI_REGION         ( PC_MULTI_REGION ),
  .PHY_COUNT_ENABLE     ( PC_PHY_COUNT_EN),
  .DISABLE_SEQ_MATCH    ( PC_DISABLE_SEQ_MATCH),
  .SYNC_MODE            ( PC_SYNC_MODE),
  .CMD_OFFSET           ( PC_CMD_OFFSET),

  .RD_CMD_OFFSET_0      ( PC_RD_CMD_OFFSET_0),
  .RD_CMD_OFFSET_1      ( PC_RD_CMD_OFFSET_1),
  .RD_CMD_OFFSET_2      ( PC_RD_CMD_OFFSET_2),
  .RD_CMD_OFFSET_3      ( PC_RD_CMD_OFFSET_3),
  .RD_DURATION_0        ( PC_RD_DURATION_0),
  .RD_DURATION_1        ( PC_RD_DURATION_1),
  .RD_DURATION_2        ( PC_RD_DURATION_2),
  .RD_DURATION_3        ( PC_RD_DURATION_3),
  .WR_CMD_OFFSET_0      ( PC_WR_CMD_OFFSET_0),
  .WR_CMD_OFFSET_1      ( PC_WR_CMD_OFFSET_1),
  .WR_CMD_OFFSET_2      ( PC_WR_CMD_OFFSET_2),
  .WR_CMD_OFFSET_3      ( PC_WR_CMD_OFFSET_3),
  .WR_DURATION_0        ( PC_WR_DURATION_0),
  .WR_DURATION_1        ( PC_WR_DURATION_1),
  .WR_DURATION_2        ( PC_WR_DURATION_2),
  .WR_DURATION_3        ( PC_WR_DURATION_3)
) phy_control_i (
  .AUXOUTPUT            (aux_out),
//`ifdef DEDICATED_ROUTES
  .INBURSTPENDING       (),
  .INRANKA              (),
  .INRANKB              (),
  .INRANKC              (),
  .INRANKD              (),
//  .OUTBURSTPENDING      (),
//  .PCENABLECALIB        (),
//`else
//  .INBURSTPENDING       (phaser_ctl_bus[MSB_BURST_PEND_PI:MSB_BURST_PEND_PI-3]),
//  .INRANKA              (in_rank[1:0]),
//  .INRANKB              (in_rank[3:2]),
//  .INRANKC              (in_rank[5:4]),
//  .INRANKD              (in_rank[7:6]),
  .OUTBURSTPENDING      (phaser_ctl_bus[MSB_BURST_PEND_PO:MSB_BURST_PEND_PO-3]),
  .PCENABLECALIB        (phy_encalib),
//`endif
  .PHYCTLALMOSTFULL     (phy_ctl_a_full),
  .PHYCTLFULL           (phy_ctl_full),
  .PHYCTLEMPTY          (phy_ctl_empty),
  .PHYCTLREADY          (phy_ctl_ready),
  .MEMREFCLK            (mem_refclk),
  .PHYCLK               (phy_ctl_clk),
  .PHYCTLMSTREMPTY      (phy_ctl_mstr_empty),
  .PHYCTLWD             (phy_ctl_wd),
  .PHYCTLWRENABLE       (phy_ctl_wr),
  .PLLLOCK              (pll_lock),
  .REFDLLLOCK           (ref_dll_lock),
  .RESET                (rst),
  .SYNCIN               (sync_pulse),
  .READCALIBENABLE      (phy_read_calib),
  .WRITECALIBENABLE     (phy_write_calib)
);

end else begin : NO_PHY_CONTROL_INST

   assign phaser_ctl_bus = 'b0;
   assign phy_ctl_full   = 1'b0;
   assign phy_ctl_a_full = 1'b0;
   assign phy_ctl_ready  = ~rst;//1'b1;
   assign phy_ctl_empty  = 1'b0;
end
endgenerate

//obligatory phaser-ref
//GENERATE statement commented out to avoid a change in the UCF for placing the 
//PHASER_REF for non-BUFG interfaces (which is most of them).
//To use the BUFG scheme for outputs this will need to be uncommented
//generate
//  if (BUFG_FOR_OUTPUTS == "OFF" ||
//     (BUFG_FOR_OUTPUTS == "ON" && INPUT_BANK == "TRUE")) begin : PHASER_REF_INST
    PHASER_REF phaser_ref_i(

     .LOCKED (ref_dll_lock),
     .CLKIN  (freq_refclk),
     .PWRDWN (1'b0),
     .RST    (rst_phaser_ref)
    );
//  end else begin : GEN_NO_PHASER_REF
//    assign ref_dll_lock = 1'b1;
//  end
//endgenerate
   

generate

if ( BYTE_LANES[0] ) begin : qdr_rld_byte_lane_A

  assign phy_dout_remap[79:0] = part_select_80(phy_dout, (LANE_REMAP[1:0]));

  mig_7series_v2_0_qdr_rld_byte_lane#(
     .ABCD                   ("A"),
     .SIMULATION             (SIMULATION), 
     .PO_COARSE_BYPASS		 (PO_COARSE_BYPASS),

     .CPT_CLK_CQ_ONLY        (CPT_CLK_CQ_ONLY),  
     .PRE_FIFO               (PRE_FIFO),                     
     .BITLANES_IN            (BITLANES_IN[11:0]),
     .BITLANES_OUT           (BITLANES_OUT[11:0]),
	 .CK_P_OUT               (CK_P_OUT[11:0]),
     .MEMORY_TYPE            (MEMORY_TYPE),
     .DATA_CTL_N             (DATA_CTL_N[0]),
     .GENERATE_DDR_CK        (GENERATE_DDR_CK[0]),
     .GENERATE_DDR_DK        (GENERATE_DDR_DK[0]),
     .DIFF_CK                (DIFF_CK),
     .DIFF_DK                (DIFF_DK),
     .CK_VALUE_D1            (CK_VALUE_D1),
     .DK_VALUE_D1            (DK_VALUE_D1),
     .IODELAY_GRP            (IODELAY_GRP),
     .IODELAY_HP_MODE        (IODELAY_HP_MODE),
     .BYTE_GROUP_TYPE        (A_BYTE_GROUP_TYPE),
	 .REFCLK_FREQ            (REFCLK_FREQ),
	 .BUFG_FOR_OUTPUTS       (BUFG_FOR_OUTPUTS),
	 .CLK_PERIOD             (CLK_PERIOD),
	 .PC_CLK_RATIO           (PC_CLK_RATIO),
     .PI_FREQ_REF_DIV        (A_PI_FREQ_REF_DIV),
     .PI_FINE_DELAY          (A_PI_FINE_DELAY),
     .PI_REFCLK_PERIOD       (A_PI_REFCLK_PERIOD),
     .MEMREFCLK_PERIOD       (MEMREFCLK_PERIOD),
     .PO_FINE_DELAY          (PO_FINE_DELAY),
     .PO_FINE_SKEW_DELAY     (A_PO_FINE_DELAY),
     .PO_COARSE_SKEW_DELAY   (A_PO_COARSE_DELAY),		     
     .PO_OCLK_DELAY          (A_PO_OCLK_DELAY),
     .PO_OCLKDELAY_INV       (A_PO_OCLKDELAY_INV),
     .PO_REFCLK_PERIOD       (A_PO_REFCLK_PERIOD),
     .PHASER_CTL_BUS_WIDTH   (PHASER_CTL_BUS_WIDTH),
     .TCQ                    (TCQ)
     )
   qdr_rld_byte_lane_A(
      .O                     ( O[11:0]),
      .I                     ( I[11:0]),
      .mem_dq_ts             ( mem_dq_ts[11:0]),
      .rst                   (rst),
      .phy_clk               (phy_clk),
	  .phy_clk_fast          (phy_clk_fast),
      .freq_refclk           (freq_refclk),
      .mem_refclk            (mem_refclk),
      .sync_pulse            (sync_pulse),
      .sys_rst               (sys_rst),
      .rst_rd_clk            (rst_rd_clk),
      .cq_buf_clk            (A_cq_clk),
      .cqn_buf_clk           (A_cqn_clk),
      .ddr_ck_out            (A_ddr_clk),
      .if_a_empty            (A_if_a_empty),
      .if_empty              (A_if_empty),
      .if_a_full             (),
      .if_full               (A_if_full),
      .of_a_empty            (),
      .of_empty              (A_of_empty),
      .of_a_full             (A_of_a_full),
      .of_full               (A_of_full),
      .out_fifos_full           (out_fifos_full ),    
      .phy_din               (phy_din_remap[79:0]),
      .phy_dout              (phy_dout_remap[79:0]),
      .phy_cmd_wr_en         (phy_cmd_wr_en),
      .phy_data_wr_en        (phy_data_wr_en),
      .phy_rd_en             (phy_rd_en),
      .phaser_ctl_bus        (phaser_ctl_bus),
      .idelay_ld             (idelay_ld),
      .idelay_ce             (idelay_ce[(1*12)-1:(12)*0]),
      .idelay_inc            (idelay_inc[(1*12)-1:(12)*0]),
      .idelay_cnt_in         (idelay_cnt_in[12*5-1:0]),
      .idelay_cnt_out        (idelay_cnt_out[12*5-1:0]),
      .po_edge_adv           (A_po_edge_adv),
      .po_fine_enable        (A_po_fine_enable),
      .po_coarse_enable      (A_po_coarse_enable),
      .po_fine_inc           (A_po_fine_inc),
      .po_coarse_inc         (A_po_coarse_inc),
      .po_counter_load_en    (A_po_counter_load_en),
      .po_counter_read_en    (A_po_counter_read_en),
      .po_counter_load_val   (A_po_counter_load_val),
      .po_coarse_overflow    (A_po_coarse_overflow),
      .po_fine_overflow      (A_po_fine_overflow),
      .po_counter_read_val   (A_po_counter_read_val),
      .po_sel_fine_oclk_delay(A_po_sel_fine_oclk_delay),
      .pi_edge_adv           (A_pi_edge_adv),
      .pi_fine_enable        (A_pi_fine_enable),
      .pi_fine_inc           (A_pi_fine_inc),
      .pi_counter_load_en    (A_pi_counter_load_en),
      .pi_counter_read_en    (A_pi_counter_read_en),
      .pi_counter_load_val   (A_pi_counter_load_val),
      .pi_fine_overflow      (A_pi_fine_overflow),
      .pi_counter_read_val   (A_pi_counter_read_val),
      .po_delay_done         (A_po_delay_done),
	  .po_dec_done           (po_dec_done),
      .po_inc_done              (po_inc_done),
	  
      .dbg_byte_lane         (A_dbg_byte_lane)
);

end
else begin : no_byte_lane_A
       assign A_of_a_full = 1'b0;
       assign A_of_full = 1'b0;
       assign A_if_full = 1'b0;
	   assign A_if_empty = 0;
       assign A_po_delay_done = 1;
       assign O[11:0]    = 0;
end

if ( BYTE_LANES[1] ) begin : qdr_rld_byte_lane_B

  assign phy_dout_remap[159:80] = part_select_80(phy_dout, (LANE_REMAP[5:4]));
  mig_7series_v2_0_qdr_rld_byte_lane#(
     .ABCD                   ("B"),
     .SIMULATION             (SIMULATION),
     .PO_COARSE_BYPASS		 (PO_COARSE_BYPASS),

     .CPT_CLK_CQ_ONLY        (CPT_CLK_CQ_ONLY), 
     .PRE_FIFO               (PRE_FIFO),     
     .BITLANES_IN            (BITLANES_IN[23:12]),
     .BITLANES_OUT           (BITLANES_OUT[23:12]),
	 .CK_P_OUT               (CK_P_OUT[23:12]),
     .MEMORY_TYPE            (MEMORY_TYPE),
     .BYTE_GROUP_TYPE        (B_BYTE_GROUP_TYPE),
	 .REFCLK_FREQ            (REFCLK_FREQ),
	 .BUFG_FOR_OUTPUTS       (BUFG_FOR_OUTPUTS),
	 .CLK_PERIOD             (CLK_PERIOD),
	 .PC_CLK_RATIO           (PC_CLK_RATIO),
     .IODELAY_GRP            (IODELAY_GRP),
     .IODELAY_HP_MODE        (IODELAY_HP_MODE),
     .DATA_CTL_N             (DATA_CTL_N[1]),
     .GENERATE_DDR_CK        (GENERATE_DDR_CK[1]),
     .GENERATE_DDR_DK        (GENERATE_DDR_DK[1]),
     .DIFF_CK                (DIFF_CK),
     .DIFF_DK                (DIFF_DK),
     .CK_VALUE_D1            (CK_VALUE_D1),
     .DK_VALUE_D1            (DK_VALUE_D1),
     .PI_FREQ_REF_DIV        (B_PI_FREQ_REF_DIV),
     .PI_FINE_DELAY          (B_PI_FINE_DELAY),
     .PI_REFCLK_PERIOD       (B_PI_REFCLK_PERIOD),
     .MEMREFCLK_PERIOD       (MEMREFCLK_PERIOD),
     .PO_FINE_DELAY          (PO_FINE_DELAY),
     .PO_FINE_SKEW_DELAY     (B_PO_FINE_DELAY),
     .PO_COARSE_SKEW_DELAY   (B_PO_COARSE_DELAY),
     .PO_OCLK_DELAY          (B_PO_OCLK_DELAY),
     .PO_OCLKDELAY_INV       (B_PO_OCLKDELAY_INV),
     .PO_REFCLK_PERIOD       (B_PO_REFCLK_PERIOD),
     .PHASER_CTL_BUS_WIDTH   (PHASER_CTL_BUS_WIDTH),
     .TCQ                    (TCQ)
     )
   qdr_rld_byte_lane_B(
      .O                     ( O[23:12]),
      .I                     ( I[23:12]),
      .mem_dq_ts             ( mem_dq_ts[23:12]),
      .rst                   (rst),
      .phy_clk               (phy_clk),
	  .phy_clk_fast          (phy_clk_fast),
      .freq_refclk           (freq_refclk),
      .mem_refclk            (mem_refclk),
      .sync_pulse            (sync_pulse),
      .sys_rst               (sys_rst),
      .rst_rd_clk            (rst_rd_clk),
      .cq_buf_clk            (B_cq_clk),
      .cqn_buf_clk           (B_cqn_clk),
      .ddr_ck_out            (B_ddr_clk),
      .if_a_empty            (B_if_a_empty),
      .if_empty              (B_if_empty),
      .if_a_full             (),
      .if_full               (B_if_full),
      .of_a_empty            (),
      .of_empty              (B_of_empty),
      .of_a_full             (B_of_a_full),
      .of_full               (B_of_full),
      .out_fifos_full        (out_fifos_full ),    
      .phy_din               (phy_din_remap[159:80]),
      .phy_dout              (phy_dout_remap[159:80]),
      .phy_cmd_wr_en         (phy_cmd_wr_en),
      .phy_data_wr_en        (phy_data_wr_en),
      .phy_rd_en             (phy_rd_en),
      .phaser_ctl_bus        (phaser_ctl_bus),
      .idelay_ld             (idelay_ld),
      .idelay_ce             (idelay_ce[(2*12)-1:(12)*1]),
      .idelay_inc            (idelay_inc[(2*12)-1:(12)*1]),
      .idelay_cnt_in         (idelay_cnt_in[24*5-1:12*5]),
      .idelay_cnt_out        (idelay_cnt_out[24*5-1:12*5]),
      .po_edge_adv           (B_po_edge_adv),
      .po_fine_enable        (B_po_fine_enable),
      .po_coarse_enable      (B_po_coarse_enable),
      .po_fine_inc           (B_po_fine_inc),
      .po_coarse_inc         (B_po_coarse_inc),
      .po_counter_load_en    (B_po_counter_load_en),
      .po_counter_read_en    (B_po_counter_read_en),
      .po_counter_load_val   (B_po_counter_load_val),
      .po_coarse_overflow    (B_po_coarse_overflow),
      .po_fine_overflow      (B_po_fine_overflow),
      .po_counter_read_val   (B_po_counter_read_val),
      .po_sel_fine_oclk_delay(B_po_sel_fine_oclk_delay),
      .pi_edge_adv           (B_pi_edge_adv),
      .pi_fine_enable        (B_pi_fine_enable),
      .pi_fine_inc           (B_pi_fine_inc),
      .pi_counter_load_en    (B_pi_counter_load_en),
      .pi_counter_read_en    (B_pi_counter_read_en),
      .pi_counter_load_val   (B_pi_counter_load_val),
      .pi_fine_overflow      (B_pi_fine_overflow),
      .pi_counter_read_val   (B_pi_counter_read_val),
      .po_delay_done         (B_po_delay_done),
      .po_dec_done           (po_dec_done),
      .po_inc_done              (po_inc_done),
      
      .dbg_byte_lane         (B_dbg_byte_lane)
);
end
else begin : no_byte_lane_B
       assign B_of_a_full = 1'b0;
       assign B_of_full = 1'b0;
       assign B_if_full = 1'b0;
	   assign B_if_empty = 0;
       assign B_po_delay_done = 1;
       if ( HIGHEST_LANE > 1) begin
          assign O[23:12]    = 0;
       end
end

if ( BYTE_LANES[2] ) begin : qdr_rld_byte_lane_C
  assign phy_dout_remap[239:160] = part_select_80(phy_dout, (LANE_REMAP[9:8]));
  mig_7series_v2_0_qdr_rld_byte_lane#(
     .ABCD                   ("C"),
     .SIMULATION             (SIMULATION),
     .PO_COARSE_BYPASS		 (PO_COARSE_BYPASS),

     .CPT_CLK_CQ_ONLY        (CPT_CLK_CQ_ONLY),
     .PRE_FIFO               (PRE_FIFO),     
     .BITLANES_IN            (BITLANES_IN[35:24]),
     .BITLANES_OUT           (BITLANES_OUT[35:24]),
	 .CK_P_OUT               (CK_P_OUT[35:24]),
     .MEMORY_TYPE            (MEMORY_TYPE),
     .BYTE_GROUP_TYPE        (C_BYTE_GROUP_TYPE),
	 .REFCLK_FREQ            (REFCLK_FREQ),
	 .BUFG_FOR_OUTPUTS       (BUFG_FOR_OUTPUTS),
	 .CLK_PERIOD             (CLK_PERIOD),
	 .PC_CLK_RATIO           (PC_CLK_RATIO),
     .IODELAY_GRP            (IODELAY_GRP),
     .IODELAY_HP_MODE        (IODELAY_HP_MODE),
     .DATA_CTL_N             (DATA_CTL_N[2]),
     .GENERATE_DDR_CK        (GENERATE_DDR_CK[2]),
     .GENERATE_DDR_DK        (GENERATE_DDR_DK[2]),
     .DIFF_CK                (DIFF_CK),
     .DIFF_DK                (DIFF_DK),
     .CK_VALUE_D1            (CK_VALUE_D1),
     .DK_VALUE_D1            (DK_VALUE_D1),
     .PI_FREQ_REF_DIV        (C_PI_FREQ_REF_DIV),
     .PI_FINE_DELAY          (C_PI_FINE_DELAY),
     .PI_REFCLK_PERIOD       (C_PI_REFCLK_PERIOD),
     .MEMREFCLK_PERIOD       (MEMREFCLK_PERIOD),
     .PO_FINE_DELAY          (PO_FINE_DELAY),
     .PO_FINE_SKEW_DELAY     (C_PO_FINE_DELAY),
     .PO_COARSE_SKEW_DELAY   (C_PO_COARSE_DELAY),
     .PO_OCLK_DELAY          (C_PO_OCLK_DELAY),
     .PO_OCLKDELAY_INV       (C_PO_OCLKDELAY_INV),
     .PO_REFCLK_PERIOD       (C_PO_REFCLK_PERIOD),
     .PHASER_CTL_BUS_WIDTH   (PHASER_CTL_BUS_WIDTH),
     .TCQ                    (TCQ)
     )
   qdr_rld_byte_lane_C(
      .O                     ( O[35:24]),
      .I                     ( I[35:24]),
      .mem_dq_ts             ( mem_dq_ts[35:24]),
      .rst                   (rst),
      .phy_clk               (phy_clk),
	  .phy_clk_fast          (phy_clk_fast),
      .freq_refclk           (freq_refclk),
      .mem_refclk            (mem_refclk),
      .sync_pulse            (sync_pulse),
      .sys_rst               (sys_rst),
      .rst_rd_clk            (rst_rd_clk),
      .cq_buf_clk            (C_cq_clk), 
      .cqn_buf_clk           (C_cqn_clk),
      .ddr_ck_out            (C_ddr_clk),
      .if_a_empty            (C_if_a_empty),
      .if_empty              (C_if_empty),
      .if_a_full             (),
      .if_full               (C_if_full),
      .of_a_empty            (),
      .of_empty              (C_of_empty),
      .of_a_full             (C_of_a_full),
      .of_full               (C_of_full),
      .out_fifos_full        (out_fifos_full ),    
      .phy_din               (phy_din_remap[239:160]),
      .phy_dout              (phy_dout_remap[239:160]),
      .phy_cmd_wr_en         (phy_cmd_wr_en),
      .phy_data_wr_en        (phy_data_wr_en),
      .phy_rd_en             (phy_rd_en),
       .phaser_ctl_bus       (phaser_ctl_bus),
      .idelay_ld             (idelay_ld),
      .idelay_ce             (idelay_ce[(3*12)-1:(12)*2]),
      .idelay_inc            (idelay_inc[(3*12)-1:(12)*2]),
      .idelay_cnt_in         (idelay_cnt_in[36*5-1:24*5]),
      .idelay_cnt_out        (idelay_cnt_out[36*5-1:24*5]),
      .po_edge_adv           (C_po_edge_adv),
      .po_fine_enable        (C_po_fine_enable),
      .po_coarse_enable      (C_po_coarse_enable),
      .po_fine_inc           (C_po_fine_inc),
      .po_coarse_inc         (C_po_coarse_inc),
      .po_counter_load_en    (C_po_counter_load_en),
      .po_counter_read_en    (C_po_counter_read_en),
      .po_counter_load_val   (C_po_counter_load_val),
      .po_coarse_overflow    (C_po_coarse_overflow),
      .po_fine_overflow      (C_po_fine_overflow),
      .po_counter_read_val   (C_po_counter_read_val),
      .po_sel_fine_oclk_delay(C_po_sel_fine_oclk_delay),
      .pi_edge_adv           (C_pi_edge_adv),
      .pi_fine_enable        (C_pi_fine_enable),
      .pi_fine_inc           (C_pi_fine_inc),
      .pi_counter_load_en    (C_pi_counter_load_en),
      .pi_counter_read_en    (C_pi_counter_read_en),
      .pi_counter_load_val   (C_pi_counter_load_val),
      .pi_fine_overflow      (C_pi_fine_overflow),
      .pi_counter_read_val   (C_pi_counter_read_val),
      .po_delay_done         (C_po_delay_done),
      .po_dec_done           (po_dec_done),
      .po_inc_done              (po_inc_done),
      
      .dbg_byte_lane         (C_dbg_byte_lane)
);

end
else begin : no_byte_lane_C
       assign C_of_a_full = 1'b0;
       assign C_of_full = 1'b0;
       assign C_if_full = 1'b0;
	   assign C_if_empty = 0;
       assign C_po_delay_done = 1;
       if ( HIGHEST_LANE > 2) begin
          assign O[35:24]    = 0;
       end
end

if ( BYTE_LANES[3] ) begin : qdr_rld_byte_lane_D
  assign phy_dout_remap[319:240] = part_select_80(phy_dout, (LANE_REMAP[13:12]));

  mig_7series_v2_0_qdr_rld_byte_lane#(
     .ABCD                   ("D"),
     .SIMULATION             (SIMULATION),
     .PO_COARSE_BYPASS		 (PO_COARSE_BYPASS),

     .CPT_CLK_CQ_ONLY        (CPT_CLK_CQ_ONLY),
     .PRE_FIFO               (PRE_FIFO),     
     .BITLANES_IN            (BITLANES_IN[47:36]),
     .BITLANES_OUT           (BITLANES_OUT[47:36]),
	 .CK_P_OUT               (CK_P_OUT[47:36]),
     .MEMORY_TYPE            (MEMORY_TYPE),
     .BYTE_GROUP_TYPE        (D_BYTE_GROUP_TYPE),
	 .REFCLK_FREQ            (REFCLK_FREQ),
	 .BUFG_FOR_OUTPUTS       (BUFG_FOR_OUTPUTS),
	 .CLK_PERIOD             (CLK_PERIOD),
	 .PC_CLK_RATIO           (PC_CLK_RATIO),
     .IODELAY_GRP            (IODELAY_GRP),
     .IODELAY_HP_MODE        (IODELAY_HP_MODE),
     .DATA_CTL_N             (DATA_CTL_N[3]),
     .GENERATE_DDR_CK        (GENERATE_DDR_CK[3]),
     .GENERATE_DDR_DK        (GENERATE_DDR_DK[3]),
     .DIFF_CK                (DIFF_CK),
     .DIFF_DK                (DIFF_DK),
     .CK_VALUE_D1            (CK_VALUE_D1),
     .DK_VALUE_D1            (DK_VALUE_D1),
     .PI_FREQ_REF_DIV        (D_PI_FREQ_REF_DIV),
     .PI_FINE_DELAY          (D_PI_FINE_DELAY),
     .PI_REFCLK_PERIOD       (D_PI_REFCLK_PERIOD),
     .MEMREFCLK_PERIOD       (MEMREFCLK_PERIOD),
     .PO_FINE_DELAY          (PO_FINE_DELAY),
     .PO_FINE_SKEW_DELAY     (D_PO_FINE_DELAY),
     .PO_COARSE_SKEW_DELAY   (D_PO_COARSE_DELAY),
     .PO_OCLK_DELAY          (D_PO_OCLK_DELAY),
     .PO_OCLKDELAY_INV       (D_PO_OCLKDELAY_INV),
     .PO_REFCLK_PERIOD       (D_PO_REFCLK_PERIOD),
     .PHASER_CTL_BUS_WIDTH   (PHASER_CTL_BUS_WIDTH),
     .TCQ                    (TCQ)
     )
   qdr_rld_byte_lane_D(
      .O                     ( O[47:36]),
      .I                     ( I[47:36]),
      .mem_dq_ts             ( mem_dq_ts[47:36]),
      .rst                   (rst),
      .phy_clk               (phy_clk),
	  .phy_clk_fast          (phy_clk_fast),
      .freq_refclk           (freq_refclk),
      .mem_refclk            (mem_refclk),
      .sync_pulse            (sync_pulse),
      .sys_rst               (sys_rst),
      .rst_rd_clk            (rst_rd_clk),
      .cq_buf_clk            (D_cq_clk), 
      .cqn_buf_clk           (D_cqn_clk),
      .ddr_ck_out            (D_ddr_clk),
      .if_a_empty            (D_if_a_empty),
      .if_empty              (D_if_empty),
      .if_a_full             (),
      .if_full               (D_if_full),
      .of_a_empty            (),
      .of_empty              (D_of_empty),
      .of_a_full             (D_of_a_full),
      .of_full               (D_of_full),
      .out_fifos_full        (out_fifos_full),    
      .phy_din               (phy_din_remap[319:240]),
      .phy_dout              (phy_dout_remap[319:240]),
      .phy_cmd_wr_en         (phy_cmd_wr_en),
      .phy_data_wr_en        (phy_data_wr_en),
      .phy_rd_en             (phy_rd_en),
       .phaser_ctl_bus       (phaser_ctl_bus),
      .idelay_ld             (idelay_ld),
      .idelay_ce             (idelay_ce[(4*12)-1:(12)*3]),
      .idelay_inc            (idelay_inc[(4*12)-1:(12)*3]),
      .idelay_cnt_in         (idelay_cnt_in[48*5-1:36*5]),
      .idelay_cnt_out        (idelay_cnt_out[48*5-1:36*5]),
      .po_edge_adv           (D_po_edge_adv),
      .po_fine_enable        (D_po_fine_enable),
      .po_coarse_enable      (D_po_coarse_enable),
      .po_fine_inc           (D_po_fine_inc),
      .po_coarse_inc         (D_po_coarse_inc),
      .po_counter_load_en    (D_po_counter_load_en),
      .po_counter_read_en    (D_po_counter_read_en),
      .po_counter_load_val   (D_po_counter_load_val),
      .po_coarse_overflow    (D_po_coarse_overflow),
      .po_fine_overflow      (D_po_fine_overflow),
      .po_counter_read_val   (D_po_counter_read_val),
      .po_sel_fine_oclk_delay(D_po_sel_fine_oclk_delay),
      .pi_edge_adv           (D_pi_edge_adv),
      .pi_fine_enable        (D_pi_fine_enable),
      .pi_fine_inc           (D_pi_fine_inc),
      .pi_counter_load_en    (D_pi_counter_load_en),
      .pi_counter_read_en    (D_pi_counter_read_en),
      .pi_counter_load_val   (D_pi_counter_load_val),
      .pi_fine_overflow      (D_pi_fine_overflow),
      .pi_counter_read_val   (D_pi_counter_read_val),
      .po_delay_done         (D_po_delay_done),
      .po_dec_done           (po_dec_done),
      .po_inc_done              (po_inc_done),
      
      .dbg_byte_lane         (D_dbg_byte_lane)
);
end
else begin : no_byte_lane_D
       assign D_of_a_full = 1'b0;
       assign D_of_full = 1'b0;
       assign D_if_full = 1'b0;
	   assign D_if_empty = 0;
       assign D_po_delay_done = 1;
       if ( HIGHEST_LANE > 3) begin
           assign O[47:36]    = 0;
       end
end
endgenerate


// register outputs to give extra slack in timing
always @(posedge phy_clk) begin
    case (calib_sel[1:0])
    2'h0: begin
       po_coarse_overflow  <= #1 A_po_coarse_overflow;
       po_fine_overflow    <= #1 A_po_fine_overflow;
       po_counter_read_val <= #1 A_po_counter_read_val;

       pi_fine_overflow    <= #1 A_pi_fine_overflow;
       pi_counter_read_val <= #1 A_pi_counter_read_val;
      end

    2'h1: begin
       po_coarse_overflow  <= #1 B_po_coarse_overflow;
       po_fine_overflow    <= #1 B_po_fine_overflow;
       po_counter_read_val <= #1 B_po_counter_read_val;

       pi_fine_overflow    <= #1 B_pi_fine_overflow;
       pi_counter_read_val <= #1 B_pi_counter_read_val;
      end

    2'h2: begin
       po_coarse_overflow  <= #1 C_po_coarse_overflow;
       po_fine_overflow    <= #1 C_po_fine_overflow;
       po_counter_read_val <= #1 C_po_counter_read_val;

       pi_fine_overflow    <= #1 C_pi_fine_overflow;
       pi_counter_read_val <= #1 C_pi_counter_read_val;
      end

    2'h3: begin
       po_coarse_overflow  <= #1 D_po_coarse_overflow;
       po_fine_overflow    <= #1 D_po_fine_overflow;
       po_counter_read_val <= #1 D_po_counter_read_val;

       pi_fine_overflow    <= #1 D_pi_fine_overflow;
       pi_counter_read_val <= #1 D_pi_counter_read_val;
      end
    default: begin
       po_coarse_overflow  <= #1 A_po_coarse_overflow;
       po_fine_overflow    <= #1 A_po_fine_overflow;
       po_counter_read_val <= #1 A_po_counter_read_val;

       pi_fine_overflow    <= #1 A_pi_fine_overflow;
       pi_counter_read_val <= #1 A_pi_counter_read_val;
      end
    endcase
end

always @(posedge phy_clk) begin
    if ( calib_sel[2]) begin
        A_pi_fine_enable          <= #TCQ 0;
        A_pi_edge_adv             <= #TCQ 0;
        A_pi_fine_inc             <= #TCQ 0;
        A_pi_counter_load_en      <= #TCQ 0;
        A_pi_counter_read_en      <= #TCQ 0;
        A_pi_counter_load_val     <= #TCQ 0;

        A_po_fine_enable          <= #TCQ 0;
        A_po_edge_adv             <= #TCQ 0;
        A_po_coarse_enable        <= #TCQ 0;
        A_po_fine_inc             <= #TCQ 0;
        A_po_coarse_inc           <= #TCQ 0;
        A_po_counter_load_en      <= #TCQ 0;
        A_po_counter_read_en      <= #TCQ 0;
        A_po_counter_load_val     <= #TCQ 0;   
        A_po_sel_fine_oclk_delay  <= #TCQ 0;
                                  
        B_pi_fine_enable          <= #TCQ 0;
        B_pi_edge_adv             <= #TCQ 0;
        B_pi_fine_inc             <= #TCQ 0;
        B_pi_counter_load_en      <= #TCQ 0;
        B_pi_counter_read_en      <= #TCQ 0;
        B_pi_counter_load_val     <= #TCQ 0;
                                  
        B_po_fine_enable          <= #TCQ 0;
        B_po_edge_adv             <= #TCQ 0;
        B_po_coarse_enable        <= #TCQ 0;
        B_po_fine_inc             <= #TCQ 0;
        B_po_coarse_inc           <= #TCQ 0;
        B_po_counter_load_en      <= #TCQ 0;
        B_po_counter_read_en      <= #TCQ 0;
        B_po_counter_load_val     <= #TCQ 0;
        B_po_sel_fine_oclk_delay  <= #TCQ 0;

        C_pi_fine_enable          <= #TCQ  0;
        C_pi_edge_adv             <= #TCQ  0;
        C_pi_fine_inc             <= #TCQ  0;
        C_pi_counter_load_en      <= #TCQ  0;
        C_pi_counter_read_en      <= #TCQ  0;
        C_pi_counter_load_val     <= #TCQ  0;

        C_po_fine_enable          <= #TCQ  0;
        C_po_edge_adv             <= #TCQ  0;
        C_po_coarse_enable        <= #TCQ  0;
        C_po_fine_inc             <= #TCQ  0;
        C_po_coarse_inc           <= #TCQ  0;
        C_po_counter_load_en      <= #TCQ  0;
        C_po_counter_read_en      <= #TCQ  0;
        C_po_counter_load_val     <= #TCQ  0;
        C_po_sel_fine_oclk_delay  <= #TCQ  0;
                                   
        D_pi_fine_enable          <= #TCQ  0;  
        D_pi_edge_adv             <= #TCQ  0;  
        D_pi_fine_inc             <= #TCQ  0;
        D_pi_counter_load_en      <= #TCQ  0;
        D_pi_counter_read_en      <= #TCQ  0;
        D_pi_counter_load_val     <= #TCQ  0;

        D_po_fine_enable          <= #TCQ  0;
        D_po_edge_adv             <= #TCQ  0;
        D_po_coarse_enable        <= #TCQ  0;
        D_po_fine_inc             <= #TCQ  0;
        D_po_coarse_inc           <= #TCQ  0;
        D_po_counter_load_en      <= #TCQ  0;
        D_po_counter_read_en      <= #TCQ  0;
        D_po_counter_load_val     <= #TCQ  0;
        D_po_sel_fine_oclk_delay  <= #TCQ  0;
                                  
    end else                      
    if (calib_in_common) begin    

      if (drive_on_calib_in_common[0] == 1) begin

        A_pi_fine_enable          <= #TCQ   pi_fine_enable;
        A_pi_edge_adv             <= #TCQ   pi_edge_adv;
        A_pi_fine_inc             <= #TCQ   pi_fine_inc;
        A_pi_counter_load_en      <= #TCQ   pi_counter_load_en;
        A_pi_counter_read_en      <= #TCQ   pi_counter_read_en;
        A_pi_counter_load_val     <= #TCQ   pi_counter_load_val;

        A_po_fine_enable          <= #TCQ   po_fine_enable;
        A_po_edge_adv             <= #TCQ   po_edge_adv;
        A_po_coarse_enable        <= #TCQ   po_coarse_enable;
        A_po_fine_inc             <= #TCQ   po_fine_inc;
        A_po_coarse_inc           <= #TCQ   po_coarse_inc;
        A_po_counter_load_en      <= #TCQ   po_counter_load_en;
        A_po_counter_read_en      <= #TCQ   po_counter_read_en;
        A_po_counter_load_val     <= #TCQ   po_counter_load_val;
        A_po_sel_fine_oclk_delay  <= #TCQ   po_sel_fine_oclk_delay;

      end

      if (drive_on_calib_in_common[1] == 1) begin

        B_pi_fine_enable          <= #TCQ   pi_fine_enable;
        B_pi_edge_adv             <= #TCQ   pi_edge_adv;
        B_pi_fine_inc             <= #TCQ   pi_fine_inc;
        B_pi_counter_load_en      <= #TCQ   pi_counter_load_en;
        B_pi_counter_read_en      <= #TCQ   pi_counter_read_en;
        B_pi_counter_load_val     <= #TCQ   pi_counter_load_val;

        B_po_fine_enable          <= #TCQ   po_fine_enable;
        B_po_edge_adv             <= #TCQ   po_edge_adv;
        B_po_coarse_enable        <= #TCQ   po_coarse_enable;
        B_po_fine_inc             <= #TCQ   po_fine_inc;
        B_po_coarse_inc           <= #TCQ   po_coarse_inc;
        B_po_counter_load_en      <= #TCQ   po_counter_load_en;
        B_po_counter_read_en      <= #TCQ   po_counter_read_en;
        B_po_counter_load_val     <= #TCQ   po_counter_load_val;
        B_po_sel_fine_oclk_delay  <= #TCQ   po_sel_fine_oclk_delay;

      end

      if (drive_on_calib_in_common[2] == 1) begin

        C_pi_fine_enable          <= #TCQ   pi_fine_enable;
        C_pi_edge_adv             <= #TCQ   pi_edge_adv;
        C_pi_fine_inc             <= #TCQ   pi_fine_inc;
        C_pi_counter_load_en      <= #TCQ   pi_counter_load_en;
        C_pi_counter_read_en      <= #TCQ   pi_counter_read_en;
        C_pi_counter_load_val     <= #TCQ   pi_counter_load_val;

        C_po_fine_enable          <= #TCQ   po_fine_enable;
        C_po_edge_adv             <= #TCQ   po_edge_adv;
        C_po_coarse_enable        <= #TCQ   po_coarse_enable;
        C_po_fine_inc             <= #TCQ   po_fine_inc;
        C_po_coarse_inc           <= #TCQ   po_coarse_inc;
        C_po_counter_load_en      <= #TCQ   po_counter_load_en;
        C_po_counter_read_en      <= #TCQ   po_counter_read_en;
        C_po_counter_load_val     <= #TCQ   po_counter_load_val;
        C_po_sel_fine_oclk_delay  <= #TCQ   po_sel_fine_oclk_delay;

      end

      if (drive_on_calib_in_common[3] == 1) begin

        D_pi_fine_enable          <= #TCQ   pi_fine_enable;
        D_pi_edge_adv             <= #TCQ   pi_edge_adv;
        D_pi_fine_inc             <= #TCQ   pi_fine_inc;
        D_pi_counter_load_en      <= #TCQ   pi_counter_load_en;
        D_pi_counter_read_en      <= #TCQ   pi_counter_read_en;
        D_pi_counter_load_val     <= #TCQ   pi_counter_load_val;


        D_po_fine_enable          <= #TCQ   po_fine_enable;
        D_po_edge_adv             <= #TCQ   po_edge_adv;
        D_po_coarse_enable        <= #TCQ   po_coarse_enable;
        D_po_fine_inc             <= #TCQ   po_fine_inc;
        D_po_coarse_inc           <= #TCQ   po_coarse_inc;
        D_po_counter_load_en      <= #TCQ   po_counter_load_en;
        D_po_counter_read_en      <= #TCQ   po_counter_read_en;
        D_po_counter_load_val     <= #TCQ   po_counter_load_val;
        D_po_sel_fine_oclk_delay  <= #TCQ   po_sel_fine_oclk_delay;

      end

    end
    else begin
    // otherwise, only a single phaser is selected
        A_pi_fine_enable          <= #TCQ  0;
        A_pi_edge_adv             <= #TCQ  0;
        A_pi_fine_inc             <= #TCQ  0;
        A_pi_counter_load_en      <= #TCQ  0;
        A_pi_counter_read_en      <= #TCQ  0;
        A_pi_counter_load_val     <= #TCQ  0;

        A_po_fine_enable          <= #TCQ  0;
        A_po_edge_adv             <= #TCQ  0;
        A_po_coarse_enable        <= #TCQ  0;
        A_po_fine_inc             <= #TCQ  0;
        A_po_coarse_inc           <= #TCQ  0;
        A_po_counter_load_en      <= #TCQ  0;
        A_po_counter_read_en      <= #TCQ  0;
        A_po_counter_load_val     <= #TCQ  0;
        A_po_sel_fine_oclk_delay  <= #TCQ  0;

        B_pi_fine_enable          <= #TCQ  0;
        B_pi_edge_adv             <= #TCQ  0;
        B_pi_fine_inc             <= #TCQ  0;
        B_pi_counter_load_en      <= #TCQ  0;
        B_pi_counter_read_en      <= #TCQ  0;
        B_pi_counter_load_val     <= #TCQ  0;

        B_po_fine_enable          <= #TCQ  0;
        B_po_edge_adv             <= #TCQ  0;
        B_po_coarse_enable        <= #TCQ  0;
        B_po_fine_inc             <= #TCQ  0;
        B_po_coarse_inc           <= #TCQ  0;
        B_po_counter_load_en      <= #TCQ  0;
        B_po_counter_read_en      <= #TCQ  0;
        B_po_counter_load_val     <= #TCQ  0;
        B_po_sel_fine_oclk_delay  <= #TCQ  0;
                                   
        C_pi_fine_enable          <= #TCQ  0;
        C_pi_edge_adv             <= #TCQ  0;
        C_pi_fine_inc             <= #TCQ  0;
        C_pi_counter_load_en      <= #TCQ  0;
        C_pi_counter_read_en      <= #TCQ  0;
        C_pi_counter_load_val     <= #TCQ  0;

        C_po_fine_enable          <= #TCQ  0;
        C_po_edge_adv             <= #TCQ  0;
        C_po_coarse_enable        <= #TCQ  0;
        C_po_fine_inc             <= #TCQ  0;
        C_po_coarse_inc           <= #TCQ  0;
        C_po_counter_load_en      <= #TCQ  0;
        C_po_counter_read_en      <= #TCQ  0;
        C_po_counter_load_val     <= #TCQ  0;
        C_po_sel_fine_oclk_delay  <= #TCQ  0;

        D_pi_fine_enable          <= #TCQ  0;
        D_pi_edge_adv             <= #TCQ  0;
        D_pi_fine_inc             <= #TCQ  0;
        D_pi_counter_load_en      <= #TCQ  0;
        D_pi_counter_read_en      <= #TCQ  0;
        D_pi_counter_load_val     <= #TCQ  0;

        D_po_fine_enable          <= #TCQ  0;
        D_po_edge_adv             <= #TCQ  0;
        D_po_coarse_enable        <= #TCQ  0;
        D_po_fine_inc             <= #TCQ  0;
        D_po_coarse_inc           <= #TCQ  0;
        D_po_counter_load_en      <= #TCQ  0;
        D_po_counter_read_en      <= #TCQ  0;
        D_po_counter_load_val     <= #TCQ  0;
        D_po_sel_fine_oclk_delay  <= #TCQ  0;

    case (calib_sel[1:0])
    0:  begin
        A_pi_fine_enable          <= #TCQ pi_fine_enable;
        A_pi_edge_adv             <= #TCQ pi_edge_adv;
        A_pi_fine_inc             <= #TCQ pi_fine_inc;
        A_pi_counter_load_en      <= #TCQ pi_counter_load_en;
        A_pi_counter_read_en      <= #TCQ pi_counter_read_en;
        A_pi_counter_load_val     <= #TCQ pi_counter_load_val;

        A_po_fine_enable          <= #TCQ po_fine_enable;
        A_po_edge_adv             <= #TCQ po_edge_adv;
        A_po_coarse_enable        <= #TCQ po_coarse_enable;
        A_po_fine_inc             <= #TCQ po_fine_inc;
        A_po_coarse_inc           <= #TCQ po_coarse_inc;
        A_po_counter_load_en      <= #TCQ po_counter_load_en;
        A_po_counter_read_en      <= #TCQ po_counter_read_en;
        A_po_counter_load_val     <= #TCQ po_counter_load_val;
		A_po_sel_fine_oclk_delay  <= #TCQ po_sel_fine_oclk_delay;
     end
    1: begin
        B_pi_fine_enable          <= #TCQ pi_fine_enable;
        B_pi_edge_adv             <= #TCQ pi_edge_adv;
        B_pi_fine_inc             <= #TCQ pi_fine_inc;
        B_pi_counter_load_en      <= #TCQ pi_counter_load_en;
        B_pi_counter_read_en      <= #TCQ pi_counter_read_en;
        B_pi_counter_load_val     <= #TCQ pi_counter_load_val;

        B_po_fine_enable          <= #TCQ po_fine_enable;
        B_po_edge_adv             <= #TCQ po_edge_adv;
        B_po_coarse_enable        <= #TCQ po_coarse_enable;
        B_po_fine_inc             <= #TCQ po_fine_inc;
        B_po_coarse_inc           <= #TCQ po_coarse_inc;
        B_po_counter_load_en      <= #TCQ po_counter_load_en;
        B_po_counter_read_en      <= #TCQ po_counter_read_en;
        B_po_counter_load_val     <= #TCQ po_counter_load_val;
		B_po_sel_fine_oclk_delay  <= #TCQ po_sel_fine_oclk_delay;
     end

    2: begin
        C_pi_fine_enable          <= #TCQ pi_fine_enable;
        C_pi_edge_adv             <= #TCQ pi_edge_adv;
        C_pi_fine_inc             <= #TCQ pi_fine_inc;
        C_pi_counter_load_en      <= #TCQ pi_counter_load_en;
        C_pi_counter_read_en      <= #TCQ pi_counter_read_en;
        C_pi_counter_load_val     <= #TCQ pi_counter_load_val;

        C_po_fine_enable          <= #TCQ po_fine_enable;
        C_po_edge_adv             <= #TCQ po_edge_adv;
        C_po_coarse_enable        <= #TCQ po_coarse_enable;
        C_po_fine_inc             <= #TCQ po_fine_inc;
        C_po_coarse_inc           <= #TCQ po_coarse_inc;
        C_po_counter_load_en      <= #TCQ po_counter_load_en;
        C_po_counter_read_en      <= #TCQ po_counter_read_en;
        C_po_counter_load_val     <= #TCQ po_counter_load_val;
		C_po_sel_fine_oclk_delay  <= #TCQ po_sel_fine_oclk_delay;
     end

    3: begin
        D_pi_fine_enable          <= #TCQ pi_fine_enable;
        D_pi_edge_adv             <= #TCQ pi_edge_adv;
        D_pi_fine_inc             <= #TCQ pi_fine_inc;
        D_pi_counter_load_en      <= #TCQ pi_counter_load_en;
        D_pi_counter_read_en      <= #TCQ pi_counter_read_en;
        D_pi_counter_load_val     <= #TCQ pi_counter_load_val;

        D_po_fine_enable          <= #TCQ po_fine_enable;
        D_po_edge_adv             <= #TCQ po_edge_adv;
        D_po_coarse_enable        <= #TCQ po_coarse_enable;
        D_po_fine_inc             <= #TCQ po_fine_inc;
        D_po_coarse_inc           <= #TCQ po_coarse_inc;
        D_po_counter_load_en      <= #TCQ po_counter_load_en;
        D_po_counter_read_en      <= #TCQ po_counter_read_en;
        D_po_counter_load_val     <= #TCQ po_counter_load_val;
		D_po_sel_fine_oclk_delay  <= #TCQ po_sel_fine_oclk_delay;

     end
    endcase
    end
end

//For QDR2+ since there is only one clock we use both BUFMR locations
//Hence, even if we only specify one location we generate both in that case
generate
genvar i;
  if (DIFF_CQ == 1) begin: gen_ibufds_cq //Differential Read Clock
    assign cqn_buf_clk = 'b0; //tie-off unused signal
	
    if (MEMORY_TYPE == "RLD3") begin : gen_ibufds_cq_rld3
	  for (i = 0; i < 4; i = i + 1) begin
	    if (GENERATE_CQ[i]==1) begin
          IBUFDS  u_bufds_cq ( .I  (Q_clk[i]),
                               .IB (Qn_clk[i]),
	                           .O  (cq_clk[i]) //cq_buf_clk[i]
	                         );
		
          assign cqn_clk[i] = ~cq_clk[i];
      
        end //end of if
	  end //end of for
	
	end else begin
	  //BUFMR instances
      if (GENERATE_CQ[1]==1) begin
        IBUFDS  bufds_cq_1 ( .I  (Q_clk[1]),
                             .IB (Qn_clk[1]),
	                         .O  (cq_buf_clk[0])
	                       );
	    
        BUFMR   bufmr_cq_1 ( .O(cq_clk[0]), .I(cq_buf_clk[0]) );
		
        assign cqn_clk[0] = ~cq_clk[0];
      
      end //end of if
    
      if (GENERATE_CQ[2]==1) begin
    
        IBUFDS  bufds_cq_2 ( .I  (Q_clk[2]),
                             .IB (Qn_clk[2]),
	                         .O  (cq_buf_clk[1])
	                        );
	                     
	    BUFMR   bufmr_cq_2 ( .O(cq_clk[1]), .I(cq_buf_clk[1]) );
	   
        assign cqn_clk[1] = ~cq_clk[1];
      
      end //end of if
	end
  
  end else begin: gen_ibuf_cq //QDR2+ case, use both locations all the time
    //work around for current QDR2+ parameters
    //ideally since we have 4 byte lanes we want the parameters to specify
    //where the clocks should go, but QDR2+ parameters handle it differently
    // When changed, fix this to [1] & {2] as expected
    if (GENERATE_CQ[0]==1 || GENERATE_CQ[1]==1 || 
        GENERATE_CQ[2]==1 || GENERATE_CQ[3]==1 ) begin
    
      //tie-off unused signals
      assign cq_clk[1]  = 1'b0;
      assign cqn_clk[1] = 1'b0;
      
      // it is legal to have the cq in either bytelane 1 or 2 for QDR.
      
      if (GENERATE_CQ[1] == 1) begin
          assign cq_capt_clk = Q_clk[1];
          assign cqn_capt_clk = Qn_clk[1];
          
      end else if (GENERATE_CQ[2] == 1) begin
          assign cq_capt_clk = Q_clk[2];
          assign cqn_capt_clk = Qn_clk[2];
          
      end
          
      
      IBUF buf_cq  (.O (cq_buf_clk[0]),  .I (cq_capt_clk) );
      IBUF buf_cqn (.O (cqn_buf_clk[0]), .I (cqn_capt_clk) );
        
      BUFMR bufmr_cq  (.O (cq_clk[0]),  .I (cq_buf_clk[0]) );
      BUFMR bufmr_cqn (.O (cqn_clk[0]), .I (cqn_buf_clk[0]));
      
            
    end else begin
      assign cq_buf_clk = 'b0;
      assign cqn_buf_clk= 'b0;
      assign cq_clk     = 'b0;
      assign cqn_clk    = 'b0;
    end
  end //end gen_ibuf_cq
endgenerate

assign #(BUFMR_DELAY) cpt_clk[0]   = cq_clk[0];
assign #(BUFMR_DELAY) cpt_clk[1]   = cq_clk[1];
assign #(BUFMR_DELAY) cpt_clk_n[0] = cqn_clk[0];
assign #(BUFMR_DELAY) cpt_clk_n[1] = cqn_clk[1];

//assign all of the read clocks to the different phy lanes (RLDRAM only)
generate
  if (DIFF_CQ == 1) begin: gen_cpt_assignments
  
    if (MEMORY_TYPE == "RLD3") begin
	  //One clock per byte lane, no BUFMR so no extra delay needs to be inserted
	  //for simulation
	  always @(*) begin
	    A_cq_clk  <= cq_clk[0];
		B_cq_clk  <= cq_clk[1];
		C_cq_clk  <= cq_clk[2];
		D_cq_clk  <= cq_clk[3];
		
		//N-side not used
        A_cqn_clk <= 1'b0;
        B_cqn_clk <= 1'b0; 
        C_cqn_clk <= 1'b0;
        D_cqn_clk <= 1'b0; 
	  end
	  
	end else begin
  
      always @(*) begin
    
        //A byte lane
        if (CPT_CLK_SEL[7:0]==8'h11)
          A_cq_clk       <= cpt_clk[0];
        else if (CPT_CLK_SEL[7:0]==8'h12)
          A_cq_clk       <= cpt_clk[1];
        else if (CPT_CLK_SEL[7:0]==8'h01) //from Bank below
          A_cq_clk       <= cpt_clk_below[0];
        else if (CPT_CLK_SEL[7:0]==8'h02) //from Bank below
          A_cq_clk       <= cpt_clk_below[1];
        else if (CPT_CLK_SEL[7:0]==8'h21) //from Bank above
          A_cq_clk       <= cpt_clk_above[0];
        else if (CPT_CLK_SEL[7:0]==8'h22) //from Bank above
          A_cq_clk       <= cpt_clk_above[1];
        else
          A_cq_clk       <= cpt_clk[0]; //default
      
        //B byte lane
        if (CPT_CLK_SEL[15:8]==8'h11)
          B_cq_clk       <= cpt_clk[0];
        else if (CPT_CLK_SEL[15:8]==8'h12)
          B_cq_clk       <= cpt_clk[1];
        else if (CPT_CLK_SEL[15:8]==8'h01) //from Bank below
          B_cq_clk       <= cpt_clk_below[0];
        else if (CPT_CLK_SEL[15:8]==8'h02) //from Bank below
          B_cq_clk       <= cpt_clk_below[1];
        else if (CPT_CLK_SEL[15:8]==8'h21) //from Bank above
          B_cq_clk       <= cpt_clk_above[0];
        else if (CPT_CLK_SEL[15:8]==8'h22) //from Bank above
          B_cq_clk       <= cpt_clk_above[1];
        else
          B_cq_clk       <= cpt_clk[0]; //default
        
        //C byte lane
        if (CPT_CLK_SEL[23:16]==8'h11)
          C_cq_clk       <= cpt_clk[0];
        else if (CPT_CLK_SEL[23:16]==8'h12)
          C_cq_clk       <= cpt_clk[1];
        else if (CPT_CLK_SEL[23:16]==8'h01) //from Bank below
          C_cq_clk       <= cpt_clk_below[0];
        else if (CPT_CLK_SEL[23:16]==8'h02) //from Bank below
          C_cq_clk       <= cpt_clk_below[1];
        else if (CPT_CLK_SEL[23:16]==8'h21) //from Bank above
          C_cq_clk       <= cpt_clk_above[0];
        else if (CPT_CLK_SEL[23:16]==8'h22) //from Bank above
          C_cq_clk       <= cpt_clk_above[1];
        else
          C_cq_clk       <= cpt_clk[0]; //default
        
        //D byte lane
        if (CPT_CLK_SEL[31:24]==8'h11)
          D_cq_clk       <= cpt_clk[0];
        else if (CPT_CLK_SEL[31:24]==8'h12)
          D_cq_clk       <= cpt_clk[1];
        else if (CPT_CLK_SEL[31:24]==8'h01) //from Bank below
          D_cq_clk       <= cpt_clk_below[0];
        else if (CPT_CLK_SEL[31:24]==8'h02) //from Bank below
          D_cq_clk       <= cpt_clk_below[1];
        else if (CPT_CLK_SEL[31:24]==8'h21) //from Bank above
          D_cq_clk       <= cpt_clk_above[0];
        else if (CPT_CLK_SEL[31:24]==8'h22) //from Bank above
          D_cq_clk       <= cpt_clk_above[1];
        else
          D_cq_clk       <= cpt_clk[0]; //default
      
        //n-side of signal not used, tie to 0
        A_cqn_clk       <= #(BUFMR_DELAY) 1'b0;
        B_cqn_clk       <= #(BUFMR_DELAY) 1'b0; 
        C_cqn_clk       <= #(BUFMR_DELAY) 1'b0;
        D_cqn_clk       <= #(BUFMR_DELAY) 1'b0; 
      end //always @ (*)
    end
  end else begin : gen_qdr_assignments
  
    always @(*) begin
    
      //A byte lane
      if (CPT_CLK_SEL[7:4]== 4'h1) begin
        A_cq_clk        =  cpt_clk[0];
        A_cqn_clk       =  cpt_clk_n[0];
      end else if (CPT_CLK_SEL[7:4]==4'h0) begin//from Bank below
        A_cq_clk       =  cpt_clk_below[0];
        A_cqn_clk      =  cpt_clk_n_below[0];
      end else if (CPT_CLK_SEL[7:4]==4'h2) begin //from Bank above
        A_cq_clk       =  cpt_clk_above[0];
        A_cqn_clk      =  cpt_clk_n_above[0];
      end else begin //default case
        A_cq_clk       =  cpt_clk[0];
        A_cqn_clk      =  cpt_clk_n[0];
      end
      
      //B byte lane
      if (CPT_CLK_SEL[15:12]== 4'h1) begin
        B_cq_clk        = cpt_clk[0];
        B_cqn_clk       = cpt_clk_n[0];
      end else if (CPT_CLK_SEL[15:12]==4'h0) begin//from Bank below
        B_cq_clk       = cpt_clk_below[0];
        B_cqn_clk      = cpt_clk_n_below[0];
      end else if (CPT_CLK_SEL[15:12]==4'h2) begin //from Bank above
        B_cq_clk       = cpt_clk_above[0];
        B_cqn_clk      = cpt_clk_n_above[0];
      end else begin //default case
        B_cq_clk       = cpt_clk[0];
        B_cqn_clk      = cpt_clk_n[0];
      end
              
      //C byte lane
      if (CPT_CLK_SEL[23:20]== 4'h1) begin
        C_cq_clk        = cpt_clk[0];
        C_cqn_clk       = cpt_clk_n[0];
      end else if (CPT_CLK_SEL[23:20]==4'h0) begin//from Bank below
        C_cq_clk       = cpt_clk_below[0];
        C_cqn_clk      = cpt_clk_n_below[0];
      end else if (CPT_CLK_SEL[23:20]==4'h2) begin //from Bank above
        C_cq_clk       = cpt_clk_above[0];
        C_cqn_clk      = cpt_clk_n_above[0];
      end else begin //default case
        C_cq_clk       = cpt_clk[0];
        C_cqn_clk      = cpt_clk_n[0];
      end
             
      //D byte lane
      if (CPT_CLK_SEL[31:28]== 4'h1) begin
        D_cq_clk        = cpt_clk[0];
        D_cqn_clk       = cpt_clk_n[0];
      end else if (CPT_CLK_SEL[31:28]==4'h0) begin//from Bank below
        D_cq_clk       = cpt_clk_below[0];
        D_cqn_clk      = cpt_clk_n_below[0];
      end else if (CPT_CLK_SEL[31:28]==4'h2) begin //from Bank above
        D_cq_clk       = cpt_clk_above[0];
        D_cqn_clk      = cpt_clk_n_above[0];
      end else begin //default case
        D_cq_clk       = cpt_clk[0];
        D_cqn_clk      = cpt_clk_n[0];
      end
    
    end 
  end
endgenerate

endmodule
