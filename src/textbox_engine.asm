SECTION "Textbox Engine", romx
include "macros.asm"
include "constants.asm"
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
    ld a, [hl]
    ld a, [hl]
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
    cp print_foe ; do we print foe name
    jr z, .foe
    cp print_player ; do we print the player's name?
    jr z, .player
    cp print_string_buffer ; do we print string buffer?
    jr z, .stringbuffer
    ld [wTileBuffer], a ; otherwise, take the char and buffer it
    updatetile ; tell vblank to update it
    inc hl
    inc de
    jr .loop ; increment and continue the loop
.stringbuffer
    call print_stringbuffer
    inc de ; move to next byte
    jr .loop ; go loop
.player
    call print_player_name
    inc de ; move to next byte
    jr .loop ; do the funny!
.foe
    call print_foe_name ; print the foe's name to the textbox
    inc de ; move to next byte in buffer
    jr .loop ; go to the loop
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

; print the player's name to the textbox
print_player_name:
    push de ; backup de
    ld de, wPlayerName ; point de at player name buffer
.loop
    ld a, [de] ; load byte into de
    cp terminator ; is it the string terminator?
    jr z, .done ; yeet
    ld [wTileBuffer], a ; write to tile buffer
    updatetile ; make vblank update the tile
    inc de ; increment source
    inc hl ; increment destination
    jr .loop ; go loop some more
.done
    pop de ; restore de to what it was before
    ret ; leave

; prints the contents of wStringBuffer to textbox
print_stringbuffer:
    push de ; backup de
    ld de, wStringBuffer ; point de at the buffer
.loop
    ld a, [de] ; load byte into de
    cp terminator ; is it terminator?
    jr z, .done ; yeet
    ld [wTileBuffer], a ; write to the buffer
    updatetile ; make vblank update the tile
    inc de ; increment source
    inc hl ; increment desitnastion
    jr .loop ; go loop some more
.done
    pop de
    ret


; print the foe name to the textbox
print_foe_name:
    push de ; backup de
    ld de, wFoeName ; point de at foe name buffer
.loop
    ld a, [de] ; load byte into de
    cp terminator ; is it the terminator?
    jr z, .done ; no more text, leave
    ld [wTileBuffer], a ; write to tile buffer
    updatetile ; make vblank draw it to the screen
    inc de ; increment source
    inc hl ; increment desitnation
    jr .loop ; go back to the loop
.done
    pop de ; restore de
    ret ; leave

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

; compatibility for the function below
remove_textbox::
    call clear_window
    ret 
    

; removes the textbox from window tilemap
; needs 4 vblank cycles to finish
; $99C0, $99E0, $9A00, $9A20
clear_window::
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

; textbox only need to be 6 long
def yesno_top equ $9C80
prompt_yes_no::
    push hl ; backup hl
    call draw_yesno ; first, we draw it to the lower part of the window
    call draw_yesno_text
    call show_yesnobox ; show the yesnobox
    call do_yesno_loop
    call hide_yesnobox
    pop hl ; get hl back off the stack lol
    ret ; leave

def y_noopt equ 136
def y_yesopt equ 144
; loops until the user selects yes or no
do_yesno_loop:
    ; first we need to configure the arrow graphic into OAM slot 3
    ld a, y_yesopt ; load a with the yes opt y coord
    ld [wOAMSpriteThree], a ; store it into a
    ld a, 13 ; load x coord into a
    ld [wOAMSpriteThree + 1], a ; store that into OAM
    ld a, $57 ; load right arrow tile index into a
    ld [wOAMSpriteThree + 2], a ; store it into the OAM buffer
    call queue_oamdma ; do a DMA transfer
    xor a ; put 0 into a
    ld [wYesNoBoxSelection], a ; zero out the selection variable
    ld hl, joypad ; point hl at the joypad
.loop
    call select_dpad ; select the dpad first
    ld a, [hl]
    ld a, [hl] ; load state of controller into a...twice
    bit 2, a ; is up pressed?
    jr z, .up ; handle it
    bit 3, a ; is down pressed?
    jr z, .down
    call select_buttons ; switch to the button array
    ld a, [hl]
    ld a, [hl] ; load the state of the controller into a
    bit 0, a ; is a pressed?
    jr z, .select
    jr .loop ; go and loop some more forever
.up
    xor a ; load 0 into a
    inc a ; add one to a
    jr .update
.down
    xor a ; 0 out a
    jr .update
.update
    ld [wYesNoBoxSelection], a ; store the new selection into the ram variable
    cp 1 ; is the currently selected option 1?
    jr nz, .arrowyes ; move arrow to yes
    jr z, .arrowno ; move arrow to no
.arrowyes
    ld a, y_yesopt ; load the y value for the yes option into a
    jr .updsprite
.arrowno
    ld a, y_noopt ; load y value for no option into a
    jr .updsprite
.updsprite
    ld [wOAMSpriteThree], a ; store new y coord
    call queue_oamdma ; preform a DMA transfer
    jp .loop
.select
    ret ; the selection is already in memory, so we can just leave

def yesline equ $9CA2
def noline equ $9CC2
; draws the yes/no text to the box
draw_yesno_text:
    loadstr yesno_no ; buffer the no string first
    ld hl, noline ; point hl at the no line
    ld de, wStringBuffer ; point de at the string buffer
    xor a ; load 0 into a
    ld c, a ; load 0 into c
.loop
    ld a, [de] ; load the byte at DE into a
    cp $FF ; is is our terminator
    jr z, .done ; leave, maybe
    ld [wTileBuffer], a ; store it into the tile buffer
    updatetile ; make vblank update the tile
    inc hl
    inc de ; inc source and desitnation adress
    jr .loop
.done
    ld a, c ; load c into a
    cp 1 ; have we done this twice?
    jr nz, .continue
    ret ; otherwise, leave
.continue
    inc c ; add 1 to c
    loadstr yesno_yes ; buffer string
    ld hl, yesline ; point hl at destination line
    ld de, wStringBuffer ; point de at the source address
    jr .loop ; go loop again!



; slide the window up by 32 pixels
show_yesnobox:
    push bc ; backup bc
    xor a ; put 0 into a
    ld c, a ; put 0 into a
    ld hl, window_y ; point hl at the window y scroll register
.loop
    ld a, c ; load c into a
    cp 16 ; have we done this  16 times?
    jr z, .done ; leave
    halt ; wait for vblank to pas
    dec [hl]
    dec [hl] ; move up by 2 pixels
    inc c ; increment our counter
    jr .loop ; go loop some more
.done
    pop bc ; pop bc off the stack
    ret ; leave

; slides the box off the bottom of the screen
hide_yesnobox:
    push bc ; backup bc
    xor a ; put 0 into a
    ld [wOAMSpriteThree + 1], a ; hide the arrow sprite
    call queue_oamdma
    ld c, a 
    ld hl, window_y ; point gl at the window y register
.loop
    ld a, c ; load c into a
    cp 16 ; have we done this 12 times?
    jr z, .done ; leave if so
    halt ; wait for vblank
    inc [hl]
    inc [hl] ; add 2 to the window y register
    inc c ; increment our counter
    jr .loop ; go loop
.done
    pop bc ; get bc off the stack
    ret ; leave

; draw the yesno textbox
draw_yesno:
    push hl
    push de
    push bc ; backup  most registers
    xor a ; put 0 into a
    ld b, a
    ld c, a ; zero out some shit
    ld hl, yesno_top
    ld a, textbox_toplefttcorner ; load top left corner
    ld [wTileBuffer], a ; store it into the tile buffer
    updatetile ; wait for vblank to update it
    inc hl ; increment hl
.toploop
    ld a, c ; load c into a
    cp 4 ; have we done this 4 times?
    jr z, .mid ; go to the middle
    ld a, textbox_topline ; load a with the top line of the textbox
    ld [wTileBuffer], a
    updatetile ; wait for vblank to do ittt
    inc hl ; move hl to next address in vram
    inc c ; increment our counter
    jr .toploop
.mid
    ld a, textbox_toprightcorner ; load the top right conrer into memory
    ld [wTileBuffer], a ; store it into the buffer
    updatetile ; wait for vblank
    inc hl ; move hl up by one
.domidagain
    xor a ; 0 into a
    push bc
    ld b, a ; 0 into b
    ld a, 26 ; 26 into a (how many tiles until next line)
    ld c, a ; put that into c
    add hl, bc ; add hl and bc
    pop bc ; restore bc
    xor a ; 0 into a
    ld c, a ; put that into c
    ld a, textbox_vertline_left ; load the left side of the vertical line into a
    ld [wTileBuffer], a ; put that into the buffer
    updatetile ; wait for vblank
    inc hl ; move hl up by one
.midloop
    ld a, c ; load c into a
    cp 4 ; have we done this 4 times?
    jr z, .bottom ; go down to the next thing lol
    xor a ; load blank tile
    ld [wTileBuffer], a ; put it into the buffer
    updatetile ; wait for vblank to do the thing
    inc hl ; move to next adress
    inc c ; increment counter
    jr .midloop ; go loop some more
.bottom
    ld a, textbox_vertline_right ; load right vertical line
    ld [wTileBuffer], a ; store it
    updatetile ; wait for vblank
    inc hl ; move hl forward 1
    inc b ; add 1 to be
    ld a, b ; load b into a
    cp 2 ; is b 2?
    jr nz, .domidagain ; do the mid loop again
    ; otherwise, we fall thru to here
    ld a, 26 ; load 26 into a
    ld c, a ; put that into c
    xor a ; 0 out a
    ld b, a ; put 0 into b
    add hl, bc ; add hl and bc to get the next line
    ld c, a ; put 0 into a
    ld a, textbox_bottomleft_corner ; load bottom left corner into a
    ld [wTileBuffer], a ; put that into the tile buffer
    updatetile ; wait for vblank to update it
    inc hl ; move to next byte
.bottomloop
    ld a, c ; load c into a
    cp 4 ; have we done this 4 times
    jr z, .done ; leave this loop if so
    ld a, textbox_bottomline ; otherwise, put the bottom line into a
    ld [wTileBuffer], a ; store it into the buffer
    updatetile ; wait for vblank to update it
    inc hl ; move hl forward 1
    inc c ; add 1 to our counter
    jr .bottomloop ; go loop some more
.done
    ld a, textbox_bottomright_corner ; load the bottom right corner into a
    ld [wTileBuffer], a ; put that into the buffer
    updatetile ; make vblank update it
    ; at this point we are done drawing the smaller textbox
    pop bc
    pop de
    pop hl ; restore everything
    ret ; leave
