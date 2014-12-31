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
// \   \   \/     Version            : %version 
//  \   \         Application        : MIG
//  /   /         Filename           : qdr_rld_phy_read_stage2_cal.v
// /___/   /\     Date Last Modified    : $date$          
// \   \  /  \    Date Created          : Nov 10 2008 
//  \___\/\___\
//
//Device: 7 Series
//Design: QDRII+ SRAM / RLDRAM II SDRAM
//
//Purpose:
//  This module
//  1. Sets the latency for fixed latency mode.
//  2. Matches latency across multiple memories.
//  3. Determines the amount of latency delay required to generate the valids.
//
//Revision History:	4/27/2013   Fixed "error_adj_latency" such that if  target PHY_LATENCY is
//                              less than measured latency will cause calibration not complete in FIXED_LATENCY_MODE = 1. 
//	                4/29/2013   Increased the pi_edge_adv_wait_cnt bus width .
////////////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps

module mig_7series_v2_0_qdr_rld_phy_read_stage2_cal #
(
  parameter BURST_LEN           = 4,  // Burst Length
  parameter MEM_TYPE            = "QDR2PLUS",
  parameter nCK_PER_CLK         = 2,
  parameter DATA_WIDTH          = 72, // Total data width across all memories
  parameter BW_WIDTH            = 8,
  parameter N_DATA_LANES        = 4,  // Number of memory devices - for v7 should reflect no. of byte lanes
  parameter BYTE_LANE_WIDTH     = 9,  // Width of each memory - needs to now reflect widht of the byte group.
  parameter FIXED_LATENCY_MODE  = 0,  // 0 = minimum latency mode, 1 = fixed latency mode
  parameter PHY_LATENCY         = 16, // Indicates the desired latency for fixed latency mode
  parameter TCQ                 = 100 // Register delay
)
(
  // System Signals
  input                              clk,                // main system half freq clk
  input                              rst_clk,            // reset syncrhonized to clk
  input                              edge_adv_cal_start, // Start edge adv cal
  input [3:0]                        dbg_byte_sel, 
  output reg                         edge_adv_cal_done,  // indicates all the byte lanes are now aligned to rising edge of clk_div
  input                              cal_stage2_start,   // indicates latency calibration has begun
  output reg                         cal_done,           // indicates overall calibration is complete
                                     
  // Write Interface                 
  input       [nCK_PER_CLK-1:0]      int_rd_cmd_n,       // read command(s) - only bit 0 is used for BL4

  // DCB Interface
   
  input       [nCK_PER_CLK*DATA_WIDTH-1:0]     iserdes_rd,
  input       [nCK_PER_CLK*DATA_WIDTH-1:0]     iserdes_fd,
    
  output reg  [N_DATA_LANES-1:0]     phase_valid,
  output reg  [N_DATA_LANES-1:0]     inc_latency = 0,    // indicates latency through a DCB to be increased
  
  // Valid Generator Interface
  output reg  [4:0]                   valid_latency,     // amount to delay read command
  output reg                          pi_edge_adv,
  output reg                          bitslip,
  output reg  [2:0]                   byte_cnt,
  output reg                          max_lat_done_r,    // delayed version of max_lat_done
 
  // Chipscope/Debug and Error
  output reg  [N_DATA_LANES-1:0]      error_max_latency,  // mem_latency counter has maxed out
  output reg                          error_adj_latency,  // target PHY_LATENCY is invalid
  output      [127:0]                 dbg_stage2_cal      // general debug port
);

  //Looking for a single rd command to generate our rd_valid
  //Even if more read commands are sent to memory the phy is responsible to
  //make sure it sends the expected pattern to this module to make sure we can
  //figure out the data valid
  localparam DIV2_RD_CMD_PATTERN = ((MEM_TYPE == "QDR2PLUS") && (BURST_LEN == 2)) ? 2'b00 : 2'b10 ;
  localparam DIV4_RD_CMD_PATTERN = 4'b1110;
  localparam RD_CMD_PATTERN      = (nCK_PER_CLK == 2) ? DIV2_RD_CMD_PATTERN :
                                                        DIV4_RD_CMD_PATTERN;

  //Wait time in clock cycles
  //Max of 31 supported, else you need to expand register bits
  localparam  START_WAIT_TIME = (nCK_PER_CLK == 2) ? 3 : 12;

  localparam  PATTERN_2 = 9'h022;
  localparam  PATTERN_3 = 9'h133;
  localparam  PATTERN_5 = 9'h155;
  localparam  PATTERN_6 = 9'h066;
  
  localparam  PATTERN_9 = 9'h199;
  localparam  PATTERN_A = 9'h0AA;
  localparam  PATTERN_C = 9'h0CC;
  localparam  PATTERN_D = 9'h1DD;
  
  // stage2 - R0_F0_R1_F1 :  A-5-0-F pattern 
                                                
  localparam [DATA_WIDTH*4-1:0] LAT_CAL_DATA = { {BW_WIDTH{PATTERN_A}},{BW_WIDTH{PATTERN_5}},
                                                {DATA_WIDTH{1'b0}},{DATA_WIDTH{1'b1}}};
												
  localparam [DATA_WIDTH*4-1:0] LAT_CAL_DATA2 = { {DATA_WIDTH/9{PATTERN_9}},
												  {DATA_WIDTH/9{PATTERN_6}},
												  {DATA_WIDTH/9{PATTERN_D}},
												  {DATA_WIDTH/9{PATTERN_2}}};

  // Wires and Regs
  wire                                 bl8_rd_cmd_int;                 // inidicates any BL8 rd_cmd
  wire                                 bl4_rd_cmd_int;                 // inidicates any BL4 rd_cmd
  wire                                 bl2_rd_cmd_int;                 // indicates any BL2 rd_cmd
  reg                                  bl8_rd_cmd_int_r;               // delayed version of bl8_rd_cmd_int
  reg                                  bl8_rd_cmd_int_r2;              // delayed version of bl8_rd_cmd_r
  reg                                  bl4_rd_cmd_int_r;               // delayed version of bl4_rd_cmd_int
  reg                                  bl2_rd_cmd_int_r;               // delayed version of bl2_rd_cmd_int
  wire                                 rd_cmd;                         // indicates rd_cmd for latency calibration
  wire                                 lat_measure_done;               // indicates latency measurement is complete
  wire                                 en_mem_cntr;                    // memory counter enable
  wire                                 start_lat_adj;                  // indicates that latency adjustment can begin
  reg                                  en_mem_latency;                 // memory latency counter enable
  reg [4:0]                            latency_cntr [N_DATA_LANES-1:0]; // counter indicating the latency for each memory in the inteface
  reg [4:0]                            latency_cntr_r [N_DATA_LANES-1:0];
  wire [DATA_WIDTH-1:0]                rd0;                            // rising data 0 for all memories
  wire [DATA_WIDTH-1:0]                fd0;                            // falling data 0 for all memories
  wire [DATA_WIDTH-1:0]                rd1;                            // rising data 1 for all memories
  wire [DATA_WIDTH-1:0]                fd1;                            // falling data 1 for all memories
  wire [DATA_WIDTH-1:0]                rd2;                            // rising data 2 for all memories
  wire [DATA_WIDTH-1:0]                fd2;                            // falling data 2 for all memories
  wire [DATA_WIDTH-1:0]                rd3;                            // rising data 3 for all memories
  wire [DATA_WIDTH-1:0]                fd3;                            // falling data 3 for all memories
  
  reg [DATA_WIDTH-1:0]                 rd1_r;                            // rising data 0 for all memories
  reg [DATA_WIDTH-1:0]                 fd1_r;                            // rising data 0 for all memories
  
  wire [DATA_WIDTH-1:0]                rd0_lat;                        // rising data 0 latency cal training pattern
  wire [DATA_WIDTH-1:0]                fd0_lat;                        // falling data 0 latency cal training pattern
  wire [DATA_WIDTH-1:0]                rd1_lat;                        // rising data 1 latency cal training pattern
  wire [DATA_WIDTH-1:0]                fd1_lat;                        // falling data 1 latency cal training pattern
  wire [DATA_WIDTH-1:0]                rd2_lat;                        // rising data 2 latency cal training pattern
  wire [DATA_WIDTH-1:0]                fd2_lat;                        // falling data 2 latency cal training pattern
  wire [DATA_WIDTH-1:0]                rd3_lat;                        // rising data 3 latency cal training pattern
  wire [DATA_WIDTH-1:0]                fd3_lat;                        // falling data 3 latency cal training pattern
  
  reg  [N_DATA_LANES-1:0]              rd0_vld;                       // indicates rd0 matches respective training pattern
  reg  [N_DATA_LANES-1:0]              fd0_vld;                       // indicates fd0 matches respective training pattern
  reg  [N_DATA_LANES-1:0]              rd1_vld;                       // indicates rd1 matches respective training pattern
  reg  [N_DATA_LANES-1:0]              fd1_vld;                       // indicates fd1 matches respective training pattern
  reg  [N_DATA_LANES-1:0]              rd2_vld;                       // indicates rd2 matches respective training pattern
  reg  [N_DATA_LANES-1:0]              fd2_vld;                       // indicates fd2 matches respective training pattern
  reg  [N_DATA_LANES-1:0]              rd3_vld;                       // indicates rd3 matches respective training pattern
  reg  [N_DATA_LANES-1:0]              fd3_vld;                       // indicates fd3 matches respective training pattern
                                      
  reg  [N_DATA_LANES-1:0]              rd0_bslip_vld;                       // indicates bitslip data matches respective training pattern
  reg  [N_DATA_LANES-1:0]              fd0_bslip_vld;                       // indicates bitslip data matches respective training pattern
  reg  [N_DATA_LANES-1:0]              rd1_bslip_vld;                       // indicates bitslip data matches respective training pattern
  reg  [N_DATA_LANES-1:0]              fd1_bslip_vld;                       // indicates bitslip data matches respective training pattern  
  wire [N_DATA_LANES-1:0]              phase_vld_check;
  wire [N_DATA_LANES-1:0]              phase_vld;
  wire [N_DATA_LANES-1:0]              phase_bslip_vld; 
  reg  [N_DATA_LANES-1:0]              phase_bslip_vld_chk;  
  
  
  reg  [BW_WIDTH-1 :0]                 phase_error; 
  reg  [3:0]                           pi_edge_adv_wait_cnt;
  
  reg [4:0]                            mem_latency  [N_DATA_LANES-1:0]; // register indicating the measured latency for each memory
  reg [N_DATA_LANES-1:0]               latency_measured;               // indicates that the latency has been measured for each memory
  reg [4:0]                            mem_cntr;                       // indicates which memory is being operated on
  reg                                  mem_cntr_done;                  // indicates mem_cntr has cycled through all memories
  reg [4:0]                            max_latency;                    // maximum measured latency  
  reg                                  max_lat_done;                   // indicates maximum latency measurement is done
  reg [4:0]                            mem_lat_adj [N_DATA_LANES-1:0];  // amount latency needs incremented
  reg [N_DATA_LANES-1:0]              lat_adj_done;                   // indicates latency adjustment is done
  reg                                 inc_byte_cnt;
  reg                                 clkdiv_phase_cal_done_r;
  reg                                 clkdiv_phase_cal_done_2r;
  reg                                 clkdiv_phase_cal_done_3r;
  reg                                 clkdiv_phase_cal_done_4r;
  reg                                 clkdiv_phase_cal_done_5r;
     
  reg                                 clkdiv_phase_cal_done; // clkdiv alignment done
  reg                                 cal_stage2_done;
  
  
  reg                                 edge_adv_cal_start_r;
  reg                                 edge_adv_cal_start_r2;
  reg [4:0]                           cal_stage2_cnt;
  reg [4:0]                           start_cnt;
  
  
  wire [4:0] latency_cntr_0;
  wire [4:0] latency_cntr_1;
  wire [4:0] mem_latency_0;
  wire [4:0] mem_latency_1;
  wire [4:0] mem_lat_adj_0;
  wire [4:0] mem_lat_adj_1;
  
  assign latency_cntr_0 = latency_cntr[0];
  assign latency_cntr_1 = latency_cntr[1];
  
  assign mem_latency_0 = mem_latency[0];
  assign mem_latency_1 = mem_latency[1];
  
  assign mem_lat_adj_0 = mem_lat_adj[0];
  assign mem_lat_adj_1 = mem_lat_adj[1];
  
  //Generic start signal
  always @(posedge clk) begin
    if (rst_clk) begin
      edge_adv_cal_start_r  <= #TCQ 0;
    end else if (start_cnt == (START_WAIT_TIME-1)) begin
      edge_adv_cal_start_r  <= #TCQ 1;
    end else begin
	  edge_adv_cal_start_r  <= #TCQ edge_adv_cal_start_r;
    end
  end
  
  //Extra register since we want to give our comparison one chance to do a check
  //before we decide what to do. Comparison starts with edge_adv_cal_start_r
  //while checking the result begins a cycle later
  always @(posedge clk) begin
    if (rst_clk)
	  edge_adv_cal_start_r2 <= #TCQ 0;
	else
	  edge_adv_cal_start_r2 <= #TCQ edge_adv_cal_start_r;
  end
  
  //Create a counter so we don't start bitslipping the data too soon before
  //valid data is to be on the bus
  always @(posedge clk) begin
    if (rst_clk) begin
      start_cnt  <= #TCQ 0;
    end else if (edge_adv_cal_start && start_cnt != START_WAIT_TIME) begin
	  start_cnt  <= #TCQ start_cnt + 1;
    end else
	  start_cnt  <= #TCQ start_cnt;
  end

  // Create rd_cmd for BL8, BL4 and BL2. BL8/BL4 only uses one bit for incoming
  // rd_cmd's. Since this stage of calibration can't start until stage 1 is
  // complete, mask off all incoming rd_cmd's until stage 2 begins. There can
  // be rd_cmd's from the stage 1 calibration just after stage 2 starts. These
  // will be masked off by looking for the rising edge of rd_cmd.
  
  assign bl8_rd_cmd_int = (BURST_LEN == 8) && (int_rd_cmd_n == RD_CMD_PATTERN);
  assign bl4_rd_cmd_int = (BURST_LEN == 4) && (int_rd_cmd_n == RD_CMD_PATTERN);
  assign bl2_rd_cmd_int = (BURST_LEN == 2) && (int_rd_cmd_n == RD_CMD_PATTERN);

  always @(posedge clk) begin
    if (rst_clk) begin
      bl8_rd_cmd_int_r  <= #TCQ 0;
      bl8_rd_cmd_int_r2 <= #TCQ 0;
    end else begin
      bl8_rd_cmd_int_r  <= #TCQ bl8_rd_cmd_int;
      bl8_rd_cmd_int_r2 <= #TCQ bl8_rd_cmd_int_r;
    end
  end

  always @(posedge clk) begin
    if (rst_clk)
      bl4_rd_cmd_int_r <= #TCQ 0;
    else
      bl4_rd_cmd_int_r <= #TCQ bl4_rd_cmd_int;
  end

  always @(posedge clk) begin
      if (rst_clk)
        bl2_rd_cmd_int_r <= #TCQ 0;
      else
        bl2_rd_cmd_int_r <= #TCQ bl2_rd_cmd_int;
  end
  
  //generate the rd_cmd flag
  generate
    if (BURST_LEN == 8) begin: BL8_RD_CMD
      assign rd_cmd = bl8_rd_cmd_int && !bl8_rd_cmd_int_r &&
                     !bl8_rd_cmd_int_r2 && cal_stage2_start && !cal_stage2_done;
    end else if (BURST_LEN == 4) begin : BL4_RD_CMD
      assign rd_cmd = bl4_rd_cmd_int && !bl4_rd_cmd_int_r && 
                      cal_stage2_start && !cal_stage2_done;
    end else if (BURST_LEN == 2) begin : BL2_RD_CMD
      assign rd_cmd = bl2_rd_cmd_int && !bl2_rd_cmd_int_r && 
                      cal_stage2_start && !cal_stage2_done;
    end
  endgenerate  
  
  always @ (posedge clk) begin
    if (rst_clk) begin
      cal_stage2_cnt <= 0;
    end else if (edge_adv_cal_done &&  (cal_stage2_cnt != 5'h1F) ) begin
      cal_stage2_cnt <= cal_stage2_cnt + 1;
    end 
  end
  
  // Create an enable for the latency counter. Enable it whenver the
  // appropriate rd_cmd is seen from the initialization logic in the write
  // interface. Since only one rd_cmd is issued during this phase, it can
  // remain enabled after asserted for the first time.
  always @(posedge clk) begin
    if (rst_clk)
      en_mem_latency <= #TCQ 0;
    else if (cal_stage2_done)    
      en_mem_latency <= #TCQ 0;
    else if (rd_cmd ) // rd_cmd is active only when cal_stage2_start has started..
      en_mem_latency <= #TCQ 1;
  end
  
  assign rd0 = iserdes_rd[DATA_WIDTH-1:0];
  assign fd0 = iserdes_fd[DATA_WIDTH-1:0];
  assign rd1 = iserdes_rd[2*DATA_WIDTH-1:DATA_WIDTH];
  assign fd1 = iserdes_fd[2*DATA_WIDTH-1:DATA_WIDTH];
  
  generate
    if (nCK_PER_CLK == 4) begin : gen_rd_div4
	  assign rd2 = iserdes_rd[3*DATA_WIDTH-1:2*DATA_WIDTH];
      assign fd2 = iserdes_fd[3*DATA_WIDTH-1:2*DATA_WIDTH];
      assign rd3 = iserdes_rd[4*DATA_WIDTH-1:3*DATA_WIDTH];
      assign fd3 = iserdes_fd[4*DATA_WIDTH-1:3*DATA_WIDTH];
	end
  endgenerate

  // For each memory in the interface, determine the latency from the time the
  // rd_cmd is issued until the expected read back data is received. This
  // determines the latency of the system.
  genvar nd_i;
  generate
    // check for each byte lane 
    for (nd_i=0; nd_i < DATA_WIDTH/9; nd_i=nd_i+1) begin : mem_lat_inst

      // Count the number of cycles from the time that the rd_cmd is seen. This
      // will be used to determine how long for the read data to be returned and
      // hence the read latency. If latency_cntr counter maxes out, issue an 
      // error. This is either because the latency of the read is higher than 
      // the design can handle or because the latency calibration readback data 
      // of AA's was never correctly received. The latency counter begins 
      // counting from 1 since there is an additional cycle of latency in the 
      // read path not accounted for by this read command from the 
      // initialization logic.
      always @(posedge clk) begin
        if (rst_clk) begin
          latency_cntr[nd_i]      <= #TCQ 1;
          error_max_latency[nd_i] <= #TCQ 0;
        end else if (latency_cntr[nd_i] == 5'h1F) begin
          latency_cntr[nd_i]      <= #TCQ 5'h1F;
          if (!latency_measured[nd_i])
            error_max_latency[nd_i] <= #TCQ 1;
          else
            error_max_latency[nd_i] <= #TCQ 0;
        end else if (en_mem_latency || rd_cmd) begin
          latency_cntr[nd_i]      <= #TCQ latency_cntr[nd_i] + 1'b1;  
          error_max_latency[nd_i] <= #TCQ 0;
        end
      end

      // Break apart the read_data bus into the various rising and falling data
      // groups for each memory. The read_data bus is constructed as follows:
      // read_data = {rd0, fd0, rd1, fd1}
      // rd0 = {rd0[n], ..., rd0[1], rd0[0]}
      // fd0 = {fd0[n], ..., fd0[1], fd0[0]}
      // rd1 = {rd1[n], ..., rd1[1], rd1[0]}
      // fd1 = {fd1[n], ..., fd1[1], fd1[0]}
//      assign rd0[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] =
//             read_data[(nd_i*BYTE_LANE_WIDTH+BYTE_LANE_WIDTH*N_DATA_LANES*0)+:BYTE_LANE_WIDTH];
//      assign fd0[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] =
//             read_data[(nd_i*BYTE_LANE_WIDTH+BYTE_LANE_WIDTH*N_DATA_LANES*1)+:BYTE_LANE_WIDTH];
//      assign rd1[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] =
//             read_data[(nd_i*BYTE_LANE_WIDTH+BYTE_LANE_WIDTH*N_DATA_LANES*2)+:BYTE_LANE_WIDTH];
//      assign fd1[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] =
//             read_data[(nd_i*BYTE_LANE_WIDTH+BYTE_LANE_WIDTH*N_DATA_LANES*3)+:BYTE_LANE_WIDTH];

      // Pull off the respective LAT_CAL_DATA for each group of data.
      assign rd0_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] = 
             LAT_CAL_DATA[(nd_i*BYTE_LANE_WIDTH+BYTE_LANE_WIDTH*N_DATA_LANES*3)+:BYTE_LANE_WIDTH];
      assign fd0_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] = 
             LAT_CAL_DATA[(nd_i*BYTE_LANE_WIDTH+BYTE_LANE_WIDTH*N_DATA_LANES*2)+:BYTE_LANE_WIDTH];
      assign rd1_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] =
             LAT_CAL_DATA[(nd_i*BYTE_LANE_WIDTH+BYTE_LANE_WIDTH*N_DATA_LANES*1)+:BYTE_LANE_WIDTH];
      assign fd1_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] =
             LAT_CAL_DATA[(nd_i*BYTE_LANE_WIDTH+BYTE_LANE_WIDTH*N_DATA_LANES*0)+:BYTE_LANE_WIDTH];
	  
	  //Seperate data pattern used for DIV4 mode
	  assign rd2_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] = 
             LAT_CAL_DATA2[(nd_i*BYTE_LANE_WIDTH+BYTE_LANE_WIDTH*N_DATA_LANES*3)+:BYTE_LANE_WIDTH];
      assign fd2_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] = 
             LAT_CAL_DATA2[(nd_i*BYTE_LANE_WIDTH+BYTE_LANE_WIDTH*N_DATA_LANES*2)+:BYTE_LANE_WIDTH];
      assign rd3_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] =
             LAT_CAL_DATA2[(nd_i*BYTE_LANE_WIDTH+BYTE_LANE_WIDTH*N_DATA_LANES*1)+:BYTE_LANE_WIDTH];
      assign fd3_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] =
             LAT_CAL_DATA2[(nd_i*BYTE_LANE_WIDTH+BYTE_LANE_WIDTH*N_DATA_LANES*0)+:BYTE_LANE_WIDTH];
      
      //**************************************************************************************************
      
      //added for v7 - to check for bitslip valid?       
      always @ (posedge clk) begin
             rd1_r[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] <= rd1[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] ;
             fd1_r[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] <= fd1[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] ;
        end        
      //*********************************************************************************************************************************8

      // Indicate if the data for each memory matches the respective LAT_CAL_DATA.
      // check for R0-F0-R1-F1 alignment in the same clkdiv cycle
      always @(posedge clk)
      begin
        if (rst_clk)
        begin
          rd0_vld[nd_i] <= #TCQ 'b0;
          fd0_vld[nd_i] <= #TCQ 'b0;
          rd1_vld[nd_i] <= #TCQ 'b0;
          fd1_vld[nd_i] <= #TCQ 'b0;
          rd2_vld[nd_i] <= #TCQ 'b0;
          fd2_vld[nd_i] <= #TCQ 'b0;
          rd3_vld[nd_i] <= #TCQ 'b0;
          fd3_vld[nd_i] <= #TCQ 'b0;
        end else
        begin
          rd0_vld[nd_i] <= #TCQ (rd0[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] ==
                                 rd0_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH]);
          fd0_vld[nd_i] <= #TCQ (fd0[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] ==
                                 fd0_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH]);
          rd1_vld[nd_i] <= #TCQ (rd1[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] ==
                                 rd1_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH]);
          fd1_vld[nd_i] <= #TCQ (fd1[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] ==
                                 fd1_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH]);
          rd2_vld[nd_i] <= #TCQ (rd2[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] ==
                                 rd2_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH]);
          fd2_vld[nd_i] <= #TCQ (fd2[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] ==
                                 fd2_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH]);
          rd3_vld[nd_i] <= #TCQ (rd3[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] ==
                                 rd3_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH]);
          fd3_vld[nd_i] <= #TCQ (fd3[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] ==
                                 fd3_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH]);
        end
      end
                              
      //assign data_vld[nd_i] = edge_adv_cal_start_r && rd0_vld[nd_i] && fd0_vld[nd_i] && rd1_vld[nd_i] && fd1_vld[nd_i];       
      assign phase_vld[nd_i] = (nCK_PER_CLK == 2) ? (edge_adv_cal_start_r && rd0_vld[nd_i] && fd0_vld[nd_i] && rd1_vld[nd_i] && fd1_vld[nd_i]) :
                                                     (edge_adv_cal_start_r && rd0_vld[nd_i] && fd0_vld[nd_i] && rd1_vld[nd_i] && fd1_vld[nd_i]
                                                                           && rd2_vld[nd_i] && fd2_vld[nd_i] && rd3_vld[nd_i] && fd3_vld[nd_i]);
                              
      ////////////////////////////////////////////////////////////////////////////////
      // added for v7 - to check for phase alignment to clkdiv edge.
      ////////////////////////////////////////////////////////////////////////////////   
      // Indicate if the data for each memory matches the respective LAT_CAL_DATA.
      // check for x-x-R0-F0/R1-F1-x-x alignment across two clkdiv cycles                   
      
      always @(posedge clk)
      begin
        if (rst_clk)
        begin
          rd0_bslip_vld[nd_i] <= #TCQ 'b0; 
          fd0_bslip_vld[nd_i] <= #TCQ 'b0; 
          rd1_bslip_vld[nd_i] <= #TCQ 'b0; 
          fd1_bslip_vld[nd_i] <= #TCQ 'b0; 
        end else begin
          rd0_bslip_vld[nd_i] <= #TCQ (rd1_r[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] ==
                                       rd0_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH]);
          fd0_bslip_vld[nd_i] <= #TCQ (fd1_r[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] ==
                                       fd0_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH]);
          rd1_bslip_vld[nd_i] <= #TCQ (rd0[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] ==
                                       rd1_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH]);
          fd1_bslip_vld[nd_i] <= #TCQ (fd0[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH] ==
                                       fd1_lat[nd_i*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH]); 
        end
      end
      
      assign phase_bslip_vld[nd_i] = (edge_adv_cal_start_r && rd0_bslip_vld[nd_i] && fd0_bslip_vld[nd_i] && rd1_bslip_vld[nd_i] && fd1_bslip_vld[nd_i]);
      
      // check if either condition is true for nCK_PER_CLK == 2, for others
      // rather than check them all we bitslip then check after
      assign phase_vld_check[nd_i] = (nCK_PER_CLK == 2) ? 
	                                  phase_vld[nd_i] || phase_bslip_vld[nd_i] :
									  phase_vld[nd_i];
      
      // check to make sure all data lanes phases have been checked. Then phase_bslip_vld_chk for corresponding data lanes are updated if pi_edge_adv needs
      // to be asserted for that particular byte lane.                    
      always @ (posedge clk) begin
        if (rst_clk) begin
           phase_bslip_vld_chk[nd_i] <= #TCQ 0;
        //when all data byte lanes have their phases checked - clkdiv_phase_cal_done_r is high.
        end else if (clkdiv_phase_cal_done_r) begin 
           phase_bslip_vld_chk[nd_i]  <= #TCQ phase_bslip_vld[nd_i];
        end
      end
     
 
      /////////////////////////////////////////////////////////////////////////////////////////

      // Capture the current latency count when the received data
      // (LAT_CAL_DATA) is seen. Also indicate that the latency has been
      // measured for this memory.
      always @(posedge clk) begin
        if (rst_clk) begin
          mem_latency[nd_i]       <= #TCQ 0;
          latency_measured[nd_i]  <= #TCQ 0;
        end else if (en_mem_latency && rd0_vld[nd_i] && fd0_vld[nd_i] &&
                     rd1_vld[nd_i] && fd1_vld[nd_i]) begin
		  if (nCK_PER_CLK == 2 || 
		     (nCK_PER_CLK == 4 && 
			  rd2_vld[nd_i] && fd2_vld[nd_i] && 
			  rd3_vld[nd_i] && fd3_vld[nd_i])) begin
           mem_latency[nd_i]       <= #TCQ latency_cntr_r[nd_i] ; 
           latency_measured[nd_i]  <= #TCQ 1;
		  end
        end
      end

      always @(posedge clk) begin
        if (rst_clk)
          latency_cntr_r[nd_i]  <= #TCQ 0;
        else
          latency_cntr_r[nd_i]  <= #TCQ latency_cntr[nd_i];
      end

    end //end mem_lat_inst
  endgenerate
  
  
  // read data alignment to the posedge of iclkdiv is done when all the read data (R0,F0,R1,F1) pattern are as expected.
  
  always @ (posedge clk) begin     
    if (rst_clk) begin
      clkdiv_phase_cal_done  <= #TCQ 0;
      clkdiv_phase_cal_done_r <= #TCQ 0;
      clkdiv_phase_cal_done_2r <= #TCQ 0;
      clkdiv_phase_cal_done_3r <= #TCQ 0;
      clkdiv_phase_cal_done_4r <= #TCQ 0;
      clkdiv_phase_cal_done_5r <= #TCQ 0;
    end else begin
      clkdiv_phase_cal_done <= #TCQ &phase_vld_check;
      clkdiv_phase_cal_done_r <= #TCQ clkdiv_phase_cal_done;
      clkdiv_phase_cal_done_2r <= #TCQ clkdiv_phase_cal_done_r;
      clkdiv_phase_cal_done_3r <= #TCQ clkdiv_phase_cal_done_2r;
      clkdiv_phase_cal_done_4r <= #TCQ clkdiv_phase_cal_done_3r;
      clkdiv_phase_cal_done_5r <= #TCQ clkdiv_phase_cal_done_4r;
    end
  end
  
  // counter to check for phase alignment per byte group
  
  always @ (posedge clk) begin
     if (rst_clk) begin
        byte_cnt <= #TCQ 0;
     end else if (inc_byte_cnt) begin
        byte_cnt <= byte_cnt +1;
     end
   end  
   
  // need to assert edge_adv for corresponding phaser_ins where the first rise data aligns to the negedge of clkdiv.
  // phase_vld refers to the case where edge_adv does not need to be asserted, phase_bslip_vld refers
  // to the condition where edge_adv needs to be asserted for that byte group. 
  
  always @ (posedge clk) begin
         if (rst_clk) begin
             pi_edge_adv  <= #TCQ 0;
			 bitslip      <= #TCQ 0;
             phase_error  <= #TCQ 0;
             pi_edge_adv_wait_cnt <= #TCQ 0;
             inc_byte_cnt <= #TCQ 0;
         end else begin
		     if (nCK_PER_CLK == 2) begin
               if ((clkdiv_phase_cal_done_5r) && (!edge_adv_cal_done)) begin
                 if (phase_bslip_vld_chk[byte_cnt] == 1'b1 &&
			         pi_edge_adv_wait_cnt == 4'b0000) begin
                    pi_edge_adv  <= #TCQ 1;
                    phase_error  <= #TCQ 0;
                    pi_edge_adv_wait_cnt <= #TCQ 4'b1111;
                    inc_byte_cnt <= #TCQ 0;
                 end else if (phase_bslip_vld_chk[byte_cnt] == 1'b0 &&
			                  pi_edge_adv_wait_cnt == 4'b0000) begin
                    pi_edge_adv  <= #TCQ 0;
                    phase_error  <= #TCQ 0;
                    pi_edge_adv_wait_cnt <= #TCQ 4'b1111; 
                    inc_byte_cnt <= #TCQ 0;
                 end else if (pi_edge_adv_wait_cnt == 4'b0010) begin
                    pi_edge_adv  <= #TCQ 0;
                    phase_error  <= #TCQ 0;
                    pi_edge_adv_wait_cnt <= #TCQ pi_edge_adv_wait_cnt -1 ;
                    inc_byte_cnt <= #TCQ 1;
                 end else begin
                    pi_edge_adv  <= #TCQ 0;
                    phase_error  <= #TCQ 0;
                    pi_edge_adv_wait_cnt <= #TCQ pi_edge_adv_wait_cnt -1 ;
                    inc_byte_cnt <= #TCQ 0;
                 end
			   end //end of (clkdiv_phase_cal_done_5r) && (!edge_adv_cal_done)
			 end else begin //nCK_PER_CLK == 4
			   //Even though we don't use the edge_adv signal we use the same
			   //counter
			   if (edge_adv_cal_start_r2 && (!edge_adv_cal_done)) begin
			     if (phase_vld_check[byte_cnt] == 1'b1 &&
			         pi_edge_adv_wait_cnt == 4'b0000) begin
                   bitslip      <= #TCQ 0;
                   phase_error  <= #TCQ 0;
                   pi_edge_adv_wait_cnt <= #TCQ 4'b1111;
                   inc_byte_cnt <= #TCQ 1;
			     end else if (phase_vld_check[byte_cnt] == 1'b0 &&
			                  pi_edge_adv_wait_cnt == 4'b0000) begin
                   bitslip      <= #TCQ 1;
                   phase_error  <= #TCQ 0;
                   pi_edge_adv_wait_cnt <= #TCQ 4'b1111;
                   inc_byte_cnt <= #TCQ 0;
			     end else if (pi_edge_adv_wait_cnt == 4'b0010) begin
                   bitslip      <= #TCQ 0;
                   phase_error  <= #TCQ 0;
                   pi_edge_adv_wait_cnt <= #TCQ pi_edge_adv_wait_cnt -1 ;
                   inc_byte_cnt <= #TCQ 0;
                 end else begin
                   bitslip      <= #TCQ 0;
                   phase_error  <= #TCQ 0;
                   pi_edge_adv_wait_cnt <= #TCQ pi_edge_adv_wait_cnt -1 ;
                   inc_byte_cnt <= #TCQ 0;
                 end
			   end
			 end //end of //nCK_PER_CLK == 4
         end //end of else
      end //end of always
      
 always @ (posedge clk) begin
     if (rst_clk) 
         edge_adv_cal_done <= #TCQ 0;
     else if (&(phase_vld))
         edge_adv_cal_done <= #TCQ 1;
     
 end  
     
//****************************************************************************************************
// second half of the stage2 calibration : determining max latency of the system 
//****************************************************************************************************

  // Determine the maximum latency
  generate
    if (N_DATA_LANES == 1) begin : max_lat_inst_dev1

      // With only one device, the maximum latency of the system is simply the
      // the latency determined previously.
      always @(posedge clk) begin
        if (rst_clk)
          max_latency <= #TCQ 0;
        else if (latency_measured[0])
          max_latency <= #TCQ mem_latency[0];
      end

      always @(posedge clk) begin
        if (rst_clk)
          max_lat_done <= #TCQ 0;
        else if (latency_measured[0])
          max_lat_done <= #TCQ 1;
      end
      
    end else begin : max_lat_inst

      assign lat_measure_done = &latency_measured;
      assign en_mem_cntr  = (lat_measure_done && !mem_cntr_done);

      // Counter that cycles through each memory which will be used to determine
      // the largest latency in the system. It only starts counting after the 
      // latency has been measured for each device. Also indicates when all
      // devices have been cycled through.
      always @(posedge clk) begin
        if (rst_clk) begin
          mem_cntr      <= #TCQ 0;
          mem_cntr_done <= #TCQ 0;
        end else if ((mem_cntr == (N_DATA_LANES - 1)) && lat_measure_done 
                      && !mem_cntr_done) begin
          mem_cntr      <= #TCQ mem_cntr;
          mem_cntr_done <= #TCQ 1;
        end else if (en_mem_cntr) begin
          mem_cntr      <= #TCQ mem_cntr + 1'b1;  
          mem_cntr_done <= #TCQ mem_cntr_done;
        end
      end

      // As the counter for each memory device increments, the latency of that
      // device is compared against the value in the max_latency register. If it
      // is larger than the stored value, it replaces the max_latency value.
      //  This repeats for each device until the maximum latency is found.
      always @(posedge clk) begin
        if (rst_clk) begin
          max_latency <= #TCQ 0;
        end else if ((mem_latency[mem_cntr] > max_latency) 
                      && !mem_cntr_done) begin
          max_latency <= #TCQ mem_latency[mem_cntr];
        end
      end

      // Indicate when maximum latency measurement is complete.
      always @(posedge clk) begin
        if (rst_clk)
          max_lat_done <= #TCQ 0;
        else
          max_lat_done <= #TCQ mem_cntr_done;
      end

    end
  endgenerate

  // Adjust the latency. For FIXED_LATENCY_MODE=1, the latency of each memory
  // must be increased to the target PHY_LATENCY value. For
  // FIXED_LATENCY_MODE=0, the latency of each memory is increased to the max
  // latency of any of the memories.
  genvar nd_j;
  generate
    if ((N_DATA_LANES > 1) || (FIXED_LATENCY_MODE == 1)) begin : adj_lat_inst

      // Determine when max_lat_done is first asserted. This will be used to
      // initiate the latency adjustment sequence.
      always @(posedge clk) begin
        if (rst_clk)
          max_lat_done_r <= #TCQ 0;
        else
          max_lat_done_r <= #TCQ max_lat_done;
      end

      assign start_lat_adj = max_lat_done && !max_lat_done_r;


      for (nd_j=0; nd_j < N_DATA_LANES; nd_j=nd_j+1) begin : inc_lat_inst

        // Adjust the latency as required for each memory. For
        // FIXED_LATENCY_MODE=0, the latency for each memory must be adjusted
        // to the maximum latency previously found within the system. For
        // FIXED_LATENCY_MODE=1, the latency for every memory will be adjusted
        // to the latency determined by the PHY_LATENCY parameter. Latency
        // adjustments are made by asserting the inc_latency signal
        // independently for each memory. For every cycle inc_latency is
        // asserted, the latency will be increased by one.
        always @(posedge clk) begin
          if (rst_clk) begin
            inc_latency[nd_j]   <= #TCQ 0;
            mem_lat_adj[nd_j]   <= #TCQ 0;
            lat_adj_done[nd_j]  <= #TCQ 0;
          end else if (start_lat_adj) begin
            if (FIXED_LATENCY_MODE == 0) begin
              inc_latency[nd_j]   <= #TCQ 0;
              mem_lat_adj[nd_j]   <= #TCQ max_latency - mem_latency[nd_j];
              lat_adj_done[nd_j]  <= #TCQ 0;
            end else begin
              inc_latency[nd_j]   <= #TCQ 0;
              mem_lat_adj[nd_j]   <= #TCQ PHY_LATENCY - mem_latency[nd_j];
              lat_adj_done[nd_j]  <= #TCQ 0;
            end
          end else if (max_lat_done_r) begin
            if (mem_lat_adj[nd_j] == 0) begin
              inc_latency[nd_j]   <= #TCQ 0;
              mem_lat_adj[nd_j]   <= #TCQ 0;
              lat_adj_done[nd_j]  <= #TCQ 1;
            end else begin
              inc_latency[nd_j]   <= #TCQ |mem_lat_adj[nd_j];
              mem_lat_adj[nd_j]   <= #TCQ mem_lat_adj[nd_j] - 1'b1;
              lat_adj_done[nd_j]  <= #TCQ 0;
            end
          end
        end

      end

      // Issue an error if in FIXED_LATENCY_MODE=1 and the target PHY_LATENCY
      // is less than what the system can safely provide.
      always @(posedge clk) begin
        if (rst_clk)
          error_adj_latency <= #TCQ 0;
        else if ((FIXED_LATENCY_MODE == 1) && start_lat_adj) begin
          if (PHY_LATENCY < max_latency)
            error_adj_latency <= #TCQ 1;
        end
      end

      // Signal that stage 2 calibration is complete once the latencies have
      // been adjusted.
      always @(posedge clk) begin
        if (rst_clk)
          cal_stage2_done <= #TCQ 0;
        else if (error_adj_latency)
          cal_stage2_done <= #TCQ 0;
        
        else
          cal_stage2_done <= #TCQ |lat_adj_done;
      end
      
    end else begin : adj_lat_inst_dev1

      // Since no latency adjustments are required for single memory interface
      // with FIXED_LATENCY_MODE=0, calibration can be signaled as soon as
      // max_lat_done is asserted
      always @(posedge clk) begin
        if (rst_clk)
          cal_stage2_done <= #TCQ 0;
        else
          cal_stage2_done <= #TCQ max_lat_done;
      end
    
      // Tie off error_adj_latency signal
      always @(posedge clk) begin
        error_adj_latency <= #TCQ 0;
      end
      
    end
  endgenerate

  // The final step is to indicate to the vld_gen logic how much to delay
  // incoming rd_cmd's by in order to align them with the read data. This
  // latency to the vld_gen logic is set to either the max_latency - 3
  // FIXED_LATENCY_MODE=0) or PHY_LATENCY - 3 (FIXED_LATENCY_MODE=1). The
  // minus 3 is to account for the extra cycles out of the vld_gen logic.
  always @(posedge clk) begin
    if (rst_clk)
      valid_latency <= #TCQ 0;
    else if (cal_stage2_done) 
      valid_latency <= #TCQ valid_latency;     
    else if (FIXED_LATENCY_MODE == 0)
      valid_latency <= #TCQ max_latency - 2'h3; 
    else
      valid_latency <= #TCQ PHY_LATENCY - 2'h3;    
  end
  
  //Register phase valid results and output for use by write calibration
  always @(posedge clk) begin
    if (rst_clk)
      phase_valid <= #TCQ 'b0;
	else
	  phase_valid <= #TCQ phase_vld_check;
  end
  

  // Indicate overall calibration is complete once stage 2 calibration is done
  // and each phase detector has completed calibration.
  always @(posedge clk) begin
    if (rst_clk)
      cal_done <= #TCQ 0;
    else
      cal_done <= #TCQ cal_stage2_done;
  end
			    
   // Assign debug signals
  assign dbg_stage2_cal[0]       = en_mem_latency;
  assign dbg_stage2_cal[5:1]     = mem_latency[dbg_byte_sel];   // latency value for each byte lane
  assign dbg_stage2_cal[6]       = rd_cmd;
  assign dbg_stage2_cal[7]       = latency_measured[0];
  assign dbg_stage2_cal[8]       = bl4_rd_cmd_int;
  assign dbg_stage2_cal[9]       = bl4_rd_cmd_int_r;
  assign dbg_stage2_cal[10]      = edge_adv_cal_start;
  assign dbg_stage2_cal[11]      = rd0_vld[dbg_byte_sel];
  assign dbg_stage2_cal[12]      = fd0_vld[dbg_byte_sel];
  assign dbg_stage2_cal[13]      = rd1_vld[dbg_byte_sel];
  assign dbg_stage2_cal[14]      = fd1_vld[dbg_byte_sel];
  assign dbg_stage2_cal[15]      = phase_vld[dbg_byte_sel];
  assign dbg_stage2_cal[16]      = rd0_bslip_vld[dbg_byte_sel];
  assign dbg_stage2_cal[17]      = fd0_bslip_vld[dbg_byte_sel];
  assign dbg_stage2_cal[18]      = rd1_bslip_vld[dbg_byte_sel];
  assign dbg_stage2_cal[19]      = fd1_bslip_vld[dbg_byte_sel];         
  assign dbg_stage2_cal[20]      = phase_bslip_vld[dbg_byte_sel];  
  assign dbg_stage2_cal[21]      = clkdiv_phase_cal_done_4r;
  assign dbg_stage2_cal[22]      = pi_edge_adv;
  assign dbg_stage2_cal[25:23]   = byte_cnt[2:0];	
  assign dbg_stage2_cal[26]      = inc_byte_cnt;  
  assign dbg_stage2_cal[30:27]   = pi_edge_adv_wait_cnt[3:0];
  assign dbg_stage2_cal[31]      = rd2_vld[dbg_byte_sel];
  assign dbg_stage2_cal[32]      = fd2_vld[dbg_byte_sel];
  assign dbg_stage2_cal[33]      = rd3_vld[dbg_byte_sel];
  assign dbg_stage2_cal[34]      = fd3_vld[dbg_byte_sel];

  assign dbg_stage2_cal[35]      = latency_measured[1];
  assign dbg_stage2_cal[36]      = (N_DATA_LANES > 2) ? latency_measured[2] : 1'b0;
  assign dbg_stage2_cal[37]      = (N_DATA_LANES > 2) ? latency_measured[3] : 1'b0;
  assign dbg_stage2_cal[38]      = error_adj_latency;
  assign dbg_stage2_cal[39]      = error_max_latency[dbg_byte_sel];
  assign dbg_stage2_cal[40]      = lat_adj_done[dbg_byte_sel];
  assign dbg_stage2_cal[76:41]   = {rd0[dbg_byte_sel*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH], rd1[dbg_byte_sel*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH], rd2[dbg_byte_sel*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH], rd3[dbg_byte_sel*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH]}; 
  assign dbg_stage2_cal[112:77]  = {fd0[dbg_byte_sel*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH], fd1[dbg_byte_sel*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH], fd2[dbg_byte_sel*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH], fd3[dbg_byte_sel*BYTE_LANE_WIDTH+:BYTE_LANE_WIDTH]}; 
  assign dbg_stage2_cal[116:113] = inc_latency[dbg_byte_sel];
  assign dbg_stage2_cal[127:117] = 'b0;

endmodule
