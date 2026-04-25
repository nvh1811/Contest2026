`timescale 1ns / 1ps

module tb_normal_kick();

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

    task press_kick;
        begin
            $display("[%0t ns] -> Thuc hien nhan nut S1 (Kick)...", $time);
            s1_wdi = 0; 
            #15_000_000; 
            s1_wdi = 1; 
            $display("[%0t ns] -> Da nha nut S1. Kick thanh cong!", $time);
        end
    endtask

    initial begin
        $dumpfile("watchdog_normal.vcd");
        $dumpvars(0, tb_normal_kick);

        // --- BƯỚC 1: KHỞI TẠO (Cấp điện) ---
        s1_wdi = 1;
        s2_en = 1; // Nhả nút S2 -> Top sẽ đảo thành EN = 0 -> Watchdog TẮT
        #1_000_000; 
        
        // --- BƯỚC 2: BẬT WATCHDOG ---
        s2_en = 0; // Bấm nút S2 -> Top sẽ đảo thành EN = 1 -> Watchdog BẬT
        $display("[%0t ns] He thong khoi dong. EN dang bat.", $time);
        
        wait(led_d4_enout == 1'b1);
        $display("[%0t ns] Da qua arm_delay. ENOUT = 1. Bat dau dem tWD (1600ms)!", $time);

        // --- BƯỚC 3: TEST NORMAL KICK ---
        $display("\n--- BAT DAU TEST NORMAL KICK ---");
        #10_000_000;
        press_kick();
        #1_000_000_000; 
        
        press_kick();
        #1_000_000_000; 
        
        press_kick();
        #1_000_000_000;

        if (led_d3_wdo == 1'b1)
            $display("[%0t ns] NORMAL KICK PASS: WDO dang giu muc 1 an toan.", $time);
        else
            $display("[%0t ns] NORMAL KICK FAIL: WDO bi rot xuong 0 sai quy tac!", $time);

        #100_000_000; 
        $display("\nMo phong hoan tat!");
        $stop;
    end
endmodule