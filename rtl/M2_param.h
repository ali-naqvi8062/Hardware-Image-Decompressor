/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/
`ifndef M2_PARAM

parameter 	CT_DIVISOR = 4'd8;
parameter 	CS_DIVISOR = 5'd16;

parameter	S_OFFSET = 7'd64;
parameter	CT_OFFSET = 7'd32;

parameter	DCT_Y_BASE_ADR = 18'd76800;
parameter 	DCT_U_BASE_ADR = 18'd153600;
parameter 	DCT_V_BASE_ADR = 18'd192000;

`define M2_PARAM 1
`endif