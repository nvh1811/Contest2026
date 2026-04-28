module uart_rx #(
    parameter CLK_FREQ = 27_000_000, // Tần số thạch anh (27MHz cho Tang Nano 4K)
    parameter BAUD_RATE = 9600       // Tốc độ truyền mặc định
)(
    input  wire clk,
    input  wire rx,          // Chân nhận tín hiệu từ ngoài vào
    output reg [7:0] rx_data, // Gói dữ liệu 1 byte vừa nhận
    output reg rx_done       // Cờ báo hiệu nhận xong (bật lên 1 chu kỳ clock)
);

    // Tính toán số chu kỳ clock cho 1 bit
    localparam CLOCKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    
    // Các trạng thái của FSM
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;
    
    reg [1:0] state = IDLE;
    reg [15:0] clk_count = 0;
    reg [2:0] bit_index = 0;
    
    // Chống nhiễu Metastability bằng 2 D-FF
    reg rx_sync_1 = 1'b1;
    reg rx_sync_2 = 1'b1;
    
    always @(posedge clk) begin
        rx_sync_1 <= rx;
        rx_sync_2 <= rx_sync_1;
    end
    
    always @(posedge clk) begin
        case (state)
            IDLE: begin
                rx_done <= 1'b0;
                if (rx_sync_2 == 1'b0) begin // Phát hiện cạnh xuống của bit Start
                    state <= START;
                    clk_count <= 0;
                end
            end
            
            START: begin
                // Đợi đến giữa chu kỳ của bit Start để kiểm tra lại
                if (clk_count == (CLOCKS_PER_BIT / 2)) begin
                    if (rx_sync_2 == 1'b0) begin
                        clk_count <= 0;
                        state <= DATA;
                    end else begin
                        state <= IDLE; // Bị nhiễu chớp nhoáng, quay về chờ
                    end
                end else begin
                    clk_count <= clk_count + 1;
                end
            end
            
            DATA: begin
                if (clk_count < CLOCKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    rx_data[bit_index] <= rx_sync_2; // Lấy mẫu ở giữa bit
                    if (bit_index < 7) begin
                        bit_index <= bit_index + 1;
                    end else begin
                        bit_index <= 0;
                        state <= STOP;
                    end
                end
            end
            
            STOP: begin
                if (clk_count < CLOCKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    rx_done <= 1'b1; // Kích hoạt cờ báo xong
                    clk_count <= 0;
                    state <= IDLE;
                end
            end
        endcase
    end
endmodule

module uart_tx #(
    parameter CLK_FREQ = 27_000_000,
    parameter BAUD_RATE = 9600
)(
    input  wire clk,
    input  wire tx_start,    // Xung kích hoạt gửi (tx_start = 1 => gửi)
    input  wire [7:0] tx_data, // Dữ liệu 8-bit cần gửi
    output reg tx = 1'b1,    // Chân truyền tín hiệu ra ngoài (Mặc định ở mức 1)
    output reg tx_busy       // Cờ báo hiệu đang bận truyền (tx = 1), không nhận thêm lệnh
);

    localparam CLOCKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;
    
    reg [1:0] state = IDLE;
    reg [15:0] clk_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] data_reg = 0;
    
    always @(posedge clk) begin
        case (state)
            IDLE: begin
                tx <= 1'b1; // Mức nhàn rỗi là 1
                tx_busy <= 1'b0;
                if (tx_start == 1'b1) begin
                    data_reg <= tx_data;
                    tx_busy <= 1'b1;
                    state <= START;
                    clk_count <= 0;
                end
            end
            
            START: begin
                tx <= 1'b0; // Kéo xuống 0 để tạo bit Start
                if (clk_count < CLOCKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    state <= DATA;
                end
            end
            
            DATA: begin
                tx <= data_reg[bit_index]; // Đẩy lần lượt các bit ra
                if (clk_count < CLOCKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    if (bit_index < 7) begin
                        bit_index <= bit_index + 1;
                    end else begin
                        bit_index <= 0;
                        state <= STOP;
                    end
                end
            end
            
            STOP: begin
                tx <= 1'b1; // Kéo lên 1 để tạo bit Stop
                if (clk_count < CLOCKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    state <= IDLE;
                end
            end
        endcase
    end
endmodule