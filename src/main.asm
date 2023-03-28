SECTION "Main game code", romx
include "macros.asm"

def textbox_upleft equ $99c0
; main routine for our game
run_game::
    ; first we copy string1 into the buffer
    loadstr test_string
    displaystr $9801
    halt
    call draw_textbox

; dead loop
memes:
    halt 
    jr memes

; top line of the textbox
textbox_top: db $1B
    ds 18, $1F
    db $1C
    db $FF ; terminator character
; middle of textbox
textbox_middle: db $22
    ds 18, 0
    db $20
    db $FF ; terminator character
textbox_bottom: db $1D
    ds 18, $21
    db $1E
    db $FF ; terminator character

; draw a textbox to the bottom of the screen
draw_textbox::
    push hl ; backup hl as we will be using this
    ld hl, textbox_upleft ; set hl to be the starting byte of the textbox
    push de ; backup de
    ld de, textbox_top ; point de at textbox_top
    push bc
    push af ; backup bc and af as well
    xor a ; zero out a
    ld b, a ; store a into b
.loop
    ld a, [de] ; load current tile into A
    cp $FF ; is it our terminator?
    jr z, .next ; if yes, go to next part of code
    ld [wTileBuffer], a ; otherwise, store the tile into our buffer
    updatetile ; make vblank update the tile
    inc hl ; increment hl
    inc de ; also increment de
    jr .loop ; loop again
.next
    inc b ; we have reached the end of a loop, increment b
    push bc ; push bc onto the stack
    xor a ; zero out a
    ld b, a ; load 0 into b
    ld a, 12 ; load 12 into a (there's 12 tiles left on this line after we drew the textbox)
    ld c, a ; store a into c. bc is now 32
    add hl, bc ; add 32 to hl
    pop bc ; restore bc
    ; load b into a
    ld a, b
    cp 3 ; have we looped 3 times?
    jr z, .bottom ; if yes, go to the bottom
    cp 4 ; have we finished all the loops?
    jr z, .done ; todo: exit subroutine
    ld de, textbox_middle ; otherwise, load the middle into de
    jr .loop ; and jump back to loop
.bottom
    ; set DE to the bottom textbox
    ld de, textbox_bottom
    jr .loop
.done
    ; we have finished, restore all registers and return
    pop af
    pop bc
    pop de
    pop hl
    ret 



