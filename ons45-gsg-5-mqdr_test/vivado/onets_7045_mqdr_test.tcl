#
# Vivado (TM) v2013.4 (64-bit)
#

############################################################
### 0. General settings
############################################################
set proj_root "."
set proj_name "onets_7045_mqdr_test"
set proj_part "xc7z045ffg676-2"
set proj_bd   "onets_bd"
set proj_top  "onetswitch_top"

set proj_bd_tcl      "$proj_root/$proj_name/bd/$proj_bd.tcl"
set proj_source_dir  "$proj_root/$proj_name/sources"
set proj_constr_dir  "$proj_root/$proj_name/constrs"
set proj_mig_example_top_dir "$proj_source_dir/mig_7series_0/example_design/rtl"
set proj_mig_user_dir "$proj_source_dir/mig_7series_0/user_design/rtl"

set sources_files [list \
 "[file normalize "$proj_source_dir/onetswitch_top.v"]"\
 "[file normalize "$proj_mig_example_top_dir/example_top.v"]"\
 "[file normalize "$proj_mig_example_top_dir/traffic_gen/mig_7series_v2_0_afifo.v"]"\
 "[file normalize "$proj_mig_example_top_dir/traffic_gen/mig_7series_v2_0_cmd_gen.v"]"\
 "[file normalize "$proj_mig_example_top_dir/traffic_gen/mig_7series_v2_0_cmd_prbs_gen.v"]"\
 "[file normalize "$proj_mig_example_top_dir/traffic_gen/mig_7series_v2_0_data_prbs_gen.v"]"\
 "[file normalize "$proj_mig_example_top_dir/traffic_gen/mig_7series_v2_0_init_mem_pattern_ctr.v"]"\
 "[file normalize "$proj_mig_example_top_dir/traffic_gen/mig_7series_v2_0_memc_flow_vcontrol.v"]"\
 "[file normalize "$proj_mig_example_top_dir/traffic_gen/mig_7series_v2_0_memc_traffic_gen.v"]"\
 "[file normalize "$proj_mig_example_top_dir/traffic_gen/mig_7series_v2_0_rd_data_gen.v"]"\
 "[file normalize "$proj_mig_example_top_dir/traffic_gen/mig_7series_v2_0_read_data_path.v"]"\
 "[file normalize "$proj_mig_example_top_dir/traffic_gen/mig_7series_v2_0_read_posted_fifo.v"]"\
 "[file normalize "$proj_mig_example_top_dir/traffic_gen/mig_7series_v2_0_s7ven_data_gen.v"]"\
 "[file normalize "$proj_mig_example_top_dir/traffic_gen/mig_7series_v2_0_tg_prbs_gen.v"]"\
 "[file normalize "$proj_mig_example_top_dir/traffic_gen/mig_7series_v2_0_tg_status.v"]"\
 "[file normalize "$proj_mig_example_top_dir/traffic_gen/mig_7series_v2_0_traffic_gen_top.v"]"\
 "[file normalize "$proj_mig_example_top_dir/traffic_gen/mig_7series_v2_0_vio_init_pattern_bram.v"]"\
 "[file normalize "$proj_mig_example_top_dir/traffic_gen/mig_7series_v2_0_wr_data_gen.v"]"\
 "[file normalize "$proj_mig_example_top_dir/traffic_gen/mig_7series_v2_0_write_data_path.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/clocking/mig_7series_v2_0_clk_ibuf.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/clocking/mig_7series_v2_0_infrastructure.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/clocking/mig_7series_v2_0_iodelay_ctrl.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_phy_byte_lane_map.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_phy_defs.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_phy_top.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_phy_write_control_io.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_phy_write_data_io.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_phy_write_init_sm.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_phy_write_top.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_rld_byte_group_io.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_rld_byte_lane.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_rld_if_post_fifo.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_rld_mc_phy.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_rld_of_pre_fifo.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_rld_phy_4lanes.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_rld_phy_ck_addr_cmd_delay.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_rld_phy_cntrl_init.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_rld_phy_rdlvl.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_rld_phy_read_data_align.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_rld_phy_read_stage2_cal.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_rld_phy_read_top.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_rld_phy_read_vld_gen.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/phy/mig_7series_v2_0_qdr_rld_prbs_gen.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/mig_7series_0_mig_sim.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/mig_7series_0.v"]"\
 "[file normalize "$proj_source_dir/mig_7series_0/user_design/rtl/mig_7series_0_mig.v"]"\
]

set constrs_files [list \
 "[file normalize "$proj_constr_dir/onetswitch_pins.xdc"]"\
 "[file normalize "$proj_constr_dir/onetswitch_top.xdc"]"\
 "[file normalize "$proj_constr_dir/mig_7series_0.xdc"]"\
]


### set bd_files [list \
###  "[file normalize "$proj_root/$proj_name.srcs/sources_1/bd/$proj_bd/$proj_bd.bd"]"\
###  "[file normalize "$proj_root/$proj_name.srcs/sources_1/bd/$proj_bd/hdl/${proj_bd}_wrapper.v"]"\
### ]

############################################################
### 1. Project
############################################################
# Create project
create_project $proj_name $proj_root -part $proj_part -force

############################################################
### 2. Generate the user-defined IPs
############################################################

############################################################
### 3. Generate the block design
############################################################
source $proj_bd_tcl
add_files [ make_wrapper -files [get_files $proj_root/$proj_name.srcs/sources_1/bd/$proj_bd/$proj_bd.bd] -top ]

############################################################
### 4. Add the source files
############################################################
# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Add files to 'sources_1' fileset
import_files -fileset sources_1 $sources_files -flat
### add_files -fileset sources_1 $bd_files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property "top" $proj_top $obj

############################################################
### 5. Add the constraint files
############################################################
# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Add files to 'constrs_1' fileset
import_files -fileset constrs_1 $constrs_files -flat

############################################################
### 6. Add the simulation files
############################################################
# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets sim_1] ""]} {
  create_fileset -simset sim_1
}

# Add files to 'sim_1' fileset
set obj [get_filesets sim_1]
# Empty (no sources present)

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property "top" $proj_top $obj

############################################################
### 7. Run the design flow
############################################################
# Create 'synth_1' run (if not found)
if {[string equal [get_runs synth_1] ""]} {
  create_run -name synth_1 -part $proj_part -flow {Vivado Synthesis 2013} -strategy "Vivado Synthesis Defaults" -constrset constrs_1
}
set obj [get_runs synth_1]
set_property "part" $proj_part $obj

# Create 'impl_1' run (if not found)
if {[string equal [get_runs impl_1] ""]} {
  create_run -name impl_1 -part $proj_part -flow {Vivado Implementation 2013} -strategy "Vivado Implementation Defaults" -constrset constrs_1 -parent_run synth_1
}
set obj [get_runs impl_1]
set_property "part" $proj_part $obj


puts "INFO: Project created."
