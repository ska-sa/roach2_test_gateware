module knight_rider(
    input        clk,
    input        rst,
    output [7:0] led,
    input  [2:0] rate
  );

  // Set this value to 8 to make it more simulateable
  //localparam SIM = 4;
  localparam SIM = 0;

  localparam NUM_LED = 8;

  wire [5*NUM_LED-1:0] pwm_val;

  reg [9-SIM:0] pwm_counter;
  reg [4:0] pwm_ticker;

  always @(posedge clk) begin
    if (rst) begin
      pwm_ticker <= 5'b0;
      pwm_counter <= 10'b0;
    end else begin
      pwm_counter <= pwm_counter + 10'b1;
      if (pwm_counter == 10'b0) begin
        pwm_ticker <= pwm_ticker + 5'b1;
      end
    end
  end

  genvar geni;
  generate for (geni=0; geni < NUM_LED; geni = geni+1) begin : pwm_assign_gen
      assign led[geni] = pwm_ticker < pwm_val[(geni+1)*5-1:geni*5];
  end endgenerate

  reg [23-2*SIM:0] global_tick_counter;
  reg [23-2*SIM:0] global_tick_counter_prev;

  always @(posedge clk) begin
    global_tick_counter_prev <= global_tick_counter;
    if (rst) begin
      global_tick_counter <= {24{1'b1}};
    end else begin
      case (rate)
        3'd0: global_tick_counter <= global_tick_counter + 24'd1;
        3'd1: global_tick_counter <= global_tick_counter + 24'd2;
        3'd2: global_tick_counter <= global_tick_counter + 24'd3;
        3'd3: global_tick_counter <= global_tick_counter + 24'd4;
        3'd4: global_tick_counter <= global_tick_counter + 24'd5;
        3'd5: global_tick_counter <= global_tick_counter + 24'd6;
        3'd6: global_tick_counter <= global_tick_counter + 24'd7;
        3'd7: global_tick_counter <= global_tick_counter + 24'd8;
      endcase
    end
  end

  wire global_pwm_tick = global_tick_counter[19-2*SIM:0] < global_tick_counter_prev[19-2*SIM:0];
  wire global_tick = global_tick_counter < global_tick_counter_prev;

  reg [2:0] led_index;
  reg dir;

  always @(posedge clk) begin
    if (rst) begin
      dir <= 1'b0;
      led_index <= 3'b0;
    end else begin
      if (global_tick) begin
        if (dir) begin
          led_index <= led_index + 3'b1;
          if (led_index == 3'd6)
            dir <= ~dir;
        end else begin
          led_index <= led_index - 3'b1;
          if (led_index == 3'd1)
            dir <= ~dir;
        end
      end
    end
  end

  wire [7:0] selected_led = 8'b1 << led_index;

  pwm_sm pwm_sm_inst[NUM_LED-1:0](
    .clk      (clk),
    .rst      (rst),
    .selected (selected_led),
    .tick     (global_pwm_tick),
    .pwm      (pwm_val)
  );

endmodule
