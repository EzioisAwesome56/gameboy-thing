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
    jp slient_heal
    jp display_exclaim
    jp hide_player

; hides the player's sprite from the screen
hide_player:
    xor a ; 0 into a
    ld [wOAMSpriteOne], a ; write to player's y position
    call queue_oamdma ; update the position
    jp predef_exit

; displays a ! above the player's head
display_exclaim:
    ld a, [wPlayerx] ; load player's x coord into a
    call multiply_by_eight ; multiply a by 8 to get destination sprite coord
    add 8 ; add 8 to a, just to compensate for coord weirdness
    ld [wOAMSpriteFive + 1], a ; update OAM
    ld a, [wPlayery] ; load the current player y coord into a
    call multiply_by_eight ; get the real sprite y coord
    add 8 ; y is (x + 16), so just add 8 for 1 above player
    ld [wOAMSpriteFive], a ; update OAM
    ld a, $5a ; load the index of the exclaim tile into a
    ld [wOAMSpriteFive + 2], a ; write to the correct place
    call queue_oamdma ; update OAM
    push bc ; backup bc
    xor a ; 0 into a
    ld c, a ; 0 into c
.loop
    ld a, c ; load c into a
    cp 60 ; has it been 15 frames?
    jr z, .done ; yeet
    halt ; wait for a vblank cycle
    inc c ; add 1 to c
    jr .loop
.done
    pop bc  ; get bc off the stack
    xor a ; 0 into a
    ld [wOAMSpriteFive], a ; write 0 to y coord
    ld [wOAMSpriteFive + 1], a ; write 0 to x coord
    call queue_oamdma ; remove the sprite from the screen
    jp predef_exit ; leave

; updates position on script parser return
invalid_map_data:
    ld a, [wOverworldFlags] ; load the flags byte
    res 0, a ; resett bit 0
    set 1, a ; set the calculate pos bit
    ld [wOverworldFlags], a ; update the thing
    jp predef_exit ; leave

slient_heal:
    ld a, [wPlayerMaxHP] ; high byte
    ld [wPlayerHP], a
    ld a, [wPlayerMaxHP + 1] ; low byte
    ld [wPlayerHP + 1], a ; update
    ld a, [wPlayerMaxMP] ; magic is a single byte
    ld [wPlayerMP], a ; heal
    jr predef_exit


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
    ld a, [wCurrentMapBank] ; load a with the current map bank
    push de ; backup de
    ld de, wPlayerLastHealData ; point de at the start of the heal buffer
    ld [de], a ; write bank to de
    inc de ; next byte
    ld a, [wCurrentMapAddress] ; load current address
    ld [de], a ; write to memory
    inc de ; next byte please
    ld a, [wCurrentMapAddress + 1] ; low byte
    ld [de], a ; store into memory
    inc de ; move to player x
    ld a, [wPlayerx]
    ld [de], a ; write to player x
    inc de ; move to player y
    ld a, [wPlayery] ; get current y value
    ld [de], a ; write to memory
    pop de ; resttore de
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