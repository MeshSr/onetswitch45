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
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 2.0
//  \   \         Application        : MIG
//  /   /         Filename           : mig_7series_0_mig.v
// /___/   /\     Date Last Modified : $Date: 2011/06/02 08:36:27 $
// \   \  /  \    Date Created       : Fri Jan 14 2011
//  \___\/\___\
//
// Device           : 7 Series
// Design Name      : QDRII+ SDRAM
// Purpose          :
//   Top-level  module. This module can be instantiated in the
//   system and interconnect as shown in user design wrapper file (user top module).
//   In addition to the memory controller, the module instantiates:
//     1. Clock generation/distribution, reset logic
//     2. IDELAY control block
//     3. Debug logic
// Reference        :
// Revision History :
//*****************************************************************************

`timescale 1ps/1ps

module mig_7series_0_mig #
  (

   parameter MEM_TYPE              = "QDR2PLUS",
                                     // # of CK/CK# outputs to memory.
   parameter DATA_WIDTH            = 36,
                                     // # of DQ (data)
   parameter BW_WIDTH              = 4,
                                     // # of byte writes (data_width/9)
   parameter ADDR_WIDTH            = 19,
                                     // Address Width
   parameter NUM_DEVICES           = 1,
                                     // # of memory components connected
   parameter MEM_RD_LATENCY        = 2.5,
                                     // Value of Memory part read latency
   parameter CPT_CLK_CQ_ONLY       = "TRUE",
                                     // whether CQ and its inverse are used for the data capture
   parameter INTER_BANK_SKEW       = 0,
                                     // Clock skew between two adjacent banks
   parameter PHY_CONTROL_MASTER_BANK = 1,
                                     // The bank index where master PHY_CONTROL resides,
                                     // equal to the PLL residing bank

   //***************************************************************************
   // The following parameters are mode register settings
   //***************************************************************************
   parameter BURST_LEN             = 4,
                                     // Burst Length of the design (4 or 2).
   parameter FIXED_LATENCY_MODE    = 0,
                                     // Enable Fixed Latency
   parameter PHY_LATENCY           = 0,
                                     // Value for Fixed Latency Mode
                                     // Expected Latency
   
   //***************************************************************************
   // The following parameters are multiplier and divisor factors for MMCM.
   // Based on the selected design frequency these parameters vary.
   //***************************************************************************
   parameter CLKIN_PERIOD          = 5000,
                                     // Input Clock Period
   parameter CLKFBOUT_MULT         = 4,
                                     // write PLL VCO multiplier
   parameter DIVCLK_DIVIDE         = 1,
                                     // write PLL VCO divisor
   parameter CLKOUT0_DIVIDE        = 2,
                                     // VCO output divisor for PLL output clock (CLKOUT0)
   parameter CLKOUT1_DIVIDE        = 2,
                                     // VCO output divisor for PLL output clock (CLKOUT1)
   parameter CLKOUT2_DIVIDE        = 32,
                                     // VCO output divisor for PLL output clock (CLKOUT2)
   parameter CLKOUT3_DIVIDE        = 4,
                                     // VCO output divisor for PLL output clock (CLKOUT3)

   //***************************************************************************
   // Simulation parameters
   //***************************************************************************
   parameter SIM_BYPASS_INIT_CAL   = "OFF",
                                     // # = "OFF" -  Complete memory init &
                                     //              calibration sequence
                                     // # = "FAST" - Skip memory init & use
                                     //              abbreviated calib sequence
   parameter SIMULATION            = "FALSE",
                                     // Should be TRUE during design simulations and
                                     // FALSE during implementations

   //***************************************************************************
   // The following parameters varies based on the pin out entered in MIG GUI.
   // Do not change any of these parameters directly by editing the RTL.
   // Any changes required should be done through GUI and the design regenerated.
   //***************************************************************************
   parameter BYTE_LANES_B0         = 4'b1111,
                                     // Byte lanes used in an IO column.
   parameter BYTE_LANES_B1         = 4'b1111,
                                     // Byte lanes used in an IO column.
   parameter BYTE_LANES_B2         = 4'b1100,
                                     // Byte lanes used in an IO column.
   parameter BYTE_LANES_B3         = 4'b0000,
                                     // Byte lanes used in an IO column.
   parameter BYTE_LANES_B4         = 4'b0000,
                                     // Byte lanes used in an IO column.
   parameter DATA_CTL_B0           = 4'b1111,
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   parameter DATA_CTL_B1           = 4'b1111,
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   parameter DATA_CTL_B2           = 4'b0000,
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   parameter DATA_CTL_B3           = 4'b0000,
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   parameter DATA_CTL_B4           = 4'b0000,
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane

   // this parameter specifies the location of the capture clock with respect
   // to read data.
   // Each byte refers to the information needed for data capture in the corresponding byte lane
   // Lower order nibble - is either 4'h1 or 4'h2. This refers to the capture clock in T1 or T2 byte lane
   // Higher order nibble - 4'h0 refers to clock present in the bank below the read data,
   //                       4'h1 refers to clock present in the same bank as the read data,
   //                       4'h2 refers to clock present in the bank above the read data.
   parameter CPT_CLK_SEL_B0  = 32'h11_11_11_11,
   parameter CPT_CLK_SEL_B1  = 32'h00_00_00_00,
   parameter CPT_CLK_SEL_B2  = 32'h00_00_00_00,

   parameter PHY_0_BITLANES       = 48'hFF8_FF1_D3F_EFC,
                                     // The bits used inside the Bank0 out of 48 pins.
   parameter PHY_1_BITLANES       = 48'h3FE_FFE_CFF_FFC,
                                     // The bits used inside the Bank1 out of 48 pins.
   parameter PHY_2_BITLANES       = 48'hEFE_FFD_000_000,
                                     // The bits used inside the Bank2 out of 48 pins.
   parameter PHY_3_BITLANES       = 48'h000_000_000_000,
                                     // The bits used inside the Bank3 out of 48 pins.
   parameter PHY_4_BITLANES       = 48'h000_000_000_000,
                                     // The bits used inside the Bank4 out of 48 pins.

   // Differentiates the INPUT and OUTPUT bytelates (1-input, 0-output)
   parameter BYTE_GROUP_TYPE_B0 = 4'b1111,
   parameter BYTE_GROUP_TYPE_B1 = 4'b0000,
   parameter BYTE_GROUP_TYPE_B2 = 4'b0000,
   parameter BYTE_GROUP_TYPE_B3 = 4'b0000,
   parameter BYTE_GROUP_TYPE_B4 = 4'b0000,

   // mapping for K/K# clocks. This parameter needs to have an 8-bit value per component
   // since the phy drives a K/K# clock pair to each memory it interfaces to. A 3 component
   // interface is supported for now. This parameter needs to be used in conjunction with
   // NUM_DEVICES parameter which provides information on the number. of components being
   // interfaced to.
   // the 8 bit for each component is defined as follows:
   // [7:4] - bank number ; [3:0] - byte lane number
   parameter K_MAP = 48'h00_00_00_00_00_13,

   // mapping for CQ/CQ# clocks. This parameter needs to have an 4-bit value per component
   // since the phy drives a CQ/CQ# clock pair to each memory it interfaces to. A 3 component
   // interface is supported for now. This parameter needs to be used in conjunction with
   // NUM_DEVICES parameter which provides information on the number. of components being
   // interfaced to.
   // the 4 bit for each component is defined as follows:
   // [3:0] - bank number
   parameter CQ_MAP = 48'h00_00_00_00_00_01,

   //**********************************************************************************************
   // Each of the following parameter contains the byte_lane and bit position information for
   // the address/control, data write and data read signals. Each bit has 12 bits and the details are
   // [3:0] - Bit position within a byte lane .
   // [7:4] - Byte lane position within a bank. [5:4] have the byte lane position and others reserved.
   // [11:8] - Bank position. [10:8] have the bank position. [11] tied to zero .
   //**********************************************************************************************

   // Mapping for address and control signals.

   parameter RD_MAP = 12'h220,      // Mapping for read enable signal
   parameter WR_MAP = 12'h222,      // Mapping for write enable signal

   // Mapping for address signals. Supports upto 22 bits of address bits (22*12)
   parameter ADD_MAP = 264'h000_000_000_223_236_22B_23B_235_234_225_229_224_232_228_23A_231_237_239_233_227_22A_226,

   // Mapping for the byte lanes used for address/control signals. Supports a maximum of 3 banks.
   parameter ADDR_CTL_MAP = 32'h00_00_23_22,

   // Mapping for data WRITE signals

   // Mapping for data write bytes (9*12)
   parameter D0_MAP  = 108'h137_134_136_135_132_133_131_138_139, //byte 0
   parameter D1_MAP  = 108'h121_124_125_122_126_127_12A_123_12B, //byte 1
   parameter D2_MAP  = 108'h102_103_108_104_106_105_107_10A_10B, //byte 2
   parameter D3_MAP  = 108'h116_117_115_11A_114_113_111_112_110, //byte 3
   parameter D4_MAP  = 108'h000_000_000_000_000_000_000_000_000, //byte 4
   parameter D5_MAP  = 108'h000_000_000_000_000_000_000_000_000, //byte 5
   parameter D6_MAP  = 108'h000_000_000_000_000_000_000_000_000, //byte 6
   parameter D7_MAP  = 108'h000_000_000_000_000_000_000_000_000, //byte 7

   // Mapping for byte write signals (8*12)
   parameter BW_MAP = 84'h000_000_000_11B_109_128_129,

   // Mapping for data READ signals

   // Mapping for data read bytes (9*12)
   parameter Q0_MAP  = 108'h033_039_034_036_035_03A_03B_037_038, //byte 0
   parameter Q1_MAP  = 108'h029_020_028_026_027_02A_02B_024_025, //byte 1
   parameter Q2_MAP  = 108'h015_014_01A_01B_011_010_013_012_018, //byte 2
   parameter Q3_MAP  = 108'h00B_003_007_002_005_004_009_006_00A, //byte 3
   parameter Q4_MAP  = 108'h000_000_000_000_000_000_000_000_000, //byte 4
   parameter Q5_MAP  = 108'h000_000_000_000_000_000_000_000_000, //byte 5
   parameter Q6_MAP  = 108'h000_000_000_000_000_000_000_000_000, //byte 6
   parameter Q7_MAP  = 108'h000_000_000_000_000_000_000_000_000, //byte 7

   //***************************************************************************
   // IODELAY and PHY related parameters
   //***************************************************************************
   parameter IODELAY_HP_MODE       = "ON",
                                     // to phy_top
   parameter IBUF_LPWR_MODE        = "OFF",
                                     // to phy_top
   parameter TCQ                   = 100,
   parameter IODELAY_GRP           = "MIG_7SERIES_0_IODELAY_MIG",
                                     // It is associated to a set of IODELAYs with
                                     // an IDELAYCTRL that have same IODELAY CONTROLLER
                                     // clock frequency.
   parameter SYSCLK_TYPE           = "SINGLE_ENDED",
                                     // System clock type DIFFERENTIAL, SINGLE_ENDED,
                                     // NO_BUFFER
   parameter REFCLK_TYPE           = "USE_SYSTEM_CLOCK",
                                     // Reference clock type DIFFERENTIAL, SINGLE_ENDED,
                                     // NO_BUFFER, USE_SYSTEM_CLOCK
   parameter SYS_RST_PORT          = "FALSE",
                                     // "TRUE" - if pin is selected for sys_rst
                                     //          and IBUF will be instantiated.
                                     // "FALSE" - if pin is not selected for sys_rst
      
   // Number of taps in target IDELAY
   parameter integer DEVICE_TAPS = 32,

   
   //***************************************************************************
   // Referece clock frequency parameters
   //***************************************************************************
   parameter REFCLK_FREQ           = 200.0,
                                     // IODELAYCTRL reference clock frequency
   parameter DIFF_TERM_REFCLK      = "TRUE",
                                     // Differential Termination for idelay
                                     // reference clock input pins
      
   //***************************************************************************
   // System clock frequency parameters
   //***************************************************************************
   parameter CLK_PERIOD            = 2500,
                                     // memory tCK paramter.
                                     // # = Clock Period in pS.
   parameter nCK_PER_CLK           = 2,
                                     // # of memory CKs per fabric CLK
   parameter DIFF_TERM_SYSCLK      = "FALSE",
                                     // Differential Termination for System
                                     // clock input pins

   //***************************************************************************
   // Wait period for the read strobe (CQ) to become stable
   //***************************************************************************
   parameter CLK_STABLE            = (20*1000*1000/(CLK_PERIOD*2)),
                                     // Cycles till CQ/CQ# is stable

   //***************************************************************************
   // Debug parameter
   //***************************************************************************
   parameter DEBUG_PORT            = "OFF",
                                     // # = "ON" Enable debug signals/controls.
                                     //   = "OFF" Disable debug signals/controls.
      
   parameter RST_ACT_LOW           = 1
                                     // =1 for active low reset,
                                     // =0 for active high.
   )
  (
// Single-ended system clock
   input                                        sys_clk_i,
   input       [NUM_DEVICES-1:0]     qdriip_cq_p,     //Memory Interface
   input       [NUM_DEVICES-1:0]     qdriip_cq_n,
   input       [DATA_WIDTH-1:0]      qdriip_q,
   output wire [NUM_DEVICES-1:0]     qdriip_k_p,
   output wire [NUM_DEVICES-1:0]     qdriip_k_n,
   output wire [DATA_WIDTH-1:0]      qdriip_d,
   output wire [ADDR_WIDTH-1:0]      qdriip_sa,
   output wire                       qdriip_w_n,
   output wire                       qdriip_r_n,
   output wire [BW_WIDTH-1:0]        qdriip_bw_n,
   output wire                       qdriip_dll_off_n,
   // User Interface signals of Channel-0
   input                             app_wr_cmd0,
   input  [ADDR_WIDTH-1:0]           app_wr_addr0,
   input  [(DATA_WIDTH*BURST_LEN)-1:0] app_wr_data0,
   input  [(BW_WIDTH*BURST_LEN)-1:0]   app_wr_bw_n0,
   input                             app_rd_cmd0,
   input  [ADDR_WIDTH-1:0]           app_rd_addr0,
   output wire                       app_rd_valid0,
   output wire [(DATA_WIDTH*BURST_LEN)-1:0] app_rd_data0,

   // User Interface signals of Channel-1. It is useful only for BL2 designs.
   // All inputs of Channel-1 can be grounded for BL4 designs.
   input                             app_wr_cmd1,
   input  [ADDR_WIDTH-1:0]           app_wr_addr1,
   input  [(DATA_WIDTH*2)-1:0]         app_wr_data1,
   input  [(BW_WIDTH*2)-1:0]           app_wr_bw_n1,
   input                             app_rd_cmd1,
   input  [ADDR_WIDTH-1:0]           app_rd_addr1,
   output wire                       app_rd_valid1,
   output wire [(DATA_WIDTH*2)-1:0]    app_rd_data1,

   output wire                       clk,
   output wire                       rst_clk,
   
   output                                       init_calib_complete,
      

   // System reset - Default polarity of sys_rst pin is Active Low.
   // System reset polarity will change based on the option 
   // selected in GUI.
   input                                        sys_rst
   );

  // clogb2 function - ceiling of log base 2
  function integer clogb2 (input integer size);
    begin
      size = size - 1;
      for (clogb2=1; size>1; clogb2=clogb2+1)
        size = size >> 1;
    end
  endfunction

  localparam integer N_DATA_LANES = DATA_WIDTH / 9;
   // Number of bits needed to represent DEVICE_TAPS
   localparam integer TAP_BITS = clogb2(DEVICE_TAPS - 1);
   // Number of bits to represent number of cq/cq#'s
   localparam integer CQ_BITS  = clogb2(DATA_WIDTH/9 - 1);
   // Number of bits needed to represent number of q's
   localparam integer Q_BITS   = clogb2(DATA_WIDTH - 1);

  // Wire declarations
   wire                              freq_refclk ;
   wire                              mem_refclk ;
   wire                              pll_locked ;
   wire                              sync_pulse;
   wire                              rst_wr_clk;
   wire                              ref_dll_lock;
   wire                              rst_phaser_ref;
   wire                              cmp_err;        // Reserve for ERROR from test bench

   wire [CQ_BITS-1:0]                dbg_byte_sel;
   wire [Q_BITS-1:0]                 dbg_bit_sel;
   wire                              dbg_pi_f_inc;
   wire                              dbg_pi_f_dec;
   wire                              dbg_po_f_inc;
   wire                              dbg_po_f_dec;
   wire                              dbg_idel_up_all;
   wire                              dbg_idel_down_all;
   wire                              dbg_idel_up;
   wire                              dbg_idel_down;
   wire [(TAP_BITS*DATA_WIDTH)-1:0]    dbg_idel_tap_cnt;
   wire [TAP_BITS-1:0]               dbg_idel_tap_cnt_sel;
   wire [2:0]                         dbg_select_rdata;
   //wire [5:0]                        dbg_pi_tap_cnt;
   //wire [5:0]                        dbg_po_tap_cnt;
   //wire [(TAP_BITS*DATA_WIDTH)-1:0]    dbg_cpt_first_edge_cnt;
   //wire [(TAP_BITS*DATA_WIDTH)-1:0]    dbg_cpt_second_edge_cnt;

   //ChipScope Readpath Debug Signals
   wire [1:0]                        dbg_phy_wr_cmd_n;       //cs debug - wr command
   wire [2:0]                        dbg_byte_sel_cnt;
   wire [(ADDR_WIDTH*4)-1:0]           dbg_phy_addr;           //cs debug - address
   wire [1:0]                        dbg_phy_rd_cmd_n;       //cs debug - rd command
   wire [(DATA_WIDTH*4)-1:0]           dbg_phy_wr_data;        //cs debug - wr data
   wire                              dbg_phy_init_wr_only;
   wire                              dbg_phy_init_rd_only;
   wire [8:0]                        dbg_po_counter_read_val;
   wire                              vio_sel_rise_chk;

   wire [(TAP_BITS*N_DATA_LANES)-1:0]  dbg_cq_tapcnt;          // tap count for each cq
   wire [(TAP_BITS*N_DATA_LANES)-1:0]  dbg_cqn_tapcnt;         // tap count for each cq#
   wire [CQ_BITS-1:0]                dbg_cq_num;             // current cq/cq# being calibrated
   wire [4:0]                        dbg_valid_lat;          // latency of the system
   wire [N_DATA_LANES-1:0]           dbg_inc_latency;        // increase latency for dcb
   wire [(4*DATA_WIDTH)-1:0]           dbg_dcb_din;            // dcb data in
   wire [(4*DATA_WIDTH)-1:0]           dbg_dcb_dout;           // dcb data out
   wire [N_DATA_LANES-1:0]           dbg_error_max_latency;  // stage 2 cal max latency error
   wire                              dbg_error_adj_latency;  // stage 2 cal latency adjustment error
   wire [DATA_WIDTH-1:0]             dbg_align_rd0;
   wire [DATA_WIDTH-1:0]             dbg_align_rd1;
   wire [DATA_WIDTH-1:0]             dbg_align_fd0;
   wire [DATA_WIDTH-1:0]             dbg_align_fd1;
   wire [8:0]                        dbg_align_rd0_r;
   wire [8:0]                        dbg_align_rd1_r;
   wire [8:0]                        dbg_align_fd0_r;
   wire [8:0]                        dbg_align_fd1_r;
   reg                               rd_valid0_r;
   reg                               rd_valid1_r;
   wire [7:0]                        dbg_phy_status;
   wire                              dbg_SM_No_Pause;
   wire                              dbg_SM_en;
   //wire [(TAP_BITS*DATA_WIDTH)-1:0]    dbg_q_tapcnt;           // tap count for each q
   //wire [Q_BITS-1:0]                 dbg_q_bit;              // current q being calibrated

   wire [(DATA_WIDTH*2)-1:0]         mux_wr_data0;
   wire [(DATA_WIDTH*2)-1:0]         mux_wr_data1;
   wire [(BW_WIDTH*2)-1:0]           mux_wr_bw_n0;
   wire [(BW_WIDTH*2)-1:0]           mux_wr_bw_n1;
   wire [(DATA_WIDTH*2)-1:0]         rd_data0;
   wire [(DATA_WIDTH*2)-1:0]         rd_data1;
   wire                              sys_clk_p;
   wire                              sys_clk_n;
   wire                              mmcm_clk;
   
   wire                              clk_ref_p;
   wire                              clk_ref_n;
   wire                              clk_ref_i;
   wire                              clk_ref_in;
   wire                              iodelay_ctrl_rdy;
   wire                              clk_ref;
   wire                              sys_rst_o;
   
   wire [5:0]                        dbg_pi_counter_read_val;
   
   wire [255:0]                     dbg_rd_stage1_cal;
   wire [127:0]                     dbg_stage2_cal;
   wire [255:0]                     dbg_wr_init;
   
      

//***************************************************************************




   assign sys_clk_p = 1'b0;
   assign sys_clk_n = 1'b0;
   assign clk_ref_i = 1'b0;
   generate
    if (BURST_LEN == 4) begin: mux_data_bl4
      assign mux_wr_data0 = app_wr_data0[DATA_WIDTH*4-1:DATA_WIDTH*2];
      assign mux_wr_bw_n0 = app_wr_bw_n0[BW_WIDTH*4-1:BW_WIDTH*2];
    end else begin: mux_data_bl2
      assign mux_wr_data0 = app_wr_data0;
      assign mux_wr_bw_n0 = app_wr_bw_n0;
    end
   endgenerate

   assign mux_wr_data1  = (BURST_LEN == 4) ? app_wr_data0[DATA_WIDTH*2-1:0] : app_wr_data1;
   assign mux_wr_bw_n1  = (BURST_LEN == 4) ? app_wr_bw_n0[BW_WIDTH*2-1:0] : app_wr_bw_n1;
   assign app_rd_data0 = (BURST_LEN == 4) ? {rd_data0, rd_data1} : rd_data0;
   assign app_rd_data1 = rd_data1;
      

  generate
    if (REFCLK_TYPE == "USE_SYSTEM_CLOCK")
      assign clk_ref_in = mmcm_clk;
    else
      assign clk_ref_in = clk_ref_i;
  endgenerate

  mig_7series_v2_0_iodelay_ctrl #
    (
     .TCQ              (TCQ),
     .IODELAY_GRP      (IODELAY_GRP),
     .REFCLK_TYPE      (REFCLK_TYPE),
     .SYSCLK_TYPE      (SYSCLK_TYPE),
     .SYS_RST_PORT     (SYS_RST_PORT),
     .RST_ACT_LOW      (RST_ACT_LOW),
     .DIFF_TERM_REFCLK (DIFF_TERM_REFCLK)
     )
    u_iodelay_ctrl
      (
       // Outputs
       .iodelay_ctrl_rdy (iodelay_ctrl_rdy),
       .sys_rst_o        (sys_rst_o),
       // Inputs
       .clk_ref_p        (clk_ref_p),
       .clk_ref_n        (clk_ref_n),
       .clk_ref_i        (clk_ref_in),
       .clk_ref          (clk_ref),
       .sys_rst          (sys_rst)
       );
  mig_7series_v2_0_clk_ibuf#
    (
     .SYSCLK_TYPE      (SYSCLK_TYPE),
     .DIFF_TERM_SYSCLK (DIFF_TERM_SYSCLK)
     )
    u_clk_ibuf
      (
       .sys_clk_p        (sys_clk_p),
       .sys_clk_n        (sys_clk_n),
       .sys_clk_i        (sys_clk_i),
       .mmcm_clk         (mmcm_clk)
       );

  mig_7series_v2_0_infrastructure #
    (
     .TCQ                (TCQ),
     .nCK_PER_CLK        (nCK_PER_CLK),
     .CLKIN_PERIOD       (CLKIN_PERIOD),
     .SYSCLK_TYPE        (SYSCLK_TYPE),
     .CLKFBOUT_MULT      (CLKFBOUT_MULT),
     .DIVCLK_DIVIDE      (DIVCLK_DIVIDE),
     .CLKOUT0_DIVIDE     (CLKOUT0_DIVIDE),
     .CLKOUT1_DIVIDE     (CLKOUT1_DIVIDE),
     .CLKOUT2_DIVIDE     (CLKOUT2_DIVIDE),
     .CLKOUT3_DIVIDE     (CLKOUT3_DIVIDE),
     .RST_ACT_LOW        (RST_ACT_LOW)
     )
    u_infrastructure
      (
       // Outputs
       .rstdiv0          (rst_wr_clk),
       .clk              (clk),
       .mem_refclk       (mem_refclk),
       .freq_refclk      (freq_refclk),
       .sync_pulse       (sync_pulse),
       .auxout_clk       (),
       .ui_addn_clk_0    (),
       .ui_addn_clk_1    (),
       .ui_addn_clk_2    (),
       .ui_addn_clk_3    (),
       .ui_addn_clk_4    (),
       .pll_locked       (pll_locked),
       .mmcm_locked      (),
       .rst_phaser_ref   (rst_phaser_ref),

       // Inputs
       .mmcm_clk         (mmcm_clk),
       .sys_rst          (sys_rst_o),
       .iodelay_ctrl_rdy (iodelay_ctrl_rdy),
       .ref_dll_lock     (ref_dll_lock)
       );

  mig_7series_v2_0_qdr_phy_top #
    (
     .MEM_TYPE                       (MEM_TYPE),             //Memory Type (QDR2PLUS, QDR2)
     .CLK_PERIOD                     (CLK_PERIOD),
     .nCK_PER_CLK                    (nCK_PER_CLK),
     .REFCLK_FREQ                    (REFCLK_FREQ),
     .IODELAY_GRP                    (IODELAY_GRP),
     .RST_ACT_LOW                    (RST_ACT_LOW),
     .CLK_STABLE                     (CLK_STABLE ),          //Cycles till CQ/CQ# is stable
     .ADDR_WIDTH                     (ADDR_WIDTH ),          //Adress Width
     .DATA_WIDTH                     (DATA_WIDTH ),          //Data Width
     .BW_WIDTH                       (BW_WIDTH),             //Byte Write Width
     .BURST_LEN                      (BURST_LEN),            //Burst Length
     .NUM_DEVICES                    (NUM_DEVICES),          //Memory Devices
     .N_DATA_LANES                   (N_DATA_LANES),
     .FIXED_LATENCY_MODE             (FIXED_LATENCY_MODE),   //Fixed Latency for data reads
     .PHY_LATENCY                    (PHY_LATENCY),          //Value for Fixed Latency Mode
     .MEM_RD_LATENCY                 (MEM_RD_LATENCY),       //Value of Memory part read latency
     .CPT_CLK_CQ_ONLY                (CPT_CLK_CQ_ONLY),      //Only CQ is used for data capture and no CQ#
     .SIMULATION                     (SIMULATION),           //TRUE during design simulation
     .MASTER_PHY_CTL                 (PHY_CONTROL_MASTER_BANK),
     .PLL_LOC                        (PHY_CONTROL_MASTER_BANK),
     .INTER_BANK_SKEW                (INTER_BANK_SKEW),

     .CQ_BITS                        (CQ_BITS),              //clogb2(NUM_DEVICES - 1)
     .Q_BITS                         (Q_BITS),               //clogb2(DATA_WIDTH - 1)
     .DEVICE_TAPS                    (DEVICE_TAPS),          // Number of taps in the IDELAY chain
     .TAP_BITS                       (TAP_BITS),             // clogb2(DEVICE_TAPS - 1)
     .SIM_BYPASS_INIT_CAL            (SIM_BYPASS_INIT_CAL),
     .IBUF_LPWR_MODE                 (IBUF_LPWR_MODE ),      //Input buffer low power mode
     .IODELAY_HP_MODE                (IODELAY_HP_MODE),      //IODELAY High Performance Mode

     .DATA_CTL_B0                    (DATA_CTL_B0),          //Data write/read bits in all banks
     .DATA_CTL_B1                    (DATA_CTL_B1),
     .DATA_CTL_B2                    (DATA_CTL_B2),
     .DATA_CTL_B3                    (DATA_CTL_B3),
     .DATA_CTL_B4                    (DATA_CTL_B4),
     .ADDR_CTL_MAP                   (ADDR_CTL_MAP),

     .BYTE_LANES_B0                  (BYTE_LANES_B0),        //Byte lanes used for the complete design
     .BYTE_LANES_B1                  (BYTE_LANES_B1),
     .BYTE_LANES_B2                  (BYTE_LANES_B2),
     .BYTE_LANES_B3                  (BYTE_LANES_B3),
     .BYTE_LANES_B4                  (BYTE_LANES_B4),

     .BYTE_GROUP_TYPE_B0             (BYTE_GROUP_TYPE_B0),   //Differentiates data write and read byte lanes
     .BYTE_GROUP_TYPE_B1             (BYTE_GROUP_TYPE_B1),
     .BYTE_GROUP_TYPE_B2             (BYTE_GROUP_TYPE_B2),
     .BYTE_GROUP_TYPE_B3             (BYTE_GROUP_TYPE_B3),
     .BYTE_GROUP_TYPE_B4             (BYTE_GROUP_TYPE_B4),

     .CPT_CLK_SEL_B0                 (CPT_CLK_SEL_B0),       //Capture clock placement parameters
     .CPT_CLK_SEL_B1                 (CPT_CLK_SEL_B1),
     .CPT_CLK_SEL_B2                 (CPT_CLK_SEL_B2),

     .BIT_LANES_B0                   (PHY_0_BITLANES),       //Bits used for the complete design
     .BIT_LANES_B1                   (PHY_1_BITLANES),
     .BIT_LANES_B2                   (PHY_2_BITLANES),
     .BIT_LANES_B3                   (PHY_3_BITLANES),
     .BIT_LANES_B4                   (PHY_4_BITLANES),

     .ADD_MAP                        (ADD_MAP),              // Address bits mapping
     .RD_MAP                         (RD_MAP),
     .WR_MAP                         (WR_MAP),

     .D0_MAP                         (D0_MAP),               // Data write bits mapping
     .D1_MAP                         (D1_MAP),
     .D2_MAP                         (D2_MAP),
     .D3_MAP                         (D3_MAP),
     .D4_MAP                         (D4_MAP),
     .D5_MAP                         (D5_MAP),
     .D6_MAP                         (D6_MAP),
     .D7_MAP                         (D7_MAP),
     .BW_MAP                         (BW_MAP),
     .K_MAP                          (K_MAP),

     .Q0_MAP                         (Q0_MAP),               // Data read bits mapping
     .Q1_MAP                         (Q1_MAP),
     .Q2_MAP                         (Q2_MAP),
     .Q3_MAP                         (Q3_MAP),
     .Q4_MAP                         (Q4_MAP),
     .Q5_MAP                         (Q5_MAP),
     .Q6_MAP                         (Q6_MAP),
     .Q7_MAP                         (Q7_MAP),
     .CQ_MAP                         (CQ_MAP),

     .DEBUG_PORT                     (DEBUG_PORT),           // Debug using Chipscope controls
     .TCQ                            (TCQ)                   //Register Delay
    )

    u_qdr_phy_top
    (
     // clocking and reset
     .clk                            (clk),                //Fabric logic clock
     .rst_wr_clk                     (rst_wr_clk),         // fabric reset based on PLL lock and system input reset.
     .clk_ref                        (clk_ref),            // Idelay_ctrl reference clock
     .clk_mem                        (mem_refclk),         // Memory clock to hard PHY
     .freq_refclk                    (freq_refclk),
     .sync_pulse                     (sync_pulse),
     .pll_lock                       (pll_locked),
     .rst_clk                        (rst_clk),            //output generated based on read clocks being stable
     .sys_rst                        (sys_rst_o),                              // input system reset
     .ref_dll_lock                   (ref_dll_lock),
     .rst_phaser_ref                 (rst_phaser_ref),

     //PHY Write Path Interface
     .wr_cmd0                        (app_wr_cmd0),        //wr command 0
     .wr_cmd1                        (app_wr_cmd1),        //wr command 1
     .wr_addr0                       (app_wr_addr0),       //wr address 0
     .wr_addr1                       (app_wr_addr1),       //wr address 1
     .rd_cmd0                        (app_rd_cmd0),        //rd command 0
     .rd_cmd1                        (app_rd_cmd1),        //rd command 1
     .rd_addr0                       (app_rd_addr0),       //rd address 0
     .rd_addr1                       (app_rd_addr1),       //rd address 1
     .wr_data0                       (mux_wr_data0),       //app write data 0
     .wr_data1                       (mux_wr_data1),       //app write data 1
     .wr_bw_n0                       (mux_wr_bw_n0),       //app byte writes 0
     .wr_bw_n1                       (mux_wr_bw_n1),       //app byte writes 1

     //PHY Read Path Interface
     .init_calib_complete            (init_calib_complete),           //Calibration complete
     .rd_valid0                      (app_rd_valid0),      //Read valid for rd_data0
     .rd_valid1                      (app_rd_valid1),      //Read valid for rd_data1
     .rd_data0                       (rd_data0),           //Read data 0
     .rd_data1                       (rd_data1),           //Read data 1

     //Memory Interface
     .qdr_dll_off_n                  (qdriip_dll_off_n),   //QDR - turn off dll in mem
     .qdr_k_p                        (qdriip_k_p),         //QDR clock K
     .qdr_k_n                        (qdriip_k_n),         //QDR clock K#
     .qdr_sa                         (qdriip_sa),          //QDR Memory Address
     .qdr_w_n                        (qdriip_w_n),         //QDR Write
     .qdr_r_n                        (qdriip_r_n),         //QDR Read
     .qdr_bw_n                       (qdriip_bw_n),        //QDR Byte Writes to Mem
     .qdr_d                          (qdriip_d),           //QDR Data to Memory
     .qdr_q                          (qdriip_q),           //QDR Data from Memory
     .qdr_cq_p                       (qdriip_cq_p),        //QDR echo clock CQ
     .qdr_cq_n                       (qdriip_cq_n),        //QDR echo clock CQ#

     //Debug interface
     .dbg_phy_status                 (dbg_phy_status),
     //.dbg_SM_en                      (dbg_SM_en),
     //.dbg_SM_No_Pause                (dbg_SM_No_Pause),
     .dbg_po_counter_read_val        (dbg_po_counter_read_val),
     .dbg_pi_counter_read_val        (dbg_pi_counter_read_val),
     .dbg_phy_init_wr_only           (dbg_phy_init_wr_only),
     .dbg_phy_init_rd_only           (dbg_phy_init_rd_only),

     .dbg_byte_sel                   (dbg_byte_sel),
     .dbg_bit_sel                    (dbg_bit_sel),
     .dbg_pi_f_inc                   (dbg_pi_f_inc),
     .dbg_pi_f_dec                   (dbg_pi_f_dec),
     .dbg_po_f_inc                   (dbg_po_f_inc),
     .dbg_po_f_dec                   (dbg_po_f_dec),
     .dbg_idel_up_all                (dbg_idel_up_all),
     .dbg_idel_down_all              (dbg_idel_down_all),
     .dbg_idel_up                    (dbg_idel_up),
     .dbg_idel_down                  (dbg_idel_down),
     .dbg_idel_tap_cnt               (dbg_idel_tap_cnt),
     .dbg_idel_tap_cnt_sel           (dbg_idel_tap_cnt_sel),
     .dbg_select_rdata               (dbg_select_rdata),

     .dbg_align_rd0_r                (dbg_align_rd0_r),
     .dbg_align_rd1_r                (dbg_align_rd1_r),
     .dbg_align_fd0_r                (dbg_align_fd0_r),
     .dbg_align_fd1_r                (dbg_align_fd1_r),
     .dbg_align_rd0                  (dbg_align_rd0),
     .dbg_align_rd1                  (dbg_align_rd1),
     .dbg_align_fd0                  (dbg_align_fd0),
     .dbg_align_fd1                  (dbg_align_fd1),

     .dbg_byte_sel_cnt               (dbg_byte_sel_cnt),
     .dbg_phy_wr_cmd_n               (dbg_phy_wr_cmd_n),
     .dbg_phy_addr                   (dbg_phy_addr),
     .dbg_phy_rd_cmd_n               (dbg_phy_rd_cmd_n),
     .dbg_phy_wr_data                (dbg_phy_wr_data),
     .dbg_wr_init                    (dbg_wr_init),
     .dbg_rd_stage1_cal              (dbg_rd_stage1_cal),
     .dbg_stage2_cal                 (dbg_stage2_cal),
     .dbg_valid_lat                  (dbg_valid_lat),
     .dbg_inc_latency                (dbg_inc_latency),
     .dbg_error_max_latency          (dbg_error_max_latency),
     .error_adj_latency              (dbg_error_adj_latency)
    );
      
      




   //*********************************************************************
   // Resetting all RTL debug inputs as the debug ports are not enabled
   //*********************************************************************
   assign dbg_phy_init_wr_only = 1'b0;
   assign dbg_phy_init_rd_only = 1'b0;
   assign dbg_byte_sel         = 'b0;
   assign dbg_bit_sel          = 'b0;
   assign dbg_pi_f_inc         = 1'b0;
   assign dbg_pi_f_dec         = 1'b0;
   assign dbg_po_f_inc         = 1'b0;
   assign dbg_po_f_dec         = 1'b0;
   assign dbg_idel_up_all      = 1'b0;
   assign dbg_idel_down_all    = 1'b0;
   assign dbg_idel_up          = 1'b0;
   assign dbg_idel_down        = 1'b0;
   assign dbg_SM_en            = 1'b1;
   assign dbg_SM_No_Pause      = 1'b1;
      

endmodule
