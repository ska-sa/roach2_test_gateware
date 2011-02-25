module qdrc_cpu_attach (
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

    /* controls the qdr dll */
    output        doffn,
    /* Enable the software calibration */
    output        cal_en,
    /* Calibration setup is complete */
    input         cal_rdy,
    /* Select the bit that we are calibrating */
    output [7:0]  bit_select,
    /* strobe to tick IODELAY delay tap */
    output        dll_en,
    /* Direction of IO delay */
    output        dll_inc_dec_n,
    /* IODELAY value reset */
    output        dll_rst,
    /* Set to enable additional delay to compensate for half cycle delay */
    output        align_en,
    output        align_strb,
    /* Sampled value */
    input  [1:0]  data_in,
    /* has the value been sampled 32 times */
    input         data_sampled,
    /* has the value stayed valid after being sampled 32 times */
    input         data_valid
  );

  /************************** Registers *******************************/

  localparam REG_CTRL      = 0;
  localparam REG_BITINDEX  = 1;
  localparam REG_BITCTRL   = 2;
  localparam REG_BITSTATUS = 3;

  /**************** Control Registers CPU Attachment ******************/
  

  /* OPB Registers */
  reg wb_ack_reg;
  assign wb_ack_o = wb_ack_reg;

  reg       cal_en_reg;
  reg       doffn_reg;
  reg [7:0] bit_select_reg;
  reg       dll_inc_dec_n_reg;
  reg       dll_en_reg;
  reg       dll_rst_reg;
  reg       align_en_reg;
  reg       align_strb_reg;

  always @(posedge wb_clk_i) begin
    wb_ack_reg     <= 1'b0;
    if (wb_stb_i & wb_cyc_i & !wb_ack_reg) begin
      wb_ack_reg   <= 1'b1;
    end
  end

  always @(posedge wb_clk_i) begin
    /* Single cycle strobes */
    dll_en_reg     <= 1'b0;
    align_strb_reg <= 1'b0;

    if (wb_rst_i) begin
      cal_en_reg        <= 1'b0;
      doffn_reg         <= 1'b0;
      bit_select_reg    <= 8'b0;
      dll_inc_dec_n_reg <= 1'b0;
      dll_rst_reg       <= 1'b0;
      align_en_reg      <= 1'b0;
    end else begin
      if (wb_stb_i & wb_cyc_i & !wb_ack_reg && wb_we_i) begin
        case (wb_adr_i[3:2])  /* convert byte to word addressing */
          REG_CTRL: begin
            if (wb_sel_i[2])
              doffn_reg <= wb_dat_i[8];
            if (wb_sel_i[3])
              cal_en_reg <= wb_dat_i[0];
          end
          REG_BITINDEX: begin
            if (wb_sel_i[3])
              bit_select_reg <= wb_dat_i[7:0];
          end
          REG_BITCTRL: begin
            if (wb_sel_i[2]) begin
              align_en_reg <= wb_dat_i[8];
              align_strb_reg <= 1'b1;
            end
            if (wb_sel_i[3]) begin
              dll_rst_reg <= wb_dat_i[2];
              dll_inc_dec_n_reg <= wb_dat_i[1];
              dll_en_reg <= wb_dat_i[0];
            end 
          end
        endcase
      end
    end
  end

  assign cal_en         = cal_en_reg;
  assign doffn          = doffn_reg;
  assign bit_select     = bit_select_reg;
  assign dll_inc_dec_n  = dll_inc_dec_n_reg;
  assign dll_en         = dll_en_reg;
  assign dll_rst        = dll_rst_reg;
  assign align_en       = align_en_reg;
  assign align_strb     = align_strb_reg;

  /* Continuous Read Logic */
  reg [0:31] wb_dat_o_reg;
  assign wb_dat_o = wb_dat_o_reg;

  always @(*) begin
    case (wb_adr_i[3:2]) 
      REG_CTRL: begin
        wb_dat_o_reg <= {16'b0, 7'b0, doffn, 7'b0, cal_en};
      end
      REG_BITINDEX: begin
        wb_dat_o_reg <= {24'b0, bit_select};
      end
      REG_BITCTRL: begin
        wb_dat_o_reg <= 32'b0;
      end
      REG_BITSTATUS: begin
        wb_dat_o_reg <= {7'b0, cal_rdy, 7'b0, data_sampled, 7'b0, data_valid, 6'b0, data_in};
      end
      default: begin
        wb_dat_o_reg <= 32'b0;
      end
    endcase
  end

  /* OPB output assignments */

  assign wb_err_o    = 1'b0;

endmodule
