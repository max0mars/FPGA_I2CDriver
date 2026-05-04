`timescale 1ns/10ps
module TB_Everything();

reg clk, reset_n;
initial clk = 0;

Testing test (clk, reset_n);

always #10 clk = ~clk;

initial begin
  reset_n = 0;
  #1000 reset_n = 1;
  #500_000 reset_n = 0;
  #1000 reset_n = 1;
end



endmodule