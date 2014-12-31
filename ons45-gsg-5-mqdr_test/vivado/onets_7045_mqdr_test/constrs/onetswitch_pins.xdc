############################################################
## LED + PMOD + BUTTON + SWITCH
############################################################
set_property PACKAGE_PIN AB24 [get_ports {pl_led[0]}]
set_property PACKAGE_PIN AA24 [get_ports {pl_led[1]}]
set_property PACKAGE_PIN AF24 [get_ports {pl_pmod[0]}]
set_property PACKAGE_PIN AD24 [get_ports {pl_pmod[1]}]
set_property PACKAGE_PIN A13 [get_ports {pl_btn[0]}]
set_property PACKAGE_PIN A12 [get_ports {pl_btn[1]}]

set_property IOSTANDARD LVCMOS33 [get_ports {pl_led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pl_led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pl_pmod[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pl_pmod[1]}]
set_property IOSTANDARD LVCMOS15 [get_ports {pl_btn[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {pl_btn[1]}]

