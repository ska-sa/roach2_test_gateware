module TB_knight_rider;
  wire       clk;
  wire       rst;
  wire [7:0] led;

  knight_rider kr(
    .clk(clk),
    .rst(rst),
    .led(led)
  );

  reg sys_rst;
  reg sys_clk;

  initial begin
    $dumpvars;
    sys_rst <= 1'b1;
    sys_clk <= 1'b0;
    #200
    sys_rst <= 1'b0;
    #999999
    $finish;
  end

  always
    #1 sys_clk <= ~sys_clk;

  assign clk = sys_clk;
  assign rst = sys_rst;
  
endmodule
