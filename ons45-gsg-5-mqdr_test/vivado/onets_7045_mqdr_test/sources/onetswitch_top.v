`timescale 1 ps / 1 ps

module onetswitch_top(
   inout [14:0]         DDR_addr,
   inout [2:0]          DDR_ba,
   inout                DDR_cas_n,
   inout                DDR_ck_n,
   inout                DDR_ck_p,
   inout                DDR_cke,
   inout                DDR_cs_n,
   inout [3:0]          DDR_dm,
   inout [31:0]         DDR_dq,
   inout [3:0]          DDR_dqs_n,
   inout [3:0]          DDR_dqs_p,
   inout                DDR_odt,
   inout                DDR_ras_n,
   inout                DDR_reset_n,
   inout                DDR_we_n,
   inout                FIXED_IO_ddr_vrn,
   inout                FIXED_IO_ddr_vrp,
   inout [53:0]         FIXED_IO_mio,
   inout                FIXED_IO_ps_clk,
   inout                FIXED_IO_ps_porb,
   inout                FIXED_IO_ps_srstb,

   input       [0:0]     qdriip_cq_p,
   input       [0:0]     qdriip_cq_n,
   input       [35:0]    qdriip_q,
   output wire [0:0]     qdriip_k_p,
   output wire [0:0]     qdriip_k_n,
   output wire [35:0]    qdriip_d,
   output wire [18:0]    qdriip_sa,
   output wire           qdriip_w_n,
   output wire           qdriip_r_n,
   output wire [3:0]     qdriip_bw_n,
   output wire           qdriip_dll_off_n,


   output [1:0]         pl_led      ,
   output [1:0]         pl_pmod     ,
   input [1:0]          pl_btn
);

   wire bd_fclk0_125m ;
   wire bd_fclk1_75m  ;
   wire bd_fclk2_200m ;
   wire bd_aresetn    ;
   wire ext_rstn      ;

   wire tg_compare_error;
   wire init_calib_complete;

   reg [23:0] cnt_0;
   reg [23:0] cnt_1;
   reg [23:0] cnt_2;
   reg [23:0] cnt_3;

   always @(posedge bd_fclk0_125m) begin
     cnt_0 <= cnt_0 + 1'b1;
   end
   always @(posedge bd_fclk1_75m) begin
     cnt_1 <= cnt_1 + 1'b1;
   end
   always @(posedge bd_fclk2_200m) begin
     cnt_2 <= cnt_2 + 1'b1;
   end
   always @(posedge bd_fclk2_200m) begin
     cnt_3 <= cnt_3 + 1'b1;
   end

   assign pl_led[0]  = init_calib_complete;
   assign pl_led[1]  = tg_compare_error;
   assign pl_pmod[0] = cnt_2[23];
   assign pl_pmod[1] = bd_aresetn;
   assign ext_rstn   = pl_btn[0];

onets_bd_wrapper i_onets_bd_wrapper(
   .DDR_addr            (DDR_addr),
   .DDR_ba              (DDR_ba),
   .DDR_cas_n           (DDR_cas_n),
   .DDR_ck_n            (DDR_ck_n),
   .DDR_ck_p            (DDR_ck_p),
   .DDR_cke             (DDR_cke),
   .DDR_cs_n            (DDR_cs_n),
   .DDR_dm              (DDR_dm),
   .DDR_dq              (DDR_dq),
   .DDR_dqs_n           (DDR_dqs_n),
   .DDR_dqs_p           (DDR_dqs_p),
   .DDR_odt             (DDR_odt),
   .DDR_ras_n           (DDR_ras_n),
   .DDR_reset_n         (DDR_reset_n),
   .DDR_we_n            (DDR_we_n),
   .FIXED_IO_ddr_vrn    (FIXED_IO_ddr_vrn),
   .FIXED_IO_ddr_vrp    (FIXED_IO_ddr_vrp),
   .FIXED_IO_mio        (FIXED_IO_mio),
   .FIXED_IO_ps_clk     (FIXED_IO_ps_clk),
   .FIXED_IO_ps_porb    (FIXED_IO_ps_porb),
   .FIXED_IO_ps_srstb   (FIXED_IO_ps_srstb),

   .bd_fclk0_125m       ( bd_fclk0_125m   ),
   .bd_fclk1_75m        ( bd_fclk1_75m    ),
   .bd_fclk2_200m       ( bd_fclk2_200m   ),
   .bd_aresetn          ( bd_aresetn      ),
   .ext_rstn            ( ext_rstn        )
);

example_top i_qdr_example_top(
   .sys_clk_i           ( bd_fclk2_200m       ),        // input                 sys_clk_i,
   .sys_rst             ( bd_aresetn          ),        // input                 sys_rst,
   .qdriip_cq_p         ( qdriip_cq_p         ),        // input       [0:0]     qdriip_cq_p,
   .qdriip_cq_n         ( qdriip_cq_n         ),        // input       [0:0]     qdriip_cq_n,
   .qdriip_q            ( qdriip_q            ),        // input       [35:0]    qdriip_q,
   .qdriip_k_p          ( qdriip_k_p          ),        // output wire [0:0]     qdriip_k_p,
   .qdriip_k_n          ( qdriip_k_n          ),        // output wire [0:0]     qdriip_k_n,
   .qdriip_d            ( qdriip_d            ),        // output wire [35:0]    qdriip_d,
   .qdriip_sa           ( qdriip_sa           ),        // output wire [18:0]    qdriip_sa,
   .qdriip_w_n          ( qdriip_w_n          ),        // output wire           qdriip_w_n,
   .qdriip_r_n          ( qdriip_r_n          ),        // output wire           qdriip_r_n,
   .qdriip_bw_n         ( qdriip_bw_n         ),        // output wire [3:0]     qdriip_bw_n,
   .qdriip_dll_off_n    ( qdriip_dll_off_n    ),        // output wire           qdriip_dll_off_n,
   .tg_compare_error    ( tg_compare_error    ),        // output                tg_compare_error,
   .init_calib_complete ( init_calib_complete )         // output                init_calib_complete
);

endmodule