## ONetSwitch 7045 v2 settings
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

############################################################
## GTX Bank 112
############################################################
set_property PACKAGE_PIN R2  [get_ports gtx_pcie_txp]
set_property PACKAGE_PIN R6  [get_ports gtx_pcie_clk_100m_p]

############################################################
## PCIe misc
############################################################
set_property PACKAGE_PIN AF19 [get_ports pcie_wake_b]
set_property PACKAGE_PIN AF22 [get_ports pcie_perst_b]
set_property PACKAGE_PIN AF20 [get_ports pcie_clkreq_b]
set_property PACKAGE_PIN AF18 [get_ports pcie_w_disable_b]
set_property IOSTANDARD LVCMOS33 [get_ports pcie_wake_b]
set_property IOSTANDARD LVCMOS33 [get_ports pcie_perst_b]
set_property IOSTANDARD LVCMOS33 [get_ports pcie_clkreq_b]
set_property IOSTANDARD LVCMOS33 [get_ports pcie_w_disable_b]

# pl_button_0 SW5
set_property PACKAGE_PIN A13 [get_ports ext_btn_rst]
set_property IOSTANDARD LVCMOS15 [get_ports ext_btn_rst]


### ## ONetSwitch 7045 v1 settings
### ############################################################
### ## LED + PMOD + BUTTON + SWITCH
### ############################################################
### set_property PACKAGE_PIN AD25 [get_ports {pl_led[0]}]
### set_property PACKAGE_PIN AD26 [get_ports {pl_led[1]}]
### set_property PACKAGE_PIN AF20 [get_ports {pl_pmod[0]}]
### set_property PACKAGE_PIN AE20 [get_ports {pl_pmod[1]}]
### set_property IOSTANDARD LVCMOS33 [get_ports {pl_led[0]}]
### set_property IOSTANDARD LVCMOS33 [get_ports {pl_led[1]}]
### set_property IOSTANDARD LVCMOS33 [get_ports {pl_pmod[0]}]
### set_property IOSTANDARD LVCMOS33 [get_ports {pl_pmod[1]}]
###
### ############################################################
### ## GTX Bank 112
### ############################################################
### set_property PACKAGE_PIN AC2  [get_ports gtx_pcie_txp]
### set_property PACKAGE_PIN W6   [get_ports gtx_pcie_clk_100m_p]
###
### ############################################################
### ## PCIe misc
### ############################################################
### set_property PACKAGE_PIN AC24 [get_ports pcie_wake_b]
### set_property PACKAGE_PIN AD20 [get_ports pcie_perst_b]
### set_property PACKAGE_PIN AC22 [get_ports pcie_clkreq_b]
### set_property PACKAGE_PIN AF19 [get_ports pcie_w_disable_b]
### set_property IOSTANDARD LVCMOS33 [get_ports pcie_wake_b]
### set_property IOSTANDARD LVCMOS33 [get_ports pcie_perst_b]
### set_property IOSTANDARD LVCMOS33 [get_ports pcie_clkreq_b]
### set_property IOSTANDARD LVCMOS33 [get_ports pcie_w_disable_b]
###
### # pl_button_0 SW5
### set_property PACKAGE_PIN A13 [get_ports ext_btn_rst]
### set_property IOSTANDARD LVCMOS15 [get_ports ext_btn_rst]