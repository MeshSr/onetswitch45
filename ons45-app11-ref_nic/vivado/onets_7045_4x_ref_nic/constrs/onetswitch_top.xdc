############################################################
## Timing Constraints
############################################################
set_false_path -from [get_clocks clk_fpga_1] -to [get_clocks clk_fpga_0]
set_false_path -from [get_clocks clk_fpga_1] -to [get_clocks clk_fpga_2]




create_debug_core u_ila_0_0 labtools_ila_v3
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0_0]
set_property port_width 1 [get_debug_ports u_ila_0_0/clk]
connect_debug_port u_ila_0_0/clk [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_mac_rx_mac_aclk]]
set_property port_width 8 [get_debug_ports u_ila_0_0/probe0]
connect_debug_port u_ila_0_0/probe0 [get_nets [list {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/rx_axis_mac_tdata[0]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/rx_axis_mac_tdata[1]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/rx_axis_mac_tdata[2]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/rx_axis_mac_tdata[3]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/rx_axis_mac_tdata[4]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/rx_axis_mac_tdata[5]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/rx_axis_mac_tdata[6]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/rx_axis_mac_tdata[7]}]]
create_debug_core u_ila_1_0 labtools_ila_v3
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_1_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_1_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_1_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_1_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1_0]
set_property port_width 1 [get_debug_ports u_ila_1_0/clk]
connect_debug_port u_ila_1_0/clk [get_nets [list bd_fclk1_75m]]
set_property port_width 1 [get_debug_ports u_ila_1_0/probe0]
connect_debug_port u_ila_1_0/probe0 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_dma_0/U0/axi_resetn]]
create_debug_core u_ila_2_0 labtools_ila_v3
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_2_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_2_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_2_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_2_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_2_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_2_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_2_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_2_0]
set_property port_width 1 [get_debug_ports u_ila_2_0/clk]
connect_debug_port u_ila_2_0/clk [get_nets [list bd_fclk0_125m]]
set_property port_width 4 [get_debug_ports u_ila_2_0/probe0]
connect_debug_port u_ila_2_0/probe0 [get_nets [list {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tkeep[0]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tkeep[1]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tkeep[2]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tkeep[3]}]]
create_debug_core u_ila_3 labtools_ila_v3
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_3]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_3]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_3]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_3]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_3]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_3]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_3]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_3]
set_property port_width 1 [get_debug_ports u_ila_3/clk]
connect_debug_port u_ila_3/clk [get_nets [list i_onets_bd_wrapper/onets_bd_i/gtx_clk_1]]
set_property port_width 8 [get_debug_ports u_ila_3/probe0]
connect_debug_port u_ila_3/probe0 [get_nets [list {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/tx_axis_mac_tdata[0]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/tx_axis_mac_tdata[1]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/tx_axis_mac_tdata[2]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/tx_axis_mac_tdata[3]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/tx_axis_mac_tdata[4]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/tx_axis_mac_tdata[5]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/tx_axis_mac_tdata[6]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/tx_axis_mac_tdata[7]}]]
create_debug_port u_ila_0_0 probe
set_property port_width 1 [get_debug_ports u_ila_0_0/probe1]
connect_debug_port u_ila_0_0/probe1 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/rx_axis_mac_tlast]]
create_debug_port u_ila_0_0 probe
set_property port_width 1 [get_debug_ports u_ila_0_0/probe2]
connect_debug_port u_ila_0_0/probe2 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/rx_axis_mac_tuser]]
create_debug_port u_ila_0_0 probe
set_property port_width 1 [get_debug_ports u_ila_0_0/probe3]
connect_debug_port u_ila_0_0/probe3 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/rx_axis_mac_tvalid]]
create_debug_port u_ila_1_0 probe
set_property port_width 1 [get_debug_ports u_ila_1_0/probe1]
connect_debug_port u_ila_1_0/probe1 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_dma_0/U0/mm2s_introut]]
create_debug_port u_ila_1_0 probe
set_property port_width 1 [get_debug_ports u_ila_1_0/probe2]
connect_debug_port u_ila_1_0/probe2 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_dma_0/U0/s2mm_introut]]
create_debug_port u_ila_2_0 probe
set_property port_width 32 [get_debug_ports u_ila_2_0/probe1]
connect_debug_port u_ila_2_0/probe1 [get_nets [list {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[0]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[1]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[2]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[3]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[4]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[5]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[6]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[7]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[8]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[9]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[10]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[11]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[12]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[13]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[14]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[15]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[16]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[17]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[18]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[19]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[20]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[21]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[22]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[23]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[24]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[25]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[26]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[27]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[28]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[29]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[30]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tdata[31]}]]
create_debug_port u_ila_2_0 probe
set_property port_width 32 [get_debug_ports u_ila_2_0/probe2]
connect_debug_port u_ila_2_0/probe2 [get_nets [list {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[0]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[1]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[2]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[3]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[4]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[5]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[6]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[7]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[8]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[9]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[10]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[11]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[12]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[13]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[14]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[15]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[16]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[17]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[18]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[19]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[20]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[21]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[22]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[23]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[24]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[25]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[26]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[27]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[28]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[29]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[30]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tdata[31]}]]
create_debug_port u_ila_2_0 probe
set_property port_width 1 [get_debug_ports u_ila_2_0/probe3]
connect_debug_port u_ila_2_0/probe3 [get_nets [list {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tkeep[3]}]]
create_debug_port u_ila_2_0 probe
set_property port_width 32 [get_debug_ports u_ila_2_0/probe4]
connect_debug_port u_ila_2_0/probe4 [get_nets [list {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[0]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[1]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[2]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[3]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[4]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[5]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[6]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[7]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[8]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[9]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[10]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[11]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[12]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[13]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[14]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[15]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[16]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[17]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[18]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[19]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[20]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[21]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[22]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[23]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[24]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[25]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[26]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[27]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[28]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[29]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[30]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tdata[31]}]]
create_debug_port u_ila_2_0 probe
set_property port_width 4 [get_debug_ports u_ila_2_0/probe5]
connect_debug_port u_ila_2_0/probe5 [get_nets [list {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tkeep[0]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tkeep[1]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tkeep[2]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tkeep[3]}]]
create_debug_port u_ila_2_0 probe
set_property port_width 32 [get_debug_ports u_ila_2_0/probe6]
connect_debug_port u_ila_2_0/probe6 [get_nets [list {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[0]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[1]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[2]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[3]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[4]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[5]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[6]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[7]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[8]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[9]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[10]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[11]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[12]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[13]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[14]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[15]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[16]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[17]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[18]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[19]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[20]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[21]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[22]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[23]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[24]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[25]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[26]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[27]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[28]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[29]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[30]} {i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tdata[31]}]]
create_debug_port u_ila_2_0 probe
set_property port_width 1 [get_debug_ports u_ila_2_0/probe7]
connect_debug_port u_ila_2_0/probe7 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tlast]]
create_debug_port u_ila_2_0 probe
set_property port_width 1 [get_debug_ports u_ila_2_0/probe8]
connect_debug_port u_ila_2_0/probe8 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tready]]
create_debug_port u_ila_2_0 probe
set_property port_width 1 [get_debug_ports u_ila_2_0/probe9]
connect_debug_port u_ila_2_0/probe9 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxd_tvalid]]
create_debug_port u_ila_2_0 probe
set_property port_width 1 [get_debug_ports u_ila_2_0/probe10]
connect_debug_port u_ila_2_0/probe10 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tlast]]
create_debug_port u_ila_2_0 probe
set_property port_width 1 [get_debug_ports u_ila_2_0/probe11]
connect_debug_port u_ila_2_0/probe11 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tready]]
create_debug_port u_ila_2_0 probe
set_property port_width 1 [get_debug_ports u_ila_2_0/probe12]
connect_debug_port u_ila_2_0/probe12 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/m_axis_rxs_tvalid]]
create_debug_port u_ila_2_0 probe
set_property port_width 1 [get_debug_ports u_ila_2_0/probe13]
connect_debug_port u_ila_2_0/probe13 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_dma_0/U0/mm2s_cntrl_reset_out_n]]
create_debug_port u_ila_2_0 probe
set_property port_width 1 [get_debug_ports u_ila_2_0/probe14]
connect_debug_port u_ila_2_0/probe14 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_dma_0/U0/s2mm_sts_reset_out_n]]
create_debug_port u_ila_2_0 probe
set_property port_width 1 [get_debug_ports u_ila_2_0/probe15]
connect_debug_port u_ila_2_0/probe15 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tlast]]
create_debug_port u_ila_2_0 probe
set_property port_width 1 [get_debug_ports u_ila_2_0/probe16]
connect_debug_port u_ila_2_0/probe16 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tready]]
create_debug_port u_ila_2_0 probe
set_property port_width 1 [get_debug_ports u_ila_2_0/probe17]
connect_debug_port u_ila_2_0/probe17 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txc_tvalid]]
create_debug_port u_ila_2_0 probe
set_property port_width 1 [get_debug_ports u_ila_2_0/probe18]
connect_debug_port u_ila_2_0/probe18 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tlast]]
create_debug_port u_ila_2_0 probe
set_property port_width 1 [get_debug_ports u_ila_2_0/probe19]
connect_debug_port u_ila_2_0/probe19 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tready]]
create_debug_port u_ila_2_0 probe
set_property port_width 1 [get_debug_ports u_ila_2_0/probe20]
connect_debug_port u_ila_2_0/probe20 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/s_axis_txd_tvalid]]
create_debug_port u_ila_3 probe
set_property port_width 1 [get_debug_ports u_ila_3/probe1]
connect_debug_port u_ila_3/probe1 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/tx_axis_mac_tlast]]
create_debug_port u_ila_3 probe
set_property port_width 1 [get_debug_ports u_ila_3/probe2]
connect_debug_port u_ila_3/probe2 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/tx_axis_mac_tready]]
create_debug_port u_ila_3 probe
set_property port_width 1 [get_debug_ports u_ila_3/probe3]
connect_debug_port u_ila_3/probe3 [get_nets [list i_onets_bd_wrapper/onets_bd_i/axi_ethernet_0/eth_buf/U0/tx_axis_mac_tvalid]]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
