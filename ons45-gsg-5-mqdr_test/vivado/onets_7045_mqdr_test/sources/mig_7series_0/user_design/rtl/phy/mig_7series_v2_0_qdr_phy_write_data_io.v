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
//  /   /         Filename           : qdr_phy_write_data_io.v
// /___/   /\     Date Last Modified : $date$
// \   \  /  \    Date Created       : Nov 12, 2008
//  \___\/\___\
//
//Device: 7 Series
//Design: QDRII+ SRAM
//
//Purpose:
//    This module
//  1. Is the top level module for write data
//  2. Instantiates the I/O modules for the memory write data
//
//Revision History:
//
////////////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps

module mig_7series_v2_0_qdr_phy_write_data_io #
(
  parameter BURST_LEN   = 4,            //Burst Length
  parameter DATA_WIDTH  = 72,           //Data Width
  parameter BW_WIDTH    = 8,            //Byte Write Width
  parameter TCQ         = 100           //Register Delay
)
(
  input                           clk,             //main system half freq clk
  input                           rst_clk,      //main write path reset 
  input                           cal_done,        //calibration done
  input                           wr_cmd0,
  input                           wr_cmd1,
  input       [1:0]               init_wr_cmd, 
  input       [DATA_WIDTH*2-1:0]  init_wr_data0,   //init state machine data 0
  input       [DATA_WIDTH*2-1:0]  init_wr_data1,   //init state machine data 1
  input       [DATA_WIDTH*2-1:0]  wr_data0,        //user write data 0
  input       [DATA_WIDTH*2-1:0]  wr_data1,        //user write data 1
  input       [BW_WIDTH*2-1:0]    wr_bw_n0,        //user byte writes 0
  input       [BW_WIDTH*2-1:0]    wr_bw_n1,        //user byte writes 1
  output reg  [DATA_WIDTH-1:0]    iob_data_rise0,  //OSERDES d rise0
  output reg  [DATA_WIDTH-1:0]    iob_data_fall0,  //OSERDES d fall0
  output reg  [DATA_WIDTH-1:0]    iob_data_rise1,  //OSERDES d rise1
  output reg  [DATA_WIDTH-1:0]    iob_data_fall1,  //OSERDES d fall1
  output reg  [BW_WIDTH-1:0]      iob_bw_rise0,    //OSERDES bw rise0
  output reg  [BW_WIDTH-1:0]      iob_bw_fall0,    //OSERDES bw fall0
  output reg  [BW_WIDTH-1:0]      iob_bw_rise1,    //OSERDES bw rise1
  output reg  [BW_WIDTH-1:0]      iob_bw_fall1,    //OSERDES bw fall1
  output wire [DATA_WIDTH*4-1:0]  dbg_phy_wr_data //cs debug - wr data
);   

  //Wire Declarations
  wire  [DATA_WIDTH-1:0] mux_data_rise0;
  wire  [DATA_WIDTH-1:0] mux_data_fall0;
  wire  [DATA_WIDTH-1:0] mux_data_rise1;
  wire  [DATA_WIDTH-1:0] mux_data_fall1;
  reg   [DATA_WIDTH-1:0] mux_data_rise0_r;
  reg   [DATA_WIDTH-1:0] mux_data_fall0_r;
  reg   [DATA_WIDTH-1:0] mux_data_rise1_r;
  reg   [DATA_WIDTH-1:0] mux_data_fall1_r;
  reg   [DATA_WIDTH-1:0] mux_data_fall1_2r;

  wire  [BW_WIDTH-1:0]   mux_bw_rise0;
  wire  [BW_WIDTH-1:0]   mux_bw_fall0;
  wire  [BW_WIDTH-1:0]   mux_bw_rise1;
  wire  [BW_WIDTH-1:0]   mux_bw_fall1;
  reg   [BW_WIDTH-1:0]   mux_bw_rise0_r;
  reg   [BW_WIDTH-1:0]   mux_bw_fall0_r;
  reg   [BW_WIDTH-1:0]   mux_bw_rise1_r;
  reg   [BW_WIDTH-1:0]   mux_bw_fall1_r;
  reg   [BW_WIDTH-1:0]   mux_bw_fall1_2r;


  //Debug ChipScope Signals
  assign dbg_phy_wr_data = {mux_data_rise0, mux_data_fall0,
                             mux_data_rise1, mux_data_fall1};
    
  //Select the data/bw from either the user or the init state machine based on
  //if calibration is done.
                         
  assign mux_data_rise0 = (cal_done && (wr_cmd0 || wr_cmd1)  ) ? 
                          wr_data0[DATA_WIDTH*2-1 : DATA_WIDTH] : (~ cal_done && |init_wr_cmd)?
                          init_wr_data0[DATA_WIDTH*2-1 : DATA_WIDTH] : 'b0;
  assign mux_data_fall0 = (cal_done && (wr_cmd0 || wr_cmd1) ) ?  
                          wr_data0[DATA_WIDTH-1 : 0] : (~ cal_done && |init_wr_cmd)?                  
                          init_wr_data0[DATA_WIDTH-1 : 0]: 'b0; 
  assign mux_data_rise1 = (cal_done && (wr_cmd0 || wr_cmd1) ) ? 
                          wr_data1[DATA_WIDTH*2-1 : DATA_WIDTH] : (~ cal_done && |init_wr_cmd)?                
                          init_wr_data1[DATA_WIDTH*2-1 : DATA_WIDTH]: 'b0; 
  assign mux_data_fall1 = (cal_done && (wr_cmd0 || wr_cmd1) ) ? 
                          wr_data1[DATA_WIDTH-1 : 0] : (~ cal_done && |init_wr_cmd)?                 
                          init_wr_data1[DATA_WIDTH-1 : 0]: 'b0; 


  assign mux_bw_rise0 = (cal_done && (wr_cmd0 || wr_cmd1)  ) ? wr_bw_n0[BW_WIDTH*2-1 : BW_WIDTH] :
                                     {BW_WIDTH{1'b0}};
  assign mux_bw_fall0 = (cal_done && (wr_cmd0 || wr_cmd1)  ) ? wr_bw_n0[BW_WIDTH-1 : 0] : 
                                     {BW_WIDTH{1'b0}};
  assign mux_bw_rise1 = (cal_done && (wr_cmd0 || wr_cmd1)  ) ? wr_bw_n1[BW_WIDTH*2-1 : BW_WIDTH] : 
                                     {BW_WIDTH{1'b0}};
  assign mux_bw_fall1 = (cal_done && (wr_cmd0 || wr_cmd1)  ) ? wr_bw_n1[BW_WIDTH-1 : 0] : 
                                     {BW_WIDTH{1'b0}};

  //When in BL4 mode, use the double registered version of the data/bw so they
  //appear on the edge after the write command was issued.  When in BL2
  //mode use the single registered data/bw so they appear on the same edge
  //as the write command.
  always @ (posedge clk)
    begin
      if (rst_clk) begin
        mux_data_rise0_r <=#TCQ 0;
        mux_data_fall0_r <=#TCQ 0;
        mux_data_rise1_r <=#TCQ 0;
        mux_data_fall1_r <=#TCQ 0;
        mux_data_fall1_2r <=#TCQ 0;

        //Initialize active low bw to 1 - to fill entire width use -1
        mux_bw_rise0_r  <=#TCQ -1;
        mux_bw_fall0_r  <=#TCQ -1;
        mux_bw_rise1_r  <=#TCQ -1;
        mux_bw_fall1_r  <=#TCQ -1;
        mux_bw_fall1_2r <=#TCQ -1;
      end else begin
        mux_data_rise0_r  <=#TCQ mux_data_rise0;
        mux_data_fall0_r  <=#TCQ mux_data_fall0;
        mux_data_rise1_r  <=#TCQ mux_data_rise1;
        mux_data_fall1_r  <=#TCQ mux_data_fall1;
        mux_data_fall1_2r <=#TCQ mux_data_fall1_r;

        mux_bw_rise0_r  <=#TCQ mux_bw_rise0;
        mux_bw_fall0_r  <=#TCQ mux_bw_fall0;
        mux_bw_rise1_r  <=#TCQ mux_bw_rise1;
        mux_bw_fall1_r  <=#TCQ mux_bw_fall1;
        mux_bw_fall1_2r <=#TCQ mux_bw_fall1_r;
      end
    end

  //select the registered data or not based on the burst length.  In BL4 the
  //data should come on the next rising edge after a wr_n command.  
  //Because the address/control are shifted by .25 of a clock cycle, the
  //data needs to be delayed in order to line up with on the cycle after the
  //write command is issued.  In order to reduce jitter on the data, we dont
  //want to delay this by using an IODELAY for that .25 of a cycle.  So for
  //this shift the D0, D1, D2, D3 ports to the oserdes need to be off by one.
  //D0 -> D3_r, D1 -> D0, D2 -> D1, D3 -> D2
  //In BL2 the data should arrive on the same cycle as the command. To keep
  //the data in line with the command, the same idea is used as that in BL4 
  //mode, by only delaying the data on D0.
  always @ (posedge clk) 
    begin
      iob_data_rise0 <=#TCQ (BURST_LEN == 4) ? mux_data_fall1_2r :
                                               mux_data_fall1_r;
      iob_data_fall0 <=#TCQ (BURST_LEN == 4) ? mux_data_rise0_r : 
                                               mux_data_rise0;
      iob_data_rise1 <=#TCQ (BURST_LEN == 4) ? mux_data_fall0_r : 
                                               mux_data_fall0;
      iob_data_fall1 <=#TCQ (BURST_LEN == 4) ? mux_data_rise1_r : 
                                               mux_data_rise1;
	  
      iob_bw_rise0 <=#TCQ (BURST_LEN == 4) ? mux_bw_fall1_2r : mux_bw_fall1_r;
      iob_bw_fall0 <=#TCQ (BURST_LEN == 4) ? mux_bw_rise0_r : mux_bw_rise0;
      iob_bw_rise1 <=#TCQ (BURST_LEN == 4) ? mux_bw_fall0_r : mux_bw_fall0;
      iob_bw_fall1 <=#TCQ (BURST_LEN == 4) ? mux_bw_rise1_r : mux_bw_rise1;
	  
    end

endmodule
