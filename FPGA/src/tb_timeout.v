`timescale 1ns / 1ps

module tb_timeout();

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
        $dumpfile("watchdog_timeout.vcd");
        $dumpvars(0, tb_timeout);

        // --- BƯỚC 1: KHỞI TẠO ---
        s1_wdi = 1;
        s2_en = 1; // Watchdog TẮT
        $display("[%0t ns] He thong khoi dong. EN dang tat.", $time);
        #10_000_000; 

        // --- BƯỚC 2: BẬT WATCHDOG ---
        $display("\n[%0t ns] Bat Watchdog (Keo S2 xuong 0 -> Core hieu la EN=1).", $time);
        s2_en = 0; 
        
        wait(led_d4_enout == 1'b1);
        $display("[%0t ns] Da qua arm_delay. ENOUT = 1. Bat dau dem tWD (1600ms)!", $time);

        // --- BƯỚC 3: TEST TIMEOUT ---
        $display("\n--- BAT DAU TEST TIMEOUT ---");
        #10_000_000;
        press_kick();
        
        $display("[%0t ns] Dang cho 1650ms de ep he thong bi Timeout...", $time);
        #1_650_000_000; 
        
        if (led_d3_wdo == 1'b0)
            $display("[%0t ns] TIMEOUT PASS: Da phat hien WDO keo xuong 0 dung luc!", $time);
        else
            $display("[%0t ns] TIMEOUT FAIL: Đa qua 1600ms ma WDO chua xuong 0!", $time);

        // --- BƯỚC 4: TEST RECOVERY ---
        $display("\n[%0t ns] Dang cho 210ms de he thong tu reset xong (tRST=200ms)...", $time);
        #210_000_000;
        
        if (led_d3_wdo == 1'b1)
            $display("[%0t ns] RECOVERY PASS: He thong da nha WDO ve 1 an toan.", $time);
        else
            $display("[%0t ns] RECOVERY FAIL: WDO van bi ket o muc 0!", $time);

        #100_000_000; 
        $display("\nMo phong hoan tat!");
        $stop;
    end
endmodule