/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`ifndef M1_PARAM

parameter	Y_BASE_ADR = 1'b0;
parameter 	U_BASE_ADR = 16'd38400;
parameter 	V_BASE_ADR = 16'd57600;
parameter	RGB_BASE_ADR = 18'd146944;

parameter	UV_PRIME_C0 = 32'd128;
parameter	UV_PRIME_C1 = 32'd21;
parameter	UV_PRIME_C2 = 32'd52;
parameter	UV_PRIME_C3 = 32'd159;
parameter	UV_PRIME_DIV_SHIFT = 32'd8;

parameter	RGB_SUB_C0 = 32'd16;
parameter	RGB_SUB_C1 = 32'd128;
parameter	RGB_MATRIX_A = 32'd76284;
parameter	RGB_MATRIX_B = 32'd104595;
parameter	RGB_MATRIX_C = 32'd25624;
parameter	RGB_MATRIX_D = 32'd53281;
parameter	RGB_MATRIX_E = 32'd132251;
parameter	RGB_DIV_SHIFT = 32'd16;

`define M1_PARAM 1
`endif
