module gbe_rx #(
    parameter DIST_RAM = 0
  ) (
    input         app_clk,

    output  [7:0] app_rx_data,
    output        app_rx_dvld,
    output        app_rx_eof,
    output [31:0] app_rx_srcip,
    output [15:0] app_rx_srcport,
    output        app_rx_badframe,

    output        app_rx_overrun,
    input         app_rx_ack,
    input         app_rx_rst,

    input         mac_rx_clk,
    input   [7:0] mac_rx_data,
    input         mac_rx_dvld,
    input         mac_rx_goodframe,
    input         mac_rx_badframe,

    input         local_enable,
    input  [47:0] local_mac,
    input  [31:0] local_ip,
    input  [15:0] local_port,

    output [10:0] cpu_addr,
    output  [7:0] cpu_wr_data,
    output        cpu_wr_en,

    output        cpu_buffer_sel,
    output [10:0] cpu_size,
    output        cpu_ready,
    input         cpu_ack
  );

endmodule
