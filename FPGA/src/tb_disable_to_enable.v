//=============Test dis to en===============//

`timescale 1ns / 1ps

module tb_disable_to_enable();

    // 1. Khai báo dây tín hiệu
    reg clk;
    reg rst_n;
    reg s1_wdi;
    reg s2_en;

    wire led_d3_wdo;
    wire led_d4_enout;

    // 2. Khởi tạo Top Module (27MHz)
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

    // 3. Tạo xung clock 27MHz
    initial begin
        clk = 0;
        forever #18.5 clk = ~clk;
    end

    // 4. Kịch bản mô phỏng chính
    initial begin
        $dumpfile("watchdog_transition.vcd");
        $dumpvars(0, tb_disable_to_enable);

        // =======================================================
        // BƯỚC 1: KHỞI TẠO Ở TRẠNG THÁI TẮT (DISABLE)
        // =======================================================
        rst_n = 0;
        s1_wdi = 1;
        s2_en = 1; // S2 = 1 (Active-Low) -> Nghĩa là hệ thống đang TẮT
        
        #1_000_000 rst_n = 1; // Gỡ reset sau 1ms
        $display("\n[%0t ns] --- HE THONG KHOI DONG (DANG TAT) ---", $time);

        // Đợi 50ms để chắc chắn hệ thống đang nằm im ở trạng thái IDLE
        #50_000_000;
        
        // Chấm điểm Bước 1
        if (led_d4_enout == 1'b0)
            $display("[%0t ns] CHECK 1 PASS: He thong dang tat, ENOUT = 0.", $time);
        else
            $display("[%0t ns] CHECK 1 FAIL: ENOUT phai bang 0 khi dang tat!", $time);

        // =======================================================
        // BƯỚC 2: BẬT HỆ THỐNG LÊN (ENABLE)
        // =======================================================
        $display("\n[%0t ns] --- TIEN HANH BAT WATCHDOG ---", $time);
        s2_en = 0; // Kéo s2 xuống 0 để BẬT

        // Chờ hệ thống xử lý debounce và đi qua ARMING (150us)
        // Dùng wait để tự động bắt đúng khoảnh khắc đèn ENOUT sáng lên
        wait(led_d4_enout == 1'b1);
        $display("[%0t ns] CHECK 2 PASS: Da qua arm_delay, ENOUT = 1. Mach da bat dau dem!", $time);

        // =======================================================
        // BƯỚC 3: ĐỢI TIMEOUT ĐỂ CHỨNG MINH MẠCH THỰC SỰ CHẠY
        // =======================================================
        $display("\n[%0t ns] Dang doi 1650ms de xem mach co bat duoc loi khong...", $time);
        
        // Đợi 1650ms (vượt quá tWD = 1600ms một chút)
        #1_650_000_000;
        
        // Chấm điểm Bước 3
        if (led_d3_wdo == 1'b0)
            $display("[%0t ns] CHECK 3 PASS: WDO rot xuong 0 -> Mach da thuc su TỈNH DẬY va hoat dong!", $time);
        else
            $display("[%0t ns] CHECK 3 FAIL: WDO van muc 1 -> Mach bat len roi nhung khong chiu dem!", $time);

        // =======================================================
        // KẾT THÚC
        // =======================================================
        #100_000_000; 
        $display("\nMo phong hoan tat!");
        $stop;
    end

endmodule