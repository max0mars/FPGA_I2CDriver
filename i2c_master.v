//based on digikey design: https://forum.digikey.com/t/i2c-master-vhdl/12797

module i2c_master #(
   parameter input_clk = 50000000,
   parameter bus_clk = 400000
) (
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
);

   localparam divider = (input_clk / bus_clk) / 4;
	localparam div1 = divider, div2 = divider*2, div3 = divider*3, div4 = divider*4;
	
	
   reg [7:0] addr_rw, data_tx, data_rx;
   reg [3:0] state;
   reg data_clk, data_clk_prev, scl_clk, scl_ena;
   reg sda_int;
   wire sda_ena_n;
   reg [2:0] bit_cnt;
   reg stretch;
   reg [31:0] count;

	localparam READY = 4'd0, START = 4'd1, COMMAND = 4'd2, SLV_ACK1 = 4'd3, WR = 4'd4, RD = 4'd5, SLV_ACK2 = 4'd6, MSTR_ACK = 4'd7, STOP = 4'd8;

   assign scl = (scl_ena && ~scl_clk) ? 1'b0 : 1'bz;
   assign sda = (sda_ena_n == 1'b0) ? 1'b0 : 1'bz;
	
	assign sda_ena = state == START ? data_clk_prev 
							: state == STOP ? ~data_clk_prev
							: sda_int;
	
always @(posedge clk or negedge reset_n) begin //clock quartering to allow proccessor to run faster while maintaining 400MHz SCL
   if (reset_n == 0) begin
       count <= 0;
       data_clk <= 1'b0;
       data_clk_prev <= 1'b0;
       scl_clk <= 1'b0;
   end else begin
		count <= count + 1;
		if(count > div4) count <= 0;
		data_clk_prev <= data_clk;
		if(count < div1) begin					// 1/4, 00 (scl_clk, data_clk)
			scl_clk <= 1'b0;
			data_clk <= 1'b0;
		end else if(count < div2) begin		// 2/4, 01
			scl_clk <= 1'b0;
			data_clk <= 1'b1;
		end else if(count < (div3)) begin	// 3/4, 11
			scl_clk <= 1'b1;
			data_clk <= 1'b1;
		end else begin 							// 4/4, 10
			scl_clk <= 1'b1;
			data_clk <= 1'b0;
		end
	end
end

always @ (posedge clk or negedge reset_n) begin
	if (reset_n == 0) begin
		state <= READY;
		busy <= 1'b1;
		scl_ena <= 1'b0;
		sda_int <= 1'b1;
		ack_error <= 1'b0;
		bit_cnt <= 3'd7;
		data_rd <= 8'b0;
	end else begin
		if (data_clk == 1 && data_clk_prev == 0) begin 			//data_clk rising
			case(state)
				READY: begin
					if(ena == 1) begin
						busy <= 1'b1;
						addr_rw <= {addr, rw};
						data_tx <= data_wr;
						state <= START;
					end else begin
						busy <= 1'b0;
						state <= READY;
					end
				end
				START: begin
					busy <= 1'b1;
					sda_int <= 1'b1;
					state <= COMMAND;
				end	
				COMMAND: begin
					if(bit_cnt == 0) begin
						sda_int <= 1'b0;
						bit_cnt <= 7;
						state <= SLV_ACK1;
					end else begin
						bit_cnt <= bit_cnt - 1'b1;
						sda_int <= data_tx[bit_cnt-1];
						state <= COMMAND;
					end
				end
				SLV_ACK1: begin
					if(addr_rw[0] == 1'b0) begin
						sda_int <= data_tx[bit_cnt];
						state <= WR;
					end else begin
						sda_int <= 1'b1;
						state <= RD;
					end
				end
				WR: begin
					busy <= 1'b1;
					if(bit_cnt == 0) begin
						sda_int <= 1'b1;
						bit_cnt <= 7;
						state <= SLV_ACK2;
					end else begin
						bit_cnt <= bit_cnt - 1'b1;
						sda_int <= data_tx[bit_cnt - 1];
						state <= WR;
					end
				end
				RD: begin
					busy <= 1'b1;
					
				end
				SLV_ACK2: begin
				
				end
				MSTR_ACK: begin
				
				end
				STOP: begin
				
				end
			endcase
		end else if (data_clk == 0 && data_clk_prev == 1)	begin	//data_clk falling
		
		end
	end
end

endmodule 