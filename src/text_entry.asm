section "On-Screen Keyboard", romx
include "macros.asm"
include "constants.asm"
; prompts the user for text of 7 characters
; writes result to wStringBuffer
; displays prompt from wStringBuffer
prompt_for_text::
    push bc
    push hl
    push de
    call init_onscreen_keyboard
    call enable_lcd
    call text_entry_loop ; run the loop
    call copy_result ; copy the inputted text into wStringBuffer
    farcall clear_oam ; empty out the OAM
    call queue_oamdma
    call disable_lcd ; lcd turns off
    call clear_bg_tilemap ; delete the bg tilemap
    pop bc
    pop hl
    pop de
    ret ; leave

; the main loop for the text entry sub routine
text_entry_loop:
    ld hl, joypad ; point hl at the joypad
.loop
    call select_dpad ; make the dpad the active matrix selection
    ld a, [hl]
    ld a, [hl] ;  load the state of  the dpad into a
    ld a, [hl]
    bit 3, a ; is down pressed?
    jr z, .down ; handle that
    bit 0, a ; is right pressed
    jr z, .right ; handle that too
    bit 1, a ; is left pressed?
    jr z, .left ; handle left
    bit 2, a ; is up pressed?
    jr z, .up ; handle up
    call select_buttons ; switch matrix to the action buttons
    ld a, [hl]
    ld a, [hl] ; load state of buttons into a
    ld a, [hl]
    bit 0, a ; is a pressed?
    jr z, .abutton ; handle that
    bit 1, a ; is b pressed
    jr z, .bbutton ; go handle that
    bit 3, a ; is start pressed?
    jp z, .start ; handle that if so
    jr .loop
.up
    ld a, [wTextArrowRow]
    dec a
    ld [wTextArrowRow], a
    jr .update
.left
    ld a, [wTextArrowColumn]
    dec a
    ld [wTextArrowColumn], a
    jr .update
.down
    ld a, [wTextArrowRow] ; load the current row
    inc a ; add 1 to a
    ld [wTextArrowRow], a ; update it
    jr .update
.right
    ld a, [wTextArrowColumn]
    inc a
    ld [wTextArrowColumn], a
    jr .update
.update
    call handle_selection_bounds
    call update_text_arrow_position
    jr .wastecycles
.abutton
    call handle_a_press ; figure out what character they selected
    ld b, a ; put it into b
    ld a, [wTextIndex] ; load the current index
    cp 7 ; is it 8?
    jr z, .loop ; do NOT add another letter
    ld a, b ; put b back into a
    call add_leter ; append letter
    call update_displayed_text ; update the text
    call update_index_arrow
    jr .wastecycles
.bbutton
    ; here we remove a letter from the buffer
    push hl ; backup hl
    ld a, [wTextIndex] ; load the index into a
    sub 1 ; subtract 1
    call c, .bunderflow ; fix underflow
    ld hl, wTextEntryBuffer ; point hl at the buffer
    call sixteenbit_addition ; add A to HL
    ld a, empty ; a is now the empty char
    ld [hl], a ; update the buffer
    ld a, [wTextIndex] ; get the index again
    sub 1 ; subtract 1
    call c, .bunderflow
    ld [wTextIndex], a ; update the index
    call update_displayed_text ; update the text being displayed
    call update_index_arrow
    pop hl ; get hl off the stack
    jr .wastecycles
.bunderflow
    xor a ; 0 into a
    ret ; yeet
.wastecycles
    ld a, 65
    ld [wSubLoopCount], a
    farcall waste_time
    jp .loop
.start
    ; basically prompt if the user is done
    call handle_start_button ; this routine does the dirty work
    ld a, b ; load b into a
    cp 1 ; do we want to exit?
    jr z, .bunderflow ; we can cheat and use that ret opcode if yes
    jr .wastecycles ; otherwise, go back into the loop

; make sure the arrow cannot leave the allowed bounds of its selections
handle_selection_bounds:
    ld a, [wTextArrowRow] ; load the row
    cp 6 ; is it 6?
    call z, .rowmaxfix
    cp $FF ; underflow?
    call z, .rowunderflowfix
    ld a, [wTextArrowColumn] ; load the colum
    cp $FF ; underflow?
    call z, .columnunderflow
    cp 9 ; is it 9?
    call z, .columnoverflow
    jr .retopc
.rowmaxfix
    ld a, 5
.saverow
    ld [wTextArrowRow], a
.retopc
    ret ; yeet
.rowunderflowfix
    xor a ; 0 into a
    jr .saverow
.columnunderflow
    xor a
    jr .savecolumn
.savecolumn
    ld [wTextArrowColumn], a
    jr .retopc
.columnoverflow
    ld a, 8 ; load 8 into a
    jr .savecolumn

; copies the resulting string into wStringBuffer
copy_result:
    ld b, 7 ; we need to copy 7 bytes
    ld hl, wTextEntryBuffer
    ld de, wStringBuffer
    call copy_bytes ; copy to the string buffer
    ld a, terminator ; load terminator into a
    ld [de], a ; append to the end of the buffer
    ret ; yeet

; deal with all the bullshit involved with selecting a letter
; mostly the row/column shit
handle_a_press:
    ld a, [wTextArrowRow] ; load the current row into a
    cp 0 ; is it the top row?
    jr z, .row0
    cp 1 ; second row?
    jr z, .row1
    cp 2 ; third row?
    jr z, .row2
    cp 3 ; fourth row?
    jr z, .row3
    cp 4 ; fith row?
    jr z, .row4
    cp 5 ; sixth row?
    jr z, .row5
.row0
    ld e, start_of_upperletters ; e is now "A"
    jr .getletter
.row1
    ld e, start_of_upperletters + 9 ; e is now J
    jr .getletter
.row2
    ld a, [wTextArrowColumn] ; load the column into a
    cp 8 ; is it the very end of the row?
    jr z, .row2_startlower ; if yes, go deal with that
    ld e, start_of_upperletters + 18 ; e is now S
    jr .getletter
.row2_startlower
    ld e, start_of_lowerletters ; get the start of lowercase letters
    xor a ; 0 into a
    jr .beans ;  skip loading the column
.row3
    ld e, start_of_lowerletters + 1 ; e is now b
    jr .getletter
.row4
    ld e, start_of_lowerletters + 10 ; e is now k
    jr .getletter
.row5
    ld a, [wTextArrowColumn] ; get the current column into a
    cp 7 ; 7 selected?
    jr z, .row5_space
    cp 8
    jr z, .row5_space
    ld e, start_of_lowerletters + 19 ; e is now t
    jr .getletter
.row5_space
    ld e, $00 ; e is now 0
    xor a ; a is now 0
    jr .beans
.getletter
    ld a, [wTextArrowColumn] ; load column into a
.beans
    add a, e ;  A = A + E
    ret ; yeet for now

; appends the letter in A to the buffer    
add_leter:
    ld b, a ; letter is now in b
    push hl ; backup hl
    ld hl, wTextEntryBuffer ; point hl at the buffer
    ld a, [wTextIndex] ; a is now the text index
    push af ; back this up for later
    call sixteenbit_addition ; add a to HL
    ld a, b ; b into a
    ld [hl], a ; update the string
    pop af ; restore a
    inc a ; add 1
    ld [wTextIndex], a ; store it back into the thing
    pop hl ; restore hl
    ret ; yeet

; prints wTextEntryBuffer to the screen
update_displayed_text:
    push hl ; backup hl
    ld b, 7 ; we want to copy 7 bytes
    ld hl, wTextEntryBuffer ; point hl at the buffer
    ld de, wStringBuffer ; de at the string buffer
    call copy_bytes
    ld a, terminator ; load a terminator into a
    ld [de], a ; put a terminator at the end
    ld hl, osk_text_entry_line ; point hl at the place where the string goes
    call strcpy_vblank ; update the text
    ; todo: move arrow forward 1
    pop hl
    ret

; handles when the start button is pressed
; b is 1 if we need to exit
handle_start_button:
    push hl ; backup hl
    ld a, [wOAMSpriteThree] ; get y pos
    ld d, a ; put into d
    ld a, [wOAMSpriteThree + 1] ; get x pos
    ld e, a ; put into e
    push de ; backup de
    buffertextbox osk_confirmation ; buffer the confirmation text
    farcall clear_textbox ; yeet the textbox
    farcall show_textbox ; show the textbox
    farcall do_textbox ; run our script
    farcall prompt_yes_no ; ask for user confirmation
    ld a, [wYesNoBoxSelection] ; load the selecion into a
    cp 1 ; did they pick yes?
    jr z, .yes
    jr nz, .no
.yes
    ld b, 1 ; set b to 1
.no
    push bc ; backup bc
    farcall hide_textbox ; hide the textbox
    farcall clear_textbox ; yeet the textbox contents again
    pop bc ; get bc back off the stack
    pop de
    ld a, d ; d into a
    ld [wOAMSpriteThree], a ; retore
    ld a, e 
    ld [wOAMSpriteThree + 1], a ; restore again
    ld a, 61 ; arrow up is slot 61
    ld [wOAMSpriteThree + 2], a ; restore original graphic
    xor a
    set 6, a ; set the y flip setting
    ld [wOAMSpriteThree + 3], a ; update the sprite in OAM
    call queue_oamdma
    pop hl ; also restore hl
    ret ; yeet

; update the arrow that points to where
; the next character will be at
update_index_arrow:
    ld a, [wTextIndex] ; load the current index
    ld c, 8 ; load 8 into c
    call simple_multiply ; do A * C
    ld b, a ; put it into b
    ld a, osk_uparrow_basex ; load the base x pos
    add a, b ; add b to a
    ld [wOAMSpriteThree + 1], a ; update x pox
    call queue_oamdma ; do a DMA transfer
    ret ; yeet

; routine to setup the OSK entirely
init_onscreen_keyboard:
    call disable_lcd ; turn off the LCD
    call clear_bg_tilemap ; clear the screen
    call set_textbox_direct ; switch textbox mode to direct
    call init_clear_buffer ; clear out the text buffer
    ld hl, osk_prompt_string ; point hl at the place where the prompt goes
    ld de, wStringBuffer ; de at the string buffer
    call strcpy ; display the string
    call init_config_uparrow ; configure the arrow
    ld a, textbox_vertline_left ; load left vertical line into a
    ld [$9827], a ; updatte tile map
    ; next, draw the big textbox
    ld hl, $9860 ;  top left corner of textbox
    ld b, 20 ; 20 tiles long
    ld c, 8 ; 16 tiles tall
    farcall draw_textbox_improved ; draw a textbox
    call init_config_righttarrow
    call init_draw_letters
    call init_draw_lowercase ; draw all the letters to the screen
    call init_last_clean
    call init_ram_variables ; clear out ram
    call init_draw_instructions ; draw the instructions
    call set_textbox_vblank ; reset ttextbox engine to vblank mode
    ret

init_clear_buffer:
    ld hl, wTextEntryBuffer ;  point hl at the buffer
    ld c, 0 ; set our counter to 0
.loop
    ld a, c ; load 0 into a
    cp 7 ; have we done this 7 times?
    ret z ; leave if yes
    ; otherwise, continue
    xor a ; load 0 into a
    ld [hl], a ; write 0 into hl
    inc hl ; move forward 1 byte
    inc c ; increment our counter
    jr .loop ; go back to the loop

; draws the up arrow below the text entry line
init_config_uparrow:
    ld a, 32
    ld [wOAMSpriteThree], a ; write ypos
    ld a, osk_uparrow_basex
    ld [wOAMSpriteThree + 1], a  ; write x pos
    ld a, 61 ; arrow facing down is slot 61 in vram
    ld [wOAMSpriteThree + 2], a ; write to sprite
    xor a ; 0 into a
    set 6, a ; enable y flip
    ld [wOAMSpriteThree + 3], a ; writye to attrrributes
    farcall do_oam_lcdoff ; update OAM
    ret ; we're done, leave

; moves the arrow based on the row and column
update_text_arrow_position:
    ld c, 16 ; load 16 into c
    ld a, [wTextArrowColumn] ; load a with the current column
    call simple_multiply ; do A * C
    ld b, a ; store it into b
    ld a, osk_base_arrowx ; get the base x coord
    add a, b ; add b to a
    ld [wOAMSpriteFour + 1], a ; update x pos
    ld c, 8 ; load c with 8
    ld a, [wTextArrowRow] ; get the current row
    call simple_multiply ; A * C again
    ld b, a ; put that into b
    ld a, osk_base_arrowy ; load the base y pos
    add a, b ; add b to a
    ld [wOAMSpriteFour], a ; update y pos
    call queue_oamdma ; do a DMA transfer
    ret ; leave


; configures the arrow that points at the character you want to select
init_config_righttarrow:
    ld a, osk_base_arrowy
    ld [wOAMSpriteFour], a ; write y pos
    ld a, osk_base_arrowx
    ld [wOAMSpriteFour + 1], a ; write x pos
    ld a, index_arrow_right
    ld [wOAMSpriteFour + 2], a ; write tile index
    farcall do_oam_lcdoff ; preform a dma transfer
    ret ; leave

; draws all the letters to the screen
init_draw_letters:
    xor a ; 0 into a
    ld c, a ; 0 into c
    ld b, a ; 0 into b
    ld hl, osk_first_row ; point hl at the first row
    ld e, start_of_upperletters ; point e at the start of uppercase letters
.loop
    ld a, c ; load our counter into a
    cp 9 ; have we done this 9 times?
    jr z, .parentloop ; do things with the parent loop
    ld a, e ; load e into a
    ld [hl], a ; update tilemap
    inc hl ; move desitnation forward 1
    ld a, $00 ; empty tile
    ld [hl], a ; update tilemap
    inc hl
    inc e
    inc c
    jr .loop ; go loop some more
.parentloop
    ld a, b ; load b into a
    cp 2 ; have we done this twice?
    ret z ; yeet
    xor a ; 0 into a
    ld c, a ; put 0 into c
    inc b ; add 1 to b
    push de ; baclup DE
    push bc ; backup bc
    ld c, b ; load b into c
    ld a, 32 ; put 32 into a
    call simple_multiply
    pop bc ; restore bc
    ld d, 0 ; 0 into d
    ld e, a ; put result into e
    ld hl, osk_first_row
    add hl, de ; add hl and DE together
    pop de ; restore de
    jr .loop

; draws the lowercase letters
; run right after drawing the uppercase letters
init_draw_lowercase:
    xor a ; load 0 into a
    ld b, a
    ld c, a ; reset counters n shit
    ld e, start_of_lowerletters
    ld a, e ; load e into a
    dec hl
    dec hl ; move back two
    ld [hl], a ; update tilemap
    ld hl, osk_first_row
    push de ; backup de
    ld d, 0 ; 0 into d
    ld e, 96 ; 64 into e
    add hl, de ; hl = hl + de
    pop de ; restore de
    inc e ; move forward 1 char
.loop
    ld a, c ; load c into a
    cp 9 ; have we done this 9 times?
    jr z, .parentloop
    ld a, e ; load e into a
    ld [hl], a ; write to tilemap
    inc hl
    ld a, $00 ; load space
    ld [hl], a ; update tile map
    inc hl
    inc e
    inc c ; increment counters
    jr .loop
.parentloop
    ld a, b ; load b into a
    cp 2 ; have we done this twice?
    ret z ; yeet
    inc b ; add 1 to b
    push bc ; backup b and c
    inc b
    inc b ; add 3 to b
    inc b
    ld c, b ; load b into c
    ld a, 32 ; load a with 32
    call simple_multiply ; a * c
    push de ; backup de
    ld d, 0
    ld e, a ; load a into e
    ld hl, osk_first_row
    add hl, de ; hl = hl + de
    pop de ; restore de
    pop bc ; restore b
    ld c, 0 ; load 0 into c
    jr .loop ; go loop

; make the last two things on the keyboard display as blank
; run after the lowercase routine
init_last_clean:
    dec hl
    dec hl ; move back 2
    ld a, $00
    ld [hl], a ; update tile map
    dec hl
    dec hl
    ld [hl], a ; update tile map again
    ret ; yeetus

; clear the ram we need
init_ram_variables:
    xor a ; 0 into a
    ld [wTextArrowRow], a
    ld [wTextArrowColumn], a ; 0 out the variables for state tracking
    ld [wTextIndex], a
    ret ; yeet

; draws the instruction text to the screen
init_draw_instructions:
    loadstr osk_instructions_1 ; load the first set of instructions
    ld hl, osk_instructions_line1 ; point hl at the destination
    ld de, wStringBuffer
    call strcpy ; display it
    loadstr osk_instructions_2 ; load the second set of instructions
    xor a ; 0 into a
    ld d, a ; load 0 into d
    ld e, 32 ; load 32 into e
    ld hl, osk_instructions_line1 ; point hl at the first line
    add hl, de ; add de to hl
    ld de, wStringBuffer ; point de at the source
    call strcpy ; copy the string into the tilemap
    ret 
