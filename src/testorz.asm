section "testing assembly routines", romx
include "macros.asm"
test_data:
    ld a, $03
    ld [wPlayerHP], a
    ld [wFoeHP], a
    ld a, $E7
    ld [wPlayerHP + 1], a
    ld [wFoeHP + 1], a
    ret

; copies test data into memory
setup_test_data::
    farcall copy_test_name
    call test_data
    ret 