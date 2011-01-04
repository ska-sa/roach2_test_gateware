module gtx_skeleton(
    input  [3:0] rx_n,
    input  [3:0] rx_p,
    output [3:0] tx_n,
    output [3:0] tx_p,

    input  mgtrefclk0_n,
    input  mgtrefclk0_p,
    input  mgtrefclk1_n,
    input  mgtrefclk1_p,
    output refclk_o_0,
    output refclk_o_1,
    
    input  refclk_i
  );

  GTX_WRAPPER GTX_WRAPPER_quad(
    .GTX0_LOOPBACK_IN    (3'b0),
    .GTX0_RXPOWERDOWN_IN (2'b0),
    .GTX0_TXPOWERDOWN_IN (2'b0),
    .GTX0_RXCHARISCOMMA_OUT (),
    .GTX0_RXCHARISK_OUT     (),
    .GTX0_RXDISPERR_OUT     (),
    .GTX0_RXNOTINTABLE_OUT  (),
    .GTX0_RXCHANBONDSEQ_OUT (),
    .GTX0_RXCHBONDI_IN      (4'b0),
    .GTX0_RXCHBONDLEVEL_IN  (3'b0),
    .GTX0_RXCHBONDMASTER_IN (1'b0),
    .GTX0_RXCHBONDO_OUT     (),
    .GTX0_RXCHBONDSLAVE_IN  (1'b0),
    .GTX0_RXENCHANSYNC_IN   (1'b0),
    .GTX0_RXCLKCORCNT_OUT   (),
    .GTX0_RXBYTEISALIGNED_OUT (),
    .GTX0_RXBYTEREALIGN_OUT   (),
    .GTX0_RXCOMMADET_OUT      (),
    .GTX0_RXENMCOMMAALIGN_IN  (1'b0),
    .GTX0_RXENPCOMMAALIGN_IN  (1'b0),
    .GTX0_PRBSCNTRESET_IN     (1'b0),
    .GTX0_RXENPRBSTST_IN      (3'b0),
    .GTX0_RXPRBSERR_OUT       (),    
    .GTX0_RXDATA_OUT          (),
    .GTX0_RXRESET_IN          (1'b0),
    .GTX0_RXUSRCLK2_IN        (1'b0),
    .GTX0_RXCDRRESET_IN       (1'b0),
    .GTX0_RXELECIDLE_OUT      (),
    .GTX0_RXEQMIX_IN          (3'b0),
    .GTX0_RXN_IN              (rx_n[0]),
    .GTX0_RXP_IN              (rx_p[0]),
    .GTX0_RXBUFRESET_IN(1'b0),
    .GTX0_RXBUFSTATUS_OUT(),
    .GTX0_RXCHANISALIGNED_OUT(),
    .GTX0_RXCHANREALIGN_OUT(),
    .GTX0_RXLOSSOFSYNC_OUT(),
    .GTX0_GTXRXRESET_IN  (1'b0),
    .GTX0_MGTREFCLKRX_IN (refclk_i),
    .GTX0_PLLRXRESET_IN  (1'b0),
    .GTX0_RXPLLLKDET_OUT(),
    .GTX0_RXRESETDONE_OUT(),
    .GTX0_DADDR_IN(8'b0),
    .GTX0_DCLK_IN(1'b0),
    .GTX0_DEN_IN(1'b0),
    .GTX0_DI_IN(16'b0),
    .GTX0_DRDY_OUT(),
    .GTX0_DRPDO_OUT(),
    .GTX0_DWE_IN(1'b0),
    .GTX0_TXCHARISK_IN(2'b0),
    .GTX0_TXDATA_IN(16'b0),
    .GTX0_TXOUTCLK_OUT(),
    .GTX0_TXRESET_IN(1'b0),
    .GTX0_TXUSRCLK2_IN(1'b0),
    .GTX0_TXDIFFCTRL_IN(4'b0),
    .GTX0_TXN_OUT(tx_n[0]),
    .GTX0_TXP_OUT(tx_p[0]),
    .GTX0_TXPOSTEMPHASIS_IN(5'b0),
    .GTX0_TXPREEMPHASIS_IN(4'b0),
    .GTX0_TXDLYALIGNDISABLE_IN(1'b0),
    .GTX0_TXDLYALIGNMONITOR_OUT(),
    .GTX0_TXDLYALIGNRESET_IN(1'b0),
    .GTX0_TXENPMAPHASEALIGN_IN(1'b0),
    .GTX0_TXPMASETPHASE_IN(1'b0),
    .GTX0_GTXTXRESET_IN(1'b0),
    .GTX0_TXRESETDONE_OUT(),
    .GTX0_TXENPRBSTST_IN(3'b0),
    .GTX0_TXPRBSFORCEERR_IN(1'b0),
    .GTX0_TXELECIDLE_IN(1'b0),

    .GTX1_LOOPBACK_IN    (3'b0),
    .GTX1_RXPOWERDOWN_IN (2'b0),
    .GTX1_TXPOWERDOWN_IN (2'b0),
    .GTX1_RXCHARISCOMMA_OUT (),
    .GTX1_RXCHARISK_OUT     (),
    .GTX1_RXDISPERR_OUT     (),
    .GTX1_RXNOTINTABLE_OUT  (),
    .GTX1_RXCHANBONDSEQ_OUT (),
    .GTX1_RXCHBONDI_IN      (4'b0),
    .GTX1_RXCHBONDLEVEL_IN  (3'b0),
    .GTX1_RXCHBONDMASTER_IN (1'b0),
    .GTX1_RXCHBONDO_OUT     (),
    .GTX1_RXCHBONDSLAVE_IN  (1'b0),
    .GTX1_RXENCHANSYNC_IN   (1'b0),
    .GTX1_RXCLKCORCNT_OUT   (),
    .GTX1_RXBYTEISALIGNED_OUT (),
    .GTX1_RXBYTEREALIGN_OUT   (),
    .GTX1_RXCOMMADET_OUT      (),
    .GTX1_RXENMCOMMAALIGN_IN  (1'b0),
    .GTX1_RXENPCOMMAALIGN_IN  (1'b0),
    .GTX1_PRBSCNTRESET_IN     (1'b0),
    .GTX1_RXENPRBSTST_IN      (3'b0),
    .GTX1_RXPRBSERR_OUT       (),    
    .GTX1_RXDATA_OUT          (),
    .GTX1_RXRESET_IN          (1'b0),
    .GTX1_RXUSRCLK2_IN        (1'b0),
    .GTX1_RXCDRRESET_IN       (1'b0),
    .GTX1_RXELECIDLE_OUT      (),
    .GTX1_RXEQMIX_IN          (3'b0),
    .GTX1_RXN_IN              (rx_n[1]),
    .GTX1_RXP_IN              (rx_p[1]),
    .GTX1_RXBUFRESET_IN(1'b0),
    .GTX1_RXBUFSTATUS_OUT(),
    .GTX1_RXCHANISALIGNED_OUT(),
    .GTX1_RXCHANREALIGN_OUT(),
    .GTX1_RXLOSSOFSYNC_OUT(),
    .GTX1_GTXRXRESET_IN  (1'b0),
    .GTX1_MGTREFCLKRX_IN (refclk_i),
    .GTX1_PLLRXRESET_IN  (1'b0),
    .GTX1_RXPLLLKDET_OUT(),
    .GTX1_RXRESETDONE_OUT(),
    .GTX1_DADDR_IN(8'b0),
    .GTX1_DCLK_IN(1'b0),
    .GTX1_DEN_IN(1'b0),
    .GTX1_DI_IN(16'b0),
    .GTX1_DRDY_OUT(),
    .GTX1_DRPDO_OUT(),
    .GTX1_DWE_IN(1'b0),
    .GTX1_TXCHARISK_IN(2'b0),
    .GTX1_TXDATA_IN(16'b0),
    .GTX1_TXOUTCLK_OUT(),
    .GTX1_TXRESET_IN(1'b0),
    .GTX1_TXUSRCLK2_IN(1'b0),
    .GTX1_TXDIFFCTRL_IN(4'b0),
    .GTX1_TXN_OUT(tx_n[1]),
    .GTX1_TXP_OUT(tx_p[1]),
    .GTX1_TXPOSTEMPHASIS_IN(5'b0),
    .GTX1_TXPREEMPHASIS_IN(4'b0),
    .GTX1_TXDLYALIGNDISABLE_IN(1'b0),
    .GTX1_TXDLYALIGNMONITOR_OUT(),
    .GTX1_TXDLYALIGNRESET_IN(1'b0),
    .GTX1_TXENPMAPHASEALIGN_IN(1'b0),
    .GTX1_TXPMASETPHASE_IN(1'b0),
    .GTX1_GTXTXRESET_IN(1'b0),
    .GTX1_TXRESETDONE_OUT(),
    .GTX1_TXENPRBSTST_IN(3'b0),
    .GTX1_TXPRBSFORCEERR_IN(1'b0),
    .GTX1_TXELECIDLE_IN(1'b0),

    .GTX2_LOOPBACK_IN    (3'b0),
    .GTX2_RXPOWERDOWN_IN (2'b0),
    .GTX2_TXPOWERDOWN_IN (2'b0),
    .GTX2_RXCHARISCOMMA_OUT (),
    .GTX2_RXCHARISK_OUT     (),
    .GTX2_RXDISPERR_OUT     (),
    .GTX2_RXNOTINTABLE_OUT  (),
    .GTX2_RXCHANBONDSEQ_OUT (),
    .GTX2_RXCHBONDI_IN      (4'b0),
    .GTX2_RXCHBONDLEVEL_IN  (3'b0),
    .GTX2_RXCHBONDMASTER_IN (1'b0),
    .GTX2_RXCHBONDO_OUT     (),
    .GTX2_RXCHBONDSLAVE_IN  (1'b0),
    .GTX2_RXENCHANSYNC_IN   (1'b0),
    .GTX2_RXCLKCORCNT_OUT   (),
    .GTX2_RXBYTEISALIGNED_OUT (),
    .GTX2_RXBYTEREALIGN_OUT   (),
    .GTX2_RXCOMMADET_OUT      (),
    .GTX2_RXENMCOMMAALIGN_IN  (1'b0),
    .GTX2_RXENPCOMMAALIGN_IN  (1'b0),
    .GTX2_PRBSCNTRESET_IN     (1'b0),
    .GTX2_RXENPRBSTST_IN      (3'b0),
    .GTX2_RXPRBSERR_OUT       (),    
    .GTX2_RXDATA_OUT          (),
    .GTX2_RXRESET_IN          (1'b0),
    .GTX2_RXUSRCLK2_IN        (1'b0),
    .GTX2_RXCDRRESET_IN       (1'b0),
    .GTX2_RXELECIDLE_OUT      (),
    .GTX2_RXEQMIX_IN          (3'b0),
    .GTX2_RXN_IN              (rx_n[2]),
    .GTX2_RXP_IN              (rx_p[2]),
    .GTX2_RXBUFRESET_IN(1'b0),
    .GTX2_RXBUFSTATUS_OUT(),
    .GTX2_RXCHANISALIGNED_OUT(),
    .GTX2_RXCHANREALIGN_OUT(),
    .GTX2_RXLOSSOFSYNC_OUT(),
    .GTX2_GTXRXRESET_IN  (1'b0),
    .GTX2_MGTREFCLKRX_IN (refclk_i),
    .GTX2_PLLRXRESET_IN  (1'b0),
    .GTX2_RXPLLLKDET_OUT(),
    .GTX2_RXRESETDONE_OUT(),
    .GTX2_DADDR_IN(8'b0),
    .GTX2_DCLK_IN(1'b0),
    .GTX2_DEN_IN(1'b0),
    .GTX2_DI_IN(16'b0),
    .GTX2_DRDY_OUT(),
    .GTX2_DRPDO_OUT(),
    .GTX2_DWE_IN(1'b0),
    .GTX2_TXCHARISK_IN(2'b0),
    .GTX2_TXDATA_IN(16'b0),
    .GTX2_TXOUTCLK_OUT(),
    .GTX2_TXRESET_IN(1'b0),
    .GTX2_TXUSRCLK2_IN(1'b0),
    .GTX2_TXDIFFCTRL_IN(4'b0),
    .GTX2_TXN_OUT(tx_n[2]),
    .GTX2_TXP_OUT(tx_p[2]),
    .GTX2_TXPOSTEMPHASIS_IN(5'b0),
    .GTX2_TXPREEMPHASIS_IN(4'b0),
    .GTX2_TXDLYALIGNDISABLE_IN(1'b0),
    .GTX2_TXDLYALIGNMONITOR_OUT(),
    .GTX2_TXDLYALIGNRESET_IN(1'b0),
    .GTX2_TXENPMAPHASEALIGN_IN(1'b0),
    .GTX2_TXPMASETPHASE_IN(1'b0),
    .GTX2_GTXTXRESET_IN(1'b0),
    .GTX2_TXRESETDONE_OUT(),
    .GTX2_TXENPRBSTST_IN(3'b0),
    .GTX2_TXPRBSFORCEERR_IN(1'b0),
    .GTX2_TXELECIDLE_IN(1'b0),

    .GTX3_LOOPBACK_IN    (3'b0),
    .GTX3_RXPOWERDOWN_IN (2'b0),
    .GTX3_TXPOWERDOWN_IN (2'b0),
    .GTX3_RXCHARISCOMMA_OUT (),
    .GTX3_RXCHARISK_OUT     (),
    .GTX3_RXDISPERR_OUT     (),
    .GTX3_RXNOTINTABLE_OUT  (),
    .GTX3_RXCHANBONDSEQ_OUT (),
    .GTX3_RXCHBONDI_IN      (4'b0),
    .GTX3_RXCHBONDLEVEL_IN  (3'b0),
    .GTX3_RXCHBONDMASTER_IN (1'b0),
    .GTX3_RXCHBONDO_OUT     (),
    .GTX3_RXCHBONDSLAVE_IN  (1'b0),
    .GTX3_RXENCHANSYNC_IN   (1'b0),
    .GTX3_RXCLKCORCNT_OUT   (),
    .GTX3_RXBYTEISALIGNED_OUT (),
    .GTX3_RXBYTEREALIGN_OUT   (),
    .GTX3_RXCOMMADET_OUT      (),
    .GTX3_RXENMCOMMAALIGN_IN  (1'b0),
    .GTX3_RXENPCOMMAALIGN_IN  (1'b0),
    .GTX3_PRBSCNTRESET_IN     (1'b0),
    .GTX3_RXENPRBSTST_IN      (3'b0),
    .GTX3_RXPRBSERR_OUT       (),    
    .GTX3_RXDATA_OUT          (),
    .GTX3_RXRESET_IN          (1'b0),
    .GTX3_RXUSRCLK2_IN        (1'b0),
    .GTX3_RXCDRRESET_IN       (1'b0),
    .GTX3_RXELECIDLE_OUT      (),
    .GTX3_RXEQMIX_IN          (3'b0),
    .GTX3_RXN_IN              (rx_n[3]),
    .GTX3_RXP_IN              (rx_p[3]),
    .GTX3_RXBUFRESET_IN(1'b0),
    .GTX3_RXBUFSTATUS_OUT(),
    .GTX3_RXCHANISALIGNED_OUT(),
    .GTX3_RXCHANREALIGN_OUT(),
    .GTX3_RXLOSSOFSYNC_OUT(),
    .GTX3_GTXRXRESET_IN  (1'b0),
    .GTX3_MGTREFCLKRX_IN (refclk_i),
    .GTX3_PLLRXRESET_IN  (1'b0),
    .GTX3_RXPLLLKDET_OUT(),
    .GTX3_RXRESETDONE_OUT(),
    .GTX3_DADDR_IN(8'b0),
    .GTX3_DCLK_IN(1'b0),
    .GTX3_DEN_IN(1'b0),
    .GTX3_DI_IN(16'b0),
    .GTX3_DRDY_OUT(),
    .GTX3_DRPDO_OUT(),
    .GTX3_DWE_IN(1'b0),
    .GTX3_TXCHARISK_IN(2'b0),
    .GTX3_TXDATA_IN(16'b0),
    .GTX3_TXOUTCLK_OUT(),
    .GTX3_TXRESET_IN(1'b0),
    .GTX3_TXUSRCLK2_IN(1'b0),
    .GTX3_TXDIFFCTRL_IN(4'b0),
    .GTX3_TXN_OUT(tx_n[3]),
    .GTX3_TXP_OUT(tx_p[3]),
    .GTX3_TXPOSTEMPHASIS_IN(5'b0),
    .GTX3_TXPREEMPHASIS_IN(4'b0),
    .GTX3_TXDLYALIGNDISABLE_IN(1'b0),
    .GTX3_TXDLYALIGNMONITOR_OUT(),
    .GTX3_TXDLYALIGNRESET_IN(1'b0),
    .GTX3_TXENPMAPHASEALIGN_IN(1'b0),
    .GTX3_TXPMASETPHASE_IN(1'b0),
    .GTX3_GTXTXRESET_IN(1'b0),
    .GTX3_TXRESETDONE_OUT(),
    .GTX3_TXENPRBSTST_IN(3'b0),
    .GTX3_TXPRBSFORCEERR_IN(1'b0),
    .GTX3_TXELECIDLE_IN(1'b0),

    .MGTREFCLK0_N (mgtrefclk0_n),
    .MGTREFCLK0_P (mgtrefclk0_p),
    .MGTREFCLK1_N (mgtrefclk1_n),
    .MGTREFCLK1_P (mgtrefclk1_p),
    .MGTREFCLK0   (refclk_o_0),
    .MGTREFCLK1   (refclk_o_1)
  );
endmodule
