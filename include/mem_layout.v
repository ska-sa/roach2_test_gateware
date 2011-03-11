`ifndef MEMLAYOUT_H
`define MEMLAYOUT_H

`define DRAM_A_HIGH      32'h07ff_ffff
`define DRAM_A_BASE      32'h0400_0000

`define QDR3_A_HIGH      32'h03ff_ffff
`define QDR3_A_BASE      32'h0380_0000

`define QDR2_A_HIGH      32'h037f_ffff
`define QDR2_A_BASE      32'h0300_0000

`define QDR1_A_HIGH      32'h02ff_ffff
`define QDR1_A_BASE      32'h0280_0000

`define QDR0_A_HIGH      32'h027f_ffff
`define QDR0_A_BASE      32'h0200_0000

`define APP_A_HIGH       32'h01ff_ffff
`define APP_A_BASE       32'h0100_0000

`define GBE_A_HIGH       32'h0067_ffff
`define GBE_A_BASE       32'h0060_0000

`define TGE7_A_HIGH      32'h005f_ffff
`define TGE7_A_BASE      32'h0058_0000
`define TGE6_A_HIGH      32'h0057_ffff
`define TGE6_A_BASE      32'h0050_0000
`define TGE5_A_HIGH      32'h004f_ffff
`define TGE5_A_BASE      32'h0048_0000
`define TGE4_A_HIGH      32'h0047_ffff
`define TGE4_A_BASE      32'h0040_0000

`define TGE3_A_HIGH      32'h003f_ffff
`define TGE3_A_BASE      32'h0038_0000
`define TGE2_A_HIGH      32'h0037_ffff
`define TGE2_A_BASE      32'h0030_0000
`define TGE1_A_HIGH      32'h002f_ffff
`define TGE1_A_BASE      32'h0028_0000
`define TGE0_A_HIGH      32'h0027_ffff
`define TGE0_A_BASE      32'h0020_0000

`define ZDOK1_A_HIGH     32'h0009_ffff
`define ZDOK1_A_BASE     32'h0009_0000

`define ZDOK0_A_HIGH     32'h0008_ffff
`define ZDOK0_A_BASE     32'h0008_0000

`define DRAMCONF_A_HIGH  32'h0007_ffff
`define DRAMCONF_A_BASE  32'h0007_0000

`define QDR3CONF_A_HIGH  32'h0006_ffff
`define QDR3CONF_A_BASE  32'h0006_0000
`define QDR2CONF_A_HIGH  32'h0005_ffff
`define QDR2CONF_A_BASE  32'h0005_0000
`define QDR1CONF_A_HIGH  32'h0004_ffff
`define QDR1CONF_A_BASE  32'h0004_0000
`define QDR0CONF_A_HIGH  32'h0003_ffff
`define QDR0CONF_A_BASE  32'h0003_0000

`define GPIO_A_HIGH      32'h0001_ffff
`define GPIO_A_BASE      32'h0001_0000

`define SYSBLOCK_A_HIGH  32'h0000_ffff
`define SYSBLOCK_A_BASE  32'h0000_0000

`endif
