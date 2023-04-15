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
    buffertextbox magic_info_box ; buffer information box
    farcall clear_textbox ; clear out the textbox
    farcall do_textbox ; display it
    call show_large_textbox
    jr @

; the main loop that runs the magic menu
magic_menu_loop:
    ld hl, joypad ; point hl at the joypad


; scrolls the textbox up 96 pixels
show_large_textbox:
   ld a, [window_y] ; load window y into a
   ld b, 96 ; load 96 into b
   halt ; wait for a vblank cycle
   sub a, b ; add b to a
   ld [window_y], a ; update window position
   halt ; wait for vblank again
   ret ; leave

; prepare the magic menu
init_battle_menu:
    call clear_huge_textbox ; clear out the space for the huge textbox
    call disable_lcd
    call init_draw_massive_textbox ; draw it
    call enable_lcd
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


