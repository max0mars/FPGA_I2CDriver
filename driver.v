`timescale 1ns / 1ns

module driver(
	inout SDA,
	input SCL,// clock signal. 1250ns flip = 2500ns period = 400 KHz
	
	input reset, enable, rw,
	
	
	input [7:0] address, dataIn,
	input dataInFlag, addressFlag, regAddressFlag,
	
	output reg [7:0] dataOut,
	output reg dataOutValidFlag
);



reg[3:0] state; //0 = idle, 1 = Send Address, 2 = Send register address, reading, writing, waiting ACK address, waiting ACK register, Waiting ACK write, sending ACK, Sending NACK
reg [7:0] status; // 0: on/~off, 1: read/~write 2: START/~STOP, 3: waitACK, 4: ACK value, 5: send Reg_address, 

reg dataDrive = 1; //drives or disconnects from SDA
assign SDA = dataDrive == 1'b0 ? 1'b0 : 1'bz; //open-drain functionality

reg [7:0] buff = 8'b0;//stores current incoming or outgoing byte
reg [2:0] bitcount = 0;//tracks how many bits of the byte have been sent

initial state = 4'b0;


parameter idle = 4'd0, START = 4'd1, sendAddress = 4'd2, addressAck = 4'd3, read = 4'd4, write = 4'd5, sendAck = 4'd6, waitAck = 4'd7, STOP = 4'd8;
always @(enable) status[0] <= enable;

always @ (SCL) begin
	if(enable == 1) begin
		if(SCL == 0) begin //NEGEDGE
			if(reset == 1) begin 
				state <= idle;
				bitcount <= 3'b0;
				buff <= 0;
			end
			case(state)
				idle: if(status[0] == 1) state <= START;
				
				START: begin
					state <= sendAddress;
				end
				
				sendAddress: begin
					if(bitcount ==0) state <= addressAck;
				end
				
				addressAck: begin
					if(status[1] == 0) state <= write;
				end
				
				write: begin
					if(bitcount == 0) state <= waitAck;
				end
				
				waitAck: begin
					if(status[4] == 0) state <= write;
					else state <= STOP;
				end
				
				STOP: begin
					state <= idle;
				end
				
				default: state <= idle;
			endcase
		end
	end
end
endmodule



//if(SCL == 0) begin// NEGEDGE
//		if(state == 2 && rw == 0) #100 dataOut = 0;
//		if(state == 1 && rw == 0) #100 dataOut = 1;
//		
//	end else begin // POSEDGE
//		case (state)
//		0: begin
//		#500
//			dataOut = 0;
//			state = 1;
//		end
//		1: begin
//			buff = buff << 1;//read data
//			if(SDA == 0)buff[0] = 0;
//			else buff[0] = 1;
//			bitcount = bitcount + 1;
//			if(bitcount == 0) state = 2;
//		end
//		2: begin
//		#500
//			dataOut = 1;
//			state = 3;
//			end
//		endcase
//	end