module watchdog_top #(
    parameter CLK_FREQ = 27_000_000 
)(
    input wire clk,          
    input wire rst_n,        
    input wire s1_wdi,       
    input wire s2_en,        
    output wire led_d3_wdo,  
    output wire led_d4_enout 
);

    wire s2_en_level_low; // Active-Low (Giữ mức)
    wire wdi_kick_pulse_n; // Active-Low (Xung) - Đổi tên cho dễ nhớ
    localparam debounce_time = 10;
    // --- Khối 1: Nút EN ---
    debounce_button #(
        .CLK_FREQ(CLK_FREQ), .DEBOUNCE_TIME_MS(debounce_time) 
    ) deb_en (
        .clk(clk), 
        .pb_1(s2_en),            
        .pb_level(s2_en_level_low), // Trả ra 0 khi nhấn giữ
        .pb_pulse()                 
    );

    // --- Khối 2: Nút WDI ---
    debounce_button #(
        .CLK_FREQ(CLK_FREQ), .DEBOUNCE_TIME_MS(debounce_time)
    ) deb_wdi (
        .clk(clk), 
        .pb_1(s1_wdi),              
        .pb_level(),                
        .pb_pulse(wdi_kick_pulse_n) // Trả ra xung 0 chớp nhoáng khi vừa nhấn
    );

    // --- Khối Core ---
    watchdog_core #(
        .CLK_FREQ(CLK_FREQ),
        .TWD_MS(1600), .TRST_MS(200), .ARM_DELAY_US(150) 
    ) wd_core (
        .clk(clk), 
        .rst_n(rst_n),
        .en_n(s2_en_level_low),      
        .wdi_kick_n(wdi_kick_pulse_n), 
        .wdo(led_d3_wdo),        
        .enout(led_d4_enout)     
    );

endmodule