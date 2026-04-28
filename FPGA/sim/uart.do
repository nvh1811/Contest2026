onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /tb_system_uart/dut/clk
add wave -noupdate -radix hexadecimal /tb_system_uart/dut/rx
add wave -noupdate -radix hexadecimal /tb_system_uart/dut/tx
add wave -noupdate -radix hexadecimal /tb_system_uart/dut/rx_data
add wave -noupdate -radix hexadecimal /tb_system_uart/dut/tx_data
add wave -noupdate -radix hexadecimal /tb_system_uart/dut/final_en
add wave -noupdate -radix hexadecimal /tb_system_uart/dut/final_kick_n
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {8189870092 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 218
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ms
update
WaveRestoreZoom {0 ps} {14892360 ns}
