module testing_I2C_Device(
	input wire clk,
	input wire reset,
	input wire [7:0] dataOut, //set what data you want to see it write
	inout sda,
	input wire scl
);

wire sda_VAL, scl_VAL;
assign sda_VAL = sda === 1'bz ? 1'b1 : sda;
assign scl_VAL = scl === 1'bz ? 1'b1 : scl;

reg dataDriver;
assign sda = dataDriver;

localparam READY = 4'd1, receiving = 4'd2, ACK1 = 4'd3, ACK2 = 4'd4, ADDR_ACK = 4'd5, sending = 4'd6, WAITACK1 = 4'd7, WAITACK2 = 4'd8, ACKERROR = 4'd9;


reg [2:0] bit_cnt;
reg[3:0] i2c_state;
reg[7:0] data;
reg command;

reg[47:0] buffer; //test if MCU received correct data

reg scl_last;
reg sda_last;


always @ (posedge clk or negedge reset) begin
	if(reset == 0) begin
		sda_last <= 0;
		scl_last <= 0;
		bit_cnt <= 0;
		dataDriver <= 1'bz;
		data <= 0;
		command <= 0;
		i2c_state <= READY;
	end else begin
		sda_last <= sda_VAL;
		scl_last <= scl_VAL;
		
		
		if(sda_VAL != sda_last) begin
			if(scl_VAL == 1'b1) begin//START OR STOP
				if(sda_VAL == 1'b0) begin //START Condition
					i2c_state <= receiving;
					command <= 1;
					bit_cnt <= 3'd7;
				end else begin //STOP Condition
					i2c_state <= READY;
					dataDriver <= 1'bz;
				end
			end
		end
		
		if(scl_VAL != scl_last) begin
			if(scl_VAL == 1) begin //rising (read)
				case (i2c_state)
					receiving: begin
						if(bit_cnt == 0) begin
							bit_cnt <= 3'd7;
							data[bit_cnt] <= sda_VAL;
							i2c_state <= ACK1;
						end else begin
							bit_cnt <= bit_cnt - 1'b1;
							data[bit_cnt] <= sda_VAL;
							i2c_state <= receiving;
						end
					end
				endcase
			end else begin //falling (write)
				case(i2c_state)
					READY: i2c_state <= READY;
					ACK1: begin
						dataDriver <= 1'b0;
						i2c_state <= ACK2;
						buffer <= buffer << 8;
						buffer[7:0] <= data;
					end
					ACK2: begin
						dataDriver <= 1'bz;
						command <= 0;
						if(data[0] == 1 && command == 1) begin
							dataDriver <= dataOut[bit_cnt];
							i2c_state <= sending;
						end
						else i2c_state <= receiving;
					end
					WAITACK1: begin
						if(sda_VAL != 0) i2c_state <= ACKERROR;
						else begin
							dataDriver <= dataOut[bit_cnt];
							i2c_state <= sending;
						end
					end
					sending: begin
						if(bit_cnt == 0) begin
							bit_cnt <= 3'd7;
							dataDriver <= 1'bz;
							i2c_state <= WAITACK1;
						end else begin
							bit_cnt <= bit_cnt - 1'b1;
							dataDriver <= dataOut[bit_cnt - 1];
							i2c_state <= sending;
						end
					end
				endcase
			end
		end
	end
end

endmodule