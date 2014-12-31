//*****************************************************************************
// (c) Copyright 2008-2013 Xilinx, Inc. All rights reserved.
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
// /___/  \  /    Vendor                : Xilinx
// \   \   \/     Version               : %version
//  \   \         Application           : MIG
//  /   /         Filename              : qdr_phy_byte_lane_map.v
// /___/   /\     Date Last Modified    : $date$
// \   \  /  \    Date Created          : Sept 09 2010
//  \___\/\___\
//
//Device            : 7 Series
//Design Name       : QDRII+ SRAM
//Purpose           : Top level memory interface block. Instantiates a clock 
//                    and reset generator, the memory controller, the phy and 
//                    the user interface blocks.
//Reference         :
//Revision History  :   12/12/2012 Change parameter MEMORYT_TYPE to
//                                 MEMORY_IO_DIR
//*****************************************************************************

`timescale 1 ps / 1 ps

module mig_7series_v2_0_qdr_phy_byte_lane_map #
  (
   parameter TCQ             = 100,
   parameter nCK_PER_CLK     = 2,         // qdr2+ used in the 2:1 mode
   parameter NUM_DEVICES     = 2,         //Memory Devices
   parameter ADDR_WIDTH      = 19,        //Adress Width
   parameter DATA_WIDTH      = 72,        //Data Width
   parameter BW_WIDTH        = 8,         //Byte Write Width
   parameter MEMORY_IO_DIR     = "UNIDIR",  // "UNIDIR" or "BIDIR"
   parameter MEM_RD_LATENCY  = 2.0,
   parameter Q_BITS          = 7,         //clog2(DATA_WIDTH - 1)
   //parameter N_LANES         = 4,
   //parameter N_CTL_LANES     = 2,
   // five fields, one per possible I/O bank, 4 bits in each field, 
   // 1 per lane data=1/ctl=0
   parameter DATA_CTL_B0     = 4'hc,
   parameter DATA_CTL_B1     = 4'hf,
   parameter DATA_CTL_B2     = 4'hf,
   parameter DATA_CTL_B3     = 4'hf,
   parameter DATA_CTL_B4     = 4'hf,
   // defines the byte lanes in I/O banks being used in the interface
   // 1- Used, 0- Unused
   parameter BYTE_LANES_B0   = 4'b1111,
   parameter BYTE_LANES_B1   = 4'b0000,
   parameter BYTE_LANES_B2   = 4'b0000,
   parameter BYTE_LANES_B3   = 4'b0000,
   parameter BYTE_LANES_B4   = 4'b0000,
   parameter HIGHEST_LANE    = 12,
   parameter HIGHEST_BANK    = 3,
   
   // [7:4] - bank no. ; [3:0] - byte lane no. 
   parameter K_MAP  = 48'h00_00_00_00_00_11,
   parameter CQ_MAP = 48'h00_00_00_00_00_01,
   
   // Mapping for address and control signals
   // The parameter contains the byte_lane and bit position information for 
   // a control signal. 
   // Each add/ctl bit will have 12 bits the assignments are
   // [3:0] - Bit position within a byte lane . 
   // [7:4] - Byte lane position within a bank. [5:4] have the byte lane position. 
    // [7:6] tied to 0 
   // [11:8] - Bank position. [10:8] have the bank position. [11] tied to zero 
   
   parameter RD_MAP = 12'h218,
   parameter WR_MAP = 12'h219,
  
   // supports 22 bits of address bits 
   
   parameter ADD_MAP = 264'h217_216_21B_21A_215_214_213_212_211_210_209_208_207_206_20B_20A_205_204_203_202_201_200,
   
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
   parameter Q7_MAP       = 108'h008_007_006_005_004_003_002_001_000//byte 7
   
   
   
  )
  (   
  input                                  clk,
  input                                  rst,
  input                                  phy_init_data_sel,
//  input                                  ck_addr_ctl_delay_done,
  input       [5:0]                      byte_sel_cnt,
  input       [HIGHEST_LANE*80-1:0]      phy_din,
  output wire [HIGHEST_LANE*80-1:0]      phy_dout,
  input       [HIGHEST_BANK*8-1:0]       ddr_clk,
  output wire [(HIGHEST_BANK*4)-1:0]     cq_clk,
  output wire [(HIGHEST_BANK*4)-1:0]     cqn_clk,
  
  input [nCK_PER_CLK*2*ADDR_WIDTH-1:0]   iob_addr, 
  input [nCK_PER_CLK*2-1:0]              iob_rd_n,
  input [nCK_PER_CLK*2-1:0]              iob_wr_n,
  input [nCK_PER_CLK*2*DATA_WIDTH-1:0]   iob_wdata,
  input [nCK_PER_CLK*2*BW_WIDTH-1:0]     iob_bw,
  input                                  iob_dll_off_n,
//  output reg [5:0]                       calib_sel,          // need clarifications//
//  output reg [HIGHEST_BANK-1:0]          calib_zero_inputs,  // need clarifications
  input  [5*DATA_WIDTH-1:0]              dlyval_dq,
  input  [HIGHEST_BANK*240-1:0]          idelay_cnt_out,
  input                                  dbg_inc_q_all,
  input                                  dbg_dec_q_all,
  input                                  dbg_inc_q,
  input                                  dbg_dec_q,
  input [Q_BITS-1:0]                     dbg_sel_q,   // selected Q bit
  output wire [5*DATA_WIDTH-1:0]         dbg_q_tapcnt,
  output wire [HIGHEST_BANK*240-1:0]     idelay_cnt_in,
  output wire [(HIGHEST_LANE*12)-1:0]    idelay_ce,
  output wire [(HIGHEST_LANE*12)-1:0]    idelay_inc,
  
  output [nCK_PER_CLK*2*DATA_WIDTH-1:0]  rd_data_map,
  output wire [NUM_DEVICES-1:0]          qdr_k_p,      //QDR clock K
  output wire [NUM_DEVICES-1:0]          qdr_k_n,      //QDR clock K#
  output wire [ADDR_WIDTH-1:0]           qdr_sa,       //QDR Memory Address       
  output wire                            qdr_w_n,      //QDR Write                
  output wire                            qdr_r_n,      //QDR Read                 
  output wire [BW_WIDTH-1:0]             qdr_bw_n,     //QDR Byte Writes to Mem   
  output wire [DATA_WIDTH-1:0]           qdr_d,        //QDR Data to Memory
  output wire                            qdr_dll_off_n,//QDR DLL OFF                
  input       [NUM_DEVICES-1:0]          qdr_cq_p,     //QDR clock CQ
  input       [NUM_DEVICES-1:0]          qdr_cq_n,     //QDR clock CQ#
  input   [DATA_WIDTH-1 :0]              qdr_q,

  input [(HIGHEST_LANE*12)-1:0]          O,   // input coming from mc_phy to drive out qdr output signals
  output [(HIGHEST_LANE*12)-1:0]         I    // read data coming from memory provided out to hard phy
  );

  wire [DATA_WIDTH-1:0]    in_dq;
  wire [DATA_WIDTH-1:0]    in_q;
  wire [ADDR_WIDTH-1:0]    out_sa;
  wire [BW_WIDTH-1:0]      out_bw_n;
  wire                     out_w_n;
  wire                     out_r_n;
  wire [DATA_WIDTH-1:0]    out_dq;
  wire [DATA_WIDTH-1:0]    out_d;
  wire [DATA_WIDTH-1:0]    ts_dq;
  
  //want this to be an inout port (add later)
  wire [DATA_WIDTH-1:0]    qdr_dq;
  
  reg  [DATA_WIDTH-1:0]    q_dly_inc;
  reg  [DATA_WIDTH-1:0]    q_dly_ce;
  
  //These are for dealing with 2:1 or 4:1 widths
  localparam MAP0 = 320;
  localparam MAP1 = 80;
  localparam MAP2 = 8;
  
  localparam DIN_MAP0 = MAP0;
  localparam DIN_MAP1 = MAP1;
  localparam DIN_MAP2 = MAP2;

  // ratio of DQS per DQ  // rd data7 assignment
  localparam BYTE_WIDTH = (DATA_WIDTH/BW_WIDTH); //=9 for QDR
  // Localparam to have the byte lane information for each byte 
  localparam CALIB_BYTE_LANE ={Q7_MAP[5:4],Q6_MAP[5:4],
			      Q5_MAP[5:4],Q4_MAP[5:4],Q3_MAP[5:4],
			      Q2_MAP[5:4],Q1_MAP[5:4],Q0_MAP[5:4]};
  // localparam to have the bank information for each byte 
  localparam CALIB_BANK = {Q7_MAP[10:8],Q6_MAP[10:8],
			  Q5_MAP[10:8],Q4_MAP[10:8],Q3_MAP[10:8],
			  Q2_MAP[10:8],Q1_MAP[10:8],Q0_MAP[10:8]};      
			  
   localparam READ_DATA_MAP = {Q7_MAP, Q6_MAP, Q5_MAP, Q4_MAP,
                                 Q3_MAP, Q2_MAP, Q1_MAP, Q0_MAP};
                                 
   // number of data phases per internal clock
  localparam PHASE_PER_CLK = 2*nCK_PER_CLK;
  
  localparam FULL_D_MAP = {D7_MAP[12*BYTE_WIDTH-1:0],  
                           D6_MAP[12*BYTE_WIDTH-1:0],
                           D5_MAP[12*BYTE_WIDTH-1:0],  
                           D4_MAP[12*BYTE_WIDTH-1:0],  
                           D3_MAP[12*BYTE_WIDTH-1:0],  
                           D2_MAP[12*BYTE_WIDTH-1:0],  
                           D1_MAP[12*BYTE_WIDTH-1:0],  
                           D0_MAP[12*BYTE_WIDTH-1:0]};
   
	                  
   // In the phy_dout bus, output signals that need to be driven out of the fpga are arranged as follows and provided to the
   //      mc_phy: {signals within bank4, bank3, bank2, bank1, bank0}
   // & within a bank the assignment is as follows: {bytelane3, bytelane2, bytelane1, bytelane0}
   // and for each byte lane, the assignment is {bit 11, bit 10, bit9,.......bit1, bit0} to accommodate the 12 bits
   //  As the QDRII+ interface is used in the 2:1 mode, 4 bit data is provided for each IO signal.
   // The higher order 2 bits inside the byte group are driven for only the Address/control byte group.
   // Write byte groups drive out only the lower 10 bits inside the byte group   

  generate
    genvar m, n;
  // System Clock
    for (m = 0; m < NUM_DEVICES; m = m + 1) begin: gen_k_out
      assign qdr_k_n[m] = ddr_clk [8*K_MAP[(8*m+4)+:3] + 
                                   2*K_MAP[(8*m)+:2] + 1];
      assign qdr_k_p[m] = ddr_clk [8*K_MAP[(8*m+4)+:3] + 
                                   2*K_MAP[(8*m)+:2]];
    end
    
  endgenerate
  
  // CQ Read Clock
  generate
    genvar cq_i;

    for (cq_i = 0; cq_i < NUM_DEVICES; cq_i = cq_i+1) begin: gen_cq_in
      // for 2 clk Read latency devices, CQ is used for rise 
      //                                 CQ# used for capturing fall data
      // for 2.5 clk Read latency devices, CQ# is used for rise and 
      //                                   CQ used for capturing fall data
      assign cqn_clk[4*CQ_MAP[(8*cq_i+4)+:3] + 
                     1*CQ_MAP[(8*cq_i)+:2]]
                    = (MEM_RD_LATENCY == 2.0) ? qdr_cq_n[cq_i] : qdr_cq_p[cq_i];
      assign cq_clk[4*CQ_MAP[(8*cq_i+4)+:3] + 
                    1*CQ_MAP[(8*cq_i)+:2]]
                    = (MEM_RD_LATENCY == 2.0) ? qdr_cq_p[cq_i] : qdr_cq_n[cq_i];
    end
   
  endgenerate
  


  // RD_N
  generate
	 for (n = 0; n < PHASE_PER_CLK; n = n + 1) begin: loop_rd_xpose
	  if (RD_MAP[3:0] < 4'hA) begin: gen_rd_lt10
        assign phy_dout[MAP0*RD_MAP[8+:3] + 
                        MAP1*RD_MAP[4+:2] + 
                        MAP2*RD_MAP[0+:4] + n]
                   = iob_rd_n[n];
      end else begin : gen_rd_ge10
	    // If signal is placed in bit lane [10] or [11], route to upper
        // nibble of phy_dout lane [5] or [6] respectively (in this case
        // phy_dout lane [5, 6] are multiplexed to take input for two
        // different SDR signals - this is how bits[10,11] need to be
        // provided to the OUT_FIFO
	    assign phy_dout[MAP0*RD_MAP[8+:3] + 
                        MAP1*RD_MAP[4+:2] + 
                        MAP2*(RD_MAP[0+:4]-5) + 4 + n]
                   = iob_rd_n[n];
	  end //end of if
	end 
	 
     assign out_r_n = O [(RD_MAP[10:8]*48) + (RD_MAP[5:4]*12) + (RD_MAP[3:0])];
       
  endgenerate
  
  // WR_N
  generate
	 for (n = 0; n < PHASE_PER_CLK; n = n + 1) begin: loop_wr_xpose
	  if (WR_MAP[3:0] < 4'hA) begin: gen_wr_lt10
        assign phy_dout[MAP0*WR_MAP[8+:3] + 
                        MAP1*WR_MAP[4+:2] + 
                        MAP2*WR_MAP[0+:4] + n]
                   = iob_wr_n[n];
      end else begin : gen_wr_ge10
	    // If signal is placed in bit lane [10] or [11], route to upper
        // nibble of phy_dout lane [5] or [6] respectively (in this case
        // phy_dout lane [5, 6] are multiplexed to take input for two
        // different SDR signals - this is how bits[10,11] need to be
        // provided to the OUT_FIFO
	    assign phy_dout[MAP0*WR_MAP[8+:3] + 
                        MAP1*WR_MAP[4+:2] + 
                        MAP2*(WR_MAP[0+:4]-5) + 4 + n]
                   = iob_wr_n[n];
	  end //end of if
	end 
	
     assign out_w_n = O [(WR_MAP[10:8]*48) + (WR_MAP[5:4]*12) + (WR_MAP[3:0])];
       
  endgenerate
  
  
  generate
  genvar add_i;
    for(add_i = 0; add_i < ADDR_WIDTH; add_i = add_i + 1) begin: gen_loop_ADD_out
	  for (n = 0; n < PHASE_PER_CLK; n = n + 1) begin: loop_xpose
	    if (ADD_MAP[12*add_i+:4] < 4'hA) begin: gen_addr_lt10
          assign phy_dout[MAP0*ADD_MAP[(12*add_i+8)+:3] + 
                          MAP1*ADD_MAP[(12*add_i+4)+:2] + 
                          MAP2*ADD_MAP[12*add_i+:4] + n]
                     = iob_addr[(add_i*PHASE_PER_CLK)+n];
        end else begin : gen_addr_ge10
	      // If signal is placed in bit lane [10] or [11], route to upper
          // nibble of phy_dout lane [5] or [6] respectively (in this case
          // phy_dout lane [5, 6] are multiplexed to take input for two
          // different SDR signals - this is how bits[10,11] need to be
          // provided to the OUT_FIFO
	      assign phy_dout[MAP0*ADD_MAP[(12*add_i+8)+:3] + 
                          MAP1*ADD_MAP[(12*add_i+4)+:2] + 
                          MAP2*(ADD_MAP[12*add_i+:4]-5) + 4 + n]
                     = iob_addr[(add_i*PHASE_PER_CLK)+n];
	    end //end of if           
      end //end of for
	end
  
    for(add_i = 0; add_i < ADDR_WIDTH*12; add_i = add_i + 12) begin: gen_loop_ADD
	     
       assign out_sa[add_i/12] = O [(ADD_MAP[add_i+10:add_i+8]*48) + 
	                                (ADD_MAP[add_i+5:add_i+4]*12)+ 
									(ADD_MAP[add_i+3:add_i+0])]; 
    
  end 
  endgenerate
  
  // Data 0 
  // each bit's information is stored in the format of "F1R1_F0R0"
 
   generate
   genvar dout_i;
     for(dout_i = 0; dout_i <DATA_WIDTH; dout_i = dout_i+1) begin: gen_loop_d0_out
       for (n = 0; n < PHASE_PER_CLK; n = n + 1) begin: loop_xpose
	      if (FULL_D_MAP[12*dout_i+:4] < 4'hA) begin: gen_d_lt10
            assign phy_dout[MAP0*FULL_D_MAP[(12*dout_i+8)+:3] + 
                            MAP1*FULL_D_MAP[(12*dout_i+4)+:2] + 
                            MAP2*FULL_D_MAP[12*dout_i+:4] + n]
                       = iob_wdata[(dout_i*PHASE_PER_CLK)+n];
          end else begin : gen_d_ge10
	        // If signal is placed in bit lane [10] or [11], route to upper
            // nibble of phy_dout lane [5] or [6] respectively (in this case
            // phy_dout lane [5, 6] are multiplexed to take input for two
            // different SDR signals - this is how bits[10,11] need to be
            // provided to the OUT_FIFO
	        assign phy_dout[MAP0*FULL_D_MAP[(12*dout_i+8)+:3] + 
                            MAP1*FULL_D_MAP[(12*dout_i+4)+:2] + 
                            MAP2*(FULL_D_MAP[12*dout_i+:4]-5) + 4 + n]
                       = iob_wdata[(dout_i*PHASE_PER_CLK)+n];
	      end //end of if           
        end //end of for
     end
   endgenerate
   
   generate
   genvar d0_i;
      for(d0_i = 0; d0_i <BYTE_WIDTH*12; d0_i = d0_i+12) begin: gen_loop_d0
		
        assign out_d[d0_i/12] = O[((D0_MAP[d0_i+10:d0_i+8]*48) +
	       (D0_MAP[d0_i+5:d0_i+4]*12) + (D0_MAP[d0_i+3:d0_i]))];
         
      end
   endgenerate   
	 
 // Data 1
   generate
   genvar d1_i;
      if(DATA_WIDTH > (BYTE_WIDTH))begin 
        for(d1_i = 0; d1_i <BYTE_WIDTH*12; d1_i = d1_i +12) begin: gen_loop_d1
        
          assign out_d[(BYTE_WIDTH)+ (d1_i/12)] = O[((D1_MAP[d1_i+10:d1_i+8]*48) +
	       (D1_MAP[d1_i+5:d1_i+4]*12) + (D1_MAP[d1_i+3:d1_i]))];
        end
       end
   endgenerate      

 // Data 2
   generate
   genvar d2_i;
      if(DATA_WIDTH > (BYTE_WIDTH*2))begin 
        for(d2_i = 0; d2_i <BYTE_WIDTH*12; d2_i = d2_i +12) begin: gen_loop_d2
        
          assign out_d[(BYTE_WIDTH*2)+ (d2_i/12)] = O[((D2_MAP[d2_i+10:d2_i+8]*48) +
	       (D2_MAP[d2_i+5:d2_i+4]*12) + (D2_MAP[d2_i+3:d2_i]))];
         end
       end
   endgenerate

 // Data 3
   generate
   genvar d3_i;
      if(DATA_WIDTH > (BYTE_WIDTH*3))begin 
        for(d3_i = 0; d3_i <BYTE_WIDTH*12; d3_i = d3_i +12) begin: gen_loop_d3    
          
        assign out_d[(BYTE_WIDTH*3)+ (d3_i/12)] = O[((D3_MAP[d3_i+10:d3_i+8]*48) +
	       (D3_MAP[d3_i+5:d3_i+4]*12) + (D3_MAP[d3_i+3:d3_i]))];
         end
       end
   endgenerate

// Data 4
   generate
   genvar d4_i;
      if(DATA_WIDTH > (BYTE_WIDTH*4))begin 
        for(d4_i = 0; d4_i <BYTE_WIDTH*12; d4_i = d4_i +12) begin: gen_loop_d4
          
          assign out_d[(BYTE_WIDTH*4)+ (d4_i/12)] = O[((D4_MAP[d4_i+10:d4_i+8]*48) +
	       (D4_MAP[d4_i+5:d4_i+4]*12) + (D4_MAP[d4_i+3:d4_i]))];
         end
       end
   endgenerate

 // Data 5
   generate
   genvar d5_i;
      if(DATA_WIDTH > (BYTE_WIDTH*5))begin  
        for(d5_i = 0; d5_i <BYTE_WIDTH*12; d5_i = d5_i +12) begin: gen_loop_d5
          
          assign out_d[(BYTE_WIDTH*5)+ (d5_i/12)] = O[((D5_MAP[d5_i+10:d5_i+8]*48) +
	       (D5_MAP[d5_i+5:d5_i+4]*12) + (D5_MAP[d5_i+3:d5_i]))];
         end 
       end
   endgenerate


  // Data 6
   generate
   genvar d6_i;
      if(DATA_WIDTH > (BYTE_WIDTH*6))begin 
        for(d6_i = 0; d6_i <BYTE_WIDTH*12; d6_i = d6_i +12) begin: gen_loop_d6
          
          assign out_d[(BYTE_WIDTH*6)+ (d6_i/12)] = O[((D6_MAP[d6_i+10:d6_i+8]*48) +
	       (D6_MAP[d6_i+5:d6_i+4]*12) + (D6_MAP[d6_i+3:d6_i]))];
          
         end
       end
   endgenerate


  // Data 7
   generate
   genvar d7_i;
      if(DATA_WIDTH > (BYTE_WIDTH*7))begin 
        for(d7_i = 0; d7_i <BYTE_WIDTH*12; d7_i = d7_i +12) begin: gen_loop_d7
          
         assign out_d[(BYTE_WIDTH*7)+ (d7_i/12)] = O[((D7_MAP[d7_i+10:d7_i+8]*48) +
	       (D7_MAP[d7_i+5:d7_i+4]*12) + (D7_MAP[d7_i+3:d7_i]))];
          
         end
       end
   endgenerate
   
   // byte writes
   
   // parameter BW_MAP = 84'h000_000_000_100_110_120_130,    
   
    generate
    genvar bw_i;
	
	for(bw_i = 0; bw_i < BW_WIDTH; bw_i = bw_i + 1) begin: gen_loop_bw_out
	  for (n = 0; n < PHASE_PER_CLK; n = n + 1) begin: loop_xpose
	      if (BW_MAP[12*bw_i+:4] < 4'hA) begin: gen_bw_lt10
            assign phy_dout[MAP0*BW_MAP[(12*bw_i+8)+:3] + 
                            MAP1*BW_MAP[(12*bw_i+4)+:2] + 
                            MAP2*BW_MAP[12*bw_i+:4] + n]
                       = iob_bw[(bw_i*PHASE_PER_CLK)+n];
          end else begin : gen_bw_ge10
	        // If signal is placed in bit lane [10] or [11], route to upper
            // nibble of phy_dout lane [5] or [6] respectively (in this case
            // phy_dout lane [5, 6] are multiplexed to take input for two
            // different SDR signals - this is how bits[10,11] need to be
            // provided to the OUT_FIFO
	        assign phy_dout[MAP0*BW_MAP[(12*bw_i+8)+:3] + 
                            MAP1*BW_MAP[(12*bw_i+4)+:2] + 
                            MAP2*(BW_MAP[12*bw_i+:4]-5) + 4 + n]
                       = iob_bw[(bw_i*PHASE_PER_CLK)+n];
	      end //end of if           
        end //end of for
	end
	
    for(bw_i = 0; bw_i < BW_WIDTH*12; bw_i = bw_i + 12) begin: gen_loop_bw

        assign out_bw_n[bw_i/12] = O [(BW_MAP[bw_i+10:bw_i+8]*48) + 
		                              (BW_MAP[bw_i+5:bw_i+4]*12)+ 
									  (BW_MAP[bw_i+3:bw_i+0])];	
     end
	       
    endgenerate
    

    generate
      genvar rd_i;
       for (rd_i = 0; rd_i < DATA_WIDTH; rd_i = rd_i +1) begin : gen_loop_rd 
       
           assign I[48*READ_DATA_MAP[(12*rd_i+8)+:3] + 
		            12*READ_DATA_MAP[(12*rd_i+4)+:2] +  
					READ_DATA_MAP[12*rd_i+:4]] 
					= in_q[rd_i];
        end 
   endgenerate

 //***************************************************************************
  // Read data bit steering
  //***************************************************************************

  // Transpose elements of rd_data_map to form final read data output:
  // phy_din elements are grouped according to "physical bit" - e.g.
  // for nCK_PER_CLK = 4, there are 8 data phases transfered per physical
  // bit per clock cycle: 
  //   = {dq0_fall3, dq0_rise3, dq0_fall2, dq0_rise2, 
  //      dq0_fall1, dq0_rise1, dq0_fall0, dq0_rise0}
  // whereas rd_data is are grouped according to "phase" - e.g.
  //   = {dq7_rise0, dq6_rise0, dq5_rise0, dq4_rise0,
  //      dq3_rise0, dq2_rise0, dq1_rise0, dq0_rise0}
  // therefore rd_data is formed by transposing phy_din - e.g.
  //   for nCK_PER_CLK = 4, and DQ_WIDTH = 16, and assuming MC_PHY 
  //   bit_lane[0] maps to DQ[0], and bit_lane[1] maps to DQ[1], then 
  //   the assignments for bits of rd_data corresponding to DQ[1:0]
  //   would be:      
  //    {rd_data[112], rd_data[96], rd_data[80], rd_data[64],
  //     rd_data[48], rd_data[32], rd_data[16], rd_data[0]} = phy_din[7:0]
  //    {rd_data[113], rd_data[97], rd_data[81], rd_data[65],
  //     rd_data[49], rd_data[33], rd_data[17], rd_data[1]} = phy_din[15:8]   
  generate
    genvar i, j;  
    for (i = 0; i < DATA_WIDTH; i = i + 1) begin: gen_loop_rd_data_1
      for (j = 0; j < PHASE_PER_CLK; j = j + 1) begin: gen_loop_rd_data_2
		if (READ_DATA_MAP[12*i+:4] < 4'hA) begin: gen_rd_data_lt10
          assign rd_data_map[DATA_WIDTH*j + i]
                   = phy_din[(DIN_MAP0*READ_DATA_MAP[(12*i+8)+:3]+
                              DIN_MAP1*READ_DATA_MAP[(12*i+4)+:2] +
                              DIN_MAP2*READ_DATA_MAP[12*i+:4]) + j];
		end else begin : gen_rd_data_ge10
	      // If signal is placed in bit lane [10] or [11], route to upper
          // nibble of phy_dout lane [5] or [6] respectively (in this case
          // phy_dout lane [5, 6] are multiplexed to take input for two
          // different SDR signals - this is how bits[10,11] need to be
          // provided to the OUT_FIFO
	      assign rd_data_map[DATA_WIDTH*j + i]
                   = phy_din[(DIN_MAP0*READ_DATA_MAP[(12*i+8)+:3]+
                              DIN_MAP1*READ_DATA_MAP[(12*i+4)+:2] +
                              DIN_MAP2*(READ_DATA_MAP[12*i+:4]-5) + 4) + j];
	    end	//end of if
      end
    end
  endgenerate
  
  // assign corresponding idelay_cnt value from calibration
  
   generate
      genvar q_i;
       for (q_i = 0; q_i < DATA_WIDTH; q_i = q_i +1) begin : gen_loop_q_val        
           assign idelay_cnt_in[(240*READ_DATA_MAP[(12*q_i+8)+:3] + 
		                          60*READ_DATA_MAP[(12*q_i+4)+:2] +  
								   5*READ_DATA_MAP[(12*q_i)+:4]) +: 5 ] 
							= dlyval_dq[q_i*5 +: 5];
           assign dbg_q_tapcnt[q_i*5 +: 5] = idelay_cnt_out[(240*READ_DATA_MAP[(12*q_i+8)+:3] + 
		                                                      60*READ_DATA_MAP[(12*q_i+4)+:2] +  
															   5*READ_DATA_MAP[(12*q_i)+:4]) +: 5 ];
           
           always @ (posedge clk) begin
             if (rst)
               q_dly_ce[q_i] <= #TCQ 1'b0;
             else if (dbg_sel_q == q_i) //which bit lane is activated
               q_dly_ce[q_i] <= #TCQ dbg_inc_q | dbg_dec_q |
                                     dbg_inc_q_all | dbg_dec_q_all;
             else
               q_dly_ce[q_i] <= #TCQ dbg_inc_q_all | dbg_dec_q_all;
           end //end of always
           
           always @ (posedge clk) begin
             if (rst)
               q_dly_inc[q_i] <= #TCQ 1'b0;
             else if (dbg_inc_q_all || dbg_inc_q)
               q_dly_inc[q_i] <= #TCQ 1'b1;
             else
               q_dly_inc[q_i] <= #TCQ 1'b0;
           end //end of always
           
           assign idelay_ce[(48*READ_DATA_MAP[(12*q_i+8)+:3] + 
                              12*READ_DATA_MAP[(12*q_i+4)+:2] +  
                               1*READ_DATA_MAP[(12*q_i)+:4])]
                            = q_dly_ce[q_i];
                            
           assign idelay_inc[(48*READ_DATA_MAP[(12*q_i+8)+:3] + 
                              12*READ_DATA_MAP[(12*q_i+4)+:2] +  
                               1*READ_DATA_MAP[(12*q_i)+:4])]
                            = q_dly_inc;
        end 
   endgenerate


  //***************************************************************************
  // Memory I/F output and I/O buffer instantiation
  //***************************************************************************

  // Note on instantiation - generally at the minimum, it's not required to 
  // instantiate the output buffers - they can be inferred by the synthesis
  // tool, and there aren't any attributes that need to be associated with
  // them. Consider as a future option to take out the OBUF instantiations
  
  OBUF u_w_n_obuf
    (
     .I (out_w_n),
     .O (qdr_w_n)
     );  

  OBUF u_r_n_obuf
    (
     .I (out_r_n),
     .O (qdr_r_n)
     );

  OBUF u_dll_off_n_obuf
    (
     .I (iob_dll_off_n),
     .O (qdr_dll_off_n)
     );
     
  generate
  genvar p;

    for (p = 0; p < ADDR_WIDTH; p = p + 1) begin: gen_sa_obuf
      OBUF u_sa_obuf
        (
         .I (out_sa[p]),
         .O (qdr_sa[p])
         );
    end
    
    for (p = 0; p < BW_WIDTH; p = p + 1) begin: gen_bw_obuf
      OBUF u_bw_n_obuf
        (
         .I (out_bw_n[p]),
         .O (qdr_bw_n[p])
         );      
    end
    
    if (MEMORY_IO_DIR == "UNIDIR") begin: gen_d_q_buf
      for (p = 0; p < DATA_WIDTH; p = p + 1) begin: loop_d_q
        //tie-off unused signals
        assign in_dq[p] = 'b0;
        
        OBUF u_d_obuf
          (
           .I (out_d[p]),
           .O (qdr_d[p])
           );
           
        IBUF u_q_ibuf
          (
           .I (qdr_q[p]),
           .O (in_q[p])
           );
      end
    end else begin: gen_dq_iobuf
      for (p = 0; p < DATA_WIDTH; p = p + 1) begin: loop_dq
        //tie-off unused signals
        assign qdr_d[p] = 'b0;
        assign in_q[p]  = 'b0;
        
        IOBUF #
        (
         .IBUF_LOW_PWR ("FALSE")
         )
        u_iobuf_dq
          (
           .I  (out_dq[p]),       
           .T  (ts_dq[p]),
           .O  (in_dq[p]),
           .IO (qdr_dq[p])
           );
      end
    end
    
  endgenerate

endmodule
