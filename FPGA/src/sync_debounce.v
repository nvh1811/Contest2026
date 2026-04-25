module debounce_button #(
    parameter CLK_FREQ = 27_000_000,   
    parameter DEBOUNCE_TIME_MS = 15    
)(
    input wire clk, 
    input wire pb_1, // Nút nhấn vật lý (Active-Low: 0 = Bấm)
    
    // Đã đổi tên ngõ ra để hiện rõ chức năng và mức logic:
    output wire pb_level_high, // Trạng thái giữ mức (Active-High: 1 = Đang bấm)
    output wire pb_pulse_low   // Xung chớp nhoáng (Active-Low: 0 = Vừa bấm xuống)
);
    wire slow_clk_en;
    wire Q1, Q2, Q0;
    
    // Nút nhấn Active-Low -> Đảo thành Active-High (1 = Bấm) để đưa vào DFF
    wire n_pb_1 = ~pb_1; 
    
    clock_enable #(
        .CLK_FREQ(CLK_FREQ),
        .DEBOUNCE_TIME_MS(DEBOUNCE_TIME_MS)
    ) u1 (
        .clk(clk), 
        .slow_clk_en(slow_clk_en)
    );
    
    my_dff_en d0(clk, slow_clk_en, n_pb_1, Q0);
    my_dff_en d1(clk, slow_clk_en, Q0, Q1);
    my_dff_en d2(clk, slow_clk_en, Q1, Q2);
    
    // 1. Dành cho nút EN (Active-High):
    // Q2 đang lưu trạng thái 1 khi bấm. Trả thẳng Q2 ra ngoài.
    assign pb_level_high = Q2; 

    // 2. Dành cho nút KICK (Active-Low):
    // Bằng 0 CHỈ KHI: nhịp trước đó chưa bấm (Q2=0) VÀ nhịp này đang bấm (Q1=1).
    // Phép toán: ~1 | 0 = 0 | 0 = 0.
    assign pb_pulse_low = ~Q1 | Q2; 
    
endmodule
// ======================================================= //

module clock_enable #(
    parameter CLK_FREQ = 27_000_000,
    parameter DEBOUNCE_TIME_MS = 20
)(
    input clk, 
    output slow_clk_en
);
    // Dùng localparam để tính toán HẰNG SỐ lúc biên dịch phần mềm
    localparam MAX_COUNT = (CLK_FREQ / 1000) * DEBOUNCE_TIME_MS - 1;
    
    reg [$clog2(MAX_COUNT + 1)-1:0] counter = 0;
    
    always @(posedge clk) begin
       counter <= (counter >= MAX_COUNT) ? 0 : counter + 1;
    end
    
    assign slow_clk_en = (counter == MAX_COUNT) ? 1'b1 : 1'b0;
endmodule

// ======================================================= //

module my_dff_en(input DFF_CLOCK, input clock_enable, input D, output reg Q=0);
    always @ (posedge DFF_CLOCK) begin
        if(clock_enable == 1) 
           Q <= D;
    end
endmodule