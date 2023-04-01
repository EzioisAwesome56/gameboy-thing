SECTION "Main Overworld Code", romx
include "macros.asm"
def joypad equ $ff00

; window size is 20x by 18y tiles

; main overworld first init routine
run_game::
    ; first we copy string1 into the buffer
    loadstr test_string
    displaystr $9801
    queuetiles banana, 1, 76
    ld a, 76 ; load tile index into a
    ld [wOAMSpriteOne + 2], a ; put that into the oam buffer
    xor a
    set 7, a
    ld [wOAMSpriteOne + 3], a
    halt ; wait for vblank to finish loading the tile into memory
    ld a, 1 ; load our tile x coord into a
    ld [wPlayerx], a ; store it
    xor a ; put 0 into a
    ld [wPlayery], a ; store that as our y coord
    call calculate_overworld_pos
.joypad_reinit
    ld hl, joypad ; point hl at our joypad
    set 5, [hl] ; do not select the action buttons
    res 4, [hl] ; listen for the dpad
.loop
    ld a, [hl]
    ld a, [hl]
    ld a, [hl]
    ; check for inputs
    bit 0, a ; right on dpad
    jr z, .right
    bit 1, a ; left press?
    jr z, .left
    bit 2, a ; up press?
    jr z, .up
    bit 3,  a ; down press?
    jr z, .down
    jr .loop
.up
    ld a, [wPlayery]
    dec a ; decrease it because yea weird grid
    ld [wPlayery], a
    jr .update
.down
    ld a, [wPlayery] ; load y coord
    inc a ; add one
    ld [wPlayery], a ; put it back
    jr .update
.left
    ld a, [wPlayerx]
    dec a ; decrease a by one
    ld [wPlayerx], a
    jr .update
.right
    ld a, [wPlayerx] ; load our x coord
    inc a ; add one
    ld [wPlayerx], a ; store it back
    jr .update
.update
    ; TODO: map scripts and stuff lol
    call calculate_overworld_pos
    ld a, 78
    ld [wSubLoopCount], a
    call waste_time
    jr .loop



    jp memes
    
; calculate the actual position the sprite should be rendered at, then update OAM
; X coord = (x * 8) + 8
; Y coord = (y * 8) + 16
calculate_overworld_pos::
    push af ; backup af
    push hl ; oops i need HL now too
    ld a, [wPlayerx] ; load our player x coord into a
    inc a ; same as adding 8
    call multiply_by_eight ; get x coord into a
    ld [wOAMSpriteOne + 1], a ; store x coord value
    ; now we do the same thing for y, more or less
    ld a, [wPlayery] ; load  y grid value into a
    inc a ; we just have to add 16
    inc a ; or add 2 before multiplying by 8
    call multiply_by_eight ; get base xcoord into a
    ld [wOAMSpriteOne], a ; and store it into memory
    ; next we have to tell vblank to call an OAMDMA transfer
    ld hl, wVBlankFlags ; point hl at our flags
    set 4, [hl] ; bit 4 is oam dma transfer
    halt ; wait
    pop hl
    pop af ; restore our stack values
    ret ; we done here

; multiplies a by 8
multiply_by_eight:
    sla a
    sla a
    sla a ; logical shift left 3 times to multiply by 8
    ret ; if it is 0, return

textbox_test:
    call draw_textbox
    buffertextbox test_box
    call do_textbox
    ; waste a lot of time
    ld a, $FF
    ld [wSubLoopCount], a
    call waste_time
    call clear_textbox
    ; attempt to get rid of textbox
    call remove_textbox
    

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

; removes the textbox from the screen
; needs 4 vblank cycles to finish
; $99C0, $99E0, $9A00, $9A20
remove_textbox::
    push hl
    push bc
    push de
    push af ; backup registers
    ld hl, $99C0 ; load first line into hl
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
    ; pop everything off the stack
    pop af
    pop de
    pop bc
    pop hl
    ret ; return to caller function




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
