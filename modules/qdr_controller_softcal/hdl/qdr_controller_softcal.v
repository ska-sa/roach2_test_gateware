module qdr_controller_softcal (
    wb_clk_i,
    wb_rst_i,
    wb_cyc_i,
    wb_stb_i,
    wb_we_i,
    wb_sel_i,
    wb_adr_i,
    wb_dat_i,
    wb_dat_o,
    wb_ack_o,
    wb_err_o,
    /* QDR Infrastructure */
    clk0,
    clk180,
    clk270,
    reset, //release when clock and delay elements are stable 
    /* Physical QDR Signals */
    qdr_d,
    qdr_q,
    qdr_sa,
    qdr_w_n,
    qdr_r_n,
    qdr_doff_n,
    qdr_k,
    qdr_k_n,
    /* QDR PHY ready */
    phy_rdy, cal_fail,
    /* QDR read interface */
    usr_rd_strb,
    usr_wr_strb,
    usr_addr,

    usr_rd_data,
    usr_rd_dvld,

    usr_wr_data
  );
  parameter DATA_WIDTH   = 36;
  parameter ADDR_WIDTH   = 22;

  input         wb_clk_i;
  input         wb_rst_i;
  input         wb_cyc_i;
  input         wb_stb_i;
  input         wb_we_i;
  input   [3:0] wb_sel_i;
  input  [31:0] wb_adr_i;
  input  [31:0] wb_dat_i;
  output [31:0] wb_dat_o;
  output        wb_ack_o;
  output        wb_err_o;

  input clk0, clk180, clk270;
  input reset;

  output [DATA_WIDTH - 1:0] qdr_d;
  input  [DATA_WIDTH - 1:0] qdr_q;
  output [ADDR_WIDTH - 1:0] qdr_sa;
  output qdr_w_n;
  output qdr_r_n;
  output qdr_doff_n;
  output qdr_k;
  output qdr_k_n;

  output phy_rdy;
  output cal_fail;

  input  usr_rd_strb;
  input  usr_wr_strb;
  input                [31:0] usr_addr;

  output [2*DATA_WIDTH - 1:0] usr_rd_data;
  output usr_rd_dvld;

  input  [2*DATA_WIDTH - 1:0] usr_wr_data;

  wire         doffn;
  /* Enable the software calibration */
  wire         cal_en;
  /* Calibration setup is complete */
  wire         cal_rdy;
  /* Select the bit that we are calibrating */
  wire  [7:0]  bit_select;
  /* strobe to tick IODELAY delay tap */
  wire         dll_en;
  /* Direction of IO delay */
  wire         dll_inc_dec_n;
  /* IODELAY value reset */
  wire         dll_rst;
  /* Set to enable additional delay to compensate for half cycle delay */
  wire         align_en;
  wire         align_strb;
  /* Sampled value */
  wire  [1:0]  data_value;
  /* has the value been sampled 32 times */
  wire         data_sampled;
  /* has the value stayed valid after being sampled 32 times */
  wire         data_valid;

  qdrc_cpu_attach cpu_attach_inst (
    .wb_clk_i      (wb_clk_i),
    .wb_rst_i      (wb_rst_i),
    .wb_cyc_i      (wb_cyc_i),
    .wb_stb_i      (wb_stb_i),
    .wb_we_i       (wb_we_i),
    .wb_sel_i      (wb_sel_i),
    .wb_adr_i      (wb_adr_i),
    .wb_dat_i      (wb_dat_i),
    .wb_dat_o      (wb_dat_o),
    .wb_ack_o      (wb_ack_o),
    .wb_err_o      (wb_err_o),
    .doffn         (doffn),
    .cal_en        (cal_en),
    .cal_rdy       (cal_rdy),
    .bit_select    (bit_select),
    .dll_en        (dll_en),
    .dll_inc_dec_n (dll_inc_dec_n),
    .dll_rst       (dll_rst),
    .align_en      (align_en),
    .align_strb    (align_strb),
    .data_in       (data_value),
    .data_sampled  (data_sampled),
    .data_valid    (data_valid)
  );

  qdrc_top #(
    .DATA_WIDTH   (DATA_WIDTH  ),
    .ADDR_WIDTH   (ADDR_WIDTH  )
  ) qdrc_top_inst (
    .clk0    (clk0),
    .clk180  (clk180),
    .clk270  (clk270),
    .div_clk (wb_clk_i),
    .reset   (reset),

    .phy_rdy  (phy_rdy),
    .cal_fail (cal_fail),

    .qdr_d         (qdr_d),
    .qdr_q         (qdr_q),
    .qdr_sa        (qdr_sa),
    .qdr_w_n       (qdr_w_n),
    .qdr_r_n       (qdr_r_n),
    .qdr_k         (qdr_k),
    .qdr_k_n       (qdr_k_n),
    .qdr_dll_off_n (qdr_doff_n),

    .usr_rd_strb (usr_rd_strb),
    .usr_wr_strb (usr_wr_strb),
    .usr_addr    (usr_addr[ADDR_WIDTH-1:0]),
    .usr_rd_data (usr_rd_data),
    .usr_rd_dvld (usr_rd_dvld),
    .usr_wr_data (usr_wr_data),

    .doffn         (doffn),
    .cal_en        (cal_en),
    .cal_rdy       (cal_rdy),
    .bit_select    (bit_select),
    .dll_en        (dll_en),
    .dll_inc_dec_n (dll_inc_dec_n),
    .dll_rst       (dll_rst),
    .align_en      (align_en),
    .align_strb    (align_strb),
    .data_value    (data_value),
    .data_sampled  (data_sampled),
    .data_valid    (data_valid)
  );

endmodule
