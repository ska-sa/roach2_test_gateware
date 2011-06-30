`timescale 1ns/1ps
module tge_bus_attach #(
    parameter FABRIC_MAC     = 48'hffff_ffff_ffff,
    parameter FABRIC_IP      = 32'hffff_ffff,
    parameter FABRIC_PORT    = 16'hffff,
    parameter FABRIC_GATEWAY = 8'd0,
    parameter FABRIC_ENABLE  = 0,
    parameter SWING          = 1,
    parameter PREEMPHASYS    = 1
  )(
    // CPU Bus Attachment
    input         wb_clk_i,
    input         wb_rst_i,
    input         wb_stb_i,
    input         wb_cyc_i,
    input         wb_we_i,
    input  [31:0] wb_adr_i,
    input  [31:0] wb_dat_i,
    input   [3:0] wb_sel_i,
    output [31:0] wb_dat_o,
    output        wb_err_o,
    output        wb_ack_o,
    //tx_buffer bits
    output  [7:0] cpu_tx_buffer_addr,
    input  [63:0] cpu_tx_buffer_rd_data,
    output [63:0] cpu_tx_buffer_wr_data,
    output        cpu_tx_buffer_wr_en,
    output  [7:0] cpu_tx_size,
    output        cpu_tx_ready,
    input         cpu_tx_done,
    //rx_buffer bits
    output  [7:0] cpu_rx_buffer_addr,
    input  [63:0] cpu_rx_buffer_rd_data,
    input   [7:0] cpu_rx_size,
    output        cpu_rx_ack,
    //ARP Cache
    output  [7:0] arp_cache_addr,
    input  [47:0] arp_cache_rd_data,
    output [47:0] arp_cache_wr_data,
    output        arp_cache_wr_en,
    //local registers
    output        local_enable,
    output [47:0] local_mac,
    output [31:0] local_ip,
    output [15:0] local_port,
    output  [7:0] local_gateway,
    output        soft_reset,
    input         soft_reset_ack,
    //xaui status
    input  [31:0] phy_status,
    //MGT/GTP PMA Config
    output  [1:0] mgt_rxeqmix,
    output  [3:0] mgt_rxeqpole,
    output  [2:0] mgt_txpreemphasis,
    output  [2:0] mgt_txdiffctrl
  );

  /************* Generic Bus Assignments *************/

  wire        cpu_clk = wb_clk_i;
  wire        cpu_rst = wb_rst_i;

  wire  [3:0] cpu_sel   = wb_sel_i;
  wire        cpu_rnw   = !wb_we_i;
  wire        cpu_trans = !wb_ack_o && wb_stb_i && wb_cyc_i; 
  wire [13:0] cpu_addr  = wb_adr_i[13:0];
  wire [31:0] cpu_din   = wb_dat_i;

  wire        cpu_ack;
  wire        cpu_err;
  wire [31:0] cpu_dout;

  assign wb_ack_o = cpu_ack;
  assign wb_err_o = cpu_err;
  assign wb_dat_o = cpu_dout;

  /************* Address Decoding *************/

  localparam REGISTERS_OFFSET = 32'h0000;
  localparam REGISTERS_HIGH   = 32'h07FF;
  localparam TX_BUFFER_OFFSET = 32'h1000;
  localparam TX_BUFFER_HIGH   = 32'h17FF;
  localparam RX_BUFFER_OFFSET = 32'h2000;
  localparam RX_BUFFER_HIGH   = 32'h27FF;
  localparam ARP_CACHE_OFFSET = 32'h3000;
  localparam ARP_CACHE_HIGH   = 32'h37FF;

  wire reg_sel   = (cpu_addr >= REGISTERS_OFFSET) && (cpu_addr <= REGISTERS_HIGH);
  wire rxbuf_sel = (cpu_addr >= RX_BUFFER_OFFSET) && (cpu_addr <= RX_BUFFER_HIGH);
  wire txbuf_sel = (cpu_addr >= TX_BUFFER_OFFSET) && (cpu_addr <= TX_BUFFER_HIGH);
  wire arp_sel   = (cpu_addr >= ARP_CACHE_OFFSET) && (cpu_addr <= ARP_CACHE_HIGH);

  wire [31:0] reg_addr   = cpu_addr - REGISTERS_OFFSET;
  wire [31:0] rxbuf_addr = cpu_addr - RX_BUFFER_OFFSET;
  wire [31:0] txbuf_addr = cpu_addr - TX_BUFFER_OFFSET;
  wire [31:0] arp_addr   = cpu_addr - ARP_CACHE_OFFSET;

  /************** Registers ****************/
  
  localparam REG_LOCAL_MAC_1   = 4'd0;
  localparam REG_LOCAL_MAC_0   = 4'd1;
  localparam REG_LOCAL_GATEWAY = 4'd3;
  localparam REG_LOCAL_IPADDR  = 4'd4;
  localparam REG_BUFFER_SIZES  = 4'd6;
  localparam REG_VALID_PORTS   = 4'd8;
  localparam REG_XAUI_STATUS   = 4'd9;
  localparam REG_PHY_CONFIG    = 4'd10;

  reg [47:0] local_mac_reg;
  reg [31:0] local_ip_reg;
  reg  [7:0] local_gateway_reg;
  reg [15:0] local_port_reg;
  reg        local_enable_reg;
  reg  [1:0] mgt_rxeqmix_reg;
  reg  [3:0] mgt_rxeqpole_reg;
  reg  [2:0] mgt_txpreemphasis_reg;
  reg  [2:0] mgt_txdiffctrl_reg;
  reg        soft_reset_reg;

  assign local_mac         = local_mac_reg;
  assign local_ip          = local_ip_reg;
  assign local_gateway     = local_gateway_reg;
  assign local_port        = local_port_reg;
  assign local_enable      = local_enable_reg;
  assign mgt_rxeqmix       = mgt_rxeqmix_reg;
  assign mgt_rxeqpole      = mgt_rxeqpole_reg;
  assign mgt_txpreemphasis = mgt_txpreemphasis_reg;
  assign mgt_txdiffctrl    = mgt_txdiffctrl_reg;
  assign soft_reset        = soft_reset_reg;

  reg use_arp_data, use_tx_data, use_rx_data;

  reg [3:0] cpu_data_src;
  reg       cpu_ack_reg;

  /* RX/TX Buffer Control regs */

  reg [7:0] cpu_tx_size_reg;
  reg       cpu_tx_ready_reg;
  reg       cpu_rx_ack_reg;
  assign cpu_tx_size  = cpu_tx_size_reg;
  assign cpu_tx_ready = cpu_tx_ready_reg;
  assign cpu_rx_ack   = cpu_rx_ack_reg;

  reg cpu_wait;
  always @(posedge cpu_clk) begin
    //strobes
    cpu_ack_reg      <= 1'b0;
    use_arp_data     <= 1'b0;
    use_tx_data      <= 1'b0;
    use_rx_data      <= 1'b0;

    /* When the 10ge wrapper has sent the packet we tell the user by clearing 
       the size register */
    if (cpu_tx_done) begin
      cpu_tx_size_reg  <= 8'd0;
      cpu_tx_ready_reg <= 1'b0;
    end

    /* The size will be set to zero when the double buffer is swapped */
    if (cpu_tx_size == 8'd0) begin
      cpu_rx_ack_reg  <= 1'b0;
    end

    if (cpu_rst) begin
      cpu_data_src      <= 4'b0;

      local_mac_reg     <= FABRIC_MAC;
      local_ip_reg      <= FABRIC_IP;
      local_gateway_reg <= FABRIC_GATEWAY;
      local_port_reg    <= FABRIC_PORT;
      local_enable_reg  <= FABRIC_ENABLE;

      cpu_tx_size_reg   <= 8'd0;

      cpu_rx_ack_reg  <= 1'b0;

      /* TODO: add decode PREEMPHASYS/SWING feature */
      mgt_rxeqmix_reg       <= 2'b00;
      mgt_rxeqpole_reg      <= 4'b0000;
      mgt_txpreemphasis_reg <= 3'b000;
      mgt_txdiffctrl_reg    <= 3'b100;

      cpu_wait <= 1'b0;

      soft_reset_reg <= 1'b0;

    end else if (cpu_wait) begin
      cpu_wait    <= 1'b0;
      cpu_ack_reg <= 1'b1;
    end else begin

      if (soft_reset_ack) begin
        soft_reset_reg <= 1'b0;
      end

      if (cpu_trans)
        cpu_ack_reg <= 1'b1;

      // ARP Cache
      if (arp_sel) begin 
        if (!cpu_rnw) begin
          cpu_ack_reg  <= 1'b0;
          cpu_wait <= 1'b1;
        end else begin
          use_arp_data <= 1'b1;
        end
      end

      // RX Buffer 
      if (rxbuf_sel) begin
        if (!cpu_rnw) begin
        end else begin
          use_rx_data <= 1'b1;
        end
      end

      // TX Buffer 
      if (txbuf_sel) begin
        if (!cpu_rnw) begin
          cpu_ack_reg  <= 1'b0;
          cpu_wait <= 1'b1;
        end else begin
          use_tx_data <= 1'b1;
        end
      end

      // registers
      if (reg_sel) begin
        cpu_data_src <= reg_addr[5:2];
        if (!cpu_rnw) begin
          case (reg_addr[5:2])
            REG_LOCAL_MAC_1: begin
              if (cpu_sel[0])
                local_mac_reg[39:32] <= cpu_din[7:0];
              if (cpu_sel[1])
                local_mac_reg[47:40] <= cpu_din[15:8];
            end
            REG_LOCAL_MAC_0: begin
              if (cpu_sel[0])
                local_mac_reg[7:0]   <= cpu_din[7:0];
              if (cpu_sel[1])
                local_mac_reg[15:8]  <= cpu_din[15:8];
              if (cpu_sel[2])
                local_mac_reg[23:16] <= cpu_din[23:16];
              if (cpu_sel[3])
                local_mac_reg[31:24] <= cpu_din[31:24];
            end
            REG_LOCAL_GATEWAY: begin
              if (cpu_sel[0])
                local_gateway_reg[7:0] <= cpu_din[7:0];
            end
            REG_LOCAL_IPADDR: begin
              if (cpu_sel[0])
                local_ip_reg[7:0]   <= cpu_din[7:0];
              if (cpu_sel[1])
                local_ip_reg[15:8]  <= cpu_din[15:8];
              if (cpu_sel[2])
                local_ip_reg[23:16] <= cpu_din[23:16];
              if (cpu_sel[3])
                local_ip_reg[31:24] <= cpu_din[31:24];
            end
            REG_BUFFER_SIZES: begin
              if (cpu_sel[0] && cpu_din[7:0] == 8'b0) begin
                cpu_rx_ack_reg <= 1'b1;
              end
              if (cpu_sel[2]) begin
                cpu_tx_size_reg  <= cpu_din[23:16];
                cpu_tx_ready_reg <= 1'b1;
              end
            end
            REG_VALID_PORTS: begin
              if (cpu_sel[0])
                local_port_reg[7:0]  <= cpu_din[7:0];
              if (cpu_sel[1])
                local_port_reg[15:8] <= cpu_din[15:8];
              if (cpu_sel[2])
                local_enable_reg     <= cpu_din[16];
              if (cpu_sel[3] && cpu_din[24])
                soft_reset_reg       <= 1'b1;
            end
            REG_XAUI_STATUS: begin
            end
            REG_PHY_CONFIG: begin
              if (cpu_sel[0])
                mgt_rxeqmix_reg       <= cpu_din[1:0];
              if (cpu_sel[1])
                mgt_rxeqpole_reg      <= cpu_din[11:8];
              if (cpu_sel[2])
                mgt_txpreemphasis_reg <= cpu_din[18:16];
              if (cpu_sel[3])
                mgt_txdiffctrl_reg    <= cpu_din[26:24];
            end
            default: begin
            end
          endcase
        end
      end
    end
  end

  /********* Handle memory interfaces ***********/

  reg arp_cache_we, tx_buffer_we;

  reg [63:0] write_data; //write data for all three buffers

  always @(posedge cpu_clk) begin
    //strobes
    arp_cache_we <= 1'b0;
    tx_buffer_we <= 1'b0;

    if (cpu_clk) begin
    end else begin
      //populate write_data according to wishbone transaction info & contents
      //of memory
      if (arp_sel && cpu_wait) begin
        arp_cache_we <= 1'b1;

        write_data[ 7: 0] <= arp_addr[2] == 1'b1 & cpu_sel[0] ? cpu_din[ 7: 0] : arp_cache_rd_data[ 7: 0]; 
        write_data[15: 8] <= arp_addr[2] == 1'b1 & cpu_sel[1] ? cpu_din[15: 8] : arp_cache_rd_data[15: 8]; 
        write_data[23:16] <= arp_addr[2] == 1'b1 & cpu_sel[2] ? cpu_din[23:16] : arp_cache_rd_data[23:16]; 
        write_data[31:24] <= arp_addr[2] == 1'b1 & cpu_sel[3] ? cpu_din[31:24] : arp_cache_rd_data[31:24]; 
        write_data[39:32] <= arp_addr[2] == 1'b0 & cpu_sel[0] ? cpu_din[ 7: 0] : arp_cache_rd_data[39:32]; 
        write_data[47:40] <= arp_addr[2] == 1'b0 & cpu_sel[1] ? cpu_din[15: 8] : arp_cache_rd_data[47:40]; 
      end
      if (txbuf_sel && cpu_wait) begin
        tx_buffer_we <= 1'b1;

        write_data[7:0]   <= txbuf_addr[2] == 1'b1 & cpu_sel[0] ? cpu_din[ 7: 0] : cpu_tx_buffer_rd_data[ 7: 0];
        write_data[15:8]  <= txbuf_addr[2] == 1'b1 & cpu_sel[1] ? cpu_din[15: 8] : cpu_tx_buffer_rd_data[15: 8];
        write_data[23:16] <= txbuf_addr[2] == 1'b1 & cpu_sel[2] ? cpu_din[23:16] : cpu_tx_buffer_rd_data[23:16]; 
        write_data[31:24] <= txbuf_addr[2] == 1'b1 & cpu_sel[3] ? cpu_din[31:24] : cpu_tx_buffer_rd_data[31:24]; 
        write_data[39:32] <= txbuf_addr[2] == 1'b0 & cpu_sel[0] ? cpu_din[ 7: 0] : cpu_tx_buffer_rd_data[39:32]; 
        write_data[47:40] <= txbuf_addr[2] == 1'b0 & cpu_sel[1] ? cpu_din[15: 8] : cpu_tx_buffer_rd_data[47:40]; 
        write_data[55:48] <= txbuf_addr[2] == 1'b0 & cpu_sel[2] ? cpu_din[23:16] : cpu_tx_buffer_rd_data[55:48]; 
        write_data[63:56] <= txbuf_addr[2] == 1'b0 & cpu_sel[3] ? cpu_din[31:24] : cpu_tx_buffer_rd_data[63:56]; 
      end
    end
  end

  // memory assignments
  assign arp_cache_addr        =   arp_addr[10:3];
  assign arp_cache_wr_data     = write_data[47:0];
  assign arp_cache_wr_en       = arp_cache_we;

  assign cpu_tx_buffer_addr    = txbuf_addr[10:3];
  assign cpu_tx_buffer_wr_data = write_data;
  assign cpu_tx_buffer_wr_en   = tx_buffer_we;

  assign cpu_rx_buffer_addr    = rxbuf_addr[10:3];

  // select what data to put on the bus
  wire [31:0] arp_data_int =   arp_addr[2] == 1'b1 ? arp_cache_rd_data[31:0] : {16'b0, arp_cache_rd_data[47:32]};
  wire [31:0] tx_data_int  = txbuf_addr[2] == 1'b1 ? cpu_tx_buffer_rd_data[31:0] : cpu_tx_buffer_rd_data[63:32];
  wire [31:0] rx_data_int  = rxbuf_addr[2] == 1'b1 ? cpu_rx_buffer_rd_data[31:0] : cpu_rx_buffer_rd_data[63:32];

  wire [31:0] cpu_data_int = cpu_data_src == REG_LOCAL_MAC_1   ? {16'b0, local_mac[47:32]} :
                             cpu_data_src == REG_LOCAL_MAC_0   ? local_mac[31:0] :
                             cpu_data_src == REG_LOCAL_GATEWAY ? {24'b0, local_gateway} :
                             cpu_data_src == REG_LOCAL_IPADDR  ? local_ip[31:0] :
                             cpu_data_src == REG_BUFFER_SIZES  ? {8'b0, cpu_tx_size, 8'b0, cpu_rx_ack ? 8'b0 : cpu_rx_size} :
                             cpu_data_src == REG_VALID_PORTS   ? {7'b0, soft_reset, 7'b0, local_enable, local_port} :
                             cpu_data_src == REG_XAUI_STATUS   ? {phy_status} :
                             cpu_data_src == REG_PHY_CONFIG    ? {5'b0, mgt_txdiffctrl, 5'b0, mgt_txpreemphasis,
                                                                  4'b0, mgt_rxeqpole,   6'b0, mgt_rxeqmix} :
                                                                 16'b0;
  assign cpu_dout = use_arp_data ? arp_data_int :
                    use_tx_data  ? tx_data_int  :
                    use_rx_data  ? rx_data_int  :
                                   cpu_data_int;

  assign cpu_err  = 1'b0;
  assign cpu_ack  = cpu_ack_reg;

endmodule
