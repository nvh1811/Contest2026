# Thiết kế Đồng hồ số (Digital Clock) - SN32F407 EVK

Dự án lập trình nhúng bare-metal xây dựng hệ thống đồng hồ số thời gian thực, tích hợp báo thức và lưu trữ dữ liệu không bay hơi (EEPROM) cho board mạch SN32F407 EVK.

## 1. Yêu cầu phần cứng (Hardware Specifications)
- **Vi điều khiển:** Bo mạch SN32F407 EVK (ARM Cortex-M0).
- **Hiển thị:** 4 LED 7 đoạn (Định dạng hiển thị: `HH.MM`).
- **Nút bấm:** Ma trận phím 4x4 (Sử dụng SW3, SW6, SW10, SW16).
- **Âm thanh:** Còi thụ động (Passive Buzzer).
- **Chỉ báo:** LED D6 (Sử dụng báo hiệu chế độ hẹn giờ).

## 2. Phân bổ chân ngoại vi (Pinout & Hardware Mapping)

| Cụm ngoại vi | Chân Vi điều khiển | Chức năng cấu hình |
| :--- | :--- | :--- |
| **Buzzer** | `P3.0` | Output PWM (CT16B0) - Tần số 4kHz |
| **LED D6** | `P3.8` | Output (Active Low - Mức thấp là Sáng) |
| **Key Matrix (Cột)** | `P2.4 - P2.7` | Input Pull-up |
| **Key Matrix (Hàng)** | `P1.4 - P1.7` | Output Low |
| **LED 7 đoạn** | Theo thư viện `Segment.h` | Quét đa hợp (Multiplexing) |

#### 3. Máy trạng thái hữu hạn (Finite State Machine - FSM)
Logic điều phối được tổ chức thành 5 trạng thái độc lập để quản lý các chế độ hiển thị và cài đặt:

| Trạng thái (Mode) | Chức năng | Phản hồi phần cứng |
| :--- | :--- | :--- |
| **MODE_NORMAL** | Chế độ đếm giờ mặc định | LED 7 đoạn sáng tĩnh hiển thị thời gian thực. |
| **MODE_SET_H** | Cài đặt giờ hệ thống | Hai chữ số giờ (HH) nhấp nháy 1Hz. |
| **MODE_SET_M** | Cài đặt phút hệ thống | Hai chữ số phút (MM) nhấp nháy 1Hz. |
| **MODE_AL_H** | Cài đặt giờ báo thức | LED Giờ nhấp nháy + LED D6 nhấp nháy 1Hz. |
| **MODE_AL_M** | Cài đặt phút báo thức | LED Phút nhấp nháy + LED D6 nhấp nháy 1Hz. |

**Sơ đồ chuyển đổi trạng thái FSM:**

<img width="2684" height="1680" alt="image" src="https://github.com/user-attachments/assets/94026245-2951-460d-ba88-e853f683e71d" />


## 4. Hướng dẫn sử dụng (Usage)
- **Khởi động:** Cấp nguồn, mạch hiển thị `00.00`.
- **Nút SETUP (SW3):** Nhấn để luân chuyển giữa các chế độ chỉnh Giờ -> chỉnh Phút -> thoát về chế độ thường.
- **Nút HẸN GIỜ (SW16):** Nhấn để vào chế độ chỉnh Giờ hẹn -> chỉnh Phút hẹn -> thoát (tự động lưu vào EEPROM).
- **Nút Tăng (SW6) / Giảm (SW10):** Thay đổi giá trị thời gian trong các chế độ cài đặt.
- **Báo thức:** Khi đến giờ hẹn, còi kêu "pip-pip" liên tục trong 5 giây. 
- **Phản hồi âm thanh:** Còi kêu "pip" 0.3 giây mỗi khi nhấn nút hoặc khi thoát chế độ cài đặt (do nhấn nút hoặc do timeout).
