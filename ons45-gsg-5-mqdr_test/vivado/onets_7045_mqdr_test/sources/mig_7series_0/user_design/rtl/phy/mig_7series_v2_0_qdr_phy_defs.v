`ifdef PHY_16BIT_H
`else
// show BLH parameters
`define SHOW_PARMS                   0 
`define MSB_SCAN_IN                  0
`define MSB_IF_SCAN_OUT              `MSB_SCAN_IN +  4
`define MSB_OF_SCAN_OUT              `MSB_IF_SCAN_OUT + 4
`define MSB_SCLK                     `MSB_OF_SCAN_OUT + 1
`define MSB_SCAN_EN                  `MSB_SCLK + 1
`define MSB_TEST_IN                  `MSB_SCAN_EN + 15
`define MSB_TEST_OUT_PI              `MSB_TEST_IN + 6
`define MSB_SCAN_OUT_PI              `MSB_TEST_OUT_PI + 1 
`define MSB_TEST_OUT_PO              `MSB_SCAN_OUT_PI + 6
`define MSB_SCAN_OUT_PO              `MSB_TEST_OUT_PO + 1 
`define MSB_DQS_OORANGE              `MSB_SCAN_OUT_PO + 1
`define MSB_IF_SCAN_EN_B_IO          `MSB_DQS_OORANGE + 1
`define MSB_IF_SCAN_IN_IO            `MSB_IF_SCAN_EN_B_IO + 3
`define MSB_IF_TEST_MODE_B_IO        `MSB_IF_SCAN_IN_IO + 1
`define MSB_IF_TEST_READ_DIS_B       `MSB_IF_TEST_MODE_B_IO + 1
`define MSB_IF_TEST_WRITE_DIS_B      `MSB_IF_TEST_READ_DIS_B + 1

`define MSB_OF_SCAN_EN_B_IO          `MSB_IF_TEST_WRITE_DIS_B + 1
`define MSB_OF_SCAN_IN_IO            `MSB_OF_SCAN_EN_B_IO  + 4
`define MSB_OF_TEST_MODE_B_IO        `MSB_OF_SCAN_IN_IO + 1
`define MSB_OF_TEST_READ_DIS_B       `MSB_OF_TEST_MODE_B_IO + 1
`define MSB_OF_TEST_WRITE_DIS_B      `MSB_OF_TEST_READ_DIS_B + 1

`define MSB_PC_TEST_INPUT            `MSB_OF_TEST_WRITE_DIS_B + 16
`define MSB_PC_TEST_OUTPUT           `MSB_PC_TEST_INPUT + 16
`define MSB_PC_SCAN_IN               `MSB_PC_TEST_OUTPUT + 14
`define MSB_PC_SCAN_OUT              `MSB_PC_SCAN_IN + 14
`define MSB_TEST_SEL                 `MSB_PC_SCAN_OUT + 3
`define MSB_PC_SCAN_EN               `MSB_TEST_SEL + 1

`define SCAN_TEST_BUS_WIDTH          `MSB_PC_SCAN_EN + 1

`define MSB_EN_CALIB                 1
`define MSB_STG2_F                   `MSB_EN_CALIB + 1
`define MSB_STG2_C                   `MSB_STG2_F + 1
`define MSB_STG2_FINCDEC	     `MSB_STG2_C + 1
`define MSB_STG2_CINCDEC             `MSB_STG2_FINCDEC + 1
`define MSB_STG2_LOAD                `MSB_STG2_CINCDEC + 1
`define MSB_STG2_READ                `MSB_STG2_LOAD + 1
`define MSB_STG2_REG1                `MSB_STG2_READ + 8
`define MSB_DIV_CYCLE_DELAY          `MSB_STG2_REG1 + 1
`define MSB_C_OVERFL                 `MSB_DIV_CYCLE_DELAY + 1
`define MSB_F_OVERFL                 `MSB_C_OVERFL + 1
`define MSB_STG2_REG_R               `MSB_F_OVERFL  + 8
`define MSB_STG2_REG_L               `MSB_STG2_REG_R + 8


`define MSB_EN_STG1                  `MSB_STG2_REG_L + 1
`define MSB_STG1_INCDEC              `MSB_EN_STG1 + 1
`define MSB_STG1_LOAD                `MSB_STG1_INCDEC + 1
`define MSB_STG1_READ                `MSB_STG1_LOAD + 1
`define MSB_STG1_REG_L               `MSB_STG1_READ + 8
`define MSB_STG1_REG_R               `MSB_STG1_REG_L + 9
`define MSB_STG1_OVRFL               `MSB_STG1_REG_R + 1
`define MSB_PHASE_LOCKED             `MSB_STG1_OVRFL + 1
`define MSB_EN_STG1_ADJUST           `MSB_PHASE_LOCKED   + 1
`define CALIB_BUS_WIDTH              `MSB_EN_STG1_ADJUST + 1
`ifndef FUJI_PHY_BLH
   `ifdef FUJI_UNISIMS
   `define UNISIM_PHASER_IN   PHASER_IN
   `else
   `define UNISIM_PHASER_IN   B_PHASER_IN
   `endif
`else
   `define UNISIM_PHASER_IN   B_PHASER_IN
`endif

`ifndef FUJI_PHY_BLH
    `ifdef FUJI_UNISIMS
    `define UNISIM_PHASER_OUT   PHASER_OUT
    `else
    `define UNISIM_PHASER_OUT   B_PHASER_OUT
    `endif
`else
    `define UNISIM_PHASER_OUT   B_PHASER_OUT
`endif

`ifndef FUJI_PHY_BLH
    `ifdef FUJI_UNISIMS
    `define UNISIM_IN_FIFO          IN_FIFO
    `else
    `define UNISIM_IN_FIFO          B_IN_FIFO
    `endif
`else
    `define UNISIM_IN_FIFO          B_IN_FIFO
`endif

`ifndef FUJI_PHY_BLH
    `ifdef FUJI_UNISIMS
    `define UNISIM_OUT_FIFO          OUT_FIFO
    `else
    `define UNISIM_OUT_FIFO          B_OUT_FIFO
    `endif
`else
    `define UNISIM_OUT_FIFO          B_OUT_FIFO
`endif

`ifndef FUJI_PHY_BLH
    `ifdef FUJI_UNISIMS
    `define UNISIM_OSERDESE2       OSERDESE2
    `else
    `define UNISIM_OSERDESE2       B_OSERDESE2
    `endif
`else
    `define UNISIM_OSERDESE2       B_OSERDESE2
`endif

`ifndef FUJI_PHY_BLH
    `ifdef FUJI_UNISIMS
    `define UNISIM_ISERDESE2       ISERDESE2
    `else
    `define UNISIM_ISERDESE2       B_ISERDESE2
    `endif
`else
    `define UNISIM_ISERDESE2       B_ISERDESE2
`endif

`endif
