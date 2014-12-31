
################################################################
# This is a generated script based on design: onets_bd
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2013.4
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   puts "ERROR: This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source onets_bd_script.tcl

# If you do not already have a project created,
# you can create a project using the following command:
#    create_project project_1 myproj -part xc7z045ffg676-2


# CHANGE DESIGN NAME HERE
set design_name onets_bd

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   puts "ERROR: Please open or create a project!"
   return 1
}


# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
if { ${design_name} ne "" && ${cur_design} eq ${design_name} } {
   # Checks if design is empty or not
   set list_cells [get_bd_cells -quiet]

   if { $list_cells ne "" } {
      set errMsg "ERROR: Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
      set nRet 1
   } else {
      puts "INFO: Constructing design in IPI design <$design_name>..."
   }
} else {

   if { [get_files -quiet ${design_name}.bd] eq "" } {
      puts "INFO: Currently there is no design <$design_name> in project, so creating one..."

      create_bd_design $design_name

      puts "INFO: Making design <$design_name> as current_bd_design."
      current_bd_design $design_name

   } else {
      set errMsg "ERROR: Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
      set nRet 3
   }

}

puts "INFO: Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   puts $errMsg
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     puts "ERROR: Unable to find parent cell <$parentCell>!"
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]
  set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]
  set mdio_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mdio_io:1.0 mdio_0 ]
  set mdio_1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mdio_io:1.0 mdio_1 ]
  set mdio_2 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mdio_io:1.0 mdio_2 ]
  set mdio_3 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mdio_io:1.0 mdio_3 ]
  set rgmii_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rgmii_rtl:1.0 rgmii_0 ]
  set rgmii_1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rgmii_rtl:1.0 rgmii_1 ]
  set rgmii_2 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rgmii_rtl:1.0 rgmii_2 ]
  set rgmii_3 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rgmii_rtl:1.0 rgmii_3 ]

  # Create ports
  set bd_fclk0_125m [ create_bd_port -dir O -type clk bd_fclk0_125m ]
  set bd_fclk1_75m [ create_bd_port -dir O -type clk bd_fclk1_75m ]
  set bd_fclk2_200m [ create_bd_port -dir O -type clk bd_fclk2_200m ]
  set phy_rst_n_0 [ create_bd_port -dir O -type rst phy_rst_n_0 ]
  set phy_rst_n_1 [ create_bd_port -dir O -type rst phy_rst_n_1 ]
  set phy_rst_n_2 [ create_bd_port -dir O -type rst phy_rst_n_2 ]
  set phy_rst_n_3 [ create_bd_port -dir O -type rst phy_rst_n_3 ]

  # Create instance: axi_dma_0, and set properties
  set axi_dma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0 ]
  set_property -dict [ list CONFIG.c_include_mm2s_dre {1} CONFIG.c_include_s2mm_dre {1} CONFIG.c_sg_use_stsapp_length {1}  ] $axi_dma_0

  # Create instance: axi_dma_1, and set properties
  set axi_dma_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_1 ]
  set_property -dict [ list CONFIG.c_include_mm2s_dre {1} CONFIG.c_include_s2mm_dre {1} CONFIG.c_sg_use_stsapp_length {1}  ] $axi_dma_1

  # Create instance: axi_dma_2, and set properties
  set axi_dma_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_2 ]
  set_property -dict [ list CONFIG.c_include_mm2s_dre {1} CONFIG.c_include_s2mm_dre {1} CONFIG.c_sg_use_stsapp_length {1}  ] $axi_dma_2

  # Create instance: axi_dma_3, and set properties
  set axi_dma_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_3 ]
  set_property -dict [ list CONFIG.c_include_mm2s_dre {1} CONFIG.c_include_s2mm_dre {1} CONFIG.c_sg_use_stsapp_length {1}  ] $axi_dma_3

  # Create instance: axi_ethernet_0, and set properties
  set axi_ethernet_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet:6.0 axi_ethernet_0 ]
  set_property -dict [ list CONFIG.PHY_TYPE {RGMII} CONFIG.Statistics_Counters {true} CONFIG.Statistics_Reset {true} CONFIG.Statistics_Width {32bit}  ] $axi_ethernet_0

  # Create instance: axi_ethernet_1, and set properties
  set axi_ethernet_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet:6.0 axi_ethernet_1 ]
  set_property -dict [ list CONFIG.PHY_TYPE {RGMII} CONFIG.Statistics_Counters {true} CONFIG.Statistics_Reset {true} CONFIG.Statistics_Width {32bit} CONFIG.SupportLevel {0}  ] $axi_ethernet_1

  # Create instance: axi_ethernet_2, and set properties
  set axi_ethernet_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet:6.0 axi_ethernet_2 ]
  set_property -dict [ list CONFIG.PHY_TYPE {RGMII} CONFIG.Statistics_Counters {true} CONFIG.Statistics_Reset {true} CONFIG.Statistics_Width {32bit} CONFIG.SupportLevel {0}  ] $axi_ethernet_2

  # Create instance: axi_ethernet_3, and set properties
  set axi_ethernet_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet:6.0 axi_ethernet_3 ]
  set_property -dict [ list CONFIG.PHY_TYPE {RGMII} CONFIG.Statistics_Counters {true} CONFIG.Statistics_Reset {true} CONFIG.Statistics_Width {32bit} CONFIG.SupportLevel {0}  ] $axi_ethernet_3

  # Create instance: axi_ic_gp, and set properties
  set axi_ic_gp [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_ic_gp ]
  set_property -dict [ list CONFIG.NUM_MI {9}  ] $axi_ic_gp

  # Create instance: axi_ic_hp, and set properties
  set axi_ic_hp [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_ic_hp ]
  set_property -dict [ list CONFIG.NUM_MI {1} CONFIG.NUM_SI {12}  ] $axi_ic_hp

  # Create instance: concat_dcmlock, and set properties
  set concat_dcmlock [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:1.0 concat_dcmlock ]
  set_property -dict [ list CONFIG.NUM_PORTS {4}  ] $concat_dcmlock

  # Create instance: concat_int, and set properties
  set concat_int [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:1.0 concat_int ]
  set_property -dict [ list CONFIG.NUM_PORTS {12}  ] $concat_int

  # Create instance: const_gnd, and set properties
  set const_gnd [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.0 const_gnd ]
  set_property -dict [ list CONFIG.CONST_VAL {0}  ] $const_gnd

  # Create instance: const_vcc, and set properties
  set const_vcc [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.0 const_vcc ]

  # Create instance: packet_pipeline_0, and set properties
  set packet_pipeline_0 [ create_bd_cell -type ip -vlnv meshsr:user:packet_pipeline_v1_0:1.0 packet_pipeline_0 ]

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]
  set_property -dict [ list CONFIG.C_AUX_RESET_HIGH {0}  ] $proc_sys_reset_0

  # Create instance: processing_system7_0, and set properties
  set processing_system7_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.3 processing_system7_0 ]
  set_property -dict [ list CONFIG.PCW_ENET0_ENET0_IO {MIO 16 .. 27} CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {1} CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} CONFIG.PCW_ENET0_PERIPHERAL_FREQMHZ {100 Mbps} CONFIG.PCW_ENET0_RESET_ENABLE {1} CONFIG.PCW_ENET0_RESET_IO {MIO 7} CONFIG.PCW_EN_CLK1_PORT {1} CONFIG.PCW_EN_CLK2_PORT {1} CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {125} CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {75} CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {200} CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {1} CONFIG.PCW_I2C0_PERIPHERAL_ENABLE {0} CONFIG.PCW_IRQ_F2P_INTR {1} CONFIG.PCW_MIO_0_PULLUP {disabled} CONFIG.PCW_MIO_10_PULLUP {disabled} CONFIG.PCW_MIO_11_PULLUP {disabled} CONFIG.PCW_MIO_12_PULLUP {disabled} CONFIG.PCW_MIO_13_PULLUP {disabled} CONFIG.PCW_MIO_14_PULLUP {disabled} CONFIG.PCW_MIO_15_PULLUP {disabled} CONFIG.PCW_MIO_16_IOTYPE {HSTL 1.8V} CONFIG.PCW_MIO_16_PULLUP {disabled} CONFIG.PCW_MIO_17_IOTYPE {HSTL 1.8V} CONFIG.PCW_MIO_17_PULLUP {disabled} CONFIG.PCW_MIO_18_IOTYPE {HSTL 1.8V} CONFIG.PCW_MIO_18_PULLUP {disabled} CONFIG.PCW_MIO_19_IOTYPE {HSTL 1.8V} CONFIG.PCW_MIO_19_PULLUP {disabled} CONFIG.PCW_MIO_1_PULLUP {disabled} CONFIG.PCW_MIO_20_IOTYPE {HSTL 1.8V} CONFIG.PCW_MIO_20_PULLUP {disabled} CONFIG.PCW_MIO_21_IOTYPE {HSTL 1.8V} CONFIG.PCW_MIO_21_PULLUP {disabled} CONFIG.PCW_MIO_22_IOTYPE {HSTL 1.8V} CONFIG.PCW_MIO_22_PULLUP {disabled} CONFIG.PCW_MIO_23_IOTYPE {HSTL 1.8V} CONFIG.PCW_MIO_23_PULLUP {disabled} CONFIG.PCW_MIO_24_IOTYPE {HSTL 1.8V} CONFIG.PCW_MIO_24_PULLUP {disabled} CONFIG.PCW_MIO_25_IOTYPE {HSTL 1.8V} CONFIG.PCW_MIO_25_PULLUP {disabled} CONFIG.PCW_MIO_26_IOTYPE {HSTL 1.8V} CONFIG.PCW_MIO_26_PULLUP {disabled} CONFIG.PCW_MIO_27_IOTYPE {HSTL 1.8V} CONFIG.PCW_MIO_27_PULLUP {disabled} CONFIG.PCW_MIO_28_PULLUP {disabled} CONFIG.PCW_MIO_29_PULLUP {disabled} CONFIG.PCW_MIO_30_PULLUP {disabled} CONFIG.PCW_MIO_31_PULLUP {disabled} CONFIG.PCW_MIO_32_PULLUP {disabled} CONFIG.PCW_MIO_33_PULLUP {disabled} CONFIG.PCW_MIO_34_PULLUP {disabled} CONFIG.PCW_MIO_35_PULLUP {disabled} CONFIG.PCW_MIO_36_PULLUP {disabled} CONFIG.PCW_MIO_37_PULLUP {disabled} CONFIG.PCW_MIO_38_PULLUP {disabled} CONFIG.PCW_MIO_39_PULLUP {disabled} CONFIG.PCW_MIO_40_PULLUP {disabled} CONFIG.PCW_MIO_41_PULLUP {disabled} CONFIG.PCW_MIO_42_PULLUP {disabled} CONFIG.PCW_MIO_43_PULLUP {disabled} CONFIG.PCW_MIO_44_PULLUP {disabled} CONFIG.PCW_MIO_45_PULLUP {disabled} CONFIG.PCW_MIO_46_DIRECTION {inout} CONFIG.PCW_MIO_46_PULLUP {disabled} CONFIG.PCW_MIO_47_DIRECTION {inout} CONFIG.PCW_MIO_47_PULLUP {disabled} CONFIG.PCW_MIO_48_DIRECTION {inout} CONFIG.PCW_MIO_48_PULLUP {disabled} CONFIG.PCW_MIO_49_DIRECTION {inout} CONFIG.PCW_MIO_49_PULLUP {disabled} CONFIG.PCW_MIO_50_PULLUP {disabled} CONFIG.PCW_MIO_51_PULLUP {disabled} CONFIG.PCW_MIO_52_PULLUP {disabled} CONFIG.PCW_MIO_53_PULLUP {disabled} CONFIG.PCW_MIO_9_PULLUP {disabled} CONFIG.PCW_PRESET_BANK0_VOLTAGE {LVCMOS 1.8V} CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} CONFIG.PCW_QSPI_GRP_FBCLK_ENABLE {1} CONFIG.PCW_QSPI_GRP_IO1_ENABLE {1} CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {1} CONFIG.PCW_SD0_GRP_CD_ENABLE {1} CONFIG.PCW_SD0_GRP_CD_IO {MIO 14} CONFIG.PCW_SD0_GRP_WP_ENABLE {1} CONFIG.PCW_SD0_GRP_WP_IO {MIO 15} CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ {50} CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {1} CONFIG.PCW_TTC1_PERIPHERAL_ENABLE {1} CONFIG.PCW_UART0_PERIPHERAL_ENABLE {1} CONFIG.PCW_UART0_UART0_IO {MIO 50 .. 51} CONFIG.PCW_UART1_PERIPHERAL_ENABLE {0} CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_0 {0.121} CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_1 {0.234} CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41J256M8 HX-15E} CONFIG.PCW_UIPARAM_DDR_TRAIN_DATA_EYE {1} CONFIG.PCW_UIPARAM_DDR_TRAIN_READ_GATE {1} CONFIG.PCW_UIPARAM_DDR_TRAIN_WRITE_LEVEL {1} CONFIG.PCW_UIPARAM_DDR_USE_INTERNAL_VREF {1} CONFIG.PCW_USB0_PERIPHERAL_ENABLE {1} CONFIG.PCW_USB0_RESET_ENABLE {0} CONFIG.PCW_USE_FABRIC_INTERRUPT {1} CONFIG.PCW_USE_S_AXI_HP0 {1} CONFIG.PCW_WDT_PERIPHERAL_ENABLE {1}  ] $processing_system7_0

  # Create instance: r_and_dcmlock, and set properties
  set r_and_dcmlock [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_reduced_logic:1.0 r_and_dcmlock ]
  set_property -dict [ list CONFIG.C_SIZE {4}  ] $r_and_dcmlock

  # Create interface connections
  connect_bd_intf_net -intf_net axi_dma_0_M_AXIS_CNTRL [get_bd_intf_pins axi_dma_0/M_AXIS_CNTRL] [get_bd_intf_pins packet_pipeline_0/s_axis_mm2s_ctrl_0]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXIS_MM2S [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S] [get_bd_intf_pins packet_pipeline_0/s_axis_mm2s_0]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_MM2S [get_bd_intf_pins axi_dma_0/M_AXI_MM2S] [get_bd_intf_pins axi_ic_hp/S01_AXI]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_S2MM [get_bd_intf_pins axi_dma_0/M_AXI_S2MM] [get_bd_intf_pins axi_ic_hp/S02_AXI]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_SG [get_bd_intf_pins axi_dma_0/M_AXI_SG] [get_bd_intf_pins axi_ic_hp/S00_AXI]
  connect_bd_intf_net -intf_net axi_dma_1_M_AXIS_CNTRL [get_bd_intf_pins axi_dma_1/M_AXIS_CNTRL] [get_bd_intf_pins packet_pipeline_0/s_axis_mm2s_ctrl_1]
  connect_bd_intf_net -intf_net axi_dma_1_M_AXIS_MM2S [get_bd_intf_pins axi_dma_1/M_AXIS_MM2S] [get_bd_intf_pins packet_pipeline_0/s_axis_mm2s_1]
  connect_bd_intf_net -intf_net axi_dma_1_M_AXI_MM2S [get_bd_intf_pins axi_dma_1/M_AXI_MM2S] [get_bd_intf_pins axi_ic_hp/S04_AXI]
  connect_bd_intf_net -intf_net axi_dma_1_M_AXI_S2MM [get_bd_intf_pins axi_dma_1/M_AXI_S2MM] [get_bd_intf_pins axi_ic_hp/S05_AXI]
  connect_bd_intf_net -intf_net axi_dma_1_M_AXI_SG [get_bd_intf_pins axi_dma_1/M_AXI_SG] [get_bd_intf_pins axi_ic_hp/S03_AXI]
  connect_bd_intf_net -intf_net axi_dma_2_M_AXIS_CNTRL [get_bd_intf_pins axi_dma_2/M_AXIS_CNTRL] [get_bd_intf_pins packet_pipeline_0/s_axis_mm2s_ctrl_2]
  connect_bd_intf_net -intf_net axi_dma_2_M_AXIS_MM2S [get_bd_intf_pins axi_dma_2/M_AXIS_MM2S] [get_bd_intf_pins packet_pipeline_0/s_axis_mm2s_2]
  connect_bd_intf_net -intf_net axi_dma_2_M_AXI_MM2S [get_bd_intf_pins axi_dma_2/M_AXI_MM2S] [get_bd_intf_pins axi_ic_hp/S07_AXI]
  connect_bd_intf_net -intf_net axi_dma_2_M_AXI_S2MM [get_bd_intf_pins axi_dma_2/M_AXI_S2MM] [get_bd_intf_pins axi_ic_hp/S08_AXI]
  connect_bd_intf_net -intf_net axi_dma_2_M_AXI_SG [get_bd_intf_pins axi_dma_2/M_AXI_SG] [get_bd_intf_pins axi_ic_hp/S06_AXI]
  connect_bd_intf_net -intf_net axi_dma_3_M_AXIS_CNTRL [get_bd_intf_pins axi_dma_3/M_AXIS_CNTRL] [get_bd_intf_pins packet_pipeline_0/s_axis_mm2s_ctrl_3]
  connect_bd_intf_net -intf_net axi_dma_3_M_AXIS_MM2S [get_bd_intf_pins axi_dma_3/M_AXIS_MM2S] [get_bd_intf_pins packet_pipeline_0/s_axis_mm2s_3]
  connect_bd_intf_net -intf_net axi_dma_3_M_AXI_MM2S [get_bd_intf_pins axi_dma_3/M_AXI_MM2S] [get_bd_intf_pins axi_ic_hp/S10_AXI]
  connect_bd_intf_net -intf_net axi_dma_3_M_AXI_S2MM [get_bd_intf_pins axi_dma_3/M_AXI_S2MM] [get_bd_intf_pins axi_ic_hp/S11_AXI]
  connect_bd_intf_net -intf_net axi_dma_3_M_AXI_SG [get_bd_intf_pins axi_dma_3/M_AXI_SG] [get_bd_intf_pins axi_ic_hp/S09_AXI]
  connect_bd_intf_net -intf_net axi_ethernet_0_m_axis_rxd [get_bd_intf_pins axi_ethernet_0/m_axis_rxd] [get_bd_intf_pins packet_pipeline_0/s_axis_rxd_0]
  connect_bd_intf_net -intf_net axi_ethernet_0_m_axis_rxs [get_bd_intf_pins axi_ethernet_0/m_axis_rxs] [get_bd_intf_pins packet_pipeline_0/s_axis_rxs_0]
  connect_bd_intf_net -intf_net axi_ethernet_0_mdio [get_bd_intf_ports mdio_0] [get_bd_intf_pins axi_ethernet_0/mdio]
  connect_bd_intf_net -intf_net axi_ethernet_0_rgmii [get_bd_intf_ports rgmii_0] [get_bd_intf_pins axi_ethernet_0/rgmii]
  connect_bd_intf_net -intf_net axi_ethernet_1_m_axis_rxd [get_bd_intf_pins axi_ethernet_1/m_axis_rxd] [get_bd_intf_pins packet_pipeline_0/s_axis_rxd_1]
  connect_bd_intf_net -intf_net axi_ethernet_1_m_axis_rxs [get_bd_intf_pins axi_ethernet_1/m_axis_rxs] [get_bd_intf_pins packet_pipeline_0/s_axis_rxs_1]
  connect_bd_intf_net -intf_net axi_ethernet_1_mdio [get_bd_intf_ports mdio_1] [get_bd_intf_pins axi_ethernet_1/mdio]
  connect_bd_intf_net -intf_net axi_ethernet_1_rgmii [get_bd_intf_ports rgmii_1] [get_bd_intf_pins axi_ethernet_1/rgmii]
  connect_bd_intf_net -intf_net axi_ethernet_2_m_axis_rxd [get_bd_intf_pins axi_ethernet_2/m_axis_rxd] [get_bd_intf_pins packet_pipeline_0/s_axis_rxd_2]
  connect_bd_intf_net -intf_net axi_ethernet_2_m_axis_rxs [get_bd_intf_pins axi_ethernet_2/m_axis_rxs] [get_bd_intf_pins packet_pipeline_0/s_axis_rxs_2]
  connect_bd_intf_net -intf_net axi_ethernet_2_mdio [get_bd_intf_ports mdio_2] [get_bd_intf_pins axi_ethernet_2/mdio]
  connect_bd_intf_net -intf_net axi_ethernet_2_rgmii [get_bd_intf_ports rgmii_2] [get_bd_intf_pins axi_ethernet_2/rgmii]
  connect_bd_intf_net -intf_net axi_ethernet_3_m_axis_rxd [get_bd_intf_pins axi_ethernet_3/m_axis_rxd] [get_bd_intf_pins packet_pipeline_0/s_axis_rxd_3]
  connect_bd_intf_net -intf_net axi_ethernet_3_m_axis_rxs [get_bd_intf_pins axi_ethernet_3/m_axis_rxs] [get_bd_intf_pins packet_pipeline_0/s_axis_rxs_3]
  connect_bd_intf_net -intf_net axi_ethernet_3_mdio [get_bd_intf_ports mdio_3] [get_bd_intf_pins axi_ethernet_3/mdio]
  connect_bd_intf_net -intf_net axi_ethernet_3_rgmii [get_bd_intf_ports rgmii_3] [get_bd_intf_pins axi_ethernet_3/rgmii]
  connect_bd_intf_net -intf_net axi_ic_gp_M00_AXI [get_bd_intf_pins axi_ethernet_0/s_axi] [get_bd_intf_pins axi_ic_gp/M00_AXI]
  connect_bd_intf_net -intf_net axi_ic_gp_M01_AXI [get_bd_intf_pins axi_ethernet_1/s_axi] [get_bd_intf_pins axi_ic_gp/M01_AXI]
  connect_bd_intf_net -intf_net axi_ic_gp_M02_AXI [get_bd_intf_pins axi_ethernet_2/s_axi] [get_bd_intf_pins axi_ic_gp/M02_AXI]
  connect_bd_intf_net -intf_net axi_ic_gp_M03_AXI [get_bd_intf_pins axi_ethernet_3/s_axi] [get_bd_intf_pins axi_ic_gp/M03_AXI]
  connect_bd_intf_net -intf_net axi_ic_gp_M04_AXI [get_bd_intf_pins axi_dma_0/S_AXI_LITE] [get_bd_intf_pins axi_ic_gp/M04_AXI]
  connect_bd_intf_net -intf_net axi_ic_gp_M05_AXI [get_bd_intf_pins axi_dma_1/S_AXI_LITE] [get_bd_intf_pins axi_ic_gp/M05_AXI]
  connect_bd_intf_net -intf_net axi_ic_gp_M06_AXI [get_bd_intf_pins axi_dma_2/S_AXI_LITE] [get_bd_intf_pins axi_ic_gp/M06_AXI]
  connect_bd_intf_net -intf_net axi_ic_gp_M07_AXI [get_bd_intf_pins axi_dma_3/S_AXI_LITE] [get_bd_intf_pins axi_ic_gp/M07_AXI]
  connect_bd_intf_net -intf_net axi_ic_gp_M08_AXI [get_bd_intf_pins axi_ic_gp/M08_AXI] [get_bd_intf_pins packet_pipeline_0/s_axi_lite]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_ic_hp/M00_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
  connect_bd_intf_net -intf_net packet_pipeline_0_m_axis_s2mm_0 [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM] [get_bd_intf_pins packet_pipeline_0/m_axis_s2mm_0]
  connect_bd_intf_net -intf_net packet_pipeline_0_m_axis_s2mm_1 [get_bd_intf_pins axi_dma_1/S_AXIS_S2MM] [get_bd_intf_pins packet_pipeline_0/m_axis_s2mm_1]
  connect_bd_intf_net -intf_net packet_pipeline_0_m_axis_s2mm_2 [get_bd_intf_pins axi_dma_2/S_AXIS_S2MM] [get_bd_intf_pins packet_pipeline_0/m_axis_s2mm_2]
  connect_bd_intf_net -intf_net packet_pipeline_0_m_axis_s2mm_3 [get_bd_intf_pins axi_dma_3/S_AXIS_S2MM] [get_bd_intf_pins packet_pipeline_0/m_axis_s2mm_3]
  connect_bd_intf_net -intf_net packet_pipeline_0_m_axis_s2mm_sts_0 [get_bd_intf_pins axi_dma_0/S_AXIS_STS] [get_bd_intf_pins packet_pipeline_0/m_axis_s2mm_sts_0]
  connect_bd_intf_net -intf_net packet_pipeline_0_m_axis_s2mm_sts_1 [get_bd_intf_pins axi_dma_1/S_AXIS_STS] [get_bd_intf_pins packet_pipeline_0/m_axis_s2mm_sts_1]
  connect_bd_intf_net -intf_net packet_pipeline_0_m_axis_s2mm_sts_2 [get_bd_intf_pins axi_dma_2/S_AXIS_STS] [get_bd_intf_pins packet_pipeline_0/m_axis_s2mm_sts_2]
  connect_bd_intf_net -intf_net packet_pipeline_0_m_axis_s2mm_sts_3 [get_bd_intf_pins axi_dma_3/S_AXIS_STS] [get_bd_intf_pins packet_pipeline_0/m_axis_s2mm_sts_3]
  connect_bd_intf_net -intf_net packet_pipeline_0_m_axis_txc_0 [get_bd_intf_pins axi_ethernet_0/s_axis_txc] [get_bd_intf_pins packet_pipeline_0/m_axis_txc_0]
  connect_bd_intf_net -intf_net packet_pipeline_0_m_axis_txc_1 [get_bd_intf_pins axi_ethernet_1/s_axis_txc] [get_bd_intf_pins packet_pipeline_0/m_axis_txc_1]
  connect_bd_intf_net -intf_net packet_pipeline_0_m_axis_txc_2 [get_bd_intf_pins axi_ethernet_2/s_axis_txc] [get_bd_intf_pins packet_pipeline_0/m_axis_txc_2]
  connect_bd_intf_net -intf_net packet_pipeline_0_m_axis_txc_3 [get_bd_intf_pins axi_ethernet_3/s_axis_txc] [get_bd_intf_pins packet_pipeline_0/m_axis_txc_3]
  connect_bd_intf_net -intf_net packet_pipeline_0_m_axis_txd_0 [get_bd_intf_pins axi_ethernet_0/s_axis_txd] [get_bd_intf_pins packet_pipeline_0/m_axis_txd_0]
  connect_bd_intf_net -intf_net packet_pipeline_0_m_axis_txd_1 [get_bd_intf_pins axi_ethernet_1/s_axis_txd] [get_bd_intf_pins packet_pipeline_0/m_axis_txd_1]
  connect_bd_intf_net -intf_net packet_pipeline_0_m_axis_txd_2 [get_bd_intf_pins axi_ethernet_2/s_axis_txd] [get_bd_intf_pins packet_pipeline_0/m_axis_txd_2]
  connect_bd_intf_net -intf_net packet_pipeline_0_m_axis_txd_3 [get_bd_intf_pins axi_ethernet_3/s_axis_txd] [get_bd_intf_pins packet_pipeline_0/m_axis_txd_3]
  connect_bd_intf_net -intf_net processing_system7_0_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins processing_system7_0/DDR]
  connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins processing_system7_0/FIXED_IO]
  connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP0 [get_bd_intf_pins axi_ic_gp/S00_AXI] [get_bd_intf_pins processing_system7_0/M_AXI_GP0]

  # Create port connections
  connect_bd_net -net axi_dma_0_mm2s_cntrl_reset_out_n [get_bd_pins axi_dma_0/mm2s_cntrl_reset_out_n] [get_bd_pins axi_ethernet_0/axi_txc_arstn]
  set_property -dict [ list HDL_ATTRIBUTE.MARK_DEBUG {false}  ] [get_bd_nets axi_dma_0_mm2s_cntrl_reset_out_n]
  connect_bd_net -net axi_dma_0_mm2s_introut [get_bd_pins axi_dma_0/mm2s_introut] [get_bd_pins concat_int/In4]
  set_property -dict [ list HDL_ATTRIBUTE.MARK_DEBUG {false}  ] [get_bd_nets axi_dma_0_mm2s_introut]
  connect_bd_net -net axi_dma_0_mm2s_prmry_reset_out_n [get_bd_pins axi_dma_0/mm2s_prmry_reset_out_n] [get_bd_pins axi_ethernet_0/axi_txd_arstn]
  set_property -dict [ list HDL_ATTRIBUTE.MARK_DEBUG {false}  ] [get_bd_nets axi_dma_0_mm2s_prmry_reset_out_n]
  connect_bd_net -net axi_dma_0_s2mm_introut [get_bd_pins axi_dma_0/s2mm_introut] [get_bd_pins concat_int/In5]
  set_property -dict [ list HDL_ATTRIBUTE.MARK_DEBUG {false}  ] [get_bd_nets axi_dma_0_s2mm_introut]
  connect_bd_net -net axi_dma_0_s2mm_prmry_reset_out_n [get_bd_pins axi_dma_0/s2mm_prmry_reset_out_n] [get_bd_pins axi_ethernet_0/axi_rxd_arstn]
  set_property -dict [ list HDL_ATTRIBUTE.MARK_DEBUG {false}  ] [get_bd_nets axi_dma_0_s2mm_prmry_reset_out_n]
  connect_bd_net -net axi_dma_0_s2mm_sts_reset_out_n [get_bd_pins axi_dma_0/s2mm_sts_reset_out_n] [get_bd_pins axi_ethernet_0/axi_rxs_arstn]
  set_property -dict [ list HDL_ATTRIBUTE.MARK_DEBUG {false}  ] [get_bd_nets axi_dma_0_s2mm_sts_reset_out_n]
  connect_bd_net -net axi_dma_1_mm2s_cntrl_reset_out_n [get_bd_pins axi_dma_1/mm2s_cntrl_reset_out_n] [get_bd_pins axi_ethernet_1/axi_txc_arstn]
  connect_bd_net -net axi_dma_1_mm2s_introut [get_bd_pins axi_dma_1/mm2s_introut] [get_bd_pins concat_int/In6]
  connect_bd_net -net axi_dma_1_mm2s_prmry_reset_out_n [get_bd_pins axi_dma_1/mm2s_prmry_reset_out_n] [get_bd_pins axi_ethernet_1/axi_txd_arstn]
  connect_bd_net -net axi_dma_1_s2mm_introut [get_bd_pins axi_dma_1/s2mm_introut] [get_bd_pins concat_int/In7]
  connect_bd_net -net axi_dma_1_s2mm_prmry_reset_out_n [get_bd_pins axi_dma_1/s2mm_prmry_reset_out_n] [get_bd_pins axi_ethernet_1/axi_rxd_arstn]
  connect_bd_net -net axi_dma_1_s2mm_sts_reset_out_n [get_bd_pins axi_dma_1/s2mm_sts_reset_out_n] [get_bd_pins axi_ethernet_1/axi_rxs_arstn]
  connect_bd_net -net axi_dma_2_mm2s_cntrl_reset_out_n [get_bd_pins axi_dma_2/mm2s_cntrl_reset_out_n] [get_bd_pins axi_ethernet_2/axi_txc_arstn]
  connect_bd_net -net axi_dma_2_mm2s_introut [get_bd_pins axi_dma_2/mm2s_introut] [get_bd_pins concat_int/In8]
  connect_bd_net -net axi_dma_2_mm2s_prmry_reset_out_n [get_bd_pins axi_dma_2/mm2s_prmry_reset_out_n] [get_bd_pins axi_ethernet_2/axi_txd_arstn]
  connect_bd_net -net axi_dma_2_s2mm_introut [get_bd_pins axi_dma_2/s2mm_introut] [get_bd_pins concat_int/In9]
  connect_bd_net -net axi_dma_2_s2mm_prmry_reset_out_n [get_bd_pins axi_dma_2/s2mm_prmry_reset_out_n] [get_bd_pins axi_ethernet_2/axi_rxd_arstn]
  connect_bd_net -net axi_dma_2_s2mm_sts_reset_out_n [get_bd_pins axi_dma_2/s2mm_sts_reset_out_n] [get_bd_pins axi_ethernet_2/axi_rxs_arstn]
  connect_bd_net -net axi_dma_3_mm2s_cntrl_reset_out_n [get_bd_pins axi_dma_3/mm2s_cntrl_reset_out_n] [get_bd_pins axi_ethernet_3/axi_txc_arstn]
  connect_bd_net -net axi_dma_3_mm2s_introut [get_bd_pins axi_dma_3/mm2s_introut] [get_bd_pins concat_int/In10]
  connect_bd_net -net axi_dma_3_mm2s_prmry_reset_out_n [get_bd_pins axi_dma_3/mm2s_prmry_reset_out_n] [get_bd_pins axi_ethernet_3/axi_txd_arstn]
  connect_bd_net -net axi_dma_3_s2mm_introut [get_bd_pins axi_dma_3/s2mm_introut] [get_bd_pins concat_int/In11]
  connect_bd_net -net axi_dma_3_s2mm_prmry_reset_out_n [get_bd_pins axi_dma_3/s2mm_prmry_reset_out_n] [get_bd_pins axi_ethernet_3/axi_rxd_arstn]
  connect_bd_net -net axi_dma_3_s2mm_sts_reset_out_n [get_bd_pins axi_dma_3/s2mm_sts_reset_out_n] [get_bd_pins axi_ethernet_3/axi_rxs_arstn]
  connect_bd_net -net axi_ethernet_0_gtx_clk90_out [get_bd_pins axi_ethernet_0/gtx_clk90_out] [get_bd_pins axi_ethernet_1/gtx_clk90] [get_bd_pins axi_ethernet_2/gtx_clk90] [get_bd_pins axi_ethernet_3/gtx_clk90]
  connect_bd_net -net axi_ethernet_0_interrupt [get_bd_pins axi_ethernet_0/interrupt] [get_bd_pins concat_int/In0]
  set_property -dict [ list HDL_ATTRIBUTE.MARK_DEBUG {true}  ] [get_bd_nets axi_ethernet_0_interrupt]
  connect_bd_net -net axi_ethernet_0_phy_rst_n [get_bd_ports phy_rst_n_0] [get_bd_pins axi_ethernet_0/phy_rst_n]
  connect_bd_net -net axi_ethernet_1_interrupt [get_bd_pins axi_ethernet_1/interrupt] [get_bd_pins concat_int/In1]
  connect_bd_net -net axi_ethernet_1_phy_rst_n [get_bd_ports phy_rst_n_1] [get_bd_pins axi_ethernet_1/phy_rst_n]
  connect_bd_net -net axi_ethernet_2_interrupt [get_bd_pins axi_ethernet_2/interrupt] [get_bd_pins concat_int/In2]
  connect_bd_net -net axi_ethernet_2_phy_rst_n [get_bd_ports phy_rst_n_2] [get_bd_pins axi_ethernet_2/phy_rst_n]
  connect_bd_net -net axi_ethernet_3_interrupt [get_bd_pins axi_ethernet_3/interrupt] [get_bd_pins concat_int/In3]
  connect_bd_net -net axi_ethernet_3_phy_rst_n [get_bd_ports phy_rst_n_3] [get_bd_pins axi_ethernet_3/phy_rst_n]
  connect_bd_net -net concat_alllock_dout [get_bd_pins concat_dcmlock/dout] [get_bd_pins r_and_dcmlock/Op1]
  connect_bd_net -net concat_int_dout [get_bd_pins concat_int/dout] [get_bd_pins processing_system7_0/IRQ_F2P]
  connect_bd_net -net const_gnd_const [get_bd_pins const_gnd/const] [get_bd_pins proc_sys_reset_0/mb_debug_sys_rst]
  set_property -dict [ list HDL_ATTRIBUTE.MARK_DEBUG {true}  ] [get_bd_nets const_gnd_const]
  connect_bd_net -net const_vcc_const [get_bd_pins concat_dcmlock/In0] [get_bd_pins concat_dcmlock/In1] [get_bd_pins concat_dcmlock/In2] [get_bd_pins concat_dcmlock/In3] [get_bd_pins const_vcc/const] [get_bd_pins proc_sys_reset_0/ext_reset_in]
  connect_bd_net -net gtx_clk_1 [get_bd_pins axi_ethernet_0/gtx_clk_out] [get_bd_pins axi_ethernet_1/gtx_clk] [get_bd_pins axi_ethernet_2/gtx_clk] [get_bd_pins axi_ethernet_3/gtx_clk]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_dma_0/axi_resetn] [get_bd_pins axi_dma_1/axi_resetn] [get_bd_pins axi_dma_2/axi_resetn] [get_bd_pins axi_dma_3/axi_resetn] [get_bd_pins axi_ethernet_0/s_axi_lite_resetn] [get_bd_pins axi_ethernet_1/s_axi_lite_resetn] [get_bd_pins axi_ethernet_2/s_axi_lite_resetn] [get_bd_pins axi_ethernet_3/s_axi_lite_resetn] [get_bd_pins axi_ic_gp/ARESETN] [get_bd_pins axi_ic_gp/M00_ARESETN] [get_bd_pins axi_ic_gp/M01_ARESETN] [get_bd_pins axi_ic_gp/M02_ARESETN] [get_bd_pins axi_ic_gp/M03_ARESETN] [get_bd_pins axi_ic_gp/M04_ARESETN] [get_bd_pins axi_ic_gp/M05_ARESETN] [get_bd_pins axi_ic_gp/M06_ARESETN] [get_bd_pins axi_ic_gp/M07_ARESETN] [get_bd_pins axi_ic_gp/M08_ARESETN] [get_bd_pins axi_ic_gp/S00_ARESETN] [get_bd_pins axi_ic_hp/ARESETN] [get_bd_pins axi_ic_hp/M00_ARESETN] [get_bd_pins axi_ic_hp/S00_ARESETN] [get_bd_pins axi_ic_hp/S01_ARESETN] [get_bd_pins axi_ic_hp/S02_ARESETN] [get_bd_pins axi_ic_hp/S03_ARESETN] [get_bd_pins axi_ic_hp/S04_ARESETN] [get_bd_pins axi_ic_hp/S05_ARESETN] [get_bd_pins axi_ic_hp/S06_ARESETN] [get_bd_pins axi_ic_hp/S07_ARESETN] [get_bd_pins axi_ic_hp/S08_ARESETN] [get_bd_pins axi_ic_hp/S09_ARESETN] [get_bd_pins axi_ic_hp/S10_ARESETN] [get_bd_pins axi_ic_hp/S11_ARESETN] [get_bd_pins packet_pipeline_0/s_axi_lite_aresetn] [get_bd_pins packet_pipeline_0/s_axis_mm2s_aresetn] [get_bd_pins packet_pipeline_0/s_axis_rxd_aresetn] [get_bd_pins packet_pipeline_0/s_axis_s2mm_aresetn] [get_bd_pins packet_pipeline_0/s_axis_txd_aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
  set_property -dict [ list HDL_ATTRIBUTE.MARK_DEBUG {true}  ] [get_bd_nets proc_sys_reset_0_peripheral_aresetn]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_ports bd_fclk0_125m] [get_bd_pins axi_dma_0/m_axi_mm2s_aclk] [get_bd_pins axi_dma_0/m_axi_s2mm_aclk] [get_bd_pins axi_dma_0/m_axi_sg_aclk] [get_bd_pins axi_dma_1/m_axi_mm2s_aclk] [get_bd_pins axi_dma_1/m_axi_s2mm_aclk] [get_bd_pins axi_dma_1/m_axi_sg_aclk] [get_bd_pins axi_dma_2/m_axi_mm2s_aclk] [get_bd_pins axi_dma_2/m_axi_s2mm_aclk] [get_bd_pins axi_dma_2/m_axi_sg_aclk] [get_bd_pins axi_dma_3/m_axi_mm2s_aclk] [get_bd_pins axi_dma_3/m_axi_s2mm_aclk] [get_bd_pins axi_dma_3/m_axi_sg_aclk] [get_bd_pins axi_ethernet_0/axis_clk] [get_bd_pins axi_ethernet_0/gtx_clk] [get_bd_pins axi_ethernet_1/axis_clk] [get_bd_pins axi_ethernet_2/axis_clk] [get_bd_pins axi_ethernet_3/axis_clk] [get_bd_pins axi_ic_hp/ACLK] [get_bd_pins axi_ic_hp/M00_ACLK] [get_bd_pins axi_ic_hp/S00_ACLK] [get_bd_pins axi_ic_hp/S01_ACLK] [get_bd_pins axi_ic_hp/S02_ACLK] [get_bd_pins axi_ic_hp/S03_ACLK] [get_bd_pins axi_ic_hp/S04_ACLK] [get_bd_pins axi_ic_hp/S05_ACLK] [get_bd_pins axi_ic_hp/S06_ACLK] [get_bd_pins axi_ic_hp/S07_ACLK] [get_bd_pins axi_ic_hp/S08_ACLK] [get_bd_pins axi_ic_hp/S09_ACLK] [get_bd_pins axi_ic_hp/S10_ACLK] [get_bd_pins axi_ic_hp/S11_ACLK] [get_bd_pins packet_pipeline_0/s_axis_mm2s_aclk] [get_bd_pins packet_pipeline_0/s_axis_rxd_aclk] [get_bd_pins packet_pipeline_0/s_axis_s2mm_aclk] [get_bd_pins packet_pipeline_0/s_axis_txd_aclk] [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK]
  connect_bd_net -net processing_system7_0_FCLK_CLK1 [get_bd_ports bd_fclk1_75m] [get_bd_pins axi_dma_0/s_axi_lite_aclk] [get_bd_pins axi_dma_1/s_axi_lite_aclk] [get_bd_pins axi_dma_2/s_axi_lite_aclk] [get_bd_pins axi_dma_3/s_axi_lite_aclk] [get_bd_pins axi_ethernet_0/s_axi_lite_clk] [get_bd_pins axi_ethernet_1/s_axi_lite_clk] [get_bd_pins axi_ethernet_2/s_axi_lite_clk] [get_bd_pins axi_ethernet_3/s_axi_lite_clk] [get_bd_pins axi_ic_gp/ACLK] [get_bd_pins axi_ic_gp/M00_ACLK] [get_bd_pins axi_ic_gp/M01_ACLK] [get_bd_pins axi_ic_gp/M02_ACLK] [get_bd_pins axi_ic_gp/M03_ACLK] [get_bd_pins axi_ic_gp/M04_ACLK] [get_bd_pins axi_ic_gp/M05_ACLK] [get_bd_pins axi_ic_gp/M06_ACLK] [get_bd_pins axi_ic_gp/M07_ACLK] [get_bd_pins axi_ic_gp/M08_ACLK] [get_bd_pins axi_ic_gp/S00_ACLK] [get_bd_pins packet_pipeline_0/s_axi_lite_aclk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
  connect_bd_net -net processing_system7_0_FCLK_CLK2 [get_bd_ports bd_fclk2_200m] [get_bd_pins axi_ethernet_0/ref_clk] [get_bd_pins processing_system7_0/FCLK_CLK2]
  connect_bd_net -net processing_system7_0_FCLK_RESET0_N [get_bd_pins proc_sys_reset_0/aux_reset_in] [get_bd_pins processing_system7_0/FCLK_RESET0_N]
  connect_bd_net -net util_alllock_Res [get_bd_pins proc_sys_reset_0/dcm_locked] [get_bd_pins r_and_dcmlock/Res]
  set_property -dict [ list HDL_ATTRIBUTE.MARK_DEBUG {true}  ] [get_bd_nets util_alllock_Res]

  # Create address segments
  create_bd_addr_seg -range 0x40000000 -offset 0x0 [get_bd_addr_spaces axi_dma_0/Data_SG] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_0_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x40000000 -offset 0x0 [get_bd_addr_spaces axi_dma_0/Data_MM2S] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_0_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x40000000 -offset 0x0 [get_bd_addr_spaces axi_dma_0/Data_S2MM] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_0_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x40000000 -offset 0x0 [get_bd_addr_spaces axi_dma_1/Data_SG] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_0_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x40000000 -offset 0x0 [get_bd_addr_spaces axi_dma_1/Data_MM2S] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_0_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x40000000 -offset 0x0 [get_bd_addr_spaces axi_dma_1/Data_S2MM] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_0_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x40000000 -offset 0x0 [get_bd_addr_spaces axi_dma_2/Data_SG] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_0_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x40000000 -offset 0x0 [get_bd_addr_spaces axi_dma_2/Data_MM2S] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_0_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x40000000 -offset 0x0 [get_bd_addr_spaces axi_dma_2/Data_S2MM] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_0_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x40000000 -offset 0x0 [get_bd_addr_spaces axi_dma_3/Data_SG] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_0_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x40000000 -offset 0x0 [get_bd_addr_spaces axi_dma_3/Data_MM2S] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_0_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x40000000 -offset 0x0 [get_bd_addr_spaces axi_dma_3/Data_S2MM] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_0_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x1000 -offset 0x0 [get_bd_addr_spaces axi_ethernet_0/eth_buf/S_AXI_2TEMAC] [get_bd_addr_segs axi_ethernet_0/eth_mac/s_axi/Reg] SEG_eth_mac_Reg
  create_bd_addr_seg -range 0x1000 -offset 0x0 [get_bd_addr_spaces axi_ethernet_1/eth_buf/S_AXI_2TEMAC] [get_bd_addr_segs axi_ethernet_1/eth_mac/s_axi/Reg] SEG_eth_mac_Reg
  create_bd_addr_seg -range 0x1000 -offset 0x0 [get_bd_addr_spaces axi_ethernet_2/eth_buf/S_AXI_2TEMAC] [get_bd_addr_segs axi_ethernet_2/eth_mac/s_axi/Reg] SEG_eth_mac_Reg
  create_bd_addr_seg -range 0x1000 -offset 0x0 [get_bd_addr_spaces axi_ethernet_3/eth_buf/S_AXI_2TEMAC] [get_bd_addr_segs axi_ethernet_3/eth_mac/s_axi/Reg] SEG_eth_mac_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x40400000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_dma_0/S_AXI_LITE/Reg] SEG_axi_dma_0_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x40410000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_dma_1/S_AXI_LITE/Reg] SEG_axi_dma_1_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x40420000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_dma_2/S_AXI_LITE/Reg] SEG_axi_dma_2_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x40430000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_dma_3/S_AXI_LITE/Reg] SEG_axi_dma_3_Reg
  create_bd_addr_seg -range 0x40000 -offset 0x43C00000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_ethernet_0/eth_buf/S_AXI/REG] SEG_eth_buf_REG
  create_bd_addr_seg -range 0x40000 -offset 0x43C40000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_ethernet_1/eth_buf/S_AXI/REG] SEG_eth_buf_REG6
  create_bd_addr_seg -range 0x40000 -offset 0x43C80000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_ethernet_2/eth_buf/S_AXI/REG] SEG_eth_buf_REG8
  create_bd_addr_seg -range 0x40000 -offset 0x43CC0000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_ethernet_3/eth_buf/S_AXI/REG] SEG_eth_buf_REG10
  create_bd_addr_seg -range 0x8000000 -offset 0x48000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs packet_pipeline_0/s_axi_lite/reg0] SEG_packet_pipeline_0_reg0
  

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


