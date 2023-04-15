section "testing assembly routines", romx
include "macros.asm"
test_data:
    ld a, $00
    ld [wPlayerHP], a
    ld [wPlayerMaxHP], a
    ld a, $FF
    ld [wUnlockedMagic], a ; no magic unlocked for now
    ;ld [wFoeHP], a
    ld a, $C8
    ld [wPlayerHP + 1], a
    ld [wPlayerMaxHP + 1], a
    ;ld [wFoeHP + 1], a
    ld a, 6 ; load test player atk stat
    ld [wPlayerAttack], a ; store it into memory
    ld a, 4
    ld [wPlayerDefense], a 
    ; setup MP
    ld a, 25
    ld [wPlayerMP], a
    ld [wPlayerMaxMP], a
    ret

; copies test data into memory
setup_test_data::
    farcall copy_test_name
    call test_data
    ret 