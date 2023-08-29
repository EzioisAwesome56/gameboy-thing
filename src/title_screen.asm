section "Title Screen Code", romx, bank[2]
include "macros.asm"
include "constants.asm"
def max_selection equ 2
def base_y_coord equ 96 ; puts arrow infront of first option
def arrow_x equ 8
; runs the title screen for the game
do_titlescreen::
    call init_validate_save_file ; check if the save file is valid
    call disable_lcd ; disable the LCD so we can freely draw to the tilemap
    call clear_bg_tilemap ; clear the bg tilemap
    loadstr title_placeholder ; load placeholder text
    ld de, $9800
    call strcpy_different ; put at the top of the screen
    call init_draw_menu_options ; draw the menu options to the screen
    ; setup the arrow sprite in OAM
    ld a, arrow_x ; load 8 coord into x
    ld [wOAMSpriteThree + 1], a ; put that into x coord
    call init_set_arrowy ; configure the arrow's y pos correctly
    ld a, right_arrow_tile ; load tile index into a
    ld [wOAMSpriteThree + 2], a ; load that into the tile index
    call enable_lcd ; turn the lcd back on
    call queue_oamdma ; do a DMA transfer
    ld hl, joypad ; point hl at the joypad register
    push hl
    call wait
    pop hl ; yeet
.loop
    call select_dpad ; switch to dpad mode
    ld a, [hl]
    ld a, [hl]
    ld a, [hl]
    bit 3, a ; is down on the dpad presses?
    jr z, .down ; handle that
    bit 2, a ; is up being pressed on the dpad
    jr z, .up
    call select_buttons
    ld a, [hl]
    ld a, [hl] ; input debouncing
    ld a, [hl]
    bit 0, a ; is a pressed?
    jr z, .abutton ; if no, yeet outta her
    jr .loop ; kermit loop
.abutton
    ld a, [wTitleScreenOption] ; load the current title screen option into a
    cp 0 ; is it 0 (resume)
    jp z, title_resume_saved_game
    cp 1 ; is it 1 (new game?)
    jp z, title_start_new_game ; start a new game
    cp 2 ; SRAM clear?
    call z, clear_sram_title
    jr .loop
.down
    ld a, [wTitleScreenOption] ; load the currently selected option into a
    inc a ; add 1
    jr .combine
.up
    ld a, [wTitleScreenOption] ; load title screen option into a
    dec a ; decrease by one
    jr .combine ; go here
.combine
    call handle_selection ; normalize the selection value in a
    ld [wTitleScreenOption], a ; store it back into wram
    call update_arrow_graphic ; update the arrow graphic
    call wait
    jr .loop ; go back to the loop

; runs all code required to start a new game
; then exits
title_start_new_game:
    farcall clear_oam ; clear OAM
    call queue_oamdma
    farcall do_intro_cutscene ; run the intro
; exits the title screen routine
title_exit:
    farcall clear_oam ; clear oam
    call queue_oamdma ; preform a dma transfer
    ret ; otherwise, nah fam

title_resume_saved_game:
    call disable_lcd
    call clear_bg_tilemap
    call enable_lcd
    call load_save_game
    farcall clear_oam ; yeet oam
    call queue_oamdma ; do a DMA transfer
    ret ; leave

; clears out the savefile in sram
clear_sram_title:
    xor a ; load 0 into a
    ld [wOAMSpriteThree + 1], a ; store that into x coord
    call queue_oamdma ; update OAM
    ld a, [wOAMSpriteThree] ; load y coord into a
    push af ; back it up for later
    buffertextbox clearsram_textbox ; load our textbox into memory
    farcall show_textbox ; show the textbox
    farcall do_textbox ; run textbox script
    farcall prompt_yes_no ; prompt for yes or no
    ld a, [wYesNoBoxSelection] ; load the selection into a
    cp 1 ; did they select yes?
    jr z, .doclear ; clear sram
    buffertextbox clearsram_cancel ; buffer text for clearing sram
    jr .skipclear
.doclear
    ld hl, $A000 ; point HL at the start of sram
    xor a ; 0 out a
    inc a ; put 1 into a
    call bankmanager_sram_bankswitch ; switch to bank 1
    call mbc3_enable_sram ; open SRAM
.loop
    ld a, l ; load low byte into a
    cp $FF ; is it ff
    jr z, .checkhigh ; we need to check highbyte if so
.resume
    xor a ; otherwise, load 0 into a
    ld [hl], a ; store it into hl
    inc hl ; move to next address
    jr .loop ; go back to the loop
.checkhigh
    ld a, h ; load h into A
    cp $BF ; is it BF?
    jr z, .done ; we're done lol
    jr .resume ; otherwise go back to copying data
.done
    xor a ; put 0 into a
    ld a, [hl] ; make sure the last byte of sram is cleared
    call bankmanager_sram_bankswitch ; switch to bank 0 of sram
    call mbc3_disable_sram ; close sram
    buffertextbox clearsram_finish ; buffer string for clearing sram
.skipclear
    farcall do_textbox ; run new textbox script
    farcall hide_textbox ; hide the textbox
    farcall remove_textbox ; get rid  of the textbox from vram
    ld a, arrow_x ; load default x into a
    ld [wOAMSpriteThree + 1], a ; put it into OAM
    pop af ; restore af
    ld [wOAMSpriteThree], a ; store back y coord
    call queue_oamdma ; update OAM
    ld hl, joypad ; repoint hl at the joypad
    ret ; leave

; waits a little bit before returning
wait:
    ld a, 75 ; load 75 into a
    ld [wSubLoopCount], a ; put that into subloop
    farcall waste_time ; waste time
    ret ; leave

; deals with the selection overflowing
; put current selectiton into a
handle_selection:
    push af
    ld a, [wSaveFileValid] ; load the valid save file byte into a
    cp 1 ; is it 1?
    jr z, .activesave ; go handle all of this differently
    pop af ; restore the state of a
    cp 0 ; did we underflow?
    jr z, .underflow ; oh no we did
    cp max_selection + 1 ; compare with max selection
    jr nc, .overflow ; oops, we overflowed
    jr .done ; neither of these cases happened, so leave
.overflow
    xor a ; reset to 0
    inc a
    jr .done
.underflow
    ld a, max_selection ; go to the highest selection
.done
    ret ; leave
.activesave
    pop af ; get the thing
    cp $FF ; underflow?
    jr z, .save_underflow
    cp max_selection + 1 ; did we overflow?
    jr nc, .save_overflow ; ah fck
    jr .done ; nothing to worry about
.save_overflow
    xor a ; a is now  0
    jr .done
.save_underflow
    ld a, max_selection ; set to the max selection
    jr .done


; updates the position of the arrow graphic
update_arrow_graphic:
    ; a should still have the new selection in it
    ld b, a ; move it into b
    xor a ; put 0 into a
    ld c, a ; load 0 into c
    ld e, base_y_coord ; store base y into e
    ld d, 8 ; put 8 into d
.loop
    ld a, b ; put b into a
    cp c ; is c equal to a?
    jr z, .done ; leave lol
    ld a, e ; otherwise, put e into a
    add a, d ; add d to a 
    ld e, a ; put it back into e
    inc c ; add 1 to our counter
    jr .loop ; go have some fun loops
.done
    ld a, e ; get new coord into a
    ld [wOAMSpriteThree], a ; update y coord
    call queue_oamdma ; update it
    ret ; leave

; draw the menu options to the screen
init_draw_menu_options:
    ld a, [wSaveFileValid] ; load the save file flag into a
    cp 1 ; is it one?
    jr z, .display_load ; if 1, display the option to load
.resume ; otherwise, fallthru to here
    loadstr title_newgame ; load our startgame str into memory
    ld de, $9961 ; point de at the right place
    call strcpy_different ; display string
    loadstr title_clearsram
    ld de, $9981 ; next row plz
    call strcpy_different
    ret ; yeet
.display_load
    loadstr title_loadgame
    ld de, $9941
    call strcpy_different ; display it
    jr .resume

; check the state of the save file
init_validate_save_file:
    ld a, bank(sHasSaveFile) ; load bank of player's save file into a
    call bankmanager_sram_bankswitch ; switch to it
    call mbc3_enable_sram ; open that sram up
    ld a, [sHasSaveFile] ; load the save file flag into a
    cp 4 ; is a 4?
    jr nz, .nosave ; if not, yeet
    call validate_save_checksums
    jr .done
.nosave
    xor a ; 0 into a
    ; this sets the savefile as non-existant
    ld [wSaveFileValid], a ; update the state of the save file
    jr .done
.done
    call mbc3_disable_sram ; close sram
    ; next we will set the arrow to the correct place
    ld a, [wSaveFileValid] ; load the valid flag
    cp 1 ; is it valid?
    jr z, .opt0
    jr nz, .opt1
.opt0
    xor a
    jr .done2
.opt1
    xor a
    inc a ; is now pointed at new game
.done2
    ld [wTitleScreenOption], a ; place the arrow where it needs to go
    ret ; we're done here

; set the arrow to the correct place
init_set_arrowy:
    ld a, [wSaveFileValid] ; load the save file valid flag
    cp 1 ; is there a valid loaded file?
    ld a, base_y_coord ; load y coord into a
    jr nz, .add8
    jr z, .done
.add8
    add 8 ; add 8 to a
.done
    ld [wOAMSpriteThree], a ; put that into y coord
    ret ; leave

; validate the save file found on the cartridge
validate_save_checksums:
    push de
    push hl ; backup registers
    push bc
    ; first we shall checksum the player information
    ld b, player_save_size
    ld hl, sSavedData
    farcall calculate_checksum ; calculate the checksum and store it into hl
    ; once done, compare against what we have in sram
    ld de, sSaveFileChecksum
    ld a, [de]
    cp a, h ; compare a to h
    jr nz, .corrupt ; oh no, the file is corrupt
    inc de ; next byte
    ld a, [de]
    cp a, l ; compare a to l
    jr nz, .corrupt ; the file is corrupted
    ; if we made it this far, we survived the onslaught of player data checksums
    ; do it again for event flags
    ld b, 255
    ld hl, sSavedEventFlags ; what we want to checksum
    farcall calculate_checksum ; find out what the checksum of the data is
    ; once that finished, point de at the checksum present in the save
    ld de, sSaveEventChecksum
    ld a, [de] ; load first byte
    cp a, h ; compare a to h
    jr nz, .corrupt
    inc de
    ld a, [de]
    cp a, l ; compare a to l
    jr nz, .corrupt
    ; if we survived again, the data is good!
    xor a
    inc a ; a is now 1
    ld [wSaveFileValid], a ; store that into memory
    jr .done
.corrupt
    xor a ; 0 out a
    inc a
    inc a ; set a to 2
    ld [wSaveFileValid], a ; store into the correct state
    jr .done
.done
    pop bc
    pop hl
    pop de
    ret ; leave

