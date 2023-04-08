section "Title Screen Code", romx, bank[2]
include "macros.asm"
def joypad equ $FF00
def max_selection equ 1
def base_y_coord equ 104 ; puts arrow infront of first option
; runs the title screen for the game
do_titlescreen::
    call disable_lcd ; disable the LCD so we can freely draw to the tilemap
    call clear_bg_tilemap ; clear the bg tilemap
    loadstr placeholder ; load placeholder text
    ld de, $9800
    call strcpy ; put at the top of the screen
    loadstr startstr ; load our startgame str into memory
    ld de, $9961 ; point de at the right place
    call strcpy ; display string
    loadstr clearsram
    ld de, $9981 ; next row plz
    call strcpy
    xor a ; put 0 into a
    ld [wTitleScreenOption], a ; put that into the currently selected option
    ; setup the arrow sprite in OAM
    ld a, 8 ; load 8 coord into x
    ld [wOAMSpriteThree + 1], a ; put that into x coord
    ld a, base_y_coord ; load y coord into a
    ld [wOAMSpriteThree], a ; put that into y coord
    ld a, $57 ; load tile index into a
    ld [wOAMSpriteThree + 2], a ; load that into the tile index
    call enable_lcd ; turn the lcd back on
    call queue_oamdma ; do a DMA transfer
    ld hl, joypad ; point hl at the joypad register
.loop
    call select_buttons
    ld a, [hl]
    ld a, [hl] ; input debouncing
    bit 0, a ; is a pressed?
    jr z, .abutton ; if no, yeet outta here
    call select_dpad ; switch to dpad mode
    ld a, [hl]
    ld a, [hl]
    bit 3, a ; is down on the dpad presses?
    jr z, .down ; handle that
    bit 2, a ; is up being pressed on the dpad
    jr z, .up
    jr .loop ; kermit loop
.abutton
    ld a, [wTitleScreenOption] ; load the current title screen option into a
    cp 0 ; is it 0 (or play game?)
    jp z, title_exit ; exit this routine
    cp 1 ; SRAM clear?
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

; exits the title screen routine
title_exit:
    farcall clear_oam ; clear oam
    call queue_oamdma ; preform a dma transfer
    ret ; otherwise, nah fam

; clears out the savefile in sram
clear_sram_title:
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
    buffertextbox clearsram_textbox ; load our textbox into memory
    farcall show_textbox ; show the textbox
    farcall do_textbox ; run textbox script
    farcall hide_textbox ; hide the textbox
    farcall remove_textbox ; get rid  of the textbox from vram
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
    cp $FF ; did we underflow?
    jr z, .underflow ; oh no we did
    cp max_selection + 1 ; compare with max selection
    jr nc, .overflow ; oops, we overflowed
    jr .done ; neither of these cases happened, so leave
.overflow
    xor a ; reset to 0
    jr .done
.underflow
    ld a, max_selection ; go to the highest selection
.done
    ret ; leave

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

