module encoder_interface(
	input wire clk,
   input wire reset_n,
   input wire getData,
	output reg[11:0] encoderData,
	output reg data_flag,
	inout wire sda,
	inout wire scl
);

reg[2:0] state;
localparam READY = 3'd0, set_write = 3'd1, wait_busy = 3'd2, set_read = 3'd3, wait_busy2 = 3'd4, wait_notbusy = 3'd5, store_byte = 3'd6;

reg byte_count;

//need data from registers 0x0C and 0x0D
localparam address = 7'bxxxxxxx, register = 8'h0C;

reg[6:0] addr;
reg rw, ena;
reg[7:0] data_wr;
wire[7:0] data_rd;

wire busy;
wire ack_error;

i2c_master(.clk(clk), .reset_n(reset_n), .ena(ena), .addr(address), .rw(rw), .data_wr(register), .busy(busy), .data_rd(data_rd), .ack_error(ack_error), .sda(sda), .scl(scl));

always @ (posedge clk or negedge reset_n) begin
	if (reset_n == 0) begin//reset
		state <= READY;
		byte_count <= 0;
		data_flag <= 0;
		ena <= 0;
	end
	case(state)
		READY: begin //reset all flags and regs, wait for cpu to say get data
			byte_count <= 0;
			ena <= 0;
			if(getData == 1) state <= set_write;
			else state <= READY;
		end
		set_write: begin// if busy, tell i2c to stop, if not busy tell it to start WRITE
			data_flag <= 0;
			if(busy == 1) begin
				state <= set_write;
				ena <= 0;
			end else begin
				ena <= 1;
				rw <= 0;
				state <= wait_busy;
			end
		end
		wait_busy: begin //wait for i2c to start before changing values
			if(busy == 1) state <= set_read;
			else state <= wait_busy;
		end
		set_read: begin//change from write to read
			rw <= 0;
		end
		wait_busy2: begin//wait for i2c to start
			if(busy == 1) state <= wait_notbusy;
			else state <= wait_busy2;
		end
		wait_notbusy: begin//wait for i2c to finish collecting byte
			if(ack_error <= 1) state <= set_write;
			if(busy == 0) state <= store_byte;
			else state <= wait_notbusy;
		end
		store_byte: begin//depending on 1st or 2nd byte store in reg and do it again or send signal that data ready
			if(ack_error <= 1) state <= set_write;//if there's an error, try again
			if(byte_count == 0) begin
				byte_count <= 1;
				encoderData[11:8] <= data_rd[3:0];//first reg only has 4 bits
				state <= set_read;
			end else begin
				byte_count <= 0;
				encoderData[7:0] <= data_rd;//second reg has 8 bits
				state <= READY;
				data_flag <= 1;
			end
		end
	endcase
end
endmodule