// 1. Khai báo parameter trong dấu #()
module debounce_button #(
    parameter CLK_FREQ = 27_000_000,   
    parameter DEBOUNCE_TIME_MS = 10    
)(
    input clk, 
    input pb_1, 
    
    // Thêm 2 ngõ ra phân biệt rõ ràng:
    output pb_level, // Tín hiệu trạng thái giữ mức (Active-Low giống nút thật)
    output pb_pulse  // Tín hiệu xung 20ms báo có nhịp bấm (Active-High)
);
    wire slow_clk_en;
    wire Q1, Q2, Q0;
    wire n_pb_1 = ~pb_1; // Nút nhấn Active-Low -> Đảo thành Active-High
    
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
    
    // 1. Dành cho nút EN: Trả về trạng thái ổn định.
    // Vì n_pb_1 là active-high, Q2 là active-high. Ta đảo ngược lại (~Q2) để trả về Active-Low.
    assign pb_level = ~Q2; 

    // 2. Dành cho nút KICK: Tạo xung báo cạnh lên (khi người dùng bấm xuống).
    // Bằng 1 CHỈ KHI: nhịp trước đó chưa bấm (Q2=0) VÀ nhịp này đang bấm (Q1=1).
    assign pb_pulse = ~Q1 | Q2; 
    
endmodule
// ======================================================= //

module clock_enable #(
    parameter CLK_FREQ = 27_000_000,
    parameter DEBOUNCE_TIME_MS = 20
)(
    input clk, 
    output slow_clk_en
);
    // 3. Dùng localparam để tính toán HẰNG SỐ lúc biên dịch phần mềm
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