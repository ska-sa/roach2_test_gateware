module temac #(
    parameter    REG_SGMII = 0,
    parameter    PHY_ADR   = 5'b00000
  ) (
    input        clk_125,
    input        reset,
    // SGMII Interface
    output [7:0] sgmii_txd,
    output       sgmii_txisk,
    output       sgmii_txdispmode,
    output       sgmii_txdispval,
    input        sgmii_txbuferr,
    output       sgmii_txreset,

    input  [7:0] sgmii_rxd,
    input        sgmii_rxiscomma,
    input        sgmii_rxisk,
    input        sgmii_rxdisperr,
    input        sgmii_rxnotintable,
    input        sgmii_rxrundisp,
    input  [2:0] sgmii_rxclkcorcnt,
    input        sgmii_rxbufstatus,
    output       sgmii_rxreset,
    
    output       sgmii_encommaalign,
    input        sgmii_pll_locked,
    input        sgmii_elecidle,

    input        sgmii_resetdone,

    output       sgmii_loopback,
    output       sgmii_powerdown,

    // MAC interface
    output       mac_rx_clk,
    output [7:0] mac_rx_data,
    output       mac_rx_dvld,
    output       mac_rx_goodframe,
    output       mac_rx_badframe,

    output       mac_tx_clk,
    input  [7:0] mac_tx_data,
    input        mac_tx_dvld,
    output       mac_tx_ack
  );

  // SGMII intermediate signals
  wire [7:0] sgmii_txd_int;
  wire       sgmii_txisk_int;
  wire       sgmii_txdispmode_int;
  wire       sgmii_txdispval_int;
  wire       sgmii_txbuferr_int;
  wire       sgmii_txreset_int;

  wire [7:0] sgmii_rxd_int;
  wire       sgmii_rxiscomma_int;
  wire       sgmii_rxisk_int;
  wire       sgmii_rxdisperr_int;
  wire       sgmii_rxnotintable_int;
  wire       sgmii_rxrundisp_int;
  wire [2:0] sgmii_rxclkcorcnt_int;
  wire       sgmii_rxbufstatus_int;
  wire       sgmii_rxreset_int;

  wire       sgmii_encommaalign_int;
  wire       sgmii_pll_locked_int;
  wire       sgmii_elecidle_int;

  wire       sgmii_resetdone_int;

  wire       sgmii_loopback_int;
  wire       sgmii_powerdown_int;

generate if (REG_SGMII == 0) begin : no_sgmii_reg

  assign sgmii_txd               = sgmii_txd_int;          
  assign sgmii_txisk             = sgmii_txisk_int;
  assign sgmii_txdispmode        = sgmii_txdispmode_int;
  assign sgmii_txdispval         = sgmii_txdispval_int;
  assign sgmii_txbuferr_int      = sgmii_txbuferr;
  assign sgmii_txreset           = sgmii_txreset_int;
                                 
  assign sgmii_rxd_int           = sgmii_rxd;
  assign sgmii_rxiscomma_int     = sgmii_rxiscomma;
  assign sgmii_rxisk_int         = sgmii_rxisk;
  assign sgmii_rxdisperr_int     = sgmii_rxdisperr;
  assign sgmii_rxnotintable_int  = sgmii_rxnotintable;
  assign sgmii_rxrundisp_int     = sgmii_rxrundisp;
  assign sgmii_rxclkcorcnt_int   = sgmii_rxclkcorcnt;
  assign sgmii_rxbufstatus_int   = sgmii_rxbufstatus;
  assign sgmii_rxreset           = sgmii_rxreset_int;

  assign sgmii_encommaalign      = sgmii_encommaalign_int;
  assign sgmii_pll_locked_int    = sgmii_pll_locked;
  assign sgmii_elecidle_int      = sgmii_elecidle;
                                                                           
  assign sgmii_resetdone_int     = sgmii_resetdone;
                                                                           
  assign sgmii_loopback          = sgmii_loopback_int;
  assign sgmii_powerdown         = sgmii_powerdown_int;

end else begin : sgmii_reg
 /* TODO */

end endgenerate

  /***** Reset Gen *****/
  reg [3:0] reset_r;
  always @(posedge clk_125 or posedge reset) begin
    if (reset) begin
      reset_r <= 4'b1111;
    end else begin
      if (sgmii_pll_locked) begin
        reset_r <= {reset_r[2:0], reset};
      end
    end
  end

  wire temac_reset = reset_r[3];

  /***** MAC TX clocking *****/

  BUFG bufg_mac_tx(
    .I (mac_tx_clk_bufg),
    .O (mac_tx_clk)
  );

  /***** MAC RX clocking *****/

  BUFG bufg_mac_xx(
    .I (mac_rx_clk_bufg),
    .O (mac_rx_clk)
  );

  /* Potential useful debug signals */
  wire mac_syncacquired;
  wire mac_an_interrupt;

  emac_wrapper emac_wrapper_inst
  (
    // Client receiver interface
    .EMACCLIENTRXCLIENTCLKOUT    (mac_rx_clk_bufg),
    .CLIENTEMACRXCLIENTCLKIN     (mac_rx_clk),
    .EMACCLIENTRXD               (mac_rx_data),
    .EMACCLIENTRXDVLD            (mac_rx_dvld),
    .EMACCLIENTRXDVLDMSW         (),
    .EMACCLIENTRXGOODFRAME       (mac_rx_goodframe),
    .EMACCLIENTRXBADFRAME        (mac_rx_badframe),
    // No address filter used
    .EMACCLIENTRXFRAMEDROP       (),
    // No rx stats needed
    .EMACCLIENTRXSTATS           (),
    .EMACCLIENTRXSTATSVLD        (),
    .EMACCLIENTRXSTATSBYTEVLD    (),

    // Client transmitter interface
    .EMACCLIENTTXCLIENTCLKOUT    (mac_tx_clk_bufg),
    .CLIENTEMACTXCLIENTCLKIN     (mac_tx_clk),
    .CLIENTEMACTXD               (mac_tx_data),
    .CLIENTEMACTXDVLD            (mac_tx_dvld),
    .CLIENTEMACTXDVLDMSW         (1'b0),
    .EMACCLIENTTXACK             (mac_tx_ack),
    .CLIENTEMACTXFIRSTBYTE       (1'b0),
    // we dont need to corrupt the current frame
    .CLIENTEMACTXUNDERRUN        (1'b0),
    //we dont need these, sgmii is full-duplex
    .EMACCLIENTTXCOLLISION       (),
    .EMACCLIENTTXRETRANSMIT      (),
    // 12 is the minimum ifgdelay
    .CLIENTEMACTXIFGDELAY        (8'h0c),

    // No statistics needed, though this may be potentially useful
    .EMACCLIENTTXSTATS           (),
    .EMACCLIENTTXSTATSVLD        (),
    .EMACCLIENTTXSTATSBYTEVLD    (),

    // MAC control interface
    // We dont need remote flow control
    .CLIENTEMACPAUSEREQ          (1'b0),
    .CLIENTEMACPAUSEVAL          (16'b0),

    // Clock signals
    .GTX_CLK                     (clk_125),
    .EMACPHYTXGMIIMIICLKOUT      (),
    .PHYEMACTXGMIIMIICLKIN       (1'b0),

    // SGMII interface
    .RXDATA                      (sgmii_rxd_int),
    .TXDATA                      (sgmii_txd_int),
    .MMCM_LOCKED                 (sgmii_pll_locked),
    .AN_INTERRUPT                (mac_an_interrupt),
    .SIGNAL_DETECT               (~sgmii_elecidle_int),
    .PHYAD                       (PHY_ADR),
    .ENCOMMAALIGN                (sgmii_encommaalign_int),
    .LOOPBACKMSB                 (sgmii_loopback_int),
    .MGTRXRESET                  (sgmii_rxreset_int),
    .MGTTXRESET                  (sgmii_txreset_int),
    .POWERDOWN                   (sgmii_powerdown_int),
    .SYNCACQSTATUS               (mac_syncacquired),
    .RXCLKCORCNT                 (sgmii_rxclkcorcnt_int),
    .RXBUFSTATUS                 (sgmii_rxbufstatus_int),
    .RXCHARISCOMMA               (sgmii_rxiscomma_int),
    .RXCHARISK                   (sgmii_rxisk_int),
    .RXDISPERR                   (sgmii_rxdisperr_int),
    .RXNOTINTABLE                (sgmii_rxnotintable_int),
    .RXREALIGN                   (1'b0),
    .RXRUNDISP                   (sgmii_rxrundisp_int),
    .TXBUFERR                    (sgmii_txbuferr_int),
    .TXCHARDISPMODE              (sgmii_txdispmode_int),
    .TXCHARDISPVAL               (sgmii_txdispval_int),
    .TXCHARISK                   (sgmii_txisk_int),

    // Asynchronous reset
    .RESET                       (temac_reset)
  );

endmodule
