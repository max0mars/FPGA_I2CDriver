`timescale 1ns / 1ns

module driver(
	inout SDA,
	output reg SCL 
);

initial SCL = 0;

always #1250 SCL = ~SCL; // clock signal. 1250ns flip = 2500ns period = 400 KHz

reg[1:0] state = 0; //0 = idle, 1 = active, 2 = waiting/sending ACK
reg rw = 0; //0 = read, 1 = write

reg dataOut = 1;
assign SDA = dataOut == 1'b0 ? 1'b0 : 1'bz; //open-drain functionality
	

reg reset = 0;
reg [7:0] buff = 8'b0;

reg [2:0] bitcount = 0;

initial state = 0;
initial rw = 0;

always @ (SCL) begin
	if(SCL == 0) begin// NEGEDGE
		if(state == 2 && rw == 0) #100 dataOut = 0;
		if(state == 1 && rw == 0) #100 dataOut = 1;
		
	end else begin // POSEDGE
		case (state)
		0: begin
		#500
			dataOut = 0;
			state = 1;
		end
		1: begin
			buff = buff << 1;//read data
			if(SDA == 0)buff[0] = 0;
			else buff[0] = 1;
			bitcount = bitcount + 1;
			if(bitcount == 0) state = 2;
		end
		2: begin
		#500
			dataOut = 1;
			state = 3;
			end
		endcase
	end
end

endmodule