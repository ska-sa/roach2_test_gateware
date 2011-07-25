module qdr_cpu_interface(
    input         wb_clk_i,
    input         wb_rst_i,
    input         wb_cyc_i,
    input         wb_stb_i,
    input         wb_we_i,
    input   [3:0] wb_sel_i,
    input  [31:0] wb_adr_i,
    input  [31:0] wb_dat_i,
    output [31:0] wb_dat_o,
    output        wb_ack_o,
    output        wb_err_o,

    input         qdr_clk,
    input         qdr_rst,

    input         phy_rdy,
    input         cal_fail,

    output [31:0] qdr_addr,
    output        qdr_wr_en,
    output [71:0] qdr_wr_data,

    output        qdr_rd_en,
    input  [71:0] qdr_rd_data,
    input         qdr_rd_dvld
  );
  assign wb_err_o = 1'b0;

  reg wb_ack_reg;
  assign wb_ack_o = wb_ack_reg;

  wire wb_trans = !wb_ack_reg && wb_cyc_i && wb_stb_i;

  always @(posedge wb_clk_i) begin
    wb_ack_reg <= 1'b0;
    if (wb_trans) begin
      wb_ack_reg <= 1'b1;
    end
  end

  reg [143:0] rd_buffer;
  reg [143:0] wr_buffer;
  reg  [31:0] addr_buffer;

  reg rd_trans;
  reg wr_trans;

  wire rd_ack;
  wire wr_ack;

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      rd_trans <= 1'b0;
      wr_trans <= 1'b0;
    end else begin
      if (rd_ack) begin
        rd_trans <= 1'b0;
      end

      if (wr_ack) begin
        wr_trans <= 1'b0;
      end

      if (wb_trans & wb_we_i) begin
        case (wb_adr_i[6:2])
          1: begin
            if (wb_dat_i[0]) begin
              rd_trans <= 1'b1;
            end else if (wb_dat_i[8]) begin
              wr_trans <= 1'b1;
            end
          end
          2: begin
            addr_buffer <= wb_dat_i[31:0];
          end

          8: begin
            wr_buffer[143:128] <= wb_dat_i[15:0];
          end
          9: begin
            wr_buffer[127:96] <= wb_dat_i;
          end
          10: begin
            wr_buffer[95:64] <= wb_dat_i;
          end
          11: begin
            wr_buffer[63:32] <= wb_dat_i;
          end
          12: begin
            wr_buffer[31:0] <= wb_dat_i;
          end

        endcase
      end
    end
  end

  reg [31:0] wb_dat_o_reg;
  assign wb_dat_o = wb_dat_o_reg;

  always @(*) begin
    case (wb_adr_i[6:2])
      0: wb_dat_o_reg <= {16'b0, 7'b0, cal_fail, 7'b0, phy_rdy};
      1: wb_dat_o_reg <= {16'b0, 7'b0, wr_trans, 7'b0, rd_trans};
      2: wb_dat_o_reg <= addr_buffer;

      8: wb_dat_o_reg <= wr_buffer[143:128];
      9: wb_dat_o_reg <= wr_buffer[127:96];
     10: wb_dat_o_reg <= wr_buffer[95:64];
     11: wb_dat_o_reg <= wr_buffer[63:32];
     12: wb_dat_o_reg <= wr_buffer[31:0];

     16: wb_dat_o_reg <= rd_buffer[143:128];
     17: wb_dat_o_reg <= rd_buffer[127:96];
     18: wb_dat_o_reg <= rd_buffer[95:64];
     19: wb_dat_o_reg <= rd_buffer[63:32];
     20: wb_dat_o_reg <= rd_buffer[31:0];

     default: 
        wb_dat_o_reg  <= 32'b0;
    endcase
  end

  /***** transaction handshaking *****/

  reg wr_ack_unstable;

  reg wr_ackR;
  reg wr_ackRR;
  assign wr_ack = wr_ackRR;

  always @(posedge wb_clk_i) begin
    wr_ackR  <= wr_ack_unstable;
    wr_ackRR <= wr_ackR;
  end

  reg rd_ack_unstable;

  reg rd_ackR;
  reg rd_ackRR;
  assign rd_ack = rd_ackRR;

  always @(posedge wb_clk_i) begin
    rd_ackR  <= rd_ack_unstable;
    rd_ackRR <= rd_ackR;
  end

  wire wr_trans_stable;
  reg wr_transR;
  reg wr_transRR;
  assign wr_trans_stable = wr_transRR;

  always @(posedge qdr_clk) begin
    wr_transR  <= wr_trans;
    wr_transRR <= wr_transR;
  end

  wire rd_trans_stable;
  reg rd_transR;
  reg rd_transRR;
  assign rd_trans_stable = rd_transRR;

  always @(posedge qdr_clk) begin
    rd_transR  <= rd_trans;
    rd_transRR <= rd_transR;
  end


  always @(posedge qdr_clk) begin

    if (wr_trans_stable)
      wr_ack_unstable <= 1'b1;

    if (wr_ack_unstable && !wr_trans_stable) 
      wr_ack_unstable <= 1'b0;
  end

  reg [1:0] wr_state;
  localparam WR_IDLE = 2'd0;
  localparam WR_0    = 2'd1;
  localparam WR_1    = 2'd2;

  reg qdr_wr_en_reg;

  always @(posedge qdr_clk) begin
    qdr_wr_en_reg <= 1'b0;
    if (qdr_rst) begin
      wr_state <= WR_IDLE;
    end else begin
      case (wr_state)
        WR_IDLE: begin
          if (wr_ack_unstable && !wr_trans_stable) begin
            wr_state <= WR_0;
            qdr_wr_en_reg <= 1'b1;
          end
        end 
        WR_0: begin
          wr_state <= WR_1;
        end
        WR_1: begin
          wr_state <= WR_IDLE;
        end
      endcase
    end
  end

  assign qdr_wr_en   = qdr_wr_en_reg;
  assign qdr_wr_data = qdr_wr_en_reg ? wr_buffer[143:72] : wr_buffer[71:0];

  reg [3:0] rd_state;
  localparam RD_IDLE  = 4'b1;
  localparam RD_TRANS = 4'b10;
  localparam RD_DATA  = 4'b100;
  localparam RD_WAIT  = 4'b1000;

  reg qdr_rd_en_reg;

  always @(posedge qdr_clk) begin
    qdr_rd_en_reg <= 1'b0;

    if (qdr_rst) begin
      rd_ack_unstable <= 1'b0;
      rd_state <= RD_IDLE;
    end else begin
      case (rd_state)
        RD_IDLE: begin
          if (rd_trans_stable) begin
            rd_state <= RD_TRANS;
            qdr_rd_en_reg <= 1'b1;
          end
        end
        RD_TRANS: begin
          if (qdr_rd_dvld) begin
            rd_state <= RD_DATA;
          end
        end
        RD_DATA: begin
          rd_state <= RD_WAIT;
          rd_ack_unstable <= 1'b1;
        end
        RD_WAIT: begin
          if (!rd_trans_stable) begin
            rd_ack_unstable <= 1'b0;
            rd_state <= RD_IDLE;
          end
        end
      endcase
    end
  end
  assign qdr_rd_en = qdr_rd_en_reg;

  always @(posedge qdr_clk) begin
    if (rd_state == RD_TRANS) begin
      rd_buffer[143:72] <= qdr_rd_data;
    end
    if (rd_state == RD_DATA) begin
      rd_buffer[71:0] <= qdr_rd_data;
    end
  end

  assign qdr_addr = addr_buffer;

endmodule
