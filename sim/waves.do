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

add wave -divider -height 10 {VGA signals}
add wave -bin UUT/VGA_unit/VGA_HSYNC_O
add wave -bin UUT/VGA_unit/VGA_VSYNC_O
add wave -uns UUT/VGA_unit/pixel_X_pos
add wave -uns UUT/VGA_unit/pixel_Y_pos
add wave -hex UUT/VGA_unit/VGA_red
add wave -hex UUT/VGA_unit/VGA_green
add wave -hex UUT/VGA_unit/VGA_blue

add wave -divider -height 10 {Milestone 1 Signals}
add wave  UUT/M1_unit/state

add wave -dec UUT/M1_unit/R_Reg
add wave -dec UUT/M1_unit/G_Reg
add wave -dec UUT/M1_unit/B_Reg

add wave -dec UUT/M1_unit/V_Prime
add wave -dec UUT/M1_unit/U_Prime

add wave -hex UUT/M1_unit/Y_Reg
add wave -hex UUT/M1_unit/V_Shift
add wave -hex UUT/M1_unit/U_Shift

add wave -divider -height 10 {M1 Signals}
add wave -dec UUT/M1_unit/M1
add wave -dec UUT/M1_unit/M1_long
add wave -dec UUT/M1_unit/M1_op1
add wave -dec UUT/M1_unit/M1_op2

add wave -divider -height 10 {M2 Signals}
add wave -dec UUT/M1_unit/M2
add wave -dec UUT/M1_unit/M2_long
add wave -dec UUT/M1_unit/M2_op1
add wave -dec UUT/M1_unit/M2_op2

add wave -divider -height 10 {M3 Signals}
add wave -dec UUT/M1_unit/M3
add wave -dec UUT/M1_unit/M3_long
add wave -dec UUT/M1_unit/M3_op1
add wave -dec UUT/M1_unit/M3_op2

add wave -divider -height 10 {Milestone 1 write data}
add wave -hex UUT/M1_unit/SRAM_write_data
add wave -hex UUT/M1_unit/R_write
add wave -hex UUT/M1_unit/G_write
add wave -hex UUT/M1_unit/B_write
add wave -hex UUT/M1_unit/RGB_temp_write