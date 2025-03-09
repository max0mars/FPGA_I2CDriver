`timescale 1ns / 1ns
module driver_tb();

reg [2:0] state = 0;//0 = idle, 1 = sending data, 2 = waiting
wire clock;
wire data;
reg datacontrol = 1;
assign data = datacontrol == 1'b0 ? 1'b0 : 1'bz;

//assign data = state == 1 ? (sample[7] == 1'b0 ? 1'b0 : 1'bz) : 1'bz;
//always @ #10 clock = ~clock;

driver d (data, clock);

reg [7:0] sample = 8'd153;
reg [2:0] shift = 0;

always @ (data) begin
	if(clock == 1)begin
		if(data == 0) state = 1;//start command
		else state = 0;//stop command
	end
end
always @ (negedge clock) begin
	if(state == 1) begin
		#500
		shift = shift + 1;
		if(shift == 0) state = 2;
		datacontrol = sample[7];
		sample = sample << 1;
	end else if(state == 2) datacontrol = 1;
end
endmodule