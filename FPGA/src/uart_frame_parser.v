module frame_parser (
    input wire clk,
    
    // --- Giao tiếp với khối UART RX ---
    input wire rx_done,        // Cờ báo có byte mới
    input wire [7:0] rx_data,  // Giá trị byte vừa nhận
    
    // --- Các biến Tủ thanh ghi (Register Map) cấp cho Core ---
    output reg core_en = 0,         // bit 0 của CTRL
    output reg core_wdi_src = 0,    // bit 1 của CTRL
    output reg core_clr_fault = 0,  // bit 2 của CTRL
    output reg core_kick = 1,       // Xung Kick (Active-Low)
    output reg [31:0] twd_ms = 1600,// Mặc định 1600ms
    output reg [31:0] trst_ms = 200,// Mặc định 200ms
    output reg [15:0] arm_delay_us = 150, // Mặc định 150us
    output reg valid_frame_pulse = 0, // Xung chớp nhoáng báo có lệnh hợp lệ
    output reg [7:0] valid_cmd = 0,   // Lệnh vừa nhận được là gì
    output reg [7:0] valid_addr = 0   // Địa chỉ vừa thao tác là gì
);

    // Định nghĩa các trạng thái FSM
    localparam S_IDLE = 3'd0;
    localparam S_CMD  = 3'd1;
    localparam S_ADDR = 3'd2;
    localparam S_LEN  = 3'd3;
    localparam S_DATA = 3'd4;
    localparam S_CHK  = 3'd5;

    reg [2:0] state = S_IDLE;
    
    // Các biến lưu trữ tạm thời trong lúc bóc gói tin
    reg [7:0] cmd_reg;
    reg [7:0] addr_reg;
    reg [7:0] len_reg;
    reg [7:0] byte_count; // Đếm số byte data
    reg [31:0] data_buf;  // Khay chứa 32-bit data
    reg [7:0] calc_chk;   // Biến nháp tính XOR Checksum

    always @(posedge clk) begin
        // Tự động tắt xung báo hiệu sau 1 chu kỳ
        if (valid_frame_pulse) valid_frame_pulse <= 1'b0;
        // Reset lại xung kick về 1 (Inactive) sau 1 chu kỳ clock nếu nó vừa bị kéo xuống 0
        if (core_kick == 1'b0) core_kick <= 1'b1;

        if (rx_done) begin
            case (state)
                S_IDLE: begin
                    if (rx_data == 8'h55) begin // Bắt được Header 0x55
                        state <= S_CMD;
                        calc_chk <= 8'h00;
                    end else begin
                        state <= S_IDLE;
                    end 
                end
                
                S_CMD: begin
                    cmd_reg <= rx_data;
                    calc_chk <= calc_chk ^ rx_data; // Cộng dồn XOR
                    state <= S_ADDR;
                end
                
                S_ADDR: begin
                    addr_reg <= rx_data;
                    calc_chk <= calc_chk ^ rx_data;
                    state <= S_LEN;
                end
                
                S_LEN: begin
                    len_reg <= rx_data;
                    calc_chk <= calc_chk ^ rx_data;
                    byte_count <= 0;
                    data_buf <= 32'd0; // Rửa sạch khay chứa
                    
                    if (rx_data == 0) begin // Ví dụ lệnh KICK (len = 0)
                        state <= S_CHK;     // Bỏ qua DATA, nhảy tới CHK luôn
                    end else begin
                        state <= S_DATA;
                    end
                end
                
                S_DATA: begin
                    calc_chk <= calc_chk ^ rx_data;
                    // Dịch trái 8 bit và nhét byte mới vào đuôi
                    data_buf <= (data_buf << 8) | rx_data; 
                    
                    if (byte_count == len_reg - 1) begin // Đã gom đủ số byte
                        state <= S_CHK;
                    end else begin
                        byte_count <= byte_count + 1;
                    end
                end
                
                S_CHK: begin
                    // Đã nhận được CHK từ PC. Bắt đầu đối chiếu!
                    if (calc_chk == rx_data) begin
                        // >>> GÓI TIN HỢP LỆ <<<
                        
                        if (cmd_reg == 8'h03) begin 
                            // Lệnh KICK
                            core_kick <= 1'b0; // Bắn xung Active-Low
                        end 
                        else if (cmd_reg == 8'h01) begin 
                            // Lệnh WRITE (Ghi vào Register)
                            case (addr_reg)
                                8'h00: begin 
                                    core_en        <= data_buf[0]; // Bật/tắt Watchdog
                                    core_wdi_src   <= data_buf[1]; // Chọn nguồn đá chó
                                    core_clr_fault <= data_buf[2]; // Lệnh xóa lỗi
                                end
                                8'h04: twd_ms <= data_buf;      
                                8'h08: trst_ms <= data_buf;     
                                8'h0C: arm_delay_us <= data_buf[15:0]; 
                            endcase
                        end
                        valid_cmd <= cmd_reg;
                        valid_addr <= addr_reg;
                        valid_frame_pulse <= 1'b1; // Phát xung kích hoạt Responder
                    end 
                    // Dù đúng hay sai CHK, cuối cùng cũng quay về rình gói mới
                    state <= S_IDLE; 
                end
                
            endcase
        end
    end
endmodule