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
    xor a ; put 0 into a
    ld [wTitleScreenOption], a ; put that into the currently selected option
    ; setup the arrow sprite in OAM
    ld a, 8 ; load 8 coord into x
    ld [wOAMSpriteThree + 1], a ; put that into x coord
    ld a, 104 ; load y coord into a
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
    jr nz, .loop ; if no, yeet outta here
    farcall clear_oam ; clear oam
    call queue_oamdma ; preform a dma transfer
    ret ; otherwise, nah fam
