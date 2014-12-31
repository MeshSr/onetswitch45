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
// \   \   \/     Version            : 1.4 
//  \   \         Application        : MIG
//  /   /         Filename           : qdr_phy_top.v
// /___/   /\     Date Last Modified : $date$
// \   \  /  \    Date Created       : Nov 18, 2008
//  \___\/\___\
//
//Device: 7 Series
//Design: QDRII+ SRAM
//
//Purpose:
//    This module
//  1. Instantiates all the modules used in the PHY
//
//Revision History:	12/10/2012  -Added logic to improve CQ_CQB capturing clock scheme.  
//                                  -Fixed dbg_pi_f_inc(dec),dbg_po_f_inc(dec) debug logic.
//			4/27/2013   - change  siganl "dbg_error_adj_latency" to "error_adj_latency". This signal will be asserted
//				      in FIXED_LATENCY_MODE == 1 and the target PHY_LATENCY is less than measured latency.
//                                  -  PI reset is connected to "rst_clk" which is stay asserted until CQ clock stable for 200 us.
//          7/30/2013   - Added PO_COARSE_BYPASS option.
////////////////////////////////////////////////////////////////////////////////


`timescale 1ps/1ps

(* X_CORE_INFO = "mig_7series_v2_0_qdriip_7Series, 2013.4" , CORE_GENERATION_INFO = "qdriip_7Series,mig_7series_v2_0,{LANGUAGE=Verilog, SYNTHESIS_TOOL=Vivado, LEVEL=PHY,  NO_OF_CONTROLLERS=1, INTERFACE_TYPE=QDRIIPLUS, CLK_PERIOD=2500, PHY_RATIO=2, CLKIN_PERIOD=5000, VCCAUX_IO=1.8V, MEMORY_PART=cy7c25652kv18-500bzc, DQ_WIDTH=36, FIXED_LATENCY_MODE=0, PHY_LATENCY=0, REFCLK_FREQ=200, DEBUG_PORT=OFF, INTERNAL_VREF=0, SYSCLK_TYPE=SINGLE_ENDED, REFCLK_TYPE=USE_SYSTEM_CLOCK, DCI_FOR_DATA=1}" *)
module mig_7series_v2_0_qdr_phy_top #
(
  parameter MEMORY_IO_DIR        = "UNIDIR",   // was named MEMORY_TYPE.
                                               // rename this to MEMORY_IO_DIR . 
                                               // this parameter is for the purpose of passing IO dirction.
  
  parameter BUFG_FOR_OUTPUTS   = "OFF",		   //  This option is for design not using OCLKDELAY to shift
                                               //  K clock.  To use this option, a different infrastructe clock
                                               //  scheme is needed. Consult Xilinx for support.
  parameter PO_COARSE_BYPASS   = "FALSE",
  parameter SIMULATION         = "FALSE",
  parameter CPT_CLK_CQ_ONLY    = "TRUE",
  parameter ADDR_WIDTH         = 19,            //Adress Width
  parameter DATA_WIDTH         = 72,            //Data Width
  parameter BW_WIDTH           = 8,             //Byte Write Width
  parameter BURST_LEN          = 4,             //Burst Length
  
  
  parameter CLK_PERIOD         = 2500,          //Memory Clk Period (ps)
  parameter nCK_PER_CLK        = 2,
  parameter REFCLK_FREQ        = 200.0,         //Reference Clk Feq for IODELAYs
  parameter NUM_DEVICES        = 2,             //Memory Devices
  parameter N_DATA_LANES       = 4,
  parameter FIXED_LATENCY_MODE = 0,             //Fixed Latency for data reads
  parameter PHY_LATENCY        = 0,             //Value for Fixed Latency Mode
  parameter MEM_RD_LATENCY     = 2.0,            
  
  parameter CLK_STABLE         = 2048,          //Cycles till CQ/CQ# is stable
  parameter IODELAY_GRP        = "IODELAY_MIG", //May be assigned unique name 
                                                // when mult IP cores in design
  parameter MEM_TYPE           = "QDR2PLUS",    //Memory Type (QDR2PLUS, QDR2)
  parameter RST_ACT_LOW        = 1,             //System Reset is active low
  parameter SIM_BYPASS_INIT_CAL    = "OFF",      // OFF or FAST
  
  parameter IBUF_LPWR_MODE     = "OFF",         //Input buffer low power mode
  parameter IODELAY_HP_MODE    = "ON",          //IODELAY High Performance Mode
  parameter CQ_BITS            = 1,             //clog2(NUM_DEVICES - 1)   
  parameter Q_BITS             = 7,             //clog2(DATA_WIDTH - 1)
  parameter DEVICE_TAPS        = 32,            // Number of taps in the IDELAY chain
  parameter TAP_BITS           = 5,             // clog2(DEVICE_TAPS - 1)
  parameter BUFMR_DELAY        = 500,
  parameter MASTER_PHY_CTL     = 0,             // The bank number where master PHY_CONTROL resides
  parameter PLL_LOC            = 4'h1,
  parameter INTER_BANK_SKEW    = 0,
  
//  parameter N_LANES         = 4,
//  parameter N_CTL_LANES     = 2,
  // five fields, one per possible I/O bank, 4 bits in each field, 
   // 1 per lane data=1/ctl=0
   parameter DATA_CTL_B0     = 4'hf,
   parameter DATA_CTL_B1     = 4'hf,
   parameter DATA_CTL_B2     = 4'hc,
   parameter DATA_CTL_B3     = 4'hf,
   parameter DATA_CTL_B4     = 4'hf,
   
   // this parameter specifies the location of the capture clock with respect
   // to read data.
   // Each byte refers to the information needed for data capture in the corresponding byte lane
   // Lower order nibble - is either 4'h1 or 4'h2. This refers to the capture clock in T1 or T2 byte lane
   // Higher order nibble - 4'h0 refers to clock present in the bank below the read data,
   //                       4'h1 refers to clock present in the same bank as the read data,
   //                       4'h2 refers to clock present in the bank above the read data.
   
   parameter CPT_CLK_SEL_B0 = 32'h12_12_11_11,
   parameter CPT_CLK_SEL_B1 = 32'h12_12_11_11,  
   parameter CPT_CLK_SEL_B2 = 32'h12_12_11_11,
   // defines the byte lanes in I/O banks being used in the interface
   // 1- Used, 0- Unused
   parameter BYTE_LANES_B0   = 4'b1111,
   parameter BYTE_LANES_B1   = 4'b1111,
   parameter BYTE_LANES_B2   = 4'b0011,
   parameter BYTE_LANES_B3   = 4'b0000,
   parameter BYTE_LANES_B4   = 4'b0000,
   
  parameter BYTE_GROUP_TYPE_B0 = 4'b1111,
  parameter BYTE_GROUP_TYPE_B1 = 4'b0000,
  parameter BYTE_GROUP_TYPE_B2 = 4'b0000,  
  parameter BYTE_GROUP_TYPE_B3 = 4'b0000, 
  parameter BYTE_GROUP_TYPE_B4 = 4'b0000, 
  
   
  // mapping for K clocks
  // this parameter needs to have an 8bit value per component, since the phy drives a K/K# clock pair to each memory it interfaces to
  // assuming a max. of 4 component interface. This parameter needs to be used in conjunction with NUM_DEVICES parameter which provides 
  // info. on the no. of components being interfaced to.
  // the 8 bit for each component is defined as follows: 
  // [7:4] - bank no. ; [3:0] - byte lane no. 
  
   // for now, PHY only supports a 3 component interface.
  
  parameter K_MAP  = 48'h00_00_00_00_00_11,
  parameter CQ_MAP = 48'h00_00_00_00_00_01,
  
  // mapping for CQ/CQ# clocks
  // this parameter needs to have a 4bit value per component. THis will be 4 bits per component
  // the same parameter is applicable to CQ# clocks as well, since they both need to be placed in the same bank.
  // assuming a max. of 4 component interface. This parameter needs to be used in conjunction with NUM_DEVICES parameter which provides 
  // info. on the no. of components being interfaced to.
  // the 4 bit for each component is defined as follows: 
  // [3:0] - bank no. of the map
  
  // for now, PHY only supports a 3 component interface.
  
  //parameter CQ_MAP = 12'h000, 
    
   // Mapping for address and control signals
   // The parameter contains the byte_lane and bit position information for 
   // a control signal. 
   // Each add/ctl bit will have 12 bits the assignments are
   // [3:0] - Bit position within a byte lane . 
   // [7:4] - Byte lane position within a bank. [5:4] have the byte lane position. 
    // [7:6] tied to 0 
   // [11:8] - Bank position. [10:8] have the bank position. [11] tied to zero . 
   
   parameter RD_MAP = 12'h218,
   parameter WR_MAP = 12'h219,
  
  // supports 22 bits of address bits 
   
   parameter ADD_MAP = 264'h217_216_21B_21A_215_214_213_212_211_210_209_208_207_206_20B_20A_205_204_203_202_201_200,
   
   parameter ADDR_CTL_MAP = 32'h00_00_21_20,  // for a max. of 3 banks
   
   //One parameter per data byte - 9bits per byte = 9*12
   parameter D0_MAP       = 108'h008_007_006_005_004_003_002_001_000,//byte 0 
   parameter D1_MAP       = 108'h008_007_006_005_004_003_002_001_000,//byte 1
   parameter D2_MAP       = 108'h008_007_006_005_004_003_002_001_000,//byte 2
   parameter D3_MAP       = 108'h008_007_006_005_004_003_002_001_000,//byte 3
   parameter D4_MAP       = 108'h008_007_006_005_004_003_002_001_000,//byte 4
   parameter D5_MAP       = 108'h008_007_006_005_004_003_002_001_000,//byte 5
   parameter D6_MAP       = 108'h008_007_006_005_004_003_002_001_000,//byte 6
   parameter D7_MAP       = 108'h008_007_006_005_004_003_002_001_000,//byte 7
   
   // byte writes for bytes 0 to 7 - 8*12
   parameter BW_MAP       = 96'h007_006_005_004_003_002_001_000,
   
   //One parameter per data byte - 9bits per byte = 9*12
   parameter Q0_MAP       = 108'h008_007_006_005_004_003_002_001_000,//byte 0 
   parameter Q1_MAP       = 108'h008_007_006_005_004_003_002_001_000,//byte 1
   parameter Q2_MAP       = 108'h008_007_006_005_004_003_002_001_000,//byte 2
   parameter Q3_MAP       = 108'h008_007_006_005_004_003_002_001_000,//byte 3
   parameter Q4_MAP       = 108'h008_007_006_005_004_003_002_001_000,//byte 4
   parameter Q5_MAP       = 108'h008_007_006_005_004_003_002_001_000,//byte 5
   parameter Q6_MAP       = 108'h008_007_006_005_004_003_002_001_000,//byte 6
   parameter Q7_MAP       = 108'h008_007_006_005_004_003_002_001_000,//byte 7
   
   // for each bank (B0 - B4), the validity of each bit within the byte lane is denoted by the following parameters
   // a 1 represents that the bit is chosen, a 0 represents an unused pin. 
   
   parameter BIT_LANES_B0    = 48'h1ff_3fd_1ff_1ff,            
   parameter BIT_LANES_B1    = 48'h000_000_000_000, 
   parameter BIT_LANES_B2    = 48'h000_000_000_000,
   parameter BIT_LANES_B3    = 48'h000_000_000_000, 
   parameter BIT_LANES_B4    = 48'h000_000_000_000,
  
  
  parameter DEBUG_PORT  = "ON", // Debug using Chipscope controls 
  parameter TCQ          = 100  //Register Delay
)
(

    // clocking and reset
  input                           clk,            // Fabric logic clock
  input                           rst_wr_clk,     // fabric reset based on PLL lock and system input reset.
  input                           clk_ref,        // Idelay_ctrl reference clock
                                                  // To hard PHY (external source)
  input                           clk_mem,        // Memory clock to hard PHY
  input                           freq_refclk,
  input                           pll_lock,
  input                           sync_pulse,
  
  output                          ref_dll_lock,
  input                           rst_phaser_ref,

  output wire                     rst_clk,          //generated based on read clocks being stable 
  input                           sys_rst,          //main write path reset
     
  //PHY Write Path Interface
  input                           wr_cmd0,          //wr command 0
  input                           wr_cmd1,          //wr command 1
  input       [ADDR_WIDTH-1:0]    wr_addr0,         //wr address 0
  input       [ADDR_WIDTH-1:0]    wr_addr1,         //wr address 1
  input                           rd_cmd0,          //rd command 0
  input                           rd_cmd1,          //rd command 1
  input       [ADDR_WIDTH-1:0]    rd_addr0,         //rd address 0
  input       [ADDR_WIDTH-1:0]    rd_addr1,         //rd address 1
  input       [DATA_WIDTH*2-1:0]  wr_data0,         //user write data 0
  input       [DATA_WIDTH*2-1:0]  wr_data1,         //user write data 1
  input       [BW_WIDTH*2-1:0]    wr_bw_n0,         //user byte writes 0
  input       [BW_WIDTH*2-1:0]    wr_bw_n1,        //user byte writes 1

  //PHY Read Path Interface 
  output wire                     init_calib_complete,         //Calibration complete	
  output                          error_adj_latency,  // stage 2 cal latency adjustment error  

  output wire                     rd_valid0,        //Read valid for rd_data0
  output wire                     rd_valid1,        //Read valid for rd_data1
  output wire [DATA_WIDTH*2-1:0]  rd_data0,         //Read data 0
  output wire [DATA_WIDTH*2-1:0]  rd_data1,         //Read data 1


  //Memory Interface
  output wire                     qdr_dll_off_n,    //QDR - turn off dll in mem
  output wire [NUM_DEVICES-1:0]   qdr_k_p,          //QDR clock K
  output wire [NUM_DEVICES-1:0]   qdr_k_n,          //QDR clock K#
  output wire [ADDR_WIDTH-1:0]    qdr_sa,           //QDR Memory Address
  output wire                     qdr_w_n,          //QDR Write 
  output wire                     qdr_r_n,          //QDR Read
  output wire [BW_WIDTH-1:0]      qdr_bw_n,         //QDR Byte Writes to Mem
  output wire [DATA_WIDTH-1:0]    qdr_d,            //QDR Data to Memory
  input       [DATA_WIDTH-1:0]    qdr_q,            //QDR Data from Memory
  input       [NUM_DEVICES-1:0]   qdr_cq_p,         //QDR echo clock CQ 
  input       [NUM_DEVICES-1:0]   qdr_cq_n,         //QDR echo clock CQ#
  
  //Chipscope Debug Signals
  output wire [7:0]               dbg_phy_status,          // phy status
 
 // uncomment the next two lines if need to debuf calibration
 // input                             dbg_SM_en,
 // input                             dbg_SM_No_Pause,
  
  output [8:0]                      dbg_po_counter_read_val,
  output [5:0]                      dbg_pi_counter_read_val,

  input                             dbg_phy_init_wr_only,
  input                             dbg_phy_init_rd_only,

  input [CQ_BITS-1:0]               dbg_byte_sel,
  input [Q_BITS-1:0]                dbg_bit_sel,
  input                             dbg_pi_f_inc,
  input                             dbg_pi_f_dec,
  input                             dbg_po_f_inc,
  input                             dbg_po_f_dec,
  input                             dbg_idel_up_all,
  input                             dbg_idel_down_all,
  input                             dbg_idel_up,
  input                             dbg_idel_down,
  output [TAP_BITS*DATA_WIDTH-1:0]  dbg_idel_tap_cnt,
  output [TAP_BITS-1:0]             dbg_idel_tap_cnt_sel,
  output reg [2:0]                  dbg_select_rdata,

  //Traffic Gen signals
  output  reg [8:0]                 dbg_align_rd0_r,
  output  reg [8:0]                 dbg_align_rd1_r,
  output  reg [8:0]                 dbg_align_fd0_r,
  output  reg [8:0]                 dbg_align_fd1_r,
  output  [DATA_WIDTH-1:0]          dbg_align_rd0,
  output  [DATA_WIDTH-1:0]          dbg_align_rd1,
  output  [DATA_WIDTH-1:0]          dbg_align_fd0,
  output  [DATA_WIDTH-1:0]          dbg_align_fd1,
  output [255:0]                    dbg_mc_phy,
  
  output [2:0]                      dbg_byte_sel_cnt,
  output [1:0]                      dbg_phy_wr_cmd_n,       //cs debug - wr command
  output [ADDR_WIDTH*4-1:0]         dbg_phy_addr,          //cs debug - address
  output [1:0]                      dbg_phy_rd_cmd_n,       //cs debug - rd command
  output [DATA_WIDTH*4-1:0]         dbg_phy_wr_data,        //cs debug - wr data
  output reg [255:0]                    dbg_wr_init ,           //cs debug - initialization logic
  output reg [255:0]                    dbg_rd_stage1_cal,      // stage 1 cal debug
  output reg [127:0]                    dbg_stage2_cal,         // stage 2 cal debug
  output [4:0]                      dbg_valid_lat,          // latency of the system
  output [N_DATA_LANES-1:0]         dbg_inc_latency,        // increase latency for dcb
  output [N_DATA_LANES-1:0]         dbg_error_max_latency  // stage 2 cal max latency error
  
);

//  localparam SIM_BYPASS_PHY_INIT_CAL =  "SKIP";
  localparam SIM_BYPASS_PHY_RD_INIT_CAL = (SIM_BYPASS_INIT_CAL == "FAST_AND_WRCAL") ? "FAST" : 
                                          (SIM_BYPASS_INIT_CAL == "SKIP_AND_WRCAL") ? "SKIP" : 
                                          SIM_BYPASS_INIT_CAL;
  
//  localparam SIM_BYPASS_PHY_WR_INIT_CAL =   (SIM_BYPASS_INIT_CAL == "FAST_AND_WRCAL") ? "FAST" : 
//                                         (SIM_BYPASS_INIT_CAL == "SKIP_AND_WRCAL") ? "SKIP_AND_WRCAL" : 
//                                          SIM_BYPASS_INIT_CAL;
  
  //Write Calibration parameters
  localparam OCAL_EN = ( ( (SIM_BYPASS_INIT_CAL == "FAST_AND_WRCAL") || 
                           (SIM_BYPASS_INIT_CAL == "SKIP_AND_WRCAL") ||
                                                   (SIM_BYPASS_INIT_CAL == "OFF") || 
                                                   (SIM_BYPASS_INIT_CAL == "NONE")) && 
                                                   (CLK_PERIOD <= 2500)) ? "ON": "OFF";


  // Width of each memory
  //localparam integer MEMORY_WIDTH = DATA_WIDTH / NUM_DEVICES;
  // no. of byte lanes used for data (read only or bidir)
   
  localparam   N_LANES           = (0+BYTE_LANES_B0[0]) + (0+BYTE_LANES_B0[1]) + (0+BYTE_LANES_B0[2]) + (0+BYTE_LANES_B0[3]) +  (0+BYTE_LANES_B1[0]) + (0+BYTE_LANES_B1[1]) + (0+BYTE_LANES_B1[2]) 
                                              + (0+BYTE_LANES_B1[3])  + (0+BYTE_LANES_B2[0]) + (0+BYTE_LANES_B2[1]) + (0+BYTE_LANES_B2[2]) + (0+BYTE_LANES_B2[3]); 
  localparam   PHY_0_IS_LAST_BANK   = ((BYTE_LANES_B1 != 0) || (BYTE_LANES_B2 != 0) || (BYTE_LANES_B3 != 0) || (BYTE_LANES_B4 != 0)) ?  "FALSE" : "TRUE";
  localparam   PHY_1_IS_LAST_BANK   = ((BYTE_LANES_B1 != 0) && ((BYTE_LANES_B2 != 0) || (BYTE_LANES_B3 != 0) || (BYTE_LANES_B4 != 0))) ?  "FALSE" : ((PHY_0_IS_LAST_BANK) ? "FALSE" : "TRUE");
  localparam   PHY_2_IS_LAST_BANK   = (BYTE_LANES_B2 != 0) && ((BYTE_LANES_B3 != 0) || (BYTE_LANES_B4 != 0)) ?  "FALSE" : ((PHY_0_IS_LAST_BANK || PHY_1_IS_LAST_BANK) ? "FALSE" : "TRUE");
  localparam HIGHEST_BANK        = (BYTE_LANES_B4 != 0 ? 5 : (BYTE_LANES_B3 != 0 ? 4 : (BYTE_LANES_B2 != 0 ? 3 :  (BYTE_LANES_B1 != 0  ? 2 : 1))));
  localparam HIGHEST_LANE_B0     =                        ((PHY_0_IS_LAST_BANK == "FALSE") ? 4 : BYTE_LANES_B0[3] ? 4 : BYTE_LANES_B0[2] ? 3 : BYTE_LANES_B0[1] ? 2 : BYTE_LANES_B0[0] ? 1 : 0);
  localparam HIGHEST_LANE_B1     = (HIGHEST_BANK > 2) ? 4 : ( BYTE_LANES_B1[3] ? 4 : BYTE_LANES_B1[2] ? 3 : BYTE_LANES_B1[1] ? 2 : BYTE_LANES_B1[0] ? 1 : 0);
  localparam HIGHEST_LANE_B2     = (HIGHEST_BANK > 3) ? 4 : ( BYTE_LANES_B2[3] ? 4 : BYTE_LANES_B2[2] ? 3 : BYTE_LANES_B2[1] ? 2 : BYTE_LANES_B2[0] ? 1 : 0);
  localparam HIGHEST_LANE_B3     = 0;
  localparam HIGHEST_LANE_B4     = 0;

  localparam HIGHEST_LANE        = (HIGHEST_LANE_B4 != 0) ? (HIGHEST_LANE_B4+16) : ((HIGHEST_LANE_B3 != 0) ? (HIGHEST_LANE_B3 + 12) : 
                                           ((HIGHEST_LANE_B2 != 0) ? (HIGHEST_LANE_B2 + 8)  : ((HIGHEST_LANE_B1 != 0) ? (HIGHEST_LANE_B1 + 4) : HIGHEST_LANE_B0)));
 
  localparam N_CTL_LANES = ((0+(!DATA_CTL_B0[0]) & BYTE_LANES_B0[0]) +
                           (0+(!DATA_CTL_B0[1]) & BYTE_LANES_B0[1]) +
                           (0+(!DATA_CTL_B0[2]) & BYTE_LANES_B0[2]) +
                           (0+(!DATA_CTL_B0[3]) & BYTE_LANES_B0[3])) +
                           ((0+(!DATA_CTL_B1[0]) & BYTE_LANES_B1[0]) +
                           (0+(!DATA_CTL_B1[1]) & BYTE_LANES_B1[1]) +
                           (0+(!DATA_CTL_B1[2]) & BYTE_LANES_B1[2]) +
                           (0+(!DATA_CTL_B1[3]) & BYTE_LANES_B1[3])) +
                           ((0+(!DATA_CTL_B2[0]) & BYTE_LANES_B2[0]) +
                           (0+(!DATA_CTL_B2[1]) & BYTE_LANES_B2[1]) +
                           (0+(!DATA_CTL_B2[2]) & BYTE_LANES_B2[2]) +
                           (0+(!DATA_CTL_B2[3]) & BYTE_LANES_B2[3])) +
                           ((0+(!DATA_CTL_B3[0]) & BYTE_LANES_B3[0]) +
                           (0+(!DATA_CTL_B3[1]) & BYTE_LANES_B3[1]) +
                           (0+(!DATA_CTL_B3[2]) & BYTE_LANES_B3[2]) +
                           (0+(!DATA_CTL_B3[3]) & BYTE_LANES_B3[3])) +
                           ((0+(!DATA_CTL_B4[0]) & BYTE_LANES_B4[0]) +
                           (0+(!DATA_CTL_B4[1]) & BYTE_LANES_B4[1]) +
                           (0+(!DATA_CTL_B4[2]) & BYTE_LANES_B4[2]) +
                           (0+(!DATA_CTL_B4[3]) & BYTE_LANES_B4[3]));
                           
  // Localparam to have the byte lane information for each byte 
  localparam CALIB_BYTE_LANE = {Q7_MAP[5:4],Q6_MAP[5:4],
                              Q5_MAP[5:4],Q4_MAP[5:4],Q3_MAP[5:4],
                              Q2_MAP[5:4],Q1_MAP[5:4],Q0_MAP[5:4]};
  // localparam to have the bank information for each byte 
  localparam CALIB_BANK = {Q7_MAP[10:8],Q6_MAP[10:8],
                           Q5_MAP[10:8],Q4_MAP[10:8],Q3_MAP[10:8],
                           Q2_MAP[10:8],Q1_MAP[10:8],Q0_MAP[10:8]}; 
                
  // Localparam to have the byte lane information for each write data byte 
  localparam OCLK_CALIB_BYTE_LANE = {D7_MAP[5:4],D6_MAP[5:4],
                              	     D5_MAP[5:4],D4_MAP[5:4],D3_MAP[5:4],
                                     D2_MAP[5:4],D1_MAP[5:4],D0_MAP[5:4]};
  // localparam to have the bank information for each write data byte 
  localparam OCLK_CALIB_BANK = {D7_MAP[10:8],D6_MAP[10:8],
                           	D5_MAP[10:8],D4_MAP[10:8],D3_MAP[10:8],
                           	D2_MAP[10:8],D1_MAP[10:8],D0_MAP[10:8]}; 
                
  localparam PRE_FIFO          = "TRUE";
  localparam PO_FINE_DELAY  = (PO_COARSE_BYPASS == "FALSE") ? 60:0;
  localparam PI_FINE_DELAY     = 33;
  
  //Starting values for counters used to enforce minimum time between PO/PI
  //adjustments (7 max value supported here)
  localparam [2:0] PO_ADJ_GAP = (SIM_BYPASS_INIT_CAL == "SKIP" ||
                                 SIM_BYPASS_INIT_CAL == "FAST") ? 
							     3'd0 : 3'd7;
  localparam [2:0] PI_ADJ_GAP = PO_ADJ_GAP;
  
   // amount of total delay required for Address and controls                               
  localparam ADDR_CTL_90_SHIFT = ((MEMORY_IO_DIR == "UNIDIR") && 
                                  (BURST_LEN == 2)) ? 0 : (CLK_PERIOD/4);
                                  
  // number of bits for window size measurements
  localparam WIN_SIZE         = 6;
  localparam SIMULATE_CHK_WIN = "FALSE";
  
  // Function to generate IN/OUT parameters from BYTE_LANES parameter
  function [47:0] calc_phy_bitlanes_in_out;
    input [47:0]  bit_lanes;
    input [3:0]   byte_type;
    input         calc_phy_in;
    integer       z, y;
    begin
      calc_phy_bitlanes_in_out = 'b0;
      for (z = 0; z < 4; z = z + 1) begin
        for (y = 0; y < 12; y = y + 1) begin
          if ((byte_type[z])== 1) //INPUT
            if (calc_phy_in)
              calc_phy_bitlanes_in_out[(z*12)+y] = bit_lanes[(z*12)+y];
            else
              calc_phy_bitlanes_in_out[(z*12)+y] = 1'b0;
          else //OUTPUT
            if (calc_phy_in)
              calc_phy_bitlanes_in_out[(z*12)+y] = 1'b0;
            else
              calc_phy_bitlanes_in_out[(z*12)+y] = bit_lanes[(z*12)+y];
        end
      end
    end 
  endfunction
  
  //Calculate Phy parameters
  localparam BITLANES_IN_B0  = calc_phy_bitlanes_in_out(BIT_LANES_B0, BYTE_GROUP_TYPE_B0, 1);
  localparam BITLANES_IN_B1  = calc_phy_bitlanes_in_out(BIT_LANES_B1, BYTE_GROUP_TYPE_B1, 1);
  localparam BITLANES_IN_B2  = calc_phy_bitlanes_in_out(BIT_LANES_B2, BYTE_GROUP_TYPE_B2, 1);
  localparam BITLANES_IN_B3  = calc_phy_bitlanes_in_out(BIT_LANES_B3, BYTE_GROUP_TYPE_B3, 1);
  localparam BITLANES_IN_B4  = calc_phy_bitlanes_in_out(BIT_LANES_B4, BYTE_GROUP_TYPE_B4, 1);
             
  localparam BITLANES_OUT_B0  = calc_phy_bitlanes_in_out(BIT_LANES_B0, BYTE_GROUP_TYPE_B0, 0);
  localparam BITLANES_OUT_B1  = calc_phy_bitlanes_in_out(BIT_LANES_B1, BYTE_GROUP_TYPE_B1, 0);
  localparam BITLANES_OUT_B2  = calc_phy_bitlanes_in_out(BIT_LANES_B2, BYTE_GROUP_TYPE_B2, 0);
  localparam BITLANES_OUT_B3  = calc_phy_bitlanes_in_out(BIT_LANES_B3, BYTE_GROUP_TYPE_B3, 0);
  localparam BITLANES_OUT_B4  = calc_phy_bitlanes_in_out(BIT_LANES_B4, BYTE_GROUP_TYPE_B4, 0);
  //*************************************************************************************************************
  //Function to compute which byte lanes have a write clock (K) and which don't
  //this is needed only when doing write calibration
  //outputs a vector that indicates a byte lane has a DK clock (1) or it 
  //doesn't (0)
  function [7:0] calc_write_clock_loc;
    input [2:0]  ck_cnt;         //How many DK's to go through?
    input [3:0]  byte_lane_cnt;  //How many data lanes to go through?
    input [23:0] bank;       //bank location for the data
    input [15:0] byte_lane;  //byte lane location for data
    input [47:0] write_clock;//DK locations, Bank and Byte lane
    integer       x, y;
    begin
      calc_write_clock_loc = 'b0;
      y = 0;
      for (x = 0; x < ck_cnt; x = x + 1) //step through all K locations
            for (y = 0; y < byte_lane_cnt; y = y + 1) //step through all byte lanes
                  if (bank[(y*3)+:3]== write_clock[((x*8)+4)+:3] &&
                      byte_lane[(y*2)+:2] == write_clock[(x*8)+:2])
                    //If true the given byte lane contains a K clock
                        calc_write_clock_loc[y] = 1'b1;
    end //function end
  endfunction

  localparam CK_WIDTH = NUM_DEVICES;
  localparam BYTE_LANE_WITH_DK = calc_write_clock_loc (CK_WIDTH, N_DATA_LANES, 
                                                     OCLK_CALIB_BANK, 
                                                     OCLK_CALIB_BYTE_LANE,
                                                     K_MAP);
                 
  //Wire Delcarations             

  reg                                  dbg_pi_f_inc_r;
  reg                                  dbg_pi_f_dec_r;
  reg                                  dbg_po_f_inc_r;
  reg                                  dbg_po_f_dec_r;

 // wire                                 dbg_SM_en;
  //wire [255:0]                         dbg_mc_phy;
  wire [767:0]                         dbg_phy_4lanes;
  reg  [19:0]                          dbg_idly_tap_counts;
  wire [3071:0]                        dbg_byte_lane;
  wire                                 dbg_next_byte;
 // added for connecting driverless bits to 0 for OOC flow

  wire [255:0]                    dbg_wr_init_tmp ;           //cs debug - initialization logic
  wire [255:0]                    dbg_rd_stage1_cal_tmp;      // stage 1 cal debug
  wire [127:0]                    dbg_stage2_cal_tmp;         // stage 2 cal debug
 
  wire [1:0]                           int_rd_cmd_n;
  wire [nCK_PER_CLK*2*ADDR_WIDTH-1:0]  iob_addr;
  wire [nCK_PER_CLK*2-1:0]             iob_wr_n;
  wire [nCK_PER_CLK*2-1:0]             iob_rd_n;
  wire [nCK_PER_CLK*2*DATA_WIDTH-1:0]  iob_wdata;
  wire [nCK_PER_CLK*2*BW_WIDTH-1:0]    iob_bw;
  wire                                 iob_dll_off_n;
  wire [5:0]                           pi_stg2_reg_l; 
  wire [5:0]                           po_stg2_reg_l;
  wire [5*DATA_WIDTH-1:0]              dlyval_dq;
  wire [5:0]                           ctl_lane_cnt;  // max. 3 byte groups               
  wire [2:0]                           edge_cal_byte_cnt;      // max 8 byte groups
  wire [CQ_BITS-1:0]                   pi_stg2_rdlvl_cnt;  
  wire [CQ_BITS-1:0]                   po_stg2_rdlvl_cnt;
  reg  [5:0]                           byte_sel_cnt;
  wire [HIGHEST_LANE*80-1:0]           phy_din;
  wire [HIGHEST_LANE*80-1:0]           phy_dout;
  reg  [5:0]                           calib_sel;
  reg [HIGHEST_BANK-1:0]               calib_zero_inputs;
  wire [nCK_PER_CLK*2*DATA_WIDTH-1:0]  rd_data_map;
  wire [(HIGHEST_LANE*12)-1:0]         O;   // input coming from mc_phy to drive out qdr output signals
  wire [(HIGHEST_LANE*12)-1:0]         I ;
  wire [HIGHEST_BANK*240-1:0]          idelay_cnt_in;
  wire [8:0]                           po_counter_load_val;
  wire [5:0]                           pi_counter_load_val;
  wire [8:0]                         po_counter_read_val;
  wire [5:0]                         pi_counter_read_val;

  wire                                 rdlvl_stg1_start; 
  wire                                 cal_stage2_start;
  wire                                 edge_adv_cal_start;
  wire                                 edge_adv_cal_done;
  wire                                 rdlvl_stg1_done;
  wire                                 io_fifo_rden_cal_done;
  reg                                  calib_in_common;
  reg                                  po_fine_enable;
  reg                                  po_fine_inc;
  wire                                 po_en_stg2_f;
  wire                                 po_stg2_f_incdec;
  wire                                 po_dec_done;
  wire                                 po_inc_done;
  wire                                 po_cnt_dec;
  wire                                 po_cnt_inc;
  wire                                 pi_dec_done;
  wire                                 po_delay_done;
   
  wire [1:0]                          wrcal_byte_sel;
   
  wire                                 pi_edge_adv;
  reg                                  pi_edge_adv_2r;
  reg                                  pi_edge_adv_r;
  wire [(HIGHEST_BANK*4)-1:0]          cq_clk;
  wire [(HIGHEST_BANK*4)-1:0]          cqn_clk;
  wire [HIGHEST_BANK*8-1:0]            ddr_clk;  
  wire [31:0]                          phy_ctl_wd;
  wire                                 of_cmd_wr_en;
  wire                                 of_data_wr_en;
  wire                                 phy_ctl_ready;
  wire                                 phy_ctl_full;
  wire                                 init_done;  
  wire                                 read_cal_done;  
  wire                                 cal1_rdlvl_restart;
  wire                                 idelay_ld;
  wire [(HIGHEST_LANE*12)-1:0]         idelay_ce;
  wire [(HIGHEST_LANE*12)-1:0]         idelay_inc;
  wire [HIGHEST_BANK*240-1:0]          idelay_cnt_out;
  
  reg                                  dbg_phy_pi_fine_inc;
  reg                                  dbg_phy_pi_fine_enable;
  reg                                  dbg_phy_po_fine_inc;
  reg                                  dbg_phy_po_fine_enable;
  reg                                  dbg_phy_po_co_inc;
  reg                                  dbg_phy_po_co_enable;
  //wire                                 dbg_phy_pi_fine_overflow;
  //wire                                 dbg_phy_po_fine_overflow;
  
  //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
  // write path signals
  

  //wire [TAP_BITS*DATA_WIDTH-1:0]   dbg_cpt_first_edge_cnt;
  //wire [TAP_BITS*DATA_WIDTH-1:0]   dbg_cpt_second_edge_cnt;
  
  // read path signals
  

  
  
  wire                           vio_win_bit_select_dec;
  wire                           vio_win_bit_select_inc;
  wire                           vio_sel_rise_chk;
  wire                           dbg_win_start;
  wire                           dbg_win_dump;
  wire [6:0]                     dbg_win_bit_select;
  wire                           dbg_win_active;
  wire                           dbg_win_dump_active;
  wire                           dbg_win_clr_error;
  wire [6:0]                     dbg_win_current_bit;
  wire [3:0]                     dbg_win_current_byte;
  wire [6:0]                     dbg_current_bit_ram_out;
  wire [WIN_SIZE-1:0]            dbg_win_left_ram_out;
  wire [WIN_SIZE-1:0]            dbg_win_right_ram_out;
  wire                           dbg_win_inc;
  wire                           dbg_win_dec;
  wire                           sim_win_start;
  wire                           sim_win_dump;
  wire  [N_DATA_LANES-1:0]        phase_valid;
  wire                           wrcal_en ;
  wire                           wrlvl_po_f_inc;
  wire                           wrlvl_po_f_dec;
  reg                            rd_valid0_r;
  reg                            rd_valid1_r;
  
  // rst_stg1, rst_stg2 are added to improve timing to reduce fanout delay.                               
 (* max_fanout = 50 *) reg rst_stg1 /* synthesis syn_maxfan = 20 */;
 (* max_fanout = 50 *) reg rst_stg2 /* synthesis syn_maxfan = 20 */;
  
  reg [2:0]                      dbg_select_rdata_r1;
  reg [2:0]                      dbg_select_rdata_r2;
  wire                           wrlvl_calib_in_common;
  wire                           po_sel_fine_oclk_delay;
  wire [31:0]                    dbg_rdphy_top;


//comment the next 5 lines if need to debug write calibration
// and uncomment the same signal names in the port list.
 wire                             dbg_SM_en;
 wire                             dbg_SM_No_Pause;

 wire phy_ctl_a_full;
 wire of_ctl_full;
 wire of_data_full;
 wire phy_ctl_wr;
 wire if_empty;
 wire if_rden;
 wire pi_en_stg2_f;
 wire pi_stg2_f_incdec;
 wire pi_stg2_load;
 wire po_stg2_load;
 wire if_a_empty;
 wire of_ctl_a_full;
 wire of_data_a_full;


assign 	dbg_SM_en = 1'b0;
assign  dbg_SM_No_Pause	= 1'b1;

  
  //simple bus to indicate phy status
  assign dbg_phy_status[0] = rst_wr_clk;
  assign dbg_phy_status[1] = io_fifo_rden_cal_done;
  assign dbg_phy_status[2] = init_done;
  assign dbg_phy_status[3] = rdlvl_stg1_start;
  assign dbg_phy_status[4] = edge_adv_cal_done;
  assign dbg_phy_status[5] = cal_stage2_start;
  assign dbg_phy_status[6] = cal_stage2_start & init_calib_complete;
  assign dbg_phy_status[7] = init_calib_complete;
  assign dbg_byte_sel_cnt   = byte_sel_cnt;

  //debug signals to adjust the fine_inc and fine_enable controls on the phasers
  always @(posedge clk) begin
    if (rst_clk) begin
      dbg_pi_f_inc_r         <= #TCQ 1'b0;
      dbg_pi_f_dec_r         <= #TCQ 1'b0;

      dbg_po_f_inc_r         <= #TCQ 1'b0;
      dbg_po_f_dec_r         <= #TCQ 1'b0;

      dbg_phy_po_fine_inc    <= #TCQ 1'b0;
      dbg_phy_po_fine_enable <= #TCQ 1'b0;
    end else begin
      //phaser_in controls

      //register chipscope controls for better timing
      dbg_pi_f_inc_r       <= #TCQ dbg_pi_f_inc;
      dbg_pi_f_dec_r       <= #TCQ dbg_pi_f_dec;

      //generate one clock pulse if VIO debug toggle the dbg_pi_f_inc or dbg_pi_f_dec
      dbg_phy_pi_fine_inc    <= #TCQ ~dbg_pi_f_inc_r  & dbg_pi_f_inc;
      dbg_phy_pi_fine_enable <= #TCQ ( ~dbg_pi_f_inc_r & dbg_pi_f_inc) | (~dbg_pi_f_dec_r & dbg_pi_f_dec);
      
      //phaser_out controls               
      dbg_po_f_inc_r       <= #TCQ dbg_po_f_inc;
      dbg_po_f_dec_r       <= #TCQ dbg_po_f_dec;

      //generate one clock pulse if VIO debug toggle the dbg_po_f_inc or dbg_po_f_dec

      dbg_phy_po_fine_inc       <= #TCQ ~dbg_po_f_inc_r & dbg_po_f_inc;
      dbg_phy_po_fine_enable    <= #TCQ (~dbg_po_f_inc_r & dbg_po_f_inc) | (~dbg_po_f_dec_r & dbg_po_f_dec);
      
     // dbg_phy_po_fine_inc    <= wrlvl_po_f_inc;
     // dbg_phy_po_fine_enable <= wrlvl_po_f_inc | wrlvl_po_f_dec;
      dbg_phy_po_co_inc         <= #TCQ 1'b0; //support coarse tap control later
      dbg_phy_po_co_enable      <= #TCQ 1'b0;
    end
  end
  assign idelay_ld = (rdlvl_stg1_done) ? 1'b0 : 1'b1;
  
  assign dbg_po_counter_read_val = po_counter_read_val;
  assign dbg_pi_counter_read_val = pi_counter_read_val;

  //***************************************************************************
  // MUX select logic to select current byte undergoing calibration
  // Use DQS_CAL_MAP to determine the correlation between the physical
  // byte numbering, and the byte numbering within the hard PHY
  //***************************************************************************  

  always @(posedge clk) begin
    if (rst_clk) begin
      byte_sel_cnt    <= #TCQ 'd0;
      calib_in_common <= #TCQ 1'b0;
    end else if (!po_dec_done && PO_COARSE_BYPASS == "FALSE" ) begin
      calib_in_common <= #TCQ 1'b1; //all byte lanes adjusted together

    end else if (!po_inc_done && PO_COARSE_BYPASS == "TRUE") begin
      calib_in_common <= #TCQ 1'b1; //all byte lanes adjusted together

    end else if (wrlvl_calib_in_common) begin //all byte lanes adjusted together in OCLK cal
    
    //  this portion of logic needs to be change to accomodate if there are 2 x18 components which means there
    //  are two K clocks.. We need to calibrate two times. "0 1"  "2  3"
    
      byte_sel_cnt    <= #TCQ 'd0;
      calib_in_common <= #TCQ 1'b0; 
    end else if (!po_delay_done) begin
      byte_sel_cnt    <= #TCQ 'd0;
      calib_in_common <= #TCQ 1'b0;
    end else if (!pi_dec_done) begin
      byte_sel_cnt    <= #TCQ  pi_stg2_rdlvl_cnt  ; 
      calib_in_common <= #TCQ 1'b0;
    end else if (!rdlvl_stg1_done) begin
      byte_sel_cnt    <= #TCQ  pi_stg2_rdlvl_cnt  ;
      calib_in_common <= #TCQ 1'b0;
    end else if (DEBUG_PORT == "ON" &&
                (dbg_phy_init_wr_only || dbg_phy_init_rd_only)) begin
      //place to allow us to modify the phaser_in/phaser_out taps after 
      //calibration and look at the data
      byte_sel_cnt    <= #TCQ dbg_byte_sel;
      calib_in_common <= #TCQ 1'b0;
    end else if (!init_calib_complete) begin
      byte_sel_cnt    <= #TCQ edge_cal_byte_cnt;
      calib_in_common <= #TCQ 1'b0;
    end else begin // init_calib_complete
      byte_sel_cnt    <= #TCQ (DEBUG_PORT == "ON") ? dbg_byte_sel : 'b0;
      calib_in_common <= #TCQ 1'b0;
    end 
  end
  
// verilint STARC-2.2.3.3 off
  always @(posedge clk) begin
    if (rst_clk || (DEBUG_PORT == "OFF" & init_calib_complete)) begin
      calib_sel         <= #TCQ 6'b000100;
      calib_zero_inputs <= #TCQ {HIGHEST_BANK{1'b1}};
    end else begin
      calib_sel[2]      <= #TCQ 1'b0;

      if (init_calib_complete) begin // READ PATH
        calib_sel[1:0]     <= #TCQ CALIB_BYTE_LANE[(byte_sel_cnt*2)+:2];
        calib_sel[5:3]     <= #TCQ CALIB_BANK[(byte_sel_cnt*3)+:3];
        calib_zero_inputs  <= #TCQ {HIGHEST_BANK{1'b1}};
        calib_zero_inputs[CALIB_BANK[(byte_sel_cnt*3)+:3]] <= #TCQ 1'b0;

      end else if (wrcal_en) begin
        calib_sel[1:0]     <= #TCQ OCLK_CALIB_BYTE_LANE[(wrcal_byte_sel*2)+:2];
        calib_sel[5:3]     <= #TCQ OCLK_CALIB_BANK[(wrcal_byte_sel*3)+:3];
        calib_zero_inputs  <= #TCQ {HIGHEST_BANK{1'b1}};
        calib_zero_inputs[OCLK_CALIB_BANK[(wrcal_byte_sel*3)+:3]] <= #TCQ 1'b0;
         
      end else if (!init_calib_complete && pi_dec_done) begin
        calib_sel[1:0]     <= #TCQ CALIB_BYTE_LANE[(byte_sel_cnt*2)+:2];
        calib_sel[5:3]     <= #TCQ CALIB_BANK[(byte_sel_cnt*3)+:3];
        calib_zero_inputs  <= #TCQ {HIGHEST_BANK{1'b1}};
        calib_zero_inputs[CALIB_BANK[(byte_sel_cnt*3)+:3]] <= #TCQ 1'b0;
         
      end else if (po_delay_done && !pi_dec_done) begin
        // performing READ leveling.   The calib_zero_inputs of the READ's data 
        // bank needs to set to 0 and only let the po_fine_enable reaches the 
        // PO of read's data bank. The po_fine_enable to PO of write data banks are forced to zero
        // because the calib_zero_inputs of teh WRITE's data bank is force to ONE.
        // 
        calib_sel[1:0]     <= #TCQ CALIB_BYTE_LANE[(byte_sel_cnt*2)+:2];
        calib_sel[2]       <= #TCQ 'b0;
        calib_sel[5:3]     <= #TCQ CALIB_BANK[(byte_sel_cnt*3)+:3]; //bank
        calib_zero_inputs  <= #TCQ {HIGHEST_BANK{1'b1}};
        calib_zero_inputs[CALIB_BANK[(byte_sel_cnt*3)+:3]] <= #TCQ 1'b0;
        
        
      end else if (!po_inc_done && PO_COARSE_BYPASS == "TRUE") begin
        calib_sel[1:0]     <= #TCQ ADDR_CTL_MAP[0+:2];
        calib_sel[2]       <= #TCQ 'b0;
        calib_sel[5:3]     <= #TCQ ADDR_CTL_MAP[4+:3];
        calib_zero_inputs  <= #TCQ {HIGHEST_BANK{1'b0}};


        
         
      end else if (po_dec_done && !po_delay_done) begin
        calib_sel[1:0]     <= #TCQ ADDR_CTL_MAP[(byte_sel_cnt*8)+:2];
        calib_sel[5:3]     <= #TCQ ADDR_CTL_MAP[((byte_sel_cnt*8)+4)+:3];
        calib_zero_inputs  <= #TCQ {HIGHEST_BANK{1'b1}};
        calib_zero_inputs[ADDR_CTL_MAP[((byte_sel_cnt*8)+4)+:3]] <= #TCQ 1'b0;
      
      end else if (!po_dec_done && PO_COARSE_BYPASS == "FALSE") begin
        calib_sel[1:0]     <= #TCQ ADDR_CTL_MAP[0+:2];
        calib_sel[2]       <= #TCQ 'b0;
        calib_sel[5:3]     <= #TCQ ADDR_CTL_MAP[4+:3];
        calib_zero_inputs  <= #TCQ {HIGHEST_BANK{1'b0}};

     end   
    end
  end
	// verilint STARC-2.2.3.3 on
  // register pi_edge_adv to track register stages in calib_sel logic
  always @ (posedge clk) begin
     if (rst_clk) begin
       pi_edge_adv_r  <= #TCQ 0;
       pi_edge_adv_2r <= #TCQ 0;
     end else begin
       pi_edge_adv_r  <= #TCQ pi_edge_adv;
       pi_edge_adv_2r <= #TCQ pi_edge_adv_r;  
     end
  end 
    
  
  always @ (posedge clk) begin
    if (rst_clk) begin
            po_fine_enable <= #TCQ 1'b0;
      po_fine_inc    <= #TCQ 1'b0;
    end else if (!po_dec_done  && PO_COARSE_BYPASS == "FALSE") begin
        // decrement PO's stage 2 to the select po_cnt tap position.
            po_fine_enable <= #TCQ po_cnt_dec;
            po_fine_inc    <= #TCQ 1'b0;
    end else if (!po_inc_done && PO_COARSE_BYPASS == "TRUE" ) begin
        // decrement PO's stage 2 to the select po_cnt tap position.
            po_fine_enable <= #TCQ po_cnt_inc;
            po_fine_inc    <= #TCQ 1'b1;

    end else if (wrcal_en) begin
          po_fine_enable         <= #TCQ wrlvl_po_f_dec | wrlvl_po_f_inc;
          po_fine_inc            <= #TCQ wrlvl_po_f_inc;
    end else if (~init_calib_complete) begin
            po_fine_enable <= #TCQ po_en_stg2_f | dbg_phy_po_fine_enable;
            po_fine_inc    <= #TCQ po_stg2_f_incdec | dbg_phy_po_fine_inc;
    end else begin       
          po_fine_enable         <= #TCQ (DEBUG_PORT == "ON") ? 
                                         dbg_phy_po_fine_enable : 1'b0;
          po_fine_inc            <= #TCQ (DEBUG_PORT == "ON") ? 
                                         dbg_phy_po_fine_inc : 1'b0;
    end
  end
                                                  
  //synthesis translate_off
  always @(posedge phy_ctl_ready)
    if (!rst_wr_clk)
      $display ("qdr_phy_top.v: phy_ctl_ready asserted  %t", $time);
  
  always @(posedge init_calib_complete)
    if (!rst_wr_clk)
      $display ("qdr_phy_top.v: init_calib_complete asserted  %t", $time);  
  //synthesis translate_on
    
  mig_7series_v2_0_qdr_phy_write_top #
    (
    .CLK_STABLE           (CLK_STABLE),
    .RST_ACT_LOW          (RST_ACT_LOW),
    .BURST_LEN            (BURST_LEN),
    .CLK_PERIOD           (CLK_PERIOD),
    .BYTE_LANE_WITH_DK     (BYTE_LANE_WITH_DK),
    .CK_WIDTH             (CK_WIDTH),
    .DATA_WIDTH           (DATA_WIDTH),
    .BW_WIDTH             (BW_WIDTH),
    .ADDR_WIDTH           (ADDR_WIDTH),
    .N_CTL_LANES          (N_CTL_LANES), 
    .N_DATA_LANES         (N_DATA_LANES),
    .nCK_PER_CLK          (nCK_PER_CLK),
    .SIMULATION           (SIMULATION),
   .PO_COARSE_BYPASS            (PO_COARSE_BYPASS),
    .SIM_BYPASS_INIT_CAL  (SIM_BYPASS_INIT_CAL),
    .PO_ADJ_GAP           (PO_ADJ_GAP),
    .PRE_FIFO             (PRE_FIFO),
    .TCQ                  (TCQ)
  ) u_qdr_phy_write_top (
    
     // system control signals
    .clk                   (clk),            
    .rst_wr_clk            (rst_wr_clk), 
    .clk_mem               (clk_mem),  
    .sys_rst               (sys_rst),
    .rst_clk               (rst_clk),
    
    // calibration status signals
    .read_cal_done             (read_cal_done),
    .init_cal_done             (init_calib_complete),
    .rdlvl_stg1_start          (rdlvl_stg1_start),
    .edge_adv_cal_start        (edge_adv_cal_start),
    .edge_adv_cal_done         (edge_adv_cal_done),    
   
    .phase_valid               (phase_valid),
    .wrcal_byte_sel            (wrcal_byte_sel),
    .wrlvl_po_f_inc            (wrlvl_po_f_inc),
    .wrlvl_po_f_dec            (wrlvl_po_f_dec),
    .wrcal_en                  (wrcal_en),
    .po_sel_fine_oclk_delay    (po_sel_fine_oclk_delay), 
    .cal1_rdlvl_restart        (cal1_rdlvl_restart),
    .rdlvl_stg1_done           (rdlvl_stg1_done),
    .cal_stage2_start          (cal_stage2_start),
    .init_done                 (init_done),
    .po_dec_done               (po_dec_done),
    .po_inc_done                 (po_inc_done),
    
    .po_delay_done             (po_delay_done),
    
    .phy_ctl_ready             (phy_ctl_ready),
    .phy_ctl_full              (phy_ctl_full),
    .phy_ctl_a_full            (phy_ctl_a_full),
    .of_ctl_full               (of_ctl_full),
    .of_data_full              (of_data_full),
    .phy_ctl_wd                (phy_ctl_wd),
    .phy_ctl_wr                (phy_ctl_wr),
    .io_fifo_rden_cal_done     (io_fifo_rden_cal_done),
    .po_counter_read_val       (po_counter_read_val),
    .po_cnt_dec                (po_cnt_dec),
    .po_cnt_inc                (po_cnt_inc),
    
    .of_cmd_wr_en              (of_cmd_wr_en),
    .of_data_wr_en             (of_data_wr_en),
    
    // write data and address/cntrls from user backend
    .wr_cmd0                   (wr_cmd0),
    .wr_cmd1                   (wr_cmd1),
    .wr_addr0                  (wr_addr0),
    .wr_addr1                  (wr_addr1), 
    .rd_cmd0                   (rd_cmd0), 
    .rd_cmd1                   (rd_cmd1), 
    .rd_addr0                  (rd_addr0), 
    .rd_addr1                  (rd_addr1),  
    .wr_data0                  (wr_data0), 
    .wr_data1                  (wr_data1),  
    .wr_bw_n0                  (wr_bw_n0),  
    .wr_bw_n1                  (wr_bw_n1),
    .int_rd_cmd_n              (int_rd_cmd_n),
        
    //write data and address/cntrs to IO
    .iob_addr             (iob_addr),
    .iob_wr_n             (iob_wr_n),
    .iob_rd_n             (iob_rd_n),
    .iob_wdata            (iob_wdata),
    .iob_bw               (iob_bw),
     
    // PHASER OUT delay controls to delay address/cntls 
    .ctl_lane_cnt         (ctl_lane_cnt),         // selects which control byte 
    
    // Doff output to memory. Does not go through OUT_FIFOs.
    .mem_dll_off_n        (iob_dll_off_n),
        
    // debug signals
     .dbg_SM_No_Pause        (dbg_SM_No_Pause),
    
    .dbg_phy_wr_cmd_n     (dbg_phy_wr_cmd_n),
    .dbg_phy_addr         (dbg_phy_addr),    
    .dbg_phy_rd_cmd_n     (dbg_phy_rd_cmd_n),
    .dbg_phy_wr_data      (dbg_phy_wr_data),
    .dbg_wr_init          (dbg_wr_init_tmp),
    .dbg_phy_init_wr_only (dbg_phy_init_wr_only),
    .dbg_phy_init_rd_only (dbg_phy_init_rd_only) ,
    .wrlvl_calib_in_common (wrlvl_calib_in_common),
     .dbg_SM_en                      (dbg_SM_en)
    
  );

// improve fanout timing.
always @ (posedge clk)
begin

 rst_stg1 <= rst_clk | cal1_rdlvl_restart;
 
 rst_stg2 <= rst_clk | cal1_rdlvl_restart;

end 
 //Instantiate the top of the read path
  mig_7series_v2_0_qdr_rld_phy_read_top #
    (
    .BURST_LEN              (BURST_LEN),
    .DATA_WIDTH             (DATA_WIDTH),
    .BW_WIDTH               (BW_WIDTH),
    .SIM_BYPASS_INIT_CAL    (SIM_BYPASS_PHY_RD_INIT_CAL),
    .CPT_CLK_CQ_ONLY        (CPT_CLK_CQ_ONLY),
    .N_DATA_LANES           (N_DATA_LANES), // no. of byte lanes used for data ),
    .MEMORY_IO_DIR          ("UNIDIR"),
    .FIXED_LATENCY_MODE     (FIXED_LATENCY_MODE),
    .PHY_LATENCY            (PHY_LATENCY),
    .CLK_PERIOD             (CLK_PERIOD),
    .REFCLK_FREQ            (REFCLK_FREQ),
    //.DEVICE_TAPS            (DEVICE_TAPS),
    .TAP_BITS               (TAP_BITS),
    //.IODELAY_GRP            (IODELAY_GRP),
    .PI_ADJ_GAP             (PI_ADJ_GAP),
    .MEM_TYPE               (MEM_TYPE),
    .nCK_PER_CLK            (nCK_PER_CLK),
    .RD_DATA_RISE_FALL      ("TRUE"),
    .CQ_BITS                (CQ_BITS),
    .Q_BITS                 (Q_BITS),
    .DEBUG_PORT             (DEBUG_PORT),
    .TCQ                    (TCQ)                
    ) 
    u_qdr_rld_phy_read_top 
    (
    .clk                    (clk),
	.rst_stg1               (rst_stg1),
	.rst_stg2               (rst_stg2),
    .rst_wr_clk             (rst_wr_clk), 
    .if_empty               (if_empty),
	.rtr_cal_done           (1'b1),
	.iserdes_rd             ({rd_data_map[(DATA_WIDTH*3)-1 : DATA_WIDTH*2],
	                          rd_data_map[DATA_WIDTH-1 : 0]}),
	.iserdes_fd             ({rd_data_map[(DATA_WIDTH*4)-1 : DATA_WIDTH*3],
	                          rd_data_map[(DATA_WIDTH*2)-1 : DATA_WIDTH]}),
    .if_rden                (if_rden),
    
    // phaser in and phaser out controls during stage1 calibration
    .pi_counter_read_val    (pi_counter_read_val),
    .pi_dec_done            (pi_dec_done),
    
    .pi_en_stg2_f           (pi_en_stg2_f),     
    .pi_stg2_f_incdec       (pi_stg2_f_incdec), 
    .pi_stg2_load           (pi_stg2_load),     
    .pi_stg2_reg_l          (pi_stg2_reg_l),    
    .pi_stg2_rdlvl_cnt      (pi_stg2_rdlvl_cnt),
    .byte_cnt               (edge_cal_byte_cnt),
    .po_counter_read_val    (po_counter_read_val),
    
    .po_en_stg2_f           (po_en_stg2_f),     
    .po_stg2_f_incdec       (po_stg2_f_incdec), 
    .po_stg2_load           (po_stg2_load),     
    .po_stg2_reg_l          (po_stg2_reg_l),    
    .po_stg2_rdlvl_cnt      (po_stg2_rdlvl_cnt),
    .phase_valid            (phase_valid),
    .pi_edge_adv            (pi_edge_adv),
    .dlyval_dq              (dlyval_dq),
//    .idelay_ce              (idelay_ce), //idelay_ce
//    .idelay_inc             (idelay_inc), //idelay_ce
    
    .read_cal_done          (read_cal_done),
	.rd_data                ({rd_data1, rd_data0}),
	.rd_valid               ({rd_valid1, rd_valid0}),
    
    .init_done              (init_done),
    .rdlvl_stg1_start       (rdlvl_stg1_start),
    .edge_adv_cal_start     (edge_adv_cal_start),
    .rdlvl_stg1_done        (rdlvl_stg1_done),
    .edge_adv_cal_done      (edge_adv_cal_done),
    .cal_stage2_start       (cal_stage2_start),
    .error_adj_latency      (error_adj_latency),

    .int_rd_cmd_n           (int_rd_cmd_n),
  
    .dbg_SM_en               (dbg_SM_en),
    .dbg_next_byte        (dbg_next_byte),
    .dbg_rd_stage1_cal      (dbg_rd_stage1_cal_tmp),
    .dbg_stage2_cal         (dbg_stage2_cal_tmp),
    //.dbg_cq_num             (dbg_cq_num),
    //.dbg_q_bit              (dbg_q_bit),
    .dbg_valid_lat          (dbg_valid_lat),
    //.dbg_phase              (dbg_phase),
    .dbg_inc_latency        (dbg_inc_latency),
    .dbg_error_max_latency  (dbg_error_max_latency),
	.dbg_align_rd           ({dbg_align_rd1, dbg_align_rd0}),
	.dbg_align_fd           ({dbg_align_fd1, dbg_align_fd0}),
    .dbg_rdphy_top          (dbg_rdphy_top)
  );                                                    

mig_7series_v2_0_qdr_phy_byte_lane_map #
  (
   .TCQ             (TCQ),
   .nCK_PER_CLK     (nCK_PER_CLK),         // qdr2+ used in the 2:1 mode
   .NUM_DEVICES     (NUM_DEVICES),
   .ADDR_WIDTH      (ADDR_WIDTH),         //Adress Width
   .DATA_WIDTH      (DATA_WIDTH),         //Data Width
   .BW_WIDTH        (BW_WIDTH),         //Byte Write Width
   .MEMORY_IO_DIR     (MEMORY_IO_DIR),
   .MEM_RD_LATENCY  (MEM_RD_LATENCY),
   .Q_BITS          (Q_BITS),
   //.N_LANES         (N_LANES),
   //.N_CTL_LANES     (2),
   // five fields, one per possible I/O bank, 4 bits in each field, 
   // 1 per lane data=1/ctl=0
   .DATA_CTL_B0     (DATA_CTL_B0),
   .DATA_CTL_B1     (DATA_CTL_B1),
   .DATA_CTL_B2     (DATA_CTL_B2),
   .DATA_CTL_B3     (DATA_CTL_B3),
   .DATA_CTL_B4     (DATA_CTL_B4),
   // defines the byte lanes in I/O banks being used in the interface
   // 1- Used, 0- Unused
   .BYTE_LANES_B0   (BYTE_LANES_B0),
   .BYTE_LANES_B1   (BYTE_LANES_B1),
   .BYTE_LANES_B2   (BYTE_LANES_B2),
   .BYTE_LANES_B3   (BYTE_LANES_B3),
   .BYTE_LANES_B4   (BYTE_LANES_B4),
   .HIGHEST_LANE    (HIGHEST_LANE),
   .HIGHEST_BANK    (HIGHEST_BANK),
   
   // Mapping for address and control signals
   // The parameter contains the byte_lane and bit position information for 
   // a control signal. 
   // Each add/ctl bit will have 12 bits the assignments are
   // [3:0] - Bit position within a byte lane . 
   // [7:4] - Byte lane position within a bank. [5:4] have the byte lane position. 
    // [7:6] tied to 0 
   // [11:8] - Bank position. [10:8] have the bank position. [11] tied to zero . 
   .K_MAP            (K_MAP),
   .CQ_MAP           (CQ_MAP),
   .RD_MAP           (RD_MAP),
   .WR_MAP           (WR_MAP),
   
   // supports 22 bits of address in 3 byte lanes
   .ADD_MAP          (ADD_MAP),
   
   //One parameter per data byte - 9bits per byte = 9*12 for write data
   .D0_MAP           (D0_MAP),//byte 0 
   .D1_MAP           (D1_MAP),//byte 1
   .D2_MAP           (D2_MAP),//byte 2
   .D3_MAP           (D3_MAP),//byte 3
   .D4_MAP           (D4_MAP),//byte 4
   .D5_MAP           (D5_MAP),//byte 5
   .D6_MAP           (D6_MAP),//byte 6
   .D7_MAP           (D7_MAP),//byte 7
   
   // byte writes for bytes 0 to 7 - 8*12
   .BW_MAP           (BW_MAP), 
                     
   .Q0_MAP           (Q0_MAP),//byte 0 
   .Q1_MAP           (Q1_MAP),//byte 1
   .Q2_MAP           (Q2_MAP),//byte 2
   .Q3_MAP           (Q3_MAP),//byte 3
   .Q4_MAP           (Q4_MAP),//byte 4
   .Q5_MAP           (Q5_MAP),//byte 5
   .Q6_MAP           (Q6_MAP),//byte 6
   .Q7_MAP           (Q7_MAP)//byte 7   
  ) u_qdr_phy_byte_lane_map
  (   
  .clk                    (clk),
  .rst                    (rst_clk),
  .phy_init_data_sel      (1'b0), //phy_init_data_sel (NOT USED)
  .byte_sel_cnt           (byte_sel_cnt),
  .phy_din                (phy_din),
  .phy_dout               (phy_dout),
  .ddr_clk                (ddr_clk),
  .cq_clk                 (cq_clk),
  .cqn_clk                (cqn_clk),
  .iob_addr               (iob_addr),
  .iob_rd_n               (iob_rd_n),
  .iob_wr_n               (iob_wr_n),
  .iob_wdata              (iob_wdata),
  .iob_bw                 (iob_bw),
  .iob_dll_off_n          (iob_dll_off_n),
  .dlyval_dq              (dlyval_dq),
  .idelay_cnt_out         (idelay_cnt_out),
  .dbg_inc_q_all          (1'b0), //dbg_inc_q_all
  .dbg_dec_q_all          (1'b0), //dbg_dec_q_all
  .dbg_inc_q              (1'b0), //dbg_inc_q
  .dbg_dec_q              (1'b0), //dbg_dec_q
  .dbg_sel_q              (dbg_bit_sel),
  .dbg_q_tapcnt           (dbg_idel_tap_cnt),
  .idelay_cnt_in          (idelay_cnt_in), //idelay_cnt_in
  .idelay_ce              (idelay_ce),
  .idelay_inc             (idelay_inc),
  .rd_data_map            (rd_data_map),
  .qdr_k_p                (qdr_k_p),
  .qdr_k_n                (qdr_k_n),
  .qdr_sa                 (qdr_sa),    //QDR Memory Address       
  .qdr_w_n                (qdr_w_n),   //QDR Write                
  .qdr_r_n                (qdr_r_n),   //QDR Read                 
  .qdr_bw_n               (qdr_bw_n),  //QDR Byte Writes to Mem   
  .qdr_d                  (qdr_d),     //QDR Data to Memory
  .qdr_dll_off_n          (qdr_dll_off_n),     //QDR Dll Off to Memory
  .qdr_cq_p               (qdr_cq_p),
  .qdr_cq_n               (qdr_cq_n), 
  .qdr_q                  (qdr_q),
  .O                      (O),
  .I                      (I)
  );
  
  mig_7series_v2_0_qdr_rld_mc_phy #
  (  
// five fields, one per possible I/O bank, 4 bits in each field, 1 per lane data=1/ctl=0
      .MEMORY_TYPE                 (MEM_TYPE),
      .MEM_TYPE                    (MEM_TYPE),
      .SIMULATION                  (SIMULATION),
      .SIM_BYPASS_INIT_CAL         (SIM_BYPASS_INIT_CAL),
      .CPT_CLK_CQ_ONLY             (CPT_CLK_CQ_ONLY),
      .PO_COARSE_BYPASS            (PO_COARSE_BYPASS),
      .INTERFACE_TYPE              (MEMORY_IO_DIR), //select between "UNIDIR" & "BIDIR"
      .BYTE_LANES_B0               (BYTE_LANES_B0), 
      .BYTE_LANES_B1               (BYTE_LANES_B1),
      .BYTE_LANES_B2               (BYTE_LANES_B2),
      .BYTE_LANES_B3               (BYTE_LANES_B3),
      .BYTE_LANES_B4               (BYTE_LANES_B4),
      .BITLANES_IN_B0              (BITLANES_IN_B0),
      .BITLANES_IN_B1              (BITLANES_IN_B1),
      .BITLANES_IN_B2              (BITLANES_IN_B2),
      .BITLANES_IN_B3              (BITLANES_IN_B3),
      .BITLANES_IN_B4              (BITLANES_IN_B4),
      .BITLANES_OUT_B0             (BITLANES_OUT_B0),
      .BITLANES_OUT_B1             (BITLANES_OUT_B1),
      .BITLANES_OUT_B2             (BITLANES_OUT_B2),
      .BITLANES_OUT_B3             (BITLANES_OUT_B3),
      .BITLANES_OUT_B4             (BITLANES_OUT_B4), 
      .DATA_CTL_B0                 (DATA_CTL_B0),
      .DATA_CTL_B1                 (DATA_CTL_B1),
      .DATA_CTL_B2                 (DATA_CTL_B2),
      .DATA_CTL_B3                 (DATA_CTL_B3),
      .DATA_CTL_B4                 (DATA_CTL_B4),
      .CPT_CLK_SEL_B0              (CPT_CLK_SEL_B0),
      .CPT_CLK_SEL_B1              (CPT_CLK_SEL_B1),  
      .CPT_CLK_SEL_B2              (CPT_CLK_SEL_B2),
      .BYTE_GROUP_TYPE_B0          (BYTE_GROUP_TYPE_B0),
      .BYTE_GROUP_TYPE_B1          (BYTE_GROUP_TYPE_B1),
      .BYTE_GROUP_TYPE_B2          (BYTE_GROUP_TYPE_B2),
      .BYTE_GROUP_TYPE_B3          (BYTE_GROUP_TYPE_B3),
      .BYTE_GROUP_TYPE_B4          (BYTE_GROUP_TYPE_B4),
      .HIGHEST_LANE                (HIGHEST_LANE),
      .BUFMR_DELAY                 (BUFMR_DELAY),
       .PLL_LOC                     (PLL_LOC),
      .INTER_BANK_SKEW             (INTER_BANK_SKEW), 
      .MASTER_PHY_CTL              (MASTER_PHY_CTL),
      .DIFF_CK                     (1'b1),
      .DIFF_DK                     (1'b1),
      .DIFF_CQ                     (1'b0), //QDR2+ uses two single ended clocks
      .CK_VALUE_D1                 (1'b0),
      .DK_VALUE_D1                 (1'b0),
      .CK_MAP                      (48'h0),
      .CK_WIDTH                    (0),   //no CK used for QDR
      .DK_MAP                      (K_MAP),
      .CQ_MAP                      (CQ_MAP),
      .DK_WIDTH                    (NUM_DEVICES),
      .CQ_WIDTH                    (NUM_DEVICES),      
      .IODELAY_GRP                 (IODELAY_GRP),
      .IODELAY_HP_MODE             (IODELAY_HP_MODE),
      .CLK_PERIOD                  (CLK_PERIOD) ,
      .PRE_FIFO                    (PRE_FIFO),
      .PHY_0_PO_FINE_DELAY         (PO_FINE_DELAY),
      .PHY_0_PI_FINE_DELAY         (PI_FINE_DELAY),
	  .REFCLK_FREQ                 (REFCLK_FREQ),
      .ADDR_CTL_90_SHIFT           (ADDR_CTL_90_SHIFT),
	  .BUFG_FOR_OUTPUTS            (BUFG_FOR_OUTPUTS),
      .TCQ                         (TCQ)
     
     ) u_qdr_rld_mc_phy
      (
      .rst                         (rst_wr_clk),
      .sys_rst                     (rst_wr_clk),
      .rst_rd_clk                  (rst_clk),
      
      .phy_clk                     (clk),
      .phy_clk_fast                (1'b0),
      .freq_refclk                 (freq_refclk),
      .mem_refclk                  (clk_mem),
      .pll_lock                    (pll_lock),
      .sync_pulse                  (sync_pulse),
      .ref_dll_lock                (ref_dll_lock), 
      .rst_phaser_ref              (rst_phaser_ref),
      .phy_ctl_wd                  (phy_ctl_wd),
      .phy_ctl_wr                  (phy_ctl_wr),
      .phy_ctl_ready               (phy_ctl_ready),
      .phy_write_calib             (1'b0),
      .phy_read_calib              (1'b0),
      .phy_ctl_full                (phy_ctl_full),
      .phy_ctl_a_full              (phy_ctl_a_full),
      .phy_dout                    (phy_dout),
      .phy_cmd_wr_en               (of_cmd_wr_en ),
      .phy_data_wr_en              (of_data_wr_en),
      .phy_rd_en                   (if_rden),
      .idelay_ld                   (idelay_ld),
      .idelay_ce                   (idelay_ce),
      .idelay_inc                  (idelay_inc),
      .idelay_cnt_in               (idelay_cnt_in),
      .idelay_cnt_out              (idelay_cnt_out),
      
      .if_a_empty                  (if_a_empty),
      .if_empty                    (if_empty),
      .if_full                     (),
      .of_empty                    (),
      .of_ctl_a_full               (of_ctl_a_full),
      .of_data_a_full              (of_data_a_full),
      .of_ctl_full                 (of_ctl_full),
      .of_data_full                (of_data_full),
      .phy_din                     (phy_din),
      .O                           (O),  // data/ctl to memory
      .I                           (I),  // data/ctl to memory
      .mem_dq_ts                   (),
      .ddr_clk                     (ddr_clk),
      .cq_clk                      (cq_clk),
      .cqn_clk                     (cqn_clk),
// calibration signals            
      .calib_sel                   (calib_sel),
      .calib_zero_inputs           (calib_zero_inputs),       
      .calib_in_common             (calib_in_common),
      .po_dec_done                 (po_dec_done),
      .po_inc_done                 (po_inc_done),
      
      .po_delay_done               (po_delay_done),
      .po_fine_enable              (po_fine_enable ),
      .po_coarse_enable            (1'b0), 
      .po_edge_adv                 (1'b0),
      .po_fine_inc                 (po_fine_inc ),
      .po_coarse_inc               (1'b0),
      .po_counter_load_en          (po_stg2_load),   // was po_stg2_load      
                                             // Rich Swanson said , don't use this, use parameter to pass in the value
                                             // and do decremenation or increment.
      .po_sel_fine_oclk_delay      (po_sel_fine_oclk_delay), 
      .po_counter_load_val         ({3'b0, po_stg2_reg_l}),     
      .po_counter_read_en          (1'b1), 
      .po_coarse_overflow          (),
      .po_fine_overflow            (),
      .po_counter_read_val         (po_counter_read_val),
      .pi_fine_enable              (pi_en_stg2_f | dbg_phy_pi_fine_enable),
      .pi_edge_adv                 (pi_edge_adv_2r),   
      .pi_fine_inc                 (pi_stg2_f_incdec | dbg_phy_pi_fine_inc),
      .pi_counter_load_en          (pi_stg2_load),
      .pi_counter_load_val         (pi_stg2_reg_l),
      .pi_counter_read_en          (1'b1),
      .pi_fine_overflow            (),
      .pi_counter_read_val         (pi_counter_read_val),
      .dbg_mc_phy                  (dbg_mc_phy), //dbg_mc_phy
      .dbg_phy_4lanes              (dbg_phy_4lanes), //dbg_phy_4lanes
      .dbg_byte_lane               (dbg_byte_lane)  //dbg_byte_lane
 );
 
  assign dbg_idel_tap_cnt_sel = dbg_idel_tap_cnt[(dbg_bit_sel*TAP_BITS)+:TAP_BITS];

  generate
  if (DATA_WIDTH >= 36) begin: gen_36_bit_design
    always @ (posedge clk) begin
       if (rst_clk )
         dbg_idly_tap_counts <= #TCQ 'b0;
       else begin
         dbg_idly_tap_counts[0+:5] <= #TCQ dbg_idel_tap_cnt[4:0];
         dbg_idly_tap_counts[5+:5] <= #TCQ dbg_idel_tap_cnt[49:45];
         dbg_idly_tap_counts[10+:5] <= #TCQ dbg_idel_tap_cnt[90+:5];
         dbg_idly_tap_counts[15+:5] <= #TCQ dbg_idel_tap_cnt[135+:5];
       end
    end
   
  end else begin: gen_18_bit_design
    always @ (posedge clk) begin
       if (rst_clk )
         dbg_idly_tap_counts <= #TCQ 'b0;
       else begin
         dbg_idly_tap_counts[0+:5] <= #TCQ dbg_idel_tap_cnt[4:0];
         dbg_idly_tap_counts[5+:5] <= #TCQ dbg_idel_tap_cnt[49:45];
         dbg_idly_tap_counts[10+:5] <= #TCQ dbg_idel_tap_cnt[44:40];
         dbg_idly_tap_counts[15+:5] <= #TCQ dbg_idel_tap_cnt[89:85];
       end
    end
  end
  endgenerate
  
  //register the data chipscope signals for better timing
  //needed if the interface gets wide and spans multiple banks
  //no need for reset
  always @ (posedge clk) begin
    if (dbg_bit_sel < 9) 
      dbg_select_rdata <= #TCQ 3'd0;
    else if (dbg_bit_sel < 18) 
      dbg_select_rdata <= #TCQ 3'd1;
    else if (dbg_bit_sel < 27)
      dbg_select_rdata <= #TCQ 3'd2;
    else if (dbg_bit_sel < 36) 
      dbg_select_rdata <= #TCQ 3'd3;
    else //default case for 9-bit interface
      dbg_select_rdata <= #TCQ 3'd0;
    
    //extra registers just in case
    dbg_select_rdata_r1 <= #TCQ dbg_select_rdata;
    dbg_select_rdata_r2 <= #TCQ dbg_select_rdata_r1;
  end

  //Use minimal chipscope signals to view data, so mux data
  //Supports up to 36-bit width
  generate 
    if (DATA_WIDTH <= 9) begin: gen_dbg_rdata_9_0
      always @ (posedge clk) begin
        dbg_align_rd0_r  <= #TCQ dbg_align_rd0[DATA_WIDTH-1:0];
        dbg_align_fd0_r  <= #TCQ dbg_align_fd0[DATA_WIDTH-1:0];
        dbg_align_rd1_r  <= #TCQ dbg_align_rd1[DATA_WIDTH-1:0];
        dbg_align_fd1_r  <= #TCQ dbg_align_fd1[DATA_WIDTH-1:0];
      end
      
    end else if (DATA_WIDTH <= 18)begin : gen_dbg_rdata_18_0
      always @ (posedge clk) begin
        if (dbg_select_rdata_r2 == 3'd0) begin
          dbg_align_rd0_r  <= #TCQ dbg_align_rd0[8:0];
          dbg_align_fd0_r  <= #TCQ dbg_align_fd0[8:0];
          dbg_align_rd1_r  <= #TCQ dbg_align_rd1[8:0];
          dbg_align_fd1_r  <= #TCQ dbg_align_fd1[8:0];
        end else begin
          dbg_align_rd0_r  <= #TCQ dbg_align_rd0[DATA_WIDTH-1:9];
          dbg_align_fd0_r  <= #TCQ dbg_align_fd0[DATA_WIDTH-1:9];
          dbg_align_rd1_r  <= #TCQ dbg_align_fd0[DATA_WIDTH-1:9];
          dbg_align_fd1_r  <= #TCQ dbg_align_fd1[DATA_WIDTH-1:9];
        end //end of if
      end //end always
    end else if (DATA_WIDTH <= 27)begin : gen_dbg_rdata_27_0
      always @ (posedge clk) begin
        if (dbg_select_rdata_r2 == 3'd0) begin
          dbg_align_rd0_r  <= #TCQ dbg_align_rd0[8:0];
          dbg_align_fd0_r  <= #TCQ dbg_align_fd0[8:0];
          dbg_align_rd1_r  <= #TCQ dbg_align_rd1[8:0];
          dbg_align_fd1_r  <= #TCQ dbg_align_fd1[8:0];
        end else if (dbg_select_rdata_r2 == 3'd1) begin
          dbg_align_rd0_r  <= #TCQ dbg_align_rd0[17:9];
          dbg_align_fd0_r  <= #TCQ dbg_align_fd0[17:9];
          dbg_align_rd1_r  <= #TCQ dbg_align_rd1[17:9];
          dbg_align_fd1_r  <= #TCQ dbg_align_fd1[17:9];
        end else begin
          dbg_align_rd0_r  <= #TCQ dbg_align_rd0[DATA_WIDTH-1:18];
          dbg_align_fd0_r  <= #TCQ dbg_align_fd0[DATA_WIDTH-1:18];
          dbg_align_rd1_r  <= #TCQ dbg_align_fd0[DATA_WIDTH-1:18];
          dbg_align_fd1_r  <= #TCQ dbg_align_fd1[DATA_WIDTH-1:18];
        end //end of if
      end //end always
    end else if (DATA_WIDTH <= 36)begin : gen_dbg_rdata_35_0
      always @ (posedge clk) begin
        if (dbg_select_rdata_r2 == 3'd0) begin
          dbg_align_rd0_r  <= #TCQ dbg_align_rd0[8:0];
          dbg_align_fd0_r  <= #TCQ dbg_align_fd0[8:0];
          dbg_align_rd1_r  <= #TCQ dbg_align_rd1[8:0];
          dbg_align_fd1_r  <= #TCQ dbg_align_fd1[8:0];
        end else if (dbg_select_rdata_r2 == 3'd1) begin
          dbg_align_rd0_r  <= #TCQ dbg_align_rd0[17:9];
          dbg_align_fd0_r  <= #TCQ dbg_align_fd0[17:9];
          dbg_align_rd1_r  <= #TCQ dbg_align_rd1[17:9];
          dbg_align_fd1_r  <= #TCQ dbg_align_fd1[17:9];
        end else if (dbg_select_rdata_r2 == 3'd2) begin
          dbg_align_rd0_r  <= #TCQ dbg_align_rd0[26:18];
          dbg_align_fd0_r  <= #TCQ dbg_align_fd0[26:18];
          dbg_align_rd1_r  <= #TCQ dbg_align_rd1[26:18];
          dbg_align_fd1_r  <= #TCQ dbg_align_fd1[26:18];
        end else begin
          dbg_align_rd0_r  <= #TCQ dbg_align_rd0[DATA_WIDTH-1:27];
          dbg_align_fd0_r  <= #TCQ dbg_align_fd0[DATA_WIDTH-1:27];
          dbg_align_rd1_r  <= #TCQ dbg_align_fd0[DATA_WIDTH-1:27];
          dbg_align_fd1_r  <= #TCQ dbg_align_fd1[DATA_WIDTH-1:27];
        end //end of if
      end //end always
    end
  endgenerate
  
  //line up the valid with the read data
  always @(posedge clk) begin
    rd_valid0_r <= #TCQ rd_valid0;
    rd_valid1_r <= #TCQ rd_valid1;
  end
  
  //Support for CQ# later
  assign vio_sel_rise_chk = 1'b0;

 // added for connecting driverless bits to 0 for OOC flow

always@*
    begin
      dbg_rd_stage1_cal = 0;
      dbg_wr_init       = 0;
      dbg_stage2_cal    = 0; 
      dbg_rd_stage1_cal = dbg_rd_stage1_cal_tmp;
      dbg_wr_init       = dbg_wr_init_tmp;
      dbg_stage2_cal    = dbg_stage2_cal_tmp;
    end
  
endmodule
