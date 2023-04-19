section "PreDefined Functions", romx
include "constants.asm"
include "macros.asm"

; runs predefined routine B
run_predefined_routine::
    ld c, 3 ; load 3 into c
    ld a, b ; load b into a
    call simple_multiply ; A * C
    ld hl, predef_table ; point hl at the predefined table
    call sixteenbit_addition ; move hl to where it needs to go
    jp hl ; jump to hl

; exits the predef routine handler
predef_exit:
    ret ; leave



; jump table with all the predefined routines
predef_table:
    jp heal


; heal the player to maximum hp and MP
heal:
    farcall prompt_yes_no ; show them the yes/no prompt
    ld a, [wYesNoBoxSelection] ; load the selection into a
    cp 1 ; did they pick yes?
    jr z, .heal ; heal if yes
    jr .done ; leave if no
.heal
    ; restore hp
    ld a, [wPlayerMaxHP] ; load high byte into a
    ld [wPlayerHP], a ; write to high byte of current hp
    ld a, [wPlayerMaxHP + 1] ; low byte
    ld [wPlayerHP + 1], a ; update low byte
    ; restore mp
    ld a, [wPlayerMaxMP]
    ld [wPlayerMP], a ; restore MP too
    buffertextbox healed_text ; load the finishing text
    farcall clear_textbox
    farcall do_textbox ; run the text script
.done
    jp predef_exit ; leave predef land
