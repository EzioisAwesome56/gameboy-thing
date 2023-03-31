include "macros.asm"
SECTION "Crash Handler ROM0", rom0
crash_handler::
    ld a, BANK(crash_handler_internal) ; load rom bank into a
    ld hl, crash_handler_internal ; load execution address into hl
    jp bankswitch_lazy_exec ; lazily switch banks

SECTION "Crash Handler Main", romx
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
    jr z, rst38
    cp $2B ; caused by rst2B?
    jr z, rst28
    cp $69 ; vba detected?
    jr z, VisualBoy
    cp $03
    jr z, rst00
.resume
    displaystr $9820 ; todo: get right adress
    jp freeze_cpu ; then just go freeze the cpu in place
rst38:
    loadstr rst38str
    jp crash_handler_internal.resume
rst28:
    loadstr rst28str
    jp crash_handler_internal.resume
VisualBoy:
    loadstr vba
    jp crash_handler_internal.resume
rst00:
    loadstr rst00str
    jp crash_handler_internal.resume

freeze_cpu:
    jp freeze_cpu ; if we unfreeze for some reason, just loop more
