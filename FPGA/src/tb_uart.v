`timescale 1ns / 1ps  // Đơn vị thời gian mô phỏng: 1ns, độ phân giải 1ps

module tb_system_uart();

    // 1. Cấu hình thông số (Giống y hệt khối Top)
    parameter CLK_FREQ = 27_000_000; // 27 MHz
    parameter BAUD_RATE = 115200;    // Tốc độ baud
    
    // Tính toán thời gian thực
    localparam CLK_PERIOD = 1000000000 / CLK_FREQ; // ~37ns cho 1 chu kỳ clk
    localparam BIT_PERIOD = 1000000000 / BAUD_RATE; // ~8680ns cho 1 bit UART

    // 2. Khai báo dây dẫn ảo
    reg clk;
    reg s1_wdi;
    reg s2_en;
    reg rx;
    
    wire tx;
    wire led_d3_wdo;
    wire led_d4_enout;

    // 3. Khởi tạo con chip (DUT - Device Under Test)
    watchdog_top #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .s1_wdi(s1_wdi),
        .s2_en(s2_en),
        .rx(rx),
        .tx(tx),
        .led_d3_wdo(led_d3_wdo),
        .led_d4_enout(led_d4_enout)
    );

    // 4. Máy phát Xung nhịp (Clock Generator)
    initial clk = 0;
    always #(CLK_PERIOD / 2.0) clk = ~clk; // Lật trạng thái liên tục

    // =========================================================
    // Task đóng giả PC gửi 1 byte qua UART
    // =========================================================
    task send_uart_byte;
        input [7:0] data;
        integer i;
        begin
            // Bắn bit Start (kéo xuống 0)
            rx = 1'b0;
            #(BIT_PERIOD);
            
            // Bắn 8 bit Data (từ thấp đến cao LSB -> MSB)
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(BIT_PERIOD);
            end
            
            // Bắn bit Stop (kéo lên 1)
            rx = 1'b1;
            #(BIT_PERIOD);
        end
    endtask

    // =========================================================
    // 5. KỊCH BẢN KIỂM THỬ CHÍNH (MAIN TEST SEQUENCE)
    // =========================================================
    initial begin
        // Khởi tạo trạng thái ban đầu (Mọi thứ im lặng)
        s1_wdi = 1; 
        s2_en = 1;
        rx = 1; // Đường truyền UART mặc định mức 1
        
        $display("=== BAT DAU MO PHONG GIAO THUC UART ===");
        
        // Đợi hệ thống ổn định lúc khởi động
        #100000; 

        // ----------------------------------------------------
        // KỊCH BẢN 1: Thử gửi lệnh GET_STATUS (0x04)
        // CHK = CMD(04) ^ ADDR(00) ^ LEN(00) = 04
        // ----------------------------------------------------
        $display(">> 1. PC gui lenh GET_STATUS...");
        send_uart_byte(8'h55); // Header
        send_uart_byte(8'h04); // Lệnh Get Status
        send_uart_byte(8'h00); // Address
        send_uart_byte(8'h00); // Length (0)
        send_uart_byte(8'h04); // Checksum
        
        // Đợi mạch trả về qua TX (Cần ít nhất 2-3ms cho Baud 115200)
        #3000000; 
        
        // ----------------------------------------------------
        // KỊCH BẢN 2: Thử gửi lệnh WRITE_REG (0x01)
        // Đổi thời gian Timeout (twd_ms - Addr 0x04) thành 2000ms (0x000007D0)
        // CHK = 01 ^ 04 ^ 04 ^ 00 ^ 00 ^ 07 ^ D0 = D6
        // ----------------------------------------------------
        $display(">> 2. PC gui lenh WRITE: Doi tWD thanh 2000ms...");
        send_uart_byte(8'h55); // Header
        send_uart_byte(8'h01); // Lệnh Write
        send_uart_byte(8'h04); // Address (0x04 là thanh ghi twd_ms)
        send_uart_byte(8'h04); // Length (4 byte data)
        send_uart_byte(8'h00); // Data byte 3
        send_uart_byte(8'h00); // Data byte 2
        send_uart_byte(8'h07); // Data byte 1
        send_uart_byte(8'hD0); // Data byte 0
        send_uart_byte(8'hD6); // Checksum
        
        // Đợi mạch phản hồi chữ OKOK qua TX
        #3000000;

        // ----------------------------------------------------
        // KỊCH BẢN 3: Thử gửi lệnh READ_REG (0x02)
        // Đọc lại thanh ghi Timeout (twd_ms - Addr 0x04) xem đã lưu đúng 2000ms chưa
        // CHK = CMD(02) ^ ADDR(04) ^ LEN(00) = 06
        // ----------------------------------------------------
        $display(">> 3. PC gui lenh READ: Doc lai thanh ghi tWD...");
        send_uart_byte(8'h55); // Header
        send_uart_byte(8'h02); // Lệnh Read
        send_uart_byte(8'h04); // Address (0x04)
        send_uart_byte(8'h00); // Length (0 byte data)
        send_uart_byte(8'h06); // Checksum
        
        // Đợi mạch xuất 4 byte giá trị của twd_ms (00 00 07 D0) ra chân TX
        #3000000;

        // ----------------------------------------------------
        // KỊCH BẢN 4: Thử gửi lệnh KICK (0x03)
        // CHK = CMD(03) ^ ADDR(00) ^ LEN(00) = 03
        // ----------------------------------------------------
        $display(">> 4. PC gui lenh KICK cho...");
        send_uart_byte(8'h55); // Header
        send_uart_byte(8'h03); // Lệnh Kick
        send_uart_byte(8'h00); // Address
        send_uart_byte(8'h00); // Length
        send_uart_byte(8'h03); // Checksum
        
        // Đợi mạch phản hồi chữ OKOK qua TX
        #3000000;

        $display("=== KET THUC MO PHONG ===");
        $stop; // Dừng mô phỏng
    end

endmodule