#include "KeyScan.h"
#include "..\Driver\Utility.h"
#include <SN32F400.h>

#define KEY_SHORT_PUSH_TIME    50
#define KEY_DEBOUNCE_MAX_TIME  200

uint8_t key_check = 0;
uint8_t key_cvt = 0;
uint8_t key_debounce = 0;

/*****************************************************************************
* Function      : KeyScan
* Description   : Quet ma tran phim 4x4
* Input         : None
* Output        : None
* Return        : Ma phim duoc nhan (key_action)
*****************************************************************************/
uint16_t KeyScan(void)
{
    uint8_t key_col, key_row;  
    uint8_t key = 0;
    uint16_t key_action = 0;
    
    // ==========================================
    // BUOC 1: QUET COT (Read Column)
    // ==========================================
    // 1. Dat P2.4 ~ P2.7 lam Input 
    SN_GPIO2->MODE &= ~(0xf << 4);
    SN_GPIO2->CFG &= ~(0xff << 8); 
    
    // 2. Dat P1.4 ~ P1.7 lam Output Low
    SN_GPIO1->MODE |= (0xf << 4);
    SN_GPIO1->BCLR = (0xf << 4);
    
    // Cho dien ap o on dinh
    UT_DelayNx10us(1);
    
    // Doc trang thai P2.4 ~ P2.7
    key_col = (SN_GPIO2->DATA >> 4) & 0xf;
    
    // ==========================================
    // BUOC 2: QUET HANG (Read Row)
    // ==========================================
    // 1. Dat P1.4 ~ P1.7 lam Input 
    SN_GPIO1->MODE &= ~(0xf << 4);  
    SN_GPIO1->CFG &= ~(0xff << 8);  
    
    // 2. Dat P2.4 ~ P2.7 lam Output Low
    SN_GPIO2->MODE |= (0xf << 4);
    SN_GPIO2->BCLR = (0xf << 4);
    
    // Cho dien ap on dinh
    UT_DelayNx10us(1);
    
    // Doc trang thai P1.4 ~ P1.7
    key_row = SN_GPIO1->DATA & 0xf0;
    
    // ==========================================
    // BUOC 3: GHEP MA VA LOC NHIEU (Debounce)
    // ==========================================
    key = key_col | key_row;
    key ^= 0xff; // Dao bit de lay muc 1 khi co phim an
    
    // Neu trang thai phim thay doi so voi lan quet truoc
    if(key != key_check)
    {                       
        key_check = key;                                                
        key_debounce = 0;                                           
    }
    // Neu trang thai giu nguyen (dang nhan giu) -> Bat dau dem debounce
    else if(key_debounce < KEY_DEBOUNCE_MAX_TIME)
    {
        key_debounce++;
    
        // Khi dat du thoi gian chong nhieu (50ms)
        if(key_debounce == KEY_SHORT_PUSH_TIME)
        {
            key = key_check ^ key_cvt;                          
            key_cvt = key_check;
            
            if(key)
            {
                // Xac nhan day la su kien Nhan phim (Push) thay vi Nha phim (Pop)
                if(key & key_check)
                {
                    key_action = key;
                }
            }
        }
    }
    
    return key_action;
}
