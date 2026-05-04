module control_unit(
	input wire clock, reset_n,
	
	inout wire encoder1_sda,
	inout wire encoder1_scl,
	
	inout wire encoder2_sda,
	inout wire encoder2_scl,
	
	inout wire chip_sda,
	inout wire chip_scl
);

//GLOBAL STATES
localparam RESET = 4'd0, READY = 4'd1;

//CONTROL UNIT STATES
localparam WAIT = 4'd2, WAITSEND = 4'd3;
reg[3:0] control_state;
reg lastSend; //0 for encoder1, 1 for encoder2

//ENCODER CONTROL STATES
localparam GETDATA = 4'd2, WAITDATA = 4'd3, STOREDATA = 4'd4, WAITNOTDATA = 4'd5;
reg[3:0] encoder1_state, encoder2_state;

//TIME REGISTER
reg[31:0] global_time;

//ENCODER DATA
reg[31:0] encoder1_time, encoder2_time;
reg[11:0] encoder1_data, encoder2_data;
reg encoder1_dataREADY, encoder2_dataREADY;

//ENCODER CONNECTIONS
reg encoder1_getData, encoder2_getData;
wire[11:0] encoder1_out, encoder2_out;
wire encoder1_dataFlag, encoder2_dataFlag;

//CHIP CONNECTIONS
reg sendData, encoder_select;
reg [31:0] timestamp;
reg [11:0]  dataOut;
wire sending;

encoder_interface encoder1 (.clk(clock), .reset_n(reset_n), .getData(encoder1_getData), .encoderData(encoder1_out), .data_flag(encoder1_dataFlag), .sda(encoder1_sda), .scl(encoder1_scl));
encoder_interface encoder2 (.clk(clock), .reset_n(reset_n), .getData(encoder2_getData), .encoderData(encoder2_out), .data_flag(encoder2_dataFlag), .sda(encoder2_sda), .scl(encoder2_scl));
odom_interface chip (.clk(clock), .reset_n(reset_n), .sendData(sendData), .select(encoder_select), .timestamp(timestamp), .data(dataOut), .sending(sending), .sda(chip_sda), .scl(chip_scl));


always @ (posedge clock or negedge reset_n) begin
	if(reset_n == 0) begin
		encoder1_state <= RESET;
		encoder1_dataREADY <= 0;
		encoder1_time <= 0;
		encoder1_data <= 0;
		encoder1_getData <= 0;
		
		encoder2_state <= RESET;
		encoder2_dataREADY <= 0;
		encoder2_time <= 0;
		encoder2_data <= 0;
		encoder2_getData <= 0;
		
		control_state <= RESET;
		global_time <= 0;
		lastSend <= 1;
		encoder_select <= 0;
		timestamp <= 0;
		dataOut <= 0;
		sendData <= 0;
	end else begin
		global_time <= global_time + 1;


		case(encoder1_state)
			RESET: begin//stays in reset state until encoder interface is reset
				encoder1_getData <= 0;
				encoder1_dataREADY <= 0;
				if(encoder1_dataFlag == 0) encoder1_state <= GETDATA;
				else encoder1_state <= RESET;
			end
			GETDATA: begin
				encoder1_getData <= 1;
				encoder1_state <= WAITNOTDATA;
			end
			WAITNOTDATA: begin
				if(encoder1_dataFlag == 0) encoder1_state <= WAITDATA;
				else encoder1_state <= WAITNOTDATA;
			end
			WAITDATA: begin
				if(encoder1_dataFlag == 1) encoder1_state <= STOREDATA;
				else encoder1_state <= WAITDATA;
				encoder1_getData <= 0;
			end
			STOREDATA: begin
				encoder1_data <= encoder1_out;
				encoder1_time <= global_time;
				encoder1_dataREADY <= 1;
				encoder1_state <= READY;
			end
			READY: begin
				if(encoder1_dataREADY == 1) encoder1_state <= READY;
				else encoder1_state <= GETDATA;
			end
		endcase
		
		case(encoder2_state)
			RESET: begin//stays in reset state until encoder interface is reset
				encoder2_getData <= 0;
				encoder2_dataREADY <= 0;
				if(encoder2_dataFlag == 0) encoder2_state <= GETDATA;
				else encoder2_state <= RESET;
			end
			GETDATA: begin
				encoder2_getData <= 1;
				encoder2_state <= WAITNOTDATA;
			end
			WAITNOTDATA: begin
				if(encoder2_dataFlag == 0) encoder2_state <= WAITDATA;
				else encoder2_state <= WAITNOTDATA;
			end
			WAITDATA: begin
				if(encoder2_dataFlag == 1) encoder2_state <= STOREDATA;
				else encoder2_state <= WAITDATA;
				encoder2_getData <= 0;
			end
			STOREDATA: begin
				encoder2_data <= encoder2_out;
				encoder2_time <= global_time;
				encoder2_dataREADY <= 1;
				encoder2_state <= READY;
			end
			READY: begin
				if(encoder2_dataREADY == 1) encoder2_state <= READY;
				else encoder2_state <= GETDATA;
			end
		endcase


		case(control_state)
			RESET:begin
				control_state <= READY;
			end
			READY: begin
				if(encoder1_dataREADY == 1 && lastSend == 1) begin
					timestamp <= global_time - encoder1_time;
					dataOut <= encoder1_data;
					encoder1_dataREADY <= 0;
					lastSend <= 0;
					sendData <= 1;
					encoder_select <= 0;
					control_state <= WAITSEND;
				end else if(encoder2_dataREADY == 1) begin
					timestamp <= global_time - encoder2_time;
					dataOut <= encoder2_data;
					encoder2_dataREADY <= 0;
					lastSend <= 1;
					sendData <= 1;
					encoder_select <= 1;
					control_state <= WAITSEND;
				end else control_state <= READY;
			end
			WAITSEND: begin
				if(sending == 1) begin
					control_state <= WAIT;
					sendData <= 0;
				end else control_state <= WAITSEND;
			end
			WAIT: begin
				if(sending == 1) control_state <= WAIT;
				else begin
					control_state <= READY;
				end
			end
		endcase
	end
end

endmodule 