SECTION "Non-essential routines", ROMX
include "macros.asm"

charmap "@", $FF
; take string HL and rombank B and copies it into the StringBuffer
prepare_buffer::
    push hl ; backup hl as we will be using it for something else
    ld hl, sram_copy ; load address of copy routine into hl
    call mbc_copytosram ; copy it into sram
    pop hl ; pop source address off stack again
    ; we need to set the desitnation address
    ld de, wStringBuffer
    ld a, d ; load high byte into a
    ld [wSramCopyDestination], a ; store it into ram
    ld a, e ; get low byte
    ld [wSramCopyDestination + 1], a ; store it into ram
    ld a, b ; move rombank number into a
    ld de, sCodeBlock ; set destination execution address to sram
    call mbc3_enable_sram ; enable sram
    call bankswitch_exec ; switch banks and execute our code in sram
    call mbc3_disable_sram ; disable sram
    ret ; we're done, so leave


; code to be copied from ROM to SRAM
; does the actual copting of data from a rom bank
sram_copy:
    ld a, [wSramCopyDestination] ; load high byte of destination into a
    ld d, a ; store it in d
    ld a, [wSramCopyDestination + 1] ; load low byte into sram
    ld e, a ; store it in e
.loop
    ld a, [hl] ; load character into a
    cp "@" ; is it our terminator?
    jr z, .done ; if yes, exit this loop
    ; otherwise, copy char into de
    ld [de], a
    inc hl ; inc source address
    inc de ; inc destination address
    jr .loop
.done
    ld [de], a ; a should still have the terminator so store it
    ret ; return from the function
    db $FE ; terminator half 1
    db $EF ; terminator half 2

; loads textbox text into the sram buffer
; loads from bank B at address HL
buffer_textbox_content::
    push hl ; backup HL
    ld hl, sram_copy ; load our copy routine into hl
    call mbc_copytosram ; copy it to sram
    pop hl ; pop hl off the stack
    ; setup destination address
    ld de, wLargeStringBuffer
    ld a, d ; get high byte of desitnation
    ld [wSramCopyDestination], a ; store it
    ld a, e ; get low byte
    ld [wSramCopyDestination + 1], a ; store it too
    ld de, sCodeBlock ; set execuation address
    ld a, b ; load rom bank address into a
    call mbc3_enable_sram ; open sram
    call bankswitch_exec ; switch banks and jump to de
    call mbc3_disable_sram ; once done, disable sram
    ret ; gtfo

; does what it says on the tin
waste_time::
    push af
    push bc
    xor a ; zero out a
    ld b, a ; load 0 into b
.mainloop
    cp $FF ; is A equal to ff?
    jr z, .subloop ; go to the sub loop if so
    inc a ; otherwise increase a
    jr .mainloop ; and go back to main loop
.subloop
    ld a, [wSubLoopCount] ; load value at wSubLoopCount into a
    ld c, a ; put a into c
    ld a, b ; load b into a
    cp c ; have we looped the amount of times we need to?
    jr z, .done ; exit if yes
    inc b ; otherwise, increment b
    xor a ; zero out a
    jr .mainloop ; and loop again!
.done
    pop bc
    pop af ; pop the backups off the stack
    ret ; leave

def joypad equ $FF00 ; location of joypad
def arrow_location equ $9A32 ; address the arrow gets put at
def textbox_line equ $21
; puts textbox in a loop of waiting for the a button to be pressed
; does not take any arguments
textbox_wait_abutton::
    push hl
    push af ; backup registers
    ld hl, joypad ; point hl at our joypad register
    res 5, [hl] ; select action button mode
    set 4, [hl] ; make sure dpad mode is not selected at all
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

; converts a number into a string
; resulting string is in wStringBuffer
number_to_string::
    nop
    nop
    