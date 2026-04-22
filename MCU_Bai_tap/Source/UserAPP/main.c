#include <SN32F400.h>
#include <SN32F400_Def.h>
#include "..\Driver\GPIO.h"
#include "..\Driver\WDT.h"
#include "..\Driver\I2C.h"
#include "..\Driver\CT16B0.h" 
#include "..\Driver\CT16B1.h"
#include "..\Driver\Utility.h"
#include "..\Module\EEPROM.h"
#include "..\Module\Segment.h"
#include "..\Module\KeyScan.h"

extern uint8_t segment_buff[4];
extern const uint8_t SEGMENT_TABLE[];
extern uint8_t timer_1ms_flag;
extern void PFPA_Init(void);

#define KEY_SETUP  17   // SW3
#define KEY_ALARM  129  // SW16
#define KEY_UP     24   // SW6
#define KEY_DOWN   40   // SW10

#define EEPROM_WRITE_ADDR  0xA0
#define EEPROM_READ_ADDR   0xA1
#define EEPROM_ALARM_H_REG 0x00
#define EEPROM_ALARM_M_REG 0x01
#define SEG_DP             0x80 

typedef enum { MODE_NORMAL, MODE_SET_H, MODE_SET_M, MODE_AL_H, MODE_AL_M } SystemMode;
SystemMode current_mode = MODE_NORMAL;

int8_t hh = 0, mm = 0, ss = 0; // Thoi gian thuc [cite: 10, 13]
int8_t al_h = 0, al_m = 0;     // Thoi gian bao thuc [cite: 37]

uint32_t ms_count = 0;
uint32_t timeout_ms = 0;
uint32_t beep_timer_ms = 0;
uint32_t alarm_ring_ms = 0;
uint8_t blink_state = 0; 

// --- HAM I2C EEPROM ---
void EEPROM_Load_Alarm(void) {
    uint8_t data;
    eeprom_read(EEPROM_READ_ADDR, EEPROM_ALARM_H_REG, &data, 1);
    if (data < 24) al_h = data; else al_h = 0; 
    eeprom_read(EEPROM_READ_ADDR, EEPROM_ALARM_M_REG, &data, 1);
    if (data < 60) al_m = data; else al_m = 0;
}

void EEPROM_Save_Alarm(void) {
    uint8_t data = al_h; 
    eeprom_write(EEPROM_WRITE_ADDR, EEPROM_ALARM_H_REG, &data, 1);
    UT_DelayNms(10); 
    data = al_m; 
    eeprom_write(EEPROM_WRITE_ADDR, EEPROM_ALARM_M_REG, &data, 1);
    UT_DelayNms(10);
}

// --- HAM DIEU KHIEN COI BANG PWM CHUAN ---
void Buzzer_Task(void) {
    // Bao thuc keu 5s/chu ky (0.5s ON - 0.5s OFF) [cite: 31]
    if (alarm_ring_ms > 0) {
        alarm_ring_ms--;
        if ((alarm_ring_ms % 1000) >= 500) SN_CT16B0->MR0 = 1500; // ON (Duty 50%)
        else SN_CT16B0->MR0 = 0;                                  // OFF
        return; 
    }
    // Bip 0.3s (300ms) khi an nut hoac timeout [cite: 30, 32]
    if (beep_timer_ms > 0) {
        beep_timer_ms--;
        SN_CT16B0->MR0 = 1500; 
    } else {
        SN_CT16B0->MR0 = 0; 
    }
}

// --- HAM DIEU KHIEN LED D6 ACTIVE LOW ---
void LED_D6_Task(void) {
    // LED D6 chi nhay khi setup Bao Thuc [cite: 34]
    if (current_mode == MODE_AL_H || current_mode == MODE_AL_M) {
        if (blink_state) SN_GPIO3->BCLR = (1 << 8); // LOW = SANG
        else SN_GPIO3->BSET = (1 << 8);             // HIGH = TAT
    } else {
        SN_GPIO3->BSET = (1 << 8); // HIGH = TAT khi o trang thai khac [cite: 35]
    }
}

void Display_Update(void) {
    uint8_t d[4];
    
    if (current_mode == MODE_AL_H || current_mode == MODE_AL_M) {
        d[3] = al_h / 10; d[2] = al_h % 10;
        d[1] = al_m / 10; d[0] = al_m % 10;
    } else {
        d[3] = hh / 10; d[2] = hh % 10;
        d[1] = mm / 10; d[0] = mm % 10;
    }

    segment_buff[0] = SEGMENT_TABLE[d[3]];
    segment_buff[1] = SEGMENT_TABLE[d[2]];
    segment_buff[2] = SEGMENT_TABLE[d[1]];
    segment_buff[3] = SEGMENT_TABLE[d[0]];
    
    segment_buff[1] |= SEG_DP; 

    // Nhap nhay LED o che do Setup [cite: 15, 16, 19, 20]
    if (!blink_state) {
        if (current_mode == MODE_SET_H || current_mode == MODE_AL_H) {
            segment_buff[0] = 0; segment_buff[1] = 0; 
        } else if (current_mode == MODE_SET_M || current_mode == MODE_AL_M) {
            segment_buff[2] = 0; segment_buff[3] = 0; 
        }
    }
}

// --- CHUONG TRINH CHINH ---
int main(void) {
    uint16_t key_code;
    
    SN_WDT->CFG = 0x5AFA0000; 
    
    SystemInit();
    SystemCoreClockUpdate();
    PFPA_Init();
    SN_SYS0->EXRSTCTRL_b.RESETDIS = 0;
    
    GPIO_Init();
    I2C0_Init();
    
    // SETUP PWM CHO COI (P3.0) [cite: 29]
    CT16B0_Init();
    SN_PFPA->CT16B0_b.PWM0 = 1; // Map Timer0 PWM ra P3.0
    SN_CT16B0->MR9 = 3000;      // Tan so ~4kHz
    SN_CT16B0->MR0 = 0;         // Tat am thanh ban dau
    SN_CT16B0->TMRCTRL = 0; SN_CT16B0->TMRCTRL = 1; 

    // SETUP CHO LED D6 (P3.8 - Active Low) [cite: 33]
    SN_GPIO3->MODE |= (1 << 8); 
    SN_GPIO3->BSET = (1 << 8);  // Tat LED

    CT16B1_Init(); 
    EEPROM_Load_Alarm(); 
    
    while(1) {
        if(timer_1ms_flag) {
            timer_1ms_flag = 0;
            
            Digital_Scan();
            Buzzer_Task();
            LED_D6_Task();
            
            ms_count++;
            if (ms_count >= 1000) {
                ms_count = 0;
                ss++;
                if (ss >= 60) { ss = 0; mm++; } // Dem phut [cite: 12]
                if (mm >= 60) { mm = 0; hh++; } // Dem gio [cite: 12]
                if (hh >= 24) hh = 0; 
                
                // Kich hoat bao thuc neu trung gio/phut va dang o MODE_NORMAL
                if (current_mode == MODE_NORMAL && hh == al_h && mm == al_m && ss == 0) {
                    alarm_ring_ms = 5000; 
                }
            }
            
            blink_state = (ms_count < 500) ? 1 : 0;
            Display_Update();
            
            // TIMEOUT 30s THOAT CAI DAT [cite: 39]
            if (current_mode != MODE_NORMAL) {
                timeout_ms++;
                if (timeout_ms >= 30000) {
                    current_mode = MODE_NORMAL;
                    beep_timer_ms = 300; // Keu 0.3s khi thoat [cite: 32]
                    timeout_ms = 0;
                }
            }
            
            key_code = KeyScan();
            if (key_code) {
                if (key_code == KEY_SETUP || key_code == KEY_ALARM || key_code == KEY_UP || key_code == KEY_DOWN) {
                    timeout_ms = 0;      
                    alarm_ring_ms = 0;   
                    beep_timer_ms = 300; // KEU 0.3s MOI KHI AN NUT [cite: 30]
                    
                    switch(key_code) {
                        case KEY_SETUP:
                            if (current_mode == MODE_NORMAL) current_mode = MODE_SET_H; // [cite: 15]
                            else if (current_mode == MODE_SET_H) current_mode = MODE_SET_M; // [cite: 16]
                            else current_mode = MODE_NORMAL; // [cite: 17]
                            break;
                            
                        case KEY_ALARM:
                            if (current_mode == MODE_NORMAL) current_mode = MODE_AL_H; // [cite: 19]
                            else if (current_mode == MODE_AL_H) current_mode = MODE_AL_M; // [cite: 20]
                            else { 
                                current_mode = MODE_NORMAL; 
                                EEPROM_Save_Alarm(); // Luu thong so [cite: 21, 36]
                            }
                            break;
                            
                        case KEY_UP:
                            if (current_mode == MODE_SET_H) { hh++; if(hh>=24) hh=0; } // [cite: 23]
                            else if (current_mode == MODE_SET_M) { mm++; if(mm>=60) mm=0; } // [cite: 24]
                            else if (current_mode == MODE_AL_H)  { al_h++; if(al_h>=24) al_h=0; }
                            else if (current_mode == MODE_AL_M)  { al_m++; if(al_m>=60) al_m=0; }
                            break;
                            
                        case KEY_DOWN:
                            if (current_mode == MODE_SET_H) { hh--; if(hh<0) hh=23; } // [cite: 27]
                            else if (current_mode == MODE_SET_M) { mm--; if(mm<0) mm=59; } // [cite: 28]
                            else if (current_mode == MODE_AL_H)  { al_h--; if(al_h<0) al_h=23; }
                            else if (current_mode == MODE_AL_M)  { al_m--; if(al_m<0) al_m=59; }
                            break;
                    }
                }
            }
        }
    }
}