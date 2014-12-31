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
//  Revision:     $Id: qdr_rld_mc_phy.v,v 1.2 2012/05/08 01:03:44 rodrigoa Exp $
//                $Author: rodrigoa $
//                $DateTime: 2010/05/11 18:05:17 $
//                $Change: 490882 $
//  Description:
//    This verilog file is a parameterizable wrapper instantiating
//    up to 5 memory banks of 4-lane phy primitives. There
//    There are always 2 control banks leaving 18 lanes for data.
//
//  History:
//  Date        Engineer    Description
//  09/30/2010  J. Mittal   Initial Checkin.	   
//  07/30/2013              Added PO_COARSE_BYPASS for QDR2+ design.
//
//////////////////////////////////////////////////////////////////////////////
`timescale 1ps/1ps

module mig_7series_v2_0_qdr_rld_mc_phy
 #(
// five fields, one per possible I/O bank, 4 bits in each field, 1 per lane data=1/ctl=0
  parameter MEMORY_TYPE    = "SRAM",
  parameter MEM_TYPE       = "SRAM",
  parameter PO_COARSE_BYPASS   = "FALSE",

  parameter SIMULATION     = "FALSE",
  parameter SIM_BYPASS_INIT_CAL = "NONE",
  parameter INTERFACE_TYPE = "UNIDIR",
  parameter BYTE_LANES_B0  = 4'b1111,
  parameter BYTE_LANES_B1  = 4'b1111,
  parameter BYTE_LANES_B2  = 4'b0011, 
  parameter BYTE_LANES_B3  = 4'b0000,
  parameter BYTE_LANES_B4  = 4'b0000,
  parameter BITLANES_IN_B0  = 48'h1ff_3fd_1ff_1ff,
  parameter BITLANES_IN_B1  = 48'h000_000_000_000,
  parameter BITLANES_IN_B2  = 48'h000_000_000_000,
  parameter BITLANES_IN_B3  = 48'h000_000_000_000,
  parameter BITLANES_IN_B4  = 48'h000_000_000_000,
            
  parameter BITLANES_OUT_B0 = 48'h000_000_000_000,
  parameter BITLANES_OUT_B1 = 48'h1ff_3fd_1ff_1ff,
  parameter BITLANES_OUT_B2 = 48'h1ff_3fd_1ff_1ff,
  parameter BITLANES_OUT_B3 = 48'h000_000_000_000,
  parameter BITLANES_OUT_B4 = 48'h000_000_000_000,
  
  parameter CK_P_OUT_B0 = 48'h000_000_000_000,
  parameter CK_P_OUT_B1 = 48'h000_000_000_000,
  parameter CK_P_OUT_B2 = 48'h000_000_000_000,
            
  parameter BYTE_GROUP_TYPE_B0 = 4'b1111,
  parameter BYTE_GROUP_TYPE_B1 = 4'b0000,
  parameter BYTE_GROUP_TYPE_B2 = 4'b0000,  
  parameter BYTE_GROUP_TYPE_B3 = 4'b0000, 
  parameter BYTE_GROUP_TYPE_B4 = 4'b0000, 
            
  parameter DATA_CTL_B0    = 4'hf, // was 4'hc as byte_lanes A,B are control 
  parameter DATA_CTL_B1    = 4'hf, // All four lanes are data 
  parameter DATA_CTL_B2    = 4'hc, // was 4'hf, byte lanes A, B are used for control  
  parameter DATA_CTL_B3    = 4'hf,
  parameter DATA_CTL_B4    = 4'hf,
  
  parameter CPT_CLK_SEL_B0 = 32'h12_12_11_11,
  parameter CPT_CLK_SEL_B1 = 32'h12_12_11_11,  
  parameter CPT_CLK_SEL_B2 = 32'h12_12_11_11,
  
  parameter BUFMR_DELAY    = 500,
  parameter PLL_LOC           =  4'h0,
  parameter INTER_BANK_SKEW   =  0,
  parameter ADDR_CTL_90_SHIFT    = 0,
  parameter SHIFT_DATA_FOR_WRCAL = "FALSE",
  parameter PHY_CLK_RATIO      = 2,          // phy to controller divide ratio
  
  parameter DIFF_CK            = 1'b1,
  parameter DIFF_DK            = 1'b1,
  parameter DIFF_CQ            = 1'b0,
  parameter CK_VALUE_D1        = 1'b0,
  parameter DK_VALUE_D1        = 1'b0,
  parameter CK_MAP             = 48'h00_00_00_00_00_00,
  parameter DK_MAP             = 48'h00_00_00_00_00_11,
  parameter CQ_MAP             = 48'h00_00_00_00_00_00,
  parameter CK_WIDTH           = 1,
  parameter DK_WIDTH           = 1,
  parameter CQ_WIDTH           = 1, //NUM_DEVICES for QDR2+
  
  parameter IODELAY_GRP        = "IODELAY_MIG", //May be assigned unique name 
                                                // when mult IP cores in design
  parameter IODELAY_HP_MODE    = "ON", //IODELAY High Performance Mode
  parameter CLK_PERIOD          = 2500,   
  parameter PRE_FIFO               = "TRUE", 
  parameter PO_CTL_COARSE_BYPASS   = "FALSE",                                 
            
  parameter PHY_0_IS_LAST_BANK   = ((BYTE_LANES_B1 != 0) || 
                                    (BYTE_LANES_B2 != 0) || 
                                    (BYTE_LANES_B3 != 0) || 
                                    (BYTE_LANES_B4 != 0)) ?  "FALSE" : "TRUE",
  parameter PHY_1_IS_LAST_BANK   = ((BYTE_LANES_B1 != 0) && 
                                   ((BYTE_LANES_B2 != 0) || 
                                    (BYTE_LANES_B3 != 0) || 
                                    (BYTE_LANES_B4 != 0))) ?  "FALSE" : 
                                    ((PHY_0_IS_LAST_BANK) ? "FALSE" : "TRUE"),
  parameter PHY_2_IS_LAST_BANK   = (BYTE_LANES_B2 != 0) && 
                                   ((BYTE_LANES_B3 != 0) || 
                                   (BYTE_LANES_B4 != 0)) ?  "FALSE" : 
                                   ((PHY_0_IS_LAST_BANK || 
                                     PHY_1_IS_LAST_BANK) ? "FALSE" : "TRUE"),
  parameter PHYCTL_CMD_FIFO  = "FALSE",
  
  // common to all i/o banks
  parameter PHY_EVENTS_DELAY     = 30,
  parameter PHY_FOUR_WINDOW_CLOCKS  = 13,
  
  // local computational use, do not pass down
  parameter N_LANES = (0+BYTE_LANES_B0[0]) + (0+BYTE_LANES_B0[1]) + 
                      (0+BYTE_LANES_B0[2]) + (0+BYTE_LANES_B0[3]) +
                      (0+BYTE_LANES_B1[0]) + (0+BYTE_LANES_B1[1]) + 
                      (0+BYTE_LANES_B1[2]) + (0+BYTE_LANES_B1[3]) + 
                      (0+BYTE_LANES_B2[0]) + (0+BYTE_LANES_B2[1]) + 
                      (0+BYTE_LANES_B2[2]) + (0+BYTE_LANES_B2[3])
  ,  // must not delete comma for syntax
  parameter HIGHEST_BANK = (BYTE_LANES_B4 != 0 ? 5 : 
                           (BYTE_LANES_B3 != 0 ? 4 : 
                           (BYTE_LANES_B2 != 0 ? 3 :  
                           (BYTE_LANES_B1 != 0  ? 2 : 1)))),
  parameter HIGHEST_LANE_B0  = ((PHY_0_IS_LAST_BANK == "FALSE") ? 4 : 
                                 BYTE_LANES_B0[3] ? 4 : 
                                 BYTE_LANES_B0[2] ? 3 : 
                                 BYTE_LANES_B0[1] ? 2 : 
                                 BYTE_LANES_B0[0] ? 1 : 0)  ,
  parameter HIGHEST_LANE_B1  = (HIGHEST_BANK > 2) ? 4 : 
                               ( BYTE_LANES_B1[3] ? 4 : 
                                 BYTE_LANES_B1[2] ? 3 : 
                                 BYTE_LANES_B1[1] ? 2 : 
                                 BYTE_LANES_B1[0] ? 1 : 0) ,
  parameter HIGHEST_LANE_B2  = (HIGHEST_BANK > 3) ? 4 : 
                               ( BYTE_LANES_B2[3] ? 4 : 
                                 BYTE_LANES_B2[2] ? 3 : 
                                 BYTE_LANES_B2[1] ? 2 : 
                                 BYTE_LANES_B2[0] ? 1 : 0) ,
  parameter HIGHEST_LANE_B3  = 0,
  parameter HIGHEST_LANE_B4  = 0,
  
  parameter HIGHEST_LANE = (HIGHEST_LANE_B4 != 0) ? 
                           (HIGHEST_LANE_B4+16) : 
                           ((HIGHEST_LANE_B3 != 0) ? 
                           (HIGHEST_LANE_B3 + 12) : 
                           ((HIGHEST_LANE_B2 != 0) ? 
                           (HIGHEST_LANE_B2 + 8)  : 
                           ((HIGHEST_LANE_B1 != 0) ? 
                           (HIGHEST_LANE_B1 + 4) : HIGHEST_LANE_B0))),

parameter PHY_0_PO_FINE_DELAY     = "UNDECLARED",
parameter PHY_1_PO_FINE_DELAY     = PHY_0_PO_FINE_DELAY,
parameter PHY_2_PO_FINE_DELAY     = PHY_0_PO_FINE_DELAY,
parameter PHY_0_PI_FINE_DELAY     = "UNDECLARED",
parameter PHY_1_PI_FINE_DELAY     = PHY_0_PI_FINE_DELAY,
parameter PHY_2_PI_FINE_DELAY     = PHY_0_PI_FINE_DELAY,
parameter CPT_CLK_CQ_ONLY     = "TRUE",
parameter REFCLK_FREQ         = 300.0,         //Reference Clk Feq for IODELAYs
parameter BUFG_FOR_OUTPUTS    = "OFF",
parameter TCQ = 100,

// The PHY_CONTROL primitive in the bank where PLL exists is declared
// as the Master PHY_CONTROL.
parameter MASTER_PHY_CTL  = 1
                           
 )
 (
      input                               rst,
      input                               phy_clk,
	  input                               phy_clk_fast,
      input                               freq_refclk,
      input                               mem_refclk,
      input                               sys_rst,
      input                               rst_rd_clk,
      input                               sync_pulse,
      
      // Phy control word signals
      input                               pll_lock,
      input [31:0]                        phy_ctl_wd,
      input                               phy_ctl_wr,
      output                              phy_ctl_ready, 
      
      output                              ref_dll_lock,
      input                               rst_phaser_ref,
      
      input                               phy_write_calib, //
      input                               phy_read_calib,//
      output                              phy_ctl_a_full,
      output                              phy_ctl_full,
      
      input       [HIGHEST_LANE*80-1:0]   phy_dout, 
      input                               phy_cmd_wr_en,
      input                               phy_data_wr_en,
      input                               phy_rd_en,
      
      input                               idelay_ld,
      input       [(HIGHEST_BANK*48)-1:0] idelay_ce,
      input       [(HIGHEST_BANK*48)-1:0] idelay_inc,
      input       [HIGHEST_BANK*240-1:0]  idelay_cnt_in,
      output wire [HIGHEST_BANK*240-1:0]  idelay_cnt_out,
      
      output wire                         if_a_empty,
      output wire                         if_empty,
      output wire                         if_full,
      output wire                         of_empty,
      output wire                         of_ctl_a_full,
      output wire                         of_data_a_full,
      output wire                         of_ctl_full,
      output wire                         of_data_full,
      
      output wire [HIGHEST_LANE*80-1:0]   phy_din,
      output wire [(HIGHEST_LANE*12)-1:0] O,      // write data/ctl to memory
      input       [(HIGHEST_LANE*12)-1:0] I,      // read data/ctl from memory
      output wire [(HIGHEST_LANE*12)-1:0] mem_dq_ts,
      output wire [(HIGHEST_BANK*8)-1:0]  ddr_clk,
      input       [(HIGHEST_BANK*4)-1:0]  cq_clk,
      input       [(HIGHEST_BANK*4)-1:0]  cqn_clk,
      
      // calibration signals             
      input       [5:0]                   calib_sel,
      input       [HIGHEST_BANK-1:0]      calib_zero_inputs, // bit calib_sel[2], one per bank
      input                               calib_in_common,
      input                               po_dec_done,
      input                               po_inc_done,
      
      output wire                         po_delay_done,
      input                               po_fine_enable,
      input                               po_coarse_enable,
      input                               po_edge_adv,
      input                               po_fine_inc,
      input                               po_coarse_inc,
      input                               po_counter_load_en,
      input                               po_sel_fine_oclk_delay,
      input        [8:0]                  po_counter_load_val,
      input                               po_counter_read_en,
      output reg                          po_coarse_overflow,
      output reg                          po_fine_overflow,
      output reg [8:0]                    po_counter_read_val,
      input                               pi_fine_enable,
      input                               pi_edge_adv,
      input                               pi_fine_inc,
      input                               pi_counter_load_en,
      input                               pi_counter_read_en,
      input      [5:0]                    pi_counter_load_val,
      output reg                          pi_fine_overflow,
      output reg [5:0]                    pi_counter_read_val,
      output [255:0]                      dbg_mc_phy,
      output [767:0]                      dbg_phy_4lanes,
      output [3071:0]                     dbg_byte_lane

 );
             

//function to determine which byte lanes are used for the various clocks
function [3:0] calc_phy_map;
    input [63:0] ck_in;
    input [3:0]  width;
    input [2:0]  bank;
    integer       z;
    begin
      calc_phy_map = 'b0;
      for (z = 0; z < width; z = z + 1) begin
        if ((ck_in[(8*z+4)+:3])== bank)
          calc_phy_map[ck_in[(8*z)+:2]] = 1'b1;
      end
    end
  endfunction
  
  // check if outputs are being driven in a bank. Outputs are present when
  // the byte lane is valid and the byte group type is "OUTPUT"
  
  localparam OUTPUT_BANK_B0 = ( (BYTE_LANES_B0[0] &&  ~BYTE_GROUP_TYPE_B0[0]) ||
                                (BYTE_LANES_B0[1] &&  ~BYTE_GROUP_TYPE_B0[1]) ||
                                (BYTE_LANES_B0[2] &&  ~BYTE_GROUP_TYPE_B0[2]) ||
                                (BYTE_LANES_B0[3] &&  ~BYTE_GROUP_TYPE_B0[3]) ) ? "TRUE" : "FALSE";
                                
  localparam OUTPUT_BANK_B1 = ( (BYTE_LANES_B1[0] &&  ~BYTE_GROUP_TYPE_B1[0]) ||
                                (BYTE_LANES_B1[1] &&  ~BYTE_GROUP_TYPE_B1[1]) ||
                                (BYTE_LANES_B1[2] &&  ~BYTE_GROUP_TYPE_B1[2]) ||
                                (BYTE_LANES_B1[3] &&  ~BYTE_GROUP_TYPE_B1[3]) ) ? "TRUE" : "FALSE";   
                                
  localparam OUTPUT_BANK_B2 = ( (BYTE_LANES_B2[0] &&  ~BYTE_GROUP_TYPE_B2[0]) ||
                                (BYTE_LANES_B2[1] &&  ~BYTE_GROUP_TYPE_B2[1]) ||
                                (BYTE_LANES_B2[2] &&  ~BYTE_GROUP_TYPE_B2[2]) ||
                                (BYTE_LANES_B2[3] &&  ~BYTE_GROUP_TYPE_B2[3]) ) ? "TRUE" : "FALSE";  
    
  localparam N_CTL_LANES = (0+(!DATA_CTL_B0[0])) +  0+((!DATA_CTL_B0[1])) +  (0+(!DATA_CTL_B0[2])) +  (0+(!DATA_CTL_B0[3])) ;
  
  localparam PHY_MULTI_REGION      = (HIGHEST_BANK > 1) ? "TRUE" : "FALSE";

//*******************************************************************************************************************
// OCLK_DELAYED 90 degree phase shift calculations
//*******************************************************************************************************************

  //90 deg equivalent to 0.25 for MEM_RefClk <= 300 MHz  and 1.25 for Mem_RefClk > 300 MHz
  localparam PO_OCLKDELAY_INV = ((SIMULATION == "FALSE" && CLK_PERIOD > 2500) || CLK_PERIOD>= 3333 || MEMORY_TYPE == "RLD3") ?  "FALSE" : "TRUE";

  //DIV1: MemRefClk >= 400 MHz, DIV2: 200 <= MemRefClk < 400, DIV4: MemRefClk < 200 MHz    
  localparam PHY_FREQ_REF_MODE = CLK_PERIOD > 5000 ?  "DIV4" : CLK_PERIOD > 2500 ? "DIV2": "NONE";  

  localparam FREQ_REF_DIV = (PHY_FREQ_REF_MODE == "DIV4" ? 4 : PHY_FREQ_REF_MODE == "DIV2" ? 2 : 1); 

  //FreqRefClk (MHz) is 1,2,4 times faster than MemRefClk  
  localparam real FREQ_REF_MHZ =  1.0/((CLK_PERIOD/FREQ_REF_DIV/1000.0) / 1000) ;
  localparam real MEM_REF_MHZ =  1.0/((CLK_PERIOD/1000.0) / 1000) ;

  // Intrinsic delay between OCLK and OCLK_DELAYED Phaser Output
  localparam real INT_DELAY = 0.4392/FREQ_REF_DIV + 100.0/CLK_PERIOD;  // Fraction of MemRefClk

  // Whether OCLK_DELAY output comes inverted or not 
  localparam real HALF_CYCLE_DELAY = 0.5 * (PO_OCLKDELAY_INV == "TRUE" ? 1 : 0); //Fraction of MemRefClk 

  // Phaser-Out Stage3 Tap delay for 90 deg shift. Maximum tap delay is FreqRefClk period distributed over 64 taps   
  // localparam real TAP_DELAY = MC_OCLK_DELAY/63/FREQ_REF_DIV;
      
  // Equation: INT_DELAY + HALF_CYCLE_DELAY + TAP_DELAY = 0.25 or 1.25 MemRefClk cycles 
  localparam real MC_OCLK_DELAY = ((PO_OCLKDELAY_INV == "TRUE" ? 1.25 : 0.25) - (INT_DELAY + HALF_CYCLE_DELAY)) * 63 * FREQ_REF_DIV; 
  //localparam integer PO_OCLK_DELAY = MC_OCLK_DELAY;  // MC_OCLK_DELAY + 0.5;
  
  //Parameter for QDR2+ only since value only based on CLK_PERIOD
  localparam integer PO_OCLK_DELAY_QDR2
                       = (CLK_PERIOD > 2500)  ? 8 : 1;//0;
  localparam integer PO_OCLK_DELAY
                       = ((MEM_TYPE == "QDR2PLUS") && (CLK_PERIOD <= 2500) && 
                          ((SIM_BYPASS_INIT_CAL == "NONE") || (SIM_BYPASS_INIT_CAL == "OFF") || (SIM_BYPASS_INIT_CAL == "FAST_AND_WRCAL") || (SIM_BYPASS_INIT_CAL == "SKIP_AND_WRCAL"))) ? 1 : 
                         (SIMULATION == "TRUE" && MEMORY_TYPE != "RLD3") ? MC_OCLK_DELAY : 
                         (MEM_TYPE == "QDR2PLUS") ? PO_OCLK_DELAY_QDR2 :
                         (MEMORY_TYPE == "RLD3") ? 0 :
		         (CLK_PERIOD > 2500)  ? 8 :
                         (CLK_PERIOD <= 938)  ? 23 :
                         (CLK_PERIOD <= 1072) ? 24 :
                         (CLK_PERIOD <= 1250) ? 25 :
                         (CLK_PERIOD <= 1500) ? 26 : 27;
  
//*******************************************************************************************************************
// Phaser OUT fine delay calculations
//
//*******************************************************************************************************************
localparam   real FREQ_REF_PER_NS = CLK_PERIOD > 2500.0 ? CLK_PERIOD/2/1000.0 : CLK_PERIOD/1000.0;
localparam   real MEMREFCLK_PERIOD = CLK_PERIOD/1000.0;

localparam  DDR_TCK = CLK_PERIOD;

localparam PHY_0_A_PI_FREQ_REF_DIV = "NONE";
localparam PHY_1_A_PI_FREQ_REF_DIV = PHY_0_A_PI_FREQ_REF_DIV;
localparam PHY_2_A_PI_FREQ_REF_DIV = PHY_0_A_PI_FREQ_REF_DIV;

localparam  FREQ_REF_PERIOD = DDR_TCK / (PHY_0_A_PI_FREQ_REF_DIV == "DIV2" ? 2 : 1);
localparam  PO_S3_TAPS        = 64 ;  // Number of taps per clock cycle in OCLK_DELAYED delay line
localparam  PI_S2_TAPS        = 128 ; // Number of taps per clock cycle in stage 2 delay line
localparam  PO_S2_TAPS        = 128 ; // Number of taps per clock cycle in sta

/*
Intrinsic delay of Phaser In Stage 1
@3300ps - 1.939ns - 58.8%
@2500ps - 1.657ns - 66.3%
@1875ps - 1.263ns - 67.4%
@1500ps - 1.021ns - 68.1%
@1250ps - 0.868ns - 69.4%
@1072ps - 0.752ns - 70.1%
@938ps  - 0.667ns - 71.1% 
*/

// Fraction of a full DDR_TCK period
localparam  real PI_STG1_INTRINSIC_DELAY  =   
                     ((DDR_TCK < 1005) ? 0.667 :
                      (DDR_TCK < 1160) ? 0.752 :
                      (DDR_TCK < 1375) ? 0.868 :
                      (DDR_TCK < 1685) ? 1.021 :
                      (DDR_TCK < 2185) ? 1.263 :
                      (DDR_TCK < 2900) ? 1.657 :
                      (DDR_TCK < 3100) ? 1.771 : 1.939)*1000;
/*
Intrinsic delay of Phaser In Stage 2
@3300ps - 0.912ns - 27.6% - single tap - 13ps
@3000ps - 0.848ns - 28.3% - single tap - 11ps
@2500ps - 1.264ns - 50.6% - single tap - 19ps
@1875ps - 1.000ns - 53.3% - single tap - 15ps
@1500ps - 0.848ns - 56.5% - single tap - 11ps
@1250ps - 0.736ns - 58.9% - single tap - 9ps
@1072ps - 0.664ns - 61.9% - single tap - 8ps
@938ps  - 0.608ns - 64.8% - single tap - 7ps 
*/
// Intrinsic delay = (.4218 + .0002freq(MHz))period(ps)
localparam  real PI_STG2_INTRINSIC_DELAY  = (0.4218*FREQ_REF_PERIOD + 200) + 12;  // 12ps fudge factor
/*
Intrinsic delay of Phaser Out Stage 2 - coarse bypass = 1
@3300ps - 1.294ns - 39.2%
@2500ps - 1.294ns - 51.8%
@1875ps - 1.030ns - 54.9%
@1500ps - 0.878ns - 58.5%
@1250ps - 0.766ns - 61.3%
@1072ps - 0.694ns - 64.7%
@938ps  - 0.638ns - 68.0%

Intrinsic delay of Phaser Out Stage 2 - coarse bypass = 0
@3300ps - 2.084ns - 63.2% - single tap - 20ps
@2500ps - 2.084ns - 81.9% - single tap - 19ps
@1875ps - 1.676ns - 89.4% - single tap - 15ps
@1500ps - 1.444ns - 96.3% - single tap - 11ps
@1250ps - 1.276ns - 102.1% - single tap - 9ps
@1072ps - 1.164ns - 108.6% - single tap - 8ps
@938ps  - 1.076ns - 114.7% - single tap - 7ps
*/          
// Fraction of a full DDR_TCK period
localparam  real  PO_STG1_INTRINSIC_DELAY  = 0;
localparam  real  PO_STG2_FINE_INTRINSIC_DELAY    = 0.4218*FREQ_REF_PERIOD + 200 + 42; // 42ps fudge factor
localparam  real  PO_STG2_COARSE_INTRINSIC_DELAY  = 0.2256*FREQ_REF_PERIOD + 200 + 29; // 29ps fudge factor
localparam  real  PO_STG2_INTRINSIC_DELAY  = PO_STG2_FINE_INTRINSIC_DELAY +
                                            (PO_CTL_COARSE_BYPASS  == "TRUE" ? 30 : PO_STG2_COARSE_INTRINSIC_DELAY);

// When the PO_STG2_INTRINSIC_DELAY is approximately equal to tCK, then the Phaser Out's circular buffer can
// go metastable. The circular buffer must be prevented from getting into a metastable state. To accomplish this,
// a default programmed value must be programmed into the stage 2 delay. This delay is only needed at reset, adjustments
// to the stage 2 delay can be made after reset is removed.

localparam  real PO_S2_TAPS_SIZE        = FREQ_REF_PERIOD / PO_S2_TAPS ; // average delay of taps in stage 2 fine delay line
localparam  real PO_CIRC_BUF_META_ZONE  = 200; 
localparam       PO_CIRC_BUF_EARLY      = (PO_STG2_INTRINSIC_DELAY < DDR_TCK) ? 1'b1 : 1'b0;
localparam  real PO_CIRC_BUF_OFFSET     = (PO_STG2_INTRINSIC_DELAY < DDR_TCK) ? DDR_TCK - PO_STG2_INTRINSIC_DELAY : PO_STG2_INTRINSIC_DELAY - DDR_TCK;
// If the stage 2 intrinsic delay is less than the clock period, then see if it is less than the threshold
// If it is not more than the threshold than we must push the delay after the clock period plus a guardband.
localparam       PO_CIRC_BUF_DELAY      = PO_CIRC_BUF_EARLY ? (PO_CIRC_BUF_OFFSET > PO_CIRC_BUF_META_ZONE) ? 0 :
                                         (PO_CIRC_BUF_META_ZONE + PO_CIRC_BUF_OFFSET) / PO_S2_TAPS_SIZE : (PO_CIRC_BUF_META_ZONE - PO_CIRC_BUF_OFFSET) / PO_S2_TAPS_SIZE;


localparam  real  PI_INTRINSIC_DELAY  = PI_STG1_INTRINSIC_DELAY + PI_STG2_INTRINSIC_DELAY;
localparam  real  PO_INTRINSIC_DELAY  = PO_STG1_INTRINSIC_DELAY + PO_STG2_INTRINSIC_DELAY;
localparam  real  PI_STG2_DELAY       = (PO_INTRINSIC_DELAY + (PO_CIRC_BUF_DELAY*PO_S2_TAPS_SIZE)) - (PI_INTRINSIC_DELAY - DDR_TCK/2);
localparam  integer DEFAULT_RCLK_DELAY  = PI_STG2_DELAY / (FREQ_REF_PERIOD / PI_S2_TAPS);

//localparam  PHY_0_A_PI_FINE_DELAY = (RCLK_SELECT_BANK == 0) ? (RCLK_SELECT_LANE == "A") ? DEFAULT_RCLK_DELAY : 0 : 0;
//localparam  PHY_0_B_PI_FINE_DELAY = (RCLK_SELECT_BANK == 0) ? (RCLK_SELECT_LANE == "B") ? DEFAULT_RCLK_DELAY : 0 : 0;
//localparam  PHY_0_C_PI_FINE_DELAY = (RCLK_SELECT_BANK == 0) ? (RCLK_SELECT_LANE == "C") ? DEFAULT_RCLK_DELAY : 0 : 0;
//localparam  PHY_0_D_PI_FINE_DELAY = (RCLK_SELECT_BANK == 0) ? (RCLK_SELECT_LANE == "D") ? DEFAULT_RCLK_DELAY : 0 : 0;
//localparam  PHY_1_A_PI_FINE_DELAY = (RCLK_SELECT_BANK == 1) ? (RCLK_SELECT_LANE == "A") ? DEFAULT_RCLK_DELAY : 0 : 0;
//localparam  PHY_1_B_PI_FINE_DELAY = (RCLK_SELECT_BANK == 1) ? (RCLK_SELECT_LANE == "B") ? DEFAULT_RCLK_DELAY : 0 : 0;
//localparam  PHY_1_C_PI_FINE_DELAY = (RCLK_SELECT_BANK == 1) ? (RCLK_SELECT_LANE == "C") ? DEFAULT_RCLK_DELAY : 0 : 0;
//localparam  PHY_1_D_PI_FINE_DELAY = (RCLK_SELECT_BANK == 1) ? (RCLK_SELECT_LANE == "D") ? DEFAULT_RCLK_DELAY : 0 : 0;
//localparam  PHY_2_A_PI_FINE_DELAY = (RCLK_SELECT_BANK == 2) ? (RCLK_SELECT_LANE == "A") ? DEFAULT_RCLK_DELAY : 0 : 0;
//localparam  PHY_2_B_PI_FINE_DELAY = (RCLK_SELECT_BANK == 2) ? (RCLK_SELECT_LANE == "B") ? DEFAULT_RCLK_DELAY : 0 : 0;
//localparam  PHY_2_C_PI_FINE_DELAY = (RCLK_SELECT_BANK == 2) ? (RCLK_SELECT_LANE == "C") ? DEFAULT_RCLK_DELAY : 0 : 0;
//localparam  PHY_2_D_PI_FINE_DELAY = (RCLK_SELECT_BANK == 2) ? (RCLK_SELECT_LANE == "D") ? DEFAULT_RCLK_DELAY : 0 : 0;

localparam L_PHY_0_PO_FINE_DELAY  = PHY_0_PO_FINE_DELAY == "UNDECLARED" ? PO_CIRC_BUF_DELAY : PHY_0_PO_FINE_DELAY;
localparam L_PHY_1_PO_FINE_DELAY  = PHY_0_PO_FINE_DELAY == "UNDECLARED" ? PO_CIRC_BUF_DELAY : PHY_1_PO_FINE_DELAY;
localparam L_PHY_2_PO_FINE_DELAY  = PHY_0_PO_FINE_DELAY == "UNDECLARED" ? PO_CIRC_BUF_DELAY : PHY_2_PO_FINE_DELAY;

localparam L_PHY_0_PI_FINE_DELAY  = PHY_0_PI_FINE_DELAY == "UNDECLARED" ? PO_CIRC_BUF_DELAY : PHY_0_PI_FINE_DELAY;
localparam L_PHY_1_PI_FINE_DELAY  = PHY_0_PI_FINE_DELAY == "UNDECLARED" ? PO_CIRC_BUF_DELAY : PHY_1_PI_FINE_DELAY;
localparam L_PHY_2_PI_FINE_DELAY  = PHY_0_PI_FINE_DELAY == "UNDECLARED" ? PO_CIRC_BUF_DELAY : PHY_2_PI_FINE_DELAY;


// calculations to compute amount of skew that needs to be added on Bank0
// If PLL is in bank2, no skew to be added. Else if Bank1, add the skew value.
// Similarly, if PLL in bank2, delay the outputs in bank0 by twice the skew value.
// The output skew value is 0 if the bank is an input bank.                              
localparam SKEW_VAL_B0   = (PLL_LOC == 4'h2)? 0 :
                               (PLL_LOC == 4'h1)? 0 :
                               (PLL_LOC == 4'h0 && OUTPUT_BANK_B2 == "TRUE" && OUTPUT_BANK_B0 == "TRUE" )? 2 * INTER_BANK_SKEW : 
                               (PLL_LOC == 4'h0 && OUTPUT_BANK_B1 == "TRUE" && OUTPUT_BANK_B0 == "TRUE" )? INTER_BANK_SKEW : 0;
                               
// calculations to compute amount of skew that needs to be added on Bank1
// If PLL is in bank1, one bank-to-bank skew is to be added. Else if PLL is bank 0 or 2, no delay is added since the output is already skewed.                      
localparam SKEW_VAL_B1   = (PLL_LOC == 4'h1 && OUTPUT_BANK_B1 == "TRUE" && (OUTPUT_BANK_B0 == "TRUE" || OUTPUT_BANK_B2 == "TRUE") )? INTER_BANK_SKEW :
                             (PLL_LOC == 4'h0 && OUTPUT_BANK_B2 == "TRUE" && OUTPUT_BANK_B1 == "TRUE")? INTER_BANK_SKEW : 
                             (PLL_LOC == 4'h2 && OUTPUT_BANK_B0 == "TRUE" && OUTPUT_BANK_B1 == "TRUE" )? INTER_BANK_SKEW : 0;
                            
                               
// calculations to compute amount of skew that needs to be added on Bank2
// If PLL is in bank0, no skew is added, since bank2 already has the max. skew.
// Else if in Bank1, add the skew value if Bank 2 is an output bank.
// Similarly, if PLL in bank0, delay the outputs in bank2 by twice the skew value.                                 
localparam SKEW_VAL_B2   = ((PLL_LOC == 4'h0) ||  (PLL_LOC == 4'h1)) ? 0 :
                                 (PLL_LOC == 4'h2 && OUTPUT_BANK_B0 == "TRUE"  && OUTPUT_BANK_B2 == "TRUE")? 2 * INTER_BANK_SKEW : 
                                 (PLL_LOC == 4'h2 && OUTPUT_BANK_B1 == "TRUE" && OUTPUT_BANK_B2 == "TRUE")? INTER_BANK_SKEW : 0;

// amount of total delay required for Address and controls                               
//localparam ADDR_CTL_90_SHIFT = (CLK_PERIOD/4);

localparam PO_FINE_TAP_CNT_LIMIT = 63;  

//calculating freq. ref clk period. For mem freq. less than 400 MHz, freq. ref clk frequency is twice the memory clock frequency. Else is the same frequency.        
localparam FREQ_REF_CLK_PERIOD           =  CLK_PERIOD > 2500 ? (CLK_PERIOD/2) : CLK_PERIOD; 
                                    
localparam integer PHASER_TAP_RES        =  (FREQ_REF_CLK_PERIOD/128) ;  
localparam TOTAL_PO_FINE_TAP_DELAY_VAL   =  (PO_FINE_TAP_CNT_LIMIT * PHASER_TAP_RES);     

localparam PO_COARSE_DELAY_FIRST_TAP_VAL  =  ( FREQ_REF_CLK_PERIOD * 93)/360;
localparam PO_COARSE_DELAY_SECOND_TAP_VAL =  ( FREQ_REF_CLK_PERIOD * 103)/360;
// if the byte lane is an addr/ctl byte lane, add 90 degree shift delay as well. Else, only use clk skew delay. Calculate for each byte lane in a bank.
// Total phaser out delay calcualtion per byte lane
// Bank0
localparam A_PO_DELAY_VAL_B0 = (BYTE_LANES_B0[0] &&  ( (SHIFT_DATA_FOR_WRCAL == "TRUE") ? DATA_CTL_B0[0] : ~DATA_CTL_B0[0] )) ? (SKEW_VAL_B0 + ADDR_CTL_90_SHIFT):            
                                                              (BYTE_LANES_B0[0] && ~BYTE_GROUP_TYPE_B0[0])? (SKEW_VAL_B0) : 0;
localparam B_PO_DELAY_VAL_B0 = (BYTE_LANES_B0[1] &&  ( (SHIFT_DATA_FOR_WRCAL == "TRUE") ? DATA_CTL_B0[1] : ~DATA_CTL_B0[1])) ? (SKEW_VAL_B0 + ADDR_CTL_90_SHIFT) : 
                                                              (BYTE_LANES_B0[1] && ~BYTE_GROUP_TYPE_B0[1])? (SKEW_VAL_B0) : 0;    
localparam C_PO_DELAY_VAL_B0 = (BYTE_LANES_B0[2] &&  ( (SHIFT_DATA_FOR_WRCAL == "TRUE") ? DATA_CTL_B0[2] : ~DATA_CTL_B0[2])) ? (SKEW_VAL_B0 + ADDR_CTL_90_SHIFT) :
                                                              (BYTE_LANES_B0[2] && ~BYTE_GROUP_TYPE_B0[2])? (SKEW_VAL_B0) : 0; 
localparam D_PO_DELAY_VAL_B0 = (BYTE_LANES_B0[3] &&  ( (SHIFT_DATA_FOR_WRCAL == "TRUE") ? DATA_CTL_B0[3] : ~DATA_CTL_B0[3])) ? (SKEW_VAL_B0 + ADDR_CTL_90_SHIFT) :
                                                               (BYTE_LANES_B0[3] && ~BYTE_GROUP_TYPE_B0[3])? (SKEW_VAL_B0) : 0; 
                                                                                                                                                      
//Bank1                                                                                                                                               
localparam A_PO_DELAY_VAL_B1 = (BYTE_LANES_B1[0] &&  ( (SHIFT_DATA_FOR_WRCAL == "TRUE") ? DATA_CTL_B1[0] : ~DATA_CTL_B1[0])) ? (SKEW_VAL_B1 + ADDR_CTL_90_SHIFT ) : 
                                                              (BYTE_LANES_B1[0] && ~BYTE_GROUP_TYPE_B1[0]) ? (SKEW_VAL_B1) : 0;  
localparam B_PO_DELAY_VAL_B1 = (BYTE_LANES_B1[1] &&  ( (SHIFT_DATA_FOR_WRCAL == "TRUE") ? DATA_CTL_B1[1] : ~DATA_CTL_B1[1])) ? (SKEW_VAL_B1 + ADDR_CTL_90_SHIFT) :
			                                       (BYTE_LANES_B1[1] && ~BYTE_GROUP_TYPE_B1[1])? (SKEW_VAL_B1) : 0;
localparam C_PO_DELAY_VAL_B1 = (BYTE_LANES_B1[2] &&  ( (SHIFT_DATA_FOR_WRCAL == "TRUE") ? DATA_CTL_B1[2] : ~DATA_CTL_B1[2])) ? (SKEW_VAL_B1 + ADDR_CTL_90_SHIFT ) :
			                                       (BYTE_LANES_B1[2] && ~BYTE_GROUP_TYPE_B1[2])? (SKEW_VAL_B1) : 0;
localparam D_PO_DELAY_VAL_B1 = (BYTE_LANES_B1[3] &&  ((SHIFT_DATA_FOR_WRCAL == "TRUE") ? DATA_CTL_B1[3] : ~DATA_CTL_B1[3])) ? (SKEW_VAL_B1 + ADDR_CTL_90_SHIFT ) : 
                                                               (BYTE_LANES_B1[3] && ~BYTE_GROUP_TYPE_B1[3])? (SKEW_VAL_B1) : 0;
                                                                                                                                                      
//Bank2                                                                                                                                               
localparam A_PO_DELAY_VAL_B2 = (BYTE_LANES_B2[0] &&  ((SHIFT_DATA_FOR_WRCAL == "TRUE") ? DATA_CTL_B2[0] : ~DATA_CTL_B2[0])) ? (SKEW_VAL_B2 + ADDR_CTL_90_SHIFT ) : 
                                                               (BYTE_LANES_B2[0] && ~BYTE_GROUP_TYPE_B2[0])? (SKEW_VAL_B2) : 0;
localparam B_PO_DELAY_VAL_B2 = (BYTE_LANES_B2[1] &&  ((SHIFT_DATA_FOR_WRCAL == "TRUE") ? DATA_CTL_B2[1] : ~DATA_CTL_B2[1])) ? (SKEW_VAL_B2 + ADDR_CTL_90_SHIFT ) : 
                                                               (BYTE_LANES_B2[1] && ~BYTE_GROUP_TYPE_B2[1])? (SKEW_VAL_B2) : 0;
localparam C_PO_DELAY_VAL_B2 = (BYTE_LANES_B2[2] &&  ((SHIFT_DATA_FOR_WRCAL == "TRUE") ? DATA_CTL_B2[2] : ~DATA_CTL_B2[2])) ? (SKEW_VAL_B2 + ADDR_CTL_90_SHIFT ) :
                                                               (BYTE_LANES_B2[2] && ~BYTE_GROUP_TYPE_B2[2])? (SKEW_VAL_B2) : 0;
localparam D_PO_DELAY_VAL_B2 = (BYTE_LANES_B2[3] &&  ((SHIFT_DATA_FOR_WRCAL == "TRUE") ? DATA_CTL_B2[3] : ~DATA_CTL_B2[3])) ? (SKEW_VAL_B2 + ADDR_CTL_90_SHIFT ) : 
                                                               (BYTE_LANES_B2[3] && ~BYTE_GROUP_TYPE_B2[3])? (SKEW_VAL_B2) : 0;

   
// Bank0 coarse and fine tap delays

localparam A_PO_COARSE_DELAY_B0 = (A_PO_DELAY_VAL_B0 < TOTAL_PO_FINE_TAP_DELAY_VAL) ? 0 : // no coarse delay needed, fine taps sufficient
                                      // else atleast 1 coarse tap needed : 
                                      //if one coarse tap + all fine taps are still not sufficient, 2 coarse taps needed, else 1 tap needed.  
                                       ( A_PO_DELAY_VAL_B0 > (PO_COARSE_DELAY_FIRST_TAP_VAL + TOTAL_PO_FINE_TAP_DELAY_VAL)) ?  2 : 1;
                                       
localparam A_PO_FINE_DELAY_B0 =  (A_PO_COARSE_DELAY_B0  == 2 )?  ((A_PO_DELAY_VAL_B0  -  (PO_COARSE_DELAY_FIRST_TAP_VAL +  PO_COARSE_DELAY_SECOND_TAP_VAL))/ PHASER_TAP_RES) :
                                   (A_PO_COARSE_DELAY_B0  == 1 )?  (A_PO_DELAY_VAL_B0  -  PO_COARSE_DELAY_FIRST_TAP_VAL)/PHASER_TAP_RES : (A_PO_DELAY_VAL_B0/PHASER_TAP_RES);

localparam B_PO_COARSE_DELAY_B0 = (B_PO_DELAY_VAL_B0 < TOTAL_PO_FINE_TAP_DELAY_VAL) ? 0 : 
                                       ( B_PO_DELAY_VAL_B0 > (PO_COARSE_DELAY_FIRST_TAP_VAL + TOTAL_PO_FINE_TAP_DELAY_VAL)) ?  2 : 1;
                                       
localparam B_PO_FINE_DELAY_B0 =  (B_PO_COARSE_DELAY_B0  == 2 )?  ((B_PO_DELAY_VAL_B0  -  (PO_COARSE_DELAY_FIRST_TAP_VAL +  PO_COARSE_DELAY_SECOND_TAP_VAL))/ PHASER_TAP_RES) :
                                  (B_PO_COARSE_DELAY_B0  == 1 )?  (B_PO_DELAY_VAL_B0  -  PO_COARSE_DELAY_FIRST_TAP_VAL)/PHASER_TAP_RES : (B_PO_DELAY_VAL_B0/PHASER_TAP_RES);
                                  
localparam C_PO_COARSE_DELAY_B0 = (C_PO_DELAY_VAL_B0 < TOTAL_PO_FINE_TAP_DELAY_VAL) ? 0 : 
                                       ( C_PO_DELAY_VAL_B0 > (PO_COARSE_DELAY_FIRST_TAP_VAL + TOTAL_PO_FINE_TAP_DELAY_VAL)) ?  2 : 1;
                                       
localparam C_PO_FINE_DELAY_B0 =  (C_PO_COARSE_DELAY_B0  == 2 )?  ((C_PO_DELAY_VAL_B0  -  (PO_COARSE_DELAY_FIRST_TAP_VAL +  PO_COARSE_DELAY_SECOND_TAP_VAL))/ PHASER_TAP_RES) :
                                  (C_PO_COARSE_DELAY_B0  == 1 )?  (C_PO_DELAY_VAL_B0  -  PO_COARSE_DELAY_FIRST_TAP_VAL)/PHASER_TAP_RES : (C_PO_DELAY_VAL_B0/PHASER_TAP_RES);     
                                  
localparam D_PO_COARSE_DELAY_B0 = (D_PO_DELAY_VAL_B0 < TOTAL_PO_FINE_TAP_DELAY_VAL) ? 0 : 
                                       ( D_PO_DELAY_VAL_B0 > (PO_COARSE_DELAY_FIRST_TAP_VAL + TOTAL_PO_FINE_TAP_DELAY_VAL)) ?  2 : 1;
                                       
localparam D_PO_FINE_DELAY_B0 =  (D_PO_COARSE_DELAY_B0  == 2 )?  ((D_PO_DELAY_VAL_B0  -  (PO_COARSE_DELAY_FIRST_TAP_VAL +  PO_COARSE_DELAY_SECOND_TAP_VAL))/ PHASER_TAP_RES) :
                                  (D_PO_COARSE_DELAY_B0  == 1 )?  (D_PO_DELAY_VAL_B0  -  PO_COARSE_DELAY_FIRST_TAP_VAL)/PHASER_TAP_RES : (D_PO_DELAY_VAL_B0/PHASER_TAP_RES);    


// Bank1 coarse and fine tap delay
			

localparam A_PO_COARSE_DELAY_B1 = (A_PO_DELAY_VAL_B1 < TOTAL_PO_FINE_TAP_DELAY_VAL) ? 0 : // no coarse delay needed, fine taps sufficient
                                      // else atleast 1 coarse tap needed : 
                                      //if one coarse tap + all fine taps are still not sufficient, 2 coarse taps needed, else 1 tap needed.  
                                       ( A_PO_DELAY_VAL_B1 > (PO_COARSE_DELAY_FIRST_TAP_VAL + TOTAL_PO_FINE_TAP_DELAY_VAL)) ?  2 : 1;
                                       
localparam A_PO_FINE_DELAY_B1 =  (A_PO_COARSE_DELAY_B1  == 2 )?  ((A_PO_DELAY_VAL_B1  -  (PO_COARSE_DELAY_FIRST_TAP_VAL +  PO_COARSE_DELAY_SECOND_TAP_VAL))/ PHASER_TAP_RES) :
                                   (A_PO_COARSE_DELAY_B1  == 1 )?  (A_PO_DELAY_VAL_B1  -  PO_COARSE_DELAY_FIRST_TAP_VAL)/PHASER_TAP_RES : (A_PO_DELAY_VAL_B1/PHASER_TAP_RES);

localparam B_PO_COARSE_DELAY_B1 = (B_PO_DELAY_VAL_B1 < TOTAL_PO_FINE_TAP_DELAY_VAL) ? 0 : 
                                       ( B_PO_DELAY_VAL_B1 > (PO_COARSE_DELAY_FIRST_TAP_VAL + TOTAL_PO_FINE_TAP_DELAY_VAL)) ?  2 : 1;
                                       
localparam B_PO_FINE_DELAY_B1 =  (B_PO_COARSE_DELAY_B1  == 2 )?  ((B_PO_DELAY_VAL_B1  -  (PO_COARSE_DELAY_FIRST_TAP_VAL +  PO_COARSE_DELAY_SECOND_TAP_VAL))/ PHASER_TAP_RES) :
                                  (B_PO_COARSE_DELAY_B1  == 1 )?  (B_PO_DELAY_VAL_B1  -  PO_COARSE_DELAY_FIRST_TAP_VAL)/PHASER_TAP_RES : (B_PO_DELAY_VAL_B1/PHASER_TAP_RES);
                                  
localparam C_PO_COARSE_DELAY_B1 = (C_PO_DELAY_VAL_B1 < TOTAL_PO_FINE_TAP_DELAY_VAL) ? 0 : 
                                       ( C_PO_DELAY_VAL_B1 > (PO_COARSE_DELAY_FIRST_TAP_VAL + TOTAL_PO_FINE_TAP_DELAY_VAL)) ?  2 : 1;
                                       
localparam C_PO_FINE_DELAY_B1 =  (C_PO_COARSE_DELAY_B1  == 2 )?  ((C_PO_DELAY_VAL_B1  -  (PO_COARSE_DELAY_FIRST_TAP_VAL +  PO_COARSE_DELAY_SECOND_TAP_VAL))/ PHASER_TAP_RES) :
                                  (C_PO_COARSE_DELAY_B1  == 1 )?  (C_PO_DELAY_VAL_B1  -  PO_COARSE_DELAY_FIRST_TAP_VAL)/PHASER_TAP_RES : (C_PO_DELAY_VAL_B1/PHASER_TAP_RES);     
                                  
localparam D_PO_COARSE_DELAY_B1 = (D_PO_DELAY_VAL_B1 < TOTAL_PO_FINE_TAP_DELAY_VAL) ? 0 : 
                                       ( D_PO_DELAY_VAL_B1 > (PO_COARSE_DELAY_FIRST_TAP_VAL + TOTAL_PO_FINE_TAP_DELAY_VAL)) ?  2 : 1;
                                       
localparam D_PO_FINE_DELAY_B1 =  (D_PO_COARSE_DELAY_B1  == 2 )?  ((D_PO_DELAY_VAL_B1  -  (PO_COARSE_DELAY_FIRST_TAP_VAL +  PO_COARSE_DELAY_SECOND_TAP_VAL))/ PHASER_TAP_RES) :
                                  (D_PO_COARSE_DELAY_B1  == 1 )?  (D_PO_DELAY_VAL_B1  -  PO_COARSE_DELAY_FIRST_TAP_VAL)/PHASER_TAP_RES : (D_PO_DELAY_VAL_B1/PHASER_TAP_RES);


// Bank2 coarse and fine tap delays

localparam A_PO_COARSE_DELAY_B2 = (A_PO_DELAY_VAL_B2 < TOTAL_PO_FINE_TAP_DELAY_VAL) ? 0 : // no coarse delay needed, fine taps sufficient
                                      // else atleast 1 coarse tap needed : 
                                      //if one coarse tap + all fine taps are still not sufficient, 2 coarse taps needed, else 1 tap needed.  
                                       ( A_PO_DELAY_VAL_B2 > (PO_COARSE_DELAY_FIRST_TAP_VAL + TOTAL_PO_FINE_TAP_DELAY_VAL)) ?  2 : 1;
                                       
localparam A_PO_FINE_DELAY_B2 =  (A_PO_COARSE_DELAY_B2  == 2 )?  ((A_PO_DELAY_VAL_B2  -  (PO_COARSE_DELAY_FIRST_TAP_VAL +  PO_COARSE_DELAY_SECOND_TAP_VAL))/ PHASER_TAP_RES) :
                                   (A_PO_COARSE_DELAY_B2  == 1 )?  (A_PO_DELAY_VAL_B2  -  PO_COARSE_DELAY_FIRST_TAP_VAL)/PHASER_TAP_RES : (A_PO_DELAY_VAL_B2/PHASER_TAP_RES);

localparam B_PO_COARSE_DELAY_B2 = (B_PO_DELAY_VAL_B2 < TOTAL_PO_FINE_TAP_DELAY_VAL) ? 0 : 
                                       ( B_PO_DELAY_VAL_B2 > (PO_COARSE_DELAY_FIRST_TAP_VAL + TOTAL_PO_FINE_TAP_DELAY_VAL)) ?  2 : 1;
                                       
localparam B_PO_FINE_DELAY_B2 =  (B_PO_COARSE_DELAY_B2  == 2 )?  ((B_PO_DELAY_VAL_B2  -  (PO_COARSE_DELAY_FIRST_TAP_VAL +  PO_COARSE_DELAY_SECOND_TAP_VAL))/ PHASER_TAP_RES) :
                                  (B_PO_COARSE_DELAY_B2  == 1 )?  (B_PO_DELAY_VAL_B2  -  PO_COARSE_DELAY_FIRST_TAP_VAL)/PHASER_TAP_RES : (B_PO_DELAY_VAL_B2/PHASER_TAP_RES);
                                  
localparam C_PO_COARSE_DELAY_B2 = (C_PO_DELAY_VAL_B2 < TOTAL_PO_FINE_TAP_DELAY_VAL) ? 0 : 
                                       ( C_PO_DELAY_VAL_B2 > (PO_COARSE_DELAY_FIRST_TAP_VAL + TOTAL_PO_FINE_TAP_DELAY_VAL)) ?  2 : 1;
                                       
localparam C_PO_FINE_DELAY_B2 =  (C_PO_COARSE_DELAY_B2  == 2 )?  ((C_PO_DELAY_VAL_B2  -  (PO_COARSE_DELAY_FIRST_TAP_VAL +  PO_COARSE_DELAY_SECOND_TAP_VAL))/ PHASER_TAP_RES) :
                                  (C_PO_COARSE_DELAY_B2  == 1 )?  (C_PO_DELAY_VAL_B2  -  PO_COARSE_DELAY_FIRST_TAP_VAL)/PHASER_TAP_RES : (C_PO_DELAY_VAL_B2/PHASER_TAP_RES);     
                                  
localparam D_PO_COARSE_DELAY_B2 = (D_PO_DELAY_VAL_B2 < TOTAL_PO_FINE_TAP_DELAY_VAL) ? 0 : 
                                       ( D_PO_DELAY_VAL_B2 > (PO_COARSE_DELAY_FIRST_TAP_VAL + TOTAL_PO_FINE_TAP_DELAY_VAL)) ?  2 : 1;
                                       
localparam D_PO_FINE_DELAY_B2 =  (D_PO_COARSE_DELAY_B2  == 2 )?  ((D_PO_DELAY_VAL_B2  -  (PO_COARSE_DELAY_FIRST_TAP_VAL +  PO_COARSE_DELAY_SECOND_TAP_VAL))/ PHASER_TAP_RES) :
                                  (D_PO_COARSE_DELAY_B2  == 1 )?  (D_PO_DELAY_VAL_B2  -  PO_COARSE_DELAY_FIRST_TAP_VAL)/PHASER_TAP_RES : (D_PO_DELAY_VAL_B2/PHASER_TAP_RES);    
  
//*********************************************************************************************************************
 
  //synthesis translate_off
  initial begin
    $display("############# OCLK_DELAY value #############\n");
        $display("CLK_PERIOD      = %7.3f", CLK_PERIOD);
        $display("MEM_REF_MHZ    = %7.3f", MEM_REF_MHZ);
        $display("FREQ_REF_MHZ    = %7.3f", FREQ_REF_MHZ);
        $display("FREQ_REF_DIV    = %7d", FREQ_REF_DIV);        
        $display("INT_DELAY   = %7.3f", INT_DELAY);        
        $display("MC_OCLK_DELAY   = %7.3f", MC_OCLK_DELAY);        
        $display("PO_OCLK_DELAY   = %7d",   PO_OCLK_DELAY);
//        $display("MC_OCLK_DELAY2  = %7.3f", MC_OCLK_DELAY2);
//        $display("MC_OCLK_DELAY3  = %7.3f", MC_OCLK_DELAY3);
//        $display("MC_OCLK_DELAY4  = %7.3f", MC_OCLK_DELAY4);
    $display("############################################################\n");
  end
  //synthesis translate_on

// parameters common to instance 0
localparam PHY_0_GENERATE_DDR_CK        = 4'h0;//calc_phy_map(CK_MAP, CK_WIDTH, 3'h0);
localparam PHY_0_GENERATE_DDR_DK        = calc_phy_map(DK_MAP, DK_WIDTH, 3'h0);
localparam PHY_0_GENERATE_CQ            = calc_phy_map(CQ_MAP, CQ_WIDTH, 3'h0);
                                        
localparam PHY_0_A_PO_OCLK_DELAY        = PO_OCLK_DELAY;
localparam PHY_0_B_PO_OCLK_DELAY        = PHY_0_A_PO_OCLK_DELAY;
localparam PHY_0_C_PO_OCLK_DELAY        = PHY_0_A_PO_OCLK_DELAY;
localparam PHY_0_D_PO_OCLK_DELAY        = PHY_0_A_PO_OCLK_DELAY;
                                        
localparam PHY_0_A_PO_OCLKDELAY_INV     = PO_OCLKDELAY_INV;
localparam PHY_0_B_PO_OCLKDELAY_INV     = PHY_0_A_PO_OCLKDELAY_INV;
localparam PHY_0_C_PO_OCLKDELAY_INV     = PHY_0_A_PO_OCLKDELAY_INV;
localparam PHY_0_D_PO_OCLKDELAY_INV     = PHY_0_A_PO_OCLKDELAY_INV;
                                        
localparam real PHY_0_A_PO_REFCLK_PERIOD     = FREQ_REF_PER_NS;
localparam real PHY_0_B_PO_REFCLK_PERIOD     = PHY_0_A_PO_REFCLK_PERIOD;
localparam real PHY_0_C_PO_REFCLK_PERIOD     = PHY_0_A_PO_REFCLK_PERIOD;
localparam real PHY_0_D_PO_REFCLK_PERIOD     = PHY_0_A_PO_REFCLK_PERIOD;
                                        
localparam real PHY_0_A_PI_REFCLK_PERIOD     = FREQ_REF_PER_NS;
localparam real PHY_0_B_PI_REFCLK_PERIOD     = PHY_0_A_PI_REFCLK_PERIOD;
localparam real PHY_0_C_PI_REFCLK_PERIOD     = PHY_0_A_PI_REFCLK_PERIOD;
localparam real PHY_0_D_PI_REFCLK_PERIOD     = PHY_0_A_PI_REFCLK_PERIOD;
                                        
localparam PHY_0_LANE_REMAP             = 16'h3210;
localparam PHY_0_DATA_CTL               = DATA_CTL_B0;
localparam PHY_0_CPT_CLK_SEL            = CPT_CLK_SEL_B0;

// inst1
localparam PHY_1_GENERATE_DDR_CK        = 4'h0;//calc_phy_map(CK_MAP, CK_WIDTH, 3'h1);
localparam PHY_1_GENERATE_DDR_DK        = calc_phy_map(DK_MAP, DK_WIDTH, 3'h1);
localparam PHY_1_GENERATE_CQ            = calc_phy_map(CQ_MAP, CQ_WIDTH, 3'h1);
                                        
localparam PHY_1_A_PO_OCLK_DELAY        = PHY_0_A_PO_OCLK_DELAY;
localparam PHY_1_B_PO_OCLK_DELAY        = PHY_1_A_PO_OCLK_DELAY;
localparam PHY_1_C_PO_OCLK_DELAY        = PHY_1_A_PO_OCLK_DELAY;
localparam PHY_1_D_PO_OCLK_DELAY        = PHY_1_A_PO_OCLK_DELAY;
                                        
localparam PHY_1_A_PO_OCLKDELAY_INV     = PHY_0_A_PO_OCLKDELAY_INV;
localparam PHY_1_B_PO_OCLKDELAY_INV     = PHY_1_A_PO_OCLKDELAY_INV;
localparam PHY_1_C_PO_OCLKDELAY_INV     = PHY_1_A_PO_OCLKDELAY_INV;
localparam PHY_1_D_PO_OCLKDELAY_INV     = PHY_1_A_PO_OCLKDELAY_INV;
                                        
localparam real PHY_1_A_PO_REFCLK_PERIOD     = FREQ_REF_PER_NS;
localparam real PHY_1_B_PO_REFCLK_PERIOD     = PHY_1_A_PO_REFCLK_PERIOD;
localparam real PHY_1_C_PO_REFCLK_PERIOD     = PHY_1_A_PO_REFCLK_PERIOD;
localparam real PHY_1_D_PO_REFCLK_PERIOD     = PHY_1_A_PO_REFCLK_PERIOD;
                                        
localparam real PHY_1_A_PI_REFCLK_PERIOD     = FREQ_REF_PER_NS;
localparam real PHY_1_B_PI_REFCLK_PERIOD     = PHY_1_A_PI_REFCLK_PERIOD;
localparam real PHY_1_C_PI_REFCLK_PERIOD     = PHY_1_A_PI_REFCLK_PERIOD;
localparam real PHY_1_D_PI_REFCLK_PERIOD     = PHY_1_A_PI_REFCLK_PERIOD;
                                        
localparam PHY_1_LANE_REMAP             = 16'h3210;
localparam PHY_1_DATA_CTL               = DATA_CTL_B1;
localparam PHY_1_CPT_CLK_SEL            = CPT_CLK_SEL_B1;

// inst2
localparam PHY_2_GENERATE_DDR_CK        = 4'h0;//calc_phy_map(CK_MAP, CK_WIDTH, 3'h2);
localparam PHY_2_GENERATE_DDR_DK        = calc_phy_map(DK_MAP, DK_WIDTH, 3'h2);
localparam PHY_2_GENERATE_CQ            = calc_phy_map(CQ_MAP, CQ_WIDTH, 3'h2);
                                        
localparam PHY_2_A_PO_OCLK_DELAY        = PHY_0_A_PO_OCLK_DELAY;
localparam PHY_2_B_PO_OCLK_DELAY        = PHY_2_A_PO_OCLK_DELAY;
localparam PHY_2_C_PO_OCLK_DELAY        = PHY_2_A_PO_OCLK_DELAY;
localparam PHY_2_D_PO_OCLK_DELAY        = PHY_2_A_PO_OCLK_DELAY;
                                        
localparam PHY_2_A_PO_OCLKDELAY_INV     = PHY_0_A_PO_OCLKDELAY_INV;
localparam PHY_2_B_PO_OCLKDELAY_INV     = PHY_2_A_PO_OCLKDELAY_INV;
localparam PHY_2_C_PO_OCLKDELAY_INV     = PHY_2_A_PO_OCLKDELAY_INV;
localparam PHY_2_D_PO_OCLKDELAY_INV     = PHY_2_A_PO_OCLKDELAY_INV;
                                        
localparam real PHY_2_A_PO_REFCLK_PERIOD     = FREQ_REF_PER_NS;
localparam real PHY_2_B_PO_REFCLK_PERIOD     = PHY_2_A_PO_REFCLK_PERIOD;
localparam real PHY_2_C_PO_REFCLK_PERIOD     = PHY_2_A_PO_REFCLK_PERIOD;
localparam real PHY_2_D_PO_REFCLK_PERIOD     = PHY_2_A_PO_REFCLK_PERIOD;
                                        
localparam real PHY_2_A_PI_REFCLK_PERIOD     = FREQ_REF_PER_NS;
localparam real PHY_2_B_PI_REFCLK_PERIOD     = PHY_2_A_PI_REFCLK_PERIOD;
localparam real PHY_2_C_PI_REFCLK_PERIOD     = PHY_2_A_PI_REFCLK_PERIOD;
localparam real PHY_2_D_PI_REFCLK_PERIOD     = PHY_2_A_PI_REFCLK_PERIOD;
                                        
localparam PHY_2_LANE_REMAP             = 16'h3210;
localparam PHY_2_DATA_CTL               = DATA_CTL_B2;
localparam PHY_2_CPT_CLK_SEL            = CPT_CLK_SEL_B2;

//wires associated with capture clocks (BUFMR) from different banks
//allow MIG to set which byte groups are captured with which clocks
wire [1:0]              cpt_clk_0;
wire [1:0]              cpt_clk_1;
wire [1:0]              cpt_clk_2;
wire [1:0]              cpt_clk_n_0;
wire [1:0]              cpt_clk_n_1;
wire [1:0]              cpt_clk_n_2;

wire [7:0]              calib_zero_inputs_int ;
                        
wire [4:0]              po_coarse_overflow_w;
wire [4:0]              po_fine_overflow_w;
wire [8:0]              po_counter_read_val_w[4:0];
wire [4:0]              pi_fine_overflow_w;
wire [5:0]              pi_counter_read_val_w[4:0];
wire [HIGHEST_BANK-1:0] po_delay_done_w;
                        
wire [3:0]              if_q0;
wire [3:0]              if_q1;
wire [3:0]              if_q2;
wire [3:0]              if_q3;
wire [3:0]              if_q4;
wire [7:0]              if_q5;
wire [7:0]              if_q6;
wire [3:0]              if_q7;
wire [3:0]              if_q8;
wire [3:0]              if_q9;
                        
wire [HIGHEST_BANK-1:0] of_data_a_full_v;
wire [HIGHEST_BANK-1:0] of_data_full_v;
wire [HIGHEST_BANK-1:0] of_ctl_a_full_v;
wire [HIGHEST_BANK-1:0] of_ctl_full_v;
wire [HIGHEST_BANK-1:0] of_empty_v;
wire [HIGHEST_BANK-1:0] if_empty_v;
wire [HIGHEST_BANK-1:0] if_full_v;
wire [HIGHEST_BANK-1:0] if_a_empty_v;
wire [HIGHEST_BANK-1:0] phy_ctl_ready_w; 
wire [HIGHEST_BANK-1:0] phy_ctl_empty;
wire                    phy_ctl_mstr_empty;
wire                    out_fifos_full; 
                        
wire [31:0]             phy_ctl_wd_phy;
wire [3:0]              aux_in_[4:1];
wire                    _phy_ctl_wr;
wire                    _phy_clk;
wire [HIGHEST_BANK-1:0] _phy_ctl_a_full_p;
wire [HIGHEST_BANK-1:0] _phy_ctl_full_p;
wire [3:0]              aux_in_1;
wire [3:0]              aux_in_2;
wire [2:0]              ref_dll_lock_w;

wire [3:0]              drive_on_calib_in_common_0;
wire [3:0]              drive_on_calib_in_common_1;
wire [3:0]              drive_on_calib_in_common_2;
wire [3:0]              drive_on_calib_in_common_3;
wire [3:0]              drive_on_calib_in_common_4;
wire                    calib_byte_dir;

assign calib_byte_dir = (calib_sel[5:3] == 0) ? BYTE_GROUP_TYPE_B0[calib_sel[1:0]] : 
                         ((calib_sel[5:3] == 1) ? BYTE_GROUP_TYPE_B1[calib_sel[1:0]] :
                          ((calib_sel[5:3] == 2) ? BYTE_GROUP_TYPE_B2[calib_sel[1:0]] :
                           ((calib_sel[5:3] == 3) ? BYTE_GROUP_TYPE_B3[calib_sel[1:0]] :
                            ((calib_sel[5:3] == 4) ? BYTE_GROUP_TYPE_B4[calib_sel[1:0]] :
                             0
                            )
                           )
                          )
                         );

assign drive_on_calib_in_common_0 = (MEM_TYPE != "QDR2PLUS") ? 4'hF : ( (calib_byte_dir == 0) ? ~BYTE_GROUP_TYPE_B0 : BYTE_GROUP_TYPE_B0) ;
assign drive_on_calib_in_common_1 = (MEM_TYPE != "QDR2PLUS") ? 4'hF : ( (calib_byte_dir == 0) ? ~BYTE_GROUP_TYPE_B1 : BYTE_GROUP_TYPE_B1) ;
assign drive_on_calib_in_common_2 = (MEM_TYPE != "QDR2PLUS") ? 4'hF : ( (calib_byte_dir == 0) ? ~BYTE_GROUP_TYPE_B2 : BYTE_GROUP_TYPE_B2) ;
assign drive_on_calib_in_common_3 = (MEM_TYPE != "QDR2PLUS") ? 4'hF : ( (calib_byte_dir == 0) ? ~BYTE_GROUP_TYPE_B3 : BYTE_GROUP_TYPE_B3) ;
assign drive_on_calib_in_common_4 = (MEM_TYPE != "QDR2PLUS") ? 4'hF : ( (calib_byte_dir == 0) ? ~BYTE_GROUP_TYPE_B4 : BYTE_GROUP_TYPE_B4) ;

// when phy command fifo not used:
//synthesis translate_off
initial begin
      $display("%m : %t : BYTE_LANES_B0 = %x BYTE_LANES_B1 = %x DATA_CTL_B0 = %x DATA_CTL_B1 = %x", $time, BYTE_LANES_B0, BYTE_LANES_B1, DATA_CTL_B0, DATA_CTL_B1);
      $display("%m : %t : HIGHEST_LANE = %d HIGHEST_LANE_B0 = %d HIGHEST_LANE_B1 = %d", $time, HIGHEST_LANE, HIGHEST_LANE_B0, HIGHEST_LANE_B1);
      $display("%m : %t : HIGHEST_BANK = %d", $time, HIGHEST_BANK);
end
 //synthesis translate_on

  wire [255:0]             dbg_phy_4lanes_0;
  wire [255:0]             dbg_phy_4lanes_1;
  wire [255:0]             dbg_phy_4lanes_2;
  wire [1023:0]            dbg_byte_lane_0;
  wire [1023:0]            dbg_byte_lane_1;
  wire [1023:0]            dbg_byte_lane_2;
  
  assign dbg_phy_4lanes = {dbg_phy_4lanes_2,
                           dbg_phy_4lanes_1,
                           dbg_phy_4lanes_0};
  assign dbg_byte_lane  = {dbg_byte_lane_2,
                           dbg_byte_lane_1,
                           dbg_byte_lane_0};
                           
assign dbg_mc_phy[2:0]    = phy_ctl_ready_w;
assign dbg_mc_phy[5:3]    = of_data_full_v;
assign dbg_mc_phy[8:6]    = of_ctl_full_v;
assign dbg_mc_phy[40:9]   = phy_ctl_wd;
assign dbg_mc_phy[41]     = phy_ctl_wr;
assign dbg_mc_phy[44:42]  = of_empty_v;
assign dbg_mc_phy[47:45]  = if_empty_v;
assign dbg_mc_phy[50:48]  = if_full_v;
assign dbg_mc_phy[54:51]  = dbg_phy_4lanes_2[3:0];
assign dbg_mc_phy[255:55] = 'b0;

assign calib_zero_inputs_int = {3'bxxx, calib_zero_inputs};

assign aux_in_1              = 4'b0000;
assign aux_in_2              = 4'b0000;

assign of_data_a_full        = |of_data_a_full_v;
assign of_data_full          = |of_data_full_v;
assign of_ctl_a_full         = |of_ctl_a_full_v;
assign of_ctl_full           = |of_ctl_full_v;
assign of_empty              = & of_empty_v;
assign if_empty              = | if_empty_v;
assign if_full               = | if_full_v;
assign if_a_empty            = & if_a_empty_v;
assign phy_ctl_ready         = &phy_ctl_ready_w[HIGHEST_BANK-1:0];

assign po_delay_done         = & po_delay_done_w;
   
//   assign phy_ctl_mstr_empty    = | phy_ctl_empty;
   
assign phy_ctl_mstr_empty    = phy_ctl_empty[MASTER_PHY_CTL];
                             
assign out_fifos_full        = (of_data_full || of_ctl_full);

assign phy_ctl_wd_phy        = phy_ctl_wd[31:0];   
assign aux_in_[1]            = aux_in_1;
assign phy_ctl_a_full        = |_phy_ctl_a_full_p;
assign phy_ctl_full          = |_phy_ctl_full_p;
assign _phy_ctl_wr           = phy_ctl_wr;
assign _phy_clk              = phy_clk;

// instance of four-lane phy

`ifdef CLK_SKEW_ON
  wire          mem_refclk_skew;
  wire          freq_refclk_skew;
//  wire          mem_refclk_div4_skew;
  wire          sync_pulse_skew;
  wire          phy_ctl_clk_skew1;
  wire          phy_clk_skew1;
  wire  [31:0]  phy_ctl_wd_phy_skew1;
  wire          phy_ctl_wr_skew1;
  wire          phy_ctl_clk_skew2;
  wire          phy_clk_skew2;
  wire  [31:0]  phy_ctl_wd_phy_skew2;
  wire          phy_ctl_wr_skew2;
  wire          phy_ctl_clk_skew3;
  wire          phy_clk_skew3;
  wire  [31:0]  phy_ctl_wd_phy_skew3;
  wire          phy_ctl_wr_skew3;
  reg   [23:0]  delay_mem_refclk;
  reg   [23:0]  delay_phy_clk1;
  reg   [23:0]  delay_phy_clk2;
  reg   [23:0]  delay_phy_clk3;
  integer       seed1;
  integer       seed2;
  integer       seed3;

   //synthesis translate_off
  initial
  begin
    seed1 = `SKEW_SEED;
    seed2 = $random(seed1);
    seed3 = $random(seed2);
    delay_mem_refclk = 150;
    delay_phy_clk1 = {$random(seed1)} % 300;
    delay_phy_clk2 = {$random(seed2)} % 300;
    delay_phy_clk3 = {$random(seed3)} % 300;
    $display ("delay generated for mem_refclk in phy_4lanes   = %d   ", delay_mem_refclk );
    $display ("delay generated for phy_ctl_clk1 in phy_4lanes = %d   ", delay_phy_clk1 );
    $display ("delay generated for phy_ctl_clk2 in phy_4lanes = %d   ", delay_phy_clk2 );
    $display ("delay generated for phy_ctl_clk3 in phy_4lanes = %d   ", delay_phy_clk3 );
  end
   //synthesis translate_on
  
  
  assign #delay_mem_refclk  mem_refclk_skew       = mem_refclk;
  assign #delay_mem_refclk  sync_pulse_skew       = sync_pulse;
  assign #delay_mem_refclk  freq_refclk_skew      = freq_refclk;
//  assign #delay_mem_refclk  mem_refclk_div4_skew  = mem_refclk_div4;
  assign #delay_phy_clk1    phy_ctl_clk_skew1     = _phy_clk;
  assign #0                 phy_clk_skew1         = phy_clk;
  assign #delay_phy_clk1    phy_ctl_wd_phy_skew1  = phy_ctl_wd_phy;
  assign #delay_phy_clk1    phy_ctl_wr_skew1      = _phy_ctl_wr;
  assign #delay_phy_clk2    phy_ctl_clk_skew2     = _phy_clk;
  assign #0                 phy_clk_skew2         = phy_clk;
  assign #delay_phy_clk2    phy_ctl_wd_phy_skew2  = {phy_ctl_wd_phy[31:12], aux_in_[1], phy_ctl_wd_phy[7:0]};
  assign #delay_phy_clk2    phy_ctl_wr_skew2      = _phy_ctl_wr;
  assign #delay_phy_clk3    phy_ctl_clk_skew3     = _phy_clk;
  assign #0                 phy_clk_skew3         = phy_clk;
  assign #delay_phy_clk3    phy_ctl_wd_phy_skew3  = {phy_ctl_wd_phy[31:12], aux_in_[2], phy_ctl_wd_phy[7:0]};
  assign #delay_phy_clk3    phy_ctl_wr_skew3      = _phy_ctl_wr;

`endif



generate 
// phy_4lane_0 inputs 36-bit Read data and QVLD control in read memory bank
if ( BYTE_LANES_B0 != 0)  begin : qdr_rld_phy_4lanes_0

  mig_7series_v2_0_qdr_rld_phy_4lanes #(
     .MEMORY_TYPE               ( MEMORY_TYPE),
     .SIMULATION                ( SIMULATION),
     .PO_COARSE_BYPASS			(PO_COARSE_BYPASS),
     .CPT_CLK_CQ_ONLY           ( CPT_CLK_CQ_ONLY),
     .INTERFACE_TYPE            ( INTERFACE_TYPE),
	 .REFCLK_FREQ               ( REFCLK_FREQ),
	 .BUFG_FOR_OUTPUTS          ( BUFG_FOR_OUTPUTS),
	 .CLK_PERIOD                ( CLK_PERIOD),
     .PRE_FIFO                  ( PRE_FIFO),
     .BYTE_LANES                ( BYTE_LANES_B0),        /* four bits, one per lanes */
     .BITLANES_IN               ( BITLANES_IN_B0),
     .BITLANES_OUT              ( BITLANES_OUT_B0),
	 .CK_P_OUT                  ( CK_P_OUT_B0),
     .DATA_CTL_N                ( PHY_0_DATA_CTL),       /* four bits, one per lane */
     .CPT_CLK_SEL               ( PHY_0_CPT_CLK_SEL),
     .GENERATE_DDR_CK           ( PHY_0_GENERATE_DDR_CK),
     .GENERATE_DDR_DK           ( PHY_0_GENERATE_DDR_DK),  
     .BUFMR_DELAY               ( BUFMR_DELAY),
	 .PC_CLK_RATIO              ( PHY_CLK_RATIO),
     .DIFF_CK                   ( DIFF_CK),
     .DIFF_DK                   ( DIFF_DK),
     .DIFF_CQ                   ( DIFF_CQ),
     .CK_VALUE_D1               ( CK_VALUE_D1),
     .DK_VALUE_D1               ( DK_VALUE_D1),
     .LAST_BANK                 ( PHY_0_IS_LAST_BANK),
     .LANE_REMAP                ( PHY_0_LANE_REMAP),
     .IODELAY_GRP               ( IODELAY_GRP),
     .IODELAY_HP_MODE           ( IODELAY_HP_MODE),
     .GENERATE_CQ               ( PHY_0_GENERATE_CQ),
     .BYTE_GROUP_TYPE           ( BYTE_GROUP_TYPE_B0),  //input byte group

     .A_PI_FREQ_REF_DIV         ( PHY_0_A_PI_FREQ_REF_DIV),
     .MEMREFCLK_PERIOD          ( MEMREFCLK_PERIOD),
     .PC_MULTI_REGION           (PHY_MULTI_REGION),

     .A_PI_REFCLK_PERIOD        ( PHY_0_A_PI_REFCLK_PERIOD),
     .B_PI_REFCLK_PERIOD        ( PHY_0_B_PI_REFCLK_PERIOD),
     .C_PI_REFCLK_PERIOD        ( PHY_0_C_PI_REFCLK_PERIOD),
     .D_PI_REFCLK_PERIOD        ( PHY_0_D_PI_REFCLK_PERIOD),     

     .A_PO_REFCLK_PERIOD        ( PHY_0_A_PO_REFCLK_PERIOD),
     .B_PO_REFCLK_PERIOD        ( PHY_0_B_PO_REFCLK_PERIOD),
     .C_PO_REFCLK_PERIOD        ( PHY_0_C_PO_REFCLK_PERIOD),
     .D_PO_REFCLK_PERIOD        ( PHY_0_D_PO_REFCLK_PERIOD),

     .A_PO_OCLK_DELAY           ( PHY_0_A_PO_OCLK_DELAY),
     .B_PO_OCLK_DELAY           ( PHY_0_B_PO_OCLK_DELAY),
     .C_PO_OCLK_DELAY           ( PHY_0_C_PO_OCLK_DELAY),
     .D_PO_OCLK_DELAY           ( PHY_0_D_PO_OCLK_DELAY),
     
     .PO_FINE_DELAY             ( L_PHY_0_PO_FINE_DELAY),
     .PI_FINE_DELAY             ( L_PHY_0_PI_FINE_DELAY),

     .A_PO_COARSE_DELAY         ( A_PO_COARSE_DELAY_B0),     
     .B_PO_COARSE_DELAY         ( B_PO_COARSE_DELAY_B0),     
     .C_PO_COARSE_DELAY         ( C_PO_COARSE_DELAY_B0),    
     .D_PO_COARSE_DELAY         ( D_PO_COARSE_DELAY_B0),
     
     .A_PO_FINE_DELAY           ( A_PO_FINE_DELAY_B0), 
     .B_PO_FINE_DELAY           ( B_PO_FINE_DELAY_B0),
     .C_PO_FINE_DELAY           ( C_PO_FINE_DELAY_B0),             
     .D_PO_FINE_DELAY           ( D_PO_FINE_DELAY_B0),
     
     .A_PO_OCLKDELAY_INV        ( PHY_0_A_PO_OCLKDELAY_INV),
     .B_PO_OCLKDELAY_INV        ( PHY_0_B_PO_OCLKDELAY_INV),
     .C_PO_OCLKDELAY_INV        ( PHY_0_C_PO_OCLKDELAY_INV),
     .D_PO_OCLKDELAY_INV        ( PHY_0_D_PO_OCLKDELAY_INV),
     .TCQ                       (TCQ)
     
     
  )
  u_qdr_rld_phy_4lanes
 (
      .rst                      (rst),
      `ifdef CLK_SKEW_ON
      .phy_clk                  (phy_clk_skew1),
      .phy_ctl_clk              (phy_ctl_clk_skew1),
      .phy_ctl_wd               (phy_ctl_wd_phy_skew1),
      .phy_ctl_wr               (phy_ctl_wr_skew1),
      .mem_refclk               (mem_refclk_skew),
      .freq_refclk              (freq_refclk_skew),
     // .mem_refclk_div4          (mem_refclk_div4_skew),
      .sync_pulse               (sync_pulse_skew),
    `else
      .phy_clk                  (phy_clk),
	  .phy_clk_fast             (phy_clk_fast),
      .phy_ctl_clk              (_phy_clk),
      .phy_ctl_wd               (phy_ctl_wd_phy),
      .phy_ctl_wr               (_phy_ctl_wr),
      .mem_refclk               (mem_refclk),
      .freq_refclk              (freq_refclk),
      //.mem_refclk_div4          (mem_refclk_div4),
      .sync_pulse               (sync_pulse),
    `endif
    
      .ddr_clk                  (ddr_clk[7:0]),
      .idelay_ld                (idelay_ld),
      .idelay_ce                (idelay_ce[(1*48)-1:(48)*0]),
      .idelay_inc               (idelay_inc[(1*48)-1:(48)*0]),
      .idelay_cnt_in            (idelay_cnt_in[HIGHEST_LANE_B0*60-1:0]),
      .idelay_cnt_out           (idelay_cnt_out[HIGHEST_LANE_B0*60-1:0]),
      
      .phy_dout                 (phy_dout[HIGHEST_LANE_B0*80-1:0]),
      .phy_cmd_wr_en            (phy_cmd_wr_en),
      .phy_data_wr_en           (phy_data_wr_en),
      .phy_rd_en                (phy_rd_en),
      
       // phy control word signals
      
      .pll_lock                 (pll_lock),
      
      .phy_ctl_a_full           (_phy_ctl_a_full_p[0]),
      .phy_ctl_full             (_phy_ctl_full_p[0]),
      .phy_ctl_ready            (phy_ctl_ready_w[0]),
      .phy_write_calib          (phy_write_calib),
      .phy_read_calib           (phy_read_calib),
      .phy_ctl_empty            (phy_ctl_empty[0]),
      .phy_ctl_mstr_empty       (phy_ctl_mstr_empty),    
      .if_a_empty               (if_a_empty_v[0]),
      .if_empty                 (if_empty_v[0]),
      .if_full                  (if_full_v[0]),
      .of_empty                 (of_empty_v[0]),
      .of_ctl_full              (of_ctl_full_v[0]),
      .of_ctl_a_full            (of_ctl_a_full_v[0]), 
      .of_data_a_full           (of_data_a_full_v[0]),
      .of_data_full             (of_data_full_v[0]),
      .out_fifos_full           (out_fifos_full ),
      .phy_din                  (phy_din[HIGHEST_LANE_B0*80-1:0]),
      .I                        (I [HIGHEST_LANE_B0*12-1:0]),    // Read Data Q[35:0] and QVLD, tieoff extra 2-bits  
      .O                        (O[HIGHEST_LANE_B0*12-1:0]),
      .mem_dq_ts                (mem_dq_ts[HIGHEST_LANE_B0*12-1:0]),
      .sys_rst                  (sys_rst), // fabric drives as phaser_phy replaced with base_phaser 
      .rst_rd_clk               (rst_rd_clk),
      .Q_clk                    (cq_clk[3:0]),
      .Qn_clk                   (cqn_clk[3:0]),
      .cpt_clk_above            (2'b0), //no banks above
      .cpt_clk_n_above          (2'b0), //no banks above
      .cpt_clk_below            (cpt_clk_1),
      .cpt_clk_n_below          (cpt_clk_n_1),
      .cpt_clk                  (cpt_clk_0),
      .cpt_clk_n                (cpt_clk_n_0),

      .calib_sel                ({ calib_zero_inputs_int[0], calib_sel[1:0]}),
      .calib_in_common          (calib_in_common),
      .drive_on_calib_in_common (drive_on_calib_in_common_0),
      .po_coarse_enable         (po_coarse_enable),
      .po_edge_adv              (po_edge_adv), // fabric drives edge_adv togetherwith sync_pulse  
      .po_fine_enable           (po_fine_enable),
      .po_fine_inc              (po_fine_inc),
      .po_coarse_inc            (po_coarse_inc),
      .po_counter_load_en       (po_counter_load_en),
      .po_sel_fine_oclk_delay   (po_sel_fine_oclk_delay),
      .po_counter_load_val      (po_counter_load_val),
      .po_counter_read_en       (po_counter_read_en),
      .po_coarse_overflow       (po_coarse_overflow_w[0]),
      .po_fine_overflow         (po_fine_overflow_w[0]),
      .po_counter_read_val      (po_counter_read_val_w[0]),

      .pi_fine_enable           (pi_fine_enable),
      .pi_edge_adv              (pi_edge_adv),
      .pi_fine_inc              (pi_fine_inc),
      .pi_counter_load_en       (pi_counter_load_en),
      .pi_counter_read_en       (pi_counter_read_en),
      .pi_counter_load_val      (pi_counter_load_val),
      .pi_fine_overflow         (pi_fine_overflow_w[0]),
      .pi_counter_read_val      (pi_counter_read_val_w[0]),
      .po_dec_done              (po_dec_done),
      .po_inc_done              (po_inc_done),
      
      .po_delay_done            (po_delay_done_w[0]), 
      .ref_dll_lock             (ref_dll_lock_w[0]),  
      .rst_phaser_ref           (rst_phaser_ref),     
      .dbg_byte_lane            (dbg_byte_lane_0),   
      .dbg_phy_4lanes           (dbg_phy_4lanes_0)
);
end
else begin
   assign ref_dll_lock_w[0] = 1'b1;
   if ( HIGHEST_BANK > 0) begin
       assign phy_din[HIGHEST_LANE_B0*80-1:0] = 0;
       assign of_data_a_full_v[0]  = 0;
       assign of_data_full_v[0]    = 0;
       assign of_ctl_a_full_v[0]   = 0;
       assign of_ctl_full_v[0]     = 0;
       assign if_full_v[0]         = 0;
   end
       assign po_fine_overflow_w[0] = 0;
       assign po_coarse_overflow_w[0] = 0;
       assign po_fine_overflow_w[0] = 0;
       assign pi_fine_overflow_w[0] = 0;
       assign po_counter_read_val_w[0] = 0;
end

// phy_4lane_1 outputs 36-bit Write data and BW[3:0] control in write memory bank
if ( BYTE_LANES_B1 != 0) begin : qdr_rld_phy_4lanes_1

  mig_7series_v2_0_qdr_rld_phy_4lanes #(
     .MEMORY_TYPE               ( MEMORY_TYPE),
     .SIMULATION                ( SIMULATION),
     .PO_COARSE_BYPASS			(PO_COARSE_BYPASS),

     .CPT_CLK_CQ_ONLY           ( CPT_CLK_CQ_ONLY),
     .INTERFACE_TYPE            ( INTERFACE_TYPE),
	 .REFCLK_FREQ               ( REFCLK_FREQ),
	 .BUFG_FOR_OUTPUTS          ( BUFG_FOR_OUTPUTS),
	 .CLK_PERIOD                ( CLK_PERIOD),
     .PRE_FIFO                  ( PRE_FIFO),
     .BYTE_LANES                ( BYTE_LANES_B1),        /* four bits, one per lanes */
     .BITLANES_IN               ( BITLANES_IN_B1),
     .BITLANES_OUT              ( BITLANES_OUT_B1),
	 .CK_P_OUT                  ( CK_P_OUT_B1),
     .DATA_CTL_N                ( PHY_1_DATA_CTL),       /* four bits, one per lane  */
     .CPT_CLK_SEL               ( PHY_1_CPT_CLK_SEL),
     .GENERATE_DDR_CK           ( PHY_1_GENERATE_DDR_CK),
     .GENERATE_DDR_DK           ( PHY_1_GENERATE_DDR_DK),
     .BUFMR_DELAY               ( BUFMR_DELAY),
	 .PC_CLK_RATIO              ( PHY_CLK_RATIO),
     .DIFF_CK                   ( DIFF_CK),
     .DIFF_DK                   ( DIFF_DK),
     .DIFF_CQ                   ( DIFF_CQ),
     .CK_VALUE_D1               ( CK_VALUE_D1),
     .DK_VALUE_D1               ( DK_VALUE_D1),
     .LAST_BANK                 ( PHY_1_IS_LAST_BANK),
     .LANE_REMAP                ( PHY_1_LANE_REMAP),
     .IODELAY_GRP               ( IODELAY_GRP),
     .IODELAY_HP_MODE           ( IODELAY_HP_MODE),
     .BYTE_GROUP_TYPE           ( BYTE_GROUP_TYPE_B1),  // output byte_group
     .GENERATE_CQ               ( PHY_1_GENERATE_CQ),         

     .A_PI_FREQ_REF_DIV         ( PHY_1_A_PI_FREQ_REF_DIV),
     .MEMREFCLK_PERIOD          ( MEMREFCLK_PERIOD),
     .PC_MULTI_REGION           (PHY_MULTI_REGION),
    
     .A_PI_REFCLK_PERIOD        ( PHY_1_A_PI_REFCLK_PERIOD),
     .B_PI_REFCLK_PERIOD        ( PHY_1_B_PI_REFCLK_PERIOD),
     .C_PI_REFCLK_PERIOD        ( PHY_1_C_PI_REFCLK_PERIOD),
     .D_PI_REFCLK_PERIOD        ( PHY_1_D_PI_REFCLK_PERIOD),    
     
     .A_PO_REFCLK_PERIOD        ( PHY_1_A_PO_REFCLK_PERIOD),
     .B_PO_REFCLK_PERIOD        ( PHY_1_B_PO_REFCLK_PERIOD),
     .C_PO_REFCLK_PERIOD        ( PHY_1_C_PO_REFCLK_PERIOD),
     .D_PO_REFCLK_PERIOD        ( PHY_1_D_PO_REFCLK_PERIOD),
     .A_PO_OCLK_DELAY           ( PHY_1_A_PO_OCLK_DELAY),
     .B_PO_OCLK_DELAY           ( PHY_1_B_PO_OCLK_DELAY),
     .C_PO_OCLK_DELAY           ( PHY_1_C_PO_OCLK_DELAY),
     .D_PO_OCLK_DELAY           ( PHY_1_D_PO_OCLK_DELAY),
		     
     .PO_FINE_DELAY             ( L_PHY_1_PO_FINE_DELAY),
     .PI_FINE_DELAY             ( L_PHY_1_PI_FINE_DELAY),

      .A_PO_COARSE_DELAY         ( A_PO_COARSE_DELAY_B1),     
     .B_PO_COARSE_DELAY         ( B_PO_COARSE_DELAY_B1),     
     .C_PO_COARSE_DELAY         ( C_PO_COARSE_DELAY_B1),    
     .D_PO_COARSE_DELAY         ( D_PO_COARSE_DELAY_B1),
     
     .A_PO_FINE_DELAY           ( A_PO_FINE_DELAY_B1), 
     .B_PO_FINE_DELAY           ( B_PO_FINE_DELAY_B1),
     .C_PO_FINE_DELAY           ( C_PO_FINE_DELAY_B1),             
     .D_PO_FINE_DELAY           ( D_PO_FINE_DELAY_B1),
		     
     .A_PO_OCLKDELAY_INV        ( PHY_1_A_PO_OCLKDELAY_INV),
     .B_PO_OCLKDELAY_INV        ( PHY_1_B_PO_OCLKDELAY_INV),
     .C_PO_OCLKDELAY_INV        ( PHY_1_C_PO_OCLKDELAY_INV),
     .D_PO_OCLKDELAY_INV        ( PHY_1_D_PO_OCLKDELAY_INV),
     .TCQ                        (TCQ)
  )
  u_qdr_rld_phy_4lanes
 (
      .rst                      (rst),
     `ifdef CLK_SKEW_ON
      .phy_clk                  (phy_clk_skew2),
      .phy_ctl_clk              (phy_ctl_clk_skew2),
      .phy_ctl_wd               (phy_ctl_wd_phy_skew2),
      .phy_ctl_wr               (phy_ctl_wr_skew2),
      .mem_refclk               (mem_refclk_skew),
      .freq_refclk              (freq_refclk_skew),
      //.mem_refclk_div4          (mem_refclk_div4_skew),
      .sync_pulse               (sync_pulse_skew),
    `else
      .phy_clk                  (phy_clk),
	  .phy_clk_fast             (phy_clk_fast),
      .phy_ctl_clk              (_phy_clk),
      .phy_ctl_wd               ({phy_ctl_wd_phy[31:12], aux_in_[1], phy_ctl_wd_phy[7:0]}),
      .phy_ctl_wr               (_phy_ctl_wr),
      .mem_refclk               (mem_refclk),
      .freq_refclk              (freq_refclk),
      //.mem_refclk_div4          (mem_refclk_div4),
      .sync_pulse               (sync_pulse),
    `endif
      
      .ddr_clk                  (ddr_clk[15:8]),
      .idelay_ld                (idelay_ld),
      .idelay_ce                (idelay_ce[(2*48)-1:(48)*1]),
      .idelay_inc               (idelay_inc[(2*48)-1:(48)*1]),
      .idelay_cnt_in            (idelay_cnt_in[HIGHEST_LANE_B1*60+240-1:240]),
      .idelay_cnt_out           (idelay_cnt_out[HIGHEST_LANE_B1*60+240-1:240]),
      
      .phy_dout                 (phy_dout[HIGHEST_LANE_B1*80+320-1:320]),
      .phy_cmd_wr_en            (phy_cmd_wr_en),
      .phy_data_wr_en           (phy_data_wr_en),
      .phy_rd_en                (phy_rd_en),
      
      // phy control word signals
      
      .pll_lock                 (pll_lock),
      
      .phy_ctl_a_full           (_phy_ctl_a_full_p[1]),
      .phy_ctl_full             (_phy_ctl_full_p[1]),
      .phy_ctl_ready            (phy_ctl_ready_w[1]),
      .phy_write_calib          (phy_write_calib),
      .phy_read_calib           (phy_read_calib),
      .phy_ctl_empty            (phy_ctl_empty[1]),
      .phy_ctl_mstr_empty       (phy_ctl_mstr_empty),    
      .if_a_empty               (if_a_empty_v[1]),
      .if_empty                 (if_empty_v[1]),
      .if_full                  (if_full_v[1]),
      .of_empty                 (of_empty_v[1]),
      .of_ctl_full              (of_ctl_full_v[1]),
      .of_ctl_a_full            (of_ctl_a_full_v[1]), 
      .of_data_a_full           (of_data_a_full_v[1]),
      .of_data_full             (of_data_full_v[1]),
      .out_fifos_full           (out_fifos_full ),    
      .phy_din                  (phy_din[HIGHEST_LANE_B1*80+320-1:320]),
      .I                        (I [HIGHEST_LANE_B1*12+48-1:48]),     // 48'h0000_0000_0000 memory inputs in write bank 
      .O                        (O[HIGHEST_LANE_B1*12+48-1:48]),
      .mem_dq_ts                (mem_dq_ts[HIGHEST_LANE_B1*12+48-1:48]),
      .sys_rst                  (sys_rst), // Fabric drives as phaser_phy replaced with base_phaser
      .rst_rd_clk               (rst_rd_clk),
      .Q_clk                    (cq_clk[7:4]),
      .Qn_clk                   (cqn_clk[7:4]),
      .cpt_clk_above            (cpt_clk_0), 
      .cpt_clk_n_above          (cpt_clk_n_0), 
      .cpt_clk_below            (cpt_clk_2),
      .cpt_clk_n_below          (cpt_clk_n_2),
      .cpt_clk                  (cpt_clk_1),
      .cpt_clk_n                (cpt_clk_n_1),
      .calib_sel                ({calib_zero_inputs_int[1], calib_sel[1:0]}),
      .calib_in_common          (calib_in_common),
      .drive_on_calib_in_common (drive_on_calib_in_common_1),
      .po_coarse_enable         (po_coarse_enable),
      .po_fine_enable           (po_fine_enable),
      .po_edge_adv              (po_edge_adv),
      .po_fine_inc              (po_fine_inc),
      .po_coarse_inc            (po_coarse_inc),
      .po_counter_load_en       (po_counter_load_en),
      .po_sel_fine_oclk_delay   (po_sel_fine_oclk_delay),
      .po_counter_load_val      (po_counter_load_val),
      .po_counter_read_en       (po_counter_read_en),
      .po_coarse_overflow       (po_coarse_overflow_w[1]),
      .po_fine_overflow         (po_fine_overflow_w[1]),
      .po_counter_read_val      (po_counter_read_val_w[1]),

      .pi_edge_adv              (pi_edge_adv),
      .pi_fine_enable           (pi_fine_enable),
      .pi_fine_inc              (pi_fine_inc),
      .pi_counter_load_en       (pi_counter_load_en),
      .pi_counter_read_en       (pi_counter_read_en),
      .pi_counter_load_val      (pi_counter_load_val),
      .pi_fine_overflow         (pi_fine_overflow_w[1]),
      .pi_counter_read_val      (pi_counter_read_val_w[1]),
      .po_delay_done            (po_delay_done_w[1]),
      .po_dec_done              (po_dec_done),
      .po_inc_done              (po_inc_done),
      
      .ref_dll_lock             (ref_dll_lock_w[1]),
      .rst_phaser_ref           (rst_phaser_ref),
      .dbg_byte_lane            (dbg_byte_lane_1),    
      .dbg_phy_4lanes           (dbg_phy_4lanes_1)
);
end
else begin
   assign ref_dll_lock_w[1] = 1'b1; 
   if ( HIGHEST_BANK > 1)  begin
       assign phy_din[HIGHEST_LANE_B1*80+320-1:320] = 0;
       assign of_data_a_full_v[1]  = 0;
       assign of_data_full_v[1]    = 0;
       assign of_ctl_a_full_v[1]   = 0;
       assign of_ctl_full_v[1]     = 0;
       assign if_full_v[1]         = 0;
   end
       assign po_coarse_overflow_w[1] = 0;
       assign po_fine_overflow_w[1] = 0;
       assign pi_fine_overflow_w[1] = 0;
       assign po_counter_read_val_w[1] = 0;
end

// phy_4lane_2 outputs 19-bit Addr[18:0], R#, W#, DOFF# controls in Addr/Cmd memory bank
if ( BYTE_LANES_B2 != 0) begin : qdr_rld_phy_4lanes_2

  mig_7series_v2_0_qdr_rld_phy_4lanes #(
     .MEMORY_TYPE               ( MEMORY_TYPE),
     .SIMULATION                ( SIMULATION),
     .PO_COARSE_BYPASS			(PO_COARSE_BYPASS),

     .CPT_CLK_CQ_ONLY           ( CPT_CLK_CQ_ONLY),
     .INTERFACE_TYPE            ( INTERFACE_TYPE),
	 .REFCLK_FREQ               ( REFCLK_FREQ),
	 .BUFG_FOR_OUTPUTS          ( BUFG_FOR_OUTPUTS),
	 .CLK_PERIOD                ( CLK_PERIOD),
     .PRE_FIFO                  ( PRE_FIFO ),
     .BYTE_LANES                ( BYTE_LANES_B2),        /* four bits, one per lanes */
     .BITLANES_IN               ( BITLANES_IN_B2),
     .BITLANES_OUT              ( BITLANES_OUT_B2),
	 .CK_P_OUT                  ( CK_P_OUT_B2),
     .DATA_CTL_N                ( PHY_2_DATA_CTL),       /* four bits, one per lane */
     .CPT_CLK_SEL               ( PHY_2_CPT_CLK_SEL),
     .GENERATE_DDR_CK           ( PHY_2_GENERATE_DDR_CK),
     .GENERATE_DDR_DK           ( PHY_2_GENERATE_DDR_DK),
     .BUFMR_DELAY               ( BUFMR_DELAY),
	 .PC_CLK_RATIO              ( PHY_CLK_RATIO),
     .DIFF_CK                   ( DIFF_CK),
     .DIFF_DK                   ( DIFF_DK),
     .DIFF_CQ                   ( DIFF_CQ),
     .CK_VALUE_D1               ( CK_VALUE_D1),
     .DK_VALUE_D1               ( DK_VALUE_D1),
     .LAST_BANK                 ( PHY_2_IS_LAST_BANK),
     .LANE_REMAP                ( PHY_2_LANE_REMAP),
     .IODELAY_GRP               ( IODELAY_GRP),
     .IODELAY_HP_MODE           ( IODELAY_HP_MODE),
     .BYTE_GROUP_TYPE           ( BYTE_GROUP_TYPE_B2),   // output byte group
     .GENERATE_CQ               ( PHY_2_GENERATE_CQ),         

     .A_PI_FREQ_REF_DIV         ( PHY_2_A_PI_FREQ_REF_DIV),
     .MEMREFCLK_PERIOD          ( MEMREFCLK_PERIOD),
     .PC_MULTI_REGION           (PHY_MULTI_REGION),
     
     .A_PI_REFCLK_PERIOD        ( PHY_2_A_PI_REFCLK_PERIOD),
     .B_PI_REFCLK_PERIOD        ( PHY_2_B_PI_REFCLK_PERIOD),
     .C_PI_REFCLK_PERIOD        ( PHY_2_C_PI_REFCLK_PERIOD),
     .D_PI_REFCLK_PERIOD        ( PHY_2_D_PI_REFCLK_PERIOD),
     
     .A_PO_REFCLK_PERIOD        ( PHY_2_A_PO_REFCLK_PERIOD),
     .B_PO_REFCLK_PERIOD        ( PHY_2_B_PO_REFCLK_PERIOD),
     .C_PO_REFCLK_PERIOD        ( PHY_2_C_PO_REFCLK_PERIOD),
     .D_PO_REFCLK_PERIOD        ( PHY_2_D_PO_REFCLK_PERIOD),
     .A_PO_OCLK_DELAY           ( PHY_2_A_PO_OCLK_DELAY),
     .B_PO_OCLK_DELAY           ( PHY_2_B_PO_OCLK_DELAY),
     .C_PO_OCLK_DELAY           ( PHY_2_C_PO_OCLK_DELAY),
     .D_PO_OCLK_DELAY           ( PHY_2_D_PO_OCLK_DELAY),
     .PO_FINE_DELAY             ( L_PHY_2_PO_FINE_DELAY),
     .PI_FINE_DELAY             ( L_PHY_2_PI_FINE_DELAY),

     .A_PO_COARSE_DELAY         ( A_PO_COARSE_DELAY_B2),     
     .B_PO_COARSE_DELAY         ( B_PO_COARSE_DELAY_B2),     
     .C_PO_COARSE_DELAY         ( C_PO_COARSE_DELAY_B2),    
     .D_PO_COARSE_DELAY         ( D_PO_COARSE_DELAY_B2),
     
     .A_PO_FINE_DELAY           ( A_PO_FINE_DELAY_B2), 
     .B_PO_FINE_DELAY           ( B_PO_FINE_DELAY_B2),
     .C_PO_FINE_DELAY           ( C_PO_FINE_DELAY_B2),             
     .D_PO_FINE_DELAY           ( D_PO_FINE_DELAY_B2),
		     
     .A_PO_OCLKDELAY_INV        ( PHY_2_A_PO_OCLKDELAY_INV),
     .B_PO_OCLKDELAY_INV        ( PHY_2_B_PO_OCLKDELAY_INV),
     .C_PO_OCLKDELAY_INV        ( PHY_2_C_PO_OCLKDELAY_INV),
     .D_PO_OCLKDELAY_INV        ( PHY_2_D_PO_OCLKDELAY_INV),
     .TCQ                       (TCQ)
  )
  u_qdr_rld_phy_4lanes
  (
      .rst                      (rst),
     `ifdef CLK_SKEW_ON
      .phy_clk                  (phy_clk_skew3),
      .phy_ctl_clk              (phy_ctl_clk_skew3),
      .phy_ctl_wd               (phy_ctl_wd_phy_skew3),
      .phy_ctl_wr               (phy_ctl_wr_skew3),
      .mem_refclk               (mem_refclk_skew),
      .freq_refclk              (freq_refclk_skew),
      //.mem_refclk_div4          (mem_refclk_div4_skew),
      .sync_pulse               (sync_pulse_skew),
    `else
      .phy_clk                  (phy_clk),
	  .phy_clk_fast             (phy_clk_fast),
      .phy_ctl_clk              (_phy_clk),
      .phy_ctl_wd               ({phy_ctl_wd_phy[31:12], aux_in_[2], phy_ctl_wd_phy[7:0]}),
      .phy_ctl_wr               (_phy_ctl_wr),
      .mem_refclk               (mem_refclk),
      .freq_refclk              (freq_refclk),
     //.mem_refclk_div4          (mem_refclk_div4),
      .sync_pulse               (sync_pulse),
    `endif
      
      .ddr_clk                  (ddr_clk[23:16]),
      .idelay_ld                (idelay_ld),
      .idelay_ce                (idelay_ce[(3*48)-1:(48)*2]),
      .idelay_inc               (idelay_inc[(3*48)-1:(48)*2]),
      .idelay_cnt_in            (idelay_cnt_in[HIGHEST_LANE_B2*60+480-1:480]),
      .idelay_cnt_out           (idelay_cnt_out[HIGHEST_LANE_B2*60+480-1:480]),     
      .phy_dout                 (phy_dout[HIGHEST_LANE_B2*80+640-1:640]),
      .phy_cmd_wr_en            (phy_cmd_wr_en),
      .phy_data_wr_en           (phy_data_wr_en),
      .phy_rd_en                (phy_rd_en),
      
      // phy control word signals
      
      .pll_lock                 (pll_lock),
     
      .phy_ctl_a_full           (_phy_ctl_a_full_p[2]),
      .phy_ctl_full             (_phy_ctl_full_p[2]),
      .phy_ctl_ready            (phy_ctl_ready_w[2]),
      .phy_write_calib          (phy_write_calib),
      .phy_read_calib           (phy_read_calib),
      .phy_ctl_empty            (phy_ctl_empty[2]),
      .phy_ctl_mstr_empty       (phy_ctl_mstr_empty),    
      .if_a_empty               (if_a_empty_v[2]),
      .if_empty                 (if_empty_v[2]),
      .if_full                  (if_full_v[2]),
      .of_empty                 (of_empty_v[2]),
      .of_ctl_full              (of_ctl_full_v[2]),
      .of_ctl_a_full            (of_ctl_a_full_v[2]), 
      .of_data_a_full           (of_data_a_full_v[2]),
      .of_data_full             (of_data_full_v[2]),
      .out_fifos_full           (out_fifos_full ),    
      .phy_din                  (phy_din[HIGHEST_LANE_B2*80+640-1:640]),
      .I                        (I [HIGHEST_LANE_B2*12+96-1:96]),   // 48'h0000_0000_0000
      .O                        (O[HIGHEST_LANE_B2*12+96-1:96]),
      .mem_dq_ts                (mem_dq_ts[HIGHEST_LANE_B2*12+96-1:96]),
      .sys_rst                  (sys_rst), // Fabric drives as phaser_phy replaced with base_phaser
      .rst_rd_clk               (rst_rd_clk),
      .Q_clk                    (cq_clk[11:8]),
      .Qn_clk                   (cqn_clk[11:8]),
      .cpt_clk_above            (cpt_clk_1), 
      .cpt_clk_n_above          (cpt_clk_n_1), 
      .cpt_clk_below            (2'b0),//no banks below
      .cpt_clk_n_below          (2'b0),//no banks below
      .cpt_clk                  (cpt_clk_2),
      .cpt_clk_n                (cpt_clk_n_2),      
      .calib_sel                ({calib_zero_inputs_int[2], calib_sel[1:0]}),
      .calib_in_common          (calib_in_common),
      .drive_on_calib_in_common (drive_on_calib_in_common_2),
      .po_coarse_enable         (po_coarse_enable),
      .po_edge_adv              (po_edge_adv),
      .po_fine_enable           (po_fine_enable),
      .po_fine_inc              (po_fine_inc),
      .po_coarse_inc            (po_coarse_inc),
      .po_counter_load_en       (po_counter_load_en),
      .po_sel_fine_oclk_delay   (po_sel_fine_oclk_delay),
      .po_counter_load_val      (po_counter_load_val),
      .po_counter_read_en       (po_counter_read_en),
      .po_coarse_overflow       (po_coarse_overflow_w[2]),
      .po_fine_overflow         (po_fine_overflow_w[2]),
      .po_counter_read_val      (po_counter_read_val_w[2]),

      .pi_edge_adv              (pi_edge_adv),
      .pi_fine_enable           (pi_fine_enable),
      .pi_fine_inc              (pi_fine_inc),
      .pi_counter_load_en       (pi_counter_load_en),
      .pi_counter_read_en       (pi_counter_read_en),
      .pi_counter_load_val      (pi_counter_load_val),
      .pi_fine_overflow         (pi_fine_overflow_w[2]),
      .pi_counter_read_val      (pi_counter_read_val_w[2]),
       .po_delay_done            (po_delay_done_w[2]),
       .po_dec_done              (po_dec_done),
      .po_inc_done              (po_inc_done),
       
      .ref_dll_lock             (ref_dll_lock_w[2]),
      .rst_phaser_ref           (rst_phaser_ref),
      .dbg_byte_lane            (dbg_byte_lane_2), 
      .dbg_phy_4lanes           (dbg_phy_4lanes_2)
);
end
else begin
   assign ref_dll_lock_w[2] = 1'b1; 
   if ( HIGHEST_BANK > 2)  begin
       assign phy_din[HIGHEST_LANE_B2*80+640-1:640] = 0;
       assign of_data_a_full_v[2]  = 0;
       assign of_data_full_v[2]    = 0;
       assign of_ctl_a_full_v[2]   = 0;
       assign of_ctl_full_v[2]     = 0;
       assign if_full_v[2]         = 0;
   end
       assign po_coarse_overflow_w[2] = 0;
       assign po_fine_overflow_w[2] = 0;
       assign pi_fine_overflow_w[2] = 0;
       assign po_counter_read_val_w[2] = 0;
end
endgenerate


`ifdef SKIPME
// don't need this
always @(calib_sel) begin
        calib_sel_0  = 6'b000100;
        calib_sel_1  = 6'b100000;
        calib_sel_2  = 6'b100000;
        calib_sel_3  = 6'b100000;
        calib_sel_4  = 6'b100000;
        calib_sel_0 = { calib_sel[5:3], calib_zero_inputs_int[calib_sel[5:3],  calib_sel[1:0]};
        calib_sel_1 = { calib_sel[5:3], calib_zero_inputs_int[calib_sel[5:3],  calib_sel[1:0]};
        calib_sel_2 = { calib_sel[5:3], calib_zero_inputs_int[calib_sel[5:3],  calib_sel[1:0]};
        calib_sel_3 = { calib_sel[5:3], calib_zero_inputs_int[calib_sel[5:3],  calib_sel[1:0]};
        calib_sel_4 = { calib_sel[5:3], calib_zero_inputs_int[calib_sel[5:3],  calib_sel[1:0]};
end
`endif // SKIPME

always @(*) begin
      case (calib_sel[5:3]) 
      3'b000: begin
          po_coarse_overflow  = po_coarse_overflow_w[0];
          po_fine_overflow    = po_fine_overflow_w[0];
          po_counter_read_val = po_counter_read_val_w[0];
          pi_fine_overflow    = pi_fine_overflow_w[0];
          pi_counter_read_val = pi_counter_read_val_w[0];
        end
      3'b001: begin
          po_coarse_overflow  = po_coarse_overflow_w[1];
          po_fine_overflow    = po_fine_overflow_w[1];
          po_counter_read_val = po_counter_read_val_w[1];
          pi_fine_overflow    = pi_fine_overflow_w[1];
          pi_counter_read_val = pi_counter_read_val_w[1];
        end
      3'b010: begin
          po_coarse_overflow  = po_coarse_overflow_w[2];
          po_fine_overflow    = po_fine_overflow_w[2];
          po_counter_read_val = po_counter_read_val_w[2];
          pi_fine_overflow    = pi_fine_overflow_w[2];
          pi_counter_read_val = pi_counter_read_val_w[2];
        end
       default: begin 
          po_coarse_overflow  = 1'b0;
          po_fine_overflow    = 1'b0;
          po_counter_read_val = 6'b0;
          pi_fine_overflow    = 1'b0;
          pi_counter_read_val = 6'b0;
        end
       endcase
end

assign ref_dll_lock = ref_dll_lock_w[0] &  
                      ref_dll_lock_w[1] &  
                      ref_dll_lock_w[2]; 

endmodule // mc_phy
