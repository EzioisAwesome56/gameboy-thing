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
    jp run_mini_boss
    jp invalid_map_data

; updates position on script parser return
invalid_map_data:
    ld a, [wOverworldFlags] ; load the flags byte
    res 0, a ; resett bit 0
    set 1, a ; set the calculate pos bit
    ld [wOverworldFlags], a ; update the thing
    jp predef_exit ; leave


; heal the player to maximum hp and MP
heal:
    buffertextbox heal_text
    farcall do_textbox
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

; used to start a battle against a miniboxx (demo shit)
run_mini_boss:
    buffertextbox demo_opening ; buffer the opening textbox
    farcall do_textbox ; run the opening script
    buffertextbox demo_areyousure ; buffer next script
    farcall do_textbox ; run it
    farcall prompt_yes_no
    ld a, [wYesNoBoxSelection] ; load the selection into a
    cp 1 ; did they pick yes?
    jr z, .startboss
    jr .done ; otherwise, yeet
.startboss
    farcall clear_textbox ; empty the textbox
    farcall hide_textbox ; hide the textbox
    ld hl, blobcat_data
    ld a, bank(blobcat_data)
    call load_foe_data ; load the blobcat data into wram
    ld a, 17
    ld [wFoeLevel], a 
    farcall enter_battle_calls
    farcall do_battle ; run a battle
    farcall exit_battle_calls
    ld a, [wBattleState] ; load the state into a
    cp 2 ; did we lose?
    jr z, .lose
.done
    jp predef_exit ; yeet outta here
.lose
    rst $38