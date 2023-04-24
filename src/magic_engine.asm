section "Magic Engine Code", romx
include "constants.asm"
include "macros.asm"

; starts the process of using magic within a battle
do_magic_battle::
    push de
    push hl ; back up shit
    push bc
    buffertextbox loading ; buffer loading string
    farcall do_textbox ; display it
    call init_battle_menu
    call enable_window
    call show_large_textbox
    buffertextbox magic_info_box ; buffer information box
    farcall clear_textbox ; clear out the textbox
    farcall do_textbox ; display it
    jr magic_menu_loop

; writes a value to signify a cancel and then exits
exit_via_cancel:
    ld a, 3 ; load 3 into a
    ld [wBattleState], a ; store it into battlestate
; exits the magic menu
exit_magic_menu:
    xor a ; load 0 into a
    ld [wOAMSpriteFour + 1], a ; hide the sprite
    call queue_oamdma ; update OAM
    call hide_large_textbox ; hide the textbox
    call clear_huge_textbox ; delete it
    pop bc
    pop hl ; pop everything off the stack
    pop de
    ret ; leave

; the main loop that runs the magic menu
magic_menu_loop:
    ld hl, joypad ; point hl at the joypad
.loop
    call select_buttons ; selection the action buttons
    ld a, [hl]
    ld a, [hl] ; get joypad input into a
    ld a, [hl]
    bit 1, a ; is B pressed?
    jp z, exit_via_cancel
    bit 0, a ; is a pressed?
    jr z, .abutton ; go deal with thatt
    call select_dpad ; select the dpad
    ld a, [hl]
    ld a, [hl] ; load the state of the dpad into a
    ld a, [hl]
    bit 3, a ; is down pressed?
    jr z, .down ; handle that
    bit 2, a ; is up pressed?
    jr z, .up ; handle pressing up
    jr .loop
.down
    ld a, [wMagicSelection] ; load a with the current selection
    inc a ; add 1
    cp 9 ; is is 10?
    call z, .fixmax
    jr .update ; run an update
.up
    ld a, [wMagicSelection] ; load current selection
    dec a ; add 1
    cp $FF ; did we underflowe?
    call z, .fixmin ; go fix it
    jr .update
.abutton
    call use_spell ; use the spell
    ld a, b ; load b into a
    cp 1 ; is it one?
    jr z, .exit
    jr nz, .loop ; loop if it failed
.fixmin
    xor a ; put 0 into a
    ret ; yeet
.fixmax
    ld a, 8 ; put 8 into a
    ret ; yeet
.update
    ld [wMagicSelection], a ; store it
    call update_arrow_selection ; update the selection arrow
    ld a, 78 ; load 78 into a
    ld [wSubLoopCount], a ; write it
    farcall waste_time
    jr .loop
.exit
    jp exit_magic_menu

; update which menu option the arrow is pointing at
update_arrow_selection:
    xor a ; load 0 into a
    ld c, a ; load 0 into a
    ld a, [wMagicSelection] ; load current selection into a
    ld b, a ; store the selection into b
    ld d, 8 ; load 8 into d
    ld e, magic_arrow_basey ; load base y into a
.loop
    ld a, c ; load c into a
    cp b ; is it equal to b?
    jr z, .done
    ld a, e ; load e into a
    add a, d ; add d to a
    ld e, a ; update e
    inc c ; add 1 to c
    jr .loop ; go loop
.done
    ld a, e ; load e into a
    ld [wOAMSpriteFour], a ; update sprite y
    call queue_oamdma ; cause a DMA transfer
    ret ; yeet

; use a spell based on selection
; returns 1 in b if it worked
use_spell:
    push hl ; backup hl
    ld a, [wMagicSelection] ; load selection into a
    ld hl, spell_jump_table ; point hl at the jump table
    ld c, 3 ; load 3 into c
    call simple_multiply ; A * C
    call sixteenbit_addition ; add a to HL
    jp hl ; jump to the position in the table
.spell_failed_notunlocked
    buffertextbox spell_not_unlocked
    farcall clear_textbox ; clear textbox
    farcall do_textbox ; display script
    jr .spell_failed
.spell_failed_nomp
    buffertextbox spell_no_mp
    farcall clear_textbox
    farcall do_textbox
.spell_failed
    ld b, 0 ; load 0 into b
    jr .done
.spell_casted
    ld b, 1 ; load 1 into b
    jr .done ; go to ret opcode
.done
    pop hl ; restore hl
    ret ; leave

; jump table for all of the spells
spell_jump_table:
    jp use_boost_def
    jp use_bless
    jp use_shieldbreak
    jp use_pillowinator
    ; below is all placeholder jumps
    jp use_spell.spell_failed
    jp use_spell.spell_failed
    jp use_spell.spell_failed
    jp use_spell.spell_failed
    jp use_spell.spell_failed

; casts the boost defense spell
use_boost_def:
    ld c, boostdef_mp_cost ; load c with mp cost
    call check_mp ; check if we have MP to use this
    ld a, b ; load b into a
    cp 1 ; do we not have the mp?
    jp z, use_spell.spell_failed_nomp ; leave this and say you dont have enough
    call subtract_mp ; subtract the mp from player's mp pool
    ld a, 4 ; load 4 into a
    ld [wBoostDefTurnsLeft], a ; update the counter
    buffertextbox spell_0_cast ; buffer the textbox content
    farcall clear_textbox ; empty the textbox
    farcall do_textbox ; run script
    jp use_spell.spell_casted ; jump back to main subroutine

; attempts to cast the bless spell
use_bless:
    ld a, [wUnlockedMagic] ; load the unlocked spell array
    bit 0, a ; is bit 0 set?
    jp z, use_spell.spell_failed_notunlocked
    ld c, bless_mp_cost ; load how much mp bless costs into c
    call check_mp ; check to see if we have enough mp
    ld a, b ; load b into a
    cp 1 ; do we not?
    jp z, use_spell.spell_failed_nomp ; oof
    call subtract_mp ; if yes, remove mp from the player
    call random ; get a random number
    ld c, 70 ; load 70 into c
    call simple_divide ; divides random number by 70 to get 0-69
    push af ; backup a
    ld a, [wPlayerHP] ; load high byte of player hp
    ld h, a ; put it into h
    ld a, [wPlayerHP + 1] ; load low byte
    ld l, a ; put it into l
    pop af ; restore our a value
    call sixteenbit_addition ; add a to hl
    ld a, [wPlayerMaxHP] ; load high byte
    ld b, a ; put into b
    ld a, [wPlayerMaxHP + 1] ; load low byte
    ld c, a ; write to c
    farcall check_hp_not_above_max ; check if not above max
    ld a, h ; load hight byte into a
    ld [wPlayerHP], a ; write to location
    ld a, l ; load low byte
    ld [wPlayerHP + 1], a ; write to location
    buffertextbox spell_1_cast ; buffer textbox script
    farcall clear_textbox ; clear textbox
    farcall do_textbox ; run the script
    jp use_spell.spell_casted ; jump back to main subroutine

; attempts to cast the bless spell
use_shieldbreak:
    ld a, [wUnlockedMagic] ; load the byte of the flags into a
    bit 1, a ; is the spell unlocked?
    jp z, use_spell.spell_failed_notunlocked ; if not, yeet
    ld c, shieldbreak_mp_cost ; load the mp cost into c
    call check_mp ; check if we have enough mp
    ld a, b ; load b into a
    cp 1 ; do we not have enough mp
    jp z, use_spell.spell_failed_nomp ; oof
    ld a, [wFoeAppliedStatus] ; load a with the shield flag
    bit 0, a ; have we already broken their sheild?
    jr nz, .cantbreakagain ; we cannot break their shield again
    call subtract_mp ; remove MP
    jr .jumpover
.cantbreakagain
    buffertextbox shield_already_broken ; buffer textbox content
    farcall clear_textbox ; clear contents of textbox
    farcall do_textbox ; show the string
    jp use_spell.spell_failed ; leave
.jumpover
    ld a, [wFoeDefense] ; load foe defense into a
    ld b, 5 ; load 5 into b
    sub a, b ; subtract 5 from a
    call c, setto0 ; if underflow, set a to 0
    ld [wFoeDefense], a ; update foe defense
    buffertextbox spell_2_cast ; buffer script
    farcall clear_textbox ; empty the textbox
    farcall do_textbox ; run the script
    xor a ; load 0 into a
    set 0, a ; set bit 0
    ld [wFoeAppliedStatus], a ; set the flag to 1
    jp use_spell.spell_casted ; jump back to main subroutine

; set a to 0
setto0:
    xor a ; set a to 0
    ret

; logic for casting the pillowinator spell
use_pillowinator:
    ld a, [wUnlockedMagic] ; load the unlocked magic byte into a
    bit 2, a ; have we unlocked it?
    jp z, use_spell.spell_failed_notunlocked ; if not, yeet
    ld c, pillow_mp_cost
    call check_mp ; check if we have enough MP to use this spell
    ld a, b ; load the result into a
    cp 1 ; did we fail the mp check?
    jp z, use_spell.spell_failed_nomp ; the player does not have enough MP
    ld a, [wFoeAppliedStatus] ; load the currently applied status into a
    bit 1, a ; has the foe been pillow'd already?
    jr nz, .cantapplyagain
    call subtract_mp ; remove the MP from the player
    ld a, [wFoeAttack] ; load the foe's attack into a
    sub 6 ; subtract 6 from a
    call c, setto0 ; put to 0 if it underflows
    ld [wFoeAttack], a ; update the foe's attack
    buffertextbox spell_3_cast ; buffer the string
    farcall clear_textbox ; empty the textbox
    farcall do_textbox ; run the textbox script
    xor a ; load 0 into a
    set 1, a ; set the applied_pillowinator flag to a
    ld [wFoeAppliedStatus], a
    jp use_spell.spell_casted ; jump back to main subroutine
.cantapplyagain
    buffertextbox foe_already_pillow ; buffer the already applied text
    farcall clear_textbox
    farcall do_textbox ; run the script
    jp use_spell.spell_failed ; yeetus

; subtract c mp from player's mp
subtract_mp:
    ld a, [wPlayerMP] ; load a with player's mp
    sub a, c ; subtract c from a
    ld [wPlayerMP], a ; store it back
    ret ; leave

; checks to see if the player has c mp
; puts 1 in b if not
check_mp:
    ld a, [wPlayerMP] ; load player mp into a
    cp c ; is a less then c
    jr c, .false
    jr .true
.false
    ld b, 1
    jr .done
.true
    ld b, 0
    jr .done
.done
    ret ; yeet
    

; scrolls the textbox up 96 pixels
show_large_textbox:
   ldh a, [window_y] ; load window y into a
   ld b, 96 ; load 96 into b
   halt ; wait for a vblank cycle
   sub a, b ; add b to a
   ldh [window_y], a ; update window position
   halt ; wait for vblank again
   ret ; leave

; removes the large textbox from view
hide_large_textbox:
    ldh a, [window_y] ; load window y pos into a
    ld b, 96 ; load 96 into b
    add a, b ; add b to a
    ldh [window_y], a ; write it back
    halt ; wait for vblank
    ret ; yeet

; prepare the magic menu
init_battle_menu:
    call init_clear_ram
    call clear_huge_textbox ; clear out the space for the huge textbox
    call disable_lcd
    call init_draw_massive_textbox ; draw it
    call init_drawn_known_spells
    call enable_lcd
    call init_move_arrow
    ret

; clears out the space where the huge textbox is drawn
clear_huge_textbox:
    ld hl, large_textbox_start ; point hl at the start of the large textbox area
    xor a ; 0 out a
    ld c, a ; put 0 into c
    ld d, a ; put 0 into d
    ld e, 32 ; lineskip magic
.loop
    ld a, c ; load c into a
    cp large_textbox_height ; have we cleared all the lines
    jr z, .done ; yeet
    ld a, CLEARFULLLINE ; load a with the magic value
    ld [wVBlankAction], a ; write it to our state holder thing
    halt ; wait for vblank
    add hl, de ; go to next line
    inc c ; add 1 to our counter
    jr .loop ; go loop some more
.done
    ret ; leave lol

; move menu arrow into the right place
init_move_arrow:
    ld a, 10 ; load x into a
    ld [wOAMSpriteFour + 1], a ; store it into memory
    ld a, magic_arrow_basey ; load the base arrow y position
    ld [wOAMSpriteFour], a ; write to buffer
    call queue_oamdma ; preform dma transfer
    ret ; leave

; clears out the ram we need
init_clear_ram:
    xor a ; put 0 into a
    ld [wMagicSelection], a ; put 0 into selection
    ret ; leave

; draws a fuckoff huge textbox
init_draw_massive_textbox:
    ld hl, large_textbox_start ; point de at the start of the textbox
    ld a, textbox_toplefttcorner ; load a with the top left corner graphic
    ld [hl], a ; write it to the tilemap
    ;updatetile ; make vblank do it
    inc hl ; move forward 1 byte
    ld d, textbox_topline ; load d with our tile
    ld e, 18 ; we need to draw it 18 times
    call tile_draw_loop ; draw it to the screen
    ld a, textbox_toprightcorner ; load the top right corner into a
    ld [hl], a ; write to tilemap
    ;updatetile ; make vblank do it
    inc hl ; move forward 1 byte
    call .nextline
    call .middle ; draw the middle portion of the textbox-
    ld a, textbox_bottomleft_corner ; load bottom left corner into a
    ld [hl], a ; store it into tile buffer
    ;updatetile ; update it
    inc hl ; move hl forward 1
    ld d, textbox_bottomline ; load d with the bottom line graphic index
    ld e, 18 ; we need to draw it 18 times
    call tile_draw_loop ; draw it to hl
    ld a, textbox_bottomright_corner ; load the bottom right corner
    ld [hl], a ; draw it to the screen
    ;updatetile ; by using vblank
    jr .retopc ; leave
.middle
    xor a ; 0 out a
    ld c, a ; put 0 into c
.midloop
    ld a, c ; load c into a
    cp 10 ; have we done this 10x?
    jr z, .retopc ; leave
    ld a, textbox_vertline_left ; load a with the left vertical line
    ld [hl], a ; write it to tilemap
    ;updatetile ; signal vblank to do it
    inc hl ; move hl forward 1
    ld d, 0 ; load 0 into d
    ld e, 18 ; load e with 18
    add hl, de ; add hl and de together
    ld a, textbox_vertline_right ; load a wqith the right vertical line
    ld [hl], a ; write to hl
    ;updatetile ; make vblank update it
    inc hl ; move forward 1 byte
    call .nextline ; move to next line
    inc c ; add 1 to our counter
    jr .midloop ; go loop
.nextline
    push de
    xor a ; 0 into a
    ld d, a ; put 0 into d
    ld e, 12 ; put 12 into e
    add hl, de ; add the two together
    pop de
.retopc
    ret ; yeet

; print known spells to the screen in the large textbox
; TODO: make spells display only if you have them unlocked
init_drawn_known_spells:
    xor a ; put 0 into a
    ld c, a ; put 0 into d
    ; spell 0 is always unlocked and visible
    loadstr spell_0_menudisplay ; load the menu display for spell 0
    call common_do_str
    inc c ; add 1 to c
    call draw_spell_1
    inc c ; move counter forward
    call draw_spell_2
    inc c
    call draw_spell_3
    inc c
    ret ; yeet

; adds 32 to base spell c times
realignhl:
    ld hl, spell0loc
    ld d, 0
    ld e, 32 ; make de be 32
    ld b, 0 ; load 0 into b
.loop
    ld a, b ; load b into a
    cp c ; have we looped enough?
    jr z, .done ; leave this routine
    add hl, de ; add de to hl
    inc b ; add 1 to b
    jr .loop ; go loop
.done
    ret ; yeet

; just so code does not have to be repeated
common_do_str:
    call realignhl
    ld de, wStringBuffer
    call strcpy
    ret

; checks if spell 1 is unlocked and draws it
draw_spell_1:
    ld a, [wUnlockedMagic] ; load the unlocked variable
    bit 0, a ; is bit 0 set?
    jr z, .done
    loadstr spell_1_menudisplay ; buffer spell 1 string
    call common_do_str
.done
    ret ; leave

draw_spell_2:
    ld a, [wUnlockedMagic] ; load the variable
    bit 1, a ; is bit 1 set?
    jr z, .done ; yeet
    loadstr spell_2_menudisplay ; load spell 2
    call common_do_str
.done
    ret ; yeet

draw_spell_3:
    ld a, [wUnlockedMagic] ; load the thing
    bit 2, a ; is bit 2 set?
    jr z, .done ; yeet
    loadstr spell_3_menudisplay
    call common_do_str
.done
    ret

; checks if the player has unlocked any new spells yet
unlock_new_spells::
    ld a, [wPlayerLevel] ; load player level into a
    cp 4 ; level 4?
    jr z, .bless
    cp 9 ; level 9?
    jr z, .shield
    cp 17 ; level 17?
    jr z, .pillow
    jr .exit ; no spells can be unlocked at this time
.bless
    ld a, [wUnlockedMagic]
    set 0, a ; unlock bless
    jr .unlock
.pillow
    ld a, [wUnlockedMagic]
    set 2, a ; unlock pillowinator
    jr .unlock
.shield
    ld a, [wUnlockedMagic]
    set 1, a ; unlock shieldbreak
    jr .unlock
.unlock
    push af ; backup AF
    buffertextbox levelup_new_spell ; buffer the text
    farcall do_textbox ; run the textbox
    pop af ; restore AF
    ld [wUnlockedMagic], a ; store the updated magic variable
.exit
    ret ; leave