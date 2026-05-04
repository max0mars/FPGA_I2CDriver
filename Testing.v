module Testing (
	input clk,
	input reset_n
);

wire sda1, scl1, sda2, scl2, sda3, scl3;

control_unit cu (clk, reset_n, sda1, scl1, sda2, scl2, sda3, scl3);
testing_I2C_Device E1 (clk, reset_n, 8'd237, sda1, scl1);
testing_I2C_Device E2 (clk, reset_n, 8'd197, sda2, scl2);
testing_I2C_Device CHIP (clk, reset_n, 8'd85, sda3, scl3);

endmodule