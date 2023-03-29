include "macros.asm"
SECTION "Crash Handler ROM0", rom0
crash_handler::
    ld a, BANK(crash_handler_internal) ; load rom bank into a
    ld hl, crash_handler_internal ; load execution address into hl
    jp bankswitch_lazy_exec ; lazily switch banks

SECTION "Crash Hanlder Main", romx
crash_handler_internal:
    ; hello and welcome to the crash handler!
    ; we will be simply displaying a string at the top left that says
    ; "congratulations, your game has crashed!"
    loadstr crash_string ; load the crash string into the buffer
    displaystr $9800 ; display the base string to the screen
    ; also state where the crash came from
    pop bc ; get return address
    ld a, c
    cp $3B ; caused by rst38?
    jr rst38
.resume
    displaystr $9820 ; todo: get right adress
    jp freeze_cpu ; then just go freeze the cpu in place
rst38:
    loadstr rst38str
    jp crash_handler_internal.resume


freeze_cpu:
    jp freeze_cpu ; if we unfreeze for some reason, just loop more
