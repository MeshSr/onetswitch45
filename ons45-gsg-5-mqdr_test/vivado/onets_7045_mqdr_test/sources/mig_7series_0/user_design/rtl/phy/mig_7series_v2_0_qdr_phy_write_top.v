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
//  /   /         Filename           : qdr_phy_write_top.v
// /___/   /\     Date Last Modified : $date$
// \   \  /  \    Date Created       : Nov 12, 2008 
//  \___\/\___\
//
//Device: 7 Series
//Design: QDRII+ SRAM
//
//Purpose:
//    This module
//  1. Instantiates all the write path submodules
//
//Revision History:	8/31/2012 - Added 2 x18 compoents support for write calibration.
//                  7/30/2013              Added PO_COARSE_BYPASS for QDR2+ design.

////////////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps

module mig_7series_v2_0_qdr_phy_write_top #
(  
  parameter PRE_FIFO      = "TRUE",
  parameter SIMULATION    = "TRUE",
  parameter PO_COARSE_BYPASS   = "FALSE",

  parameter BYTE_LANE_WITH_DK = 4'h00,
  parameter CLK_STABLE      = 2048,   //Cycles till CQ/CQ# are stable  
  parameter RST_ACT_LOW     = 1,      //sys reset is active low 
  parameter BURST_LEN   = 4,            //Burst Length
  parameter CLK_PERIOD  = 2500,         //Memory Clk Period (in ps)
  parameter CK_WIDTH    = 1,
  parameter DATA_WIDTH  = 72,           //Data Width
  parameter ADDR_WIDTH  = 19,           //Address Width
  parameter BW_WIDTH    = 8,            //Byte Write Width 
  parameter N_CTL_LANES = 2,
  parameter N_DATA_LANES = 4,
  parameter nCK_PER_CLK = 2,
  parameter SIM_BYPASS_INIT_CAL = "OFF",
  parameter PO_ADJ_GAP  = 7,            //Time to wait between PO adj
  parameter TCQ         = 100           //Register Delay
)
(
  //System Signals
  input                                    clk,             //main system half freq clk
  input                                    rst_wr_clk,      //main write path reset
  input                                    clk_mem,         //full frequency clock
  input                                    sys_rst,
  output                                   rst_clk,         // asserted until memory clocks are stable
                                           
  //cal signals                            
  output                                   init_done,       //init done, cal can begin
  output reg                               po_dec_done,
  output reg                               po_inc_done,
  output                                   edge_adv_cal_start,
  input                                    edge_adv_cal_done,
   input wire  [N_DATA_LANES-1:0]          phase_valid,              

  output wire [1:0]                        wrcal_byte_sel,
  output                                   wrlvl_po_f_inc,
  output                                   wrlvl_po_f_dec,
  output                                   wrcal_en,
  output                                   rdlvl_stg1_start, //stage 1 calibration start
  input                                    rdlvl_stg1_done, 
  output                                   cal1_rdlvl_restart,
  output                                   cal_stage2_start,//stage 2 calibration start
  output                                   init_cal_done,        // Init calibration done
  input                                    read_cal_done,        // Read calibration done
  input                                    po_delay_done,   
                                           
  // hard phy control signals              
                                           
  input                                    phy_ctl_ready,
  input                                    phy_ctl_full,
  input                                    phy_ctl_a_full,
  input                                    of_ctl_full,
  input                                    of_data_full,
  input [8:0]                              po_counter_read_val,
                                           
  output [31:0]                            phy_ctl_wd,
  output                                   phy_ctl_wr,
  output                                   io_fifo_rden_cal_done,
  output                                   of_cmd_wr_en,         // OUT_FIFO write enable
  output                                   of_data_wr_en,
  output reg                               po_cnt_dec,
  output reg                               po_cnt_inc,  

  // from User Interface
  input                                     wr_cmd0,         //wr command 0
  input                                     wr_cmd1,         //wr command 1
  input       [ADDR_WIDTH-1:0]              wr_addr0,        //wr address 0
  input       [ADDR_WIDTH-1:0]              wr_addr1,        //wr address 1
  input                                     rd_cmd0,         //rd command 0
  input                                     rd_cmd1,         //rd command 1
  input       [ADDR_WIDTH-1:0]              rd_addr0,        //rd address 0
  input       [ADDR_WIDTH-1:0]              rd_addr1,        //rd address 1
  input       [DATA_WIDTH*2-1:0]            wr_data0,        //user write data 0
  input       [DATA_WIDTH*2-1:0]            wr_data1,        //user write data 1
  input       [BW_WIDTH*2-1:0]              wr_bw_n0,        //user byte writes 0
  input       [BW_WIDTH*2-1:0]              wr_bw_n1,        //user byte writes 1
  output      [1:0]                         int_rd_cmd_n,    
                                            
  output  [nCK_PER_CLK*2*ADDR_WIDTH-1:0]    iob_addr,
  output  [nCK_PER_CLK*2-1:0]               iob_wr_n,
  output  [nCK_PER_CLK*2-1:0]               iob_rd_n,
  output  [nCK_PER_CLK*2*DATA_WIDTH-1:0]    iob_wdata,
  output  [nCK_PER_CLK*2*BW_WIDTH-1:0]      iob_bw,
                                            
  // To Address/Command PHASER_OUT          
  output wire [5:0]                          ctl_lane_cnt,         // selects which control byte
                                             
  output wire                                mem_dll_off_n,
                                            
                                            
  //ChipScope Debug Signals                 
   input                                     dbg_SM_No_Pause,
  output wire [1:0]                          dbg_phy_wr_cmd_n,//cs debug - wr command
  output wire [ADDR_WIDTH*4-1:0]             dbg_phy_addr,    //cs debug - address
  output wire [1:0]                          dbg_phy_rd_cmd_n,//cs debug - rd command
  output wire [DATA_WIDTH*4-1:0]             dbg_phy_wr_data,  //cs debug - wr data
  output wire [255:0]                        dbg_wr_init,
  input                                      dbg_phy_init_wr_only,
  input                                      dbg_phy_init_rd_only,
  
  input                                      dbg_SM_en,
  output wire                                po_sel_fine_oclk_delay,  
  output wire                                wrlvl_calib_in_common
);

  wire [1:0]                      init_rd_cmd;
  wire [1:0]                      init_wr_cmd;
  wire [ADDR_WIDTH-1:0]           init_wr_addr0;
  wire [ADDR_WIDTH-1:0]           init_wr_addr1;
  wire [ADDR_WIDTH-1:0]           init_rd_addr0;
  wire [ADDR_WIDTH-1:0]           init_rd_addr1;
  wire [DATA_WIDTH*2-1:0]         init_wr_data0;
  wire [DATA_WIDTH*2-1:0]         init_wr_data1;
  
  wire [ADDR_WIDTH-1:0]           iob_addr_rise0;
  wire [ADDR_WIDTH-1:0]           iob_addr_fall0; 
  wire [ADDR_WIDTH-1:0]           iob_addr_rise1; 
  wire [ADDR_WIDTH-1:0]           iob_addr_fall1; 
  wire [DATA_WIDTH-1:0]           iob_data_rise0;
  wire [DATA_WIDTH-1:0]           iob_data_fall0; 
  wire [DATA_WIDTH-1:0]           iob_data_rise1;
  wire [DATA_WIDTH-1:0]           iob_data_fall1; 
  wire [BW_WIDTH-1:0]             iob_bw_rise0;  
  wire [BW_WIDTH-1:0]             iob_bw_fall0; 
  wire [BW_WIDTH-1:0]             iob_bw_rise1;  
  wire [BW_WIDTH-1:0]             iob_bw_fall1; 
  wire [1:0]                      int_wr_cmd_n;

  reg [8:0]                po_rdval_cnt;
  reg [2:0]                io_fifo_rden_cal_done_r;
  reg [2:0]                po_gap_enforcer;
  wire                     po_adjust_rdy;
  
    generate
  genvar addr_i;
   for (addr_i = 0; addr_i < ADDR_WIDTH; addr_i = addr_i+1) begin : gen_iob_addr_inst
      assign iob_addr[(addr_i*4)+3] = iob_addr_fall1[addr_i] ;
      assign iob_addr[(addr_i*4)+2] = iob_addr_rise1[addr_i] ;
      assign iob_addr[(addr_i*4)+1] = iob_addr_fall0[addr_i] ;
      assign iob_addr[(addr_i*4)]   = iob_addr_rise0[addr_i] ;
   end
  endgenerate
  
  assign iob_rd_n = {int_rd_cmd_n[1], int_rd_cmd_n[1],int_rd_cmd_n[0],int_rd_cmd_n[0]};
  assign iob_wr_n = {int_wr_cmd_n[1], int_wr_cmd_n[1],int_wr_cmd_n[0],int_wr_cmd_n[0]}; 
  
  generate
  genvar wd_i;
   for (wd_i = 0; wd_i < DATA_WIDTH; wd_i = wd_i+1) begin : gen_iob_wd_inst
      assign iob_wdata[(wd_i*4)+3] = iob_data_fall1[wd_i] ;
      assign iob_wdata[(wd_i*4)+2] = iob_data_rise1[wd_i] ;
      assign iob_wdata[(wd_i*4)+1] = iob_data_fall0[wd_i] ;
      assign iob_wdata[(wd_i*4)]   = iob_data_rise0[wd_i] ;
   end
  endgenerate
  
  generate
  genvar bw_i;
   for (bw_i = 0; bw_i < BW_WIDTH; bw_i = bw_i+1) begin : gen_iob_bw_inst
      assign iob_bw[(bw_i*4)+3] = iob_bw_fall1[bw_i] ;
      assign iob_bw[(bw_i*4)+2] = iob_bw_rise1[bw_i] ;
      assign iob_bw[(bw_i*4)+1] = iob_bw_fall0[bw_i] ;
      assign iob_bw[(bw_i*4)]   = iob_bw_rise0[bw_i] ;
   end
  endgenerate

  mig_7series_v2_0_qdr_phy_write_control_io #
    (
    .BURST_LEN   (BURST_LEN),
    .ADDR_WIDTH  (ADDR_WIDTH),
    .TCQ         (TCQ)
  ) u_qdr_phy_write_control (
    .clk                (clk),
    .rst_clk            (rst_clk),
    .wr_cmd0            (wr_cmd0),
    .wr_cmd1            (wr_cmd1),
    .wr_addr0           (wr_addr0),
    .wr_addr1           (wr_addr1),
    .rd_cmd0            (rd_cmd0),
    .rd_cmd1            (rd_cmd1),
    .rd_addr0           (rd_addr0),
    .rd_addr1           (rd_addr1),
    .init_rd_cmd        (init_rd_cmd),
    .init_wr_cmd        (init_wr_cmd),
    .init_wr_addr0      (init_wr_addr0),
    .init_wr_addr1      (init_wr_addr1),
    .init_rd_addr0      (init_rd_addr0),
    .init_rd_addr1      (init_rd_addr1),
    .cal_done           (init_cal_done),
    .int_rd_cmd_n       (int_rd_cmd_n),
    .int_wr_cmd_n       (int_wr_cmd_n),     
    .iob_addr_rise0     (iob_addr_rise0), 
    .iob_addr_fall0     (iob_addr_fall0), 
    .iob_addr_rise1     (iob_addr_rise1), 
    .iob_addr_fall1     (iob_addr_fall1),
    .dbg_phy_wr_cmd_n   (dbg_phy_wr_cmd_n),
    .dbg_phy_addr       (dbg_phy_addr),    
    .dbg_phy_rd_cmd_n   (dbg_phy_rd_cmd_n)
  );

  mig_7series_v2_0_qdr_phy_write_data_io #
    (
    .BURST_LEN   (BURST_LEN),
    .DATA_WIDTH  (DATA_WIDTH),
    .BW_WIDTH    (BW_WIDTH),
    .TCQ         (TCQ)
  ) u_qdr_phy_write_data (
    .clk                (clk),
    .rst_clk            (rst_clk), 
    .cal_done           (init_cal_done),  
    .wr_cmd0            (wr_cmd0),
    .wr_cmd1            (wr_cmd1),    
    .init_wr_cmd        (init_wr_cmd),     
    .init_wr_data0      (init_wr_data0),
    .init_wr_data1      (init_wr_data1),
    .wr_data0           (wr_data0), 
    .wr_data1           (wr_data1),
    .wr_bw_n0           (wr_bw_n0), 
    .wr_bw_n1           (wr_bw_n1),
    .iob_data_rise0     (iob_data_rise0),
    .iob_data_fall0     (iob_data_fall0), 
    .iob_data_rise1     (iob_data_rise1),
    .iob_data_fall1     (iob_data_fall1),
    .iob_bw_rise0       (iob_bw_rise0), 
    .iob_bw_fall0       (iob_bw_fall0), 
    .iob_bw_rise1       (iob_bw_rise1),  
    .iob_bw_fall1       (iob_bw_fall1),
    .dbg_phy_wr_data    (dbg_phy_wr_data) 
  );

  mig_7series_v2_0_qdr_phy_write_init_sm #
    (
    .BURST_LEN   (BURST_LEN),  
    .BYTE_LANE_WITH_DK     (BYTE_LANE_WITH_DK),
    .N_DATA_LANES  (N_DATA_LANES),
    .CLK_STABLE  (CLK_STABLE),
    .CLK_PERIOD  (CLK_PERIOD),
    .RST_ACT_LOW (RST_ACT_LOW),
    .CK_WIDTH             (CK_WIDTH),    
    .ADDR_WIDTH  (ADDR_WIDTH),
    .DATA_WIDTH  (DATA_WIDTH),
    .BW_WIDTH    (BW_WIDTH),
    .SIMULATION                  (SIMULATION),
    
    .SIM_BYPASS_INIT_CAL (SIM_BYPASS_INIT_CAL),
    .TCQ         (TCQ)
  ) u_qdr_phy_write_init_sm (
    .clk                (clk),
    .sys_rst            (sys_rst), 
    .rst_wr_clk         (rst_wr_clk),
    .ck_addr_cmd_delay_done (po_delay_done),
    .rdlvl_stg1_start    (rdlvl_stg1_start),
    .wrlvl_po_f_inc     (wrlvl_po_f_inc),
    .wrlvl_po_f_dec     (wrlvl_po_f_dec),
    .wrcal_en                  (wrcal_en),
    .wrcal_byte_sel               (wrcal_byte_sel),
    
    .po_counter_read_val  (po_counter_read_val),
    .rdlvl_stg1_done    (rdlvl_stg1_done),
    .cal1_rdlvl_restart (cal1_rdlvl_restart),
    .edge_adv_cal_start (edge_adv_cal_start), 
    .edge_adv_cal_done  (edge_adv_cal_done ),
    .phase_valid        (phase_valid),
    .cal_stage2_start   (cal_stage2_start),
    .init_cal_done      (init_cal_done),
    .read_cal_done      (read_cal_done),
    .rst_clk            (rst_clk),
    .init_done          (init_done), 
    .init_wr_data0      (init_wr_data0),
    .init_wr_data1      (init_wr_data1),
    .init_wr_addr0      (init_wr_addr0),
    .init_wr_addr1      (init_wr_addr1),
    .init_rd_addr0      (init_rd_addr0),
    .init_rd_addr1      (init_rd_addr1),
    .init_rd_cmd        (init_rd_cmd),
    .init_wr_cmd        (init_wr_cmd),
    .mem_dll_off_n      (mem_dll_off_n),
    .dbg_SM_No_Pause    (dbg_SM_No_Pause),
	.dbg_MIN_STABLE_EDGE_CNT (3'b0), //what value should this have??
    .dbg_wr_init        (dbg_wr_init),
    .dbg_phy_init_wr_only (dbg_phy_init_wr_only),
    .dbg_phy_init_rd_only (dbg_phy_init_rd_only) ,
    .po_sel_fine_oclk_delay (po_sel_fine_oclk_delay),
    .wrlvl_calib_in_common (wrlvl_calib_in_common),
     .dbg_SM_en                      (dbg_SM_en)
  );
  
  
  mig_7series_v2_0_qdr_rld_phy_cntrl_init #
   (
   .PRE_FIFO (PRE_FIFO),
   .TCQ  (TCQ)  //Register Delay
   ) 
   u_qdr_rld_phy_cntrl_init
  (
       .clk                       (clk),
       .rst                       (rst_clk),
       .phy_ctl_ready             (phy_ctl_ready),
       .phy_ctl_full              (phy_ctl_full),
       .phy_ctl_a_full            (phy_ctl_a_full),
       .of_ctl_full               (of_ctl_full),
       .of_data_full              (of_data_full),
	   .phy_ctl_data_offset       (6'b000000),
	   .phy_ctl_cmd               (3'b001), //Always writing
       .phy_ctl_wd                (phy_ctl_wd),
       .phy_ctl_wr                (phy_ctl_wr),
       .io_fifo_rden_cal_done     (io_fifo_rden_cal_done),
       .of_cmd_wr_en              (of_cmd_wr_en),
       .of_data_wr_en             (of_data_wr_en)
   );   

   //**************************************************************************
   // Decrement all phaser_outs to starting position
   //**************************************************************************
   
   always @(posedge clk) begin
     io_fifo_rden_cal_done_r[0] <= #TCQ io_fifo_rden_cal_done;
     io_fifo_rden_cal_done_r[1] <= #TCQ io_fifo_rden_cal_done_r[0];
     io_fifo_rden_cal_done_r[2] <= #TCQ io_fifo_rden_cal_done_r[1];
   end
   
   localparam PO_STG2_MIN = 30;  //  D Write Path's stage 2 PO are set to 30 to make room for
                                 //  deskew between byte lanes using PO FINE delay.
   
   //counter to determine how much to decrement
   always @(posedge clk) begin
     if (rst_clk) begin
       po_rdval_cnt    <= #TCQ 'd0;
     end else if (io_fifo_rden_cal_done_r[1] && 
                 ~io_fifo_rden_cal_done_r[2]) begin
       po_rdval_cnt    <= #TCQ po_counter_read_val;
     end else if ((po_rdval_cnt > PO_STG2_MIN) && PO_COARSE_BYPASS == "FALSE")  begin
       if (po_cnt_dec)
         po_rdval_cnt  <= #TCQ po_rdval_cnt - 1;
       else            
         po_rdval_cnt  <= #TCQ po_rdval_cnt;
     end else if ((po_rdval_cnt == 'd0) && PO_COARSE_BYPASS == "FALSE")begin
       po_rdval_cnt    <= #TCQ po_rdval_cnt;

     end else if ((po_rdval_cnt < PO_STG2_MIN) && PO_COARSE_BYPASS == "TRUE")  begin
       if (po_cnt_inc)
         po_rdval_cnt  <= #TCQ po_rdval_cnt + 1;
       else            
         po_rdval_cnt  <= #TCQ po_rdval_cnt;
     end else if ((po_rdval_cnt == 'd30) &&  PO_COARSE_BYPASS == "TRUE") begin
       po_rdval_cnt    <= #TCQ po_rdval_cnt;
     end
   end
   
   //Counter used to adjust the time between decrements
   always @ (posedge clk) begin
     if (rst_clk || po_cnt_dec || po_cnt_inc) begin
	   po_gap_enforcer <= #TCQ PO_ADJ_GAP; //8 clocks between adjustments for HW
	 end else if (po_gap_enforcer != 'b0) begin
	   po_gap_enforcer <= #TCQ po_gap_enforcer - 1;
	 end else begin
	   po_gap_enforcer <= #TCQ po_gap_enforcer; //hold value
	 end
   end
   
   assign po_adjust_rdy = (po_gap_enforcer == 'b0) ? 1'b1 : 1'b0;
   
   //decrement signal
   always @(posedge clk) begin
     if (rst_clk) begin
       po_cnt_dec      <= #TCQ 1'b0;
     end else if (io_fifo_rden_cal_done_r[2] && (po_rdval_cnt > PO_STG2_MIN) && po_adjust_rdy) begin
       po_cnt_dec      <= #TCQ ~po_cnt_dec;
     end else if (po_rdval_cnt == 'd0) begin
       po_cnt_dec      <= #TCQ 1'b0;
     end
   end
   
   //increment signal
   always @(posedge clk) begin
     if (rst_clk) 
       po_cnt_inc      <= #TCQ 1'b0;  
     else if (PO_COARSE_BYPASS == "FALSE")
       po_cnt_inc      <= #TCQ 1'b0;  
     else if (io_fifo_rden_cal_done_r[2] && (po_rdval_cnt < PO_STG2_MIN) && po_adjust_rdy) begin
       po_cnt_inc      <= #TCQ ~po_cnt_inc;
     end else if (po_rdval_cnt == 'd30) begin
       po_cnt_inc      <= #TCQ 1'b0;
     end
   end

   
   //indicate when finished
   always @(posedge clk) begin
     if (rst_clk) begin
         if ( PO_COARSE_BYPASS == "FALSE")
       po_dec_done <= #TCQ 1'b0;
         else
            po_dec_done <= #TCQ 1'b1;

     end else if (((po_cnt_dec == 'd1) && (po_rdval_cnt == 'd1)) ||
                  (io_fifo_rden_cal_done_r[2] && (po_rdval_cnt == PO_STG2_MIN))) begin

       po_dec_done <= #TCQ 1'b1;
     end
   end
  
  
   
   //indicate when finished
   always @(posedge clk) begin
     if (rst_clk) 
       po_inc_done <= #TCQ 1'b0;
	 else if (	PO_COARSE_BYPASS == "FALSE")
        po_inc_done <= #TCQ 1'b0;

     else if (io_fifo_rden_cal_done_r[2] && (po_rdval_cnt == PO_STG2_MIN)) begin

       po_inc_done <= #TCQ 1'b1;
     end
   end
            
   // check for flags from both fifos before writing into the Output fifos.
  /*always @ (posedge clk)
    begin
      if (rst_clk) begin
        of_cmd_wr_en  <= #TCQ 1'b0;
        of_data_wr_en <= #TCQ 1'b0;
      end else if (~(of_ctl_full || of_data_full)) begin
        of_cmd_wr_en  <= #TCQ 1'b1; 
        of_data_wr_en <= #TCQ 1'b1;  
      end       
    end */
          

endmodule
