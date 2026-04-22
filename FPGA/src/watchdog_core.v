
module watchdog_core #(
    parameter CLK_FREQ = 27_000_000, // Tang Nano 4K
    parameter TWD_MS = 1600,         
    parameter TRST_MS = 200,         
    parameter ARM_DELAY_US = 150     
)(
    input wire clk,
    input wire rst_n,
    
    // Đã sửa thành Active-low
    input wire en_n,       // 0 = Bật Watchdog, 1 = Tắt Watchdog
    input wire wdi_kick_n, // Xung mức 0 (thấp) = Có kick, 1 = Không kick
    
    output reg wdo,            
    output reg enout           
);

    localparam CYCLES_PER_MS = CLK_FREQ / 1000;
    localparam CYCLES_PER_US = CLK_FREQ / 1000_000;
    
    localparam MAX_TWD      = TWD_MS * CYCLES_PER_MS;
    localparam MAX_TRST     = TRST_MS * CYCLES_PER_MS;
    localparam MAX_ARM      = ARM_DELAY_US * CYCLES_PER_US;

    localparam IDLE       = 2'b00; 
    localparam ARMING     = 2'b01; 
    localparam MONITORING = 2'b10; 
    localparam FAULT      = 2'b11; 

    reg [1:0] state, next_state; 
    reg [31:0] timer;            

    // --- KHỐI BỘ NHỚ TRẠNG THÁI & TIMER (Sequential Logic) ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE; 
            timer <= 0;    
        end else begin
            // SNếu en_n == 1 (Nghĩa là nhả nút S2 -> Tắt)
            if (en_n == 1'b1) begin
                state <= IDLE; 
                timer <= 0;
            end else begin
                state <= next_state; 
                
                if (state != next_state) begin
                    timer <= 0; 
                end else begin
                    // Nếu có xung cạnh xuống (wdi_kick_n == 0)
                    if (state == MONITORING && wdi_kick_n == 1'b0) begin
                        timer <= 0; // Reset timer, cứu hệ thống
                    end else begin
                        timer <= timer + 1; 
                    end
                end
            end
        end
    end

    // --- KHỐI TÍNH TOÁN TRẠNG THÁI TIẾP THEO (Combinational Logic) ---
    always @(*) begin
        next_state = state; 
        
        case (state)
            IDLE: begin
                // Nếu nhấn nút S2 (en_n == 0) -> Chuyển sang ARMING
                if (en_n == 1'b0) next_state = ARMING;
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

    // --- KHỐI ĐIỀU KHIỂN NGÕ RA (Output Logic) ---
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