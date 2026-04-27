/*
struct tree
    main.c:       initial, main loop and FSM logic (Finite State Machine)
    PFPA.c:       pin function routing (set P3.0 for PWM CT16B0)
    GPIO.c:       initial gpio pin for LED D6 and Key Matrix
    WDT.c:        disable watchdog timer
    CT16B0.c:     initial timer 0 for buzzer PWM (4kHz)
    CT16B1.c:     initial timer 1 for 1ms interrupt task scheduling
    I2C.c:        initial I2C0 peripheral for EEPROM
    utility.c:    delay functions

    keyscan.c:    scan key matrix with software debounce
    segment.c:    display HH.MM with multiplexing
    eeprom.c:     eeprom R/W process for alarm data

function:
    1. keyscan input control
       KEY_SETUP (SW3):  switch FSM mode (NORMAL -> SET_H -> SET_M)
       KEY_ALARM (SW16): switch FSM mode (AL_H -> AL_M -> Save EEPROM)
       KEY_UP (SW6):     increase time value
       KEY_DOWN (SW10):  decrease time value

    2. display real-time and alarm time (HH.MM format)

    3. alarm execution
       trigger buzzer with PWM and save configuration to EEPROM

    note: auto timeout 30s to return MODE_NORMAL
*/