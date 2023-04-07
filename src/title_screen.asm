section "Title Screen Code", romx, bank[2]
include "macros.asm"
def joypad equ $FF00
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

    call enable_lcd ; turn the lcd back on
    ld hl, joypad ; point hl at the joypad register
    call select_buttons ; select the buttons
.loop
    ld a, [hl]
    ld a, [hl]
    ld a, [hl] ; for input debouncing
    bit 0, a ; is a pressed?
    jr nz, .loop ; if no, yeet outta here
    ret ; otherwise, nah fam
