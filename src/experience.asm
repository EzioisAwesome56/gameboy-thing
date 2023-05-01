section "Experience handler", romx
include "macros.asm"
include "constants.asm"

; check if a player has enough experience to level up
check_for_levelup::
    push hl
    push bc ; backup registers
    ld a, [wExperienceForNext] ; load high byte into a
    ld d, a ; store it into d
    ld a, [wExperienceForNext + 1] ; load low byte into a
    ld e, a ; store it into e
    ld a, [wCurrentExperiencePoints] ; loadhigh byte of experience points into a
    ld h, a ; store into h
    ld a, [wCurrentExperiencePoints + 1] ; load low byte of EXP into a
    ld l, a ; store it into l
    ; first we check the hight byte
    ld a, h ; put high byte back into h
    cp d ; compare to d
    jr z, .checklow ; check low if equal too the highbyte
    jp c, exit_experience ; exit if is it less than
    jp do_level_up ; if its greater than the high byte, automatic level up
.checklow
    ld a, l ; load load byte into a
    cp e ; compare against e
    jp nc, do_level_up ; if >=, do level up[
    jp exit_experience ; otherwise, leave

; exit this routine
exit_experience:
    pop bc
    pop hl
    ret ; yeetus

; preformed a level up
do_level_up:
    buffertextbox level_up_box ; buffer our text
    farcall clear_textbox ; empty out the textbox
    farcall do_textbox ; display to the screen
    call init_draw_statsbox ; draw the statsbox to the window
    call show_statsbox
    call levelup_hp ; level up HP stat
    call levelup_mp ; level up MP stat
    call levelup_atk ; level up atk stat
    call levelup_def ; level up the defense stat
    buffertextbox level_up_afterstats ; buffer level printing texttbox
    ld a, [wPlayerLevel] ; load current level into a
    inc a ; add 1
    push af ; backup
    call number_to_string ; convert to string
    pop af ; restore a
    ld [wPlayerLevel], a ; write back into wram
    farcall do_textbox ; run the script
    call player_select_booststat ; allow the player to pick a stat to boost
    farcall clear_textbox
    call hide_statbox
    call remove_statbox
    call remove_experience ; remove experience from the player
    call update_experience_requirements ; update the required amount of experience
    farcall unlock_new_spells ; check to see if we can unlock new spells
    jp exit_experience ; yeetus

; slide the stats box 48 pixels up
show_statsbox:
    ld b, 4 ; load 12 into b
    xor a ; 0 into a
    ld c, a ; load 0 into c
    ld hl, window_y ; point hl at window y
.loop
    ld a, c ; load c into a
    cp 12 ; have we done this 12 times?
    jr z, .done ; yeet if so
    halt ; wait for vblank
    dec [hl]
    dec [hl]
    dec [hl] ; subtract 4 from the window y register
    dec [hl]
    inc c ; add 1 to c
    jr .loop ; go loop
.done
    ret ; leave

; slide the statbox 48 pixels down
hide_statbox:
    ld b, 4
    xor a
    ld c, a
    ld hl, window_y
.loop
    ld a, c
    cp 12
    jr z, .done
    halt
    inc [hl]
    inc [hl]
    inc [hl]
    inc [hl]
    inc c
    jr .loop
.done
    ret

; removes experience points that where used for this level up
remove_experience:
    ld a, [wCurrentExperiencePoints] ; load high byte
    ld h, a ; store into h
    ld a, [wCurrentExperiencePoints + 1] ; load low byte
    ld l, a ; store to l
    ld a, [wExperienceForNext] ; load high byte into a
    ld d, a ; store into d
    ld a, [wExperienceForNext + 1] ; load low byte
    ld e, a ; store into e
    call sixteen_sixteen_subtraction ; HL - DE
    ld a, h ; h into a
    ld [wCurrentExperiencePoints], a ; update high byte
    ld a, l ; l into a
    ld [wCurrentExperiencePoints + 1], a ; update low byte
    ret ; we've finished, so leave

; updates wExperienceForNext to be something
update_experience_requirements:
    ; first, load the current variable into hl
    ld a, [wExperienceForNext] ; high byte
    ld h, a ; into h
    ld a, [wExperienceForNext + 1] ; low byte
    ld l, a ; into l
    ld a, [wPlayerLevel] ; load the player's level into a
    cp 10 ; is the player's level 10
    jr c, .below10 ; if below, go here
    cp 25 ; is it 25?
    jr c, .below25
    cp 35 ; is it 35?
    jr c, .below35
    jr .everythingelse
.below10
    ld a, 16
    jr .addreq
.below25
    ld a, 32
    jr .addreq
.below35
    ld a, 64
    jr .addreq
.everythingelse
    ld a, 255
    jr .addreq
.addreq
    ld b, 0 ; load 0 into b
    ld c, a ; put a into c
    add hl, bc ; add bc to hl
    call c, fixoverflow16
    ld a, h ; h into a
    ld [wExperienceForNext], a ; update high byte
    ld a, l
    ld [wExperienceForNext + 1], a ; update low byte
    ret ; leave 

; sets hl to $FFFF
fixoverflow16:
    ld hl, $FFFF
    ret

; removes the statbox from vram
remove_statbox:
    ld hl, start_totalstatbox
    xor a ; 0 into a
    ld c, a ; load 0 into c
    ld d, a ; 0 into d
    ld e, 32 ; lineskip magic
.loop
    ld a, c ; load c into a
    cp 6 ; have we done this 6 times?
    jr z, .exit
    ld a, CLEARFULLLINE ; load a with the magic
    ld [wVBlankAction], a ; store into action var
    halt ; wait for vblank
    add hl, de ; add de to hl
    inc c
    jr .loop
.exit
    ret ; leave

; draws the box that lists all player stats
init_draw_statsbox:
    ld hl, start_totalstatbox ; point hl at the starting address
    ld b, 13 ; 13 long
    ld c, 6 ; 6 tall
    farcall draw_textbox_improved ; funni memes
    ret ; leave

; moves a converted number to wTempBuffer
move_num_to_buffer:
    ld hl, wStringBuffer ; hl at source
    ld de, wTempBuffer ; de at desitnation
    ld b, 3 ; 3 bytes need to be copied
    jr move_global
move_buffer_to_string:
    ld hl, wTempBuffer
    ld b, 3 ; we need to move only 3 bytes
    jr move_global
move_buffer2_to_string:
    ld hl, wTempBuffer2
    ld b, 3
    jr move_global
move_entire_contents: ; move the entire size of wTempBuffer into it
    ld hl, wStringBuffer ; source
    ld de, wTempBuffer ; destination
    ld b, temp_buffer_size ; size of temp buffer
    jr move_global ; run copy_bytes
copy_entire_buffer_string: ; puts wTempBuffer into de
    ld hl, wTempBuffer ; pointt hl at the temp buffer
    ld de, wStringBuffer ; de at the string buffer
    ld b, temp_buffer_size ; copy the ENTIRE buffer
    jr move_global
copy_num_buffer2: ; copy a num to wTempBuffer2
    ld hl, wStringBuffer
    ld de, wTempBuffer2
    ld b, 3 ; we need only 3 bytes
    jr move_global
move_global:
    call copy_bytes ; preform the copy
    ret ; leave

; levels up the HP stat
levelup_hp:
    ld a, [wPlayerMaxHP] ; load high byte of max hp into a
    ld h, a ; put into h
    ld a, [wPlayerMaxHP + 1] ; load low byte
    ld l, a ; store into l
    push hl ; put this on the stack as we'll need it later
    farcall number_to_string_sixteen ; converts hl into a string, stored into wStringBuffer
    call move_num_to_buffer ; move number to buffer
    loadstr hp_stat_text ; buffer the HP String into memory
    ld de, wStringBuffer + 2 ; point de at the buffer, right after the hp text
    call append_space_num_plus
    push de ; backup de
    call move_entire_contents ; move the entire buffer
    call random ; get a random number into a
    ld c, 12 ; load 12 into c
    call simple_divide ; A mod C
    cp 0 ; is a 0?
    call z, add_one
    ld b, a ; store the result into b
    xor a ; 0 into a
    ld h, a ; store 0 into h
    ld l, b ; put b into a, which is how much we are adding to the HP stat
    farcall number_to_string_sixteen ; convert to string
    push bc ; backup bc
    call copy_num_buffer2 ; copy wStringBuffer to wTempBuffer2
    call copy_entire_buffer_string
    pop bc
    pop de ; restore hl
    pop hl ; get the original de off the stack again
    ld a, b ; put b back into a
    call sixteenbit_addition ; adds A to HL
    ld a, h ; get new hp high byte into a
    ld [wPlayerMaxHP], a ; write to memory
    ld a, l ; get low byte
    ld [wPlayerMaxHP + 1], a  ; store, hl is now free for whatever we need
    call move_buffer2_to_string ; write buffer 2 to this string
    call append_terminator ; add terminator to the end of DE
    ld hl, hp_stat_line
    call strcpy_vblank
    ret ; yeet

; add one to a
add_one:
    inc a
    ret 

; appends a space, the main number and + to [de]
append_space_num_plus:
    ld a, " " ; load space into a
    ld [de], a ; store in de
    inc de ; next byte plz
    call move_buffer_to_string ; move wTempBuffer to [de]
    ld a, "+" ; load plus into a
    ld [de], a ; write to de
    inc de ; move to next byte
    ret ; leave

; levels up the MP stat
levelup_mp:
    ld a, [wPlayerMaxMP] ; load maximum mp stat into a
    push af ; backup a for later
    call number_to_string ; convert a to a string
    call move_num_to_buffer ; move the number to a buffer
    loadstr mp_stat_text ; buffer the "MP" text into wStringBuffer
    ld de, wStringBuffer + 2 ; point de right after the MP text
    call append_space_num_plus
    push de ; backup de
    call move_entire_contents ; move everything to wTempBuffer
    call random ; get random number
    ld c, 6 ; load 4 into c
    call simple_divide ; A mod C
    cp 0
    call z, add_one
    ld b, a ; backup a into b
    push bc ; push it to the stack
    call number_to_string ; convert to string
    call copy_num_buffer2 ; move result to wTempBuffer2
    call copy_entire_buffer_string ; copy wTempBuffer back to WStringBuffer
    pop bc
    pop de ; restore bc and de
    pop af
    call ensure_no_overflow_8bit
    ld [wPlayerMaxMP], a ; update the max MP in wram
    call move_buffer2_to_string ; copy wTempBuffer2 to [de]
    call append_terminator
    ld hl, mp_stat_line ; point hl at the stat line
    call strcpy_vblank
    ret ; yeet

; levels up the ATK stat
levelup_atk:
    ld a, [wPlayerAttack] ; load players attack into a
    push af ; backup a
    call number_to_string ; convert a to string
    call move_num_to_buffer ; copy result to wTempBuffer
    loadstr battle_atk ; load the ATK string into wString buffer
    ld de, wStringBuffer + 3 ; move past the ATK string in the buffer
    call append_space_num_plus ; do the do
    push de ; backup de
    call move_entire_contents ; move all contents to wTempBuffer
    call random ; get random number
    ld c, 4 ; load 4 into c
    call simple_divide ; A mod C
    cp 0
    call z, add_one
    ld b, a ; store result into b
    push bc ; backup bc
    call number_to_string
    call copy_num_buffer2 ; move number to wTempBuffer2
    call copy_entire_buffer_string ; wTempBuffer -> wStringBuffer
    pop bc
    pop de
    pop af
    call ensure_no_overflow_8bit
    ld [wPlayerAttack], a ; write to wram
    call move_buffer2_to_string ; move wTempBuffer2 to [de]
    call append_terminator
    ld hl, atk_stat_line
    call strcpy_vblank
    ret ; yeet

; levels up the DEF stat
levelup_def:
    ld a, [wPlayerDefense] ; load the defense stat into a
    push af ; back up
    ; yesyesyesyesyesy this is acopy paste of the last 2 functions
    ; you should be able to figure out what it does by reading those
    call number_to_string
    call move_num_to_buffer
    loadstr def_stat_text
    ld de, wStringBuffer + 3
    call append_space_num_plus
    push de
    call move_entire_contents
    call random
    ld c, 4
    call simple_divide
    cp 0
    call z, add_one
    ld b, a
    push bc
    call number_to_string
    call copy_num_buffer2
    call copy_entire_buffer_string
    pop bc
    pop de
    pop af
    call ensure_no_overflow_8bit
    ld [wPlayerDefense], a
    call move_buffer2_to_string
    call append_terminator
    ld hl, def_stat_line
    call strcpy_vblank
    ret ; yeet

; sets up the selecton arrow to be next to HP
setup_arrow:
    ld a, [wOAMSpriteFour + 3] ; load the flags byte
    set 5, a ; set the xflip bit
    ld [wOAMSpriteFour + 3], a ; write it to the oam buffer
    ld a, exp_arrow_basey ; load base y coord into a
    ld [wOAMSpriteFour], a ; store to y coord
    ld a, exp_arrow_basex ; load x coord
    ld [wOAMSpriteFour + 1], a ;  update x coord
    call queue_oamdma ; preform a dma transfer
    ret ; yeet

; routine for letting the player select a stat to give additional points too
player_select_booststat:
    call setup_arrow ; setup the arrow to pick a stat
    xor a ; load 0 into a
    ld [wExperienceSelection], a ; set the selection to 0 (defaults to hp)
    buffertextbox levelup_picka_stat ; buffer pickastat text
    farcall do_textbox ; run the script
    ld hl, joypad ; point hl at the joypad register
.select_loop
    call select_dpad ; select the dpad
    ld a, [hl]
    ld a, [hl] ; load state of joypad register into a
    ld a, [hl]
    bit 3, a ; is down pressed?
    jr z, .down
    bit 2, a ; is up pressed?
    jr z, .up
    call select_buttons ; select the ACTION buttons
    ld a, [hl]
    ld a, [hl] ; load the state of the joypad into a again
    ld a, [hl]
    bit 0, a ; is the a button pressed?
    jr z, .abutton ; yes, go do that
    jr .select_loop
.up
    ld a, [wExperienceSelection] ; load current selection into a
    dec a ; subtract 1
    call check_sel_overflow ; check for overflow
    jr .update
.down
    ld a, [wExperienceSelection] ; load selection into a
    inc a ; add 1
    call check_sel_overflow ; make sure it did not over/underflow
    jr .update
.update
    ld [wExperienceSelection], a ; update the ram variable
    call update_arrow_position ; update the arrow
    ld a, 64 ; load 64 into a
    ld [wSubLoopCount], a ; store into here
    farcall waste_time ; waste some cycles
    jr .select_loop ; go back to the loop
.abutton
    call init_roulette ; draw the roulette box
    push hl
    buffertextbox levelup_roulette_text ; load this text
    farcall do_textbox ; run the script
    pop hl
    call roulette_loop ; run the thing
    ld a, b ; load b into a
    cp 1 ; is b 1?
    jr z, .cancelled
    jp nz, .done
.cancelled
    call clear_roulette_num ; get rid of the number
    push hl
    buffertextbox levelup_picka_stat ; reload old text
    farcall do_textbox ; run it
    pop hl
    ld a, 42 ; load 42 into a
    ld [wSubLoopCount], a ; write to sub loop
    farcall waste_time ; wait
    jp .select_loop
.done
    call apply_statboost ; applies the statboost to the correct stat
    call reset_and_hide_arrow ; get rid of the mf arrow
    buffertextbox levelup_boost_applied ; buffer the final message
    farcall do_textbox ; run the script to display it
    ret

; applies the statboost in C to whatever stat is selected
apply_statboost:
    ld a, [wExperienceSelection] ; load selection into a
    cp 0 ; hp
    jr z, .hp
    cp 1 ; MP
    jr z, .mp
    cp 2 ; ATK
    jr z, .atk
    cp 3 ; DEF
    jr z, .def
.hp
    ld a, [wPlayerMaxHP] ; load high byte into a
    ld h, a ; store to h
    ld a, [wPlayerMaxHP + 1] ; store low byte into a
    ld l, a ; store into l
    ld a, c ; loads c into a
    call sixteenbit_addition ; adds A to HL
    ld a, h ; h into a
    ld [wPlayerMaxHP], a ; write high byte
    ld a, l ; l into a
    ld [wPlayerMaxHP + 1], a ; write low byte
    jr .leave ; boost applied!
.mp
    ld a, [wPlayerMaxMP] ; load MP stat into a
    ld b, c ; move c into b
    call ensure_no_overflow_8bit ; do the thing
    ld [wPlayerMaxMP], a ; write to wram
    jr .leave ; boost applied, leave
.atk
    ld a, [wPlayerAttack] ; load attack stat into a
    ld b, c ; move c into b
    call ensure_no_overflow_8bit ; add them and ensure no overflow
    ld [wPlayerAttack], a ; write to wram
    jr .leave ; we've finished
.def
    ld a, [wPlayerDefense] ; load player defense into a
    ld b, c ; move c into b
    call ensure_no_overflow_8bit ; add together and ensure there is no overflow
    ld [wPlayerDefense], a ; update wram
    jr .leave ; yeet
.leave
    ret ; return to caller

; draws a very small textbox to the screen to hold the roulette
init_roulette:
    push hl
    ld hl, exp_start_roulette ; hl at the start of the textbox
    ld b, 3 ; 3 long
    ld c, 3 ; 3 high
    farcall draw_textbox_improved
    pop hl
    ret ; yeet

; does the roulette loop
; 1 in b if cancelled
roulette_loop:
    push hl ; backup hl
    ld hl, exp_roulette_number ; point de at the roulette number
    ld de, joypad ; de points at the joypad now
    call select_buttons ; select the ACTION buttons
    xor a ; load 0 into a
    inc a ; add 1
    ld c, a ; put that 0 into c
.loop
    ; update the wheel first
    ld a, c ; load c into a
    push bc ; backup c
    ld c, start_of_numbers ; load c with the numbers
    add a, c ; add together
    pop bc ; restore c
    ld [wTileBuffer], a ; place in tile buffer
    updatetile ; update the tile using vblank
    ; then prompt for user input
    ld a, [de]
    ld a, [de] ; load state of joypads into a
    ld a, [de] 
    bit 1, a ; is b pressed?
    jr z, .cancel ; cancel this
    bit 0, a ; is a pressed?
    jr z, .stopwheel ; stop the wheel
    ; if nothing happened, then increase the stat boost
    call increment_stat_boost ; do the thing
    jr .loop ; go back to the top of the loop
.stopwheel
    xor a ; 0 into a
    ld b, a ; make sure b is 0
    jr .exit ; yeet
.cancel
    ld b, 1 ; set cancel flag to 1
.exit
    pop hl ; dont forget to pop hl off the stack
    ret ; yeet

; this is mostly for code cleanliness
increment_stat_boost:
    inc c ; add 1 to c
    ld a, c ; load c into a
    cp 8 ; is it 8?
    jr z, .one
.done
    ret
.one
    ld c, 1 ; make c 1
    jr .done ; exit

; gets rid of the roulette number on cancel
clear_roulette_num:
    push hl
    ld hl, exp_roulette_number
    ld a, " " ; load blank into a
    ld [wTileBuffer], a ; put into buffer
    updatetile ; make vblank update it
    pop hl
    ret

; check if the selection is 4 or $FF
; must be in a already
check_sel_overflow:
    cp 4 ; is it 4?
    jr z, .min
    cp $FF ; 255?
    jr z, .max
    jr .done
.min
    xor a ; 0 into a
    jr .done
.max
    ld a, 3 ; 3 into a
    jr .done
.done
    ret

; updates where the arrow is pointing
update_arrow_position:
    push hl ; backup hl
    ld a, [wExperienceSelection] ; load the current selection into a
    call multiply_by_eight ; multiply a by 8
    ld b, a ; load result into b
    ld a, exp_arrow_basey ; load base y into a
    add a, b ; add b to A
    ld [wOAMSpriteFour], a ; update sprite y post
    call queue_oamdma ; do DMA
    pop hl ; restore hl
    ret ; yeetus

; unflips the arrow and then hides it
reset_and_hide_arrow:
    xor a ; set a to 0
    ld [wOAMSpriteFour + 3], a ; write to OAM
    ld [wOAMSpriteFour], a ; zero out the y coord
    call queue_oamdma ; update OAM via DMA
    ret ; leave

; adds b to a, if overflow, resets result to 255
ensure_no_overflow_8bit:
    add a, b ; do the addition
    jr c, .fix
    jr .end
.fix
    ld a, $FF ; load 255 into a
.end
    ret

; adds a terminator to the end of de
append_terminator:
    ld a, terminator ; load a with the terminator
    ld [de], a ; store it into de
    inc de ; move forward 1
    ret ; leave

