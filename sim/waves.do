# activate waveform simulation

view wave

# format signal names in waveform

configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform

add wave -divider -height 20 {Top-level signals}
add wave -bin UUT/CLOCK_50_I
add wave -bin UUT/resetn
add wave UUT/top_state
add wave -uns UUT/UART_timer

add wave -divider -height 10 {SRAM signals}
add wave -uns UUT/SRAM_address
add wave -hex UUT/SRAM_write_data
add wave -bin UUT/SRAM_we_n
add wave -hex UUT/SRAM_read_data

add wave -divider -height 10 {Milestone 2 Signals}
add wave  UUT/M2_unit/state
add wave -hex UUT/M2_unit/m2_fs_enable
add wave -hex UUT/M2_unit/m2_fs_done
add wave -hex UUT/M2_unit/WR_Jump_offset
add wave -hex UUT/M2_unit/FS_Jump_offset
add wave -hex UUT/M2_unit/FS_col_idx
add wave -hex UUT/M2_unit/FS_row_idx

add wave -divider -height 10 {Milestone 3 Signals}
add wave  UUT/M2_unit/M3_unit/state
add wave  -uns UUT/M2_unit/M3_unit/Base_address
add wave  -bin UUT/M2_unit/M3_unit/SRAM_read_data
add wave  -bin UUT/M2_unit/M3_unit/SRAM_read_buff
add wave  -bin UUT/M2_unit/M3_unit/bitstream_buff
add wave  -uns UUT/M2_unit/M3_unit/shiftAmount
add wave  -uns UUT/M2_unit/M3_unit/dataEnd
add wave  -bin UUT/M2_unit/M3_unit/quant
add wave  -uns UUT/M2_unit/M3_unit/quantShift
add wave  -bin UUT/M2_unit/M3_unit/multiWriteInput
add wave  -uns UUT/M2_unit/M3_unit/address_M3
add wave  -hex UUT/M2_unit/M3_unit/write_data_M3
add wave  -bin UUT/M2_unit/M3_unit/wren_M3
add wave -hex UUT/M2_unit/M3_unit/write_data_SP_a
add wave -hex UUT/M2_unit/M3_unit/wren_SP_a
add wave  UUT/M2_unit/M3_unit/M3FS_state
add wave  -hex UUT/M2_unit/M3_unit/DPRAM4_buffer
add wave  -hex UUT/M2_unit/M3_unit/read_data_M3_b
add wave  -uns UUT/M2_unit/M3_unit/address_M3_b
add wave  -uns UUT/M2_unit/M3_unit/address_SP_a
add wave -bin UUT/M2_unit/M3_unit/next_zz_counter

#add wave -divider -height 10 {FS signals}
#add wave -hex UUT/M2_unit/fs_unit/SRAM_read_data
#add wave -dec UUT/M2_unit/fs_unit/DP_counter
#add wave -dec UUT/M2_unit/fs_unit/row_index
#add wave -hex UUT/M2_unit/fs_unit/state
#add wave -hex UUT/M2_unit/fs_unit/write_data_SP
#add wave -dec UUT/M2_unit/fs_unit/wren_SP
#add wave -dec UUT/M2_unit/fs_unit/address_SP


add wave -divider -height 10 {Milestone 2 WR Signals}
add wave -hex UUT/M2_unit/write_unit/state
add wave -hex UUT/M2_unit/m2_wr_enable
add wave -hex UUT/M2_unit/m2_wr_done
add wave -uns UUT/M2_unit/write_unit/T_counter
add wave -uns UUT/M2_unit/write_unit/jump
add wave -uns UUT/M2_unit/write_unit/Jump_offset
add wave -uns UUT/M2_unit/write_unit/SRAM_counter
add wave -uns UUT/M2_unit/write_unit/Base_address


#add wave -divider -height 10 {VGA signals}
#add wave -bin UUT/VGA_unit/VGA_HSYNC_O
#add wave -bin UUT/VGA_unit/VGA_VSYNC_O
#add wave -uns UUT/VGA_unit/pixel_X_pos
#add wave -uns UUT/VGA_unit/pixel_Y_pos
#add wave -hex UUT/VGA_unit/VGA_red
#add wave -hex UUT/VGA_unit/VGA_green
#add wave -hex UUT/VGA_unit/VGA_blue

#add wave -divider -height 10 {Milestone 1 Signals}
#add wave  UUT/M1_unit/state

#add wave -dec UUT/M1_unit/R_Reg
#add wave -dec UUT/M1_unit/G_Reg
#add wave -dec UUT/M1_unit/B_Reg

#add wave -dec UUT/M1_unit/V_Prime
#add wave -dec UUT/M1_unit/U_Prime

#add wave -hex UUT/M1_unit/Y_Reg
#add wave -hex UUT/M1_unit/V_Shift
#add wave -hex UUT/M1_unit/U_Shift

#add wave -divider -height 10 {M1 Signals}
#add wave -dec UUT/M1_unit/M1
#add wave -dec UUT/M1_unit/M1_long
#add wave -dec UUT/M1_unit/M1_op1
#add wave -dec UUT/M1_unit/M1_op2

#add wave -divider -height 10 {M2 Signals}
#add wave -dec UUT/M1_unit/M2
#add wave -dec UUT/M1_unit/M2_long
#add wave -dec UUT/M1_unit/M2_op1
#add wave -dec UUT/M1_unit/M2_op2

#add wave -divider -height 10 {M3 Signals}
#add wave -dec UUT/M1_unit/M3
#add wave -dec UUT/M1_unit/M3_long
#add wave -dec UUT/M1_unit/M3_op1
#add wave -dec UUT/M1_unit/M3_op2

#add wave -divider -height 10 {Milestone 1 write data}
#add wave -hex UUT/M1_unit/SRAM_write_data
#add wave -hex UUT/M1_unit/R_write
#add wave -hex UUT/M1_unit/G_write
#add wave -hex UUT/M1_unit/B_write
#add wave -hex UUT/M1_unit/RGB_temp_write



#add wave -divider -height 10 {Milestone 2 CT Signals}
#add wave  UUT/M2_unit/ct_unit/state
#add wave -hex UUT/M2_unit/m2_ct_enable
#add wave -hex UUT/M2_unit/m2_ct_done
#add wave -uns UUT/M2_unit/ct_unit/T_accumulator
#add wave -uns UUT/M2_unit/ct_unit/write_data_T
#add wave -uns UUT/M2_unit/ct_unit/SP_buffer
#add wave -uns UUT/M2_unit/ct_unit/C_buffer
#add wave -dec UUT/M2_unit/ct_unit/SP_counter
#add wave -dec UUT/M2_unit/ct_unit/address_SP_a
#add wave -dec UUT/M2_unit/ct_unit/address_SP_b
#add wave -hex UUT/M2_unit/ct_unit/read_data_SP_a
#add wave -hex UUT/M2_unit/ct_unit/read_data_SP_b
#add wave -hex UUT/M2_unit/ct_unit/read_data_C_a
#add wave -hex UUT/M2_unit/ct_unit/read_data_C_b
#add wave -dec UUT/M2_unit/M1_long
#add wave -dec UUT/M2_unit/M1_op1
#add wave -dec UUT/M2_unit/M1_op2
#add wave -dec UUT/M2_unit/M2_long
#add wave -dec UUT/M2_unit/M2_op1
#add wave -dec UUT/M2_unit/M2_op2
#add wave -dec UUT/M2_unit/M3_long
#add wave -dec UUT/M2_unit/M3_op1
#add wave -dec UUT/M2_unit/M3_op2

#add wave -hex UUT/M2_unit/RAM_inst1/address_a
#add wave -hex UUT/M2_unit/RAM_inst1/address_b
#add wave -hex UUT/M2_unit/CT_address_SP
#add wave -hex UUT/M2_unit/address_SP

#add wave -divider -height 10 {Milestone 2 CS Signals}
#add wave -hex UUT/M2_unit/cs_unit/state
#add wave -hex UUT/M2_unit/m2_cs_enable
#add wave -hex UUT/M2_unit/m2_cs_done
#add wave -uns UUT/M2_unit/cs_unit/T_read_counter
#add wave -uns UUT/M2_unit/cs_unit/T_addr_jump
#add wave -uns UUT/M2_unit/cs_unit/C_addr_counter
#add wave -dec UUT/M2_unit/cs_unit/S_accumulator

#add wave -divider -height 10 {CS ARITHMETIC}
#add wave -hex UUT/M2_unit/cs_unit/read_data_C_a
#add wave -hex UUT/M2_unit/cs_unit/read_data_C_b
#add wave -hex UUT/M2_unit/cs_unit/read_data_T_a
#add wave -hex UUT/M2_unit/cs_unit/address_C_a
#add wave -hex UUT/M2_unit/cs_unit/address_C_b
#add wave -dec UUT/M2_unit/cs_unit/flag
#add wave -dec UUT/M2_unit/cs_unit/flag2
#add wave -dec UUT/M2_unit/cs_unit/flag3
#add wave -dec UUT/M2_unit/cs_unit/flag4
#add wave -hex UUT/M2_unit/cs_unit/M1_op1
#add wave -hex UUT/M2_unit/cs_unit/M1_op2
#add wave -hex UUT/M2_unit/cs_unit/M2_op1
#add wave -hex UUT/M2_unit/cs_unit/M2_op2
#add wave -hex UUT/M2_unit/cs_unit/M3_op1
#add wave -hex UUT/M2_unit/cs_unit/M3_op2

#add wave -hex UUT/M2_unit/cs_unit/write_data_T_b
#add wave -uns UUT/M2_unit/cs_unit/address_T_b
#add wave -uns UUT/M2_unit/cs_unit/T_write_counter
#add wave -uns UUT/M2_unit/cs_unit/write_offset
#add wave -hex UUT/M2_unit/cs_unit/wren_T_b
#add wave -hex UUT/M2_unit/cs_unit/S_buff1
#add wave -hex UUT/M2_unit/cs_unit/S_buff2



