/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`ifndef M3_PARAM
// mic18 base adr will be 0 for testing m3 individually, then 76800 for integrated
parameter	MIC18_BASE_ADR = 18'd76800; 
parameter 	Q_offset = 3'd2;
parameter 	D_offset = 4'd4;

`define M3_PARAM 1
`endif
