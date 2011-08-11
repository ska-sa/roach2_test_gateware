module ddr3_cpu_interface(
    input              wb_clk_i,
    input              wb_rst_i,
    input              wb_cyc_i,
    input              wb_stb_i,
    input              wb_we_i,
    input        [3:0] wb_sel_i,
    input       [31:0] wb_adr_i,
    input       [31:0] wb_dat_i,
    output      [31:0] wb_dat_o,
    output             wb_ack_o,
    output             wb_err_o,

    input              ddr3_clk,
    input              ddr3_rst,

    input              phy_rdy,
    input              cal_fail,

    input              app_rdy,
    output             app_en,
    output       [2:0] app_cmd,
    output      [31:0] app_addr,
    output [144*2-1:0] app_wdf_data,
    output             app_wdf_end,
    output  [18*2-1:0] app_wdf_mask,
    output             app_wdf_wren,
    input              app_wdf_rdy,
    input  [144*2-1:0] app_rd_data,
    input              app_rd_data_end,
    input              app_rd_data_valid
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

  reg [144*4 - 1:0] rd_buffer;
  reg [144*4 - 1:0] wr_buffer;
  reg        [31:0] addr_buffer;

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
        case (wb_adr_i[8:2])
          1: begin
            if (wb_dat_i[0]) begin
              rd_trans <= 1'b1;
            end else if (wb_dat_i[8]) begin
              wr_trans <= 1'b1;
            end
          end
          2: addr_buffer <= wb_dat_i[31:0];

          32: wr_buffer[575:560] <= wb_dat_i[15:0];
          33: wr_buffer[559:528] <= wb_dat_i;
          34: wr_buffer[527:496] <= wb_dat_i;
          35: wr_buffer[495:464] <= wb_dat_i;
          36: wr_buffer[463:432] <= wb_dat_i;

          40: wr_buffer[431:416] <= wb_dat_i[15:0];
          41: wr_buffer[415:384] <= wb_dat_i;
          42: wr_buffer[383:352] <= wb_dat_i;
          43: wr_buffer[351:320] <= wb_dat_i;
          44: wr_buffer[319:288] <= wb_dat_i;

          48: wr_buffer[287:272] <= wb_dat_i[15:0];
          49: wr_buffer[271:240] <= wb_dat_i;
          50: wr_buffer[239:208] <= wb_dat_i;
          51: wr_buffer[207:176] <= wb_dat_i;
          52: wr_buffer[175:144] <= wb_dat_i;

          56: wr_buffer[143:128] <= wb_dat_i[15:0];
          57: wr_buffer[127:96]  <= wb_dat_i;
          58: wr_buffer[95:64]   <= wb_dat_i;
          59: wr_buffer[63:32]   <= wb_dat_i;
          60: wr_buffer[31:0]    <= wb_dat_i;

        endcase
      end
    end
  end

  reg [31:0] wb_dat_o_reg;
  assign wb_dat_o = wb_dat_o_reg;

  always @(*) begin
    case (wb_adr_i[8:2])
      0:   wb_dat_o_reg <= {7'b0, app_wdf_rdy, 7'b0, app_rdy, 7'b0, cal_fail, 7'b0, phy_rdy};
      1:   wb_dat_o_reg <= {16'b0, 7'b0, wr_trans, 7'b0, rd_trans};
      2:   wb_dat_o_reg <= addr_buffer;

      32:  wb_dat_o_reg <= wr_buffer[575:560] ;
      33:  wb_dat_o_reg <= wr_buffer[559:528] ;
      34:  wb_dat_o_reg <= wr_buffer[527:496] ;
      35:  wb_dat_o_reg <= wr_buffer[495:464] ;
      36:  wb_dat_o_reg <= wr_buffer[463:432] ;
                           
      40:  wb_dat_o_reg <= wr_buffer[431:416] ;
      41:  wb_dat_o_reg <= wr_buffer[415:384] ;
      42:  wb_dat_o_reg <= wr_buffer[383:352] ;
      43:  wb_dat_o_reg <= wr_buffer[351:320] ;
      44:  wb_dat_o_reg <= wr_buffer[319:288] ;
                           
      48:  wb_dat_o_reg <= wr_buffer[287:272] ;
      49:  wb_dat_o_reg <= wr_buffer[271:240] ;
      50:  wb_dat_o_reg <= wr_buffer[239:208] ;
      51:  wb_dat_o_reg <= wr_buffer[207:176] ;
      52:  wb_dat_o_reg <= wr_buffer[175:144] ;
                           
      56:  wb_dat_o_reg <= wr_buffer[143:128] ;
      57:  wb_dat_o_reg <= wr_buffer[127:96]  ;
      58:  wb_dat_o_reg <= wr_buffer[ 95:64]  ;
      59:  wb_dat_o_reg <= wr_buffer[ 63:32]  ;
      60:  wb_dat_o_reg <= wr_buffer[ 31:0 ]  ;

      80:  wb_dat_o_reg <= rd_buffer[575:560] ;
      81:  wb_dat_o_reg <= rd_buffer[559:528] ;
      82:  wb_dat_o_reg <= rd_buffer[527:496] ;
      83:  wb_dat_o_reg <= rd_buffer[495:464] ;
      84:  wb_dat_o_reg <= rd_buffer[463:432] ;

      88:  wb_dat_o_reg <= rd_buffer[431:416] ;
      89:  wb_dat_o_reg <= rd_buffer[415:384] ;
      90:  wb_dat_o_reg <= rd_buffer[383:352] ;
      91:  wb_dat_o_reg <= rd_buffer[351:320] ;
      92:  wb_dat_o_reg <= rd_buffer[319:288] ;

      64:  wb_dat_o_reg <= rd_buffer[287:272] ;
      65:  wb_dat_o_reg <= rd_buffer[271:240] ;
      66:  wb_dat_o_reg <= rd_buffer[239:208] ;
      67:  wb_dat_o_reg <= rd_buffer[207:176] ;
      68:  wb_dat_o_reg <= rd_buffer[175:144] ;

      72:  wb_dat_o_reg <= rd_buffer[143:128] ;
      73:  wb_dat_o_reg <= rd_buffer[127:96]  ;
      74:  wb_dat_o_reg <= rd_buffer[ 95:64]  ;
      75:  wb_dat_o_reg <= rd_buffer[ 63:32]  ;
      76:  wb_dat_o_reg <= rd_buffer[ 31:0 ]  ;
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

  always @(posedge ddr3_clk) begin
    wr_transR  <= wr_trans;
    wr_transRR <= wr_transR;
  end

  wire rd_trans_stable;
  reg rd_transR;
  reg rd_transRR;
  assign rd_trans_stable = rd_transRR;

  always @(posedge ddr3_clk) begin
    rd_transR  <= rd_trans;
    rd_transRR <= rd_transR;
  end

  always @(posedge ddr3_clk) begin
    if (wr_trans_stable)
      wr_ack_unstable <= 1'b1;

    if (wr_ack_unstable && !wr_trans_stable) 
      wr_ack_unstable <= 1'b0;
  end

  reg             app_en_reg;
  reg       [2:0] app_cmd_reg;
  reg      [31:0] app_addr_reg;
  reg [144*2-1:0] app_wdf_data_reg;
  reg             app_wdf_end_reg;
  reg  [18*2-1:0] app_wdf_mask_reg;
  reg             app_wdf_wren_reg;

  assign app_en       = app_en_reg         ;
  assign app_cmd      = app_cmd_reg        ;
  assign app_addr     = app_addr_reg       ;
  assign app_wdf_data = app_wdf_data_reg   ;
  assign app_wdf_end  = app_wdf_end_reg    ;
  assign app_wdf_mask = app_wdf_mask_reg   ;
  assign app_wdf_wren = app_wdf_wren_reg   ;

  reg [2:0] xfer_state;
  localparam IDLE    = 0;
  localparam WR_0    = 1;
  localparam WR_1    = 2;
  localparam RD_WAIT = 3;
  localparam RD_1    = 4;
  localparam RD_DONE = 5;

  always @(posedge ddr3_clk) begin
    if (ddr3_rst) begin
      xfer_state       <= IDLE;
      app_cmd_reg      <= 3'b000;
      app_en_reg       <= 1'b0;
      app_wdf_wren_reg <= 1'b0;
      rd_ack_unstable  <= 1'b0;
    end else begin
      case (xfer_state)
        IDLE    : begin
          if (wr_ack_unstable && !wr_trans_stable) begin
            app_cmd_reg      <= 3'b000;
            app_en_reg       <= 1'b1;
            app_wdf_wren_reg <= 1'b1;
            app_wdf_end_reg  <= 1'b0;

            xfer_state <= WR_0;
          end

          if (rd_trans_stable) begin
            app_cmd_reg      <= 3'b001;
            app_en_reg       <= 1'b1;

            xfer_state <= RD_WAIT;
          end
        end
        WR_0    : begin
          if (app_rdy) begin
            app_en_reg <= 1'b0;
            app_wdf_end_reg  <= 1'b1;
            xfer_state <= WR_1;
          end
        end
        WR_1    : begin
          app_wdf_wren_reg <= 1'b0;
          app_wdf_end_reg  <= 1'b0;

          xfer_state <= IDLE;
        end
        RD_WAIT : begin
          if (app_rdy) begin
            app_en_reg <= 1'b0;
          end
          if (app_rd_data_valid) begin
            rd_ack_unstable <= 1'b1;
            xfer_state <= RD_1;
          end
        end
        RD_1    : begin
          xfer_state <= RD_DONE;
        end
        RD_DONE : begin
          if (!rd_trans_stable) begin
            rd_ack_unstable <= 1'b0;
            xfer_state      <= IDLE;
          end
        end
      endcase
    end
  end

  always @(*) begin
    app_addr_reg <= addr_buffer;
    app_wdf_mask_reg <= {36{1'b1}};
  end

  always @(posedge ddr3_clk) begin
   if (app_rd_data_valid && xfer_state == RD_WAIT) begin
     rd_buffer[144*4-1:144*2] <= app_rd_data;
   end

   if (xfer_state == RD_1) begin
     rd_buffer[144*2-1:144*0] <= app_rd_data;
   end
  end

  always @(*) begin
    if (xfer_state == WR_1) begin
      app_wdf_data_reg <= wr_buffer[144*4-1:144*2];
    end else begin
      app_wdf_data_reg <= wr_buffer[144*2-1:144*0];
    end
  end

endmodule
