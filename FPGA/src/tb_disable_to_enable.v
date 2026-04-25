`timescale 1ns / 1ps

module tb_disable_to_enable();

    reg clk;
    reg s1_wdi;
    reg s2_en;

    wire led_d3_wdo;
    wire led_d4_enout;

    watchdog_top #(
        .CLK_FREQ(27_000_000) 
    ) dut (
        .clk(clk),
        .s1_wdi(s1_wdi),
        .s2_en(s2_en),
        .led_d3_wdo(led_d3_wdo),
        .led_d4_enout(led_d4_enout)
    );

    initial begin
        clk = 0;
        forever #18.5 clk = ~clk;
    end

    initial begin
        $dumpfile("watchdog_dis_to_en.vcd");
        $dumpvars(0, tb_disable_to_enable);

        // --- BƯỚC 1: KHỞI TẠO Ở TRẠNG THÁI TẮT ---
        s1_wdi = 1;
        s2_en = 1; // TẮT
        
        $display("\n[%0t ns] --- HE THONG KHOI DONG (DANG TAT) ---", $time);
        #50_000_000; 
        
        if (led_d4_enout == 1'b0)
            $display("[%0t ns] CHECK 1 PASS: He thong dang tat, ENOUT = 0.", $time);
        else
            $display("[%0t ns] CHECK 1 FAIL: ENOUT phai bang 0 khi dang tat!", $time);

        // --- BƯỚC 2: BẬT HỆ THỐNG ---
        $display("\n[%0t ns] --- TIEN HANH BAT WATCHDOG ---", $time);
        s2_en = 0; // BẬT

        wait(led_d4_enout == 1'b1);
        $display("[%0t ns] CHECK 2 PASS: Da qua arm_delay, ENOUT = 1. Mach da bat dau dem!", $time);

        // --- BƯỚC 3: ĐỢI TIMEOUT CHỨNG MINH ---
        $display("\n[%0t ns] Dang doi 1650ms de xem mach co bat duoc loi khong...", $time);
        #1_650_000_000;
        
        if (led_d3_wdo == 1'b0)
            $display("[%0t ns] CHECK 3 PASS: WDO rot xuong 0 -> Mach da thuc su TỈNH DẬY!", $time);
        else
            $display("[%0t ns] CHECK 3 FAIL: WDO van muc 1 -> Mach bat len roi nhung khong chiu dem!", $time);

        #100_000_000; 
        $display("\nMo phong hoan tat!");
        $stop;
    end
endmodule