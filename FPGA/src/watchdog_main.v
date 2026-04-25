module watchdog_top #(
    parameter CLK_FREQ = 27_000_000,
    parameter BAUD_RATE = 115200 // Hoặc 9600 tùy em test
)(
    input  wire clk,         
    input  wire s1_wdi,        // Nút cứng S1
    input  wire s2_en,         // Nút cứng S2
    input  wire rx,            // Chân nhận UART từ máy tính
    output wire tx,            // Chân gửi UART lên máy tính
    output wire led_d3_wdo,  
    output wire led_d4_enout 
);

    // ==========================================
    // 1. DÂY NỐI CÁC KHỐI
    // ==========================================
    // Nút bấm
    wire btn_en_high;       
    wire btn_kick_low_n;   

    // UART Vật lý
    wire [7:0] rx_data;
    wire rx_done;
    wire [7:0] tx_data;
    wire tx_start;
    wire tx_busy;

    // Giao thức (Parser -> Responder & Core)
    wire uart_core_en;
    wire uart_core_kick_n;
    wire [31:0] twd_ms;
    wire [31:0] trst_ms;
    wire [15:0] arm_delay_us;
    
    wire valid_frame_pulse;
    wire [7:0] valid_cmd;
    wire [7:0] valid_addr;

    // ==========================================
    // 2. GỘP LOGIC (NÚT BẤM + PHẦN MỀM)
    // ==========================================
    // Watchdog BẬT khi (Nút nhấn Đang Giữ) HOẶC (Phần mềm gửi lệnh Bật)
    wire final_en = btn_en_high | uart_core_en;
    
    // Watchdog KICK khi (Nút nhấn Vừa Bấm) HOẶC (Phần mềm gửi lệnh Kick)
    // Vì Kick là Active-Low (Mức 0) nên ta dùng cổng AND.
    wire final_kick_n = btn_kick_low_n & uart_core_kick_n;

    // Đóng gói Thanh ghi Trạng thái (STATUS - 0x10)
    wire [31:0] status_reg;
    assign status_reg[0] = final_en; // EN_EFFECTIVE
    assign status_reg[1] = ~led_d3_wdo;  // FAULT_ACTIVE (WDO=0 nghĩa là lỗi)
    assign status_reg[2] = led_d4_enout; // Chân ENOUT
    assign status_reg[3] = led_d3_wdo;   // Chân WDO
    assign status_reg[4] = 1'b0;         // Mặc định đá chó cứng
    assign status_reg[31:5] = 27'd0;

    // ==========================================
    // 3. KHỞI TẠO CÁC MODULE
    // ==========================================
    
    // Nút bấm
    debounce_button #(.CLK_FREQ(CLK_FREQ), .DEBOUNCE_TIME_MS(15)) deb_en (
        .clk(clk), .pb_1(s2_en), .pb_level_high(btn_en_high), .pb_pulse_low()
    );
    debounce_button #(.CLK_FREQ(CLK_FREQ), .DEBOUNCE_TIME_MS(15)) deb_wdi (
        .clk(clk), .pb_1(s1_wdi), .pb_level_high(), .pb_pulse_low(btn_kick_low_n)
    );

    // UART RX
    uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_rx (
        .clk(clk), .rx(rx), .rx_data(rx_data), .rx_done(rx_done)
    );

    // Bộ giải mã gói tin
    frame_parser u_parser (
        .clk(clk),
        .rx_done(rx_done), .rx_data(rx_data),
        
        // Cấp lệnh cho Core
        .core_en(uart_core_en),
        .core_kick(uart_core_kick_n),
        .twd_ms(twd_ms),
        .trst_ms(trst_ms),
        .arm_delay_us(arm_delay_us),
        
        // Báo cho Responder
        .valid_frame_pulse(valid_frame_pulse),
        .valid_cmd(valid_cmd),
        .valid_addr(valid_addr)
    );

    // Bộ trả lời gói tin
    uart_frame_responder u_responder (
        .clk(clk),
        .trigger_send(valid_frame_pulse),
        .cmd_in(valid_cmd),
        .addr_in(valid_addr),
        
        // Lấy data từ Register Map
        .twd_ms(twd_ms),
        .trst_ms(trst_ms),
        .arm_delay_us(arm_delay_us),
        .status_reg(status_reg),
        
        // Ra lệnh cho UART TX
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_busy(tx_busy)
    );

    // UART TX
    uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_tx (
        .clk(clk), .tx_start(tx_start), .tx_data(tx_data), .tx(tx), .tx_busy(tx_busy)
    );

    // Lõi Watchdog
    watchdog_core #(.CLK_FREQ(CLK_FREQ)) wd_core (
        .clk(clk),
        .en(final_en),             
        .wdi_kick_n(final_kick_n), 
        
        // Cấu hình động
        .twd_ms(twd_ms),
        .trst_ms(trst_ms),
        .arm_delay_us(arm_delay_us),
        
        .wdo(led_d3_wdo),        
        .enout(led_d4_enout)     
    );

endmodule