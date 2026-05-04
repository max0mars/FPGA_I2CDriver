`timescale 1ns/10ps
module TB_encoder_interface();


reg clock, reset, getData;
wire[11:0] encoderData;
wire data_flag;

//handles the InOut pins
wire data_line, clock_line;
wire dataVal, clockVal;
reg data_driver, clock_driver;
assign data_line = data_driver;
assign clock_line = clock_driver;
assign dataVal = data_line === 1'bz ? 1'b1 : data_line;
assign clockVal = clock_line === 1'bz ? 1'b1 : clock_line;

encoder_interface ei (clock, reset, getData, encoderData, data_flag, data_line, clock_line);

reg last, rw, Byte_Count;
reg [2:0] bit_cnt;
reg[11:0] EncoderRawAngle;
reg[3:0] i2c_state, interface_state;
reg[7:0] data, dataOut, dataOut1, dataOut2;
parameter rs = 4'd0, READY = 4'd1, receiving = 4'd2, ACK1 = 4'd3, ACK2 = 4'd4, ADDR_ACK = 4'd5, sending = 4'd6, WAITACK1 = 4'd7, WAITACK2 = 4'd8;//can add more states here
parameter GETDATA = 4'd1, WAITDATA = 4'd2, STOREDATA = 4'd3, WAITNOTDATA = 4'd4, e = 4'd5, f = 4'd6, g = 4'd7, h = 4'd8, i = 4'd9, j = 4'd10, k = 4'd11;//can add more states here

reg command;

initial begin
	clock = 0; i2c_state = rs; interface_state = rs;
	data_driver = 1'bz;
	clock_driver = 1'bz;
	getData = 0;
	rw = 1'b0;
	reset = 1'b1; bit_cnt = 3'd7; last = 1'b1;
	dataOut1 = 8'b00001111;
	dataOut2 = 8'b00110011;
	command = 0; Byte_Count = 0;
end


always #10 clock = ~clock;

//always @ (data_flag or negedge reset) begin
//	case(interface_state)
//		rs: interface_state <= GETDATA;
//		GETDATA: begin
//			getData <= 1;
//			interface_state <= WAITDATA;
//		end
//		WAITDATA: begin
//			getData <= 0;
//			interface_state <= GETDATA;
//		end
//	endcase
//end

always @ (clock) begin
	if(clock == 1) begin //rising
		if(i2c_state == rs) begin
			reset <= 0;
			i2c_state <= READY;
		end else reset <= 1;
		
		
		
		
	end else begin //falling
		if(dataVal !== last) begin
			if(clockVal == 1 && dataVal === 1'b0 && last <= 1'b1) begin //START Condition
				i2c_state <= receiving;
				command <= 1;
				bit_cnt <= 3'd7;
			end
		end else begin
			if(clockVal == 1 && dataVal === 1'b1 && last <= 1'b0) begin //STOP Condition
				i2c_state <= READY;
			end
		end
		last <= dataVal;
		
		//put it on oposite edge of interface so no problems with unstable states
		case(interface_state)
			rs: interface_state <= GETDATA;
			GETDATA: begin
				getData <= 1;
				interface_state <= WAITNOTDATA;
			end
			WAITNOTDATA: begin
				if(data_flag == 0) interface_state <= WAITDATA;
				else interface_state <= WAITNOTDATA;
			end
			WAITDATA: begin
				if(data_flag == 1) interface_state <= STOREDATA;
				else interface_state <= WAITDATA;
				getData <= 0;
			end
			STOREDATA: begin
				EncoderRawAngle <= encoderData;
				interface_state <= GETDATA;
				dataOut2 <= dataOut2 +1;
				dataOut1 <= dataOut1 +1;
			end
		endcase
	end
end




//simulates an i2c device
always @(clockVal) begin
	if(clockVal == 1) begin //rising (read)
		case (i2c_state)
			receiving: begin
				if(bit_cnt == 0) begin
					bit_cnt <= 3'd7;
					data[bit_cnt] <= dataVal;
					i2c_state <= ACK1;
				end else begin
					bit_cnt <= bit_cnt - 1'b1;
					data[bit_cnt] <= dataVal;
					i2c_state <= receiving;
				end
			end
//			ACK2: i2c_state <= sending;
			
		endcase
	end else begin //falling (write)
		case(i2c_state)
			ACK1: begin
				data_driver <= 1'b0;
				i2c_state <= ACK2;
			end
			ACK2: begin
				data_driver <= 1'bz;
				command <= 0;
				if(data[0] == 1 && command == 1) begin
					//data_driver <= dataOut1[bit_cnt];
					if(Byte_Count == 0) data_driver <= dataOut1[bit_cnt];
					else data_driver <= dataOut2[bit_cnt];
					i2c_state <= sending;
				end
				else i2c_state <= receiving;
			end
			WAITACK1: begin
				//data_driver <= dataOut2[bit_cnt];
				if(Byte_Count == 0) data_driver <= dataOut1[bit_cnt];
				else data_driver <= dataOut2[bit_cnt];
				i2c_state <= sending;
			end
			sending: begin
				if(bit_cnt == 0) begin
					bit_cnt <= 3'd7;
					data_driver <= 1'bz;
					i2c_state <= WAITACK1;
				end else begin
					bit_cnt <= bit_cnt - 1'b1;
					//data_driver <= dataOut1[bit_cnt - 1];
					if(Byte_Count == 0) data_driver <= dataOut1[bit_cnt - 1];
					else data_driver <= dataOut2[bit_cnt - 1];
					i2c_state <= sending;
				end
			end
		endcase
	end
end
endmodule