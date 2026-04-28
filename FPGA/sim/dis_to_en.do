onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_disable_to_enable/dut/clk
add wave -noupdate /tb_disable_to_enable/dut/s1_wdi
add wave -noupdate /tb_disable_to_enable/dut/wdi_kick_pulse_low
add wave -noupdate /tb_disable_to_enable/dut/s2_en
add wave -noupdate /tb_disable_to_enable/dut/en_active_high
add wave -noupdate /tb_disable_to_enable/dut/led_d4_enout
add wave -noupdate /tb_disable_to_enable/dut/led_d3_wdo
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {89909981500 ps} 0} {{Cursor 2} {90059868500 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 266
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
WaveRestoreZoom {89735014136 ps} {90617533916 ps}
