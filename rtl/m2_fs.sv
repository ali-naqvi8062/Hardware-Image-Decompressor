`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"
`include "M2_param.h"

module m2_fs (

		input logic 			CLOCK_50, 
		input logic				Resetn, 
		input logic [15:0] 	SRAM_read_data,
		input logic [17:0]	Base_address, // 76800, 76808...
		input logic [8:0]		Jump_offset,
		input logic 			Start,
		
		output logic			Done,
		output logic [17:0]	SRAM_address,
		output logic [6:0] 	address_SP,
		output logic [31:0]	write_data_SP,
		output logic 			wren_SP
		
);

logic [15:0]	buff_reg;
logic [17:0]	jump;
logic [6:0]		DP_counter; 
logic [3:0] 	row_index;

enum logic [2:0] {
	S_IDLE,
	S_LEAD_IN_0,
	S_LEAD_IN_1,
	S_READ_EVEN,
	S_READ_ODD
} state;

always_ff @(posedge CLOCK_50 or negedge Resetn) begin
	if (~Resetn) begin
		row_index <= 4'd0;
		DP_counter <= 7'd0;
		jump <= 18'd0;
		wren_SP <= 1'd0;
		buff_reg <= 16'd0;
		Done <= 1'b0;
		state <= S_IDLE;
	end else begin
		case (state) 
			S_IDLE: begin 
				Done <= 1'b0;
				wren_SP <= 1'd0;
				if(Start && ~Done) begin
					SRAM_address <= Base_address + row_index + jump; // 76800
					row_index <= row_index + 1'd1;
					state <= S_LEAD_IN_0;
				end
			end
			
			S_LEAD_IN_0: begin //requests y0
					SRAM_address <= Base_address + row_index + jump; //76808 ri = 1
					row_index <= row_index + 1'd1;
					state <= S_LEAD_IN_1;
			end
			
			S_LEAD_IN_1: begin //requests y1
				SRAM_address <= Base_address + row_index + jump; // 76816 ri = 2
				row_index <= row_index + 1'd1;
				state <= S_READ_EVEN;
			end
			
			S_READ_EVEN: begin // requests y2, received y0
				SRAM_address <= Base_address + row_index + jump; // 76824 ri = 3, 76840 ri = 5, 76848 ri = 7
				buff_reg <= SRAM_read_data; 
				row_index <= row_index + 1'd1;
				wren_SP <= 1'd0;
				state <= S_READ_ODD;
				if(row_index == 4'd7) begin
					row_index <= 4'd0;
					jump <= jump + Jump_offset; //320*7 only
				end
			end
			
			S_READ_ODD: begin // 76832 ri = 4
				SRAM_address <= Base_address + row_index + jump;
				row_index <= row_index + 1'd1;
				address_SP <= DP_counter; 
				DP_counter <= DP_counter + 1'd1;
				wren_SP <= 1'd1;
				state <= S_READ_EVEN;
				write_data_SP <= {buff_reg, SRAM_read_data}; //y0y1
				if(DP_counter == 7'd31) begin
					Done <= 1'b1;
					row_index <= 3'd0;
					DP_counter <= 7'd0;
					jump <= 18'd0;
					buff_reg <= 16'd0;
					state <= S_IDLE;
				end
			end
			default: state <= S_IDLE;
		endcase
	end
end

endmodule
