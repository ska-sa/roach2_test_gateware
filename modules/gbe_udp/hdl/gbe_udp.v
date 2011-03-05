module gbe_udp #(
  /* Enable the application interface at startup */
    parameter LOCAL_ENABLE = 0,
  /* Default local MAC */
    parameter LOCAL_MAC = 0,
  /* Default local IP */
    parameter LOCAL_IP = 0,
  /* Default application UDP port */
    parameter LOCAL_PORT = 0,
  /* Default local gateway */
    parameter LOCAL_GATEWAY = 0,
  /* Default PHY Config */
    parameter PHY_CONFIG = 0,
  /* Disable CPU_TX */
    parameter DIS_CPU_TX = 0,
  /* Disable CPU_RX */
    parameter DIS_CPU_RX = 0,
  /* Enable large packets on TX (doubles BRAM/FIFO utilization on TX FIFO) */
    parameter TX_LARGE_PACKETS = 0,
  /* Enable distributed RAM FIFOs on RX */
    parameter RX_DIST_RAM = 0,
  /* ARP Cache initialization string */
    parameter ARP_CACHE_INIT = 0
  ) (
  /**** Application Interface ****/
    input         app_clk,

    input   [7:0] app_tx_data,
    input         app_tx_dvld,
    input         app_tx_eof,
    input  [31:0] app_tx_destip,
    input  [15:0] app_tx_destport,

    output        app_tx_afull,
    output        app_tx_overflow,
    input         app_tx_rst,

    output  [7:0] app_rx_data,
    output        app_rx_dvld,
    output        app_rx_eof,
    output [31:0] app_rx_srcip,
    output [15:0] app_rx_srcport,
    output        app_rx_badframe,

    output        app_rx_overrun,
    input         app_rx_ack,
    input         app_rx_rst,

  /**** MAC Interface ****/

    input         mac_tx_clk,
    output  [7:0] mac_tx_data,
    output        mac_tx_dvld,
    input         mac_tx_ack,

    input         mac_rx_clk,
    input   [7:0] mac_rx_data,
    input         mac_rx_dvld,
    input         mac_rx_goodframe,
    input         mac_rx_badframe,

  /**** PHY Status/Control ****/
    input  [15:0] phy_status,
    output [15:0] phy_control,

  /**** CPU Bus Attachment ****/
    input         wb_clk_i,
    input         wb_rst_i,
    input         wb_stb_i,
    input         wb_cyc_i,
    input         wb_we_i,
    input  [31:0] wb_adr_i,
    input  [31:0] wb_dat_i,
    input   [3:0] wb_stb_i,
    output [31:0] wb_dat_o,
    output        wb_err_o,
    input         wb_ack_o
  );

/****** Wishbone attachment ******/

  /* Common CPU signals */
  wire        local_enable;
  wire [47:0] local_mac;
  wire [31:0] local_ip;
  wire [15:0] local_port;
  wire  [7:0] local_gateway;

  /* ARP cache CPU signals */
  wire  [7:0] arp_cpu_cache_index;
  wire [47:0] arp_cpu_cache_rd_data;
  wire [47:0] arp_cpu_cache_wr_data;
  wire        arp_cpu_cache_wr_en;

  /* CPU TX signals */
  wire  [8:0] cputx_cpu_addr;
  wire [31:0] cputx_cpu_rd_data;
  wire [31:0] cputx_cpu_wr_data;
  wire        cputx_cpu_wr_en;
  wire [11:0] cputx_cpu_size; //up to 2k
  wire        cputx_cpu_packet_ready;
  wire        cputx_cpu_packet_ack;

  /* CPU RX signals */
  wire  [8:0] cpurx_cpu_addr;
  wire [31:0] cpurx_cpu_rd_data;
  wire [11:0] cpurx_cpu_size; //up to 2k
  wire        cpurx_cpu_packet_ready;
  wire        cpurx_cpu_packet_ack;

  gbe_cpu_attach (
    .APP_ENABLE     (LOCAL_ENABLE),
    .LOCAL_MAC      (LOCAL_MAC),
    .LOCAL_IP       (LOCAL_IP),
    .LOCAL_PORT     (LOCAL_PORT),
    .LOCAL_GATEWAY  (LOCAL_GATEWAY),
    .PHY_CONFIG     (PHY_CONFIG)
  gbe_cpu_attach_inst (
    .wb_clk_i (wb_clk_i),
    .wb_rst_i (wb_rst_i),
    .wb_stb_i (wb_stb_i),
    .wb_cyc_i (wb_cyc_i),
    .wb_we_i  (wb_we_i),
    .wb_adr_i (wb_adr_i),
    .wb_dat_i (wb_dat_i),
    .wb_stb_i (wb_stb_i),
    .wb_dat_o (wb_dat_o),
    .wb_err_o (wb_err_o),
    .wb_ack_o (wb_ack_o)
  /* Common CPU signals */
    .local_enable  (local_enable),
    .local_mac     (local_mac),
    .local_ip      (local_ip),
    .local_port    (local_port),
    .local_gateway (local_gateway),

  /* ARP cache CPU signals */
    .arp_cache_addr    (arp_cpu_cache_index),
    .arp_cache_rd_data (arp_cpu_cache_rd_data),
    .arp_cache_wr_data (arp_cpu_cache_wr_data),
    .arp_cache_wr_en   (arp_cpu_cache_wr_en),

  /* CPU RX signals */
    .cpu_rx_buffer_addr    (cpurx_cpu_addr),
    .cpu_rx_buffer_rd_data (cpurx_cpu_rd_data),
    .cpu_rx_size           (cpurx_cpu_size),
    .cpu_rx_packet_ready   (cpurx_cpu_packet_ready),
    .cpu_rx_packet_ack     (cpurx_cpu_packet_ack),

  /* CPU TX signals */
    .cpu_tx_buffer_addr    (cputx_cpu_addr),
    .cpu_tx_buffer_rd_data (cputx_cpu_rd_data),
    .cpu_tx_buffer_wr_data (cputx_cpu_wr_data),
    .cpu_tx_buffer_wr_en   (cputx_cpu_wr_en),
    .cpu_tx_size           (cputx_cpu_size),
    .cpu_tx_ready          (cputx_cpu_packet_ready),
    .cpu_tx_done           (cputx_cpu_packet_ack),
  /* PHY Status/Control */
    .phy_status  (phy_status),
    .phy_control (phy_control)
  );

/*** buffer size clock domain crossing ***/

  wire [10:0] cpu_rx_size_unstable;
  wire [10:0] cpu_tx_size_stable;
  assign cpu_rx_size = cpu_rx_size_unstable;
  assign cpu_tx_size_stable = cpu_tx_size;

  /* possible meta stability cause here
     although with handshake problems are VERY unlikely */

/*** CPU buffer Handshake clock domain crossing ***/
  wire cpu_rx_packet_ready_unstable;
  wire cpu_rx_packet_ack_stable;

  wire cpu_tx_packet_ready_stable;
  wire cpu_tx_packet_ack_unstable;

  /* RX */
  reg cpu_rx_packet_readyR;
  reg cpu_rx_packet_readyRR;

  reg cpu_rx_packet_ackR;
  reg cpu_rx_packet_ackRR;

  always @(posedge wb_clk_i) begin
    cpu_rx_packet_readyR  <= cpu_rx_packet_ready_unstable;
    cpu_rx_packet_readyRR <= cpu_rx_packet_readyR;
  end

  always @(posedge mac_rx_clk) begin
    cpu_rx_packet_ackR  <= cpu_rx_packet_ack;
    cpu_rx_packet_ackRR <= cpu_rx_packet_ackR;
  end
  assign cpu_rx_packet_ack_stable = cpu_rx_packet_ackRR;

  /* TX */
  reg cpu_tx_packet_readyR;
  reg cpu_tx_packet_readyRR;

  always @(posedge mac_tx_clk) begin
    cpu_tx_packet_readyR  <= cpu_tx_packet_ready;
    cpu_tx_packet_readyRR <= cpu_tx_packet_readyR;
  end
  assign cpu_tx_packet_ready_stable = cpu_tx_packet_readyRR;

  reg cpu_tx_packet_ackR;
  reg cpu_tx_packet_ackRR;

  always @(posedge wb_clk_i) begin
    cpu_tx_packet_ackR  <= cpu_tx_packet_ack_unstable;
    cpu_tx_packet_ackRR <= cpu_tx_packet_ackR;
  end
  assign cpu_tx_packet_ack = cpu_tx_packet_ackRR;

/****** TX Logic ******/
  /* ARP cache TX logic signals */
  wire  [7:0] arp_tx_cache_index;
  wire [47:0] arp_tx_cache_rd_data;

  /* CPU buffer TX logic signals */
  wire [10:0] cputx_tx_addr;
  wire  [7:0] cputx_tx_rd_data;
  wire        cpurx_tx_buffer_sel;

  gbe_tx #(
    .LARGE_PACKETS (TX_LARGE_PACKETS)
  ) gbe_tx_inst (
    .app_clk      (app_clk),
    .app_rst      (app_tx_rst),
    .app_data     (app_tx_data),
    .app_dvld     (app_tx_dvld),
    .app_eof      (app_tx_eof),
    .app_ip       (app_tx_destip),
    .app_port     (app_tx_destport),
    .app_afull    (app_tx_afull),
    .app_overflow (app_tx_overflow),

    .mac_tx_clk   (mac_tx_clk),
    .mac_tx_data  (mac_tx_data),
    .mac_tx_dvld  (mac_tx_dvld),
    .mac_tx_ack   (mac_tx_ack),

    .local_enable  (local_enable),
    .local_mac     (local_mac),
    .local_ip      (local_ip),
    .local_port    (local_port),
    .local_gateway (local_gateway),

    .arp_cache_index (arp_tx_cache_index),
    .arp_cache_data  (arp_tx_cache_rd_data),

    .cpu_addr        (cputx_tx_addr),
    .cpu_data        (cputx_tx_rd_data),
    .cpu_size        (cpu_tx_size_stable),
    .cpu_ready       (cpu_tx_packet_ready_stable),
    .cpu_ack         (cpu_tx_packet_ack_unstable)
    .cpu_buffer_sel  (cpurx_tx_buffer_sel)
  );

  reg cpu_tx_buffer_selR;
  reg cpu_tx_buffer_selRR;
  always @(posedge wb_clk_i) begin
    cpu_tx_buffer_selR  <= cpurx_tx_buffer_sel;
    cpu_tx_buffer_selRR <= cpurx_tx_buffer_selR;
  end
  assign cputx_cpu_buffer_sel = cpu_tx_buffer_selRR;

/****** RX Logic ******/

  /* CPU buffer RX logic signals */
  wire [10:0] cpurx_rx_addr;
  wire  [7:0] cpurx_rx_wr_data;
  wire        cpurx_rx_wr_en;
  wire        cpurx_rx_buffer_sel;

  gbe_rx #(
    .DIST_RAM (RX_DIST_RAM)
  ) gbe_tx_inst (
    .app_clk      (app_clk),
    .app_rst      (app_rx_rst),
    .app_data     (app_rx_data),
    .app_dvld     (app_rx_dvld),
    .app_ack      (app_rx_ack),
    .app_eof      (app_rx_eof),
    .app_ip       (app_rx_srcip),
    .app_port     (app_rx_srcport),
    .app_badframe (app_rx_badframe),
    .app_overrun  (app_rx_overrun),

    .mac_rx_clk    (mac_rx_clk),
    .mac_rx_data   (mac_rx_data),
    .mac_rx_dvld   (mac_rx_dvld),
    .mac_goodframe (mac_rx_goodframe),
    .mac_badframe  (mac_rx_badframe),

    .local_enable  (local_enable),
    .local_mac     (local_mac),
    .local_ip      (local_ip),
    .local_port    (local_port),
    .local_gateway (local_gateway),

    .cpu_addr       (cpurx_rx_addr);
    .cpu_wr_data    (cpurx_rx_wr_data);
    .cpu_wr_en      (cpurx_rx_wr_en);
    .cpu_size       (cpu_rx_size_unstable),
    .cpu_ready      (cpu_rx_packet_ready_unstable),
    .cpu_ack        (cpu_rx_packet_ack_stable),
    .cpu_buffer_sel (cpurx_rx_buffer_sel)
  );

  reg cpu_rx_buffer_selR;
  reg cpu_rx_buffer_selRR;
  always @(posedge wb_clk_i) begin
    cpu_rx_buffer_selR  <= cpurx_rx_buffer_sel;
    cpu_rx_buffer_selRR <= cpurx_rx_buffer_selR;
  end
  assign cpurx_cpu_buffer_sel = cpu_rx_buffer_selRR;

/****** ARP Cache ******/

  /* TODO: Optimization - shave off 1 bram
     A 48-bit memory will use two brams on virtex-6 (and others)
     due to the native BRAM geometry of 32x1k.  However, 
     we could quite comfortably use a 24 bit memory and time
     multiplex to make up 48 bits. */

  arp_cache #(
    .MEM_INIT (ARP_CACHE_INIT)
  ) arp_cache_inst (
    .clka  (wb_clk_i),
    .addra (arp_cpu_cache_index),
    .douta (arp_cpu_cache_rd_data),
    .dina  (arp_cpu_cache_wr_data),
    .wea   (arp_cpu_cache_wr_en),

    .clkb  (mac_tx_clk),
    .addrb (arp_tx_cache_index),
    .doutb (arp_tx_cache_rd_data),
    .dinb  (48'b0),
    .web   (1'b0),
  );

/****** TX Buffer ******/

generate if (DIS_CPU_TX) begin : disable_cpu_tx

  assign cputx_cpu_rd_data = 32'b0;
  assign cputx_tx_rd_data  = 8'b0;

end else begin : enable_cpu_tx

  cpu_buffer cpu_buffer_tx(
    .clka  (wb_clk_i),
    .addra ({cputx_cpu_buffer_sel, cputx_cpu_addr}),
    .douta (cputx_cpu_rd_data),
    .dina  (cputx_cpu_wr_data),
    .wea   (cputx_cpu_wr_en),

    .clkb  (mac_tx_clk),
    .addrb ({cputx_tx_buffer_sel, cputx_tx_addr}),
    .doutb (cputx_tx_rd_data),
    .dinb  (8'b0),
    .web   (1'b0),
  );
end endgenerate

/****** RX Buffer ******/

generate if (DIS_CPU_RX) begin : disable_cpu_rx

  assign cpurx_cpu_rd_data = 32'b0;

end else begin : enable_cpu_rx

  cpu_buffer cpu_buffer_rx(
    .clka  (wb_clk_i),
    .addra ({cpurx_cpu_buffer_sel, cpurx_cpu_addr}),
    .douta (cpurx_cpu_rd_data),
    .dina  (32'b0),
    .wea   (1'b0),

    .clkb  (mac_rx_clk),
    .addrb ({cpurx_rx_buffer_sel, cpurx_rx_addr}),
    .doutb (),
    .dinb  (cpurx_rx_wr_data),
    .web   (cpurx_rx_wr_en),
  );

end endgenerate



endmodule
