module sys_block(
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

    input         debug_clk,
    input  [31:0] regin_0,
    input  [31:0] regin_1,
    input  [31:0] regin_2,
    input  [31:0] regin_3,
    input  [31:0] regin_4,
    input  [31:0] regin_5,
    input  [31:0] regin_6,
    input  [31:0] regin_7,

    output [31:0] regout_0,
    output [31:0] regout_1,
    output [31:0] regout_2,
    output [31:0] regout_3,
    output [31:0] regout_4,
    output [31:0] regout_5,
    output [31:0] regout_6,
    output [31:0] regout_7,

    input  [31:0] fifo_wr_in,
    input         fifo_wr_en
  );

  /* latch data in */
  reg [31:0] regin_0_R;
  reg [31:0] regin_1_R;
  reg [31:0] regin_2_R;
  reg [31:0] regin_3_R;
  reg [31:0] regin_4_R;
  reg [31:0] regin_5_R;
  reg [31:0] regin_6_R;
  reg [31:0] regin_7_R;
  reg [31:0] regin_0_RR;
  reg [31:0] regin_1_RR;
  reg [31:0] regin_2_RR;
  reg [31:0] regin_3_RR;
  reg [31:0] regin_4_RR;
  reg [31:0] regin_5_RR;
  reg [31:0] regin_6_RR;
  reg [31:0] regin_7_RR;

  always @(posedge wb_clk_i) begin
    regin_0_R <= regin_0;
    regin_1_R <= regin_1;
    regin_2_R <= regin_2;
    regin_3_R <= regin_3;
    regin_4_R <= regin_4;
    regin_5_R <= regin_5;
    regin_6_R <= regin_6;
    regin_7_R <= regin_7;
    regin_0_RR<= regin_0_R;
    regin_1_RR<= regin_1_R;
    regin_2_RR<= regin_2_R;
    regin_3_RR<= regin_3_R;
    regin_4_RR<= regin_4_R;
    regin_5_RR<= regin_5_R;
    regin_6_RR<= regin_6_R;
    regin_7_RR<= regin_7_R;
  end

  /* latch data out */
  reg [31:0] regout_0_reg;
  reg [31:0] regout_1_reg;
  reg [31:0] regout_2_reg;
  reg [31:0] regout_3_reg;
  reg [31:0] regout_4_reg;
  reg [31:0] regout_5_reg;
  reg [31:0] regout_6_reg;
  reg [31:0] regout_7_reg;

  reg [31:0] regout_0_R;
  reg [31:0] regout_1_R;
  reg [31:0] regout_2_R;
  reg [31:0] regout_3_R;
  reg [31:0] regout_4_R;
  reg [31:0] regout_5_R;
  reg [31:0] regout_6_R;
  reg [31:0] regout_7_R;
  reg [31:0] regout_0_RR;
  reg [31:0] regout_1_RR;
  reg [31:0] regout_2_RR;
  reg [31:0] regout_3_RR;
  reg [31:0] regout_4_RR;
  reg [31:0] regout_5_RR;
  reg [31:0] regout_6_RR;
  reg [31:0] regout_7_RR;

  always @(posedge debug_clk) begin
    regout_0_R <= regout_0_reg;
    regout_1_R <= regout_1_reg;
    regout_2_R <= regout_2_reg;
    regout_3_R <= regout_3_reg;
    regout_4_R <= regout_4_reg;
    regout_5_R <= regout_5_reg;
    regout_6_R <= regout_6_reg;
    regout_7_R <= regout_7_reg;

    regout_0_RR<= regout_0_R;
    regout_1_RR<= regout_1_R;
    regout_2_RR<= regout_2_R;
    regout_3_RR<= regout_3_R;
    regout_4_RR<= regout_4_R;
    regout_5_RR<= regout_5_R;
    regout_6_RR<= regout_6_R;
    regout_7_RR<= regout_7_R;
  end

  assign regout_0 = regout_0_RR;
  assign regout_1 = regout_1_RR;
  assign regout_2 = regout_2_RR;
  assign regout_3 = regout_3_RR;
  assign regout_4 = regout_4_RR;
  assign regout_5 = regout_5_RR;
  assign regout_6 = regout_6_RR;
  assign regout_7 = regout_7_RR;

  reg wb_ack_reg;
  assign wb_ack_o = wb_ack_reg;
  always @(posedge wb_clk_i) begin
    wb_ack_reg <= 1'b0;
    if (wb_rst_i) begin
    end else begin
      if (wb_stb_i && wb_cyc_i) begin
        wb_ack_reg <= 1'b1;
      end
    end
  end

  /* wb write */
  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      regout_0_reg <= 32'd0;
      regout_1_reg <= 32'd0;
      regout_2_reg <= 32'd0;
      regout_3_reg <= 32'd0;
      regout_4_reg <= 32'd0;
      regout_5_reg <= 32'd0;
      regout_6_reg <= 32'd0;
      regout_7_reg <= 32'd0;
    end else begin
      if (wb_stb_i && wb_cyc_i && wb_we_i) begin
        case (wb_adr_i[5:2])
          4'd8:  regout_0_reg <= wb_dat_i;
          4'd9:  regout_1_reg <= wb_dat_i;
          4'd10: regout_2_reg <= wb_dat_i;
          4'd11: regout_3_reg <= wb_dat_i;
          4'd12: regout_4_reg <= wb_dat_i;
          4'd13: regout_5_reg <= wb_dat_i;
          4'd14: regout_6_reg <= wb_dat_i;
          4'd15: regout_7_reg <= wb_dat_i;
        endcase
      end
    end
  end

  /* wb read */

  reg [31:0] wb_dat_o_reg;
  assign wb_dat_o = wb_dat_o_reg;

  always @(*) begin
    case (wb_adr_i[5:2])
      4'd0:   wb_dat_o_reg <= regin_0_RR;
      4'd1:   wb_dat_o_reg <= regin_1_RR;
      4'd2:   wb_dat_o_reg <= regin_2_RR;
      4'd3:   wb_dat_o_reg <= regin_3_RR;
      4'd4:   wb_dat_o_reg <= regin_4_RR;
      4'd5:   wb_dat_o_reg <= regin_5_RR;
      4'd6:   wb_dat_o_reg <= regin_6_RR;
      4'd7:   wb_dat_o_reg <= regin_7_RR;
      4'd8:   wb_dat_o_reg <= regout_0_reg;
      4'd9:   wb_dat_o_reg <= regout_1_reg;
      4'd10:  wb_dat_o_reg <= regout_2_reg;
      4'd11:  wb_dat_o_reg <= regout_3_reg;
      4'd12:  wb_dat_o_reg <= regout_4_reg;
      4'd13:  wb_dat_o_reg <= regout_5_reg;
      4'd14:  wb_dat_o_reg <= regout_6_reg;
      4'd15:  wb_dat_o_reg <= regout_7_reg;
    endcase
  end

endmodule
