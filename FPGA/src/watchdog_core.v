module watchdog_core #(
    parameter CLK_FREQ = 27_000_000 
)(
    input  wire clk,
    input  wire en,         // 1 = Bật Watchdog,  0 = Tắt Watchdog
    input  wire wdi_kick_n, // Xung mức 0 = Có kick, 1 = Không kick
    
    // --- THÊM 3 DÂY NÀY ĐỂ NHẬN CẤU HÌNH TỪ UART ---
    input  wire [31:0] twd_ms,       
    input  wire [31:0] trst_ms,      
    input  wire [15:0] arm_delay_us, 
    
    output reg wdo,            
    output reg enout           
);

    localparam CYCLES_PER_MS = CLK_FREQ / 1000;
    localparam CYCLES_PER_US = CLK_FREQ / 1000_000;
    
    // SỬA: Đổi từ localparam sang wire để FPGA tự nhân (Multiplier) liên tục
    wire [63:0] MAX_TWD  = twd_ms * CYCLES_PER_MS;
    wire [63:0] MAX_TRST = trst_ms * CYCLES_PER_MS;
    wire [31:0] MAX_ARM  = arm_delay_us * CYCLES_PER_US;

    localparam IDLE       = 2'b00; 
    localparam ARMING     = 2'b01; 
    localparam MONITORING = 2'b10; 
    localparam FAULT      = 2'b11;

    // Cấp giá trị mặc định lúc khởi động thay cho rst_n
    reg [1:0] state = IDLE; 
    reg [1:0] next_state; 
    reg [31:0] timer = 0;            

    // --- KHỐI 1: BỘ NHỚ TRẠNG THÁI & TIMER (Sequential Logic) ---
    always @(posedge clk) begin
        // Reset mềm bằng nút EN
        if (en == 1'b0) begin
            state <= IDLE; 
            timer <= 0;
        end else begin
            state <= next_state; 
            
            // Xử lý bộ đếm Timer
            if (state != next_state) begin
                timer <= 0; // Reset khi đổi trạng thái
            end else begin
                // Xử lý đá chó
                if (state == MONITORING && wdi_kick_n == 1'b0) begin
                    timer <= 0; 
                end else begin
                    timer <= timer + 1; 
                end
            end
        end
    end

    // --- KHỐI 2: TÍNH TOÁN TRẠNG THÁI TIẾP THEO (Combinational Logic) ---
    always @(*) begin
        next_state = state; 
        
        case (state)
            IDLE: begin
                if (en == 1'b1) next_state = ARMING;
            end
            ARMING: begin
                if (timer >= MAX_ARM - 1) next_state = MONITORING;
            end
            MONITORING: begin
                if (timer >= MAX_TWD - 1) next_state = FAULT;
            end
            FAULT: begin
                if (timer >= MAX_TRST - 1) next_state = MONITORING;
            end
        endcase
    end

    // --- KHỐI 3: ĐIỀU KHIỂN NGÕ RA (Output Logic) ---
    always @(*) begin
        wdo = 1'b1;   
        enout = 1'b0; 
        
        case (state)
            MONITORING: begin
                wdo = 1'b1;
                enout = 1'b1; 
            end
            FAULT: begin
                wdo = 1'b0;   
                enout = 1'b1; 
            end
        endcase
    end
endmodule