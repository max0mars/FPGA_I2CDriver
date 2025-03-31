module cpu();

	input wire clk,
   input wire reset_n,
   input wire ena,
   input wire [6:0] addr,
   input wire rw,
   input wire [7:0] data_wr,
   output reg busy,
   output reg [7:0] data_rd,
   output reg ack_error,
   inout wire sda,
   inout wire scl

reg clk;

//always (48 MHz) clk <= ~clk;

//getting data from one encoder:
//first set addr input, set rw, if write set data_wr

//first byte of write is used to set encoder internal address pointer



//set enable high,
//wait for busy signal from i2c



//once busy signal is set, can safely change input values



//if you only want to perform 1 byte action, set enable low

//if want to read or write >1 bytes:
	//enable remain high, addr stays the same, rw stays the same

	

	
//for Encoders: write will only ever be used for internal pointer assignment



//Initially for simplicity do the same thing for all the encoders



always @ (negedge clk) begin
	

end


endmodule 