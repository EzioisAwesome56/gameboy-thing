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
    farcall clear_textbox
    call hide_statbox
    call remove_statbox
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

