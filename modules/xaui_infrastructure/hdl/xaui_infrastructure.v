module xaui_infrastructure #(
    parameter ENABLE_MASK = 8'b1111_1111
  ) (
    input             mgt_reset,

    input       [2:0] xaui_refclk_n,
    input       [2:0] xaui_refclk_p,

    input   [8*4-1:0] mgt_rx_n,
    input   [8*4-1:0] mgt_rx_p,
    output  [8*4-1:0] mgt_tx_n,
    output  [8*4-1:0] mgt_tx_p,

    output            xaui_clk,

    input   [8*1-1:0] mgt_tx_rst,
    input   [8*1-1:0] mgt_rx_rst,

    input  [8*64-1:0] mgt_txdata,
    input   [8*8-1:0] mgt_txcharisk,

    output [8*64-1:0] mgt_rxdata,
    output  [8*8-1:0] mgt_rxcharisk,
    output  [8*8-1:0] mgt_rxcodecomma,
    input   [8*4-1:0] mgt_rxencommaalign,
    input   [8*1-1:0] mgt_rxenchansync,
    output  [8*4-1:0] mgt_rxsyncok,
    output  [8*8-1:0] mgt_rxcodevalid,
    output  [8*4-1:0] mgt_rxbufferr,

    output  [8*4-1:0] mgt_rxlock,
    output  [8*4-1:0] mgt_rxelecidle,

    input   [8*1-1:0] mgt_loopback,
    input   [8*1-1:0] mgt_powerdown,

    input   [8*5-1:0] mgt_txpostemphasis,
    input   [8*4-1:0] mgt_txpreemphasis,
    input   [8*4-1:0] mgt_txdiffctrl,
    input   [8*3-1:0] mgt_rxeqmix,

    output [8*16-1:0] mgt_status
  );

  wire [2:0] gtx_refclk;
  wire [2:0] pma_reset;

  IBUFDS_GTXE1 gtk_clkbuf[2:0] (
    .I     (xaui_refclk_p),
    .IB    (xaui_refclk_n),
    .CEB   (1'b0),
    .O     (gtx_refclk),
    .ODIV2 ()
  );

  wire gtx_clk_o;

  BUFG bufg_xaui_clk(
    .I (gtx_clk_o),
    .O (xaui_clk)
  );

  wire [2:0] gtx_refclk_bufr;

  BUFR bufr_gtx_refclk[2:0](
    .I   (gtx_refclk),
    .O   (gtx_refclk_bufr),
    .CE  (1'b1),
    .CLR (1'b0)
  );

  /* synchronize pma reset to local gtx_refclk_bufr domain */
  // I'm not actually sure why, but the sgmii example did this so...

  reg  [3:0] reset_r[2:0];

  always@(posedge gtx_refclk_bufr[0] or posedge mgt_reset) begin
    if (mgt_reset == 1'b1) begin
      reset_r[0] <= 4'b1111;
    end else begin
      reset_r[0] <= {reset_r[0][2:0], mgt_reset};
    end
  end

  always@(posedge gtx_refclk_bufr[1] or posedge mgt_reset) begin
    if (mgt_reset == 1'b1) begin
      reset_r[1] <= 4'b1111;
    end else begin
      reset_r[1] <= {reset_r[1][2:0], mgt_reset};
    end
  end

  always@(posedge gtx_refclk_bufr[2] or posedge mgt_reset) begin
    if (mgt_reset == 1'b1) begin
      reset_r[2] <= 4'b1111;
    end else begin
      reset_r[2] <= {reset_r[2][2:0], mgt_reset};
    end
  end

  assign pma_reset = {reset_r[2], reset_r[1], reset_r[0]};

  /* Which pma resets and gtx_refclks go where */
  wire [7:0] pma_reset_map;
  wire [7:0] gtx_refclk_map;

  /* which GTX output clock should we use use as the xaui reference clock.
     Note that all clocks are generated from the source source using a PLL, this means
     that we can use one clock for all application interfaces */
  wire [8*4-1:0] gtxclk_out_map;
  assign gtx_clk_o = gtxclk_out_map[0];

  wire [8*8-1:0] mgt_rxdisperror;
  wire [8*8-1:0] mgt_rxnotintable;
  assign mgt_rxcodevalid = ~(mgt_rxdisperror | mgt_rxnotintable);

  wire [8*8-1:0] rxlossofsync;

  wire [8*4-1:0] rx_resetdone;
  wire [8*4-1:0] tx_resetdone;

  genvar I;
generate for (I=0; I < 8; I=I+1) begin : gtx_wrap_gen

  gtx_quad gtx_quad_inst (
    //---------------------- Loopback and Powerdown Ports ----------------------
    .LOOPBACK_IN                    (mgt_loopback[I]),
    .RXPOWERDOWN_IN                 (mgt_powerdown[I]),
    .TXPOWERDOWN_IN                 (mgt_powerdown[I]),
    //--------------------- Receive Ports - 8b10b Decoder ----------------------
    .RXCHARISCOMMA_OUT              (mgt_rxcodecomma[I*8+:8]),
    .RXCHARISK_OUT                  (mgt_rxcharisk[I*8+:8]),
    .RXDISPERR_OUT                  (mgt_rxdisperror[I*8+:8]),
    .RXNOTINTABLE_OUT               (mgt_rxnotintable[I*8+:8]),
    //------------- Receive Ports - Comma Detection and Alignment --------------
    .RXENMCOMMAALIGN_IN             (mgt_rxencommaalign[I*4+:4]),
    .RXENPCOMMAALIGN_IN             (mgt_rxencommaalign[I*4+:4]),

    .RXENCHANSYNC_IN                (mgt_rxenchansync[I]),
    //----------------- Receive Ports - RX Data Path interface -----------------
    .RXDATA_OUT                     (mgt_rxdata[I*64+:64]),
    .RXRESET_IN                     (gtx_rx_reset),
    .RXUSRCLK2_IN                   (xaui_clk),
    //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
    .RXCDRRESET_IN                  (pma_reset_map[I]),
    .RXELECIDLE_OUT                 (mgt_rxelecidle[I*4+:4]),
    .RXEQMIX_IN                     (mgt_rxeqmix[I*3+:3]),
    .RXN_IN                         (mgt_rx_n[I*4+:4]),
    .RXP_IN                         (mgt_rx_p[I*4+:4]),
    //------ Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
    .RXBUFRESET_IN                  (gtx_rx_reset),
    .RXBUFSTATUS_OUT                (mgt_rxbufferr[I*4+:4]),
    //------------- Receive Ports - RX Loss-of-sync State Machine --------------
    .RXLOSSOFSYNC_OUT               (rxlossofsync[I*8+:8]),
    //---------------------- Receive Ports - RX PLL Ports ----------------------
    .GTXRXRESET_IN                  (pma_reset_map[I]),
    .MGTREFCLKRX_IN                 (gtx_refclk_map[I]),
    .PLLRXRESET_IN                  (pma_reset_map[I]),
    .RXPLLLKDET_OUT                 (mgt_rxlock[I*4+:4]),
    .RXRESETDONE_OUT                (rx_resetdone[I*4+:4]),
    //---------------- Transmit Ports - TX Data Path interface -----------------
    .TXCHARISK_IN                   (mgt_txcharisk[I*8+:8]),
    .TXDATA_IN                      (mgt_txdata[I*64+:64]),

    .TXOUTCLK_OUT                   (gtxclk_out_map[I*4+:4]),        
    .TXRESET_IN                     (gtx_tx_reset),
    .TXUSRCLK2_IN                   (xaui_clk),
    //-------------- Transmit Ports - TX Driver and OOB signaling --------------
    .TXDIFFCTRL_IN                  (mgt_txdiffctrl[I*4+:4]),
    .TXN_OUT                        (mgt_tx_n[I*4+:4]),
    .TXP_OUT                        (mgt_tx_p[I*4+:4]),
    .TXPOSTEMPHASIS_IN              (mgt_txpostemphasis[I*5+:5]),
    //------------- Transmit Ports - TX Driver and OOB signalling --------------
    .TXPREEMPHASIS_IN               (mgt_txpreemphasis[I*4+:4]),
    //--------------------- Transmit Ports - TX PLL Ports ----------------------
    .GTXTXRESET_IN                  (pma_reset_map[I]),
    .MGTREFCLKTX_IN                 (gtx_refclk_map[I]),
    .PLLTXRESET_IN                  (1'b0),
    .TXRESETDONE_OUT                (tx_resetdone[I*4+:4])
  );

  assign mgt_rxsyncok[I*4+:4] = {rxlossofsync[I*8+7],
                                 rxlossofsync[I*8+5],
                                 rxlossofsync[I*8+3],
                                 rxlossofsync[I*8+1]};

  assign mgt_status[I*16+:16] = {4'b0, mgt_rxbufferr[I*4+:4], 4'b0, mgt_rxelecidle[I*4+:4]};
end endgenerate

  /* Which pma resets and gtx_refclks go where */

  assign gtx_refclk_map = { gtx_refclk[2],  gtx_refclk[2],  gtx_refclk[2],
                            gtx_refclk[1],  gtx_refclk[1],  gtx_refclk[1],
                            gtx_refclk[0],  gtx_refclk[0]};

  assign pma_reset_map = { pma_reset[2],  pma_reset[2],  pma_reset[2],
                           pma_reset[1],  pma_reset[1],  pma_reset[1],
                           pma_reset[0],  pma_reset[0]};

  
endmodule
