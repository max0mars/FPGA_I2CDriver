module encoder_interface(
	input wire clk,
   input wire reset_n,
   input wire getData,
	output reg[11:0] encoderData,
	output reg data_flag,
	inout wire sda,
	inout wire scl
);

reg[3:0] state;
localparam READY = 4'd0, set_write = 4'd1, wait_busy1 = 4'd2, set_read1 = 4'd3, wait_busy2 = 4'd4, wait_notbusy1 = 4'd5, store_byte = 4'd6, startWrite = 4'd7, 
	set_read2 = 4'd8, wait_notbusy2 = 4'd9;

reg byte_count;

//need data from registers 0x0C and 0x0D
localparam address = 7'b1110111, register = 8'h0C;

//reg[6:0] addr;
reg rw, ena;
//reg[7:0] data_wr;
wire[7:0] data_rd;

wire busy;
wire ack_error;

//address and write byte is hardcoded based on encoder address and internal register address.
//Function consists of a 1 byte write to set the correct internal pointer and then a 2 byte read to get the 12 bit data
i2c_master i2c(.clk(clk), .reset_n(reset_n), .ena(ena), .addr(address), .rw(rw), .data_wr(register), .busy(busy), .data_rd(data_rd), .ack_error(ack_error), .sda(sda), .scl(scl));


always @ (posedge clk or negedge reset_n) begin
	if (reset_n == 0) begin//reset
		state <= READY;
		byte_count <= 0;
		data_flag <= 0;
		ena <= 0;
		rw <= 0;
		encoderData <= 0;
	end else begin
		case(state)
			READY: begin //reset internal regs, wait for cpu to say get data
				byte_count <= 0;
				ena <= 0;
				rw <= 0;
				if(getData == 1) state <= set_write;
				else state <= READY;
			end
			set_write: begin// if busy, tell i2c to stop, if not busy tell it to start WRITE
				data_flag <= 0;
				rw <= 0;
				if(busy == 1) begin
					state <= set_write;
					ena <= 0;
				end else begin
					state <= startWrite;
				end
			end
			startWrite: begin
				ena <= 1;
				state <= wait_busy1;
			end
			wait_busy1: begin //wait for i2c to start before changing values
				if(busy == 1) state <= set_read1;
				else state <= wait_busy1;
			end
			set_read1: begin//change from write to read
				rw <= 1;
				state <= wait_notbusy1;
			end
			wait_notbusy1: begin//wait for i2c to finish writing
				if(ack_error <= 1) state <= set_write;//error: restart
				if(busy == 0) state <= wait_busy2;
				else state <= wait_notbusy1;
			end
			wait_busy2: begin//wait for i2c to start reading
				if(busy == 1) state <= wait_notbusy2;
				else state <= wait_busy2;
			end
			wait_notbusy2: begin//wait for i2c to finish reading
				if(ack_error <= 1) state <= set_write;//error: restart
				if(busy == 0) state <= store_byte;
				else state <= wait_notbusy2;
			end
			store_byte: begin//depending on 1st or 2nd byte store in reg and do it again or send signal that data ready
				if(byte_count == 0) begin
					byte_count <= 1;
					encoderData[11:8] <= data_rd[3:0];//first reg only has 4 bits
					state <= wait_busy2;
				end else begin
					byte_count <= 0;
					encoderData[7:0] <= data_rd;//second reg has 8 bits
					state <= READY;
					data_flag <= 1;
				end
			end
		endcase
	end
end
endmodule