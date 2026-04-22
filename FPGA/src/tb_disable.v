//================Test disable=============//

`timescale 1ns / 1ps

module tb_disable();

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

    // 3. Tạo xung clock 27MHz
    initial begin
        clk = 0;
        forever #18.5 clk = ~clk;
    end

    // 4. Task Kick thời gian thực
    task press_kick;
        begin
            $display("[%0t ns] -> Thuc hien nhan nut S1 (Kick)...", $time);
            s1_wdi = 0; 
            
            #15_000_000; 
            
            s1_wdi = 1; 
            #1_000_000; // Nghỉ 1ms
            $display("[%0t ns] -> Da nha nut S1. Kick xong!", $time);
        end
    endtask

    // 5. Kịch bản mô phỏng chính
    initial begin
        $dumpfile("watchdog_disable.vcd");
        $dumpvars(0, tb_disable); 

        // =======================================================
        // BƯỚC 1: KHỞI TẠO (RESET)
        // =======================================================
        rst_n = 0;
        s1_wdi = 1;
        s2_en = 1; // S2 = 1 nghĩa là Active-Low đang nhả -> Watchdog tắt
        
        #1_000_000; 
        rst_n = 1; 
        $display("[%0t ns] He thong khoi dong.", $time);
        
        #10_000_000; 

        // =======================================================
        // BƯỚC 2: KIỂM TRA TRẠNG THÁI DISABLE
        // =======================================================
        $display("\n[%0t ns] Kiem tra trang thai Watchdog Disable.", $time);
        
        // Đợi để mạch ổn định
        #10_000_000; 
        
        if (led_d4_enout == 1'b0)
            $display("\n[%0t ns] PASS: Đèn ENOUT đang tắt (0) đúng như thiết kế.", $time);
        else
            $display("\n[%0t ns] FAIL: Đèn ENOUT sáng sai quy tắc!", $time);
        // =======================================================
        // BƯỚC 3: THỬ KICK VÀ ĐỢI TIMEOUT XEM CÓ BỊ LỖI KHÔNG
        // =======================================================
        $display("\n[%0t ns] Thu KICK trong khi dang Disable...", $time);
        press_kick();
        
        $display("\n[%0t ns] Dang doi 1800ms (Vuot qua tWD 1600ms) xem he thong co bao loi khong...", $time);
        // Đợi hẳn 1800ms (lớn hơn tWD 1600ms)
        #1_800_000_000;
        
        if (led_d3_wdo == 1'b1)
            $display("\n[%0t ns] PASS: WDO van la 1 (Khong bi Timeout vi dang Disable).", $time);
        else
            $display("\n[%0t ns] FAIL: WDO bi rot xuong 0!", $time);

        // =======================================================
        // KẾT THÚC
        // =======================================================
        #100_000_000;
        $display("\nMo phong hoan tat!");
        $stop;
    end

endmodule