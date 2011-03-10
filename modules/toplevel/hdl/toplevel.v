`include "mem_layout.v"
module toplevel(
    input          sys_clk_n,
    input          sys_clk_p,

    input          aux_clk_n,
    input          aux_clk_p,
    input          aux_synci_n,
    input          aux_synci_p,
    output         aux_synco_n,
    output         aux_synco_p,

    inout   [11:0] v6_gpio,

    input          ppc_perclk,
    input   [5:29] ppc_paddr,
    input    [1:0] ppc_pcsn,
    inout   [0:31] ppc_pdata,
    input    [0:3] ppc_pben,
    input          ppc_poen,
    input          ppc_pwrn,
    input          ppc_pblastn,
    output         ppc_prdy,
    output         ppc_doen,

    output         v6_irqn,

    output         ddr3_ck_n,
    output         ddr3_ck_p,
    output   [8:0] ddr3_dm,
    inout   [71:0] ddr3_dq,
    inout    [8:0] ddr3_dqs_n,
    inout    [8:0] ddr3_dqs_p,
    output   [2:0] ddr3_ba,
    output  [15:0] ddr3_a,
    output   [3:0] ddr3_sn,
    output         ddr3_rasn,
    output         ddr3_casn,
    output         ddr3_wen,
    output   [1:0] ddr3_cke,
    output   [1:0] ddr3_odt,
    output         ddr3_resetn,

    output         qdr0_k,
    output         qdr0_kn,
    output         qdr0_rdn,
    output         qdr0_wrn,
    output  [20:0] qdr0_a,
    output  [35:0] qdr0_d,
    output         qdr0_doffn,
    input   [35:0] qdr0_q,

    output         qdr1_k,
    output         qdr1_kn,
    output         qdr1_rdn,
    output         qdr1_wrn,
    output  [20:0] qdr1_a,
    output  [35:0] qdr1_d,
    output         qdr1_doffn,
    input   [35:0] qdr1_q,

    output         qdr2_k,
    output         qdr2_kn,
    output         qdr2_rdn,
    output         qdr2_wrn,
    output  [20:0] qdr2_a,
    output  [35:0] qdr2_d,
    output         qdr2_doffn,
    input   [35:0] qdr2_q,

    output         qdr3_k,
    output         qdr3_kn,
    output         qdr3_rdn,
    output         qdr3_wrn,
    output  [20:0] qdr3_a,
    output  [35:0] qdr3_d,
    output         qdr3_doffn,
    input   [35:0] qdr3_q,

    inout    [1:0] zdok0_clk_n,
    inout    [1:0] zdok0_clk_p,
    inout   [37:0] zdok0_dp_n,
    inout   [37:0] zdok0_dp_p,

    inout    [1:0] zdok1_clk_n,
    inout    [1:0] zdok1_clk_p,
    inout   [37:0] zdok1_dp_n,
    inout   [37:0] zdok1_dp_p,

    /*

    inout   [11:0] mgt_gpio,
    output  [31:0] mgt_tx_n,
    output  [31:0] mgt_tx_p,
    input   [31:0] mgt_rx_n,
    input   [31:0] mgt_rx_p,

    input    [2:0] xaui_clkref_n,
    input    [2:0] xaui_clkref_p,
    input    [2:0] misc_clkref_n,
    input    [2:0] misc_clkref_p,
    input    [7:0] ext_refclk_p,
    input    [7:0] ext_refclk_n,
    */

    input          sgmii_rx_n,
    input          sgmii_rx_p,
    output         sgmii_tx_n,
    output         sgmii_tx_p,
    input          sgmii_clkref_n,
    input          sgmii_clkref_p
  );
  
  // Make sure clk_125 is not renamed
  // synthesis attribute KEEP of clk_125 is TRUE
  wire clk_125;
  // synthesis attribute KEEP of sys_clk is TRUE
  wire sys_clk;

  wire sys_rst;
  wire idelay_rdy;

  infrastructure infrastructure_inst (
    .sys_clk_buf_n  (sys_clk_n),
    .sys_clk_buf_p  (sys_clk_p),
    .sys_clk0       (sys_clk),
    .sys_clk180     (),
    .sys_clk270     (),
    .clk_200        (),
    .sys_rst        (sys_rst),
    .idelay_rdy     (idelay_rdy)
  );


  wire [2:0] knight_rider_speed;

  knight_rider knight_rider_inst(
    .clk  (sys_clk),
    .rst  (sys_rst),
    .led  (v6_gpio[7:0]),
    .rate (knight_rider_speed)
  );

  wire aux_clk;
  IBUFGDS #(
    .IOSTANDARD("LVDS_25"),
    .DIFF_TERM("TRUE")
  ) ibufgds_aux_clk (
    .I (aux_clk_p),
    .IB(aux_clk_n),
    .O (aux_clk)
  );
  
  wire aux_synci;
  IBUFDS #(
    .IOSTANDARD("LVDS_25"),
    .DIFF_TERM("TRUE")
  ) ibufds_aux_synci (
    .I (aux_synci_p),
    .IB(aux_synci_n),
    .O (aux_synci)
  );
  
  wire aux_synco;
  OBUFDS #(
    .IOSTANDARD("LVDS_25")
  ) obufds_aux_synco (
    .O (aux_synco_p),
    .OB(aux_synco_n),
    .I (aux_synco)
  );
  assign aux_synco = sys_clk;

  assign v6_gpio[8] = aux_synci;
  assign v6_gpio[11] = aux_clk;

  wire        wb_clk_i;
  wire        wb_rst_i;
  wire        wbm_cyc_o;
  wire        wbm_stb_o;
  wire        wbm_we_o;
  wire  [3:0] wbm_sel_o;
  wire [31:0] wbm_adr_o;
  wire [31:0] wbm_dat_o;
  wire [31:0] wbm_dat_i;
  wire        wbm_ack_i;
  wire        wbm_err_i;

  assign wb_clk_i = sys_clk;
  assign wb_rst_i = sys_rst;

  wire [0:31] epb_data_i;
  wire [0:31] epb_data_o;
  wire        epb_data_oe_n;
  wire        epb_clk;

  epb_infrastructure epb_infrastructure_inst(
    .epb_data_buf  (ppc_pdata),
    .epb_data_oe_n (epb_data_oe_n),
    .epb_data_in   (epb_data_o),
    .epb_data_out  (epb_data_i),
    .per_clk       (ppc_perclk),
    .epb_clk       (epb_clk)
  );

  OBUF #(
    .IOSTANDARD("LVCMOS25")
  ) OBUF_v6_irqn (
    .O (v6_irqn),
    .I (1'b0)
  );

  epb_wb_bridge_reg epb_wb_bridge_reg_inst(
    .wb_clk_i (wb_clk_i),
    .wb_rst_i (wb_rst_i),
    .wb_cyc_o (wbm_cyc_o),
    .wb_stb_o (wbm_stb_o),
    .wb_we_o  (wbm_we_o),
    .wb_sel_o (wbm_sel_o),
    .wb_adr_o (wbm_adr_o),
    .wb_dat_o (wbm_dat_o),
    .wb_dat_i (wbm_dat_i),
    .wb_ack_i (wbm_ack_i),
    .wb_err_i (wbm_err_i),

    .epb_clk       (epb_clk),
    .epb_cs_n      (ppc_pcsn[0]),
    .epb_oe_n      (ppc_poen),
    .epb_r_w_n     (ppc_pwrn),
    .epb_be_n      (ppc_pben), 
    .epb_addr      (ppc_paddr),
    .epb_data_i    (epb_data_i),
    .epb_data_o    (epb_data_o),
    .epb_data_oe_n (epb_data_oe_n),
    .epb_rdy       (ppc_prdy),
    .epb_doen      (ppc_doen)
  );

  localparam NUM_SLAVES    = 24;

  localparam DRAM_SLI      = 23;
  localparam QDR3_SLI      = 22;
  localparam QDR2_SLI      = 21;
  localparam QDR1_SLI      = 20;
  localparam QDR0_SLI      = 19;
  localparam APP_SLI       = 18;
  localparam GBE_SLI       = 17;
  localparam TGE7_SLI      = 16;
  localparam TGE6_SLI      = 15;
  localparam TGE5_SLI      = 14;
  localparam TGE4_SLI      = 13;
  localparam TGE3_SLI      = 12;
  localparam TGE2_SLI      = 11;
  localparam TGE1_SLI      = 10;
  localparam TGE0_SLI      =  9;
  localparam ZDOK1_SLI     =  8;
  localparam ZDOK0_SLI     =  7;
  localparam DRAMCONF_SLI  =  6;
  localparam QDR3CONF_SLI  =  5;
  localparam QDR2CONF_SLI  =  4;
  localparam QDR1CONF_SLI  =  3;
  localparam QDR0CONF_SLI  =  2;
  localparam GPIO_SLI      =  1;
  localparam SYSBLOCK_SLI  =  0;

  localparam SLAVE_BASE = {
    `DRAM_A_BASE,
    `QDR3_A_BASE,
    `QDR2_A_BASE,
    `QDR1_A_BASE,
    `QDR0_A_BASE,
    `APP_A_BASE,
    `GBE_A_BASE,
    `TGE7_A_BASE,
    `TGE6_A_BASE,
    `TGE5_A_BASE,
    `TGE4_A_BASE,
    `TGE3_A_BASE,
    `TGE2_A_BASE,
    `TGE1_A_BASE,
    `TGE0_A_BASE,
    `ZDOK1_A_BASE,
    `ZDOK0_A_BASE,
    `DRAMCONF_A_BASE,
    `QDR3CONF_A_BASE,
    `QDR2CONF_A_BASE,
    `QDR1CONF_A_BASE,
    `QDR0CONF_A_BASE,
    `GPIO_A_BASE,
    `SYSBLOCK_A_BASE
  };

  localparam SLAVE_HIGH = {
    `DRAM_A_HIGH,
    `QDR3_A_HIGH,
    `QDR2_A_HIGH,
    `QDR1_A_HIGH,
    `QDR0_A_HIGH,
    `APP_A_HIGH,
    `GBE_A_HIGH,
    `TGE7_A_HIGH,
    `TGE6_A_HIGH,
    `TGE5_A_HIGH,
    `TGE4_A_HIGH,
    `TGE3_A_HIGH,
    `TGE2_A_HIGH,
    `TGE1_A_HIGH,
    `TGE0_A_HIGH,
    `ZDOK1_A_HIGH,
    `ZDOK0_A_HIGH,
    `DRAMCONF_A_HIGH,
    `QDR3CONF_A_HIGH,
    `QDR2CONF_A_HIGH,
    `QDR1CONF_A_HIGH,
    `QDR0CONF_A_HIGH,
    `GPIO_A_HIGH,
    `SYSBLOCK_A_HIGH
  };

  wire    [NUM_SLAVES - 1:0] wbs_cyc_o;
  wire    [NUM_SLAVES - 1:0] wbs_stb_o;
  wire                       wbs_we_o;
  wire                 [3:0] wbs_sel_o;
  wire                [31:0] wbs_adr_o;
  wire                [31:0] wbs_dat_o;
  wire [32*NUM_SLAVES - 1:0] wbs_dat_i;
  wire    [NUM_SLAVES - 1:0] wbs_ack_i;
  wire    [NUM_SLAVES - 1:0] wbs_err_i;

  wbs_arbiter #(
    .NUM_SLAVES (NUM_SLAVES),
    .SLAVE_ADDR (SLAVE_BASE),
    .SLAVE_HIGH (SLAVE_HIGH),
    .TIMEOUT    (1024)
  ) wbs_arbiter_inst (
    .wb_clk_i  (wb_clk_i),
    .wb_rst_i  (wb_rst_i),

    .wbm_cyc_i (wbm_cyc_o),
    .wbm_stb_i (wbm_stb_o),
    .wbm_we_i  (wbm_we_o),
    .wbm_sel_i (wbm_sel_o),
    .wbm_adr_i (wbm_adr_o),
    .wbm_dat_i (wbm_dat_o),
    .wbm_dat_o (wbm_dat_i),
    .wbm_ack_o (wbm_ack_i),
    .wbm_err_o (wbm_err_i),

    .wbs_cyc_o (wbs_cyc_o),
    .wbs_stb_o (wbs_stb_o),
    .wbs_we_o  (wbs_we_o),
    .wbs_sel_o (wbs_sel_o),
    .wbs_adr_o (wbs_adr_o),
    .wbs_dat_o (wbs_dat_o),
    .wbs_dat_i (wbs_dat_i),
    .wbs_ack_i (wbs_ack_i)
  );

  wire        debug_clk;
  wire [31:0] debug_regin_0;
  wire [31:0] debug_regin_1;
  wire [31:0] debug_regin_2;
  wire [31:0] debug_regin_3;
  wire [31:0] debug_regin_4;
  wire [31:0] debug_regin_5;
  wire [31:0] debug_regin_6;
  wire [31:0] debug_regin_7;
  wire [31:0] debug_regout_0;
  wire [31:0] debug_regout_1;
  wire [31:0] debug_regout_2;
  wire [31:0] debug_regout_3;
  wire [31:0] debug_regout_4;
  wire [31:0] debug_regout_5;
  wire [31:0] debug_regout_6;
  wire [31:0] debug_regout_7;

  sys_block sys_block_inst(
    .wb_clk_i (wb_clk_i),
    .wb_rst_i (wb_rst_i),
    .wb_cyc_i (wbs_cyc_o[SYSBLOCK_SLI]),
    .wb_stb_i (wbs_stb_o[SYSBLOCK_SLI]),
    .wb_we_i  (wbs_we_o),
    .wb_sel_i (wbs_sel_o),
    .wb_adr_i (wbs_adr_o),
    .wb_dat_i (wbs_dat_o),
    .wb_dat_o (wbs_dat_i[(SYSBLOCK_SLI+1)*32-1:(SYSBLOCK_SLI)*32]),
    .wb_ack_o (wbs_ack_i[SYSBLOCK_SLI]),
    .wb_err_o (wbs_err_i[SYSBLOCK_SLI]),

    .debug_clk (debug_clk),
    .regin_0   (debug_regin_0),
    .regin_1   (debug_regin_1),
    .regin_2   (debug_regin_2),
    .regin_3   (debug_regin_3),
    .regin_4   (debug_regin_4),
    .regin_5   (debug_regin_5),
    .regin_6   (debug_regin_6),
    .regin_7   (debug_regin_7),
    .regout_0  (debug_regout_0),
    .regout_1  (debug_regout_1),
    .regout_2  (debug_regout_2),
    .regout_3  (debug_regout_3),
    .regout_4  (debug_regout_4),
    .regout_5  (debug_regout_5),
    .regout_6  (debug_regout_6),
    .regout_7  (debug_regout_7)
  );

  assign debug_clk     = sys_clk;

  assign debug_regin_0 = 32'h_DEAD_CAFE;
  assign debug_regin_1 = 32'h_0B0E_FACE;
  assign debug_regin_2 = 32'h_BAFF_BABE;
  assign debug_regin_3 = 32'h_C0DE_B00B;
  assign debug_regin_4 = 32'h_F00D_D00D;
  assign debug_regin_5 = 32'h_ACED_DEED;
  assign debug_regin_6 = 32'h_BAD_FACED;
  assign debug_regin_7 = 32'h_B00ED_0FF;

  /************************ ZDOK 0 ****************************/

  wire [79:0] zdok0_out;
  wire [79:0] zdok0_in;
  wire [79:0] zdok0_oe;
  wire [79:0] zdok0_ded;

  gpio_controller #(
    .COUNT(80)
  ) gpio_zdok0 (
    .wb_clk_i (wb_clk_i),
    .wb_rst_i (wb_rst_i),
    .wb_cyc_i (wbs_cyc_o[ZDOK0_SLI]),
    .wb_stb_i (wbs_stb_o[ZDOK0_SLI]),
    .wb_we_i  (wbs_we_o),
    .wb_sel_i (wbs_sel_o),
    .wb_adr_i (wbs_adr_o),
    .wb_dat_i (wbs_dat_o),
    .wb_dat_o (wbs_dat_i[(ZDOK0_SLI+1)*32-1:(ZDOK0_SLI)*32]),
    .wb_ack_o (wbs_ack_i[ZDOK0_SLI]),
    .wb_err_o (wbs_err_i[ZDOK0_SLI]),

    .gpio_out (zdok0_out),
    .gpio_in  (zdok0_in),
    .gpio_oe  (zdok0_oe),
    .gpio_ded (zdok0_ded)
  );

  IOBUF #(
    .IOSTANDARD("LVCMOS25")
  ) IOBUF_zdok0[79:0] (
    .IO ({zdok0_clk_p[1], zdok0_dp_p[37:29], zdok0_clk_p[0], zdok0_dp_p[28:0],
          zdok0_clk_n[1], zdok0_dp_n[37:29], zdok0_clk_n[0], zdok0_dp_n[28:0]}),
    .I  (zdok0_out),
    .O  (zdok0_in),
    .T  (~zdok0_oe)
  );

  PULLUP pullup_zdok0[79:0](
    .O ({zdok0_clk_p[1], zdok0_dp_p[37:29], zdok0_clk_p[0], zdok0_dp_p[28:0],
         zdok0_clk_n[1], zdok0_dp_n[37:29], zdok0_clk_n[0], zdok0_dp_n[28:0]})
  );

  /************************ ZDOK 1 ****************************/

  wire [79:0] zdok1_out;
  wire [79:0] zdok1_in;
  wire [79:0] zdok1_oe;
  wire [79:0] zdok1_ded;

  gpio_controller #(
    .COUNT(80)
  ) gpio_zdok1 (
    .wb_clk_i (wb_clk_i),
    .wb_rst_i (wb_rst_i),
    .wb_cyc_i (wbs_cyc_o[ZDOK1_SLI]),
    .wb_stb_i (wbs_stb_o[ZDOK1_SLI]),
    .wb_we_i  (wbs_we_o),
    .wb_sel_i (wbs_sel_o),
    .wb_adr_i (wbs_adr_o),
    .wb_dat_i (wbs_dat_o),
    .wb_dat_o (wbs_dat_i[(ZDOK1_SLI+1)*32-1:(ZDOK1_SLI)*32]),
    .wb_ack_o (wbs_ack_i[ZDOK1_SLI]),
    .wb_err_o (wbs_err_i[ZDOK1_SLI]),

    .gpio_out (zdok1_out),
    .gpio_in  (zdok1_in),
    .gpio_oe  (zdok1_oe),
    .gpio_ded (zdok1_ded)
  );

  IOBUF #(
    .IOSTANDARD ("LVCMOS25")
  ) IOBUF_zdok1[79:0] (
    .IO ({zdok1_clk_p[1], zdok1_dp_p[37:29], zdok1_clk_p[0], zdok1_dp_p[28:0],
          zdok1_clk_n[1], zdok1_dp_n[37:29], zdok1_clk_n[0], zdok1_dp_n[28:0]}),
    .I  (zdok1_out),
    .O  (zdok1_in),
    .T  (~zdok1_oe)
  );

  PULLUP pullup_zdok1[79:0](
    .O ({zdok1_clk_p[1], zdok1_dp_p[37:29], zdok1_clk_p[0], zdok1_dp_p[28:0],
         zdok1_clk_n[1], zdok1_dp_n[37:29], zdok1_clk_n[0], zdok1_dp_n[28:0]})
  );

  /************** Common QDR Infrastructure ****************/

  wire qdr_clk0;
  wire qdr_clk180;
  wire qdr_clk270;

  wire qdr_pll_lock;

  clk_gen #(
    .CLK_FREQ (200)
  ) clk_gen_qdr (
    .clk_100  (sys_clk),
    .reset    (sys_rst),
    .clk0     (qdr_clk0),
    .clk180   (qdr_clk180),
    .clk270   (qdr_clk270),
    .clkdiv2  (),
    .pll_lock (qdr_pll_lock)
  );

  reg qdr_rstR;
  reg qdr_rstRR;

  always @(posedge qdr_clk0) begin
    qdr_rstR  <= sys_rst || !qdr_pll_lock || !idelay_rdy;
    qdr_rstRR <= qdr_rstR;
  end
  wire qdr_rst = qdr_rstRR;

  /************************ QDR 0 ****************************/

  wire [31:0] qdr0_app_addr;
  wire        qdr0_app_wr_en;
  wire [71:0] qdr0_app_wr_data;
  wire        qdr0_app_rd_en;
  wire [71:0] qdr0_app_rd_data;
  wire        qdr0_app_rd_dvld;

  wire        qdr0_phy_rdy;
  wire        qdr0_cal_fail;
  
  qdr_controller_softcal #( 
    .DATA_WIDTH (36),
    .ADDR_WIDTH (21)
  ) qdr0_controller_inst (
    .wb_clk_i    (wb_clk_i),
    .wb_rst_i    (wb_rst_i),
    .wb_cyc_i    (wbs_cyc_o[QDR0CONF_SLI]),
    .wb_stb_i    (wbs_stb_o[QDR0CONF_SLI]),
    .wb_we_i     (wbs_we_o),
    .wb_sel_i    (wbs_sel_o),
    .wb_adr_i    (wbs_adr_o),
    .wb_dat_i    (wbs_dat_o),
    .wb_dat_o    (wbs_dat_i[(QDR0CONF_SLI+1)*32-1:(QDR0CONF_SLI)*32]),
    .wb_ack_o    (wbs_ack_i[QDR0CONF_SLI]),
    .wb_err_o    (wbs_err_i[QDR0CONF_SLI]),

    .qdr_k       (qdr0_k),
    .qdr_k_n     (qdr0_kn),
    .qdr_r_n     (qdr0_rdn),
    .qdr_w_n     (qdr0_wrn),
    .qdr_sa      (qdr0_a),
    .qdr_d       (qdr0_d),
    .qdr_doff_n  (qdr0_doffn),
    .qdr_q       (qdr0_q),

    .clk0        (qdr_clk0),
    .clk180      (qdr_clk180),
    .clk270      (qdr_clk270),
    .reset       (qdr_rst),

    .phy_rdy     (qdr0_phy_rdy),
    .cal_fail    (qdr0_cal_fail),

    .usr_addr    (qdr0_app_addr),
    .usr_wr_strb (qdr0_app_wr_en),
    .usr_wr_data (qdr0_app_wr_data),
    .usr_rd_strb (qdr0_app_rd_en),
    .usr_rd_data (qdr0_app_rd_data),
    .usr_rd_dvld (qdr0_app_rd_dvld)
  );

  qdr_cpu_interface qdr0_cpu_interface(
    .wb_clk_i    (wb_clk_i),
    .wb_rst_i    (wb_rst_i),
    .wb_cyc_i    (wbs_cyc_o[QDR0_SLI]),
    .wb_stb_i    (wbs_stb_o[QDR0_SLI]),
    .wb_we_i     (wbs_we_o),
    .wb_sel_i    (wbs_sel_o),
    .wb_adr_i    (wbs_adr_o),
    .wb_dat_i    (wbs_dat_o),
    .wb_dat_o    (wbs_dat_i[(QDR0_SLI+1)*32-1:(QDR0_SLI)*32]),
    .wb_ack_o    (wbs_ack_i[QDR0_SLI]),
    .wb_err_o    (wbs_err_i[QDR0_SLI]),

    .qdr_clk     (qdr_clk0),
    .qdr_rst     (qdr_rst),

    .qdr_addr    (qdr0_app_addr),
    .qdr_wr_en   (qdr0_app_wr_en),
    .qdr_wr_data (qdr0_app_wr_data),
    .qdr_rd_en   (qdr0_app_rd_en),
    .qdr_rd_data (qdr0_app_rd_data),
    .qdr_rd_dvld (qdr0_app_rd_dvld),
    .phy_rdy     (qdr0_phy_rdy),
    .cal_fail    (qdr0_cal_fail)
  );

  /************************ QDR 1 ****************************/

  wire [31:0] qdr1_app_addr;
  wire        qdr1_app_wr_en;
  wire [71:0] qdr1_app_wr_data;
  wire        qdr1_app_rd_en;
  wire [71:0] qdr1_app_rd_data;
  wire        qdr1_app_rd_dvld;

  wire        qdr1_phy_rdy;
  wire        qdr1_cal_fail;
  
  qdr_controller_softcal #( 
    .DATA_WIDTH (36),
    .ADDR_WIDTH (21)
  ) qdr1_controller_inst (
    .wb_clk_i    (wb_clk_i),
    .wb_rst_i    (wb_rst_i),
    .wb_cyc_i    (wbs_cyc_o[QDR1CONF_SLI]),
    .wb_stb_i    (wbs_stb_o[QDR1CONF_SLI]),
    .wb_we_i     (wbs_we_o),
    .wb_sel_i    (wbs_sel_o),
    .wb_adr_i    (wbs_adr_o),
    .wb_dat_i    (wbs_dat_o),
    .wb_dat_o    (wbs_dat_i[(QDR1CONF_SLI+1)*32-1:(QDR1CONF_SLI)*32]),
    .wb_ack_o    (wbs_ack_i[QDR1CONF_SLI]),
    .wb_err_o    (wbs_err_i[QDR1CONF_SLI]),

    .qdr_k       (qdr1_k),
    .qdr_k_n     (qdr1_kn),
    .qdr_r_n     (qdr1_rdn),
    .qdr_w_n     (qdr1_wrn),
    .qdr_sa      (qdr1_a),
    .qdr_d       (qdr1_d),
    .qdr_doff_n  (qdr1_doffn),
    .qdr_q       (qdr1_q),

    .clk0        (qdr_clk0),
    .clk180      (qdr_clk180),
    .clk270      (qdr_clk270),
    .reset       (qdr_rst),

    .phy_rdy     (qdr1_phy_rdy),
    .cal_fail    (qdr1_cal_fail),

    .usr_addr    (qdr1_app_addr),
    .usr_wr_strb (qdr1_app_wr_en),
    .usr_wr_data (qdr1_app_wr_data),
    .usr_rd_strb (qdr1_app_rd_en),
    .usr_rd_data (qdr1_app_rd_data),
    .usr_rd_dvld (qdr1_app_rd_dvld)
  );

  qdr_cpu_interface qdr1_cpu_interface(
    .wb_clk_i    (wb_clk_i),
    .wb_rst_i    (wb_rst_i),
    .wb_cyc_i    (wbs_cyc_o[QDR1_SLI]),
    .wb_stb_i    (wbs_stb_o[QDR1_SLI]),
    .wb_we_i     (wbs_we_o),
    .wb_sel_i    (wbs_sel_o),
    .wb_adr_i    (wbs_adr_o),
    .wb_dat_i    (wbs_dat_o),
    .wb_dat_o    (wbs_dat_i[(QDR1_SLI+1)*32-1:(QDR1_SLI)*32]),
    .wb_ack_o    (wbs_ack_i[QDR1_SLI]),
    .wb_err_o    (wbs_err_i[QDR1_SLI]),

    .qdr_clk     (qdr_clk0),
    .qdr_rst     (qdr_rst),

    .qdr_addr    (qdr1_app_addr),
    .qdr_wr_en   (qdr1_app_wr_en),
    .qdr_wr_data (qdr1_app_wr_data),
    .qdr_rd_en   (qdr1_app_rd_en),
    .qdr_rd_data (qdr1_app_rd_data),
    .qdr_rd_dvld (qdr1_app_rd_dvld),
    .phy_rdy     (qdr1_phy_rdy),
    .cal_fail    (qdr1_cal_fail)
  );

  /************************ QDR 2 ****************************/

  wire [31:0] qdr2_app_addr;
  wire        qdr2_app_wr_en;
  wire [71:0] qdr2_app_wr_data;
  wire        qdr2_app_rd_en;
  wire [71:0] qdr2_app_rd_data;
  wire        qdr2_app_rd_dvld;

  wire        qdr2_phy_rdy;
  wire        qdr2_cal_fail;
  
  qdr_controller_softcal #( 
    .DATA_WIDTH (36),
    .ADDR_WIDTH (21)
  ) qdr2_controller_inst (
    .wb_clk_i    (wb_clk_i),
    .wb_rst_i    (wb_rst_i),
    .wb_cyc_i    (wbs_cyc_o[QDR2CONF_SLI]),
    .wb_stb_i    (wbs_stb_o[QDR2CONF_SLI]),
    .wb_we_i     (wbs_we_o),
    .wb_sel_i    (wbs_sel_o),
    .wb_adr_i    (wbs_adr_o),
    .wb_dat_i    (wbs_dat_o),
    .wb_dat_o    (wbs_dat_i[(QDR2CONF_SLI+1)*32-1:(QDR2CONF_SLI)*32]),
    .wb_ack_o    (wbs_ack_i[QDR2CONF_SLI]),
    .wb_err_o    (wbs_err_i[QDR2CONF_SLI]),

    .qdr_k       (qdr2_k),
    .qdr_k_n     (qdr2_kn),
    .qdr_r_n     (qdr2_rdn),
    .qdr_w_n     (qdr2_wrn),
    .qdr_sa      (qdr2_a),
    .qdr_d       (qdr2_d),
    .qdr_doff_n  (qdr2_doffn),
    .qdr_q       (qdr2_q),

    .clk0        (qdr_clk0),
    .clk180      (qdr_clk180),
    .clk270      (qdr_clk270),
    .reset       (qdr_rst),

    .phy_rdy     (qdr2_phy_rdy),
    .cal_fail    (qdr2_cal_fail),

    .usr_addr    (qdr2_app_addr),
    .usr_wr_strb (qdr2_app_wr_en),
    .usr_wr_data (qdr2_app_wr_data),
    .usr_rd_strb (qdr2_app_rd_en),
    .usr_rd_data (qdr2_app_rd_data),
    .usr_rd_dvld (qdr2_app_rd_dvld)
  );

  qdr_cpu_interface qdr2_cpu_interface(
    .wb_clk_i    (wb_clk_i),
    .wb_rst_i    (wb_rst_i),
    .wb_cyc_i    (wbs_cyc_o[QDR2_SLI]),
    .wb_stb_i    (wbs_stb_o[QDR2_SLI]),
    .wb_we_i     (wbs_we_o),
    .wb_sel_i    (wbs_sel_o),
    .wb_adr_i    (wbs_adr_o),
    .wb_dat_i    (wbs_dat_o),
    .wb_dat_o    (wbs_dat_i[(QDR2_SLI+1)*32-1:(QDR2_SLI)*32]),
    .wb_ack_o    (wbs_ack_i[QDR2_SLI]),
    .wb_err_o    (wbs_err_i[QDR2_SLI]),

    .qdr_clk     (qdr_clk0),
    .qdr_rst     (qdr_rst),

    .qdr_addr    (qdr2_app_addr),
    .qdr_wr_en   (qdr2_app_wr_en),
    .qdr_wr_data (qdr2_app_wr_data),
    .qdr_rd_en   (qdr2_app_rd_en),
    .qdr_rd_data (qdr2_app_rd_data),
    .qdr_rd_dvld (qdr2_app_rd_dvld),
    .phy_rdy     (qdr2_phy_rdy),
    .cal_fail    (qdr2_cal_fail)
  );

  /************************ QDR 3 ****************************/

  wire [31:0] qdr3_app_addr;
  wire        qdr3_app_wr_en;
  wire [71:0] qdr3_app_wr_data;
  wire        qdr3_app_rd_en;
  wire [71:0] qdr3_app_rd_data;
  wire        qdr3_app_rd_dvld;

  wire        qdr3_phy_rdy;
  wire        qdr3_cal_fail;
  
  qdr_controller_softcal #( 
    .DATA_WIDTH (36),
    .ADDR_WIDTH (21)
  ) qdr3_controller_inst (
    .wb_clk_i    (wb_clk_i),
    .wb_rst_i    (wb_rst_i),
    .wb_cyc_i    (wbs_cyc_o[QDR3CONF_SLI]),
    .wb_stb_i    (wbs_stb_o[QDR3CONF_SLI]),
    .wb_we_i     (wbs_we_o),
    .wb_sel_i    (wbs_sel_o),
    .wb_adr_i    (wbs_adr_o),
    .wb_dat_i    (wbs_dat_o),
    .wb_dat_o    (wbs_dat_i[(QDR3CONF_SLI+1)*32-1:(QDR3CONF_SLI)*32]),
    .wb_ack_o    (wbs_ack_i[QDR3CONF_SLI]),
    .wb_err_o    (wbs_err_i[QDR3CONF_SLI]),

    .qdr_k       (qdr3_k),
    .qdr_k_n     (qdr3_kn),
    .qdr_r_n     (qdr3_rdn),
    .qdr_w_n     (qdr3_wrn),
    .qdr_sa      (qdr3_a),
    .qdr_d       (qdr3_d),
    .qdr_doff_n  (qdr3_doffn),
    .qdr_q       (qdr3_q),

    .clk0        (qdr_clk0),
    .clk180      (qdr_clk180),
    .clk270      (qdr_clk270),
    .reset       (qdr_rst),

    .phy_rdy     (qdr3_phy_rdy),
    .cal_fail    (qdr3_cal_fail),

    .usr_addr    (qdr3_app_addr),
    .usr_wr_strb (qdr3_app_wr_en),
    .usr_wr_data (qdr3_app_wr_data),
    .usr_rd_strb (qdr3_app_rd_en),
    .usr_rd_data (qdr3_app_rd_data),
    .usr_rd_dvld (qdr3_app_rd_dvld)
  );

  qdr_cpu_interface qdr3_cpu_interface(
    .wb_clk_i    (wb_clk_i),
    .wb_rst_i    (wb_rst_i),
    .wb_cyc_i    (wbs_cyc_o[QDR3_SLI]),
    .wb_stb_i    (wbs_stb_o[QDR3_SLI]),
    .wb_we_i     (wbs_we_o),
    .wb_sel_i    (wbs_sel_o),
    .wb_adr_i    (wbs_adr_o),
    .wb_dat_i    (wbs_dat_o),
    .wb_dat_o    (wbs_dat_i[(QDR3_SLI+1)*32-1:(QDR3_SLI)*32]),
    .wb_ack_o    (wbs_ack_i[QDR3_SLI]),
    .wb_err_o    (wbs_err_i[QDR3_SLI]),

    .qdr_clk     (qdr_clk0),
    .qdr_rst     (qdr_rst),

    .qdr_addr    (qdr3_app_addr),
    .qdr_wr_en   (qdr3_app_wr_en),
    .qdr_wr_data (qdr3_app_wr_data),
    .qdr_rd_en   (qdr3_app_rd_en),
    .qdr_rd_data (qdr3_app_rd_data),
    .qdr_rd_dvld (qdr3_app_rd_dvld),
    .phy_rdy     (qdr3_phy_rdy),
    .cal_fail    (qdr3_cal_fail)
  );

/*********** DRAM *************/

  wire ddr3_clk_mem;
  wire ddr3_clk_div2;
  wire ddr3_rst_div2;

  wire ddr3_pll_lock;

  clk_gen #(
    .CLK_FREQ (250)
  ) clk_gen_ddr3 (
    .clk_100  (sys_clk),
    .reset    (sys_rst),
    .clk0     (ddr3_clk_mem),
    .clk180   (),
    .clk270   (),
    .clkdiv2  (ddr3_clk_div2),
    .pll_lock (ddr3_pll_lock)
  );

  reg ddr3_rstR;
  reg ddr3_rstRR;

  always @(posedge ddr3_clk_div2) begin
    ddr3_rstR  <= sys_rst || !ddr3_pll_lock || !idelay_rdy;
    ddr3_rstRR <= ddr3_rstR;
  end
  assign ddr3_rst_div2 = ddr3_rstRR;

  wire             ddr3_phy_rdy;
  wire             ddr3_cal_fail;
  wire [144*2-1:0] ddr3_app_rd_data;
  wire             ddr3_app_rd_data_end;
  wire             ddr3_app_rd_data_valid;
  wire             ddr3_app_rdy;
  wire             ddr3_app_wdf_rdy;
  wire      [31:0] ddr3_app_addr;
  wire       [2:0] ddr3_app_cmd;
  wire             ddr3_app_en;
  wire [144*2-1:0] ddr3_app_wdf_data;
  wire             ddr3_app_wdf_end;
  wire  [18*2-1:0] ddr3_app_wdf_mask;
  wire             ddr3_app_wdf_wren;

  ddr3_controller #(
    .tCK           (4000),
    .RANK_WIDTH    (1),
    .BANK_WIDTH    (3),
    .CK_WIDTH      (1),
    .CKE_WIDTH     (1),
    .COL_WIDTH     (10),
    .CS_WIDTH      (1),
    .DM_WIDTH      (9),
    .DQ_WIDTH      (72),
    .DQS_WIDTH     (9),
    .ROW_WIDTH     (15),
    .tPRDI         (1_000_000),
    .tREFI         (7800000),
    .ZQI           (512),
    .ADDR_WIDTH    (29),
    .DATA_WIDTH    (72)
  ) ddr3_controller_inst (
    .clk_mem           (ddr3_clk_mem),
    .clk_div2          (ddr3_clk_div2),
    .rst_div2          (ddr3_rst_div2),

    .ddr3_dq           (ddr3_dq),
    .ddr3_addr         (ddr3_a),
    .ddr3_ba           (ddr3_ba),
    .ddr3_ras_n        (ddr3_rasn),
    .ddr3_cas_n        (ddr3_casn),
    .ddr3_we_n         (ddr3_wen),
    .ddr3_reset_n      (ddr3_resetn),
    .ddr3_cs_n         (ddr3_sn[0]),
    .ddr3_odt          (ddr3_odt[1:0]),
    .ddr3_cke          (ddr3_cke[1:0]),
    .ddr3_dm           (ddr3_dm),
    .ddr3_dqs_p        (ddr3_dqs_p),
    .ddr3_dqs_n        (ddr3_dqs_n),
    .ddr3_ck_p         (ddr3_ck_p),
    .ddr3_ck_n         (ddr3_ck_n),

    .phy_rdy           (ddr3_phy_rdy),
    .cal_fail          (ddr3_cal_fail),

    .app_rd_data       (ddr3_app_rd_data),
    .app_rd_data_end   (ddr3_app_rd_data_end),
    .app_rd_data_valid (ddr3_app_rd_data_valid),
    .app_rdy           (ddr3_app_rdy),
    .app_wdf_rdy       (ddr3_app_wdf_rdy),
    .app_addr          (ddr3_app_addr),
    .app_cmd           (ddr3_app_cmd),
    .app_en            (ddr3_app_en),
    .app_wdf_data      (ddr3_app_wdf_data),
    .app_wdf_end       (ddr3_app_wdf_end),
    .app_wdf_mask      (ddr3_app_wdf_mask),
    .app_wdf_wren      (ddr3_app_wdf_wren)
  );

  OBUF obuf_ddr3_sn[2:0](
    .I (3'b1),
    .O (ddr3_sn[3:1])
  );

  ddr3_cpu_interface ddr3_cpu_interface_inst(
    .wb_clk_i    (wb_clk_i),
    .wb_rst_i    (wb_rst_i),
    .wb_cyc_i    (wbs_cyc_o[DRAM_SLI]),
    .wb_stb_i    (wbs_stb_o[DRAM_SLI]),
    .wb_we_i     (wbs_we_o),
    .wb_sel_i    (wbs_sel_o),
    .wb_adr_i    (wbs_adr_o),
    .wb_dat_i    (wbs_dat_o),
    .wb_dat_o    (wbs_dat_i[(DRAM_SLI+1)*32-1:(DRAM_SLI)*32]),
    .wb_ack_o    (wbs_ack_i[DRAM_SLI]),
    .wb_err_o    (wbs_err_i[DRAM_SLI]),

    .ddr3_clk    (ddr3_clk_div2),
    .ddr3_rst    (ddr3_rst_div2),

    .phy_rdy     (ddr3_phy_rdy),
    .cal_fail    (ddr3_cal_fail),

    .app_rdy           (ddr3_app_rdy),
    .app_en            (ddr3_app_en),
    .app_cmd           (ddr3_app_cmd),
    .app_addr          (ddr3_app_addr),
    .app_wdf_data      (ddr3_app_wdf_data),
    .app_wdf_end       (ddr3_app_wdf_end),
    .app_wdf_mask      (ddr3_app_wdf_mask),
    .app_wdf_wren      (ddr3_app_wdf_wren),
    .app_wdf_rdy       (ddr3_app_wdf_rdy),
    .app_rd_data       (ddr3_app_rd_data),
    .app_rd_data_end   (ddr3_app_rd_data_end),
    .app_rd_data_valid (ddr3_app_rd_data_valid)
  );
  
//
//wire [11:0] gpio_bufi;
//wire [11:0] gpio_bufo;
//wire [11:0] gpio_bufoen;
//
//IOBUF #(
//  .IOSTANDARD("LVCMOS15")
//) IOBUF_gpio[11:0] (
//  .IO (v6_gpio),
//  .I  (gpio_bufo),
//  .O  (gpio_bufi),
//  .T  (gpio_bufoen)
//);
//assign gpio_bufo   = {6{aux_clk}} | gpio_bufi;
//assign gpio_bufoen = {6{sys_clk}} | gpio_bufi;
//
///*************** PPC Signals ****************/
//wire ppc_perclk_buf;
//IBUFG #(
//  .IOSTANDARD("LVCMOS25")
//) IBUFG_ppc_perclk (
//  .I (ppc_perclk),
//  .O (ppc_perclk_buf)
//);
//
//wire [5:29] ppc_paddr_buf;
//IBUF #(
//  .IOSTANDARD("LVCMOS25")
//) IBUF_ppc_paddr[5:29] (
//  .I (ppc_paddr),
//  .O (ppc_paddr_buf)
//);
//
//wire [1:0] ppc_pcsn_buf;
//IBUF #(
//  .IOSTANDARD("LVCMOS25")
//) IBUF_ppc_pcsn[1:0] (
//  .I (ppc_pcsn),
//  .O (ppc_pcsn_buf)
//);
//
//wire [0:31] ppc_pdata_bufi;
//wire [0:31] ppc_pdata_bufo;
//wire [0:31] ppc_pdata_oen;
//
//IOBUF #(
//  .IOSTANDARD("LVCMOS25")
//) IOBUF_ppc_pdata[0:31] (
//  .IO (ppc_pdata),
//  .I (ppc_pdata_bufo),
//  .O (ppc_pdata_bufi),
//  .T (ppc_pdata_oen)
//);
//
//wire [0:3] ppc_pben_buf;
//IBUF #(
//  .IOSTANDARD("LVCMOS25")
//) IBUF_ppc_pben[0:3] (
//  .I (ppc_pben),
//  .O (ppc_pben_buf)
//);
//
//wire ppc_poen_buf;
//IBUF #(
//  .IOSTANDARD("LVCMOS25")
//) IBUF_ppc_poen (
//  .I (ppc_poen),
//  .O (ppc_poen_buf)
//);
//
//wire ppc_pwrn_buf;
//IBUF #(
//  .IOSTANDARD("LVCMOS25")
//) IBUF_ppc_pwrn (
//  .I (ppc_pwrn),
//  .O (ppc_pwrn_buf)
//);
//
//wire ppc_pblastn_buf;
//IBUF #(
//  .IOSTANDARD("LVCMOS25")
//) IBUF_ppc_pblastn (
//  .I (ppc_pblastn),
//  .O (ppc_pblastn_buf)
//);
//
//wire ppc_prdy_buf;
//OBUF #(
//  .IOSTANDARD("LVCMOS25")
//) OBUF_ppc_prdy (
//  .O (ppc_prdy),
//  .I (ppc_prdy_buf)
//);
//
//wire ppc_doen_buf;
//OBUF #(
//  .IOSTANDARD("LVCMOS15")
//) OBUF_ppc_doen (
//  .O (ppc_doen),
//  .I (ppc_doen_buf)
//);
//
//wire ppc_irqn_buf;
//OBUF #(
//  .IOSTANDARD("LVCMOS25")
//) OBUF_ppc_irqn (
//  .O (ppc_irqn),
//  .I (ppc_irqn_buf)
//);
//
//assign ppc_pdata_bufo = ppc_pdata_bufi;
//assign ppc_pdata_oen  = {ppc_paddr_buf, ppc_pcsn_buf, ppc_pben_buf, ppc_poen_buf};
//assign ppc_prdy_buf = ppc_pblastn_buf;
//assign ppc_doen_buf = ppc_pwrn_buf;
//assign ppc_irqn_buf = ppc_perclk_buf;
//
///******************* ZDOKs ********************/
//
//wire [1:0] zdok0_clk;
//IBUFGDS #(
//  .IOSTANDARD("LVDS_25"),
//  .DIFF_TERM("TRUE")
//) IBUFGDS_zdok0_clk[1:0] (
//  .I  ({zdok0_clk0_p, zdok0_clk1_p}),
//  .IB ({zdok0_clk0_n, zdok0_clk1_n}),
//  .O  (zdok0_clk)
//);
//
//wire [37:0] zdok0_dp;
//IBUFDS #(
//  .IOSTANDARD("LVDS_25"),
//  .DIFF_TERM("TRUE")
//) IBUFDS_zdok0_dp[37:0] (
//  .I  (zdok0_dp_p),
//  .IB (zdok0_dp_n),
//  .O  (zdok0_dp)
//);
//
//wire [1:0] zdok1_clk;
//OBUFDS #(
//  .IOSTANDARD("LVDS_25")
//) OBUFDS_zdok1_clk[1:0] (
//  .O  ({zdok1_clk0_p, zdok1_clk1_p}),
//  .OB ({zdok1_clk0_n, zdok1_clk1_n}),
//  .I  (zdok0_clk)
//);
//
//wire [37:0] zdok1_dp;
//OBUFDS #(
//  .IOSTANDARD("LVDS_25")
//) OBUFDS_zdok1_dp[37:0] (
//  .O  (zdok1_dp_p),
//  .OB (zdok1_dp_n),
//  .I  (zdok0_dp)
//);
//
///* qdr 1 */
//
//wire qdr1_k_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr1_k (
//  .I (qdr1_k_buf),
//  .O (qdr1_k)
//);
//
//wire qdr1_kn_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr1_kn (
//  .I (qdr1_kn_buf),
//  .O (qdr1_kn)
//);
//
//wire qdr1_rdn_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr1_rdn (
//  .I (qdr1_rdn_buf),
//  .O (qdr1_rdn)
//);
//
//wire qdr1_wrn_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr1_wrn (
//  .I (qdr1_wrn_buf),
//  .O (qdr1_wrn)
//);
//
//wire [20:0] qdr1_a_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr1_a[20:0] (
//  .I (qdr1_a_buf),
//  .O (qdr1_a)
//);
//
//wire [35:0] qdr1_d_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr1_d[35:0] (
//  .I (qdr1_d_buf),
//  .O (qdr1_d)
//);
//
//wire qdr1_doffn_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr1_doffn (
//  .I (qdr1_doffn_buf),
//  .O (qdr1_doffn)
//);
//
//wire [35:0] qdr1_q_buf;
//IBUF #(
//  .IOSTANDARD("HSTL_I_DCI")
//) IBUF_qdr1_q[35:0] (
//  .I (qdr1_q),
//  .O (qdr1_q_buf)
//);
//assign qdr1_d_buf     = qdr1_q_buf;
//assign qdr1_a_buf     = qdr1_q_buf[20:0];
//assign qdr1_doffn_buf = qdr1_q_buf[0];
//assign qdr1_wrn_buf   = qdr1_q_buf[0];
//assign qdr1_rdn_buf   = qdr1_q_buf[0];
//assign qdr1_k_buf     = qdr1_q_buf[0];
//assign qdr1_kn_buf    = qdr1_q_buf[0];
//
///* qdr2 */
//
//wire qdr2_k_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr2_k (
//  .I (qdr2_k_buf),
//  .O (qdr2_k)
//);
//
//wire qdr2_kn_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr2_kn (
//  .I (qdr2_kn_buf),
//  .O (qdr2_kn)
//);
//
//wire qdr2_rdn_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr2_rdn (
//  .I (qdr2_rdn_buf),
//  .O (qdr2_rdn)
//);
//
//wire qdr2_wrn_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr2_wrn (
//  .I (qdr2_wrn_buf),
//  .O (qdr2_wrn)
//);
//
//wire [20:0] qdr2_a_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr2_a[20:0] (
//  .I (qdr2_a_buf),
//  .O (qdr2_a)
//);
//
//wire [35:0] qdr2_d_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr2_d[35:0] (
//  .I (qdr2_d_buf),
//  .O (qdr2_d)
//);
//
//wire qdr2_doffn_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr2_doffn (
//  .I (qdr2_doffn_buf),
//  .O (qdr2_doffn)
//);
//
//wire [35:0] qdr2_q_buf;
//IBUF #(
//  .IOSTANDARD("HSTL_I_DCI")
//) IBUF_qdr2_q[35:0] (
//  .I (qdr2_q),
//  .O (qdr2_q_buf)
//);
//assign qdr2_d_buf     = qdr2_q_buf;
//assign qdr2_a_buf     = qdr2_q_buf[20:0];
//assign qdr2_doffn_buf = qdr2_q_buf[0];
//assign qdr2_wrn_buf   = qdr2_q_buf[0];
//assign qdr2_rdn_buf   = qdr2_q_buf[0];
//assign qdr2_k_buf     = qdr2_q_buf[0];
//assign qdr2_kn_buf    = qdr2_q_buf[0];
//
///* qdr 3 */
//
//wire qdr3_k_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr3_k (
//  .I (qdr3_k_buf),
//  .O (qdr3_k)
//);
//
//wire qdr3_kn_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr3_kn (
//  .I (qdr3_kn_buf),
//  .O (qdr3_kn)
//);
//
//wire qdr3_rdn_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr3_rdn (
//  .I (qdr3_rdn_buf),
//  .O (qdr3_rdn)
//);
//
//wire qdr3_wrn_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr3_wrn (
//  .I (qdr3_wrn_buf),
//  .O (qdr3_wrn)
//);
//
//wire [20:0] qdr3_a_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr3_a[20:0] (
//  .I (qdr3_a_buf),
//  .O (qdr3_a)
//);
//
//wire [35:0] qdr3_d_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr3_d[35:0] (
//  .I (qdr3_d_buf),
//  .O (qdr3_d)
//);
//
//wire qdr3_doffn_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr3_doffn (
//  .I (qdr3_doffn_buf),
//  .O (qdr3_doffn)
//);
//
//wire [35:0] qdr3_q_buf;
//IBUF #(
//  .IOSTANDARD("HSTL_I_DCI")
//) IBUF_qdr3_q[35:0] (
//  .I (qdr3_q),
//  .O (qdr3_q_buf)
//);
//assign qdr3_d_buf     = qdr3_q_buf;
//assign qdr3_a_buf     = qdr3_q_buf[20:0];
//assign qdr3_doffn_buf = qdr3_q_buf[0];
//assign qdr3_wrn_buf   = qdr3_q_buf[0];
//assign qdr3_rdn_buf   = qdr3_q_buf[0];
//assign qdr3_k_buf     = qdr3_q_buf[0];
//assign qdr3_kn_buf    = qdr3_q_buf[0];
//

///*********** MGT GPIO ************/
//wire [11:0] mgt_gpio_bufi;
//wire [11:0] mgt_gpio_bufo;
//wire [11:0] mgt_gpio_bufoen;
//
//IOBUF #(
//  .IOSTANDARD("LVCMOS15")
//) IOBUF_mgt_gpio[11:0] (
//  .IO (mgt_gpio),
//  .I  (mgt_gpio_bufo),
//  .O  (mgt_gpio_bufi),
//  .T  (mgt_gpio_bufoen)
//);
//assign mgt_gpio_bufo   = mgt_gpio_bufi;
//assign mgt_gpio_bufoen = mgt_gpio_bufi;
//
///*********** MGTs ************/
//
//localparam XAUI_CLK  = 0;
//localparam MISC_CLK  = 1;
//localparam MEZZ_CLK0 = 2;
//localparam MEZZ_CLK1 = 3;
//
//localparam GTX_CLK_SRC = XAUI_CLK;
//
//wire xaui_clkref_0;
//wire misc_clkref_0;
//wire xaui_clkref_1;
//wire misc_clkref_1;
//wire misc_clkref_2;
//wire xaui_clkref_2;
//
//wire ext_refclk7;
//wire ext_refclk6;
//wire ext_refclk5;
//wire ext_refclk4;
//wire ext_refclk3;
//wire ext_refclk2;
//wire ext_refclk1;
//wire ext_refclk0;
//
//gtx_skeleton gtx_quad_110(
//  .rx_n         (mgt_rx_n[3:0]),
//  .rx_p         (mgt_rx_p[3:0]),
//  .tx_n         (mgt_tx_n[3:0]),
//  .tx_p         (mgt_tx_p[3:0]),
//
//  .mgtrefclk0_n (ext_refclk_n[3]),
//  .mgtrefclk0_p (ext_refclk_p[3]),
//  .mgtrefclk1_n (ext_refclk_n[7]),
//  .mgtrefclk1_p (ext_refclk_p[7]),
//  .refclk_o_0   (ext_refclk3),
//  .refclk_o_1   (ext_refclk7),
//  
//  .refclk_i     (
//                  GTX_CLK_SRC == MISC_CLK  ? misc_clkref_0 :
//                  GTX_CLK_SRC == MEZZ_CLK0 ? ext_refclk3 :
//                  GTX_CLK_SRC == MEZZ_CLK1 ? ext_refclk7 :
//                                             xaui_clkref_0
//                 )
//);
//
//gtx_skeleton gtx_quad_111(
//  .rx_n         (mgt_rx_n[7:4]),
//  .rx_p         (mgt_rx_p[7:4]),
//  .tx_n         (mgt_tx_n[7:4]),
//  .tx_p         (mgt_tx_p[7:4]),
//
//  .mgtrefclk0_n (xaui_clkref_n[0]),
//  .mgtrefclk0_p (xaui_clkref_p[0]),
//  .mgtrefclk1_n (misc_clkref_n[0]),
//  .mgtrefclk1_p (misc_clkref_p[0]),
//  .refclk_o_0   (xaui_clkref_0),
//  .refclk_o_1   (misc_clkref_0),
//  
//  .refclk_i     (
//                  GTX_CLK_SRC == MISC_CLK  ? misc_clkref_0 :
//                  GTX_CLK_SRC == MEZZ_CLK0 ? ext_refclk3 :
//                  GTX_CLK_SRC == MEZZ_CLK1 ? ext_refclk7 :
//                                             xaui_clkref_0
//                 )
//);
//
//gtx_skeleton gtx_quad_112(
//  .rx_n         (mgt_rx_n[11:8]),
//  .rx_p         (mgt_rx_p[11:8]),
//  .tx_n         (mgt_tx_n[11:8]),
//  .tx_p         (mgt_tx_p[11:8]),
//
//  .mgtrefclk0_n (ext_refclk_n[2]),
//  .mgtrefclk0_p (ext_refclk_p[2]),
//  .mgtrefclk1_n (ext_refclk_n[6]),
//  .mgtrefclk1_p (ext_refclk_p[6]),
//  .refclk_o_0   (ext_refclk2),
//  .refclk_o_1   (ext_refclk6),
//  
//  .refclk_i     (
//                  GTX_CLK_SRC == MISC_CLK  ? misc_clkref_0 :
//                  GTX_CLK_SRC == MEZZ_CLK0 ? ext_refclk2 :
//                  GTX_CLK_SRC == MEZZ_CLK1 ? ext_refclk6 :
//                                             xaui_clkref_0
//                 )
//);
//
//gtx_skeleton gtx_quad_113(
//  .rx_n         (mgt_rx_n[15:12]),
//  .rx_p         (mgt_rx_p[15:12]),
//  .tx_n         (mgt_tx_n[15:12]),
//  .tx_p         (mgt_tx_p[15:12]),
//
//  .mgtrefclk0_n (xaui_clkref_n[1]),
//  .mgtrefclk0_p (xaui_clkref_p[1]),
//  .mgtrefclk1_n (misc_clkref_n[1]),
//  .mgtrefclk1_p (misc_clkref_p[1]),
//  .refclk_o_0   (xaui_clkref_1),
//  .refclk_o_1   (misc_clkref_1),
//  
//  .refclk_i     (
//                  GTX_CLK_SRC == MISC_CLK  ? misc_clkref_1 :
//                  GTX_CLK_SRC == MEZZ_CLK0 ? ext_refclk2 :
//                  GTX_CLK_SRC == MEZZ_CLK1 ? ext_refclk6 :
//                                             xaui_clkref_1
//                 )
//);
//
//gtx_skeleton gtx_quad_114(
//  .rx_n         (mgt_rx_n[19:16]),
//  .rx_p         (mgt_rx_p[19:16]),
//  .tx_n         (mgt_tx_n[19:16]),
//  .tx_p         (mgt_tx_p[19:16]),
//
//  .mgtrefclk0_n (ext_refclk_n[1]),
//  .mgtrefclk0_p (ext_refclk_p[1]),
//  .mgtrefclk1_n (ext_refclk_n[5]),
//  .mgtrefclk1_p (ext_refclk_p[5]),
//  .refclk_o_0   (ext_refclk1),
//  .refclk_o_1   (ext_refclk5),
//  
//  .refclk_i     (
//                  GTX_CLK_SRC == MISC_CLK  ? misc_clkref_1 :
//                  GTX_CLK_SRC == MEZZ_CLK0 ? ext_refclk1 :
//                  GTX_CLK_SRC == MEZZ_CLK1 ? ext_refclk5 :
//                                             xaui_clkref_1
//                 )
//);
//
//gtx_skeleton gtx_quad_115(
//  .rx_n         (mgt_rx_n[23:20]),
//  .rx_p         (mgt_rx_p[23:20]),
//  .tx_n         (mgt_tx_n[23:20]),
//  .tx_p         (mgt_tx_p[23:20]),
//
//  .mgtrefclk0_n (),
//  .mgtrefclk0_p (),
//  .mgtrefclk1_n (),
//  .mgtrefclk1_p (),
//  .refclk_o_0   (),
//  .refclk_o_1   (),
//  
//  .refclk_i     (
//                  GTX_CLK_SRC == MISC_CLK  ? misc_clkref_2 :
//                  GTX_CLK_SRC == MEZZ_CLK0 ? ext_refclk1 :
//                  GTX_CLK_SRC == MEZZ_CLK1 ? ext_refclk5 :
//                                             xaui_clkref_2
//                 )
//);
//
//gtx_skeleton gtx_quad_116(
//  .rx_n         (mgt_rx_n[27:24]),
//  .rx_p         (mgt_rx_p[27:24]),
//  .tx_n         (mgt_tx_n[27:24]),
//  .tx_p         (mgt_tx_p[27:24]),
//
//  .mgtrefclk0_n (xaui_clkref_n[2]),
//  .mgtrefclk0_p (xaui_clkref_p[2]),
//  .mgtrefclk1_n (misc_clkref_n[2]),
//  .mgtrefclk1_p (misc_clkref_p[2]),
//  .refclk_o_0   (xaui_clkref_2),
//  .refclk_o_1   (misc_clkref_2),
//  
//  .refclk_i     (
//                  GTX_CLK_SRC == MISC_CLK  ? misc_clkref_2 :
//                  GTX_CLK_SRC == MEZZ_CLK0 ? ext_refclk0 :
//                  GTX_CLK_SRC == MEZZ_CLK1 ? ext_refclk4 :
//                                             xaui_clkref_2
//                 )
//);
//
//gtx_skeleton gtx_quad_117(
//  .rx_n         (mgt_rx_n[31:28]),
//  .rx_p         (mgt_rx_p[31:28]),
//  .tx_n         (mgt_tx_n[31:28]),
//  .tx_p         (mgt_tx_p[31:28]),
//
//  .mgtrefclk0_n (ext_refclk_n[0]),
//  .mgtrefclk0_p (ext_refclk_p[0]),
//  .mgtrefclk1_n (ext_refclk_n[4]),
//  .mgtrefclk1_p (ext_refclk_p[4]),
//  .refclk_o_0   (ext_refclk0),
//  .refclk_o_1   (ext_refclk4),
//  
//  .refclk_i     (
//                  GTX_CLK_SRC == MISC_CLK  ? misc_clkref_2 :
//                  GTX_CLK_SRC == MEZZ_CLK0 ? ext_refclk0 :
//                  GTX_CLK_SRC == MEZZ_CLK1 ? ext_refclk4 :
//                                             xaui_clkref_2
//                 )
//);
  
  /********* SGMII PHY ************/
  
  reg sgmii_reset_R;
  reg sgmii_reset_RR;
  always @(posedge clk_125) begin
    sgmii_reset_R  <= sys_rst;
    sgmii_reset_RR <= sgmii_reset_R;
  end
  wire sgmii_reset = sgmii_reset_RR;
  
  wire       recclk_125;

  wire [7:0] sgmii_txd;
  wire       sgmii_txisk;
  wire       sgmii_txdispmode;
  wire       sgmii_txdispval;
  wire [1:0] sgmii_txbufstatus;
  wire       sgmii_txreset;
  
  wire [7:0] sgmii_rxd;
  wire       sgmii_rxiscomma;
  wire       sgmii_rxisk;
  wire       sgmii_rxdisperr;
  wire       sgmii_rxnotintable;
  wire       sgmii_rxrundisp;
  wire [2:0] sgmii_rxclkcorcnt;
  wire [2:0] sgmii_rxbufstatus;
  wire       sgmii_rxreset;
  
  wire       sgmii_encommaalign;
  wire       sgmii_pll_locked;
  wire       sgmii_elecidle;
  
  wire       sgmii_resetdone;
  
  wire       sgmii_loopback;
  wire       sgmii_powerdown;
  
  sgmii_phy sgmii_phy_inst (
    .mgt_rx_n           (sgmii_rx_n),
    .mgt_rx_p           (sgmii_rx_p),
    .mgt_tx_n           (sgmii_tx_n),
    .mgt_tx_p           (sgmii_tx_p),
    .mgt_clk_n          (sgmii_clkref_n),
    .mgt_clk_p          (sgmii_clkref_p),
  
    .mgt_reset          (sgmii_reset),
  
    .clk_125            (clk_125),
    .recclk_125         (recclk_125),
  
    .sgmii_txd          (sgmii_txd),
    .sgmii_txisk        (sgmii_txisk),
    .sgmii_txdispmode   (sgmii_txdispmode),
    .sgmii_txdispval    (sgmii_txdispval),
    .sgmii_txbufstatus  (sgmii_txbufstatus),
    .sgmii_txreset      (sgmii_txreset),
  
    .sgmii_rxd          (sgmii_rxd),
    .sgmii_rxiscomma    (sgmii_rxiscomma),
    .sgmii_rxisk        (sgmii_rxisk),
    .sgmii_rxdisperr    (sgmii_rxdisperr),
    .sgmii_rxnotintable (sgmii_rxnotintable),
    .sgmii_rxrundisp    (sgmii_rxrundisp),
    .sgmii_rxclkcorcnt  (sgmii_rxclkcorcnt),
    .sgmii_rxbufstatus  (sgmii_rxbufstatus),
    .sgmii_rxreset      (sgmii_rxreset),
  
    .sgmii_encommaalign (sgmii_encommaalign),
    .sgmii_pll_locked   (sgmii_pll_locked),
    .sgmii_elecidle     (sgmii_elecidle),
    .sgmii_resetdone    (sgmii_resetdone),
  
    .sgmii_loopback     (1'b0),
    .sgmii_powerdown    (1'b0)
  );

  // MAC interface
  wire       mac_rx_clk;
  wire [7:0] mac_rx_data;
  wire       mac_rx_dvld;
  wire       mac_rx_goodframe;
  wire       mac_rx_badframe;
  
  wire       mac_tx_clk;
  wire [7:0] mac_tx_data;
  wire       mac_tx_dvld;
  wire       mac_tx_ack;

  temac #(
    .REG_SGMII (0),
    .PHY_ADR   (4'b0000)
  ) temac_inst (
    .clk_125            (clk_125),
    .reset              (sgmii_reset),
    .sgmii_txd          (sgmii_txd),
    .sgmii_txisk        (sgmii_txisk),
    .sgmii_txdispmode   (sgmii_txdispmode),
    .sgmii_txdispval    (sgmii_txdispval),
    .sgmii_txbuferr     (sgmii_txbufstatus[1]),
    .sgmii_txreset      (sgmii_txreset),
  
    .sgmii_rxd          (sgmii_rxd),
    .sgmii_rxiscomma    (sgmii_rxiscomma),
    .sgmii_rxisk        (sgmii_rxisk),
    .sgmii_rxdisperr    (sgmii_rxdisperr),
    .sgmii_rxnotintable (sgmii_rxnotintable),
    .sgmii_rxrundisp    (sgmii_rxrundisp),
    .sgmii_rxclkcorcnt  (sgmii_rxclkcorcnt),
    .sgmii_rxbufstatus  (sgmii_rxbufstatus[2]),
    .sgmii_rxreset      (sgmii_rxreset),
    
    .sgmii_encommaalign (sgmii_encommaalign),
    .sgmii_pll_locked   (sgmii_pll_locked),
    .sgmii_elecidle     (sgmii_elecidle),
  
    .sgmii_resetdone    (sgmii_resetdone),
  
    .sgmii_loopback     (sgmii_loopback),
    .sgmii_powerdown    (sgmii_powerdown),
  
    .mac_rx_clk         (mac_rx_clk),
    .mac_rx_data        (mac_rx_data),
    .mac_rx_dvld        (mac_rx_dvld),
    .mac_rx_goodframe   (mac_rx_goodframe),
    .mac_rx_badframe    (mac_rx_badframe),
  
    .mac_tx_clk         (mac_tx_clk),
    .mac_tx_data        (mac_tx_data),
    .mac_tx_dvld        (mac_tx_dvld),
    .mac_tx_ack         (mac_tx_ack),
    .mac_syncacquired   (mac_syncacquired)
  );

  assign mac_tx_data = mac_rx_data;
  assign mac_tx_dvld = mac_rx_dvld;

  /*

  assign debug_regin_0 = {3'b0, mac_syncacquired,  1'b0, sgmii_rxclkcorcnt, 3'b0, sgmii_reset, 3'b0, sgmii_pll_locked, 3'b0, sgmii_encommaalign, 3'b0, sgmii_resetdone, 3'b0, sgmii_txbufstatus[1], 3'b0, sgmii_rxbufstatus[2]};
  //10010100


  assign debug_clk = clk_125;

  reg [31:0] foo0;
  reg [31:0] foo1;
  reg [31:0] foo2;
  reg [31:0] foo3;
  reg [31:0] foo4;
  reg [31:0] foo5;
  reg [31:0] foo6;

  reg prev_dvld;

  always @(posedge mac_rx_clk) begin
    prev_dvld <= mac_rx_dvld;

    if (mac_rx_goodframe)
      foo0[15:0] <= foo0[15:0] + 1;
    if (mac_rx_badframe)
      foo0[31:16] <= foo0[31:16] + 1;

    if (mac_rx_dvld)
      foo1[15:0] <= foo1[15:0] + 1;
    if (mac_rx_dvld && !prev_dvld)
      foo1[15:0] <= 0;
  end

  always @(posedge clk_125) begin
      
    if (sgmii_rxiscomma) 
      foo3[7:0] <= foo3[7:0] + 1;
    if (sgmii_rxisk) 
      foo3[15:8] <= foo3[15:8] + 1;
    if (!sgmii_rxisk) 
      foo3[23:16] <= foo3[23:16] + 1;
    if (sgmii_rxdisperr) 
      foo3[31:24] <= foo3[31:24] + 1;

    if (sgmii_rxd != 8'b1011_1100) begin
      if (sgmii_rxisk) 
        foo4[15:0] <= foo4[15:0] + 1;
    end

    if (sgmii_rxisk) 
      foo4[31:24] <= sgmii_rxd;

    if (!sgmii_rxisk) 
      foo4[23:16] <= sgmii_rxd;

    if (sgmii_rxclkcorcnt == 3'b001  ||
        sgmii_rxclkcorcnt == 3'b010  ||
        sgmii_rxclkcorcnt == 3'b011  ||
        sgmii_rxclkcorcnt == 3'b100) 
      foo5[15:0] <= foo5[15:0] + 1;

    if (sgmii_rxclkcorcnt == 3'b111 || sgmii_rxclkcorcnt == 3'b110) 
      foo5[31:16] <= foo5[31:16] + 1;

    if (sgmii_rxbufstatus[2]) 
      foo6 <= foo6 + 1;
  end

  assign debug_regin_1 = foo0;
  assign debug_regin_2 = foo1;
  assign debug_regin_3 = foo2;
  assign debug_regin_4 = foo3;
  assign debug_regin_5 = foo4;
  assign debug_regin_6 = foo5;
  assign debug_regin_7 = foo6;


  reg [26:0] tx_counter;
  reg [1:0] state;
  always @(posedge mac_tx_clk) begin
    tx_counter <= tx_counter + 1;
    if (sgmii_reset) begin
      state <= 0;
      tx_counter <= 0;
    end else begin
      case (state) 
        0: begin
          if (mac_tx_ack) begin
            state <= 1;
          end else begin
            tx_counter <= 0;
          end
        end
        1: begin
          if (tx_counter == 27'd256) begin
            state <= 2;
          end
        end
        2: begin
          if (tx_counter == {27{1'b1}}) begin
            state <= 0;
          end
        end
        default: begin
          state <= 2;
        end
      endcase
    end
  end

  assign mac_tx_dvld = state == 0 || state == 1;
  assign mac_tx_data = tx_counter[7:0];
  */


endmodule
