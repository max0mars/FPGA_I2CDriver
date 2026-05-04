module odom_interface(
	input wire clk,
   input wire reset_n,
   input wire sendData,
	input wire select,//0 for first encoder, 1 for second encoder
	input wire [31:0] timestamp,
	input wire[11:0] data,
	output reg sending,
	inout wire sda,
	inout wire scl
);

localparam READY = 4'd0, set_write = 4'd1, waitbusy = 4'd2, startWrite = 4'd3, waitnotbusy = 4'd4, ERROR = 4'd5;
localparam rw = 1'b0;
reg [3:0] state;
reg ena;
reg[2:0] byte_count;
reg[6:0] address;
reg[7:0] byte_data;



wire[7:0] data_rd;
wire busy;
wire ack_error;

i2c_master i2c(.clk(clk), .reset_n(reset_n), .ena(ena), .addr(address), .rw(rw), .data_wr(byte_data), .busy(busy), .data_rd(data_rd), .ack_error(ack_error), .sda(sda), .scl(scl));


//busy lets us know after a byte is sent
//need to send 6 bytes total
always @ (posedge clk or negedge reset_n) begin
	if(reset_n == 0) begin
		state <= READY;
		byte_count <= 0;
		ena <= 0;
		sending <= 0;
	end else begin
		case(state)
			READY: begin //reset internal regs, wait for cpu to say get data
				byte_count <= 0;
				ena <= 0;
				sending <= 0;
				if(sendData == 1) state <= set_write;
				else state <= READY;
			end
			set_write: begin// if busy, tell i2c to stop, if not busy tell it to start WRITE
				if(select == 0) address = 7'b0001000;
				else address = 7'b0011000;
				sending <= 1;
				case(byte_count)
					0: byte_data <= timestamp[31:24];
					1: byte_data <= timestamp[23:16];
					2: byte_data <= timestamp[15:8];
					3: byte_data <= timestamp[7:0];
					4: byte_data <= {4'b0, data[11:8]};
					5: byte_data <= data[7:0];
				endcase
				state <= waitnotbusy;
			end
			waitnotbusy: begin
				if(busy == 1) state <= waitnotbusy;
				else begin
					if(ack_error == 1) begin
						state <= ERROR;
					end
					byte_count <= byte_count + 1'b1;
					if(byte_count == 5) state <= READY;
					else state <= startWrite;
				end
			end
			startWrite: begin
				ena <= 1;
				state <= waitbusy;
			end
			waitbusy: begin
				if(busy == 0) state <= waitbusy;
				else state <= set_write;
			end
			ERROR: begin
				ena <= 0;
				byte_count <= 0;
				if(busy == 1) state <= ERROR;
				else state <= set_write;
			end
		endcase
	end
end

endmodule