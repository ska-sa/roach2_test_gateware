module toplevel(
    input          sys_clk_n,
    input          sys_clk_p,
    /*
    input          aux_clk_n,
    input          aux_clk_p,
    input          aux_synci_n,
    input          aux_synci_p,
    output         aux_synco_n,
    output         aux_synco_p,
    */

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

    output         ppc_irqn,

    /*

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
    output         ddr3_cke0,
    output         ddr3_cke1,
    output         ddr3_odt0,
    output         ddr3_odt1,
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

    input          zdok0_clk0_n,
    input          zdok0_clk0_p,
    input          zdok0_clk1_n,
    input          zdok0_clk1_p,
    inout   [37:0] zdok0_dp_n,
    inout   [37:0] zdok0_dp_p,

    inout          zdok1_clk0_n,
    inout          zdok1_clk0_p,
    inout          zdok1_clk1_n,
    inout          zdok1_clk1_p,
    inout   [37:0] zdok1_dp_n,
    inout   [37:0] zdok1_dp_p,

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

  /***************** system signals *****************/

  wire sys_clk_ds;
  IBUFGDS #(
    .IOSTANDARD("LVDS_25"),
    .DIFF_TERM("TRUE")
  ) ibufgds_sys_clk (
    .I (sys_clk_p),
    .IB(sys_clk_n),
    .O (sys_clk_ds)
  );

  BUFG bufg_sys_clk(
    .I(sys_clk_ds),
    .O(sys_clk)
  );
  
  /* reset gen */
  reg sys_rst;
  reg [15:0] sys_rst_counter;
  always @(posedge sys_clk) begin
    sys_rst_counter <= sys_rst_counter + 16'd1;

    if (sys_rst_counter == {16{1'b1}}) begin
      sys_rst <= 1'b0;
      sys_rst_counter <= {16{1'b1}};
    end else begin
      sys_rst <= 1'b1;
    end
  end

  wire [2:0] knight_rider_speed;

  knight_rider knight_rider_inst(
    .clk  (sys_clk),
    .rst  (sys_rst),
    .led  (v6_gpio[7:0]),
    .rate (knight_rider_speed)
  );

  wire wb_clk_i, wb_rst_i;
  wire wb_cyc_o, wb_stb_o, wb_we_o;
  wire  [3:0] wb_sel_o;
  wire [31:0] wb_adr_o;
  wire [31:0] wb_dat_o;
  wire [31:0] wb_dat_i;
  wire wb_ack_i, wb_err_i;

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

  epb_wb_bridge_reg epb_wb_bridge_reg_inst(
    .wb_clk_i (wb_clk_i),
    .wb_rst_i (wb_rst_i),
    .wb_cyc_o (wb_cyc_o),
    .wb_stb_o (wb_stb_o),
    .wb_we_o  (wb_we_o),
    .wb_sel_o (wb_sel_o),
    .wb_adr_o (wb_adr_o),
    .wb_dat_o (wb_dat_o),
    .wb_dat_i (wb_dat_i),
    .wb_ack_i (wb_ack_i),
    .wb_err_i (wb_err_i),

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
  wire        debug_clk;
  wire [31:0] regin_0;
  wire [31:0] regin_1;
  wire [31:0] regin_2;
  wire [31:0] regin_3;
  wire [31:0] regin_4;
  wire [31:0] regin_5;
  wire [31:0] regin_6;
  wire [31:0] regin_7;

  wire [31:0] regout_0;
  wire [31:0] regout_1;
  wire [31:0] regout_2;
  wire [31:0] regout_3;
  wire [31:0] regout_4;
  wire [31:0] regout_5;
  wire [31:0] regout_6;
  wire [31:0] regout_7;

  wb_debug wb_debug_inst(
    .wb_clk_i (wb_clk_i),
    .wb_rst_i (wb_rst_i),
    .wb_cyc_i (wb_cyc_o),
    .wb_stb_i (wb_stb_o),
    .wb_we_i  (wb_we_o),
    .wb_sel_i (wb_sel_o),
    .wb_adr_i (wb_adr_o),
    .wb_dat_i (wb_dat_o),
    .wb_dat_o (wb_dat_i),
    .wb_ack_o (wb_ack_i),
    .wb_err_o (wb_err_i),

    .debug_clk(debug_clk),
    .regin_0(regin_0),
    .regin_1(regin_1),
    .regin_2(regin_2),
    .regin_3(regin_3),
    .regin_4(regin_4),
    .regin_5(regin_5),
    .regin_6(regin_6),
    .regin_7(regin_7),

    .regout_0(regout_0),
    .regout_1(regout_1),
    .regout_2(regout_2),
    .regout_3(regout_3),
    .regout_4(regout_4),
    .regout_5(regout_5),
    .regout_6(regout_6),
    .regout_7(regout_7),

    .fifo_wr_in(fifo_wr_in),
    .fifo_wr_en(fifo_wr_en)
  );

  /*

  reg [31:0] scratch0;
  reg [31:0] scratch1;
  reg [31:0] misc0;
  reg [31:0] misc1;
  reg [31:0] misc2;
  reg [31:0] misc3;
  reg [31:0] misc4;
  reg [31:0] misc5;

  reg wb_ack_i_reg;
  assign wb_ack_i = wb_ack_i_reg;

  assign knight_rider_speed = scratch1[2:0];

  reg [31:0] debug;

  always @(posedge clk_125) begin
    misc0 <= debug;
  end

  reg [31:0] misc0_R;
  reg [31:0] misc0_RR;

  always @(posedge wb_clk_i) begin
    misc0_R  <= misc0;
    misc0_RR <= misc0_R;

    wb_ack_i_reg <= 1'b0;
    if (wb_rst_i) begin
      scratch0 <= 32'hdeadbeef;
      scratch1 <= 32'h1;
      misc1    <= 32'b0;
    end else begin
      if (wb_stb_o && wb_cyc_o) begin
        wb_ack_i_reg <= 1'b1;

        if (wb_we_o) begin
          case (wb_adr_o[4:2])
            2'b00: begin
              scratch0 <= wb_dat_o;
            end
            2'b01: begin
              scratch1 <= wb_dat_o;
            end
            2'b10: begin
            end
            2'b11: begin
            end
          endcase
        end

        if (wb_we_o) begin
          misc1[15:0] <= misc1[15:0] + 16'b1;
        end else begin
          misc1[31:16] <= misc1[31:16] + 16'b1;
        end
      end
    end
  end

  assign wb_err_i = 1'b0;

  reg [31:0] wb_dat_i_reg;
  assign wb_dat_i = wb_dat_i_reg;

  always @(*) begin
    case (wb_adr_o[4:2])
      3'd0:    wb_dat_i_reg <= scratch0;
      3'd1:    wb_dat_i_reg <= scratch1;
      3'd2:    wb_dat_i_reg <= misc0_RR;
      3'd3:    wb_dat_i_reg <= misc1;
      3'd4:    wb_dat_i_reg <= misc2;
      3'd5:    wb_dat_i_reg <= misc3;
      3'd6:    wb_dat_i_reg <= misc4;
      3'd7:    wb_dat_i_reg <= misc5;
    endcase
  end
  */

  OBUF #(
    .IOSTANDARD("LVCMOS25")
  ) OBUF_ppc_irqn (
    .O (ppc_irqn),
    .I (1'b0)
  );
  
//wire aux_clk;
//IBUFGDS #(
//  .IOSTANDARD("LVDS_25"),
//  .DIFF_TERM("TRUE")
//) ibufgds_aux_clk (
//  .I (aux_clk_p),
//  .IB(aux_clk_n),
//  .O (aux_clk)
//);
//
//wire aux_synci;
//IBUFDS #(
//  .IOSTANDARD("LVDS_25"),
//  .DIFF_TERM("TRUE")
//) ibufds_aux_synci (
//  .I (aux_synci_p),
//  .IB(aux_synci_n),
//  .O (aux_synci)
//);
//
//wire aux_synco;
//OBUFDS #(
//  .IOSTANDARD("LVDS_25")
//) obufds_aux_synco (
//  .O (aux_synco_p),
//  .OB(aux_synco_n),
//  .I (aux_synco)
//);
//assign aux_synco = aux_synci;
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
///***************** QDRs *****************/
//
//wire qdr0_k_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr0_k (
//  .I (qdr0_k_buf),
//  .O (qdr0_k)
//);
//
//wire qdr0_kn_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr0_kn (
//  .I (qdr0_kn_buf),
//  .O (qdr0_kn)
//);
//
//wire qdr0_rdn_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr0_rdn (
//  .I (qdr0_rdn_buf),
//  .O (qdr0_rdn)
//);
//
//wire qdr0_wrn_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr0_wrn (
//  .I (qdr0_wrn_buf),
//  .O (qdr0_wrn)
//);
//
//wire [20:0] qdr0_a_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr0_a[20:0] (
//  .I (qdr0_a_buf),
//  .O (qdr0_a)
//);
//
//wire [35:0] qdr0_d_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr0_d[35:0] (
//  .I (qdr0_d_buf),
//  .O (qdr0_d)
//);
//
//wire qdr0_doffn_buf;
//OBUF #(
//  .IOSTANDARD("HSTL_I")
//) OBUF_qdr0_doffn (
//  .I (qdr0_doffn_buf),
//  .O (qdr0_doffn)
//);
//
//wire [35:0] qdr0_q_buf;
//IBUF #(
//  .IOSTANDARD("HSTL_I_DCI")
//) IBUF_qdr0_q[35:0] (
//  .I (qdr0_q),
//  .O (qdr0_q_buf)
//);
//
//assign qdr0_d_buf     = qdr0_q_buf;
//assign qdr0_a_buf     = qdr0_q_buf[20:0];
//assign qdr0_doffn_buf = qdr0_q_buf[0];
//assign qdr0_wrn_buf   = qdr0_q_buf[0];
//assign qdr0_rdn_buf   = qdr0_q_buf[0];
//assign qdr0_k_buf     = qdr0_q_buf[0];
//assign qdr0_kn_buf    = qdr0_q_buf[0];
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
///*************** DDR3 **************/
//
//wire ddr3_ck_buf;
//OBUFDS #(
//  .IOSTANDARD("DIFF_SSTL15")
//) OBUFDS_ddr3_ck (
//  .I  (ddr3_ck_buf),
//  .O  (ddr3_ck_p),
//  .OB (ddr3_ck_n)
//);
//
//wire [8:0] ddr3_dm_buf;
//OBUF #(
//  .IOSTANDARD("SSTL15")
//) OBUF_ddr3_dm[8:0] (
//  .I (ddr3_dm_buf),
//  .O (ddr3_dm)
//);
//
//wire [71:0] ddr3_dq_bufi;
//wire [71:0] ddr3_dq_bufo;
//wire [71:0] ddr3_dq_bufoen;
//
//IOBUF #(
//  .IOSTANDARD("SSTL15_T_DCI")
//) IOBUF_ddr3_dq[71:0] (
// .IO (ddr3_dq),
// .O  (ddr3_dq_bufi),
// .I  (ddr3_dq_bufo),
// .T  (ddr3_dq_bufoen)
//);
//assign ddr3_dq_bufo   = ddr3_dq_bufi;
//assign ddr3_dq_bufoen = ddr3_dq_bufi;
//
//wire [8:0] ddr3_dqs_bufi;
//wire [8:0] ddr3_dqs_bufo;
//wire [8:0] ddr3_dqs_bufoen;
//
//IOBUFDS #(
//  .IOSTANDARD("DIFF_SSTL15_T_DCI")
//) IOBUF_ddr3_dqs[8:0] (
// .IO  (ddr3_dqs_p),
// .IOB (ddr3_dqs_n),
// .O  (ddr3_dqs_bufi),
// .I  (ddr3_dqs_bufo),
// .T  (ddr3_dqs_bufoen)
//);
//assign ddr3_dqs_bufo   = ddr3_dqs_bufi;
//assign ddr3_dqs_bufoen = ddr3_dqs_bufi;
//
//wire [2:0] ddr3_ba_buf;
//OBUF #(
//  .IOSTANDARD("SSTL15")
//) OBUF_ddr3_ba[2:0] (
//  .I (ddr3_ba_buf),
//  .O (ddr3_ba)
//);
//
//wire [15:0] ddr3_a_buf;
//OBUF #(
//  .IOSTANDARD("SSTL15")
//) OBUF_ddr3_a[15:0] (
//  .I (ddr3_a_buf),
//  .O (ddr3_a)
//);
//
//wire [3:0] ddr3_sn_buf;
//OBUF #(
//  .IOSTANDARD("SSTL15")
//) OBUF_ddr3_sn[3:0] (
//  .I (ddr3_sn_buf),
//  .O (ddr3_sn)
//);
//
//wire ddr3_rasn_buf;
//OBUF #(
//  .IOSTANDARD("SSTL15")
//) OBUF_ddr3_rasn (
//  .I (ddr3_rasn_buf),
//  .O (ddr3_rasn)
//);
//
//wire ddr3_casn_buf;
//OBUF #(
//  .IOSTANDARD("SSTL15")
//) OBUF_ddr3_casn (
//  .I (ddr3_casn_buf),
//  .O (ddr3_casn)
//);
//
//wire ddr3_wen_buf;
//OBUF #(
//  .IOSTANDARD("SSTL15")
//) OBUF_ddr3_wen (
//  .I (ddr3_wen_buf),
//  .O (ddr3_wen)
//);
//
//wire [1:0] ddr3_cke_buf;
//OBUF #(
//  .IOSTANDARD("SSTL15")
//) OBUF_ddr3_cke[1:0] (
//  .I (ddr3_cke_buf),
//  .O ({ddr3_cke1, ddr3_cke0})
//);
//wire [1:0] ddr3_odt_buf;
//OBUF #(
//  .IOSTANDARD("SSTL15")
//) OBUF_ddr3_odt[1:0] (
//  .I (ddr3_odt_buf),
//  .O ({ddr3_odt1, ddr3_odt0})
//);
//
//wire ddr3_resetn_buf;
//OBUF #(
//  .IOSTANDARD("SSTL15")
//) OBUF_ddr3_resetn (
//  .I (ddr3_resetn_buf),
//  .O (ddr3_resetn)
//);
//
//assign ddr3_resetn_buf = ddr3_dq_bufi[0:0];
//assign ddr3_odt_buf    = ddr3_dq_bufi[1:0];
//assign ddr3_cke_buf    = ddr3_dq_bufi[1:0];
//assign ddr3_wen_buf    = ddr3_dq_bufi[0:0];
//assign ddr3_casn_buf   = ddr3_dq_bufi[0:0];
//assign ddr3_rasn_buf   = ddr3_dq_bufi[0:0];
//assign ddr3_sn_buf     = ddr3_dq_bufi[3:0];
//assign ddr3_a_buf      = ddr3_dq_bufi[15:0];
//assign ddr3_ba_buf     = ddr3_dq_bufi[2:0];
//assign ddr3_dm_buf     = ddr3_dq_bufi[8:0];
//assign ddr3_ck_buf     = ddr3_dq_bufi[0:0];
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

  assign v6_gpio[8] = clk_125;
  assign v6_gpio[11] = recclk_125;

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

  assign regin_0 = {3'b0, mac_syncacquired,  1'b0, sgmii_rxclkcorcnt, 3'b0, sgmii_reset, 3'b0, sgmii_pll_locked, 3'b0, sgmii_encommaalign, 3'b0, sgmii_resetdone, 3'b0, sgmii_txbufstatus[1], 3'b0, sgmii_rxbufstatus[2]};
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

  assign regin_1 = foo0;
  assign regin_2 = foo1;
  assign regin_3 = foo2;
  assign regin_4 = foo3;
  assign regin_5 = foo4;
  assign regin_6 = foo5;
  assign regin_7 = foo6;

  /*
  wire [31:0] regout_0;
  wire [31:0] regout_1;
  wire [31:0] regout_2;
  wire [31:0] regout_3;
  wire [31:0] regout_4;
  wire [31:0] regout_5;
  wire [31:0] regout_6;
  wire [31:0] regout_7;
  */

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

endmodule
