//=======================Test normal kick=========================//

`timescale 1ns / 1ps

module tb_normal_kick();

    // 1. Khai báo dây tín hiệu
    reg clk;
    reg rst_n;
    reg s1_wdi;
    reg s2_en;

    wire led_d3_wdo;
    wire led_d4_enout;

    // 2. Khởi tạo Top Module với tần số 27MHz. 
    watchdog_top #(
        .CLK_FREQ(27_000_000) 
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .s1_wdi(s1_wdi),
        .s2_en(s2_en),
        .led_d3_wdo(led_d3_wdo),
        .led_d4_enout(led_d4_enout)
    );

    // 3. Tạo xung clock 27MHz (Chu kỳ ~ 37.037 ns -> nửa chu kỳ là 18.5)
    initial begin
        clk = 0;
        forever #18.5 clk = ~clk;
    end

    // 4. Task Kick thời gian thực
    task press_kick;
        begin
            $display("[%0t ns] -> Thuc hien nhan nut S1 (Kick)...", $time);
            s1_wdi = 0; // Kéo thấp để nhấn nút
            
            // QUAN TRỌNG: Giữ nút 15ms để chắc chắn vượt qua bộ lọc Debounce 10ms
            #15_000_000; 
            
            s1_wdi = 1; // Nhả nút
            $display("[%0t ns] -> Da nha nut S1. Kick thanh cong!", $time);
        end
    endtask

    // 5. Kịch bản mô phỏng chính
    initial begin
        // Chuẩn bị file xuất sóng cho ModelSim
        $dumpfile("watchdog_realtime.vcd");
        $dumpvars(0, tb_normal_kick);

        // =======================================================
        // BƯỚC 1: KHỞI TẠO
        // =======================================================
        rst_n = 0;
        s1_wdi = 1;
        s2_en = 1;
        
        #1_000_000; 
        rst_n = 1; // Gỡ reset sau 1ms
        s2_en = 0; 
        $display("[%0t ns] He thong khoi dong. EN dang bat.", $time);
        
        #10_000_000; // Đợi ổn định 10ms

        // Chờ qua debounce và arm_delay (150us)
        wait(led_d4_enout == 1'b1);
        $display("[%0t ns] Da qua arm_delay. ENOUT = 1. Bat dau dem tWD (1600ms)!", $time);

        // =======================================================
        // BƯỚC 2: TEST NORMAL KICK
        // =======================================================
        $display("\n--- BAT DAU TEST NORMAL KICK ---");
        #10_000_000;
        press_kick();
        #1_000_000_000; // Đợi 1 giây (nằm trong khoảng an toàn < 1.6s)
        
        press_kick();
        #1_000_000_000; 
        
        press_kick();
        #1_000_000_000;

        // Kiểm tra xem WDO có bị kéo xuống sai quy tắc không
        if (led_d3_wdo == 1'b1)
            $display("[%0t ns] NORMAL KICK PASS: WDO dang giu muc 1 an toan.", $time);
        else
            $display("[%0t ns] NORMAL KICK FAIL: WDO bi rot xuong 0 sai quy tac!", $time);

        // =======================================================
        // KẾT THÚC
        // =======================================================
        #100_000_000; // Đợi thêm 100ms
        $display("\nMo phong hoan tat!");
        $stop;
    end

endmodule