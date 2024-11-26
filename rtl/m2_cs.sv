`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"
`include "M2_param.h"

module m2_cs (

		input logic 						CLOCK_50, 
		input logic							Resetn, 
		input logic 						Start,
		input logic				[31:0]	read_data_T_a, // we don't need the other output port because we're just writing (S) to it.
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
		output logic						wren_T_b, // writing only to port B, port A is for reading.
		output logic			[6:0] 	address_T_a,	
		output logic			[6:0] 	address_T_b,	// for putting S back
		output logic 			[6:0]		address_C_a,
		output logic 			[6:0]		address_C_b, 		
		output logic signed	[31:0]	write_data_T_b // writing only to port B, port A is for reading. 
);

/*	Define signals here */
logic signed [31:0] S_accumulator[2:0], S_buff1, S_buff2;
logic [6:0] SRAM_counter, T_write_counter, T_read_counter, C_addr_counter;
logic [5:0] write_offset, offset;
logic [3:0] T_addr_jump;
logic [2:0] write_flag, write_flag2;
logic flag, flag2, flag3, flag4;



enum logic [3:0] {
	S_IDLE,
	S_LEAD_IN_0,
	S_LEAD_IN_1,
	S_COMMON_0,
	S_LEAD_OUT_0,
	S_LEAD_OUT_1,
	S_LEAD_OUT_2,
	S_LEAD_OUT_3
} state;

//assign write_data_T_b = {,};
 
always_ff @(posedge CLOCK_50 or negedge Resetn) begin
	if (~Resetn) begin
	
		Done <= 1'b0;
		
		//flags
		flag <= 1'd0;
		flag2 <= 1'd0;
		flag3 <= 1'd0;
		flag4 <= 1'd0;
		write_flag <= 3'd0;
		write_flag2 <= 3'd0;
		
		// Counters,increments and jumps
		T_write_counter <= 7'd0;
		T_read_counter <= 7'd0;
		C_addr_counter <= 7'd0;
		T_addr_jump <= 4'd0;
		write_offset <= 6'd0;
		offset <= 6'd0;
		
		// Accumulators and multiplier operands
		S_accumulator[0] <= 32'd0;
		S_accumulator[1] <= 32'd0;
		S_accumulator[2] <= 32'd0;
		
		S_buff1 <= 32'd0;
		S_buff1 <= 32'd0;
		
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
				Done <= 1'b0;
				wren_T_b <= 1'd0;
				S_accumulator[0] <= 32'd0;
				S_accumulator[1] <= 32'd0;
				S_accumulator[2] <= 32'd0;
				T_write_counter <= 7'd0;
				T_read_counter <= 7'd0;
				C_addr_counter <= 7'd0;
				T_addr_jump <= 4'd0;
				write_offset <= 6'd0;
				offset <= 6'd0;
				flag <= 1'd0;
				flag2 <= 1'd0;
				flag3 <= 1'd0;
				flag4 <= 1'd0;
				if(Start && ~Done) begin
					address_T_a <= T_read_counter; // 0
					T_read_counter <= T_read_counter + 7'd8;
					
					address_C_a <= C_addr_counter + CT_OFFSET; // 0
					address_C_b <= C_addr_counter + 1'd1 + CT_OFFSET; // 1
					C_addr_counter <= C_addr_counter + 2'd2; // 2
					
					state <= S_LEAD_IN_0;
				end
			end
			
			S_LEAD_IN_0: begin // C_addr_counter = 2 now, T_read_counter = 8 now
				address_T_a <= T_read_counter; // 8
				T_read_counter <= T_read_counter + 7'd8; // becomes 16 in next cc

				address_C_a <= C_addr_counter + CT_OFFSET; // 2
				address_C_b <= C_addr_counter + 1'd1 + CT_OFFSET; // 3
				C_addr_counter <= C_addr_counter + 2'd2; // becomes 4 in next cc
				
				state <= S_LEAD_IN_1;
			end
			
			S_LEAD_IN_1: begin // C_addr_counter = 4 now, T_read_counter = 16 now, 
									//data lines now have CT0,CT8,CT16 & CT24 as well as T0
			
				address_T_a <= T_read_counter; // 16
				T_read_counter <= T_read_counter + 7'd8; // becomes 24 in next cc

				address_C_a <= C_addr_counter + CT_OFFSET; // 4
				address_C_b <= C_addr_counter + 1'd1 + CT_OFFSET; // 5
				C_addr_counter <= C_addr_counter + 2'd2; // becomes 6 in next cc
				
					
				// prep operands
				M1_op1 <= $signed(read_data_T_a);
				M1_op2 <= $signed(read_data_C_a[31:16]); // CT0
				
				M2_op1 <= $signed(read_data_T_a);
				M2_op2 <= $signed(read_data_C_a[15:0]); // CT8
				
				M3_op1 <= $signed(read_data_T_a);
				M3_op2 <= $signed(read_data_C_b[31:16]); // CT16
				
				// CT 24 is also on the data line but we don't need it
				
				// prepare for common states
				T_addr_jump <= 4'd0;
				offset <= 6'd0;
				
				state <= S_COMMON_0;
			end
			
			S_COMMON_0: begin 
				
				S_accumulator[0] <= S_accumulator[0] + M1;
				S_accumulator[1] <= S_accumulator[1] + M2;
				S_accumulator[2] <= S_accumulator[2] + M3;
/////////////////////////////////////////////////////// T ADDRESS LOGIC & INCREMENTING ////////////////////////

				if(T_read_counter >= 7'd64) begin // This indicates the end of the T row (when we address T56, this counter is at 64 or higher due to jump)
					address_T_a <= T_addr_jump; // 1 when c counter reaches 33
					T_read_counter <= 7'd8;
				end else if(C_addr_counter == 7'd31) begin // Whenever C counter is at 31 we know a new batch is imminent
					T_addr_jump <= T_addr_jump + 1'd1;
					address_T_a <= T_read_counter + T_addr_jump;
					T_read_counter <= T_read_counter + 7'd8;
				end else begin
					address_T_a <= T_read_counter + T_addr_jump;
					T_read_counter <= T_read_counter + 7'd8;
				end

/////////////////////////////////////////////////////// C ADDRESS LOGIC & INCREMENTING ////////////////////////

				// manage C counter increment with flags first. 
				// There are three types: 
				// TYPE 1: The double address access (at the beginning) goes 0, 1, 2, 3, ... using both ports (see COLUMN B/C)
				// TYPE 2: When it jumps from 16 to 1 and starts going 1,3,5,7... and 16,18,20... (see COLUMN J)
				// TYPE 3: When it only uses 1 port and jumps from 30 to 17 and goes 17, 19, 21 ... (see COLUMN R)

				// do the increments based on the flags:
				
				if (flag2) begin // TYPE 3
					address_C_b <= C_addr_counter + CT_OFFSET; //17, 19, 21... 
					C_addr_counter <= C_addr_counter + 2'd2;
				end else if(flag) begin // TYPE 2
					address_C_a <= C_addr_counter + CT_OFFSET - offset; // 18 - 15 = 3, 20 - 15 = 5, ...
					address_C_b <= C_addr_counter + CT_OFFSET; //18, 20, 22, ... 
					C_addr_counter <= C_addr_counter + 2'd2; // becomes 20 next cc, becomes 22 next cc, ... 
				end else begin // TYPE 1 (both flags are down) we start the CC with this one
					address_C_a <= C_addr_counter + CT_OFFSET; 
					address_C_b <= C_addr_counter + 1'd1 + CT_OFFSET; 
					C_addr_counter <= C_addr_counter + 2'd2; 
				end
				
				// raise flags based on what C counter is to control the increment 
				
				if(C_addr_counter == 7'd16) begin // change from TYPE 1 to TYPE 2, occurs when counter is 16 @ column J
					address_C_a <= CT_OFFSET + 7'd1;
					address_C_b <= C_addr_counter + CT_OFFSET; // 16, 18, 20, ... 
					C_addr_counter <= C_addr_counter + 2'd2; // will be 18 in the next cc, will be 20 next cc, ... 
					offset <= 6'd15;
					flag <= 1'd1; // initiate TYPE 2
				end else if(C_addr_counter == 7'd30) begin // change from TYPE 2 to TYPE 3, occurs when counter is 30 @ column R
					flag <= 1'd0;
					flag2 <= 1'd1; // initiate TYPE 3
					C_addr_counter <= 7'd17; // start at 17
				end else if (C_addr_counter == 7'd31) begin // change from TYPE 3 back to TYPE 1, occurs when counter is 3 @ column Z
					flag <= 1'd0;
					flag2 <= 1'd0;
					C_addr_counter <= 7'd0; // reset back to 0 
				end
				


								
				
/////////////////////////////////////////////////////// WRITE LOGIC ////////////////////////////////////

				// writing occurs at specific locations of the C_counter, see state table
				// it occurs in a series of 3 writes, then later on another 3 writes and lastly 2 writes
				// 3, 3 and 2 is the order of writes. 
				// The first 3 occur when counter is 22 
				// The second 3 occur when counter is 23 
				// The last 3 occur when counter is 6 and we loop back around once, hence why T_addr_jump is needed.

				// Using the write flags which are raised based on the counter, check whether it is a series of 3 writes
				// or 2 writes:
				
				//write 2 times in a row
				if(write_flag2 == 2'd1) begin
					address_T_b = T_write_counter + S_OFFSET + write_offset; 
					T_write_counter <= T_write_counter + 7'd8;
					write_data_T_b <= S_buff1;
					write_flag2 <= 2'd2;  
				end else if (write_flag2 == 2'd2) begin
					write_offset <= write_offset + 1'd1; // we know the last 2 writes are done if we end up in this else block, so we increment write_offset.
					write_flag2 <= 3'd0;
					T_write_counter <= 7'd0;
					wren_T_b <= 1'd0;
				end
				
				// write 3 times in a row
				if(write_flag != 1'd0 && write_flag < 2'd3) begin
					address_T_b = T_write_counter + S_OFFSET + write_offset; // to 8, to 16, to 9 to 17
					T_write_counter <= T_write_counter + 7'd8;
					write_flag <= write_flag + 1'd1; // now its 2... so one more write (3 writes for counter ==22 or ==23)
					if(write_flag == 2'd2) write_data_T_b <= S_buff2;
					else write_data_T_b <= S_buff1;
				end else if (write_flag == 2'd3) begin
					write_flag <= 1'd0;
					wren_T_b <= 1'd0;
				end
				
				if(C_addr_counter == 6'd22 || C_addr_counter == 6'd23) begin
				
					write_data_T_b  <= ($signed(S_accumulator[0]) >>> CS_DIVISOR);
					S_buff1 <= ($signed(S_accumulator[1]) >>> CS_DIVISOR);
					S_buff2 <= ($signed(S_accumulator[2]) >>> CS_DIVISOR);
					
					S_accumulator[0] <= M1;
					S_accumulator[1] <= M2;
					S_accumulator[2] <= M3;
				
					wren_T_b <= 1'd1;
					write_flag <= 1'd1;
					address_T_b = T_write_counter + S_OFFSET + write_offset; // to 0, to 1, ... 
					T_write_counter <= T_write_counter + 7'd8;
					
				end
				if (T_addr_jump != 1'd0 && C_addr_counter == 6'd6) begin
					
					write_data_T_b  <= ($signed(S_accumulator[0]) >>> CS_DIVISOR);
					S_buff1 <= ($signed(S_accumulator[1]) >>> CS_DIVISOR);
					
					S_accumulator[0] <= M1;
					S_accumulator[1] <= M2;
					S_accumulator[2] <= M3;

					wren_T_b <= 1'd1;
					write_flag2 <= 1'd1;
					address_T_b = T_write_counter + S_OFFSET + write_offset; 
					T_write_counter <= T_write_counter + 7'd8;
				end
				
/////////////////////////// MATH /////////////////////////////
				
				if(C_addr_counter == 6'd20) begin
					flag3 <= 1'd1;
				end else if (C_addr_counter == 6'd19) begin
					flag3 <= 1'd0;
					flag4 <= 1'd1;
				end else if (C_addr_counter == 6'd2) begin
					flag3 <= 1'd0;
					flag4 <= 1'd0;
				end
				
				if(flag3) begin // first change
					M1_op1 <= $signed(read_data_T_a);
					M1_op2 <= $signed(read_data_C_a[15:0]); // CT24
				
					M2_op1 <= $signed(read_data_T_a);
					M2_op2 <= $signed(read_data_C_b[31:16]); // CT32
				
					M3_op1 <= $signed(read_data_T_a);
					M3_op2 <= $signed(read_data_C_b[15:0]); // CT40
				end else if (flag4) begin // second change
					M1_op1 <= $signed(read_data_T_a);
					M1_op2 <= $signed(read_data_C_b[31:16]); // CT48
				
					M2_op1 <= $signed(read_data_T_a);
					M2_op2 <= $signed(read_data_C_b[15:0]); // CT56
				end else begin 
					M1_op1 <= $signed(read_data_T_a);
					M1_op2 <= $signed(read_data_C_a[31:16]); // CT0
				
					M2_op1 <= $signed(read_data_T_a);
					M2_op2 <= $signed(read_data_C_a[15:0]); // CT8
				
					M3_op1 <= $signed(read_data_T_a);
					M3_op2 <= $signed(read_data_C_b[31:16]); // CT16
				end
				
				if(T_read_counter == 7'd64 && T_addr_jump == 4'd8) begin
					state <= S_LEAD_OUT_0; //change this
				end
			end
			
			S_LEAD_OUT_0: begin 
				S_accumulator[0] <= S_accumulator[0] + M1;
				S_accumulator[1] <= S_accumulator[1] + M2;
				
				M1_op1 <= $signed(read_data_T_a);
				M1_op2 <= $signed(read_data_C_b[31:16]); // CT48
				
				M2_op1 <= $signed(read_data_T_a);
				M2_op2 <= $signed(read_data_C_b[15:0]);
				state <= S_LEAD_OUT_1;
			end
			
			S_LEAD_OUT_1: begin 
			
				S_accumulator[0] <= S_accumulator[0] + M1;
				S_accumulator[1] <= S_accumulator[1] + M2;
				
				state <= S_LEAD_OUT_2;
				
			end
			
			S_LEAD_OUT_2: begin 
				wren_T_b <= 1'd1;
				address_T_b = T_write_counter + S_OFFSET + write_offset; // to 0, to 1, ... 
				T_write_counter <= T_write_counter + 7'd8;
				write_data_T_b  <= ($signed(S_accumulator[0]) >>> CS_DIVISOR);
				
				state <= S_LEAD_OUT_3;
				
			end
			S_LEAD_OUT_3: begin 
				wren_T_b <= 1'd1;
				address_T_b = T_write_counter + S_OFFSET + write_offset; // to 0, to 1, ... 
				T_write_counter <= T_write_counter + 7'd8;
				write_data_T_b  <= ($signed(S_accumulator[1]) >>> CS_DIVISOR);
				
				Done <= 1'd1;
				state <= S_IDLE;
				
			end
			default: state <= S_IDLE;
		endcase
	end
end

endmodule
