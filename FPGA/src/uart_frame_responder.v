module uart_frame_responder (
    input wire clk,
    
    // --- Tín hiệu điều khiển từ Parser ---
    input wire trigger_send,      // Nối từ valid_frame_pulse của parser
    input wire [7:0] cmd_in,      // Nối từ valid_cmd
    input wire [7:0] addr_in,     // Nối từ valid_addr
    
    // --- Dữ liệu từ Tủ thanh ghi & Core ---
    input wire [31:0] twd_ms,
    input wire [31:0] trst_ms,
    input wire [15:0] arm_delay_us,
    input wire [31:0] status_reg, // Trạng thái của Watchdog
    
    // --- Giao tiếp với khối UART TX ---
    output reg tx_start = 0,
    output reg [7:0] tx_data = 0,
    input  wire tx_busy
);

    // FSM Gửi dữ liệu
    localparam IDLE      = 4'd0;
    localparam WAIT_TX   = 4'd1;
    localparam SEND_HDR  = 4'd2;
    localparam SEND_CMD  = 4'd3;
    localparam SEND_ADDR = 4'd4;
    localparam SEND_LEN  = 4'd5;
    localparam SEND_D3   = 4'd6; // Byte cao nhất
    localparam SEND_D2   = 4'd7;
    localparam SEND_D1   = 4'd8;
    localparam SEND_D0   = 4'd9; // Byte thấp nhất
    localparam SEND_CHK  = 4'd10;

    reg [3:0] state = IDLE;
    reg [3:0] next_state = IDLE;
    
    reg [7:0] calc_chk = 0;
    reg [31:0] data_to_send = 0;

    always @(posedge clk) begin
        // Tắt xung start tx nếu đang bật
        if (tx_start) tx_start <= 1'b0;

        case (state)
            IDLE: begin
                if (trigger_send) begin
                    // Lựa chọn dữ liệu để gửi đi dựa vào lệnh và địa chỉ
                    if (cmd_in == 8'h02) begin // Lệnh READ_REG
                        case (addr_in)
                            8'h04: data_to_send <= twd_ms;
                            8'h08: data_to_send <= trst_ms;
                            8'h0C: data_to_send <= {16'd0, arm_delay_us};
                            8'h10: data_to_send <= status_reg;
                            default: data_to_send <= 32'h00000000;
                        endcase
                    end 
                    else if (cmd_in == 8'h04) begin // Lệnh GET_STATUS nhanh
                        data_to_send <= status_reg;
                    end
                    else begin // Lệnh WRITE (0x01) hoặc KICK (0x03)
                        data_to_send <= 32'h4F4B4F4B; // Trả về chữ "OKOK"
                    end

                    state <= SEND_HDR;
                end
            end

            SEND_HDR: begin
                if (!tx_busy && !tx_start) begin
                    tx_data <= 8'h55;
                    tx_start <= 1'b1;
                    calc_chk <= 8'h00;
                    state <= WAIT_TX;
                    next_state <= SEND_CMD;
                end
            end

            SEND_CMD: begin
                if (!tx_busy && !tx_start) begin
                    tx_data <= cmd_in;
                    tx_start <= 1'b1;
                    calc_chk <= calc_chk ^ cmd_in;
                    state <= WAIT_TX;
                    next_state <= SEND_ADDR;
                end
            end

            SEND_ADDR: begin
                if (!tx_busy && !tx_start) begin
                    tx_data <= addr_in;
                    tx_start <= 1'b1;
                    calc_chk <= calc_chk ^ addr_in;
                    state <= WAIT_TX;
                    next_state <= SEND_LEN;
                end
            end

            SEND_LEN: begin
                if (!tx_busy && !tx_start) begin
                    tx_data <= 8'h04; // Luôn trả về 4 byte data
                    tx_start <= 1'b1;
                    calc_chk <= calc_chk ^ 8'h04;
                    state <= WAIT_TX;
                    next_state <= SEND_D3;
                end
            end

            SEND_D3: begin
                if (!tx_busy && !tx_start) begin
                    tx_data <= data_to_send[31:24];
                    tx_start <= 1'b1;
                    calc_chk <= calc_chk ^ data_to_send[31:24];
                    state <= WAIT_TX;
                    next_state <= SEND_D2;
                end
            end

            SEND_D2: begin
                if (!tx_busy && !tx_start) begin
                    tx_data <= data_to_send[23:16];
                    tx_start <= 1'b1;
                    calc_chk <= calc_chk ^ data_to_send[23:16];
                    state <= WAIT_TX;
                    next_state <= SEND_D1;
                end
            end

            SEND_D1: begin
                if (!tx_busy && !tx_start) begin
                    tx_data <= data_to_send[15:8];
                    tx_start <= 1'b1;
                    calc_chk <= calc_chk ^ data_to_send[15:8];
                    state <= WAIT_TX;
                    next_state <= SEND_D0;
                end
            end

            SEND_D0: begin
                if (!tx_busy && !tx_start) begin
                    tx_data <= data_to_send[7:0];
                    tx_start <= 1'b1;
                    calc_chk <= calc_chk ^ data_to_send[7:0];
                    state <= WAIT_TX;
                    next_state <= SEND_CHK;
                end
            end

            SEND_CHK: begin
                if (!tx_busy && !tx_start) begin
                    tx_data <= calc_chk; // Gửi mã bảo vệ đi
                    tx_start <= 1'b1;
                    state <= WAIT_TX;
                    next_state <= IDLE; // Gửi xong quay về nghỉ ngơi
                end
            end

            WAIT_TX: begin
                // Đợi cho khối uart_tx phát tín hiệu bận (busy) lên 1 rồi rơi xuống 0 mới đi tiếp
                if (!tx_busy && !tx_start) begin
                    state <= next_state;
                end
            end
        endcase
    end
endmodule