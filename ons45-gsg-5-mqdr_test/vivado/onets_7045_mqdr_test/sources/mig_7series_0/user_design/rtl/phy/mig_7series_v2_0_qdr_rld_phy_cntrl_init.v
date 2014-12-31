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
// /___/  \  /    Vendor                : Xilinx
// \   \   \/     Version               : %version
//  \   \         Application           : MIG
//  /   /         Filename              : qdr_rld_phy_cntrl_init.v
// /___/   /\     Date Last Modified    : $Date: 2011/06/02 08:36:29 $
// \   \  /  \    Date Created          : Tue Jun 30 2009
//  \___\/\___\
//
//Device            : 7 Series
//Design            : QDRII+ SRAM / RLDRAM II SDRAM
//Purpose           : write to phy_control block and handle write_enable
//Reference         :
//Revision History  :
//*****************************************************************************

`timescale 1ps/1ps

module mig_7series_v2_0_qdr_rld_phy_cntrl_init #
( 
  parameter PRE_FIFO = "TRUE",
  parameter MEM_TYPE = "QDR2",
  parameter TCQ = 100  //Register Delay
)
(
  input              clk,
  input              rst,
  input              phy_ctl_ready,
  input              phy_ctl_full,
  input              phy_ctl_a_full,
  input              of_ctl_full,
  input              of_data_full,
  input [5:0]        phy_ctl_data_offset,
  input [2:0]        phy_ctl_cmd,
  
  output wire [31:0] phy_ctl_wd,
  output reg         phy_ctl_wr,
  output wire        io_fifo_rden_cal_done,
(* KEEP = "TRUE" *)  output reg         of_cmd_wr_en /* synthesis syn_keep = 1 */,
(* KEEP = "TRUE" *)  output reg         of_data_wr_en /* synthesis syn_keep = 1 */ 
);

  localparam [4:0] IDLE       = 5'b00000;
  localparam [4:0] STALL_CMD  = 5'b00001;
  localparam [4:0] CONT_CMD   = 5'b00010;
  localparam [4:0] CMD_WAIT1  = 5'b00100;
  localparam [4:0] CMD_WAIT2  = 5'b01000;
  localparam [4:0] CONT_CMD2  = 5'b10000;
  
  
  reg [4:0] pc_cntr_cmd;    
  reg [4:0] pc_command_offset;
  reg [5:0] pc_data_offset;
  reg [1:0] pc_seq; 
  reg [2:0] pc_cmd;
  reg [4:0] pc_ctl_ns;
  reg io_fifo_rden_cal_done_r;
  
  wire early_io_fifo_rden_cal_done;
  
  assign io_fifo_rden_cal_done = (PRE_FIFO == "TRUE")? io_fifo_rden_cal_done_r : 1'b1;

  assign phy_ctl_wd = {1'b0, 1'b1, pc_cntr_cmd[4:0], pc_seq[1:0], 
                       pc_data_offset[5:0], 2'b00, 3'b000, 
                       4'b0000, pc_command_offset[4:0], pc_cmd[2:0]}; 
  
  always @ (posedge clk) begin
    if (rst)
      pc_seq <= #TCQ 'b0;
    else if (phy_ctl_wr)
      pc_seq <= #TCQ pc_seq + 1;
  end
  
  always @ (posedge clk) begin
    if (rst) begin
      phy_ctl_wr            <=  #TCQ 1'b0;
      pc_cntr_cmd           <=  #TCQ 5'b11111;    
      pc_data_offset        <=  #TCQ 6'b000000;
      pc_command_offset     <=  #TCQ 5'b00000;
      pc_cmd                <=  #TCQ 3'b100;
      pc_ctl_ns             <=  #TCQ IDLE;   
      io_fifo_rden_cal_done_r <=  #TCQ 1'b0;
       
    end else begin 
      case (pc_ctl_ns) 
        IDLE : begin
          if (phy_ctl_ready) begin
            phy_ctl_wr        <= #TCQ 1'b1;
            pc_cntr_cmd       <= #TCQ 5'b11111;
            pc_data_offset    <= #TCQ 6'b000000;
            pc_command_offset <= #TCQ 5'b00000;
            pc_cmd            <= #TCQ 3'b100;
            pc_ctl_ns         <= #TCQ STALL_CMD;
          end else begin 
             pc_ctl_ns <= #TCQ IDLE;
          end
        end
        
        STALL_CMD : begin
           // issue stall command. The command offset delays the 
           // read from the phy control fifo
           if (~phy_ctl_a_full) begin
             phy_ctl_wr        <= #TCQ 1'b1;
             pc_cntr_cmd       <= #TCQ 5'b00000; // pc_cntr_cmd of 5'b000xx - refers to a stall command
             pc_data_offset    <= #TCQ 6'b000001;
             pc_command_offset <= #TCQ 5'b11111;  // max delay possible
             pc_cmd            <= #TCQ 3'b100; // Non data command
             pc_ctl_ns         <= #TCQ CONT_CMD; 
           end else begin
             pc_ctl_ns         <= #TCQ STALL_CMD;
		   end
           
         end
                
         CONT_CMD : begin  //0x02
           // continue to write into the phy control fifo until the fifo is full
           if (~phy_ctl_a_full) begin
             phy_ctl_wr            <= #TCQ 1'b1;
             pc_cntr_cmd           <= #TCQ 5'b11111;
             pc_data_offset        <= #TCQ 6'b100010;  // was 0
             pc_command_offset     <= #TCQ 5'b00000;
             pc_cmd                <= #TCQ 3'b001; 
             pc_ctl_ns             <= #TCQ CONT_CMD;    
           end else begin
             // phy_ctl_wr cannot be asserted when full flag is high
             phy_ctl_wr            <= #TCQ 1'b0;
             pc_cntr_cmd           <= #TCQ 5'b11111;    
             pc_data_offset        <= #TCQ 6'b000000;
             pc_command_offset     <= #TCQ 5'b00000;
             pc_cmd                <= #TCQ 3'b001;
             pc_ctl_ns             <= #TCQ CONT_CMD2;
           end 
             //io_fifo_rden_cal_done <= #TCQ 1'b1;                   
         end
         
         // wait for the full flag to deassert. Then start writing into the phy command fifo.
         CMD_WAIT1 : begin
             if (~ phy_ctl_a_full) begin
               phy_ctl_wr            <= #TCQ 1'b0;
               pc_cntr_cmd           <= #TCQ 5'b11111;
			   pc_data_offset        <= #TCQ 6'b000000;
               pc_command_offset     <= #TCQ 5'b00000;
               pc_cmd                <= #TCQ 3'b001;
               pc_ctl_ns             <= #TCQ CONT_CMD2;
             end
          end
          
          
       //   // potential additional stage, probably not required.. will need to remove
       //   CMD_WAIT2 : begin
       //      
       //      phy_ctl_wr            <= #TCQ 1'b0;
       //      pc_cntr_cmd           <= #TCQ 5'b11111;    
       //      pc_data_offset        <= #TCQ 6'b000000;
       //      pc_command_offset     <= #TCQ 5'b00000;
       //      pc_cmd                <= #TCQ 3'b001;
       //      pc_ctl_ns             <= #TCQ CONT_CMD2;
       //      
       //   end
                 
         CONT_CMD2 : begin
           // continue to write NOP commands to the control fifo as long as 
           // the fifo is not full. 
           // The fifo will not be full as by now the read enable will be 
           // asserted and will be held high.
           // Now the WRITE data and COMMAND fifos can be filled with 
           // data by the controller.
           if (~phy_ctl_a_full) begin
             phy_ctl_wr            <= #TCQ 1'b1;
             pc_cntr_cmd           <= #TCQ (MEM_TYPE == "RLD3") ? 5'b0 : 5'b11111;
             pc_data_offset        <= #TCQ phy_ctl_data_offset; //6'b000000
             pc_command_offset     <= #TCQ 5'b00000;
             pc_cmd                <= #TCQ phy_ctl_cmd; //3'b001
             pc_ctl_ns             <= #TCQ CONT_CMD2; 
             io_fifo_rden_cal_done_r <= #TCQ 1'b1;          
           end  
         end // case: CONT_CMD2

	default : begin
	   phy_ctl_wr            <=  #TCQ 1'b0;
           pc_cntr_cmd           <=  #TCQ 5'b11111;    
           pc_data_offset        <=  #TCQ 6'b000000;
           pc_command_offset     <=  #TCQ 5'b00000;
           pc_cmd                <=  #TCQ 3'b100;
           pc_ctl_ns             <=  #TCQ IDLE;
	end
      endcase
    end
  end
  
  assign early_io_fifo_rden_cal_done = (pc_ctl_ns == CONT_CMD2 && !phy_ctl_a_full) ? 1'b1 : 1'b0;
  
 //Generate write enable for the out FIFOs
 //always write while the FIFOs are not FULL
 always @ (posedge clk) begin
     if (rst)  begin
       of_cmd_wr_en  <= #TCQ 1'b0;
       of_data_wr_en <= #TCQ 1'b0;
      
     end else if ((PRE_FIFO == "TRUE") && (~phy_ctl_ready)) begin
        of_cmd_wr_en  <= #TCQ 1'b0;
        of_data_wr_en <= #TCQ 1'b0;
  
	 end else if (MEM_TYPE == "RLD3") begin
	   if ((PRE_FIFO == "TRUE") && (!early_io_fifo_rden_cal_done)) begin
        of_cmd_wr_en  <= #TCQ phy_ctl_wr;
        of_data_wr_en <= #TCQ phy_ctl_wr;
       end else begin
	     of_cmd_wr_en  <= #TCQ ~of_ctl_full;
         of_data_wr_en <= #TCQ ~of_data_full;
	   end
	end else if ((PRE_FIFO == "TRUE") && (~io_fifo_rden_cal_done_r)) begin
	  of_cmd_wr_en  <= #TCQ phy_ctl_wr;
      of_data_wr_en <= #TCQ phy_ctl_wr;
    //end else begin //can possibly change this to be always high if Pre-fifo is used.
    end else if ( ~ (of_ctl_full | of_data_full)) begin //can possibly change this to be always high if Pre-fifo is used.
    
      of_cmd_wr_en  <= #TCQ 1'b1;//~(of_ctl_full | of_data_full);
      of_data_wr_en <= #TCQ 1'b1; //~(of_ctl_full | of_data_full);
    end
  end


 
endmodule
