onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_disable/clk
add wave -noupdate /tb_disable/rst_n
add wave -noupdate /tb_disable/s1_wdi
add wave -noupdate /tb_disable/s2_en
add wave -noupdate /tb_disable/led_d3_wdo
add wave -noupdate /tb_disable/led_d4_enout
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 204
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
WaveRestoreZoom {0 ps} {2033850 us}
