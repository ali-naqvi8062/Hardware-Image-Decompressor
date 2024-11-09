`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"
`include "M1_param.h"

// Performs milestone 1 of the project (upsampling and colourspace conversion)
module upsample_plus_csc (

		input logic 			CLOCK_50, 
		input logic				Resetn, 
		input logic [15:0] 	SRAM_read_data,
		input logic 			Start,
		
		output logic [17:0]	SRAM_address,
		output logic [15:0]	SRAM_write_data,
		output logic 			SRAM_we_n,	
		output logic			Done
		
		
);

logic [1:0] lead_out_cycle;
logic [7:0] V_temp, U_temp, R_write, G_write, B_write, RGB_temp_write, lead_out_counter;
logic [15:0] Y_Reg, Y_temp;
logic [31:0] R_Reg, G_Reg, B_Reg, RGB_temp, V_Prime, U_Prime, M1, M2, M3, M1_op1, M1_op2, M2_op1, M2_op2, M3_op1, M3_op2;
logic [47:0] V_Shift, U_Shift;
logic [17:0] Y_Counter, UV_Counter, RGB_Counter;
logic [63:0] M1_long, M2_long, M3_long;
logic UV_Read_Cycle;

enum logic [1:0]{
	EVEN_PAIR,
	COMB_PAIR,
	ODD_PAIR
}RGB_select;

M1_state_type state;

assign M1_long = M1_op1*M1_op2;
assign M2_long = M2_op1*M2_op2;
assign M3_long = M3_op1*M3_op2;

assign M1 = M1_long[31:0];
assign M2 = M2_long[31:0];
assign M3 = M3_long[31:0];

always_comb begin
	if(R_Reg[31] == 1'b1) begin
		R_write = 8'd0;
	end else if (|R_Reg[31:8]) begin
		R_write = 8'd255;
	end else begin
		R_write = R_Reg[7:0];
	end

	if(G_Reg[31] == 1'b1) begin
		G_write = 8'd0;
	end else if (|G_Reg[31:8]) begin
		G_write = 8'd255;
	end else begin
		G_write = G_Reg[7:0];
	end
	
	if(B_Reg[31] == 1'b1) begin
		B_write = 8'd0;
	end else if (|B_Reg[31:8]) begin
		B_write = 8'd255;
	end else begin
		B_write = B_Reg[7:0];
	end
	
	if(RGB_temp[31] == 1'b1) begin
		RGB_temp_write = 8'd0;
	end else if (|RGB_temp[31:8]) begin
		RGB_temp_write = 8'd255;
	end else begin
		RGB_temp_write = RGB_temp[7:0];
	end
	
	case (RGB_select)
	
	EVEN_PAIR: begin
		SRAM_write_data = {R_write,G_write};
	end
	
	COMB_PAIR: begin
		SRAM_write_data = {RGB_temp_write,R_write};
	end
	
	ODD_PAIR: begin
		SRAM_write_data = {G_write,B_write};
	end
	endcase
end

always_ff @(posedge CLOCK_50 or negedge Resetn) begin
	if(~Resetn) begin
		R_Reg <= 32'd0;
		G_Reg <= 32'd0;
		B_Reg <= 32'd0;
		RGB_temp <= 32'd0;
		V_temp <= 8'd0;
		lead_out_counter <= 8'd0;
		lead_out_cycle <= 2'd0;
		U_temp <= 8'd0;
		Y_Reg <= 16'd0;
		Y_temp <= 16'd0;
		V_Prime <= 32'd0;
		U_Prime <= 32'd0;
		V_Shift <= 48'd0;
		U_Shift <= 48'd0;
		
		SRAM_address <= 18'd0;
		SRAM_we_n <= 1'b1;
		Done <= 1'b0;
		
		Y_Counter <= 18'd0;
		UV_Counter <= 18'd0;
		RGB_Counter <= 18'd0;
		
		RGB_select <= EVEN_PAIR;
		
		UV_Read_Cycle <= 1'b0;
	end else begin
		case (state)
			S_M1_IDLE: begin
				SRAM_we_n <= 1'b1;
				if(Start) begin
					SRAM_address <= Y_BASE_ADR+Y_Counter;
					Y_Counter <= Y_Counter + 1'd1;
					lead_out_counter <= lead_out_counter + 1'd1;
					state <= S_LEAD_IN_0;
				end
			end
			
			S_LEAD_IN_0: begin
				SRAM_address <= V_BASE_ADR+UV_Counter;
				
				state <= S_LEAD_IN_1;
			end
			
			S_LEAD_IN_1: begin
				SRAM_address <= U_BASE_ADR+UV_Counter;
				UV_Counter <= UV_Counter + 1'd1;
				
				state <= S_LEAD_IN_2;
			end
			
			S_LEAD_IN_2: begin
				SRAM_address <= V_BASE_ADR+UV_Counter;
				
				Y_Reg <= SRAM_read_data;	
								
				state <= S_LEAD_IN_3;
			end
			
			S_LEAD_IN_3: begin
				SRAM_address <= U_BASE_ADR+UV_Counter;
				UV_Counter <= UV_Counter + 1'd1;
				
				V_Shift[47:40] <= SRAM_read_data[15:8];
			   V_Shift[39:32] <= SRAM_read_data[15:8];	
				V_Shift[31:24] <= SRAM_read_data[15:8];
				V_Shift[23:16] <= SRAM_read_data[15:8];
				V_Shift[15:8] <= SRAM_read_data[15:8];
				V_Shift[7:0] <= SRAM_read_data[7:0];
				
				M1_op1 <= {24'd0,Y_Reg[15:8]}-RGB_SUB_C0;
				M1_op2 <= RGB_MATRIX_A;
				
				state <= S_LEAD_IN_4;
			end
			
			S_LEAD_IN_4: begin
				SRAM_address <= Y_BASE_ADR+Y_Counter;
				Y_Counter <= Y_Counter + 1'd1;
				lead_out_counter <= lead_out_counter + 1'd1;
				
				U_Shift[47:40] <= SRAM_read_data[15:8];
			   U_Shift[39:32] <= SRAM_read_data[15:8];	
				U_Shift[31:24] <= SRAM_read_data[15:8];
				U_Shift[23:16] <= SRAM_read_data[15:8];
				U_Shift[15:8] <= SRAM_read_data[15:8];
				U_Shift[7:0] <= SRAM_read_data[7:0];
				
				R_Reg <= M1;
				G_Reg <= M1;
				B_Reg <= M1;
				
				V_Prime <= UV_PRIME_C0;
				
				M1_op1 <= {24'd0,V_Shift[15:8]}-RGB_SUB_C1;
				M1_op2 <= RGB_MATRIX_B;
				
				M2_op1 <= {24'd0,V_Shift[15:8]}-RGB_SUB_C1;
				M2_op2 <= RGB_MATRIX_D;
				
				M3_op1 <= {24'd0,V_Shift[15:8]}+{24'd0,V_Shift[7:0]};
				M3_op2 <= UV_PRIME_C3;
					
				state <= S_LEAD_IN_5;
			end
			
			S_LEAD_IN_5: begin
				SRAM_address <= V_BASE_ADR+UV_Counter;
				
				V_Shift <= (V_Shift << 16);
				V_Shift[15:8] <= SRAM_read_data[15:8];
				V_Shift[7:0] <= SRAM_read_data[7:0];
								
				R_Reg <= ($signed(R_Reg + M1) >>> RGB_DIV_SHIFT);
				G_Reg <= G_Reg - M2;
				
				V_Prime <= V_Prime + M3;
				
				U_Prime <= UV_PRIME_C0;
				
				M1_op1 <= {24'd0,U_Shift[15:8]}-RGB_SUB_C1;
				M1_op2 <= RGB_MATRIX_C;
				
				M2_op1 <= {24'd0,U_Shift[15:8]}-RGB_SUB_C1;
				M2_op2 <= RGB_MATRIX_E;
				
				M3_op1 <= {24'd0,U_Shift[15:8]}+{24'd0,U_Shift[7:0]};
				M3_op2 <= UV_PRIME_C3;
					
				state <= S_LEAD_IN_6;
			end
			
			S_LEAD_IN_6: begin
				SRAM_address <= RGB_BASE_ADR+RGB_Counter;
				RGB_Counter <= RGB_Counter + 1'd1;			
				SRAM_we_n <= 1'b0;
				RGB_select <= EVEN_PAIR;
				
				U_Shift <= (U_Shift << 16);
				U_Shift[15:8] <= SRAM_read_data[15:8];
				U_Shift[7:0] <= SRAM_read_data[7:0];
								
				G_Reg <= ($signed(G_Reg - M1) >>> RGB_DIV_SHIFT);
				B_Reg <= ($signed(B_Reg + M2) >>> RGB_DIV_SHIFT);
				
				U_Prime <= U_Prime + M3;
				
				M1_op1 <= {24'd0,V_Shift[39:32]}+{24'd0,V_Shift[15:8]};
				M1_op2 <= UV_PRIME_C2;
				
				M2_op1 <= {24'd0,V_Shift[47:40]}+{24'd0,V_Shift[7:0]};
				M2_op2 <= UV_PRIME_C1;
				
				M3_op1 <= {24'd0,Y_Reg[7:0]}-RGB_SUB_C0;
				M3_op2 <= RGB_MATRIX_A;
						
				state <= S_LEAD_IN_7;
			end
			
			S_LEAD_IN_7: begin
				SRAM_address <= U_BASE_ADR+UV_Counter;
				UV_Counter <= UV_Counter + 1'd1;
				SRAM_we_n <= 1'b1;
				
				Y_temp = SRAM_read_data;
				
				R_Reg <= M3;
				G_Reg <= M3;
				B_Reg <= M3;
				RGB_temp <= B_Reg;
				
				V_Prime <= ($signed(V_Prime - M1 + M2) >>> UV_PRIME_DIV_SHIFT);
								
				M1_op1 <= {24'd0,U_Shift[39:32]}+{24'd0,U_Shift[15:8]};
				M1_op2 <= UV_PRIME_C2;
				
				M2_op1 <= {24'd0,U_Shift[47:40]}+{24'd0,U_Shift[7:0]};
				M2_op2 <= UV_PRIME_C1;			
					
				state <= S_LEAD_IN_8;
			end
			
			S_LEAD_IN_8: begin			
				V_Shift <= (V_Shift << 8);
				V_Shift[7:0] <= SRAM_read_data[15:8];
				V_temp <= SRAM_read_data[7:0];
							
				U_Prime <= ($signed(U_Prime + M2 - M1) >>> UV_PRIME_DIV_SHIFT);
				
				M3_op1 <= V_Prime - RGB_SUB_C1;
				M3_op2 <= RGB_MATRIX_B;		
					
				state <= S_LEAD_IN_9;
			end
			
			S_LEAD_IN_9: begin
				SRAM_address <= RGB_BASE_ADR+RGB_Counter;
				RGB_Counter <= RGB_Counter + 1'd1;			
				SRAM_we_n <= 1'b0;
				RGB_select <= COMB_PAIR;
				
				Y_Reg <= Y_temp;
				
				R_Reg <= ($signed(R_Reg + M3) >>> RGB_DIV_SHIFT);
								
				M1_op1 <= V_Prime - RGB_SUB_C1;
				M1_op2 <= RGB_MATRIX_D;
				
				M2_op1 <= U_Prime - RGB_SUB_C1;
				M2_op2 <= RGB_MATRIX_C;
				
				M3_op1 <= U_Prime - RGB_SUB_C1;
				M3_op2 <= RGB_MATRIX_E;
						
				state <= S_LEAD_IN_10;
			end
			
			S_LEAD_IN_10: begin
				SRAM_address <= RGB_BASE_ADR+RGB_Counter;
				RGB_Counter <= RGB_Counter + 1'd1;			
				RGB_select <= ODD_PAIR;
				
				U_Shift <= (U_Shift << 8);
				U_Shift[7:0] <= SRAM_read_data[15:8];
				U_temp <= SRAM_read_data[7:0];
	
				G_Reg <= ($signed(G_Reg - M2 - M1) >>> RGB_DIV_SHIFT);
				B_Reg <= ($signed(B_Reg + M3) >>> RGB_DIV_SHIFT);
								
				M1_op1 <= {24'd0,Y_Reg[15:8]}-RGB_SUB_C0;
				M1_op2 <= RGB_MATRIX_A;		
				
				UV_Read_Cycle <= 1'b0;
				
				state <= S_COMMON_STATE_0;
			end
			
			S_COMMON_STATE_0: begin
				SRAM_address <= Y_BASE_ADR+Y_Counter;
				Y_Counter <= Y_Counter + 1'd1;
				lead_out_counter <= lead_out_counter + 1'd1;
				SRAM_we_n <= 1'b1;
							
				R_Reg <= M1;
				G_Reg <= M1;
				B_Reg <= M1;
				
				V_Prime <= UV_PRIME_C0;
	
				M1_op1 <= {24'd0,V_Shift[31:24]}-RGB_SUB_C1;
				M1_op2 <= RGB_MATRIX_B;		
				
				M2_op1 <= {24'd0,V_Shift[31:24]}-RGB_SUB_C1;
				M2_op2 <= RGB_MATRIX_D;	
				
				M3_op1 <= {24'd0,V_Shift[47:40]}+{24'd0,V_Shift[7:0]};
				M3_op2 <= UV_PRIME_C1;	
		
				state <= S_COMMON_STATE_1;
			end
			
			S_COMMON_STATE_1: begin							
				if (UV_Read_Cycle) begin
					SRAM_address <= V_BASE_ADR+UV_Counter;
				end
				
				R_Reg <= ($signed(R_Reg + M1) >>> RGB_DIV_SHIFT);
				G_Reg <= G_Reg - M2;
				
				V_Prime <= V_Prime + M3;				
				U_Prime <= UV_PRIME_C0;
	
				M1_op1 <= {24'd0,U_Shift[31:24]}-RGB_SUB_C1;
				M1_op2 <= RGB_MATRIX_C;		
				
				M2_op1 <= {24'd0,U_Shift[31:24]}-RGB_SUB_C1;
				M2_op2 <= RGB_MATRIX_E;	
				
				M3_op1 <= {24'd0,U_Shift[47:40]}+{24'd0,U_Shift[7:0]};
				M3_op2 <= UV_PRIME_C1;	
		
				state <= S_COMMON_STATE_2;
			end
			
			S_COMMON_STATE_2: begin
				SRAM_address <= RGB_BASE_ADR+RGB_Counter;
				RGB_Counter <= RGB_Counter + 1'd1;			
				SRAM_we_n <= 1'b0;
				RGB_select <= EVEN_PAIR;
							
				G_Reg <= ($signed(G_Reg - M1) >>> RGB_DIV_SHIFT);
				B_Reg <= ($signed(B_Reg + M2) >>> RGB_DIV_SHIFT);
				
				U_Prime <= U_Prime + M3;
	
				M1_op1 <= {24'd0,V_Shift[39:32]}+{24'd0,V_Shift[15:8]};
				M1_op2 <= UV_PRIME_C2;		
				
				M2_op1 <= {24'd0,V_Shift[31:24]}+{24'd0,V_Shift[23:16]};
				M2_op2 <= UV_PRIME_C3;	
				
				M3_op1 <= {24'd0,U_Shift[39:32]}+{24'd0,U_Shift[15:8]};
				M3_op2 <= UV_PRIME_C2;	
		
				state <= S_COMMON_STATE_3;
			end
			
			S_COMMON_STATE_3: begin							
				if (UV_Read_Cycle) begin
					SRAM_address <= U_BASE_ADR+UV_Counter;
					UV_Counter <= UV_Counter + 1'd1;
				end
				SRAM_we_n <= 1'b1;
				
				Y_temp <= SRAM_read_data;
								
				RGB_temp <= B_Reg;
				
				V_Prime <= ($signed(V_Prime - M1 + M2) >>> UV_PRIME_DIV_SHIFT);
				U_Prime <= U_Prime - M3;
				
				M1_op1 <= {24'd0,Y_Reg[7:0]}-RGB_SUB_C0;
				M1_op2 <= RGB_MATRIX_A;
				
				M2_op1 <= {24'd0,U_Shift[31:24]}+{24'd0,U_Shift[23:16]};
				M2_op2 <= UV_PRIME_C3;			
					
				state <= S_COMMON_STATE_4;
			end
			
			S_COMMON_STATE_4: begin
				V_Shift <= (V_Shift << 8);			
				if (UV_Read_Cycle) begin
					V_Shift[7:0] <= SRAM_read_data[15:8];
					V_temp <= SRAM_read_data[7:0];
				end else begin
					V_Shift[7:0] <= V_temp;
				end
				
				R_Reg <= M1;
				G_Reg <= M1;
				B_Reg <= M1;
				
				U_Prime <= ($signed(U_Prime + M2) >>> UV_PRIME_DIV_SHIFT);
				
				M3_op1 <= V_Prime - RGB_SUB_C1;
				M3_op2 <= RGB_MATRIX_B;		
					
				state <= S_COMMON_STATE_5;
			end
			
			S_COMMON_STATE_5: begin
				SRAM_address <= RGB_BASE_ADR+RGB_Counter;
				RGB_Counter <= RGB_Counter + 1'd1;			
				SRAM_we_n <= 1'b0;
				RGB_select <= COMB_PAIR;
				
				Y_Reg <= Y_temp;
				
				R_Reg <= ($signed(R_Reg + M3) >>> RGB_DIV_SHIFT);
								
				M1_op1 <= V_Prime - RGB_SUB_C1;
				M1_op2 <= RGB_MATRIX_D;
				
				M2_op1 <= U_Prime - RGB_SUB_C1;
				M2_op2 <= RGB_MATRIX_C;
				
				M3_op1 <= U_Prime - RGB_SUB_C1;
				M3_op2 <= RGB_MATRIX_E;		
					
				state <= S_COMMON_STATE_6;
			end
			
			S_COMMON_STATE_6: begin
				SRAM_address <= RGB_BASE_ADR+RGB_Counter;
				RGB_Counter <= RGB_Counter + 1'd1;			
				RGB_select <= ODD_PAIR;
				
				U_Shift <= (U_Shift << 8);			
				if (UV_Read_Cycle) begin
					U_Shift[7:0] <= SRAM_read_data[15:8];
					U_temp <= SRAM_read_data[7:0];
				end else begin
					U_Shift[7:0] <= U_temp;
				end
				
				G_Reg <= ($signed(G_Reg - M2 - M1) >>> RGB_DIV_SHIFT);
				B_Reg <= ($signed(B_Reg + M3) >>> RGB_DIV_SHIFT);
								
				M1_op1 <= {24'd0,Y_Reg[15:8]}-RGB_SUB_C0;
				M1_op2 <= RGB_MATRIX_A;		
				
				UV_Read_Cycle <= 	~UV_Read_Cycle;
				
				if(lead_out_counter == 8'd158) begin
					lead_out_counter <= 8'd0;
					state <= S_LEAD_OUT_0;
				end
				else begin
					state <= S_COMMON_STATE_0;
				end
			end
			
			S_LEAD_OUT_0: begin
				SRAM_address <= Y_BASE_ADR+Y_Counter;
				Y_Counter <= Y_Counter + 1'd1;
				SRAM_we_n <= 1'b1;
							
				R_Reg <= M1;
				G_Reg <= M1;
				B_Reg <= M1;
				
				V_Prime <= UV_PRIME_C0;
				
				if(lead_out_cycle == 3'd0) begin // SHIFT REG: (155,156,157,158,159,160(is actually 159))
					M1_op1 <= {24'd0,V_Shift[31:24]}-RGB_SUB_C1;
					M1_op2 <= RGB_MATRIX_B;		
				
					M2_op1 <= {24'd0,V_Shift[31:24]}-RGB_SUB_C1;
					M2_op2 <= RGB_MATRIX_D;	
				
					M3_op1 <= {24'd0,V_Shift[47:40]}+{24'd0,V_Shift[15:8]}; //155 + 160 (159)
					M3_op2 <= UV_PRIME_C1;	
				end else if(lead_out_cycle == 3'd1) begin
					M1_op1 <= {24'd0,V_Shift[23:16]}-RGB_SUB_C1;
					M1_op2 <= RGB_MATRIX_B;		
				
					M2_op1 <= {24'd0,V_Shift[23:16]}-RGB_SUB_C1;
					M2_op2 <= RGB_MATRIX_D;	
				
					M3_op1 <= {24'd0,V_Shift[39:32]}+{24'd0,V_Shift[15:8]}; // 156 + 159
					M3_op2 <= UV_PRIME_C1;	
				end else begin
					M1_op1 <= {24'd0,V_Shift[15:8]}-RGB_SUB_C1;
					M1_op2 <= RGB_MATRIX_B;		
				
					M2_op1 <= {24'd0,V_Shift[15:8]}-RGB_SUB_C1;
					M2_op2 <= RGB_MATRIX_D;	
				
					M3_op1 <= {24'd0,V_Shift[31:24]}+{24'd0,V_Shift[15:8]};
					M3_op2 <= UV_PRIME_C1;	
				end

				state <= S_LEAD_OUT_1;	
			end
			S_LEAD_OUT_1: begin 
				R_Reg <= ($signed(R_Reg + M1) >>> RGB_DIV_SHIFT);
				G_Reg <= G_Reg - M2;
				
				V_Prime <= V_Prime + M3;				
				U_Prime <= UV_PRIME_C0;
	
				if(lead_out_cycle == 3'd0) begin // SHIFT REG: (155,156,157,158,159,160(is actually 159))
					M1_op1 <= {24'd0,U_Shift[31:24]}-RGB_SUB_C1;
					M1_op2 <= RGB_MATRIX_C;		
				
					M2_op1 <= {24'd0,U_Shift[31:24]}-RGB_SUB_C1;
					M2_op2 <= RGB_MATRIX_E;	
				
					M3_op1 <= {24'd0,U_Shift[47:40]}+{24'd0,U_Shift[15:8]}; 
					M3_op2 <= UV_PRIME_C1;	
				end else if(lead_out_cycle == 3'd1) begin
					M1_op1 <= {24'd0,U_Shift[23:16]}-RGB_SUB_C1;
					M1_op2 <= RGB_MATRIX_C;		
				
					M2_op1 <= {24'd0,U_Shift[23:16]}-RGB_SUB_C1;
					M2_op2 <= RGB_MATRIX_E;	
				
					M3_op1 <= {24'd0,U_Shift[39:32]}+{24'd0,U_Shift[15:8]}; 
					M3_op2 <= UV_PRIME_C1;	
				end else begin
					M1_op1 <= {24'd0,U_Shift[15:8]}-RGB_SUB_C1;
					M1_op2 <= RGB_MATRIX_C;		
				
					M2_op1 <= {24'd0,U_Shift[15:8]}-RGB_SUB_C1;
					M2_op2 <= RGB_MATRIX_E;	
				
					M3_op1 <= {24'd0,U_Shift[31:24]}+{24'd0,U_Shift[15:8]};
					M3_op2 <= UV_PRIME_C1;	
				end
				state <= S_LEAD_OUT_2;
			end
			
			S_LEAD_OUT_2: begin 
				SRAM_address <= RGB_BASE_ADR+RGB_Counter;
				RGB_Counter <= RGB_Counter + 1'd1;			
				SRAM_we_n <= 1'b0;
				RGB_select <= EVEN_PAIR;
							
				G_Reg <= ($signed(G_Reg - M1) >>> RGB_DIV_SHIFT);
				B_Reg <= ($signed(B_Reg + M2) >>> RGB_DIV_SHIFT);
				
				U_Prime <= U_Prime + M3;
	
				if(lead_out_cycle == 3'd0) begin // SHIFT REG: (155,156,157,158,159,160(is actually 159))
					M1_op1 <= {24'd0,V_Shift[39:32]}+{24'd0,V_Shift[15:8]};
					M1_op2 <= UV_PRIME_C2;		
				
					M2_op1 <= {24'd0,V_Shift[31:24]}+{24'd0,V_Shift[23:16]};
					M2_op2 <= UV_PRIME_C3;	
				
					M3_op1 <= {24'd0,U_Shift[39:32]}+{24'd0,U_Shift[15:8]};
					M3_op2 <= UV_PRIME_C2;	
				end else if(lead_out_cycle == 3'd1) begin // want 156,157,158,159,159,159 have 155,156,157,158,159,160
					M1_op1 <= {24'd0,V_Shift[31:24]}+{24'd0,V_Shift[15:8]};
					M1_op2 <= UV_PRIME_C2;		
				
					M2_op1 <= {24'd0,V_Shift[23:16]}+{24'd0,V_Shift[15:8]};
					M2_op2 <= UV_PRIME_C3;	
				
					M3_op1 <= {24'd0,U_Shift[31:24]}+{24'd0,U_Shift[15:8]};
					M3_op2 <= UV_PRIME_C2;	
				end else begin
					M1_op1 <= {24'd0,V_Shift[23:16]}+{24'd0,V_Shift[15:8]}; // want 157,158,159,159,159,159 have 155,156,157,158,159,160
					M1_op2 <= UV_PRIME_C2;		
				
					M2_op1 <= {24'd0,V_Shift[15:8]}+{24'd0,V_Shift[15:8]};
					M2_op2 <= UV_PRIME_C3;	
				
					M3_op1 <= {24'd0,U_Shift[23:16]}+{24'd0,U_Shift[15:8]};
					M3_op2 <= UV_PRIME_C2;	
				end
		
				state <= S_LEAD_OUT_3;
			end
			
			S_LEAD_OUT_3: begin 
				SRAM_we_n <= 1'b1;
				
				Y_temp <= SRAM_read_data;
								
				RGB_temp <= B_Reg;
				
				V_Prime <= ($signed(V_Prime - M1 + M2) >>> UV_PRIME_DIV_SHIFT);
				U_Prime <= U_Prime - M3;
				
				if(lead_out_cycle == 3'd0) begin // SHIFT REG: (155,156,157,158,159,160(is actually 159))
					M1_op1 <= {24'd0,Y_Reg[7:0]}-RGB_SUB_C0;
					M1_op2 <= RGB_MATRIX_A;
				
					M2_op1 <= {24'd0,U_Shift[31:24]}+{24'd0,U_Shift[23:16]};
					M2_op2 <= UV_PRIME_C3;	
				end else if(lead_out_cycle == 3'd1) begin // want 156,157,158,159,159,159 have 155,156,157,158,159,160
					M1_op1 <= {24'd0,Y_Reg[7:0]}-RGB_SUB_C0;
					M1_op2 <= RGB_MATRIX_A;
				
					M2_op1 <= {24'd0,U_Shift[23:16]}+{24'd0,U_Shift[15:8]};
					M2_op2 <= UV_PRIME_C3;	
				end else begin
					M1_op1 <= {24'd0,Y_Reg[7:0]}-RGB_SUB_C0; //// want 157,158,159,159,159,159 have 155,156,157,158,159,160
					M1_op2 <= RGB_MATRIX_A;
				
					M2_op1 <= {24'd0,U_Shift[15:8]}+{24'd0,U_Shift[15:8]};
					M2_op2 <= UV_PRIME_C3;	
				end

				state <= S_LEAD_OUT_4;
			end
			
			S_LEAD_OUT_4: begin 
				R_Reg <= M1;
				G_Reg <= M1;
				B_Reg <= M1;
				
				U_Prime <= ($signed(U_Prime + M2) >>> UV_PRIME_DIV_SHIFT);
				
				M3_op1 <= V_Prime - RGB_SUB_C1;
				M3_op2 <= RGB_MATRIX_B;	

				state <= S_LEAD_OUT_5;
			end
			
			S_LEAD_OUT_5: begin 
				SRAM_address <= RGB_BASE_ADR+RGB_Counter;
				RGB_Counter <= RGB_Counter + 1'd1;			
				SRAM_we_n <= 1'b0;
				RGB_select <= COMB_PAIR;
				
				Y_Reg <= Y_temp;
				
				R_Reg <= ($signed(R_Reg + M3) >>> RGB_DIV_SHIFT);
								
				M1_op1 <= V_Prime - RGB_SUB_C1;
				M1_op2 <= RGB_MATRIX_D;
				
				M2_op1 <= U_Prime - RGB_SUB_C1;
				M2_op2 <= RGB_MATRIX_C;
				
				M3_op1 <= U_Prime - RGB_SUB_C1;
				M3_op2 <= RGB_MATRIX_E;		
					
				state <= S_LEAD_OUT_6;
			end
			
			S_LEAD_OUT_6: begin 
				SRAM_address <= RGB_BASE_ADR+RGB_Counter;
				RGB_Counter <= RGB_Counter + 1'd1;			
				RGB_select <= ODD_PAIR;
				
				G_Reg <= ($signed(G_Reg - M2 - M1) >>> RGB_DIV_SHIFT);
				B_Reg <= ($signed(B_Reg + M3) >>> RGB_DIV_SHIFT);
								
				M1_op1 <= {24'd0,Y_Reg[15:8]}-RGB_SUB_C0;
				M1_op2 <= RGB_MATRIX_A;		
								
				lead_out_cycle <= lead_out_cycle + 1'd1;
				if(lead_out_cycle == 8'd2) begin
					lead_out_cycle <= 8'd0;
					Y_Counter <= Y_Counter - 1'd1;
					UV_Counter <= UV_Counter - 1'd1;
					state <= S_M1_IDLE;
				end else begin
					state <= S_LEAD_OUT_0;
				end	

				if(Y_Counter == U_BASE_ADR + 1'd1) begin
					Done <= 1'b1;
					Y_Counter <= 18'd0;
					UV_Counter <= 18'd0;
				end		
		
			end
			
			default: state <= S_M1_IDLE;
		endcase
	end
end

endmodule