module sgmii_phy (
    input        mgt_rx_n,
    input        mgt_rx_p,
    output       mgt_tx_n,
    output       mgt_tx_p,

    input        mgt_clk_n,
    input        mgt_clk_p,

    input        mgt_reset,

    output       clk_125,

    // MAC Interface
    input  [7:0] sgmii_txd,
    input        sgmii_txisk,
    input        sgmii_txdispmode,
    input        sgmii_txdispval,
    output       sgmii_txbuferr,
    input        sgmii_txreset,

    output [7:0] sgmii_rxd,
    output       sgmii_rxiscomma,
    output       sgmii_rxisk,
    output       sgmii_rxdisperr,
    output       sgmii_rxnotintable,
    output       sgmii_rxrundisp,
    output [2:0] sgmii_rxclkcorcnt,
    output       sgmii_rxbufstatus,
    input        sgmii_rxreset,
    

    input        sgmii_encommaalign,
    output       sgmii_pll_locked,
    output       sgmii_elecidle,

    output       sgmii_resetdone,

    input        sgmii_loopback,
    input        sgmii_powerdown
  );


  /*********** Clocks ************/

  // Clock for transceiver
  wire clk_ds;

  IBUFDS_GTXE1 clkingen (
    .I     (mgt_clk_p),
    .IB    (mgt_clk_n),
    .CEB   (1'b0),
    .O     (clk_ds),
    .ODIV2 ()
  );

  // Global buffer for output clock

  // gtp refclk out
  wire clk_125_o;
  BUFG bufg_clk_125 (
     .I (clk_125_o),
     .O (clk_125)
  );

  rocketio_wrapper_top rocketio_wrapper_top_inst (
      .RESETDONE      (sgmii_resetdone),
      .ENMCOMMAALIGN  (sgmii_encommaalign),
      .ENPCOMMAALIGN  (sgmii_encommaalign),
      .LOOPBACK       (sgmii_loopback),
      .POWERDOWN      (sgmii_powerdown),
      .RXUSRCLK2      (clk_125),
      .RXRESET        (sgmii_rxreset),
      .TXCHARDISPMODE (sgmii_txdispmode),
      .TXCHARDISPVAL  (sgmii_txdispval),
      .TXCHARISK      (sgmii_txisk),
      .TXDATA         (sgmii_txd),
      .TXUSRCLK2      (clk_125),
      .TXRESET        (sgmii_txreset),
      .RXCHARISCOMMA  (sgmii_rxiscomma),
      .RXCHARISK      (sgmii_rxisk),
      .RXCLKCORCNT    (sgmii_rxclkcorcnt),
      .RXDATA         (sgmii_rxd),
      .RXDISPERR      (sgmii_rxdisperr),
      .RXNOTINTABLE   (sgmii_rxnotintable),
      .RXRUNDISP      (sgmii_rxrundisp),
      .RXBUFERR       (sgmii_rxbufstatus),
      .TXBUFERR       (sgmii_txbuferr),
      .PLLLKDET       (sgmii_pll_locked),
      .TXOUTCLK       (clk_125_o),
      .RXELECIDLE     (sgmii_elecidle),
      .TXN            (mgt_tx_n),
      .TXP            (mgt_tx_p),
      .RXN            (mgt_rx_n),
      .RXP            (mgt_rx_p),
      .CLK_DS         (clk_ds),
      .PMARESET       (mgt_reset)
  );

endmodule
