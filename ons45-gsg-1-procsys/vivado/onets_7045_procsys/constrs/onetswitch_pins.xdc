############################################################
## LED + PMOD + BUTTON + SWITCH
############################################################
set_property PACKAGE_PIN AB24 [get_ports {pl_led[0]}]
set_property PACKAGE_PIN AA24 [get_ports {pl_led[1]}]
set_property PACKAGE_PIN AF24 [get_ports {pl_pmod[0]}]
set_property PACKAGE_PIN AD24 [get_ports {pl_pmod[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pl_led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pl_led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pl_pmod[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pl_pmod[1]}]

set_property PACKAGE_PIN AD21 [get_ports PL_SGMII_REFCLK_125M_N]
set_property IOSTANDARD TMDS_33 [get_ports PL_SGMII_REFCLK_125M_P]
set_property IOSTANDARD TMDS_33 [get_ports PL_SGMII_REFCLK_125M_N]

