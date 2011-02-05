module pwm_sm(
    input        clk,
    input        rst,
    input        tick,
    input        selected,
    output [4:0] pwm
  );

  reg [1:0] state;
  localparam IDLE = 0;
  localparam UP = 1;
  localparam DOWN = 2;

  reg prev_selected;

  reg [4:0] pwm_val_reg;
  assign pwm = pwm_val_reg;

  always @(posedge clk) begin
    prev_selected <= selected;
    if (rst) begin
      pwm_val_reg <= 5'b0;
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          //IDLE is default state
          if (prev_selected == 1'b0 && selected == 1'b1)
            state <= UP;
        end
        UP: begin
          if (tick) begin
            pwm_val_reg <= pwm_val_reg + 5'b1;
            if (pwm_val_reg == 5'b11110)
              state <= DOWN;
          end
        end
        DOWN: begin
          if (tick) begin
            pwm_val_reg <= pwm_val_reg - 5'b1;
            if (pwm_val_reg == 5'b1)
              state <= IDLE;
          end
        end
        default: begin
          state <= IDLE;
        end
      endcase
    end
  end

endmodule
