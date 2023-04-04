SECTION "Textbox Engine", romx
include "macros.asm"

def joypad equ $FF00 ; location of joypad
; if drawing to BG map: $9A32
; if drawing to top of window: $9C72
def arrow_location equ $9C72 ; address the arrow gets put at
def textbox_line equ $21
; puts textbox in a loop of waiting for the a button to be pressed
; does not take any arguments
textbox_wait_abutton::
    push hl
    push af ; backup registers
    ld hl, joypad ; point hl at our joypad register
    call select_buttons ; set joypad to use buttons
    push hl ; backup hl for a second
    ld hl, wVBlankFlags ; load vblank flag byte into ram
    set 0, [hl] ; set the blink flag
    pop hl ; restore hl
.loop
    ld a, [hl] ; load joypad register
    bit 0, a ;  is the a button pressed?
    jr z, .done ; leave if yes
    jr .loop ; continue the loop
.done
    ld hl, wVBlankFlags ; we need to unset the blink bit
    res 0, [hl] ; we do that here before we return
    ; as a justt-in-case thing, we will put a line character where the arrow is
    ld hl, arrow_location ; set hl to arrow location
    ld a, textbox_line ; load the line characteer into a
    ld [wTileBuffer], a ; and put it into the buffer
    updatetile ; make vblank update it
    pop af
    pop hl ; pop our backups off the stack
    ret ; leave

; drawing to the bgmap: $99E1
; drawing to correctly positioned window: $9c21
def textbox_firstline equ $9C21
; drawing to bgmap: $9A01
; drawing to top of window: $9c41
def textbox_secondline equ $9c41
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

; for BG: 99c0 = bottom 4 rows
; window is 9C00 = top 4 rows of the window
def textbox_upleft equ $9C00

; draw a textbox to the top of the window
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
    ; before we really return, we need to set the flag that it is drawn
    xor a
    inc a
    ld [wTextboxDrawn], a ; set this ram location to 1
    ; we have finished, restore all registers and return
    pop af
    pop bc
    pop de
    pop hl
    ret
    
def window_x equ $FF4B
def window_y equ $FF4A ; note: ypos 112 is where the textbox is perfectly visible
; configures the window for displaying a textbox
configure_window:
    push af ; backup a
    ld a, 7 ; load 7 intto a
    ldh [window_x], a ; store it into Window X
    call enable_window ; enable the window
    ld a, 144 ; load y so its off the bottom of the screen
    ldh [window_y], a ; store it into window y
    pop af ; restore af
    ret ; yeet

; slides the textbox up from the bottom of the screen
show_textbox::
    push hl
    push af ; backup registers
    push bc
    ld a, [wTextboxDrawn] ; load flag byte
    cp 1 ; is it drawn?
    call nz, draw_textbox ; draw textbox if its not
    xor a ; load 0 into a
    ld b, a ; store 0 into b
    ld hl, window_y ; point hl at window y
    call configure_window ; setup the window
    call enable_window ; enable the window
.loop
    ld a, b ; load b into a
    cp 16 ; have we done this 13 times?
    jr z, .done ; leave if so
    halt ; wait for vblank
    dec [hl]
    dec [hl] ; decrease windowy by 2
    inc b ; increment counter
    jr .loop ; go loop some more
.done
    pop bc
    pop af
    pop hl ; pop all registers off the stack
    ret ; leave


; removes the textbox from window tilemap
; needs 4 vblank cycles to finish
; $99C0, $99E0, $9A00, $9A20
remove_textbox::
    push hl
    push bc
    push de
    push af ; backup registers
    ld hl, textbox_upleft ; load first line into hl
    ld a, 20 ; store 20 into a
    ld e, a ; put it into e
    xor a ; zero out a
    ld d, a ; put 0 into d
.loop
    ld a, 5 ; put 5 into a
    ld [wVBlankAction], a ; put that into vblank action
    halt ; wait for vblank to do the thing
    ld a, l ; load low byte of hl into a
    cp $34 ; is it equal to 34?
    jr z, .done ; exit if so
    add hl, de ; add de to hl
    jr .loop ; go loop more
.done
    xor a ; load 0 into a
    ld [wTextboxDrawn], a ; set the textbox drawn flag to 0
    ; pop everything off the stack
    pop af
    pop de
    pop bc
    pop hl
    ret ; return to caller function

; scrolls the textbox out of view
hide_textbox::
    push hl
    push af ; backup registers that we need
    push bc
    xor a ; put 0 into a
    ld b, a ; put 0 into b
    ld hl, window_y ; point hl at our window y position
.loop
    ld a, b ; load counter into a
    cp 16 ; have we done this 16 times?
    jr z, .done ; leave
    halt ; wait for vblank
    inc [hl] ; increment hl 2 times
    inc [hl]
    inc b ; increment b
    jr .loop ; go and loop
.done
    call disable_window ; disable the window
    pop bc
    pop af
    pop hl ; pop all our shit off the stack
    ret 