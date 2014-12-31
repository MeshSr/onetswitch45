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
//  /   /         Filename           : example_top.v
// /___/   /\     Date Last Modified : $Date: 2011/06/02 08:36:27 $
// \   \  /  \    Date Created       : Fri Jan 14 2011
//  \___\/\___\
//
// Device           : 7 Series
// Design Name      : QDRII+ SDRAM
// Purpose          :
//   Top-level  module. This module serves as an example,
//   and allows the user to synthesize a self-contained design,
//   which they can be used to test their hardware.
//   In addition to the memory controller, the module instantiates:
//     1. Synthesizable testbench - used to model user's backend logic
//        and generate different traffic patterns
// Reference        :
// Revision History :
//*****************************************************************************

`timescale 1ps/1ps

module example_top #
  (

   parameter MEM_TYPE              = "QDR2PLUS",
                                     // # of CK/CK# outputs to memory.
   parameter DATA_WIDTH            = 36,
                                     // # of DQ (data)
   parameter BW_WIDTH              = 4,
                                     // # of byte writes (data_width/9)
   parameter ADDR_WIDTH            = 19,
                                     // Address Width
//   parameter NUM_DEVICES           = 1,
                                     // # of memory components connected
//   parameter MEM_RD_LATENCY        = 2.5,
                                     // Value of Memory part read latency
//   parameter CPT_CLK_CQ_ONLY       = "TRUE",
                                     // whether CQ and its inverse are used for the data capture
//   parameter INTER_BANK_SKEW       = 0,
                                     // Clock skew between two adjacent banks
//   parameter PHY_CONTROL_MASTER_BANK = 1,
                                     // The bank index where master PHY_CONTROL resides,
                                     // equal to the PLL residing bank

   //***************************************************************************
   // The following parameters are mode register settings
   //***************************************************************************
   parameter BURST_LEN             = 4,
                                     // Burst Length of the design (4 or 2).
//   parameter FIXED_LATENCY_MODE    = 0,
                                     // Enable Fixed Latency
//   parameter PHY_LATENCY           = 0,
                                     // Value for Fixed Latency Mode
                                     // Expected Latency
   
   //***************************************************************************
   // The following parameters are multiplier and divisor factors for MMCM.
   // Based on the selected design frequency these parameters vary.
   //***************************************************************************
//   parameter CLKIN_PERIOD          = 5000,
                                     // Input Clock Period
//   parameter CLKFBOUT_MULT         = 4,
                                     // write PLL VCO multiplier
//   parameter DIVCLK_DIVIDE         = 1,
                                     // write PLL VCO divisor
//   parameter CLKOUT0_DIVIDE        = 2,
                                     // VCO output divisor for PLL output clock (CLKOUT0)
//   parameter CLKOUT1_DIVIDE        = 2,
                                     // VCO output divisor for PLL output clock (CLKOUT1)
//   parameter CLKOUT2_DIVIDE        = 32,
                                     // VCO output divisor for PLL output clock (CLKOUT2)
//   parameter CLKOUT3_DIVIDE        = 4,
                                     // VCO output divisor for PLL output clock (CLKOUT3)

   //***************************************************************************
   // Simulation parameters
   //***************************************************************************
//   parameter SIM_BYPASS_INIT_CAL   = "OFF",
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
//   parameter BYTE_LANES_B0         = 4'b1111,
//                                     // Byte lanes used in an IO column.
//   parameter BYTE_LANES_B1         = 4'b1111,
//                                     // Byte lanes used in an IO column.
//   parameter BYTE_LANES_B2         = 4'b1100,
//                                     // Byte lanes used in an IO column.
//   parameter BYTE_LANES_B3         = 4'b0000,
//                                     // Byte lanes used in an IO column.
//   parameter BYTE_LANES_B4         = 4'b0000,
//                                     // Byte lanes used in an IO column.
//   parameter DATA_CTL_B0           = 4'b1111,
//                                     // Indicates Byte lane is data byte lane
//                                     // or control Byte lane. '1' in a bit
//                                     // position indicates a data byte lane and
//                                     // a '0' indicates a control byte lane
//   parameter DATA_CTL_B1           = 4'b1111,
//                                     // Indicates Byte lane is data byte lane
//                                     // or control Byte lane. '1' in a bit
//                                     // position indicates a data byte lane and
//                                     // a '0' indicates a control byte lane
//   parameter DATA_CTL_B2           = 4'b0000,
//                                     // Indicates Byte lane is data byte lane
//                                     // or control Byte lane. '1' in a bit
//                                     // position indicates a data byte lane and
//                                     // a '0' indicates a control byte lane
//   parameter DATA_CTL_B3           = 4'b0000,
//                                     // Indicates Byte lane is data byte lane
//                                     // or control Byte lane. '1' in a bit
//                                     // position indicates a data byte lane and
//                                     // a '0' indicates a control byte lane
//   parameter DATA_CTL_B4           = 4'b0000,
//                                     // Indicates Byte lane is data byte lane
//                                     // or control Byte lane. '1' in a bit
//                                     // position indicates a data byte lane and
//                                     // a '0' indicates a control byte lane
//
//   // this parameter specifies the location of the capture clock with respect
//   // to read data.
//   // Each byte refers to the information needed for data capture in the corresponding byte lane
//   // Lower order nibble - is either 4'h1 or 4'h2. This refers to the capture clock in T1 or T2 byte lane
//   // Higher order nibble - 4'h0 refers to clock present in the bank below the read data,
//   //                       4'h1 refers to clock present in the same bank as the read data,
//   //                       4'h2 refers to clock present in the bank above the read data.
//   parameter CPT_CLK_SEL_B0  = 32'h11_11_11_11,
//   parameter CPT_CLK_SEL_B1  = 32'h00_00_00_00,
//   parameter CPT_CLK_SEL_B2  = 32'h00_00_00_00,
//
//   parameter PHY_0_BITLANES       = 48'hFF8_FF1_D3F_EFC,
//                                     // The bits used inside the Bank0 out of 48 pins.
//   parameter PHY_1_BITLANES       = 48'h3FE_FFE_CFF_FFC,
//                                     // The bits used inside the Bank1 out of 48 pins.
//   parameter PHY_2_BITLANES       = 48'hEFE_FFD_000_000,
//                                     // The bits used inside the Bank2 out of 48 pins.
//   parameter PHY_3_BITLANES       = 48'h000_000_000_000,
//                                     // The bits used inside the Bank3 out of 48 pins.
//   parameter PHY_4_BITLANES       = 48'h000_000_000_000,
//                                     // The bits used inside the Bank4 out of 48 pins.
//
//   // Differentiates the INPUT and OUTPUT bytelates (1-input, 0-output)
//   parameter BYTE_GROUP_TYPE_B0 = 4'b1111,
//   parameter BYTE_GROUP_TYPE_B1 = 4'b0000,
//   parameter BYTE_GROUP_TYPE_B2 = 4'b0000,
//   parameter BYTE_GROUP_TYPE_B3 = 4'b0000,
//   parameter BYTE_GROUP_TYPE_B4 = 4'b0000,
//
//   // mapping for K/K# clocks. This parameter needs to have an 8-bit value per component
//   // since the phy drives a K/K# clock pair to each memory it interfaces to. A 3 component
//   // interface is supported for now. This parameter needs to be used in conjunction with
//   // NUM_DEVICES parameter which provides information on the number. of components being
//   // interfaced to.
//   // the 8 bit for each component is defined as follows:
//   // [7:4] - bank number ; [3:0] - byte lane number
//   parameter K_MAP = 48'h00_00_00_00_00_13,
//
//   // mapping for CQ/CQ# clocks. This parameter needs to have an 4-bit value per component
//   // since the phy drives a CQ/CQ# clock pair to each memory it interfaces to. A 3 component
//   // interface is supported for now. This parameter needs to be used in conjunction with
//   // NUM_DEVICES parameter which provides information on the number. of components being
//   // interfaced to.
//   // the 4 bit for each component is defined as follows:
//   // [3:0] - bank number
//   parameter CQ_MAP = 48'h00_00_00_00_00_01,
//
//   //**********************************************************************************************
//   // Each of the following parameter contains the byte_lane and bit position information for
//   // the address/control, data write and data read signals. Each bit has 12 bits and the details are
//   // [3:0] - Bit position within a byte lane .
//   // [7:4] - Byte lane position within a bank. [5:4] have the byte lane position and others reserved.
//   // [11:8] - Bank position. [10:8] have the bank position. [11] tied to zero .
//   //**********************************************************************************************
//
//   // Mapping for address and control signals.
//
//   parameter RD_MAP = 12'h220,      // Mapping for read enable signal
//   parameter WR_MAP = 12'h222,      // Mapping for write enable signal
//
//   // Mapping for address signals. Supports upto 22 bits of address bits (22*12)
//   parameter ADD_MAP = 264'h000_000_000_223_236_22B_23B_235_234_225_229_224_232_228_23A_231_237_239_233_227_22A_226,
//
//   // Mapping for the byte lanes used for address/control signals. Supports a maximum of 3 banks.
//   parameter ADDR_CTL_MAP = 32'h00_00_23_22,
//
//   // Mapping for data WRITE signals
//
//   // Mapping for data write bytes (9*12)
//   parameter D0_MAP  = 108'h137_134_136_135_132_133_131_138_139, //byte 0
//   parameter D1_MAP  = 108'h121_124_125_122_126_127_12A_123_12B, //byte 1
//   parameter D2_MAP  = 108'h102_103_108_104_106_105_107_10A_10B, //byte 2
//   parameter D3_MAP  = 108'h116_117_115_11A_114_113_111_112_110, //byte 3
//   parameter D4_MAP  = 108'h000_000_000_000_000_000_000_000_000, //byte 4
//   parameter D5_MAP  = 108'h000_000_000_000_000_000_000_000_000, //byte 5
//   parameter D6_MAP  = 108'h000_000_000_000_000_000_000_000_000, //byte 6
//   parameter D7_MAP  = 108'h000_000_000_000_000_000_000_000_000, //byte 7
//
//   // Mapping for byte write signals (8*12)
//   parameter BW_MAP = 84'h000_000_000_11B_109_128_129,
//
//   // Mapping for data READ signals
//
//   // Mapping for data read bytes (9*12)
//   parameter Q0_MAP  = 108'h033_039_034_036_035_03A_03B_037_038, //byte 0
//   parameter Q1_MAP  = 108'h029_020_028_026_027_02A_02B_024_025, //byte 1
//   parameter Q2_MAP  = 108'h015_014_01A_01B_011_010_013_012_018, //byte 2
//   parameter Q3_MAP  = 108'h00B_003_007_002_005_004_009_006_00A, //byte 3
//   parameter Q4_MAP  = 108'h000_000_000_000_000_000_000_000_000, //byte 4
//   parameter Q5_MAP  = 108'h000_000_000_000_000_000_000_000_000, //byte 5
//   parameter Q6_MAP  = 108'h000_000_000_000_000_000_000_000_000, //byte 6
//   parameter Q7_MAP  = 108'h000_000_000_000_000_000_000_000_000, //byte 7

   //***************************************************************************
   // IODELAY and PHY related parameters
   //***************************************************************************
//   parameter IODELAY_HP_MODE       = "ON",
//                                     // to phy_top
//   parameter IBUF_LPWR_MODE        = "OFF",
//                                     // to phy_top
   parameter TCQ                   = 100,
   //parameter IODELAY_GRP           = "MIG_7SERIES_0_IODELAY_MIG",
                                     // It is associated to a set of IODELAYs with
                                     // an IDELAYCTRL that have same IODELAY CONTROLLER
                                     // clock frequency.
//   parameter SYSCLK_TYPE           = "SINGLE_ENDED",
                                     // System clock type DIFFERENTIAL, SINGLE_ENDED,
                                     // NO_BUFFER
//   parameter REFCLK_TYPE           = "USE_SYSTEM_CLOCK",
                                     // Reference clock type DIFFERENTIAL, SINGLE_ENDED,
                                     // NO_BUFFER, USE_SYSTEM_CLOCK
//   parameter SYS_RST_PORT          = "FALSE",
                                     // "TRUE" - if pin is selected for sys_rst
                                     //          and IBUF will be instantiated.
                                     // "FALSE" - if pin is not selected for sys_rst
      
   // Number of taps in target IDELAY
   parameter integer DEVICE_TAPS = 32,

   
   //***************************************************************************
   // Referece clock frequency parameters
   //***************************************************************************
//   parameter REFCLK_FREQ           = 200.0,
                                     // IODELAYCTRL reference clock frequency
//   parameter DIFF_TERM_REFCLK      = "TRUE",
                                     // Differential Termination for idelay
                                     // reference clock input pins
      
   //***************************************************************************
   // System clock frequency parameters
   //***************************************************************************
//   parameter CLK_PERIOD            = 2500,
                                     // memory tCK paramter.
                                     // # = Clock Period in pS.
   parameter nCK_PER_CLK           = 2,
                                     // # of memory CKs per fabric CLK
//   parameter DIFF_TERM_SYSCLK      = "FALSE",
                                     // Differential Termination for System
                                     // clock input pins

      //***************************************************************************
   // Traffic Gen related parameters
   //***************************************************************************
   parameter BL_WIDTH              = 8,
   parameter PORT_MODE             = "BI_MODE",
   parameter DATA_MODE             = 4'b0010,
   parameter EYE_TEST              = "FALSE",
                                     // set EYE_TEST = "TRUE" to probe memory
                                     // signals. Traffic Generator will only
                                     // write to one single location and no
                                     // read transactions will be generated.
   parameter DATA_PATTERN          = "DGEN_ALL",
                                      // "DGEN_HAMMER", "DGEN_WALKING1",
                                      // "DGEN_WALKING0","DGEN_ADDR","
                                      // "DGEN_NEIGHBOR","DGEN_PRBS","DGEN_ALL"
   parameter CMD_PATTERN           = "CGEN_ALL",
                                      // "CGEN_PRBS","CGEN_FIXED","CGEN_BRAM",
                                      // "CGEN_SEQUENTIAL", "CGEN_ALL"
   parameter CMD_WDT               = 'h3FF,
   parameter WR_WDT                = 'h1FFF,
   parameter RD_WDT                = 'h3FF,
   parameter BEGIN_ADDRESS         = 32'h00000000,
   parameter END_ADDRESS           = 32'h00000fff,
   parameter PRBS_EADDR_MASK_POS   = 32'hfffff000,

   //***************************************************************************
   // Wait period for the read strobe (CQ) to become stable
   //***************************************************************************
   //parameter CLK_STABLE            = (20*1000*1000/(CLK_PERIOD*2)),
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
   input       [0:0]     qdriip_cq_p,     //Memory Interface
   input       [0:0]     qdriip_cq_n,
   input       [35:0]      qdriip_q,
   output wire [0:0]     qdriip_k_p,
   output wire [0:0]     qdriip_k_n,
   output wire [35:0]      qdriip_d,
   output wire [18:0]      qdriip_sa,
   output wire                       qdriip_w_n,
   output wire                       qdriip_r_n,
   output wire [3:0]        qdriip_bw_n,
   output wire                       qdriip_dll_off_n,
   output                                       tg_compare_error,
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

   localparam APP_DATA_WIDTH        = BURST_LEN*DATA_WIDTH;
   localparam APP_MASK_WIDTH        = APP_DATA_WIDTH / 9;
   // Number of bits needed to represent DEVICE_TAPS
   localparam integer TAP_BITS = clogb2(DEVICE_TAPS - 1);
   // Number of bits to represent number of cq/cq#'s
   localparam integer CQ_BITS  = clogb2(DATA_WIDTH/9 - 1);
   // Number of bits needed to represent number of q's
   localparam integer Q_BITS   = clogb2(DATA_WIDTH - 1);

  // Wire declarations
   wire                            clk;
   wire                            rst_clk;
   wire                            cmp_err;
   wire                            dbg_clear_error;
   wire                            app_wr_cmd0;
   wire                            app_wr_cmd1;
   wire [ADDR_WIDTH-1:0]           app_wr_addr0;
   wire [ADDR_WIDTH-1:0]           app_wr_addr1;
   wire                            app_rd_cmd0;
   wire                            app_rd_cmd1;
   wire [ADDR_WIDTH-1:0]           app_rd_addr0;
   wire [ADDR_WIDTH-1:0]           app_rd_addr1;
   wire [(BURST_LEN*DATA_WIDTH)-1:0] app_wr_data0;
   wire [(DATA_WIDTH*2)-1:0]         app_wr_data1;
   wire [(BURST_LEN*BW_WIDTH)-1:0]   app_wr_bw_n0;
   wire [(BW_WIDTH*2)-1:0]           app_wr_bw_n1;
   wire                            app_cal_done;
   wire                            app_rd_valid0;
   wire                            app_rd_valid1;
   wire [(BURST_LEN*DATA_WIDTH)-1:0] app_rd_data0;
   wire [(DATA_WIDTH*2)-1:0]         app_rd_data1;
   wire [(ADDR_WIDTH*2)-1:0]         tg_addr;
   wire [APP_DATA_WIDTH-1:0]       cmp_data;
   wire [47:0]                     wr_data_counts;
   wire [47:0]                     rd_data_counts;

   (*mark_debug  = "TRUE" *) wire                            vio_modify_enable;
   (*mark_debug  = "TRUE" *) wire [3:0]                      vio_data_mode_value;
   (*mark_debug  = "TRUE" *) wire                            vio_pause_traffic;
   (*mark_debug  = "TRUE" *) wire [2:0]                      vio_addr_mode_value;
   (*mark_debug  = "TRUE" *) wire [3:0]                      vio_instr_mode_value;
   (*mark_debug  = "TRUE" *) wire [1:0]                      vio_bl_mode_value;
   (*mark_debug  = "TRUE" *) wire [7:0]                      vio_fixed_bl_value;
   (*mark_debug  = "TRUE" *) wire [2:0]                      vio_fixed_instr_value;
   (*mark_debug  = "TRUE" *) wire                            vio_data_mask_gen;

//***************************************************************************






      
// Start of User Design top instance
//***************************************************************************
// The User design is instantiated below. The memory interface ports are
// connected to the top-level and the application interface ports are
// connected to the traffic generator module. This provides a reference
// for connecting the memory controller to system.
//***************************************************************************

  mig_7series_0 //#
//    (
//     #parameters_mapping_user_design_top_instance#
//     .RST_ACT_LOW                      (RST_ACT_LOW)
//     )
    u_mig_7series_0
      (
       
     
     // Memory interface ports
     .qdriip_cq_p                     (qdriip_cq_p),
     .qdriip_cq_n                     (qdriip_cq_n),
     .qdriip_q                        (qdriip_q),
     .qdriip_k_p                      (qdriip_k_p),
     .qdriip_k_n                      (qdriip_k_n),
     .qdriip_d                        (qdriip_d),
     .qdriip_sa                       (qdriip_sa),
     .qdriip_w_n                      (qdriip_w_n),
     .qdriip_r_n                      (qdriip_r_n),
     .qdriip_bw_n                     (qdriip_bw_n),
     .qdriip_dll_off_n                (qdriip_dll_off_n),
     .init_calib_complete              (init_calib_complete),
      
     
     // Application interface ports
     .app_wr_cmd0                     (app_wr_cmd0),
     .app_wr_cmd1                     (1'b0),
     .app_wr_addr0                    (app_wr_addr0),
     .app_wr_addr1                    ({ADDR_WIDTH{1'b0}}),
     .app_rd_cmd0                     (app_rd_cmd0),
     .app_rd_cmd1                     (1'b0),
     .app_rd_addr0                    (app_rd_addr0),
     .app_rd_addr1                    ({ADDR_WIDTH{1'b0}}),
     .app_wr_data0                    (app_wr_data0),
     .app_wr_data1                    ({DATA_WIDTH*2{1'b0}}),
     .app_wr_bw_n0                    ({BURST_LEN*BW_WIDTH{1'b0}}),
     .app_wr_bw_n1                    ({2*BW_WIDTH{1'b0}}),
     .app_rd_valid0                   (app_rd_valid0),
     .app_rd_valid1                   (app_rd_valid1),
     .app_rd_data0                    (app_rd_data0),
     .app_rd_data1                    (app_rd_data1),
     .clk                             (clk),
     .rst_clk                         (rst_clk),
      
     
     // System Clock Ports
     .sys_clk_i                       (sys_clk_i),
      
       .sys_rst                        (sys_rst)
       );
// End of User Design top instance


//***************************************************************************
// The traffic generation module instantiated below drives traffic (patterns)
// on the application interface of the memory controller
//***************************************************************************

  assign app_wr_addr0 = tg_addr[ADDR_WIDTH-1:0];
  assign app_rd_addr0 = tg_addr[ADDR_WIDTH-1:0];

  mig_7series_v2_0_traffic_gen_top #
    (
     .TCQ                 (TCQ),
     .SIMULATION          (SIMULATION),
     .FAMILY              ("VIRTEX7"),
     .MEM_TYPE            (MEM_TYPE),
     //.BL_WIDTH            (BL_WIDTH),
     .nCK_PER_CLK         (nCK_PER_CLK),
     .NUM_DQ_PINS         (DATA_WIDTH),
     .MEM_BURST_LEN       (BURST_LEN),
     .PORT_MODE           (PORT_MODE),
     .DATA_PATTERN        (DATA_PATTERN),
     .CMD_PATTERN         (CMD_PATTERN),
     .DATA_WIDTH          (APP_DATA_WIDTH),
     .ADDR_WIDTH          (ADDR_WIDTH),
     .DATA_MODE           (DATA_MODE),
     .BEGIN_ADDRESS       (BEGIN_ADDRESS),
     .END_ADDRESS         (END_ADDRESS),
     .PRBS_EADDR_MASK_POS (PRBS_EADDR_MASK_POS),
     .CMD_WDT             (CMD_WDT),
     .RD_WDT              (RD_WDT),
     .WR_WDT              (WR_WDT),
     .EYE_TEST            (EYE_TEST)
     )
    u_traffic_gen_top
      (
       .clk                  (clk),
       .rst                  (rst_clk),
       .tg_only_rst          (rst_clk),
       .manual_clear_error   (dbg_clear_error),
       .memc_init_done       (init_calib_complete),
       .memc_cmd_full        (1'b0),
       .memc_cmd_en          (),
       .memc_cmd_instr       (),
       .memc_cmd_bl          (),
       .memc_cmd_addr        (tg_addr[31:0]),
       .memc_wr_en           (),
       .memc_wr_end          (),
       .memc_wr_mask         (),
       .memc_wr_data         (app_wr_data0),
       .memc_wr_full         (1'b0),
       .memc_rd_en           (),
       .memc_rd_data         (app_rd_data0),
       .memc_rd_empty        (~app_rd_valid0),
       .qdr_wr_cmd_o         (app_wr_cmd0),
       .qdr_rd_cmd_o         (app_rd_cmd0),
       .vio_pause_traffic    (vio_pause_traffic),
       .vio_modify_enable    (vio_modify_enable),
       .vio_data_mode_value  (vio_data_mode_value),
       .vio_addr_mode_value  (vio_addr_mode_value),
       .vio_instr_mode_value (vio_instr_mode_value),
       .vio_bl_mode_value    (vio_bl_mode_value),
       .vio_fixed_bl_value   (vio_fixed_bl_value),
       .vio_fixed_instr_value(vio_fixed_instr_value),
       .vio_data_mask_gen    (vio_data_mask_gen),
       .fixed_addr_i         (32'b0),
       .fixed_data_i         (32'b0),
       .simple_data0         (32'b0),
       .simple_data1         (32'b0),
       .simple_data2         (32'b0),
       .simple_data3         (32'b0),
       .simple_data4         (32'b0),
       .simple_data5         (32'b0),
       .simple_data6         (32'b0),
       .simple_data7         (32'b0),
       .wdt_en_i             (1'b1),
       .bram_cmd_i           (39'b0),
       .bram_valid_i         (1'b0),
       .bram_rdy_o           (),
       .cmp_data             (cmp_data),
       .cmp_data_valid       (),
       .cmp_error            (dbg_cmp_err),
       .wr_data_counts       (wr_data_counts),
       .rd_data_counts       (rd_data_counts),
       .cumlative_dq_lane_error (),
       .cmd_wdt_err_o        (),
       .wr_wdt_err_o         (),
       .rd_wdt_err_o         (),
       .mem_pattern_init_done(),
       .error                (tg_compare_error),
       .error_status         ()
       );


   //*****************************************************************
   // Default values are assigned to the debug inputs of the traffic
   // generator
   //*****************************************************************
   assign vio_modify_enable     = 1'b0;
   assign vio_data_mode_value   = 4'b0010;
   assign vio_addr_mode_value   = 3'b011;
   assign vio_instr_mode_value  = 4'b0010;
   assign vio_bl_mode_value     = 2'b10;
   assign vio_fixed_bl_value    = 8'd32;
   assign vio_data_mask_gen     = 1'b0;
   assign vio_pause_traffic     = 1'b0;
   assign vio_fixed_instr_value = 3'b001;
   assign dbg_clear_error       = 1'b0;
      

endmodule
