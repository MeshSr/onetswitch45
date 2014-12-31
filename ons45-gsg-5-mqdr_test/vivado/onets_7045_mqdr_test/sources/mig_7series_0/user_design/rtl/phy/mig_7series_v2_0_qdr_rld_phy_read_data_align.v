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
////////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : %version 
//  \   \         Application        : MIG
//  /   /         Filename           : qdr_rld_phy_read_data_align.v
// /___/   /\     Date Last Modified : $date$
// \   \  /  \    Date Created       : Nov 17, 2008
//  \___\/\___\
//
//Device: 7 Series
//Design: QDRII+ SRAM / RLDRAM II SDRAM
//
//Purpose:
//  This module adds latency to the byte lanes where read data comes in ahead
//  of the maximum latency or the fixed latency desired in the fixed latency mode
//    
//  
//
//Revision History:	12/12/2012  Improved rd_ptr	fanout to fix timing problems.
//
////////////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps

module mig_7series_v2_0_qdr_rld_phy_read_data_align #
(
  parameter BYTE_LANE_WIDTH  = 36, // Width of each memory
  parameter nCK_PER_CLK      = 2,
  parameter TCQ              = 100 // Register delay
)
(
  // System Signals
  input                           clk,       // half freq CQ clock
  input                           rst_clk,   // reset syncrhonized to clk

  // ISERDES Interface
  input       [nCK_PER_CLK*BYTE_LANE_WIDTH-1:0]  iserdes_rd,  // rising data from ISERDES
  input       [nCK_PER_CLK*BYTE_LANE_WIDTH-1:0]  iserdes_fd,  // falling data from ISERDES

  // DCB Interface
  output [nCK_PER_CLK*BYTE_LANE_WIDTH-1:0]  rise_data,   // rising data to DCB
  output [nCK_PER_CLK*BYTE_LANE_WIDTH-1:0]  fall_data,   // falling data to DCB

  // Delay/Alignment Calibration Interface
  input                           bitslip,
  input                           inc_latency,        // realigns when asserted
  input                           max_lat_done 
 
  // ChipScope Debug Signals
  //output                          dbg_phase     // phase indicator
);

wire [nCK_PER_CLK*BYTE_LANE_WIDTH-1:0]  rd;   // rising data before bitslip
wire [nCK_PER_CLK*BYTE_LANE_WIDTH-1:0]  fd;   // falling data before bitslip

// For higher divide by two lane width, one is added to 
// take care of odd widths such as 9
reg [BYTE_LANE_WIDTH/2-1:0]     memory_rd0_0 [15:0];
reg [(BYTE_LANE_WIDTH+1)/2-1:0] memory_rd0_1 [15:0]; 
reg [BYTE_LANE_WIDTH/2-1:0]     memory_fd0_0 [15:0];
reg [(BYTE_LANE_WIDTH+1)/2-1:0] memory_fd0_1 [15:0];
reg [BYTE_LANE_WIDTH/2-1:0]     memory_rd1_0 [15:0];
reg [(BYTE_LANE_WIDTH+1)/2-1:0] memory_rd1_1 [15:0];
reg [BYTE_LANE_WIDTH/2-1:0]     memory_fd1_0 [15:0];
reg [(BYTE_LANE_WIDTH+1)/2-1:0] memory_fd1_1 [15:0];
reg [BYTE_LANE_WIDTH/2-1:0]     memory_rd2_0 [15:0];
reg [(BYTE_LANE_WIDTH+1)/2-1:0] memory_rd2_1 [15:0]; 
reg [BYTE_LANE_WIDTH/2-1:0]     memory_fd2_0 [15:0];
reg [(BYTE_LANE_WIDTH+1)/2-1:0] memory_fd2_1 [15:0];
reg [BYTE_LANE_WIDTH/2-1:0]     memory_rd3_0 [15:0];
reg [(BYTE_LANE_WIDTH+1)/2-1:0] memory_rd3_1 [15:0];
reg [BYTE_LANE_WIDTH/2-1:0]     memory_fd3_0 [15:0];
reg [(BYTE_LANE_WIDTH+1)/2-1:0] memory_fd3_1 [15:0];
localparam integer byte_lane_fanout =  (BYTE_LANE_WIDTH+1)/4;
localparam integer wr_ptr_fanout =  (BYTE_LANE_WIDTH+1)/2;
reg [3:0] wr_ptr /* synthesis syn_maxfan = wr_ptr_fanout */;
reg [3:0] rd_r_ptr /* synthesis syn_maxfan = byte_lane_fanout */;
reg [3:0] rd_f_ptr /* synthesis syn_maxfan = byte_lane_fanout */;

reg max_lat_done_r;
reg [nCK_PER_CLK*BYTE_LANE_WIDTH-1:0]  rd_r;   // rising data before bitslip
reg [nCK_PER_CLK*BYTE_LANE_WIDTH-1:0]  fd_r;   // falling data before bitslip
reg [nCK_PER_CLK/2-1:0] bitslip_cnt;

// write pointer logic
always @(posedge clk) 
begin
   if (rst_clk)
      wr_ptr <= 4'b0;
   else if (max_lat_done)
      wr_ptr <= wr_ptr + 1;
end

// Latching max_lat_done
always @(posedge clk) 
begin
   if (rst_clk)
      max_lat_done_r <= 1'b0;
   else
      max_lat_done_r <= max_lat_done;
end

// read pointer logic
always @(posedge clk) 
begin
   if (rst_clk) begin
      rd_r_ptr <= 4'b0;
      rd_f_ptr <= 4'b0;
      
      end
   else if (max_lat_done_r && ~inc_latency)
      begin
      rd_r_ptr <= rd_r_ptr + 1;
      rd_f_ptr <= rd_f_ptr + 1;
      
      end
end

// Distributed RAM implementation with 16 words depth

always @(posedge clk)
  begin
     memory_rd0_0[wr_ptr] <= iserdes_rd[(0*BYTE_LANE_WIDTH)+BYTE_LANE_WIDTH/2-1:0*BYTE_LANE_WIDTH];
     memory_rd0_1[wr_ptr] <= iserdes_rd[(1*BYTE_LANE_WIDTH)-1:0*BYTE_LANE_WIDTH + BYTE_LANE_WIDTH/2];
     memory_fd0_0[wr_ptr] <= iserdes_fd[(0*BYTE_LANE_WIDTH)+BYTE_LANE_WIDTH/2-1:0*BYTE_LANE_WIDTH];
     memory_fd0_1[wr_ptr] <= iserdes_fd[(1*BYTE_LANE_WIDTH)-1:0*BYTE_LANE_WIDTH + BYTE_LANE_WIDTH/2];
	   
     memory_rd1_0[wr_ptr] <= iserdes_rd[(1*BYTE_LANE_WIDTH)+BYTE_LANE_WIDTH/2-1:1*BYTE_LANE_WIDTH];
     memory_rd1_1[wr_ptr] <= iserdes_rd[(2*BYTE_LANE_WIDTH)-1:1*BYTE_LANE_WIDTH + BYTE_LANE_WIDTH/2];
     memory_fd1_0[wr_ptr] <= iserdes_fd[(1*BYTE_LANE_WIDTH)+BYTE_LANE_WIDTH/2-1:1*BYTE_LANE_WIDTH];
     memory_fd1_1[wr_ptr] <= iserdes_fd[(2*BYTE_LANE_WIDTH)-1:1*BYTE_LANE_WIDTH + BYTE_LANE_WIDTH/2];
  end
  
generate
  if (nCK_PER_CLK == 2) begin : gen_ram_div2
  
    //Tie-off unused signals
    always @(posedge clk)
    begin
	   memory_rd2_0[wr_ptr] <= 'b0;
       memory_rd2_1[wr_ptr] <= 'b0;
       memory_fd2_0[wr_ptr] <= 'b0;
       memory_fd2_1[wr_ptr] <= 'b0;
	   
       memory_rd3_0[wr_ptr] <= 'b0;
       memory_rd3_1[wr_ptr] <= 'b0;
       memory_fd3_0[wr_ptr] <= 'b0;
       memory_fd3_1[wr_ptr] <= 'b0;
    end
    
	assign rd = {memory_rd1_1[rd_r_ptr],memory_rd1_0[rd_r_ptr],
	             memory_rd0_1[rd_r_ptr],memory_rd0_0[rd_r_ptr]};
	             
        assign fd = {memory_fd1_1[rd_f_ptr],memory_fd1_0[rd_f_ptr], 
	             memory_fd0_1[rd_f_ptr],memory_fd0_0[rd_f_ptr]};
				 
  end else begin : gen_ram_div4
    always @(posedge clk)
    begin
	   memory_rd2_0[wr_ptr] <= iserdes_rd[(2*BYTE_LANE_WIDTH)+BYTE_LANE_WIDTH/2-1:2*BYTE_LANE_WIDTH];
       memory_rd2_1[wr_ptr] <= iserdes_rd[(3*BYTE_LANE_WIDTH)-1:2*BYTE_LANE_WIDTH + BYTE_LANE_WIDTH/2];
       memory_fd2_0[wr_ptr] <= iserdes_fd[(2*BYTE_LANE_WIDTH)+BYTE_LANE_WIDTH/2-1:2*BYTE_LANE_WIDTH];
       memory_fd2_1[wr_ptr] <= iserdes_fd[(3*BYTE_LANE_WIDTH)-1:2*BYTE_LANE_WIDTH + BYTE_LANE_WIDTH/2];
	   
       memory_rd3_0[wr_ptr] <= iserdes_rd[(3*BYTE_LANE_WIDTH)+BYTE_LANE_WIDTH/2-1:3*BYTE_LANE_WIDTH];
       memory_rd3_1[wr_ptr] <= iserdes_rd[(4*BYTE_LANE_WIDTH)-1:3*BYTE_LANE_WIDTH + BYTE_LANE_WIDTH/2];
       memory_fd3_0[wr_ptr] <= iserdes_fd[(3*BYTE_LANE_WIDTH)+BYTE_LANE_WIDTH/2-1:3*BYTE_LANE_WIDTH];
       memory_fd3_1[wr_ptr] <= iserdes_fd[(4*BYTE_LANE_WIDTH)-1:3*BYTE_LANE_WIDTH + BYTE_LANE_WIDTH/2];
    end
	
	assign rd = {memory_rd3_1[rd_r_ptr],memory_rd3_0[rd_r_ptr],
	             memory_rd2_1[rd_r_ptr],memory_rd2_0[rd_r_ptr],
		     memory_rd1_1[rd_r_ptr],memory_rd1_0[rd_r_ptr],
	             memory_rd0_1[rd_r_ptr],memory_rd0_0[rd_r_ptr]};
	             
        assign fd = {memory_fd3_1[rd_f_ptr],memory_fd3_0[rd_f_ptr],
	             memory_fd2_1[rd_f_ptr],memory_fd2_0[rd_f_ptr],
	             memory_fd1_1[rd_f_ptr],memory_fd1_0[rd_f_ptr], 
	             memory_fd0_1[rd_f_ptr],memory_fd0_0[rd_f_ptr]};
  end
endgenerate

//Register data, which is needed for bitslip
//reset not needed
always @ (posedge clk)
begin
  rd_r <= #TCQ rd;
  fd_r <= #TCQ fd;
end

//Bitslip functionality basically used for nCK_PER_CLK == 4
always @ (posedge clk)
begin
  if (rst_clk)
    bitslip_cnt <= 'b0;
  //allow counter to wrap around if needed
  else if (bitslip)
    bitslip_cnt <= bitslip_cnt + 1;
  else
    bitslip_cnt <= bitslip_cnt;
end

//Bitslip select of the data pattern out
generate
  if (nCK_PER_CLK == 2) begin : gen_bitslip_div2
    assign rise_data = (bitslip_cnt == 0) ? rd : 
	                               {rd[(0*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH], 
					                rd_r[(1*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH]};
	assign fall_data = (bitslip_cnt == 0) ? fd : 
	                               {fd[(0*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH], 
					                fd_r[(1*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH]};
  end else if (nCK_PER_CLK == 4) begin : gen_bitslip_div4
    assign rise_data = (bitslip_cnt == 0) ? rd : 
	                   (bitslip_cnt == 1) ? 
					               {rd[(2*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH],
					                rd[(1*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH],
									rd[(0*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH],
									rd_r[(3*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH]} :
					   (bitslip_cnt == 2) ? 
                                   {rd[(1*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH],
					                rd[(0*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH],
									rd_r[(3*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH],
									rd_r[(2*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH]} :
								   {rd[(0*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH],
					                rd_r[(3*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH],
									rd_r[(2*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH],
									rd_r[(1*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH]};
								   
    assign fall_data = (bitslip_cnt == 0) ? fd : 
	                   (bitslip_cnt == 1) ? 
					               {fd[(2*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH],
					                fd[(1*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH],
									fd[(0*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH],
									fd_r[(3*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH]} :
					   (bitslip_cnt == 2) ? 
                                   {fd[(1*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH],
					                fd[(0*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH],
									fd_r[(3*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH],
									fd_r[(2*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH]} :
								   {fd[(0*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH],
					                fd_r[(3*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH],
									fd_r[(2*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH],
									fd_r[(1*BYTE_LANE_WIDTH)+:BYTE_LANE_WIDTH]};
  end
endgenerate

endmodule
