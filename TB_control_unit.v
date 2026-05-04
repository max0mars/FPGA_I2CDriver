`timescale 1ns/10ps
module TB_control_unit();

reg clock, reset_n;


//in-out wires for encoder 1
wire encoder1_sda, encoder1_scl;
wire encoder1_sda_VAL, encoder1_scl_VAL;

reg i2c_datadriver, i2c_clockdriver;

assign encoder1_sda = i2c_datadriver;
assign encoder1_scl = i2c_clockdriver;
assign encoder1_sda_VAL = encoder1_sda === 1'bz ? 1'b1 : encoder1_sda;
assign encoder1_scl_VAL = encoder1_scl === 1'bz ? 1'b1 : encoder1_scl;

//other i2c wires, not being tested yet
wire encoder2_sda, encoder2_scl;
wire chip_sda, chip_scl;


control_unit CU (clock, reset_n, encoder1_sda, encoder1_scl, encoder2_sda, encoder2_scl, chip_sda, chip_scl);


localparam rs = 4'd0, READY = 4'd1, receiving = 4'd2, ACK1 = 4'd3, ACK2 = 4'd4, ADDR_ACK = 4'd5, sending = 4'd6, WAITACK1 = 4'd7, WAITACK2 = 4'd8;

reg last, Byte_Count;
reg [2:0] bit_cnt;
reg[3:0] i2c_state;
reg[7:0] data, dataOut1, dataOut2;
reg command;

initial begin
	clock = 0; i2c_state = rs;
	i2c_datadriver = 1'bz;
	i2c_clockdriver = 1'bz;
	reset_n = 1'b1; bit_cnt = 3'd7; last = 1'b1;
	dataOut1 = 8'b10101010;
	dataOut2 = 8'b00110011;
	command = 0; Byte_Count = 0;
end

always #10 clock = ~clock;

always @ (clock) begin
	if(clock == 1) begin //rising
		if(i2c_state == rs) begin
			reset_n <= 0;
			i2c_state <= READY;
		end else reset_n <= 1;
		
		
		
		
	end else begin //falling
		//i2c START and STOP conditions
		if(encoder1_sda_VAL !== last) begin
			if(encoder1_scl_VAL == 1 && encoder1_sda_VAL === 1'b0 && last <= 1'b1) begin //START Condition
				i2c_state <= receiving;
				command <= 1;
				bit_cnt <= 3'd7;
			end
		end else begin
			if(encoder1_scl_VAL == 1 && encoder1_sda_VAL === 1'b1 && last <= 1'b0) begin //STOP Condition
				i2c_state <= READY;
			end
		end
		last <= encoder1_sda_VAL;
		
	end
end


//simulated I2C slave device
always @(encoder1_scl_VAL) begin
	if(encoder1_scl_VAL == 1) begin //rising (read)
		case (i2c_state)
			receiving: begin
				if(bit_cnt == 0) begin
					bit_cnt <= 3'd7;
					data[bit_cnt] <= encoder1_sda_VAL;
					i2c_state <= ACK1;
				end else begin
					bit_cnt <= bit_cnt - 1'b1;
					data[bit_cnt] <= encoder1_sda_VAL;
					i2c_state <= receiving;
				end
			end
		endcase
	end else begin //falling (write)
		case(i2c_state)
			ACK1: begin
				i2c_datadriver <= 1'b0;
				i2c_state <= ACK2;
			end
			ACK2: begin
				i2c_datadriver <= 1'bz;
				command <= 0;
				if(data[0] == 1 && command == 1) begin
					if(Byte_Count == 0) i2c_datadriver <= dataOut1[bit_cnt];
					else i2c_datadriver <= dataOut2[bit_cnt];
					i2c_state <= sending;
				end
				else i2c_state <= receiving;
			end
			WAITACK1: begin
				if(Byte_Count == 0) i2c_datadriver <= dataOut1[bit_cnt];
				else i2c_datadriver <= dataOut2[bit_cnt];
				i2c_state <= sending;
			end
			sending: begin
				if(bit_cnt == 0) begin
					bit_cnt <= 3'd7;
					i2c_datadriver <= 1'bz;
					i2c_state <= WAITACK1;
				end else begin
					bit_cnt <= bit_cnt - 1'b1;
					if(Byte_Count == 0) i2c_datadriver <= dataOut1[bit_cnt - 1];
					else i2c_datadriver <= dataOut2[bit_cnt - 1];
					i2c_state <= sending;
				end
			end
		endcase
	end
end


endmodule 