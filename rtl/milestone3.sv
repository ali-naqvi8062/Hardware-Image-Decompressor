`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"
`include "M2_param.h"
`include "M3_param.h"


module milestone3 (

		input logic 			CLOCK_50, 
		input logic				Resetn, 
		input logic [15:0] 	SRAM_read_data,
		input logic [31:0]	read_data_M3_b, // bottom data port of dpram 4 for reading values from dpram 4 to then put into sp ram
		input logic [17:0]	Base_address, // for writing back to sram
		input logic [8:0]		Jump_offset,
		input logic 			Start,
		
		output logic 			Done,
		output logic [17:0]	SRAM_address,
		output logic [15:0]	SRAM_write_data,
		output logic 			SRAM_we_n,
		output logic [6:0] 	address_M3, // top address port of dpram 4 
		output logic [31:0]	write_data_M3, // top data port of dpram 4 for writing values into dpram 4 from sram bitstream
		output logic 			wren_M3,
		output logic [6:0] 	address_M3_b, // bottom data port of dpram 4 
		output logic [6:0] 	address_SP_a, // top port of sp ram to be filled with the read value from dpram 4
		output logic [31:0]	write_data_SP_a, // to be filled with the read value from dpram 4
		output logic 			wren_SP_a
		
);

typedef enum logic [3:0] {
	S_IDLE,
	S_LEAD_IN_0,
	S_LEAD_IN_1,
	S_LEAD_IN_2,
	S_LEAD_IN_3,
	S_PROCESS_HEADER,
	S_WRITE_3BIT,
	S_ZERO_RUN,
	S_ALL_ZERO,
	S_DELAY_1,
	S_DELAY_2,
	S_REST
} M3_state_type;

enum logic [2:0]{
	S_M3FS_IDLE,
	S_M3FS_LEAD_IN_0,
	S_M3FS_LEAD_IN_1,
	S_M3FS_READ_ODD,
	S_M3FS_READ_EVEN,
	S_M3FS_LEAD_OUT_0
} M3FS_state;

M3_state_type state;
M3_state_type nextState;

logic [31:0] bitstream_buff, DPRAM_write;
logic [15:0] SRAM_read_buff, SRAM_write, DPRAM4_buffer;
logic [17:0] SRAM_read_counter;
logic [11:0] next_SRAM_write_counter;
logic [5:0]  zz_counter, next_zz_counter, DPRAM4_counter;
logic [4:0] SP_DPRAM_counter;
logic quant, leadInFlag, readFlag, bufferFlag, decodeDone;

/*
	fsFlag is raised when m3 dpram is 2/3 full ( check in s_process_header: writes to adr 30, next_zz_counter == 37)
	once fs flag is raised use the 2nd port of the m3 dpram to read outvalues in row order (0,1,2,3...)
		i think implementing by adding an if statement below the always ff case statement would work
	follow the same pattern as fs where once 2 values are read, they are packed together and sent the the SP dpram
	will need to shorten the values to 16 bits (values are 9 bits max so {m3dpram[31], m3dpram[14:0]} would work)
	additional inputs and outputs to the m3 module will need to be added for accessing the 2nd port of m3 dpram and the sp dpram
*/

logic [3:0] shiftAmount;
logic [4:0] dataEnd;
logic [2:0] multiWriteInput, quantShift; // for the headers that write multiple values

always_comb begin
	case(zz_counter) 
		6'd0: next_zz_counter = 6'd1;
		6'd1: next_zz_counter = 6'd8;
		6'd8: next_zz_counter = 6'd16;
		6'd16: next_zz_counter = 6'd9;
		6'd9: next_zz_counter = 6'd2;
		6'd2: next_zz_counter = 6'd3;
		6'd3: next_zz_counter = 6'd10;
		6'd10: next_zz_counter = 6'd17;
		6'd17: next_zz_counter = 6'd24;
		6'd24: next_zz_counter = 6'd32;
		6'd32: next_zz_counter = 6'd25;
		6'd25: next_zz_counter = 6'd18;
		6'd18: next_zz_counter = 6'd11;
		6'd11: next_zz_counter = 6'd4;
		6'd4: next_zz_counter = 6'd5;
		6'd5: next_zz_counter = 6'd12;
		6'd12: next_zz_counter = 6'd19;
		6'd19: next_zz_counter = 6'd26;
		6'd26: next_zz_counter = 6'd33;
		6'd33: next_zz_counter = 6'd40;
		6'd40: next_zz_counter = 6'd48;
		6'd48: next_zz_counter = 6'd41;
		6'd41: next_zz_counter = 6'd34;
		6'd34: next_zz_counter = 6'd27;
		6'd27: next_zz_counter = 6'd20;
		6'd20: next_zz_counter = 6'd13;
		6'd13: next_zz_counter = 6'd6;
		6'd6: next_zz_counter = 6'd7;
		6'd7: next_zz_counter = 6'd14;
		6'd14: next_zz_counter = 6'd21;
		6'd21: next_zz_counter = 6'd28;
		6'd28: next_zz_counter = 6'd35;
		6'd35: next_zz_counter = 6'd42;
		6'd42: next_zz_counter = 6'd49;
		6'd49: next_zz_counter = 6'd56;
		6'd56: next_zz_counter = 6'd57;
		6'd57: next_zz_counter = 6'd50;
		6'd50: next_zz_counter = 6'd43;
		6'd43: next_zz_counter = 6'd36;
		6'd36: next_zz_counter = 6'd29;
		6'd29: next_zz_counter = 6'd22;
		6'd22: next_zz_counter = 6'd15;
		6'd15: next_zz_counter = 6'd23;
		6'd23: next_zz_counter = 6'd30;
		6'd30: next_zz_counter = 6'd37;
		6'd37: next_zz_counter = 6'd44;
		6'd44: next_zz_counter = 6'd51;
		6'd51: next_zz_counter = 6'd58;
		6'd58: next_zz_counter = 6'd59;
		6'd59: next_zz_counter = 6'd52;
		6'd52: next_zz_counter = 6'd45;
		6'd45: next_zz_counter = 6'd38;
		6'd38: next_zz_counter = 6'd31;
		6'd31: next_zz_counter = 6'd39;
		6'd39: next_zz_counter = 6'd46;
		6'd46: next_zz_counter = 6'd53;
		6'd53: next_zz_counter = 6'd60;
		6'd60: next_zz_counter = 6'd61;
		6'd61: next_zz_counter = 6'd54;
		6'd54: next_zz_counter = 6'd47;
		6'd47: next_zz_counter = 6'd55;
		6'd55: next_zz_counter = 6'd62;
		6'd62: next_zz_counter = 6'd63;
		6'd63: next_zz_counter = 6'd0;
		default next_zz_counter = 6'd0;
	endcase
end

always_comb begin
	if(~quant) begin
		case(next_zz_counter[5:3]+next_zz_counter[2:0])
			4'd0: quantShift = 3'd3;
			4'd1: quantShift = 3'd2;
			4'd2: quantShift = 3'd3;
			4'd3: quantShift = 3'd3;
			4'd4: quantShift = 3'd4;
			4'd5: quantShift = 3'd4;
			4'd6: quantShift = 3'd5;
			4'd7: quantShift = 3'd5;
			4'd8: quantShift = 3'd6;
			4'd9: quantShift = 3'd6;
			4'd10: quantShift = 3'd6;
			4'd11: quantShift = 3'd6;
			4'd12: quantShift = 3'd6;
			4'd13: quantShift = 3'd6;
			4'd14: quantShift = 3'd6;
			default quantShift = 3'd3;
		endcase
	end else begin
		case(next_zz_counter[5:3]+next_zz_counter[2:0])
			4'd0: quantShift = 3'd3;
			4'd1: quantShift = 3'd1;
			4'd2: quantShift = 3'd1;
			4'd3: quantShift = 3'd1;
			4'd4: quantShift = 3'd2;
			4'd5: quantShift = 3'd2;
			4'd6: quantShift = 3'd3;
			4'd7: quantShift = 3'd3;
			4'd8: quantShift = 3'd4;
			4'd9: quantShift = 3'd4;
			4'd10: quantShift = 3'd4;
			4'd11: quantShift = 3'd5;
			4'd12: quantShift = 3'd5;
			4'd13: quantShift = 3'd5;
			4'd14: quantShift = 3'd5;
			default quantShift = 3'd3;
		endcase
	end
end

always_comb begin	
	case(next_zz_counter[5:3])
		3'd0: begin
			if(Jump_offset == 9'd320) begin
				next_SRAM_write_counter = next_zz_counter[2:0];
			end else begin
				next_SRAM_write_counter = next_zz_counter[2:0];
			end
		end
		
		3'd1: begin
			if(Jump_offset == 9'd320) begin
				next_SRAM_write_counter = 9'd320 + next_zz_counter[2:0];
			end else begin
				next_SRAM_write_counter = 8'd160 + next_zz_counter[2:0];
			end
		end
		
		3'd2: begin
			if(Jump_offset == 9'd320) begin
				next_SRAM_write_counter = 10'd640 + next_zz_counter[2:0];
			end else begin
				next_SRAM_write_counter = 9'd320 + next_zz_counter[2:0];
			end
		end
		
		3'd3: begin
			if(Jump_offset == 9'd320) begin
				next_SRAM_write_counter = 10'd960 + next_zz_counter[2:0];
			end else begin
				next_SRAM_write_counter = 9'd480 + next_zz_counter[2:0];
			end
		end
		
		3'd4: begin
			if(Jump_offset == 9'd320) begin
				next_SRAM_write_counter = 11'd1280 + next_zz_counter[2:0];
			end else begin
				next_SRAM_write_counter = 10'd640 + next_zz_counter[2:0];
			end
		end
		
		3'd5: begin
			if(Jump_offset == 9'd320) begin
				next_SRAM_write_counter = 11'd1600 + next_zz_counter[2:0];
			end else begin
				next_SRAM_write_counter = 10'd800 + next_zz_counter[2:0];
			end
		end
		
		3'd6: begin
			if(Jump_offset == 9'd320) begin
				next_SRAM_write_counter = 11'd1920 + next_zz_counter[2:0];
			end else begin
				next_SRAM_write_counter = 10'd960 + next_zz_counter[2:0];
			end
		end
		
		3'd7: begin
			if(Jump_offset == 9'd320) begin
				next_SRAM_write_counter = 12'd2240 + next_zz_counter[2:0];
			end else begin
				next_SRAM_write_counter = 11'd1120 + next_zz_counter[2:0];
			end
		end
		
		default: next_SRAM_write_counter = 1'd0;
	endcase
end

always_comb begin
	case (bitstream_buff[31:30])
		2'b00: begin // 3 bit # x2
			shiftAmount = 4'd8;
			if(bitstream_buff[29]) begin
				SRAM_write = {bitstream_buff[29], 13'd8191, bitstream_buff[28:27]};
				DPRAM_write = {bitstream_buff[29], 29'h1FFFFFFF, bitstream_buff[28:27]};
			end else begin
				SRAM_write = {bitstream_buff[29], 13'd0, bitstream_buff[28:27]};
				DPRAM_write = {bitstream_buff[29], 29'd0, bitstream_buff[28:27]};
			end
			nextState = S_WRITE_3BIT;
		end
			
		2'b01: begin // 3 bit #
			shiftAmount = 4'd5;
			if(bitstream_buff[29]) begin
				SRAM_write = {bitstream_buff[29], 13'd8191, bitstream_buff[28:27]};
				DPRAM_write = {bitstream_buff[29], 29'h1FFFFFFF, bitstream_buff[28:27]};
			end else begin
				SRAM_write = {bitstream_buff[29], 13'd0, bitstream_buff[28:27]};
				DPRAM_write = {bitstream_buff[29], 29'd0, bitstream_buff[28:27]};
			end
			nextState = S_REST;
		end
		
		2'b10: begin
			if(!bitstream_buff[29]) begin // 6 bit #
				shiftAmount = 4'd9;
				if(bitstream_buff[28]) begin
					SRAM_write = {bitstream_buff[28], 10'h3FF, bitstream_buff[27 -:5]};
					DPRAM_write = {bitstream_buff[28], 26'h3FFFFFF, bitstream_buff[27 -:5]};
				end else begin
					SRAM_write = {bitstream_buff[28], 10'd0, bitstream_buff[27 -:5]};
					DPRAM_write = {bitstream_buff[28], 26'd0, bitstream_buff[27 -:5]};
				end
				nextState = S_REST;
			end else begin
				if(!bitstream_buff[28]) begin // zeros to end of block
					shiftAmount = 4'd4;
					SRAM_write = 16'd0;
					DPRAM_write = 32'd0;
					nextState = S_ALL_ZERO;
				end else begin // 9 bit #
					shiftAmount = 4'd13;
					if(bitstream_buff[27]) begin
						SRAM_write = {bitstream_buff[27], 7'h7F, bitstream_buff[26 -:8]};
						DPRAM_write = {bitstream_buff[27], 23'h7FFFFF, bitstream_buff[26 -:8]};
					end else begin
						SRAM_write = {bitstream_buff[27], 7'd0, bitstream_buff[26 -:8]};
						DPRAM_write = {bitstream_buff[27], 23'd0, bitstream_buff[26 -:8]};
					end				
					nextState = S_REST;
				end
			end
		end
		
		2'b11: begin
			shiftAmount = 4'd5;
			SRAM_write = 16'd0;
			DPRAM_write = 32'd0;
			nextState = S_ZERO_RUN;
		end

		default: begin
			shiftAmount = 4'd0;
			SRAM_write = 16'd0;
			DPRAM_write = 32'd0;
			nextState = S_IDLE;
		end
	endcase
end

always_ff @(posedge CLOCK_50 or negedge Resetn) begin
	if (~Resetn) begin
		Done <= 1'b0;
		dataEnd <= 5'd0;
		bitstream_buff <= 32'd0;
		SRAM_read_buff <= 16'd0;
		SRAM_read_counter <= 18'd0;
		zz_counter <= 6'd63;
		leadInFlag <= 1'b1;
		readFlag <= 1'b0;
		bufferFlag <= 1'b0;
		quant <= 1'b0;
		SRAM_we_n <= 1'b1;
		SRAM_write_data <= 16'd0;
		state <= S_IDLE;
		decodeDone <= 1'b0;
		
		M3FS_state <= S_M3FS_IDLE;
		DPRAM4_counter <= 6'd0;
		SP_DPRAM_counter <= 5'd0;
		DPRAM4_buffer <= 16'd0;
		wren_SP_a <= 1'b0;
		write_data_SP_a <= 32'd0;
	end else begin
		case (state) 
			S_IDLE: begin
				Done <= 1'b0;
				if(Start && ~Done && ~decodeDone) begin
					if (leadInFlag) begin // first block of 64 numbers in an image
						SRAM_address <= MIC18_BASE_ADR + Q_offset; // quant bits
						state <= S_LEAD_IN_0;
					end else begin
						SRAM_address <= MIC18_BASE_ADR + D_offset + SRAM_read_counter;
						state <= S_PROCESS_HEADER; // any other set of 64 numbers
					end
				end
			end
			
			S_LEAD_IN_0: begin 
					SRAM_address <= MIC18_BASE_ADR + D_offset + SRAM_read_counter; // call data location (d0)
					SRAM_read_counter <= SRAM_read_counter + 1'd1;
					state <= S_LEAD_IN_1;
			end
			
			S_LEAD_IN_1: begin 
				SRAM_address <= MIC18_BASE_ADR + D_offset + SRAM_read_counter; // call data location (d1)
				SRAM_read_counter <= SRAM_read_counter + 1'd1;
				state <= S_LEAD_IN_2;
			end
			
			S_LEAD_IN_2: begin // received quant
				quant <= SRAM_read_data[15];
				
				state <= S_LEAD_IN_3;
			end
			
			S_LEAD_IN_3: begin // received d0
			
				SRAM_address <= MIC18_BASE_ADR + D_offset + SRAM_read_counter; // call data location (d2)
				
				bitstream_buff[31:16] <= SRAM_read_data;
				dataEnd <= 5'd16;	
				
				state <= S_PROCESS_HEADER;
			end
			
			S_PROCESS_HEADER: begin
				bitstream_buff <= bitstream_buff << shiftAmount;
				dataEnd <= dataEnd + shiftAmount;
				
				if(leadInFlag) begin // happens one time
					leadInFlag <= 1'd0;
					bitstream_buff[dataEnd+shiftAmount-1 -:16] <= SRAM_read_data; // load in d1
					SRAM_read_counter <= SRAM_read_counter + 1'd1; // point to d3
					dataEnd <= dataEnd + shiftAmount - 5'd16;
					readFlag <= 1'b1;
					if(nextState == S_REST) begin // one write
						state <= S_DELAY_1;
					end else
						state <= nextState; // multi writes
				end else if(dataEnd + shiftAmount > 5'd15) begin
					bitstream_buff[dataEnd+shiftAmount-1 -:16] <= SRAM_read_buff; // load in d[n+1]
					SRAM_read_counter <= SRAM_read_counter + 1'd1; // point to d[n+2]
					dataEnd <= dataEnd + shiftAmount - 5'd16;
					readFlag <= 1'b1;
					if(nextState == S_REST) begin // one write
						state <= S_DELAY_1;
					end else
						state <= nextState; // multi writes
				end else begin
					state <= nextState;
				end
				
				SRAM_address <= Base_address + next_SRAM_write_counter;
				SRAM_write_data <= ($signed(SRAM_write) <<< quantShift);
				SRAM_we_n <= 1'd0;
				
				address_M3 <= next_zz_counter;
				write_data_M3 <= ($signed(DPRAM_write) <<< quantShift);
				wren_M3 <= 1'd1;
				zz_counter <= next_zz_counter;
				
				
				if(nextState == S_WRITE_3BIT) begin
					multiWriteInput <= bitstream_buff[26 -:3]; // pass the value to be written
				end else if (nextState == S_ZERO_RUN) begin
					multiWriteInput <= bitstream_buff[29 -:3] - 1'b1; // pass the number of 0s left to write
				end
			end

			S_DELAY_1: begin
				SRAM_we_n <= 1'd1;
				wren_M3 <= 1'b0;
				
				state <= S_DELAY_2;
			end
			
			S_DELAY_2: begin
				readFlag <= 1'b0;
				
				SRAM_we_n <= 1'd1;
				wren_M3 <= 1'b0;
				
				SRAM_read_buff <= SRAM_read_data; // load d[n+1] into buffer, d[n] in bitstream currently 
				
				SRAM_address <= MIC18_BASE_ADR + D_offset + SRAM_read_counter; // call d[n+2], d[n] in bitstream currently 
				
				if(next_zz_counter == 6'd0) begin // last write of 64 just happend 
					decodeDone <= 1'b1;
					state <= S_IDLE;
				end else begin
					state <= S_PROCESS_HEADER;
				end
			end
			
			S_REST: begin
				SRAM_we_n <= 1'd1;
				wren_M3 <= 1'b0;
				
				SRAM_address <= MIC18_BASE_ADR + D_offset + SRAM_read_counter; // call d[n+2], d[n] in bitstream currently 
				
				if(next_zz_counter == 6'd0) begin // last write of 64 just happend 
					decodeDone <= 1'b1;	
					state <= S_IDLE;
				end else begin
					state <= S_PROCESS_HEADER;
				end
			end
			
			S_WRITE_3BIT: begin
				if(multiWriteInput[2]) begin
					SRAM_write_data = ($signed({multiWriteInput[2], 13'd8191, multiWriteInput[1:0]}) <<< quantShift);
					write_data_M3 = ($signed({multiWriteInput[2], 29'h1FFFFFFF, multiWriteInput[1:0]}) <<< quantShift);
				end else begin
					SRAM_write_data = ($signed({multiWriteInput[2], 13'd0, multiWriteInput[1:0]}) <<< quantShift);
					write_data_M3 = ($signed({multiWriteInput[2], 29'd0, multiWriteInput[1:0]}) <<< quantShift);
				end
				
				SRAM_address <= Base_address + next_SRAM_write_counter;
				SRAM_we_n <= 1'd0;
				
				address_M3 <= next_zz_counter;
				wren_M3 <= 1'd1;
				zz_counter <= next_zz_counter;
				
				
				if(readFlag) begin
					state <= S_DELAY_2;
				end else begin
					state <= S_REST;
				end
			end
			
			S_ZERO_RUN: begin
				multiWriteInput <= multiWriteInput - 1'b1;
				SRAM_write_data = 16'd0;
				write_data_M3 = 32'd0;
				
				SRAM_address <= Base_address + next_SRAM_write_counter;
				SRAM_we_n <= 1'd0;
				
				address_M3 <= next_zz_counter;
				wren_M3 <= 1'd1;
				zz_counter <= next_zz_counter;
				
				if((readFlag) && (multiWriteInput > 3'd1)) begin
					bufferFlag <= 1'b1;
				end 
				if (bufferFlag) begin
					readFlag <= 1'b0;
					bufferFlag <= 1'b0;
					SRAM_read_buff <= SRAM_read_data;					
				end
				
				if(multiWriteInput == 3'd0) begin // only write a single 0
					SRAM_we_n <= 1'd1;
					wren_M3 <= 1'b0;
					address_M3 <= address_M3;
					zz_counter <= zz_counter;
					if(readFlag) begin
						state <= S_DELAY_2;
					end else begin
						state <= S_REST;
					end
				end else if (multiWriteInput == 3'd1) begin // currently writing last 0, more than 1 written in total
					if(readFlag && ~bufferFlag) begin
						state <= S_DELAY_2;
					end else begin
						state <= S_REST;
					end
				end else begin
					state <= S_ZERO_RUN;
				end
			end
			
			S_ALL_ZERO: begin
				SRAM_write_data <= 16'd0;
				write_data_M3 <= 32'd0;
				
				SRAM_address <= Base_address + next_SRAM_write_counter;
				SRAM_we_n <= 1'd0;
				
				address_M3 <= next_zz_counter;
				wren_M3 <= 1'd1;
				zz_counter <= next_zz_counter;
				
				if ((readFlag) && ~((next_zz_counter == 6'd0) || (next_zz_counter == 6'd63))) begin
					bufferFlag <= 1'b1;
				end  
				if (bufferFlag) begin
					readFlag <= 1'b0;
					bufferFlag <= 1'b0;
					SRAM_read_buff <= SRAM_read_data;					
				end
				
				if (next_zz_counter == 6'd0) begin // only writing a single 0
					SRAM_we_n <= 1'd1;
					wren_M3 <= 1'b0;
					
					SRAM_address <= SRAM_address;
					address_M3 <= address_M3;
					zz_counter <= zz_counter;
					if (readFlag) begin
						state <= S_DELAY_2;
					end else begin
						state <= S_REST;
					end
				end else if (next_zz_counter == 6'd63) begin // last write
					if (readFlag && ~bufferFlag) begin
						state <= S_DELAY_2;
					end else begin
						state <= S_REST;
					end
				end else begin
					state <= S_ALL_ZERO;
				end
			end
			
			default: state <= S_IDLE;
		endcase
		
		case (M3FS_state)
			S_M3FS_IDLE: begin
				wren_SP_a <= 1'd0;
				if(next_zz_counter == 6'd37) begin
					address_M3_b <= DPRAM4_counter; // extracts 1 value
					DPRAM4_counter <= DPRAM4_counter + 1'd1;
					M3FS_state <= S_M3FS_LEAD_IN_0;
				end
			end
			
			S_M3FS_LEAD_IN_0: begin
				address_M3_b <= DPRAM4_counter; 
				DPRAM4_counter <= DPRAM4_counter + 1;
				
				M3FS_state <= S_M3FS_LEAD_IN_1;
			end
			
			S_M3FS_LEAD_IN_1: begin
				address_M3_b <= DPRAM4_counter; 
				DPRAM4_counter <= DPRAM4_counter + 1'd1;
				DPRAM4_buffer <= {read_data_M3_b[31], read_data_M3_b[14:0]};
				
				M3FS_state <= S_M3FS_READ_ODD;
			end
			
			S_M3FS_READ_ODD: begin
				address_M3_b <= DPRAM4_counter; 
				DPRAM4_counter <= DPRAM4_counter + 1'd1;
				
				address_SP_a <= SP_DPRAM_counter;
				SP_DPRAM_counter <= SP_DPRAM_counter + 1'd1;
				write_data_SP_a <= {DPRAM4_buffer,({read_data_M3_b[31], read_data_M3_b[14:0]})};
				wren_SP_a <= 1'd1;
				
				M3FS_state <= S_M3FS_READ_EVEN;
			end
			
			S_M3FS_READ_EVEN: begin
				address_M3_b <= DPRAM4_counter; 
				DPRAM4_counter <= DPRAM4_counter + 1;
				
				DPRAM4_buffer <= {read_data_M3_b[31], read_data_M3_b[14:0]};
				wren_SP_a <= 1'd0;
				
				M3FS_state <= S_M3FS_READ_ODD;
				
				if(DPRAM4_counter == 6'd0) begin
					M3FS_state <= S_M3FS_LEAD_OUT_0;
				end

			end
			
			S_M3FS_LEAD_OUT_0: begin
					write_data_SP_a <= {DPRAM4_buffer,({read_data_M3_b[31], read_data_M3_b[14:0]})};
					wren_SP_a <= 1'd1;
					address_SP_a <= SP_DPRAM_counter;
					
					DPRAM4_counter <= 6'd0;
					SP_DPRAM_counter <= 5'd0;
					decodeDone <= 1'b0;
					M3FS_state <= S_M3FS_IDLE;
					Done <= 1'b1;
					
					if (Base_address == DCT_V_BASE_ADR + 18'd37120 + 18'd152) begin // last block of 64 top left address = DCT_V_base_adr + 160*232 + 152
						dataEnd <= 5'd0;
						bitstream_buff <= 32'd0;
						SRAM_read_buff <= 16'd0;
						SRAM_read_counter <= 18'd0;
						zz_counter <= 6'd63;
						leadInFlag <= 1'b1;
						readFlag <= 1'b0;
						bufferFlag <= 1'b0;
						quant <= 1'b0;
					end
			end
			
			default: M3FS_state <= S_M3FS_IDLE;
		endcase
		
	end
end
endmodule
