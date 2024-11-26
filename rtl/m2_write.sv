`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"
`include "M2_param.h"

module m2_write (

		input logic 				CLOCK_50, 
		input logic					Resetn, 
		input logic 				Start,
		input logic		[31:0] 	read_data_T, //bottom port is for reading S.
		input logic 	[17:0]	Base_address, 
		input logic 	[8:0]		Jump_offset,
		

		output logic				Done,
		output logic 	[17:0]	SRAM_address,
		output logic 	[15:0]	SRAM_write_data,
		output logic	[6:0] 	address_T,
		output logic 				SRAM_we_n
);


logic [10:0] jump; 
logic [6:0] T_counter;
logic [31:0] buff_reg, other_data;
logic flag;
logic [7:0] buff_write, other_write;
logic [17:0] SRAM_counter;

enum logic [2:0] {
	S_IDLE,
	S_LEAD_IN_0,
	S_LEAD_IN_1,
	S_COMMON_0,
	S_COMMON_1
} state;

assign SRAM_write_data = {buff_write,other_write};

always_comb begin
	if(buff_reg[31] == 1'b1) begin
		buff_write = 8'd0;
	end else if (|buff_reg[31:8]) begin
		buff_write = 8'd255;
	end else begin
		buff_write = buff_reg[7:0];
	end
	
	if(other_data[31] == 1'b1) begin
		other_write = 8'd0;
	end else if (|other_data[31:8]) begin
		other_write = 8'd255;
	end else begin
		other_write = other_data[7:0];
	end
end

always_ff @(posedge CLOCK_50 or negedge Resetn) begin
	if (~Resetn) begin
		Done <= 1'b0;
		jump <= 11'd0;
		T_counter <= 7'd0;
		flag <= 1'd0;
		T_counter <= 7'd0;
		SRAM_counter <= 7'd0;
		state <= S_IDLE;
	end else begin
		case(state)
			S_IDLE: begin
				Done <= 1'd0;
				SRAM_we_n <= 1'd1;
				if(Start && ~Done) begin
					address_T <= S_OFFSET + T_counter; //0
					T_counter <= T_counter + 1'd1;
					state <= S_LEAD_IN_0;
				end
			end
			
			S_LEAD_IN_0: begin
				address_T <= S_OFFSET + T_counter;
				T_counter <= T_counter + 1'd1;
				state <= S_LEAD_IN_1;
			end
						
			S_LEAD_IN_1: begin
				address_T <= S_OFFSET + T_counter;
				T_counter <= T_counter + 1'd1;
				buff_reg <= read_data_T;
				state <= S_COMMON_0;
			end
			
			S_COMMON_0: begin
				SRAM_address <= Base_address + SRAM_counter + jump;
				SRAM_counter <= SRAM_counter + 1'd1;
				SRAM_we_n <= 1'd0;
				
				address_T <= S_OFFSET + T_counter;
				T_counter <= T_counter + 1'd1;
				other_data <= read_data_T;
				state <= S_COMMON_1;
				
				if(T_counter == 7'd65) begin 
					Done <= 1'd1;
					T_counter <= 7'd0;
					SRAM_counter <= 7'd0;
					jump <= 11'd0;
					state <= S_IDLE;
				end
				
			end
			
			S_COMMON_1: begin
				
				SRAM_we_n <= 1'd1;
				
				address_T <= S_OFFSET + T_counter;
				T_counter <= T_counter + 1'd1;
				buff_reg <= read_data_T;
				
				if(SRAM_counter == 3'd4) begin
					jump <= jump + Jump_offset;
					SRAM_counter <= 3'd0;
				end
				
				state <= S_COMMON_0;
			end
			default: state <= S_IDLE;
		endcase
	end
end
endmodule
