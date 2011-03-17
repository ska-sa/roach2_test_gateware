`timescale 1ns/1ps

`define SIM_LENGTH 100000

`define APPCLK_PERIOD 4
`define MACCLK_PERIOD 8
`define CPUCLK_PERIOD 10
module TB_gbe_dup();


  localparam LOCAL_MAC        = 48'h02_03_04_05_06_07;
  localparam LOCAL_IP         = {8'd192, 8'd168, 8'd69, 8'd5};
  localparam LOCAL_PORT       = 16'hdead;
  localparam LOCAL_GATEWAY    = 8'd1;

  /* Loopback test */
  localparam APP_DEST_IP      = LOCAL_IP;
  localparam APP_DEST_PORT    = LOCAL_PORT;

  localparam APP_TX_FRAMESIZE = 4096;

  localparam CPU_TX_FRAMESIZE = 512;
  localparam CPU_FRAME        = 10;

/**** Application Interface ****/
  wire        app_clk_i;

  wire  [7:0] app_tx_data;
  wire        app_tx_dvld;
  wire        app_tx_eof;
  wire [31:0] app_tx_destip;
  wire [15:0] app_tx_destport;
  wire        app_tx_afull;
  wire        app_tx_overflow;
  wire        app_tx_rst;

  wire  [7:0] app_rx_data;
  wire        app_rx_dvld;
  wire        app_rx_eof;
  wire [31:0] app_rx_srcip;
  wire [15:0] app_rx_srcport;
  wire        app_rx_badframe;
  wire        app_rx_overrun;
  wire        app_rx_ack;
  wire        app_rx_rst;

/**** MAC Interface ****/

  wire        mac_tx_clk;
  wire        mac_tx_rst;
  wire  [7:0] mac_tx_data;
  wire        mac_tx_dvld;
  wire        mac_tx_ack;

  wire        mac_rx_clk;
  wire        mac_rx_rst;
  wire  [7:0] mac_rx_data;
  wire        mac_rx_dvld;
  wire        mac_rx_goodframe;
  wire        mac_rx_badframe;

/**** PHY Status/Control ****/
  wire [31:0] phy_status;
  wire [31:0] phy_control;

/**** CPU Bus Attachment ****/
  wire        wb_clk_i;
  wire        wb_rst_i;
  wire        wb_stb_i;
  wire        wb_cyc_i;
  wire        wb_we_i;
  wire [31:0] wb_adr_i;
  wire [31:0] wb_dat_i;
  wire  [3:0] wb_sel_i;
  wire [31:0] wb_dat_o;
  wire        wb_err_o;
  wire        wb_ack_o;

 gbe_udp #(
   .LOCAL_ENABLE      (1),
   .LOCAL_MAC         (LOCAL_MAC),
   .LOCAL_IP          (LOCAL_IP),
   .LOCAL_PORT        (LOCAL_PORT),
   .LOCAL_GATEWAY     (LOCAL_GATEWAY),
   .CPU_PROMISCUOUS   (1),
   .PHY_CONFIG        (0),
   .DIS_CPU_TX        (0),
   .DIS_CPU_RX        (0),
   .TX_LARGE_PACKETS  (0),
   .RX_DIST_RAM       (0),
   .ARP_CACHE_INIT    (0)
  ) gbe_udp_inst (
    .app_clk(app_clk_i),

    .app_tx_data(app_tx_data),
    .app_tx_dvld(app_tx_dvld),
    .app_tx_eof(app_tx_eof),
    .app_tx_destip(app_tx_destip),
    .app_tx_destport(app_tx_destport),

    .app_tx_afull(app_tx_afull),
    .app_tx_overflow(app_tx_overflow),
    .app_tx_rst(app_tx_rst),

    .app_rx_data(app_rx_data),
    .app_rx_dvld(app_rx_dvld),
    .app_rx_eof(app_rx_eof),
    .app_rx_srcip(app_rx_srcip),
    .app_rx_srcport(app_rx_srcport),
    .app_rx_badframe(app_rx_badframe),

    .app_rx_overrun(app_rx_overrun),
    .app_rx_ack(app_rx_ack),
    .app_rx_rst(app_rx_rst),

    .mac_tx_clk(mac_tx_clk),
    .mac_tx_rst(mac_tx_rst),
    .mac_tx_data(mac_tx_data),
    .mac_tx_dvld(mac_tx_dvld),
    .mac_tx_ack(mac_tx_ack),

    .mac_rx_clk(mac_rx_clk),
    .mac_rx_rst(mac_rx_rst),
    .mac_rx_data(mac_rx_data),
    .mac_rx_dvld(mac_rx_dvld),
    .mac_rx_goodframe(mac_rx_goodframe),
    .mac_rx_badframe(mac_rx_badframe),

    .phy_status(phy_status),
    .phy_control(phy_control),

    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wb_stb_i(wb_stb_i),
    .wb_cyc_i(wb_cyc_i),
    .wb_we_i(wb_we_i),
    .wb_adr_i(wb_adr_i),
    .wb_dat_i(wb_dat_i),
    .wb_sel_i(wb_sel_i),
    .wb_dat_o(wb_dat_o),
    .wb_err_o(wb_err_o),
    .wb_ack_o(wb_ack_o)
  );


  reg [31:0] clk_counter;
  reg rst;

  initial begin
    $dumpvars;
    clk_counter <= 32'b0;
    rst <= 1'b1;
    #100
    rst <= 1'b0;
    #`SIM_LENGTH
    $display("FAILED: simulation timed out");
    $finish;
  end

  always
   #1 clk_counter <= clk_counter + 1;

  wire app_clk = (clk_counter % (`APPCLK_PERIOD)) < ((`APPCLK_PERIOD)/2);
  wire mac_clk = (clk_counter % (`MACCLK_PERIOD)) < ((`MACCLK_PERIOD)/2);
  wire cpu_clk = (clk_counter % (`CPUCLK_PERIOD)) < ((`CPUCLK_PERIOD)/2);

  /************************* MODE *****************************/

  reg  [4:0] mode;
  reg [10:0] mode_done;
  localparam MODE_TX_OVERFLOW = 0;
  localparam MODE_TX_OVERWAIT = 1;
  localparam MODE_RX_OVERRUN  = 2;
  localparam MODE_RX_OVERWAIT = 3;
  localparam MODE_CPU         = 4;


  /************************* APP TX *****************************/

  assign app_clk_i = app_clk;

  reg app_rst;
  always @(posedge app_clk) begin
    app_rst <= rst;
  end

  reg [33:0] app_tx_counter;
  reg        app_tx_en;

  /* we send a 32-bit counter */

  reg wait_overflow_clear;

  reg tx_overflow_rst;

  always @(posedge app_clk) begin
    tx_overflow_rst <= 1'b0;

    if (app_rst) begin
      mode_done[MODE_TX_OVERFLOW] <= 1'b0;
      app_tx_counter <= 34'h0;
      app_tx_en <= 1'b0;
      wait_overflow_clear <= 1'b0;
    end else begin
      case (mode)
        MODE_TX_OVERFLOW: begin
          if (wait_overflow_clear) begin
            if (!app_tx_overflow)  begin
              mode_done[MODE_TX_OVERFLOW] <= 1'b1;
            end
          end else begin
            app_tx_en <= 1'b1;
            if (app_tx_overflow) begin
              tx_overflow_rst     <= 1'b1;
              wait_overflow_clear <= 1'b1;
              app_tx_en <= 1'b0;
            end
          end
        end
        default : begin
          if (app_tx_afull)
            app_tx_en <= 1'b0;
          if (!app_tx_afull)
            app_tx_en <= 1'b1;

          if (app_tx_en)
            app_tx_counter <= app_tx_counter + 1;

          if (app_tx_overflow) begin
            $display("FAILED: unexpected tx buffer overflow");
            $finish;
          end
        end
      endcase
    end
  end

  assign app_tx_data     = app_tx_counter[1:0] == 0 : (app_tx_counter >>  2) & 8'hff:
                           app_tx_counter[1:0] == 1 : (app_tx_counter >> 10) & 8'hff:
                           app_tx_counter[1:0] == 2 : (app_tx_counter >> 18) & 8'hff:
                           app_tx_counter[1:0] == 3 : (app_tx_counter >> 26) & 8'hff:

  assign app_tx_dvld     = app_tx_en && !app_rst;
  assign app_tx_eof      = mode == MODE_TX_OVERFLOW ? 1'b0:
                           (app_tx_counter % APP_TX_FRAME_SIZE) == APP_TX_FRAME_SIZE - 1;
  assign app_tx_destip   = APP_DEST_IP;
  assign app_tx_destport = APP_DEST_PORT;
  assign app_tx_rst      = app_rst || app_tx_overflow &&app_tx_en;

  /************************* APP RX **************************/

  reg app_rx_ack_reg;

  reg        rx_counter_valid;
  reg [31:0] rx_counter;

  reg [31:0] rx_data;
  reg  [1:0] rx_data_index;

  reg        rx_data_check;

  always @(posedge app_clk) begin
    rx_data_check <= 1'b0;

    if (app_rst) begin
      app_rx_ack_reg   <= 1'b0;
      rx_counter_valid <= 1'b0;
      rx_data_index    <= 2'b0;
      mode_done[MODE_RX_OVERRUN]  <= 1'b0;
      mode_done[MODE_RX_OVERWAIT] <= 1'b0;
    end else begin
      if (rx_data_check) begin
        rx_counter_valid <= 1'b1;
        rx_counter       <= rx_data;

        if (rx_data != (rx_counter + 1) && rx_counter_valid) begin
          $display("FAILED: app rx data mismatch - got %x, expected %x", rx_data, rx_counter + 1);
          $finish;
        end
      end

      case (mode)
        MODE_TX_OVERFLOW : begin
          app_rx_ack_reg <= 1'b1;
        end
        MODE_TX_OVERWAIT : begin
          app_rx_ack_reg <= 1'b1;
        end
        MODE_RX_OVERRUN  : begin
          app_rx_ack_reg <= 1'b0;
          if (app_rx_overrun)
            mode_done[MODE_RX_OVERRUN] <= 1'b1;
        end
        MODE_RX_OVERWAIT : begin
          app_rx_ack_reg <= 1'b1;
          if (!app_rx_overrun && app_rx_eof && app_rx_dvld)
            mode_done[MODE_RX_OVERWAIT] <= 1'b1;
        end
        default: begin
          app_rx_ack_reg <= 1'b1;
          if (app_rx_dvld && app_rx_ack) begin
            rx_data_index <= rx_data_index + 1;
            case (rx_data_index)
              0: begin
                rx_data[7:0]  <= app_rx_data;
              end
              1: begin
                rx_data[15:8]  <= app_rx_data;
              end
              2: begin
                rx_data[23:16] <= app_rx_data;
              end
              3: begin
                rx_data[31:24] <= app_rx_data;
                rx_data_check <= 1'b1;
              end
            endcase
          end
        end
      endcase
    end
  end


  /******************* MAC *******************/

  /* A simple loopback */
  

  /* TX */
  assign mac_tx_clk = mac_clk;
  reg mac_rst;
  always @(posedge mac_clk) begin
    mac_rst <= rst;
  end
  assign mac_tx_rst = mac_rst;

  reg [1:0] mac_tx_state;
  reg [3:0] wait_counter;

  always @(posedge mac_clk) begin
    if (mac_rst) begin
      mac_tx_state <= 1'b0;
    end else begin
      case (mac_tx_state)
        0: begin
          if (mac_tx_dvld)
            mac_tx_state <= 1;
        end
        1: begin
          mac_tx_state <= 2;
        end
        2: begin
          wait_counter <= 15;
          if (!mac_tx_dvld)
            mac_tx_state <= 3;
        end
        3: begin
          if (wait_counter == 0) begin
            mac_tx_state <= 0;
          end
          wait_counter <= wait_counter - 1;
        end
      endcase
    end
  end

  assign mac_tx_ack = mac_tx_state == 1;

  reg [31:0] foo_index;

  /* RX */
  assign mac_rx_clk  = mac_clk;
  assign mac_rx_rst  = mac_rst;
  assign mac_rx_data = mac_tx_data;
  assign mac_rx_dvld = mac_tx_dvld && (mac_tx_state == 1 || mac_tx_state == 2);

  /* A number of cycles later */

  assign mac_rx_goodframe = mac_tx_state == 3 && wait_counter == 10;
  assign mac_rx_badframe  = 1'b0;

  /************************ CPU Master ******************************/

  reg cpu_rst;
  always @(posedge cpu_clk) begin
    cpu_rst <= rst;
  end

  reg         cpu_stb;
  reg         cpu_rnw;
  reg   [3:0] cpu_sel;
  reg  [31:0] cpu_adr;
  reg  [31:0] cpu_dat_wr;
  wire [31:0] cpu_dat_rd;
  wire        cpu_ack;

  reg  [2:0] cpu_state;
  reg [15:0] cpu_buffer_index;
  reg        cpu_wait_ack;
  localparam CPU_IDLE   = 0;
  localparam CPU_WRWAIT = 1;
  localparam CPU_WR     = 2;
  localparam CPU_WRSEND = 3;
  localparam CPU_RDWAIT = 4;
  localparam CPU_RD     = 5;
  localparam CPU_RDSEND = 6;
  localparam CPU_DONE   = 7;

  reg [31:0] cpu_progress;


  always @(posedge cpu_clk) begin
    cpu_sel <= 1'b0;

    if (cpu_rst) begin
      cpu_state           <= CPU_IDLE;
      cpu_wait_ack        <= 1'b0;
      cpu_progress        <= 32'b0;
      cpu_buffer_index    <= 16'h0;
      mode_done[MODE_CPU] <= 1'b0;
    end else begin
      case (cpu_state)
        CPU_IDLE : begin
          if (mode == MODE_CPU) begin
            cpu_state <= CPU_WR;
          end
        end
        CPU_WRWAIT : begin
        end
        CPU_WR : begin
        end
        CPU_WRSEND : begin
        end
        CPU_RDWAIT : begin
        end
        CPU_RD : begin
        end
        CPU_RDACK : begin
        end
        CPU_DONE : begin
          mode_done[MODE_CPU] <= 1'b0;
        end
      endcase
    end
  end

  assign wb_clk_i   = cpu_clk;
  assign wb_rst_i   = cpu_rst;

  assign wb_stb_i   = cpu_stb;
  assign wb_cyc_i   = cpu_stb;
  assign wb_we_i    = !cpu_rnw;
  assign wb_adr_i   = cpu_adr;
  assign wb_dat_i   = cpu_dat_wr;
  assign wb_sel_i   = cpu_sel;

  assign cpu_dat_rd = wb_dat_o;
  assign cpu_ack    = wb_ack_o;



endmodule
