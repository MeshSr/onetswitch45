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
//  /   /         Filename           : qdr_phy_write_control_io.v
// /___/   /\     Date Last Modified : $Date: 2011/06/02 08:36:30 $ 
// \   \  /  \    Date Created       : Nov 11, 2008 
//  \___\/\___\
//
//Device: 7 Series
//Design: QDRII+ SRAM
//
//Purpose:
//    This module
//  1. Instantiates the I/O modules for generating the addresses and control
//     signals for memory
//
//Revision History:
//
////////////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps

module mig_7series_v2_0_qdr_phy_write_control_io #(
  parameter BURST_LEN   = 4,      //Burst Length
  parameter ADDR_WIDTH  = 19,     //Address Width
  parameter TCQ         = 100     //Register Delay
)
(
  input                           clk,              //main system half freq clk
  input                           rst_clk,       //main write path reset
  input                           wr_cmd0,          //wr command 0
  input                           wr_cmd1,          //wr command 1
  input       [ADDR_WIDTH-1:0]    wr_addr0,         //wr address 0
  input       [ADDR_WIDTH-1:0]    wr_addr1,         //wr address 1
  input                           rd_cmd0,          //rd command 0
  input                           rd_cmd1,          //rd command 1
  input       [ADDR_WIDTH-1:0]    rd_addr0,         //rd address 0
  input       [ADDR_WIDTH-1:0]    rd_addr1,         //rd address 1
  input       [1:0]               init_rd_cmd,      //init sm rd command
  input       [1:0]               init_wr_cmd,      //init sm wr command
  input       [ADDR_WIDTH-1:0]    init_wr_addr0,    //init sm wr address0
  input       [ADDR_WIDTH-1:0]    init_wr_addr1,    //init sm wr address1
  input       [ADDR_WIDTH-1:0]    init_rd_addr0,    //init sm rd address0
  input       [ADDR_WIDTH-1:0]    init_rd_addr1,    //init sm rd address1
  input                           cal_done,         //calibration done
  output reg  [1:0]               int_rd_cmd_n,     //internal rd cmd
  output reg  [1:0]               int_wr_cmd_n,     //internal rd cmd
  output reg  [ADDR_WIDTH-1:0]    iob_addr_rise0,   //OSERDES addr rise0
  output reg  [ADDR_WIDTH-1:0]    iob_addr_fall0,   //OSERDES addr fall0
  output reg  [ADDR_WIDTH-1:0]    iob_addr_rise1,   //OSERDES addr rise1
  output reg  [ADDR_WIDTH-1:0]    iob_addr_fall1,   //OSERDES addr fall1
  output wire [1:0]               dbg_phy_wr_cmd_n,//cs debug - wr command
  output wire [ADDR_WIDTH*4-1:0]  dbg_phy_addr,    //cs debug - address
  output wire [1:0]               dbg_phy_rd_cmd_n //cs debug - rd command
);

  //Wire Declarations
  wire                  mux_rd_cmd0;
  wire                  mux_rd_cmd1;
  wire                  mux_wr_cmd0;
  wire                  mux_wr_cmd1;
  wire [ADDR_WIDTH-1:0] rd_addr0_r;
  wire [ADDR_WIDTH-1:0] rd_addr1_r;
  wire [ADDR_WIDTH-1:0] wr_addr0_r;
  wire [ADDR_WIDTH-1:0] wr_addr1_r;
  reg [ADDR_WIDTH-1:0]  wr_addr1_2r;

  //Test Signals for Chipscope
  assign dbg_phy_wr_cmd_n = int_wr_cmd_n;
  assign dbg_phy_rd_cmd_n = int_rd_cmd_n;
  assign dbg_phy_addr     = {iob_addr_rise0, iob_addr_fall0, 
                             iob_addr_rise1, iob_addr_fall1};
  
  //In BL4 mode, writes should only be driven out on the falling edge, if we
  //have a command on port 0 (rising edge) move it to port 1 (falling edge)
  //Tie off the rising edge 
  wire [ADDR_WIDTH-1:0] mv_wr_addr0 = (BURST_LEN == 4) ? {ADDR_WIDTH{1'b0}} : wr_addr0;
  wire [ADDR_WIDTH-1:0] mv_wr_addr1 = (BURST_LEN == 4) ? wr_addr0 : wr_addr1;
  wire [ADDR_WIDTH-1:0] mv_rd_addr1 = (BURST_LEN == 4) ? {ADDR_WIDTH{1'b0}} : rd_addr1;


  //Select the correct address either from the user or from the init state
  //machine based on if calibration is complete
  assign rd_addr0_r  = (cal_done) ? rd_addr0 : init_rd_addr0;
  assign rd_addr1_r  = (cal_done) ? mv_rd_addr1 : init_rd_addr1;
  assign wr_addr0_r  = (cal_done) ? mv_wr_addr0 : init_wr_addr0;
  assign wr_addr1_r  = (cal_done) ? mv_wr_addr1 : init_wr_addr1;
 
  always @(posedge clk) 
    begin
      wr_addr1_2r <= #TCQ wr_addr1_r;
    end

  always @ (posedge clk)
    begin
      //Select the correct input to the oserdes based on the burst mode
      iob_addr_rise0 <=#TCQ (BURST_LEN == 4) ? rd_addr0_r : wr_addr1_2r;
      iob_addr_fall0 <=#TCQ (BURST_LEN == 4) ? rd_addr0_r : rd_addr0_r;
      iob_addr_rise1 <=#TCQ (BURST_LEN == 4) ? wr_addr1_r : wr_addr0_r;
      iob_addr_fall1 <=#TCQ (BURST_LEN == 4) ? wr_addr1_r : rd_addr1_r;
    end

  //In BL4 mode, writes should only be driven out on the falling edge, if we
  //have a command on port 0 (rising edge) move it to port 1 (falling edge)
  //Tie off the rising edge 
  wire mv_wr_cmd0 = (BURST_LEN == 4) ? 1'b0 : wr_cmd0;
  wire mv_wr_cmd1 = (BURST_LEN == 4) ? wr_cmd0 : wr_cmd1;
  wire mv_rd_cmd1 = (BURST_LEN == 4) ? 1'b0 : rd_cmd1;
  

  //Select the command from the user or from the init state machine based 
  //on if calibration is complete.
  //from the init state machine the high bit 1, corresponds to a write on the
  //rising edge of the clock as is "_cmd0"
  assign mux_rd_cmd0 = (cal_done) ? rd_cmd0 : init_rd_cmd[0];
  assign mux_rd_cmd1 = (cal_done) ? mv_rd_cmd1 : init_rd_cmd[1];
  assign mux_wr_cmd0 = (cal_done) ? mv_wr_cmd0 : init_wr_cmd[0];
  assign mux_wr_cmd1 = (cal_done) ? mv_wr_cmd1 : init_wr_cmd[1];

  //Invert the commands to be used on the memory interface as active low.. NOP issued until clocks are stable
  always @ (posedge clk)
    begin
      if (rst_clk) begin
        int_rd_cmd_n <=#TCQ 2'b11;
        int_wr_cmd_n <=#TCQ 2'b11;
      end else begin
        int_rd_cmd_n <=#TCQ {~mux_rd_cmd1, ~mux_rd_cmd0};
        int_wr_cmd_n <=#TCQ {~mux_wr_cmd1, ~mux_wr_cmd0};
      end
    end
    
endmodule
