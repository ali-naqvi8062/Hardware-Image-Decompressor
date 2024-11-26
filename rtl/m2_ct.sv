`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"
`include "M2_param.h"


module m2_ct (
		// we will use both ports of both DP RAMS resulting in 4 available outputs for S' and C (will be using 3/4 for computation)
		input logic 						CLOCK_50, 
		input logic							Resetn, 
		input logic 						Start,
		input logic				[31:0]	read_data_SP_a,
		input logic				[31:0]	read_data_SP_b,
		input logic				[31:0]	read_data_C_a,
		input logic				[31:0]	read_data_C_b,
		input logic	signed	[31:0]	M1,
		input logic	signed	[31:0]	M2,
		input logic	signed	[31:0]	M3,


		output logic signed	[31:0]	M1_op1,
		output logic signed	[31:0]	M1_op2,
		output logic signed	[31:0]	M2_op1,
		output logic signed	[31:0]	M2_op2,
		output logic signed	[31:0]	M3_op1,
		output logic signed	[31:0]	M3_op2,
		output logic						Done,
		output logic			[6:0]		address_T, 	// ***access top port for writing the computed T value (bottom port is used by write_S in the common case so we can't use both but its fine). 
		output logic			[6:0]		address_C_a, 	//let m2 top level know we want to access both ports of the C DPRAM for reading
		output logic			[6:0]		address_C_b,
		output logic			[6:0]		address_SP_a, 	// same for S'
		output logic			[6:0]		address_SP_b,
		output logic signed	[31:0]	write_data_T,// write the computed T value, 1 value per location.  
		output logic						wren_T	 	// write to the top port of DPRAM the computed T value
		
);

logic [6:0] SP_counter, C_counter, T_address_counter, Jump;
logic signed [15:0] SP_buffer, C_buffer;
logic signed [31:0] T_accumulator;

enum logic [3:0] {
	S_IDLE,
	S_LEAD_IN_0,
	S_LEAD_IN_1,
	S_LEAD_IN_2,
	S_LEAD_IN_3,
	S_LEAD_IN_4,
	S_COMMON_0,
	S_COMMON_1,
	S_COMMON_2
} state;

always_ff @(posedge CLOCK_50 or negedge Resetn) begin
	if (~Resetn) begin
		SP_counter <= 7'd0;
		C_counter <= 7'd0;
		Done <= 1'b0;
		T_accumulator <= 32'd0;
		address_T <= 7'd0;
		T_address_counter <= 7'd0;
		SP_buffer <= 16'd0; 
		C_buffer <= 16'd0;
		Jump <= 7'd0;
		
		M1_op1 <= 32'd0;
		M1_op2 <= 32'd0;
				
		M2_op1 <= 32'd0;
		M2_op2 <= 32'd0;
				
		M3_op1 <= 32'd0;
		M3_op2 <= 32'd0;
		state <= S_IDLE;
	end else begin
		case(state) 
		
			S_IDLE: begin
				T_accumulator <= 32'd0;
				address_T <= 7'd0;
				T_address_counter <= 7'd0;
				Jump <= 7'd0;
				Done <= 1'b0;
				SP_counter <= 7'd0;
				C_counter <= 7'd0;
				wren_T <= 1'd0;
				if(Start && ~Done) begin
					address_SP_a <= SP_counter; //33
					address_SP_b <= SP_counter + 1'd1;
					SP_counter <= SP_counter + 2'd2;
					
					address_C_a <= C_counter;
					address_C_b <= C_counter + 1'd1;
					C_counter <= C_counter + 2'd2;
					
					state <= S_LEAD_IN_0;
				end
			end
			
			S_LEAD_IN_0: begin
				address_SP_a <= SP_counter;
				SP_counter <= SP_counter + 1'd1;
				
				address_C_a <= C_counter;
				C_counter <= C_counter + 1'd1;
				
				state <= S_LEAD_IN_1;
			end

			S_LEAD_IN_1: begin
				address_SP_a <= SP_counter;
				SP_counter <= 1'd0;
				
				address_C_a <= C_counter;
				C_counter <= C_counter + 1'd1;
				
				SP_buffer <= $signed(read_data_SP_b[15:0]);
				C_buffer <= $signed(read_data_C_b[15:0]);
				
				M1_op1 <= $signed(read_data_SP_a[31:16]); //y0
				M1_op2 <= $signed(read_data_C_a[31:16]); //c0;
				
				M2_op1 <= $signed(read_data_SP_a[15:0]); //y1
				M2_op2 <= $signed(read_data_C_a[15:0]); //c8;
				
				M3_op1 <= $signed(read_data_SP_b[31:16]); //y2
				M3_op2 <= $signed(read_data_C_b[31:16]); //c16;
				state <= S_LEAD_IN_2;
			end
			
			S_LEAD_IN_2: begin
				address_SP_a <= SP_counter;
				address_SP_b <= SP_counter + 1'd1;
				SP_counter <= SP_counter + 2'd2;
				
				address_C_a <= C_counter;
				address_C_b <= C_counter + 1'd1;
				C_counter <= C_counter + 2'd2;
				
				T_accumulator <= M1 + M2 + M3;

				M1_op1 <= SP_buffer; //y3
				M1_op2 <= C_buffer; //c24
				
				M2_op1 <= $signed(read_data_SP_a[31:16]); //y4
				M2_op2 <= $signed(read_data_C_a[31:16]); //c32;
				
				M3_op1 <= $signed(read_data_SP_a[15:0]); //y5
				M3_op2 <= $signed(read_data_C_a[15:0]); //c40;
				
				state <= S_LEAD_IN_3;
			end
			
			S_LEAD_IN_3: begin
				address_SP_a <= SP_counter;
				SP_counter <= SP_counter + 1'd1;
				
				address_C_a <= C_counter;
				C_counter <= C_counter + 1'd1;
				
				T_accumulator <= T_accumulator + M1 + M2 + M3;

				M1_op1 <= $signed(read_data_SP_a[31:16]); //y6
				M1_op2 <= $signed(read_data_C_a[31:16]); //c48;
				
				M2_op1 <= $signed(read_data_SP_a[15:0]); //y7
				M2_op2 <= $signed(read_data_C_a[15:0]); //c56
					
				state <= S_LEAD_IN_4;
			end
			
			S_LEAD_IN_4: begin
				address_SP_a <= SP_counter;
				SP_counter <= 1'd0;
				
				address_C_a <= C_counter;
				C_counter <= C_counter + 1'd1;
				
				address_T <= T_address_counter;
				T_accumulator <= 32'd0;
				T_address_counter <= T_address_counter + 1'd1;
				write_data_T <= ($signed(T_accumulator + M1 + M2) >>> CT_DIVISOR);
				wren_T <= 1'd1;
				
				C_buffer <= $signed(read_data_C_b[15:0]);

				M1_op1 <= $signed(read_data_SP_a[31:16]); //y0
				M1_op2 <= $signed(read_data_C_a[31:16]); //c1;
				
				M2_op1 <= $signed(read_data_SP_a[15:0]); //y1
				M2_op2 <= $signed(read_data_C_a[15:0]); //c9;
				
				M3_op1 <= $signed(read_data_SP_b[31:16]); //y2
				M3_op2 <= $signed(read_data_C_b[31:16]); //c17;
				
				Jump <= 7'd0;
				state <= S_COMMON_0;
			end
			
			S_COMMON_0: begin
				address_SP_a <= SP_counter + Jump; //0
				address_SP_b <= SP_counter + Jump + 1'd1;
				SP_counter <= SP_counter + 2'd2;
				
				address_C_a <= C_counter; //8
				address_C_b <= C_counter + 1'd1; //9
				C_counter <= C_counter + 2'd2; //10
				
				wren_T <= 1'd0;

				T_accumulator <= M1 + M2 + M3;

				M1_op1 <= SP_buffer; //y3
				M1_op2 <= C_buffer; //c25
				
				M2_op1 <= $signed(read_data_SP_a[31:16]); //y4
				M2_op2 <= $signed(read_data_C_a[31:16]); //c33;
				
				M3_op1 <= $signed(read_data_SP_a[15:0]); //y5
				M3_op2 <= $signed(read_data_C_a[15:0]); //c41;
				
				state <= S_COMMON_1;
			end

			S_COMMON_1: begin
				address_SP_a <= SP_counter + Jump;
				SP_counter <= SP_counter + 1'd1;
				
				address_C_a <= C_counter;
				C_counter <= C_counter + 1'd1;
				
				T_accumulator <= T_accumulator + M1 + M2 + M3;

				M1_op1 <= $signed(read_data_SP_a[31:16]); //y6
				M1_op2 <= $signed(read_data_C_a[31:16]); //c49;
				
				M2_op1 <= $signed(read_data_SP_a[15:0]); //y7
				M2_op2 <= $signed(read_data_C_a[15:0]); //c57
				
				state <= S_COMMON_2;
			end
	
			S_COMMON_2: begin
				address_SP_a <= SP_counter + Jump;
				SP_counter <= 1'd0;
				
				address_C_a <= C_counter;
				C_counter <= C_counter + 1'd1;
				
				address_T <= T_address_counter;
				T_accumulator <= 32'd0;
				T_address_counter <= T_address_counter + 1'd1;
				write_data_T <= ($signed(T_accumulator + M1 + M2) >>> CT_DIVISOR);
				wren_T <= 1'd1;
				
				SP_buffer <= $signed(read_data_SP_b[15:0]);
				C_buffer <= $signed(read_data_C_b[15:0]);

				M1_op1 <= $signed(read_data_SP_a[31:16]); //y0
				M1_op2 <= $signed(read_data_C_a[31:16]); //c1;
				
				M2_op1 <= $signed(read_data_SP_a[15:0]); //y1
				M2_op2 <= $signed(read_data_C_a[15:0]); //c9;
				
				M3_op1 <= $signed(read_data_SP_b[31:16]); //y2
				M3_op2 <= $signed(read_data_C_b[31:16]); //c17;
					
				state <= S_COMMON_0;
				
				if(C_counter == 7'd31) begin
					C_counter <= 7'd0;
					Jump <= Jump + 7'd4;
				end 
				
				if (Jump == 7'd32) begin
					Done <= 1'b1;					
					state <= S_IDLE; 
				end
			end
			default: state <= S_IDLE;
		endcase
	end
end

endmodule
