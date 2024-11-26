
mem save -o SRAM.mem -f mti -data hex -addr dec -startaddress 0 -endaddress 262143 -wordsperline 2 /TB/SRAM_component/SRAM_data
mem save -o C_DP.mem -f mti -data hex -addr dec -startaddress 0 -endaddress 127 -wordsperline 1 /TB/UUT/M2_unit/RAM_inst0/altsyncram_component/m_default/altsyncram_inst/mem_data
mem save -o SP_DP.mem -f mti -data hex -addr dec -startaddress 0 -endaddress 127 -wordsperline 1 /TB/UUT/M2_unit/RAM_inst1/altsyncram_component/m_default/altsyncram_inst/mem_data
mem save -o TS_DP.mem -f mti -data hex -addr dec -startaddress 0 -endaddress 127 -wordsperline 1 /TB/UUT/M2_unit/RAM_inst2/altsyncram_component/m_default/altsyncram_inst/mem_data
mem save -o M3_DP.mem -f mti -data hex -addr dec -startaddress 0 -endaddress 127 -wordsperline 1 /TB/UUT/M2_unit/RAM_inst3/altsyncram_component/m_default/altsyncram_inst/mem_data