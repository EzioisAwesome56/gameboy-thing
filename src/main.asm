SECTION "Main game code", romx
include "macros.asm"

; main routine for our game
run_game::
    ; first we copy string1 into the buffer
    loadstr test_string
    displaystr $9801
    call draw_textbox
    buffertextbox test_box
    call do_textbox
    ; waste a lot of time
    ld a, $FF
    ld [wSubLoopCount], a
    call waste_time
    call clear_textbox
    ; testing random number generation
    call random
    ld [wDebugByte], a
    rst $28

; dead loop
memes:
    halt 
    jr memes

; clears out both lines of the textbox
clear_textbox::
    push hl
    push af ; backup variables
    ; first clear the top line
    ld hl, textbox_firstline
    ld a, 4
    ld [wVBlankAction], a ; setup vblank to do it
    halt ; wait for it to finish
    ; next, clear the second line tpp
    ld hl, textbox_secondline
    ld a, 4
    ld [wVBlankAction], a
    halt ; wait for vblank
    pop af
    pop hl
    ret ; we're done here

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

def textbox_upleft equ $99c0

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

def textbox_firstline equ $99e1
def textbox_secondline equ $9A01
; text flow control chars
def newline equ $FD
def terminator equ $FF
def clear equ $FA
def button equ $FC
def pointer equ $FB
; starts processing textbox contents from wLargeStringBuffer
do_textbox::
    push hl ; backup hl
    ld hl, textbox_firstline ; put the address to the start of the first line here
    push af ; backup a
    xor a ; delete contents of a just in case
    push de ; backup de
    ld de, wLargeStringBuffer ; point de at our string buffer
.loop
    ld a, [de] ; load current char into a
    cp newline ; is it the new line char?
    jr z, .newline ; handle that if so
    cp terminator ; is it the terminator?
    jr z, .done ; we have finished then, leave
    cp button ; does the text want us to wait for a button press?
    jr z, .button ; go deal with that if yes
    cp clear ; do they want to clear the textbox?
    jr z, .clear ; go do that
    cp pointer ; does the text spesify more text to load?
    jr z, .pointer ; go deal with that
    ld [wTileBuffer], a ; otherwise, take the char and buffer it
    updatetile ; tell vblank to update it
    inc hl
    inc de
    jr .loop ; increment and continue the loop
.newline
    ld hl, textbox_secondline ; move hl to point at the second line
    inc de ; move to next character to prevent infinite loops
    jr .loop ; resume the loop
.button
    call textbox_wait_abutton ; call subroutine to handle this for us
    inc de ; increment de to next char
    jr .loop ; go back to the loop
.clear
    call clear_textbox ; clear the textbox
    inc de ; increment source address
    ld hl, textbox_firstline ; reset hl to the first line
    jr .loop ; go back to the loop
.done
    ; we finished, so
    pop de
    pop af
    pop hl ; pop everything off the stack
    ret ; return
.pointer
    inc de ; increment our source address again
    push bc ; backup bc
    ld a, [de] ; load ROMbank number into a
    ld b, a ; store it into b
    inc de ; increment source address again
    ld a, [de] ; load high byte of source address into a
    ld h, a ; store it into h
    inc de ; increment again
    ld a, [de] ; get low byte of address
    ld l, a ; store it in l
    farcall buffer_textbox_content ; call the routine to buffer textbox content
    ; if we're here, then we have returned from buffering
    ld de, wLargeStringBuffer ; point de at the start of our buffer
    ld hl, textbox_firstline ; point hl at the first line of the textbox
    xor a ; clear a
    pop bc ; restore bc
    jr .loop ; go back to the loop
