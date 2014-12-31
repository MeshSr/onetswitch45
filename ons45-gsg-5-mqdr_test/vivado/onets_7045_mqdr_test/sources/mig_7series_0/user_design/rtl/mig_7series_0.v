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
//  /   /         Filename           : mig_7series_0.v
// /___/   /\     Date Last Modified : $Date: 2011/06/02 08:36:27 $
// \   \  /  \    Date Created       : Fri Jan 14 2011
//  \___\/\___\
//
// Device           : 7 Series
// Design Name      : QDRII+ SDRAM
// Purpose          :
//   Wrapper module for the user design top level file. This module can be 
//   instantiated in the system and interconnect as shown in example design 
//   (example_top module).
// Reference        :
// Revision History :
//*****************************************************************************

`timescale 1ps/1ps

module mig_7series_0 (

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
  // User Interface signals of Channel-0
  input                             app_wr_cmd0,
  input  [18:0]           app_wr_addr0,
  input  [143:0] app_wr_data0,
  input  [15:0]   app_wr_bw_n0,
  input                             app_rd_cmd0,
  input  [18:0]           app_rd_addr0,
  output wire                       app_rd_valid0,
  output wire [143:0] app_rd_data0,
  // User Interface signals of Channel-1. It is useful only for BL2 designs.
  // All inputs of Channel-1 can be grounded for BL4 designs.
  input                             app_wr_cmd1,
  input  [18:0]           app_wr_addr1,
  input  [71:0]         app_wr_data1,
  input  [7:0]           app_wr_bw_n1,
  input                             app_rd_cmd1,
  input  [18:0]           app_rd_addr1,
  output wire                       app_rd_valid1,
  output wire [71:0]    app_rd_data1,
  output wire                       clk,
  output wire                       rst_clk,
  output                                       init_calib_complete,
  input			sys_rst
  );

// Start of IP top instance
  mig_7series_0_mig u_mig_7series_0_mig (
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
    .app_wr_cmd1                     (app_wr_cmd1),
    .app_wr_addr0                    (app_wr_addr0),
    .app_wr_addr1                    (app_wr_addr1),
    .app_rd_cmd0                     (app_rd_cmd0),
    .app_rd_cmd1                     (app_rd_cmd1),
    .app_rd_addr0                    (app_rd_addr0),
    .app_rd_addr1                    (app_rd_addr1),
    .app_wr_data0                    (app_wr_data0),
    .app_wr_data1                    (app_wr_data1),
    .app_wr_bw_n0                    (app_wr_bw_n0),
    .app_wr_bw_n1                    (app_wr_bw_n1),
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
// End of IP top instance

endmodule
