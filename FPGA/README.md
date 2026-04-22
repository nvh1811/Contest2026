# FPGA Watchdog Timer (Mô phỏng TPS3431) trên Tang Nano 4K

**Sinh viên thực hiện:** [Tên của em]
**Mã sinh viên:** [Mã SV của em]
**Môn học / Cuộc thi:** [Tên cuộc thi hoặc môn học]
**Board phát triển:** Gowin Tang Nano 4K (Thạch anh 27MHz)

---

## 1. Giới thiệu Dự án
Dự án này triển khai thiết kế lõi IP mô phỏng hoạt động của IC Watchdog Timer (tương tự TPS3431) trên FPGA. Hệ thống có nhiệm vụ giám sát tín hiệu "nhịp tim" (WDI) từ một hệ thống khác và xuất tín hiệu cảnh báo (WDO) nếu xảy ra sự cố treo máy (Timeout).

Hệ thống được thiết kế hoàn toàn bằng Verilog HDL, áp dụng máy trạng thái hữu hạn (FSM) và được kiểm chứng toàn diện (Verification) thông qua phần mềm ModelSim với nhiều kịch bản hoạt động thực tế.

---

## 2. Cấu trúc Mô-đun (System Architecture)
Hệ thống được chia thành các mô-đun phân cấp để tối ưu hoá việc tái sử dụng code:

* **`watchdog_top.v`**: Mô-đun cấp cao nhất (Top-level). Nơi kết nối lõi Watchdog với các ngoại vi vật lý (nút nhấn, đèn LED) trên board.
* **`watchdog_core.v`**: Lõi FSM điều khiển logic chính của Watchdog. Quản lý 4 trạng thái: `IDLE` (Nghỉ), `ARMING` (Khởi động), `MONITORING` (Giám sát) và `FAULT` (Báo lỗi).
* **`debounce_button.v`**: Khối lọc nhiễu nút nhấn (Debounce).
    * Sử dụng kỹ thuật thanh ghi dịch (Shift Register) kết hợp xung clock chậm.
    * Bộ đếm được tham số hoá toàn phần bằng hàm `$clog2()`, chống tràn bit ở mọi tần số cấu hình. Cung cấp cả tín hiệu giữ mức (Level) và xung nhọn (Pulse) bằng định lý De Morgan.
    * *Các mô-đun con:* `clock_enable.v`, `my_dff_en.v`.

---

## 3. Lựa chọn Thiết kế & Kỹ thuật (Design Decisions)

### 3.1. Đồng bộ Logic phần cứng (Active-Low)
Để bám sát với phần cứng thực tế (nút nhấn kéo xuống GND khi bấm), lõi `watchdog_core` được thiết kế để giao tiếp hoàn toàn bằng logic **Active-Low** (`en_n`, `wdi_kick_n`). Mô-đun Debounce đảm nhiệm việc xuất ra xung Active-Low chính xác mà không cần dùng cổng NOT rườm rà ở cấp Top, giúp mạch chạy ổn định và tiết kiệm tài nguyên (LUTs).

### 3.2. Mô phỏng ngõ ra Open-Drain của TPS3431
*(Yêu cầu theo đề bài 4.3)*
Trong dự án này, em lựa chọn phương pháp **B) Đơn giản hoá** để thiết kế ngõ ra cho tín hiệu WDO và ENOUT. 
Thay vì sử dụng chân `inout` và trạng thái trở kháng cao (`1'bz`) để mô phỏng ngõ ra Open-Drain vật lý, em sử dụng ngõ ra **Push-Pull** tiêu chuẩn của FPGA để xuất tín hiệu. Tuy nhiên, em vẫn đảm bảo tuân thủ tuyệt đối quy ước logic của chip TPS3431:
* **WDO (Active-Low):** Chủ động xuất mức 0 (`1'b0`) khi xảy ra lỗi Timeout (tWD > 1600ms) để kéo sáng LED báo lỗi, và xuất mức 1 (`1'b1`) ở trạng thái bình thường.
    * Quy ước: Led sáng, hệ thống bình thường; led tắt thì hệ thống bị timeout
* **ENOUT:** Xuất logic hợp lệ (1 hoặc 0) theo đúng giản đồ thời gian quy định để điều khiển LED trạng thái.
Phương pháp này giúp thiết kế ổn định, code RTL sạch sẽ, dễ dàng kiểm chứng trên Testbench và hoạt động hoàn hảo khi nạp trực tiếp lên các LED tích hợp sẵn trên board Tang Nano 4K.
    * Quy ước: ENOUT = 1, báo hiệu hệ thống đang chạy

---

## 4. Kịch bản Kiểm chứng (Testbenches)
Dự án đính kèm 4 file Testbench giả lập môi trường thực tế (Real-time simulation) với đầy đủ thông số delay (Debounce 20ms, Arm_delay 150us, tWD 1600ms, tRST 200ms).

1.  **`tb_normal_kick.v`**: Đóng vai trò hệ thống khoẻ mạnh. Định kỳ "đá chó" (Kick) mỗi 1 giây. Kết quả: WDO luôn giữ mức 1 an toàn.
2.  **`tb_timeout.v`**: Giả lập lỗi treo máy. Hệ thống bỏ đói Watchdog. Kết quả: Phát hiện WDO sụp xuống 0 chính xác ở mốc 1.6 giây, và tự phục hồi (Recovery) về mức 1 sau 200ms (tRST).
3.  **`tb_disable.v`**: Kịch bản vô hiệu hoá (EN = 1). Dù hệ thống không có tín hiệu Kick nào qua 1.6 giây, WDO vẫn không báo lỗi (không bị kéo xuống 0) do Watchdog đang ngủ. Đèn ENOUT tắt hoàn toàn.
4.  **`tb_disable_to_enable.v`**: Kịch bản chuyển đổi trạng thái (Transition). Đánh thức FSM từ trạng thái IDLE sang MONITORING thành công và kích hoạt báo lỗi WDO chính xác.

---

## 5. Hướng dẫn Biên dịch và Chạy Mô phỏng

**Yêu cầu phần mềm:**
* Gowin FPGA Designer (V1.9.9 hoặc mới hơn)
* ModelSim (Intel/Altera hoặc Standalone)

**Các bước chạy Mô phỏng (Simulation):**
1. Mở ModelSim và chuyển thư mục làm việc (Change Directory) đến thư mục `/src`.
2. Chạy lệnh Compile toàn bộ các file `.v`: `vlog *.v`
3. Gọi mô phỏng một testbench bất kỳ (ví dụ Test Timeout): `vsim work.tb_timeout`
4. Kéo các tín hiệu cần xem từ cửa sổ *Objects* vào cửa sổ *Wave*.
5. Gõ lệnh `run -all` để bộ mô phỏng chạy và tự động tạm dừng ở lệnh `$stop`.
6. Dùng nút **Zoom Full** trên màn hình Waveform để quan sát toàn cảnh tín hiệu.