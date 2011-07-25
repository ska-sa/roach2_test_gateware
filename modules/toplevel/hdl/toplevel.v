`include "build_parameters.v"
`include "parameters.v"
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

`ifdef REV0
    inout   [11:0] v6_gpio,
`else
    inout   [15:0] v6_gpio,
`endif

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
    input    [7:0] ext_refclk_p,
    input    [7:0] ext_refclk_n,
    */

    input          sgmii_rx_n,
    input          sgmii_rx_p,
    output         sgmii_tx_n,
    output         sgmii_tx_p,
    input          sgmii_clkref_n,
    input          sgmii_clkref_p,

    inout   [11:0] mgt_gpio,

    output  [31:0] mgt_tx_n,
    output  [31:0] mgt_tx_p,
    input   [31:0] mgt_rx_n,
    input   [31:0] mgt_rx_p,

    input    [2:0] xaui_refclk_n,
    input    [2:0] xaui_refclk_p
  );
  
  wire clk_200;
  wire clk_125;
  wire clk_100;

  wire rst_200;
  wire rst_125;
  wire rst_100;

  wire idelay_rdy;

  infrastructure infrastructure_inst (
    .sys_clk_buf_n  (sys_clk_n),
    .sys_clk_buf_p  (sys_clk_p),
    .sys_clk0       (clk_100),
    .sys_clk180     (),
    .sys_clk270     (),
    .clk_200        (clk_200),
    .sys_rst        (rst_100),
    .idelay_rdy     (idelay_rdy)
  );

  reg rst_200R;
  reg rst_200RR;

  always @(posedge clk_200) begin
    rst_200R  <= rst_100;
    rst_200RR <= rst_200R;
  end
  assign rst_200 = rst_200RR;


  wire [2:0] knight_rider_speed;

  knight_rider knight_rider_inst(
    .clk  (clk_100),
    .rst  (rst_100),
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

  reg [9:0] sync_counter;

  always @(posedge clk_100) begin
    sync_counter <= sync_counter + 10'd1;
  end

  assign aux_synco = sync_counter == 10'b0;

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

  wire ppc_prdy_int;

  reg epb_rstR;
  reg epb_rstRR;

  always @(posedge epb_clk) begin
    epb_rstR  <= rst_100;
    epb_rstRR <= epb_rstR;
  end

  assign wb_clk_i = epb_clk;
  assign wb_rst_i = epb_rstRR;

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
    .epb_rdy       (ppc_prdy_int),
    .epb_doen      (ppc_doen)
  );
  assign ppc_prdy = !ppc_pcsn[0] ? ppc_prdy_int : 1'b1;

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

  sys_block #(
    .BOARD_ID (`BOARD_ID),
    .REV_MAJ  (`REV_MAJOR),
    .REV_MIN  (`REV_MINOR),
    .REV_RCS  (`RCS_UPTODATE ? `REV_RCS : 32'b0)
  ) sys_block_inst (
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

  assign debug_clk = clk_100;

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
  // synthesis attribute KEEP of qdr_clk0 is TRUE
  wire qdr_clk180;
  wire qdr_clk270;

  wire qdr_pll_lock;

  clk_gen #(
    .CLK_FREQ (266)
  ) clk_gen_qdr (
    .clk_100  (clk_100),
    .reset    (rst_100),
    .clk0     (qdr_clk0),
    .clk180   (qdr_clk180),
    .clk270   (qdr_clk270),
    .clkdiv2  (),
    .pll_lock (qdr_pll_lock)
  );

  reg qdr_rstR;
  reg qdr_rstRR;

  reg qdr0_rst;
  reg qdr1_rst;
  reg qdr2_rst;
  reg qdr3_rst;
  //synthesis attribute equivalent_register_removal of qdr0_rst is no
  //synthesis attribute equivalent_register_removal of qdr1_rst is no
  //synthesis attribute equivalent_register_removal of qdr2_rst is no
  //synthesis attribute equivalent_register_removal of qdr3_rst is no

  always @(posedge qdr_clk0) begin
    //qdr_rstR  <= rst_100 || !idelay_rdy;
    qdr_rstR  <= !qdr_pll_lock || !idelay_rdy;
    qdr_rstRR <= qdr_rstR;
    qdr0_rst  <= qdr_rstRR;
    qdr1_rst  <= qdr_rstRR;
    qdr2_rst  <= qdr_rstRR;
    qdr3_rst  <= qdr_rstRR;
  end

  /************************ QDR 0 ****************************/

`ifdef ENABLE_QDR
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
    .reset       (qdr0_rst),

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
    .qdr_rst     (qdr0_rst),

    .qdr_addr    (qdr0_app_addr),
    .qdr_wr_en   (qdr0_app_wr_en),
    .qdr_wr_data (qdr0_app_wr_data),
    .qdr_rd_en   (qdr0_app_rd_en),
    .qdr_rd_data (qdr0_app_rd_data),
    .qdr_rd_dvld (qdr0_app_rd_dvld),
    .phy_rdy     (qdr0_phy_rdy),
    .cal_fail    (qdr0_cal_fail)
  );
`else
  OBUF #(
    .IOSTANDARD("LVCMOS15")
  ) qdr0_obuf [61:0] (
    .I (62'b0),
    .O ({qdr0_k, qdr0_kn, qdr0_rdn, qdr0_wrn, qdr0_a, qdr0_d, qdr0_doffn})
  );

  wire [35:0] qdr0_q_noreduce;
  //synthesis attribute NOREDUCE of qdr0_q_noreduce is TRUE
  IBUF #(
    .IOSTANDARD("LVCMOS15")
  ) qdr0_ibuf [35:0] (
    .I (qdr0_q),
    .O (qdr0_q_noreduce)
  );
`endif

  /************************ QDR 1 ****************************/

`ifdef ENABLE_QDR
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
    .reset       (qdr1_rst),

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
    .qdr_rst     (qdr1_rst),

    .qdr_addr    (qdr1_app_addr),
    .qdr_wr_en   (qdr1_app_wr_en),
    .qdr_wr_data (qdr1_app_wr_data),
    .qdr_rd_en   (qdr1_app_rd_en),
    .qdr_rd_data (qdr1_app_rd_data),
    .qdr_rd_dvld (qdr1_app_rd_dvld),
    .phy_rdy     (qdr1_phy_rdy),
    .cal_fail    (qdr1_cal_fail)
  );
`else
  OBUF #(
    .IOSTANDARD("LVCMOS15")
  ) qdr1_obuf [61:0] (
    .I (62'b0),
    .O ({qdr1_k, qdr1_kn, qdr1_rdn, qdr1_wrn, qdr1_a, qdr1_d, qdr1_doffn})
  );

  wire [35:0] qdr1_q_noreduce;
  //synthesis attribute NOREDUCE of qdr1_q_noreduce is TRUE
  IBUF #(
    .IOSTANDARD("LVCMOS15")
  ) qdr1_ibuf [35:0] (
    .I (qdr1_q),
    .O (qdr1_q_noreduce)
  );
`endif

  /************************ QDR 2 ****************************/
`ifdef ENABLE_QDR

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
    .reset       (qdr2_rst),

    .phy_rdy     (qdr2_phy_rdy),
    .cal_fail    (qdr2_cal_fail),

    .usr_addr    (qdr2_app_addr),
    .usr_wr_strb (qdr2_app_wr_en),
    .usr_wr_data (qdr2_app_wr_data),
    .usr_rd_strb (qdr2_app_rd_en),
    .usr_rd_data (qdr2_app_rd_data),
    .usr_rd_dvld (qdr2_app_rd_dvld)
    ,.debug (qdr_debug)
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
    .qdr_rst     (qdr2_rst),

    .qdr_addr    (qdr2_app_addr),
    .qdr_wr_en   (qdr2_app_wr_en),
    .qdr_wr_data (qdr2_app_wr_data),
    .qdr_rd_en   (qdr2_app_rd_en),
    .qdr_rd_data (qdr2_app_rd_data),
    .qdr_rd_dvld (qdr2_app_rd_dvld),
    .phy_rdy     (qdr2_phy_rdy),
    .cal_fail    (qdr2_cal_fail)
  );
`else
  OBUF #(
    .IOSTANDARD("LVCMOS15")
  ) qdr2_obuf [61:0] (
    .I (62'b0),
    .O ({qdr2_k, qdr2_kn, qdr2_rdn, qdr2_wrn, qdr2_a, qdr2_d, qdr2_doffn})
  );

  wire [35:0] qdr2_q_noreduce;
  //synthesis attribute NOREDUCE of qdr2_q_noreduce is TRUE
  IBUF #(
    .IOSTANDARD("LVCMOS15")
  ) qdr2_ibuf [35:0] (
    .I (qdr2_q),
    .O (qdr2_q_noreduce)
  );
`endif

  assign v6_gpio[15:8] = qdr_debug;

  /************************ QDR 3 ****************************/
`ifdef ENABLE_QDR

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
    .reset       (qdr3_rst),

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
    .qdr_rst     (qdr3_rst),

    .qdr_addr    (qdr3_app_addr),
    .qdr_wr_en   (qdr3_app_wr_en),
    .qdr_wr_data (qdr3_app_wr_data),
    .qdr_rd_en   (qdr3_app_rd_en),
    .qdr_rd_data (qdr3_app_rd_data),
    .qdr_rd_dvld (qdr3_app_rd_dvld),
    .phy_rdy     (qdr3_phy_rdy),
    .cal_fail    (qdr3_cal_fail)
  );
`else
  OBUF #(
    .IOSTANDARD("LVCMOS15")
  ) qdr3_obuf [61:0] (
    .I (62'b0),
    .O ({qdr3_k, qdr3_kn, qdr3_rdn, qdr3_wrn, qdr3_a, qdr3_d, qdr3_doffn})
  );

  wire [35:0] qdr3_q_noreduce;
  //synthesis attribute NOREDUCE of qdr3_q_noreduce is TRUE
  IBUF #(
    .IOSTANDARD("LVCMOS15")
  ) qdr3_ibuf [35:0] (
    .I (qdr3_q),
    .O (qdr3_q_noreduce)
  );
`endif

/*********** DRAM *************/

  wire ddr3_clk_rd_base;
  wire ddr3_clk_mem;
  wire ddr3_clk_div2;
  wire ddr3_rst_div2;

  wire ddr3_pll_lock;

  ddr3_clk #(
    .DRAM_FREQUENCY (400)
  ) ddr3_clk_inst (
    .clk_100          (clk_100),       
    .sys_rst          (rst_100),        
    .iodelay_ctrl_rdy (idelay_rdy),

    .clk_mem          (ddr3_clk_mem),     // 2x logic clock
    .clk_app          (ddr3_clk_div2),    // 1x logic clock
    .clk_rd_base      (ddr3_clk_rd_base), // 2x base read clock

    .rstdiv0          (ddr3_rst_div2),    // Reset CLK and CLKDIV logic (incl I/O),
    .PSEN             (1'b0),
    .PSINCDEC         (1'b0),
    .PSDONE           ()
  );

`ifdef ENABLE_DDR3

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
    .clk_rd_base       (ddr3_clk_rd_base),

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
`else
  wire [71:0] ddr3_iobuf_I = {72{1'b0}};
  wire [71:0] ddr3_iobuf_O;
  wire [71:0] ddr3_iobuf_T = {72{1'b1}};

  IOBUF ddr3_iobuf[71:0] (
    .IO (ddr3_dq),
    .I  (ddr3_iobuf_I),
    .O  (ddr3_iobuf_O),
    .T  (ddr3_iobuf_T)
  );

  wire [8:0] ddr3_iobufds_I = {9{1'b0}};
  wire [8:0] ddr3_iobufds_O;
  wire [8:0] ddr3_iobufds_T = {9{1'b1}};

  /* Xilinx will kill this buffer unless I connect .I to .O
     Doing this makes me want to kill kittens */
  IOBUFDS ddr3_iobufds [8:0] (
    .IO  (ddr3_dqs_p),
    .IOB (ddr3_dqs_n),
    .I   (ddr3_iobufds_O),
    .O   (ddr3_iobufds_O),
    .T   (ddr3_iobufds_T)
  );

  OBUFDS ddr3_obufds(
    .O  (ddr3_ck_p),
    .OB (ddr3_ck_n),
    .I  (clk_100)
  );

  assign ddr3_dm      =  9'b0;
  assign ddr3_ba      =  3'b0;
  assign ddr3_a       = 16'b0;
  assign ddr3_sn      =  4'b0;
  assign ddr3_rasn    =  1'b0;
  assign ddr3_casn    =  1'b0;
  assign ddr3_wen     =  1'b0;
  assign ddr3_cke     =  2'b0;
  assign ddr3_odt     =  2'b0;
  assign ddr3_resetn  =  1'b0;
`endif

  /*********** 10Ge ***************/
  assign mgt_gpio = 12'b111000_000111;

  //156.25 MHz clock for the board
  // synthesis attribute KEEP of xaui_clk is TRUE
  wire xaui_clk;

  reg xaui_rstR;
  reg xaui_rstRR;
  always @(posedge xaui_clk) begin
    xaui_rstR  <= rst_100;
    xaui_rstRR <= xaui_rstR;
  end
  wire xaui_rst = xaui_rstRR;

  wire  [8*1-1:0] mgt_tx_rst;
  wire  [8*1-1:0] mgt_rx_rst;

  wire [8*64-1:0] mgt_txdata;
  wire  [8*8-1:0] mgt_txcharisk;

  wire [8*64-1:0] mgt_rxdata;
  wire  [8*8-1:0] mgt_rxcharisk;
  wire  [8*8-1:0] mgt_rxcodecomma;
  wire  [8*4-1:0] mgt_rxencommaalign;
  wire  [8*1-1:0] mgt_rxenchansync;
  wire  [8*4-1:0] mgt_rxsyncok;
  wire  [8*8-1:0] mgt_rxcodevalid;
  wire  [8*4-1:0] mgt_rxbufferr;

  wire  [8*4-1:0] mgt_rxlock;
  wire  [8*4-1:0] mgt_rxelecidle;

  wire  [8*1-1:0] mgt_loopback;
  wire  [8*1-1:0] mgt_powerdown;

  wire  [8*5-1:0] mgt_txpostemphasis;
  wire  [8*4-1:0] mgt_txpreemphasis;
  wire  [8*4-1:0] mgt_txdiffctrl;
  wire  [8*3-1:0] mgt_rxeqmix;

  wire [8*16-1:0] mgt_status;

  /* XAUI XGMII signals */
  wire [64*8-1:0] xgmii_txd;
  wire  [8*8-1:0] xgmii_txc;
  wire [64*8-1:0] xgmii_rxd;
  wire  [8*8-1:0] xgmii_rxc;

  wire  [8*8-1:0] xaui_status;

  assign mgt_txpostemphasis [5*(0+1)-1:0*5] = 5'b0000;
  assign mgt_txpreemphasis  [4*(0+1)-1:0*4] = 4'b0100;
  assign mgt_txdiffctrl     [4*(0+1)-1:0*4] = 4'b1010;
  assign mgt_rxeqmix        [3*(0+1)-1:0*3] = 3'b111;
                                 
  assign mgt_txpostemphasis [5*(1+1)-1:1*5] = 5'b00000;
  assign mgt_txpreemphasis  [4*(1+1)-1:1*4] = 4'b0100;
  assign mgt_txdiffctrl     [4*(1+1)-1:1*4] = 4'b1010;
  assign mgt_rxeqmix        [3*(1+1)-1:1*3] = 3'b111;
                                 
  assign mgt_txpostemphasis [5*(2+1)-1:2*5] = 5'b00000;
  assign mgt_txpreemphasis  [4*(2+1)-1:2*4] = 4'b0100;
  assign mgt_txdiffctrl     [4*(2+1)-1:2*4] = 4'b1010;
  assign mgt_rxeqmix        [3*(2+1)-1:2*3] = 3'b111;
                                 
  assign mgt_txpostemphasis [5*(3+1)-1:3*5] = 5'b00000;
  assign mgt_txpreemphasis  [4*(3+1)-1:3*4] = 4'b0100;
  assign mgt_txdiffctrl     [4*(3+1)-1:3*4] = 4'b1010;
  assign mgt_rxeqmix        [3*(3+1)-1:3*3] = 3'b111;
                                 
  assign mgt_txpostemphasis [5*(4+1)-1:4*5] = 5'b00000;
  assign mgt_txpreemphasis  [4*(4+1)-1:4*4] = 4'b0100;
  assign mgt_txdiffctrl     [4*(4+1)-1:4*4] = 4'b1010;
  assign mgt_rxeqmix        [3*(4+1)-1:4*3] = 3'b111;
                                 
  assign mgt_txpostemphasis [5*(5+1)-1:5*5] = 5'b00000;
  assign mgt_txpreemphasis  [4*(5+1)-1:5*4] = 4'b0100;
  assign mgt_txdiffctrl     [4*(5+1)-1:5*4] = 4'b1010;
  assign mgt_rxeqmix        [3*(5+1)-1:5*3] = 3'b111;
                                 
  assign mgt_txpostemphasis [5*(6+1)-1:6*5] = 5'b00000;
  assign mgt_txpreemphasis  [4*(6+1)-1:6*4] = 4'b0100;
  assign mgt_txdiffctrl     [4*(6+1)-1:6*4] = 4'b1010;
  assign mgt_rxeqmix        [3*(6+1)-1:6*3] = 3'b111;
                                 
  assign mgt_txpostemphasis [5*(7+1)-1:7*5] = 5'b00000;
  assign mgt_txpreemphasis  [4*(7+1)-1:7*4] = 4'b0100;
  assign mgt_txdiffctrl     [4*(7+1)-1:7*4] = 4'b1010;
  assign mgt_rxeqmix        [3*(7+1)-1:7*3] = 3'b111;

`ifdef ENABLE_TGE
  parameter TGE_ENABLE_MASK = 8'b1111_1111;
`else
  parameter TGE_ENABLE_MASK = 8'b0000_0000;
`endif

  xaui_infrastructure #(
    .ENABLE_MASK (TGE_ENABLE_MASK)
  ) xaui_infrastructure_inst (
    .mgt_reset          (rst_100),

    .xaui_refclk_n      (xaui_refclk_n),
    .xaui_refclk_p      (xaui_refclk_p),

    .mgt_rx_n           (mgt_rx_n),
    .mgt_rx_p           (mgt_rx_p),
    .mgt_tx_n           (mgt_tx_n),
    .mgt_tx_p           (mgt_tx_p),

    .xaui_clk           (xaui_clk),

    .mgt_tx_rst         (mgt_tx_rst),
    .mgt_rx_rst         (mgt_rx_rst),

    .mgt_txdata         (mgt_txdata),
    .mgt_txcharisk      (mgt_txcharisk),

    .mgt_rxdata         (mgt_rxdata),
    .mgt_rxcharisk      (mgt_rxcharisk),
    .mgt_rxcodecomma    (mgt_rxcodecomma),
    .mgt_rxencommaalign (mgt_rxencommaalign),
    .mgt_rxenchansync   (mgt_rxenchansync),
    .mgt_rxsyncok       (mgt_rxsyncok),
    .mgt_rxcodevalid    (mgt_rxcodevalid),
    .mgt_rxbufferr      (mgt_rxbufferr),

    .mgt_rxlock         (mgt_rxlock),
    .mgt_rxelecidle     (mgt_rxelecidle),

    .mgt_loopback       (mgt_loopback),
    .mgt_powerdown      (mgt_powerdown),

    .mgt_txpostemphasis (mgt_txpostemphasis),
    .mgt_txpreemphasis  (mgt_txpreemphasis),
    .mgt_txdiffctrl     (mgt_txdiffctrl),
    .mgt_rxeqmix        (mgt_rxeqmix),

    .mgt_status         (mgt_status)
  );

  wire [7:0] xaui_loopback = 8'b0000_0000;

  reg [15:0] xaui_err_cnt [7:0];

  always @(posedge xaui_clk) begin
    if (mgt_rxcodevalid[(0 + 1)*8-1:0*8] != 8'b1111_1111)
      xaui_err_cnt[0] <= xaui_err_cnt[0] + 16'b1;
    if (mgt_rxcodevalid[(1 + 1)*8-1:1*8] != 8'b1111_1111)
      xaui_err_cnt[1] <= xaui_err_cnt[1] + 16'b1;
    if (mgt_rxcodevalid[(2 + 1)*8-1:2*8] != 8'b1111_1111)
      xaui_err_cnt[2] <= xaui_err_cnt[2] + 16'b1;
    if (mgt_rxcodevalid[(3 + 1)*8-1:3*8] != 8'b1111_1111)
      xaui_err_cnt[3] <= xaui_err_cnt[3] + 16'b1;
    if (mgt_rxcodevalid[(4 + 1)*8-1:4*8] != 8'b1111_1111)
      xaui_err_cnt[4] <= xaui_err_cnt[4] + 16'b1;
    if (mgt_rxcodevalid[(5 + 1)*8-1:5*8] != 8'b1111_1111)
      xaui_err_cnt[5] <= xaui_err_cnt[5] + 16'b1;
    if (mgt_rxcodevalid[(6 + 1)*8-1:6*8] != 8'b1111_1111)
      xaui_err_cnt[6] <= xaui_err_cnt[6] + 16'b1;
    if (mgt_rxcodevalid[(7 + 1)*8-1:7*8] != 8'b1111_1111)
      xaui_err_cnt[7] <= xaui_err_cnt[7] + 16'b1;
  end

`ifdef ENABLE_TGE
  wire        tge_tx_valid         [7:0];
  wire        tge_tx_end_of_frame  [7:0];
  wire [63:0] tge_tx_data          [7:0];
  wire [31:0] tge_tx_dest_ip       [7:0];
  wire [15:0] tge_tx_dest_port     [7:0];
  wire        tge_tx_overflow      [7:0];
  wire        tge_tx_afull         [7:0];

  wire        tge_rx_valid         [7:0];
  wire        tge_rx_end_of_frame  [7:0];
  wire [63:0] tge_rx_data          [7:0];
  wire [31:0] tge_rx_source_ip     [7:0];
  wire [15:0] tge_rx_source_port   [7:0];
  wire        tge_rx_bad_frame     [7:0];
  wire        tge_rx_overrun       [7:0];
  wire        tge_rx_overrun_ack   [7:0];
  wire        tge_rx_ack           [7:0];

  genvar I;
generate for (I=0; I < 8; I=I+1) begin : gen_10ge

  xaui_phy xaui_phy_inst (
    .clk              (xaui_clk),
    .reset            (xaui_rst),

    .mgt_txdata       (mgt_txdata[I*64+:64]),
    .mgt_txcharisk    (mgt_txcharisk[I*8+:8]),
    .mgt_rxdata       (mgt_rxdata[I*64+:64]),
    .mgt_rxcharisk    (mgt_rxcharisk[I*8+:8]),
    .mgt_enable_align (mgt_rxencommaalign[I*4+:4]),
    .mgt_en_chan_sync (mgt_rxenchansync[I]), 
    .mgt_code_valid   (mgt_rxcodevalid[I*8+:8]),
    .mgt_rxbufferr    (mgt_rxbufferr[I*4+:4]),
    .mgt_code_comma   (mgt_rxcodecomma[I*8+:8]),
    .mgt_rxlock       (mgt_rxlock[I*4+:4]),
    .mgt_syncok       (mgt_rxsyncok[I*4+:4]),
    .mgt_loopback     (mgt_loopback[I]),
    .mgt_powerdown    (mgt_powerdown[I]),
    .mgt_tx_reset     (mgt_tx_rst[I*4]),
    .mgt_rx_reset     (mgt_rx_rst[I*4]),

    .xgmii_txd        (xgmii_txd[I*64+:64]),
    .xgmii_txc        (xgmii_txc[I*8+:8]),
    .xgmii_rxd        (xgmii_rxd[I*64+:64]),
    .xgmii_rxc        (xgmii_rxc[I*8+:8]),

    .xaui_status      (xaui_status[I*8+:8]),
    .loopback_en      (xaui_loopback[I])
  );

  kat_ten_gb_eth kat_ten_gb_eth_inst (
    .clk (clk_200),
    .rst (rst_200),

    .tx_valid        (tge_tx_valid[I]),
    .tx_end_of_frame (tge_tx_end_of_frame[I]),
    .tx_data         (tge_tx_data[I]),
    .tx_dest_ip      (tge_tx_dest_ip[I]),
    .tx_dest_port    (tge_tx_dest_port[I]),
    .tx_overflow     (tge_tx_overflow[I]), 
    .tx_afull        (tge_tx_afull[I]), 

    .rx_valid        (tge_rx_valid[I]),
    .rx_end_of_frame (tge_rx_end_of_frame[I]),
    .rx_data         (tge_rx_data[I]),
    .rx_source_ip    (tge_rx_source_ip[I]),
    .rx_source_port  (tge_rx_source_port[I]),
    .rx_bad_frame    (tge_rx_bad_frame[I]),
    .rx_overrun      (tge_rx_overrun[I]),
    .rx_overrun_ack  (tge_rx_overrun_ack[I]),
    .rx_ack          (tge_rx_ack[I]),

    .wb_clk_i    (wb_clk_i),
    .wb_rst_i    (wb_rst_i),
    .wb_cyc_i    (wbs_cyc_o[TGE0_SLI + I]),
    .wb_stb_i    (wbs_stb_o[TGE0_SLI + I]),
    .wb_we_i     (wbs_we_o),
    .wb_sel_i    (wbs_sel_o),
    .wb_adr_i    (wbs_adr_o),
    .wb_dat_i    (wbs_dat_o),
    .wb_dat_o    (wbs_dat_i[(TGE0_SLI + I)*32+:32]),
    .wb_ack_o    (wbs_ack_i[TGE0_SLI + I]),
    .wb_err_o    (wbs_err_i[TGE0_SLI + I]),

    .led_up (),
    .led_rx (),
    .led_tx (),

    .xaui_clk   (xaui_clk),
    .xaui_reset (xaui_reset),
    .phy_status ({xaui_err_cnt[I], 8'b0, xaui_status[I*8+:8]}),

    .xgmii_txd   (xgmii_txd[I*64+:64]),
    .xgmii_txc   (xgmii_txc[I*8+:8]),
    .xgmii_rxd   (xgmii_rxd[I*64+:64]),
    .xgmii_rxc   (xgmii_rxc[I*8+:8]),

    .mgt_rxeqmix       (),
    .mgt_rxeqpole      (),
    .mgt_txpreemphasis (),
    .mgt_txdiffctrl    ()

  );

  reg ppc_poenR;
  reg ppc_poenRR;

  reg [1:0] foo_state;

  reg [31:0] ppc_data_buf;
  reg [31:0] ppc_addr_buf;

  reg eek;
  
  reg [2:0] moo;

  always @(posedge clk_200) begin
    eek <= 1'b0;

    ppc_poenR  <= ppc_poen;
    ppc_poenRR <= ppc_poenR;

    if (rst_200) begin
      foo_state <= 2'b0;
    end else begin
      case (foo_state) 
        2'b0: begin
          if (!ppc_poenRR) begin
            foo_state <= 2'b1;
          end
        end
        2'b1: begin
          if (ppc_poenRR) begin
            foo_state <= 2'd0;
            ppc_data_buf <= epb_data_i;
            ppc_addr_buf <= ppc_paddr;
            eek <= 1'b1;
          end
        end
      endcase
    end
  end

  reg [5:0] pkt_counter;
  always @(posedge clk_200) begin
    if (rst_200) begin
      pkt_counter <= 6'd0;
    end else begin
      if (eek)
        pkt_counter <= pkt_counter + 6'd1;
    end
  end

  assign tge_tx_data[I]         = {ppc_addr_buf, ppc_data_buf};
  assign tge_tx_valid[I]        = eek;
  assign tge_tx_end_of_frame[I] = pkt_counter == {6{1'b1}};
  assign tge_tx_dest_ip[I]      = {8'd192, 8'd168, 8'd43, 8'd1};
  assign tge_tx_dest_port[I]    = 16'd6969;

  assign tge_rx_overrun_ack[I]   = 1'b0;
  assign tge_rx_ack[I]           = 1'b1;

end endgenerate
`endif
  
  
  /********* SGMII PHY ************/
  
  reg sgmii_reset_R;
  reg sgmii_reset_RR;
  always @(posedge clk_125) begin
    sgmii_reset_R  <= rst_100;
    sgmii_reset_RR <= sgmii_reset_R;
  end
  wire sgmii_reset = sgmii_reset_RR;
  assign rst_125 = sgmii_reset;
  
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
`ifdef ENABLE_GBE
    .sgmii_powerdown    (1'b0)
`else
    .sgmii_powerdown    (1'b1)
`endif
  );

`ifdef ENABLE_GBE

  // MAC interface
  wire       mac_rx_clk;
  wire       mac_rx_rst = sgmii_reset;
  wire [7:0] mac_rx_data;
  wire       mac_rx_dvld;
  wire       mac_rx_goodframe;
  wire       mac_rx_badframe;
  
  wire       mac_tx_clk;
  wire       mac_tx_rst = sgmii_reset;
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

  wire        gbe_app_clk;

  wire  [7:0] gbe_app_tx_data;
  wire        gbe_app_tx_dvld;
  wire        gbe_app_tx_eof;
  wire [31:0] gbe_app_tx_destip;
  wire [15:0] gbe_app_tx_destport;

  wire        gbe_app_tx_afull;
  wire        gbe_app_tx_overflow;
  wire        gbe_app_tx_rst;

  wire  [7:0] gbe_app_rx_data;
  wire        gbe_app_rx_dvld;
  wire        gbe_app_rx_eof;
  wire [31:0] gbe_app_rx_srcip;
  wire [15:0] gbe_app_rx_srcport;
  wire        gbe_app_rx_badframe;

  wire        gbe_app_rx_overrun;
  wire        gbe_app_rx_ack;
  wire        gbe_app_rx_rst;

  reg [15:0] gbe_idle_errors;
  always @(posedge clk_125)
    if (sgmii_rxdisperr)
      gbe_idle_errors <= gbe_idle_errors + 16'h1;

  gbe_udp #(
    .LOCAL_ENABLE     (1'b1),
    .LOCAL_MAC        (48'h1234_5678_9abc),
    .LOCAL_IP         ({8'd192, 8'd168, 8'd41, 8'd10}),
    .LOCAL_PORT       (16'd666),
    .LOCAL_GATEWAY    (8'd1),
    .CPU_PROMISCUOUS  (1'b1),
    .PHY_CONFIG       (0),
    .DIS_CPU_TX       (1'b0),
    .DIS_CPU_RX       (1'b0),
    .TX_LARGE_PACKETS (1'b0),
    .RX_DIST_RAM      (1'b0),
    .ARP_CACHE_INIT   (0)
  ) gbe_udp_inst (
  /**** Application Interface ****/
    .app_clk         (gbe_app_clk),
    .app_tx_data     (gbe_app_tx_data),
    .app_tx_dvld     (gbe_app_tx_dvld),
    .app_tx_eof      (gbe_app_tx_eof),
    .app_tx_destip   (gbe_app_tx_destip),
    .app_tx_destport (gbe_app_tx_destport),
    .app_tx_afull    (gbe_app_tx_afull),
    .app_tx_overflow (gbe_app_tx_overflow),
    .app_tx_rst      (gbe_app_tx_rst),
    .app_rx_data     (gbe_app_rx_data),
    .app_rx_dvld     (gbe_app_rx_dvld),
    .app_rx_eof      (gbe_app_rx_eof),
    .app_rx_srcip    (gbe_app_rx_srcip),
    .app_rx_srcport  (gbe_app_rx_srcport),
    .app_rx_badframe (gbe_app_rx_badframe),
    .app_rx_overrun  (gbe_app_rx_overrun),
    .app_rx_ack      (gbe_app_rx_ack),
    .app_rx_rst      (gbe_app_rx_rst),

  /**** MAC Interface ****/
    .mac_tx_clk       (mac_tx_clk),
    .mac_tx_rst       (mac_tx_rst),
    .mac_tx_data      (mac_tx_data),
    .mac_tx_dvld      (mac_tx_dvld),
    .mac_tx_ack       (mac_tx_ack),
    .mac_rx_clk       (mac_rx_clk),
    .mac_rx_rst       (mac_rx_rst),
    .mac_rx_data      (mac_rx_data),
    .mac_rx_dvld      (mac_rx_dvld),
    .mac_rx_goodframe (mac_rx_goodframe),
    .mac_rx_badframe  (mac_rx_badframe),

  /**** PHY Status/Control ****/
    .phy_status       ({gbe_idle_errors, 15'b0, mac_syncacquired}),
    .phy_control      (),

  /**** CPU Bus Attachment ****/
    .wb_clk_i    (wb_clk_i),
    .wb_rst_i    (wb_rst_i),
    .wb_cyc_i    (wbs_cyc_o[GBE_SLI]),
    .wb_stb_i    (wbs_stb_o[GBE_SLI]),
    .wb_we_i     (wbs_we_o),
    .wb_sel_i    (wbs_sel_o),
    .wb_adr_i    (wbs_adr_o),
    .wb_dat_i    (wbs_dat_o),
    .wb_dat_o    (wbs_dat_i[(GBE_SLI+1)*32-1:(GBE_SLI)*32]),
    .wb_ack_o    (wbs_ack_i[GBE_SLI]),
    .wb_err_o    (wbs_err_i[GBE_SLI])
  );

  assign gbe_app_rx_ack       = 1'b1;
  assign gbe_app_rx_rst       = 1'b0;


`endif

  assign debug_regin_0 = {31'h0, idelay_rdy};
  assign debug_regin_1 = 32'hdead_0001;
  assign debug_regin_2 = 32'hdead_0002;
  assign debug_regin_3 = 32'hdead_0003;
  assign debug_regin_4 = 32'hdead_0004;
  assign debug_regin_5 = 32'hdead_0005;
  assign debug_regin_6 = 32'hdead_0006;
  assign debug_regin_7 = 32'hdead_0007;


endmodule
