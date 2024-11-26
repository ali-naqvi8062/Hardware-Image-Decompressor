/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"
`include "M2_param.h"
`include "M1_param.h" // for y u v base addresses


// Performs milestone 2 of the project (IDCT)
module milestone2 (

		input logic 			CLOCK_50, 
		input logic				Resetn, 
		input logic [15:0] 	SRAM_read_data,
		input logic 			Start,
		
		output logic [17:0]	SRAM_address,
		output logic [15:0]	SRAM_write_data,
		output logic 			SRAM_we_n,	
		output logic			Done
		
		
);

/* Multi bit signals for DP-RAMs*/
logic [6:0] address_C[1:0];
logic [6:0] address_SP[1:0];
logic [6:0] address_T[1:0];
logic [31:0] read_data_C[1:0];
logic [31:0] read_data_SP[1:0];
logic [31:0] read_data_T[1:0];
logic [31:0] write_data_SP[1:0];
logic wren_SP[1:0];

logic [31:0] write_data_T[1:0];
logic wren_T[1:0];

logic [6:0] address_M3[1:0];
logic [31:0] read_data_M3[1:0];
logic [31:0] write_data_M3[1:0];
logic wren_M3;


/*	M3 Signals */
logic M3_enable, M3_done, M3_SRAM_we_n, M3_wren_M3, M3_wren_SP_a;
logic [17:0] M3_SRAM_address, M3_Base_address;
logic [15:0] M3_SRAM_write_data;
logic [8:0] M3_Jump_offset;
logic [31:0] M3_write_data_M3, M3_read_data_M3, M3_write_data_SP;
logic [6:0] M3_address_M3, M3_address_M3_b, M3_address_SP;

/* FS Signals */
logic m2_fs_enable, m2_fs_done, FS_wren_SP; 
logic [17:0] FS_SRAM_address, FS_Base_address;
logic [8:0] FS_Jump_offset;
logic [6:0] FS_address_SP;
logic [31:0] FS_write_data_SP;

/* CT Signals */
logic m2_ct_enable, m2_ct_done, CT_wren_T;
logic [6:0] CT_address_T;
logic [6:0] CT_address_SP[1:0];
logic [6:0] CT_address_C[1:0];
logic [31:0] CT_write_data_T;
logic [31:0] CT_M1_ops[1:0];
logic [31:0] CT_M2_ops[1:0];
logic [31:0] CT_M3_ops[1:0];

/* CS Signals */
logic m2_cs_enable, m2_cs_done, CS_wren_T_b;
logic [6:0] CS_address_T[1:0];
logic [6:0] CS_address_C[1:0];
logic [31:0] CS_write_data_T_b;
logic [31:0] CS_M1_ops[1:0];
logic [31:0] CS_M2_ops[1:0];
logic [31:0] CS_M3_ops[1:0];

/* WR Signals */
logic m2_wr_enable, m2_wr_done, WR_SRAM_we_n;
logic [17:0] WR_SRAM_address, WR_Base_address;
logic [8:0] WR_Jump_offset;
logic [6:0] WR_address_T;
logic [15:0] WR_SRAM_write_data;

logic signed [31:0] M1, M2, M3, M1_op1, M1_op2, M2_op1, M2_op2, M3_op1, M3_op2;

logic signed [63:0] M1_long, M2_long, M3_long;

assign M1_long = M1_op1*M1_op2;
assign M2_long = M2_op1*M2_op2;
assign M3_long = M3_op1*M3_op2;

assign M1 = {M1_long[63], M1_long[30:0]};
assign M2 = {M2_long[63], M2_long[30:0]};
assign M3 = {M3_long[63], M3_long[30:0]};

assign M3_Base_address = FS_Base_address;
assign M3_Jump_offset = FS_Jump_offset;

// instantiate RAM0 C MATRIX
// only reading from this DPRAM so wren and data lines are hardcoded. 
dual_port_RAM RAM_inst0 (
	.address_a ( address_C[0] ),
	.address_b ( address_C[1] ),
	.clock ( CLOCK_50 ),
	.data_a ( 32'h00 ),
	.data_b ( 32'h00 ),
	.wren_a ( 1'b0 ),
	.wren_b ( 1'b0 ),
	.q_a ( read_data_C[0] ),
	.q_b ( read_data_C[1] )
);

// S PRIME MATRIX
dual_port_RAM RAM_inst1 (
	.address_a ( address_SP[0] ), // 7 bits to address 128 locations
	.address_b ( address_SP[1] ),
	.clock ( CLOCK_50 ),
	.data_a ( write_data_SP[0] ), // write data lines 32 bits (per location)
	.data_b ( write_data_SP[1] ),
	.wren_a ( wren_SP[0] ),
	.wren_b ( wren_SP[1] ),
	.q_a ( read_data_SP[0] ), // 32 bits output data line
	.q_b ( read_data_SP[1] )
);

// T MATRIX
dual_port_RAM RAM_inst2 (
	.address_a ( address_T[0] ), // 8 bits for 128 locations
	.address_b ( address_T[1] ),
	.clock ( CLOCK_50 ),
	.data_a ( write_data_T[0] ), //write data lines
	.data_b ( write_data_T[1] ),
	.wren_a ( wren_T[0] ),
	.wren_b ( wren_T[1] ),
	.q_a ( read_data_T[0] ), //output read lines
	.q_b ( read_data_T[1] )
);

// M3 DPRAM 
dual_port_RAM RAM_inst3 (
	.address_a ( address_M3[0] ), // 8 bits for 128 locations
	.address_b ( address_M3[1] ),
	.clock ( CLOCK_50 ),
	.data_a ( write_data_M3[0] ), //write data lines
	.data_b ( write_data_M3[1] ),
	.wren_a ( wren_M3 ),
	.wren_b ( 1'b0 ),
	.q_a ( read_data_M3[0] ), //output read lines
	.q_b ( read_data_M3[1] )
);

milestone3 M3_unit (
	.CLOCK_50( CLOCK_50 ),
	.Resetn( Resetn ),
	.SRAM_read_data( SRAM_read_data ),
	.read_data_M3_b ( read_data_M3[1] ), 
	.Base_address ( M3_Base_address ), // for testing m3 individually
	.Jump_offset ( M3_Jump_offset ),  // for testing m3 individually
	.Start( M3_enable ),

	.Done( M3_done ),
	.SRAM_address(	M3_SRAM_address ),
	.SRAM_write_data(	M3_SRAM_write_data ), // for testing m3 individually
	.SRAM_we_n(	M3_SRAM_we_n ), // for testing m3 individually
	.address_M3( M3_address_M3 ), // for testing m3 integrated with m2
	.write_data_M3( M3_write_data_M3 ), // for testing m3 integrated with m2
	.wren_M3( M3_wren_M3 ), // for testing m3 integrated with m2
	
	.address_M3_b ( M3_address_M3_b ), // second port of dpram4
	
	.address_SP_a ( M3_address_SP ),
	.write_data_SP_a ( M3_write_data_SP ),
	.wren_SP_a ( M3_wren_SP_a )
);


m2_fs fs_unit (
	.CLOCK_50( CLOCK_50 ),
	.Resetn( Resetn ),
	.SRAM_read_data( SRAM_read_data ),
	.Base_address ( FS_Base_address ),
	.Jump_offset ( FS_Jump_offset ), 
	.Start ( m2_fs_enable ),

	.Done( m2_fs_done ),
	.SRAM_address( FS_SRAM_address ),
	.address_SP( FS_address_SP ), 
	.write_data_SP( FS_write_data_SP ),
	.wren_SP( FS_wren_SP )
);


m2_ct ct_unit (
	.CLOCK_50( CLOCK_50 ),
	.Resetn( Resetn ),
	.Start( m2_ct_enable ),
	.read_data_SP_a ( read_data_SP[0] ),
	.read_data_SP_b ( read_data_SP[1] ),
	.read_data_C_a ( read_data_C[0] ),
	.read_data_C_b ( read_data_C[1] ),
	.M1 ( M1 ),
	.M2 ( M2 ),
	.M3 ( M3 ),
	
	.M1_op1 ( CT_M1_ops[0] ),
	.M1_op2 ( CT_M1_ops[1] ),
	.M2_op1 ( CT_M2_ops[0] ),
	.M2_op2 ( CT_M2_ops[1] ),
	.M3_op1 ( CT_M3_ops[0] ),
	.M3_op2 ( CT_M3_ops[1] ),
	.Done( m2_ct_done ),
	.address_T ( CT_address_T ),
	.address_C_a ( CT_address_C[0] ),
	.address_C_b ( CT_address_C[1] ),
	.address_SP_a ( CT_address_SP[0] ),
	.address_SP_b ( CT_address_SP[1] ),
	.write_data_T ( CT_write_data_T ),
	.wren_T ( CT_wren_T )
);

m2_cs cs_unit (
	.CLOCK_50( CLOCK_50 ),
	.Resetn( Resetn ),
	.Start( m2_cs_enable ),
	.read_data_T_a( read_data_T[0] ),
	.read_data_C_a( read_data_C[0] ),
	.read_data_C_b( read_data_C[1] ),
	.M1 ( M1 ),
	.M2 ( M2 ),
	.M3 ( M3 ),
	
	.M1_op1 ( CS_M1_ops[0] ),
	.M1_op2 ( CS_M1_ops[1] ),
	.M2_op1 ( CS_M2_ops[0] ),
	.M2_op2 ( CS_M2_ops[1] ),
	.M3_op1 ( CS_M3_ops[0] ),
	.M3_op2 ( CS_M3_ops[1] ),
	.Done( m2_cs_done ),
	.wren_T_b( CS_wren_T_b ),
	.address_T_a( CS_address_T[0] ),
	.address_T_b( CS_address_T[1] ),
	.address_C_a( CS_address_C[0] ),
	.address_C_b( CS_address_C[1] ),
	.write_data_T_b( CS_write_data_T_b )
);

m2_write write_unit (
	.CLOCK_50( CLOCK_50 ),
	.Resetn( Resetn ),
	.Start( m2_wr_enable ),
	.read_data_T( read_data_T[1] ),
	.Base_address( WR_Base_address ),
	.Jump_offset( WR_Jump_offset ),
	
	.Done( m2_wr_done ),
	.SRAM_address( WR_SRAM_address ),
	.SRAM_write_data ( WR_SRAM_write_data ),
	.address_T ( WR_address_T ),
	.SRAM_we_n ( WR_SRAM_we_n )
);

M2_state_type state;

logic [8:0] FS_row_idx;
logic [7:0] WR_row_idx;
logic [17:0] FS_col_idx, WR_col_idx;

// Combination logic to control read/write/wren lines depending on states
// to be changed...
always_comb begin
	if(state == S_FETCH_SP) begin
		SRAM_address = M3_SRAM_address;
		SRAM_we_n = 1'b1; //M3_SRAM_we_n; //M3 signal for testing m3 isolated
		SRAM_write_data = 16'd0; //M3_SRAM_write_data; // M3 signal for testing m3 isolated
		
		address_C[0] = 7'd0;
		address_C[1] = 7'd0;
		
		/* without m3 integration
		address_SP[0] = FS_address_SP;
		address_SP[1] = 7'd0;
		write_data_SP[0] = FS_write_data_SP;
		write_data_SP[1] = 32'd0;
		wren_SP[0] = FS_wren_SP;
		wren_SP[1] = 1'b0;
		*/
		
		// m3 integration
		address_SP[0] = M3_address_SP;
		address_SP[1] = 7'd0;
		write_data_SP[0] = M3_write_data_SP;
		write_data_SP[1] = 32'd0;
		wren_SP[0] = M3_wren_SP_a;
		wren_SP[1] = 1'b0;
		
		
		address_T[0] = 7'd0;
		address_T[1] = 7'd0;
		write_data_T[0] = 32'd0;
		write_data_T[1] = 32'd0;
		wren_T[0] = 1'b0;
		wren_T[1] = 1'b0;
		
		//4th dp ram
		address_M3[0] = M3_address_M3;
		address_M3[1] = M3_address_M3_b;
		write_data_M3[0] = M3_write_data_M3;
		write_data_M3[1] = 32'd0;
		wren_M3 = M3_wren_M3;
		
		M1_op1 = 32'd0;
		M1_op2 = 32'd0;
		M2_op1 = 32'd0;
		M2_op2 = 32'd0;
		M3_op1 = 32'd0;
		M3_op2 = 32'd0;
		
	end else if (state == S_COMPUTE_T) begin
		SRAM_address = 18'd0;
		SRAM_we_n = 1'b1;
		SRAM_write_data = 16'd0;
		
		address_C[0] = CT_address_C[0];
		address_C[1] = CT_address_C[1];

		address_SP[0] = CT_address_SP[0];
		address_SP[1] = CT_address_SP[1];
		write_data_SP[0] = 32'd0;
		write_data_SP[1] = 32'd0;
		wren_SP[0] = 1'b0;
		wren_SP[1] = 1'b0;
		
		address_T[0] = CT_address_T;
		address_T[1] = 7'd0;
		write_data_T[0] = CT_write_data_T;
		write_data_T[1] = 32'd0;
		wren_T[0] = CT_wren_T;
		wren_T[1] = 1'b0;
		
		//4th dp ram
		address_M3[0] = 7'd0;
		address_M3[1] = 7'd0;
		write_data_M3[0] = 32'd0;
		write_data_M3[1] = 32'd0;
		wren_M3 = 1'b0;
		
		M1_op1 = CT_M1_ops[0];
		M1_op2 = CT_M1_ops[1];
		M2_op1 = CT_M2_ops[0];
		M2_op2 = CT_M2_ops[1];
		M3_op1 = CT_M3_ops[0];
		M3_op2 = CT_M3_ops[1];
		
	end else if (state == S_COMMON_0) begin //cs and fs
		SRAM_address = M3_SRAM_address;
		SRAM_we_n = 1'b1; //M3_SRAM_we_n; //M3 signal for testing m3 isolated
		SRAM_write_data = 16'd0; //M3_SRAM_write_data; // M3 signal for testing m3 isolated
		
		address_C[0] = CS_address_C[0];
		address_C[1] = CS_address_C[1];
		
		/* without m3 integration
		address_SP[0] = FS_address_SP;
		address_SP[1] = 7'd0;
		write_data_SP[0] = FS_write_data_SP;
		write_data_SP[1] = 32'd0;
		wren_SP[0] = FS_wren_SP;
		wren_SP[1] = 1'b0;
		*/
		
		// m3 integration
		address_SP[0] = M3_address_SP;
		address_SP[1] = 7'd0;
		write_data_SP[0] = M3_write_data_SP;
		write_data_SP[1] = 32'd0;
		wren_SP[0] = M3_wren_SP_a;
		wren_SP[1] = 1'b0;
		
		address_T[0] = CS_address_T[0];
		address_T[1] = CS_address_T[1];
		write_data_T[0] = 32'd0;
		write_data_T[1] = CS_write_data_T_b;
		wren_T[0] = 1'b0;
		wren_T[1] = CS_wren_T_b;
		
		//4th dp ram
		address_M3[0] = M3_address_M3;
		address_M3[1] = M3_address_M3_b;
		write_data_M3[0] = M3_write_data_M3;
		write_data_M3[1] = 32'd0;
		wren_M3 = M3_wren_M3;
		
		M1_op1 = CS_M1_ops[0];
		M1_op2 = CS_M1_ops[1];
		M2_op1 = CS_M2_ops[0];
		M2_op2 = CS_M2_ops[1];
		M3_op1 = CS_M3_ops[0];
		M3_op2 = CS_M3_ops[1];
		
	end else if (state == S_COMMON_1) begin // CT and Wr
		SRAM_address = WR_SRAM_address;
		SRAM_we_n = WR_SRAM_we_n;
		SRAM_write_data = WR_SRAM_write_data;
		
		address_C[0] = CT_address_C[0];
		address_C[1] = CT_address_C[1];

		address_SP[0] = CT_address_SP[0];
		address_SP[1] = CT_address_SP[1];
		write_data_SP[0] = 32'd0;
		write_data_SP[1] = 32'd0;
		wren_SP[0] = 1'b0;
		wren_SP[1] = 1'b0;
		
		address_T[0] = CT_address_T;
		address_T[1] = WR_address_T;
		write_data_T[0] = CT_write_data_T;
		write_data_T[1] = 32'd0;
		wren_T[0] = CT_wren_T;
		wren_T[1] = 1'b0;
		
		//4th dp ram
		address_M3[0] = 7'd0;
		address_M3[1] = 7'd0;
		write_data_M3[0] = 32'd0;
		write_data_M3[1] = 32'd0;
		wren_M3 = 1'b0;
		
		M1_op1 = CT_M1_ops[0];
		M1_op2 = CT_M1_ops[1];
		M2_op1 = CT_M2_ops[0];
		M2_op2 = CT_M2_ops[1];
		M3_op1 = CT_M3_ops[0];
		M3_op2 = CT_M3_ops[1];
		
	end else if (state == S_COMPUTE_S) begin
		SRAM_address = 18'd0;
		SRAM_we_n = 1'b1;
		SRAM_write_data = 16'd0;
		
		address_C[0] = CS_address_C[0];
		address_C[1] = CS_address_C[1];

		address_SP[0] = 7'd0;
		address_SP[1] = 7'd0;
		write_data_SP[0] = 32'd0;
		write_data_SP[1] = 32'd0;
		wren_SP[0] = 1'b0;
		wren_SP[1] = 1'b0;
		
		address_T[0] = CS_address_T[0];
		address_T[1] = CS_address_T[1];
		write_data_T[0] = 32'd0;
		write_data_T[1] = CS_write_data_T_b;
		wren_T[0] = 1'b0;
		wren_T[1] = CS_wren_T_b;
		
		//4th dp ram
		address_M3[0] = 7'd0;
		address_M3[1] = 7'd0;
		write_data_M3[0] = 32'd0;
		write_data_M3[1] = 32'd0;
		wren_M3 = 1'b0;
		
		M1_op1 = CS_M1_ops[0];
		M1_op2 = CS_M1_ops[1];
		M2_op1 = CS_M2_ops[0];
		M2_op2 = CS_M2_ops[1];
		M3_op1 = CS_M3_ops[0];
		M3_op2 = CS_M3_ops[1];
		
	end else if (state == S_WRITE_S) begin
		SRAM_address = WR_SRAM_address;
		SRAM_we_n = WR_SRAM_we_n;
		SRAM_write_data = WR_SRAM_write_data;
		
		address_C[0] = 7'd0;
		address_C[1] = 7'd0;

		address_SP[0] = 7'd0;
		address_SP[1] = 7'd0;
		write_data_SP[0] = 32'd0;
		write_data_SP[1] = 32'd0;
		wren_SP[0] = 1'b0;
		wren_SP[1] = 1'b0;
		
		address_T[0] = 7'd0;
		address_T[1] = WR_address_T;
		write_data_T[0] = 32'd0;
		write_data_T[1] = 32'd0;
		wren_T[0] = 1'b0;
		wren_T[1] = 1'b0;
		
		//4th dp ram
		address_M3[0] = 7'd0;
		address_M3[1] = 7'd0;
		write_data_M3[0] = 32'd0;
		write_data_M3[1] = 32'd0;
		wren_M3 = 1'b0;
		
		M1_op1 = 32'd0;
		M1_op2 = 32'd0;
		M2_op1 = 32'd0;
		M2_op2 = 32'd0;
		M3_op1 = 32'd0;
		M3_op2 = 32'd0;
		
	end else begin // IDLE state
		SRAM_address = 18'd0;
		SRAM_we_n = 1'b1;
		SRAM_write_data = 16'd0;
		
		address_C[0] = 7'd0;
		address_C[1] = 7'd0;

		address_SP[0] = 7'd0;
		address_SP[1] = 7'd0;
		write_data_SP[0] = 32'd0;
		write_data_SP[1] = 32'd0;
		wren_SP[0] = 1'b0;
		wren_SP[1] = 1'b0;
		
		address_T[0] = 7'd0;
		address_T[1] = 7'd0;
		write_data_T[0] = 32'd0;
		write_data_T[1] = 32'd0;
		wren_T[0] = 1'b0;
		wren_T[1] = 1'b0;
		
		address_M3[0] = 7'd0;
		address_M3[1] = 7'd0;
		write_data_M3[0] = 32'd0;
		write_data_M3[1] = 32'd0;
		wren_M3 = 1'b0;
		
		M1_op1 = 32'd0;
		M1_op2 = 32'd0;
		M2_op1 = 32'd0;
		M2_op2 = 32'd0;
		M3_op1 = 32'd0;
		M3_op2 = 32'd0;
		
	end
end

always_ff @(posedge CLOCK_50 or negedge Resetn) begin
	if (~Resetn) begin
		state <= S_M2_IDLE;
		m2_fs_enable <= 1'b0;
		m2_ct_enable <= 1'b0;
		m2_cs_enable <= 1'b0;
		m2_wr_enable <= 1'b0;
		M3_enable <= 1'b0;
		
		FS_Base_address <= 18'd0;
		WR_Base_address <= 18'd0;
		
		FS_Jump_offset <= 9'd0;
		WR_Jump_offset <= 9'd0;
		
		FS_row_idx <= 9'd0;
		WR_row_idx <= 8'd0;
		FS_col_idx <= 18'd0;
		WR_col_idx <= 18'd0;
		
		Done <= 1'b0;
	end else begin
		case (state)
			S_M2_IDLE: begin
				Done <= 1'b0;
				if(Start && ~Done) begin
					//m2_fs_enable <= 1'b1;
					M3_enable <= 1'b1;
					FS_Base_address <= DCT_Y_BASE_ADR;
					FS_Jump_offset <= 9'd320;
					
					state <= S_FETCH_SP;
				end
			end
			
			S_FETCH_SP: begin
				//if(m2_fs_done) begin
				if(M3_done) begin
					//m2_fs_enable <= 1'b0;
					M3_enable <= 1'b0;
					FS_row_idx <= FS_row_idx + 4'd8;
					
					m2_ct_enable <= 1'b1;
					state <= S_COMPUTE_T;
					//Done <= 1'b1;
					//state <= S_M2_IDLE;
				end
			end
			
			S_COMPUTE_T: begin
				if(m2_ct_done) begin
					m2_ct_enable <= 1'b0;
					
					//m2_fs_enable <= 1'b1;
					M3_enable <= 1'b1;
					FS_Base_address <= DCT_Y_BASE_ADR + FS_row_idx + FS_col_idx;
					FS_Jump_offset <= 9'd320;				
					m2_cs_enable <= 1'b1;
					
					//Done <= 1'b1;
					//state <= S_M2_IDLE;
					state <= S_COMMON_0;
				end
			end
			
			S_COMMON_0: begin
				//if(m2_fs_done)
				//	m2_fs_enable <= 1'b0; // fs finishes cycles before cs
				
				if(M3_done)
					M3_enable <= 1'b0; // M3 finishes cycles before cs
					
				if(m2_cs_done) begin // common 0 ends when cs finishes
					m2_cs_enable <= 1'b0;
					
					if(FS_row_idx == 9'd312 && (DCT_Y_BASE_ADR + FS_col_idx) < DCT_U_BASE_ADR) begin
						FS_row_idx <= 9'd0;
						FS_col_idx <= FS_col_idx + 12'd2560;
					end else if(FS_row_idx == 9'd152 && (DCT_Y_BASE_ADR + FS_col_idx) >= DCT_U_BASE_ADR) begin
						FS_row_idx <= 9'd0;
						FS_col_idx <= FS_col_idx + 11'd1280;
					end else begin
						FS_row_idx <= FS_row_idx + 4'd8;
					end
					
					WR_Base_address <= Y_BASE_ADR + WR_row_idx + WR_col_idx;
					if((Y_BASE_ADR + WR_col_idx) < U_BASE_ADR) begin //condition to determine what base add and jump offset to give to wr
						WR_Jump_offset <= 9'd160;
					end else begin
						WR_Jump_offset <= 9'd80;
					end
					
					m2_wr_enable <= 1'd1;
					m2_ct_enable <= 1'd1;
					
					state <= S_COMMON_1;
				end
			end
			
			S_COMMON_1: begin
				if(m2_wr_done)
					m2_wr_enable <= 1'b0;
					
				if(m2_ct_done) begin
					m2_ct_enable <= 1'b0;
					
					if((WR_row_idx == 8'd156) && ((Y_BASE_ADR + WR_col_idx) < U_BASE_ADR)) begin
						WR_row_idx <= 8'd0;
						WR_col_idx <= WR_col_idx + 11'd1280;
					end else if((WR_row_idx == 7'd76) && ((Y_BASE_ADR + WR_col_idx) >= U_BASE_ADR)) begin
						WR_row_idx <= 8'd0;
						WR_col_idx <= WR_col_idx + 10'd640;
					end else begin
						WR_row_idx <= WR_row_idx + 3'd4;
					end
					
					FS_Base_address <= DCT_Y_BASE_ADR + FS_row_idx + FS_col_idx;
					if((DCT_Y_BASE_ADR + FS_col_idx) < DCT_U_BASE_ADR) begin //condition to determine what base add and jump offset to give to wr
						FS_Jump_offset <= 9'd320;
					end else begin
						FS_Jump_offset <= 9'd160;
					end
					if(WR_row_idx == 8'd72 && WR_col_idx == 18'd76160) begin //2nd last col and last row of v
						m2_cs_enable <= 1'd1;
						state <= S_COMPUTE_S;
					end else begin
						//m2_fs_enable <= 1'd1;
						M3_enable <= 1'b1;
						m2_cs_enable <= 1'd1;
						state <= S_COMMON_0;
					end
				end
			end
			
			S_COMPUTE_S: begin
				if(m2_cs_done) begin
					m2_cs_enable <= 1'b0;
					
					WR_Base_address <= Y_BASE_ADR + WR_row_idx + WR_col_idx;
					WR_Jump_offset <= 7'd80;
					//WR_Jump_offset <= 9'd160;
					
					m2_wr_enable <= 1'b1;
		
					//Done <= 1'b1;
					//state <= S_M2_IDLE;
					
					state <= S_WRITE_S;
				end
			end
			
			S_WRITE_S: begin
				if(m2_wr_done) begin
					//m2_fs_enable <= 1'b0;
					M3_enable <= 1'b0;
					m2_ct_enable <= 1'b0;
					m2_cs_enable <= 1'b0;
					m2_wr_enable <= 1'b0;
		
					FS_Base_address <= 18'd0;
					WR_Base_address <= 18'd0;
		
					FS_Jump_offset <= 9'd0;
					WR_Jump_offset <= 9'd0;
		
					FS_row_idx <= 9'd0;
					WR_row_idx <= 8'd0;
					FS_col_idx <= 18'd0;
					WR_col_idx <= 18'd0;
					
					Done <= 1'b1;
					state <= S_M2_IDLE;
				end
			end
			default: state <= S_M2_IDLE;
		endcase
	end
end

endmodule
