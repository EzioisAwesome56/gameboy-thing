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

; detect if we are running on 
vba_detection::
    ld a, $ED ; load some random value into A
    ld [$D000], a ; store it into $D000
    ld b, a ; store the value of a into b
    ld a, [$F000] ; load the same byte from echo ram into A
    cp b ; is the value equal to b?
    jr nz, .vba ; oh no we are using VBA
    ret ; oh, we passed, return
.vba
    ld a, $69 ; load 69 into a
    ld c, a ; put that into c
    push bc ; push it onto the stack
    jp crash_handler ; jump to crash handler

; converts a number into a string
; resulting string is in wStringBuffer
number_to_string::
    nop
    nop

; clears wOAMBuffer
clear_oam::
    push hl
    push af
    ld hl, wOAMBuffer ; point hl at our oam buffer
.loop
    ld a, l ; put l into a
    cp low(wEndOfOAM) ; is it the end of oam?
    jr z, .done ; exit
    xor a ; backup a
    ld [hl], a ; put a into hl
    inc hl ; increment hl
    jr .loop ; go loop some more
.done
    pop af
    pop hl
    ret

section "Overworld map loading routines", romx
; buffers map header from ROMbank b at address hl
buffer_map_header::
    push hl ; backup hl
    ld hl, map_header_copier ; point hl at our routine
    call mbc_copytosram ; copy it into sram
    pop hl ; pop hl back off the stack
    ld a, b ; put rombank number into a
    ld de, sCodeBlock ; point DE at the sram codeblock
    call mbc3_enable_sram ; open sram
    call bankswitch_exec ; execute itt
    call mbc3_disable_sram ; close sram
    ret ; return to caller routine

; buffers script at ROMBank b from address hl
buffer_map_script::
    push hl ; backup hl
    ld hl, map_script_copier ; point hl at our script copier
    call mbc_copytosram ; copy the copier to sram
    pop hl ; get hl back off the stack
    ld a, b ; put rombank into a
    ld de, sCodeBlock ; point de to our sram code block
    call mbc3_enable_sram ; open sram
    call bankswitch_exec ; execute our code
    call mbc3_disable_sram ; close sram
    ret ; leave lmao

; code to get executed from sram
; copies data from address HL into wMapHeader
map_header_copier:
    ld de, wMapHeader ; point de at our map header
.loop
    ld a, [hl] ; load what is at hl
    cp $FD ; is it first half of terminator?
    jr z, .check ; we need to check the second half next
.resume
    ld [de], a ; store hl into a
    inc de
    inc hl ; increment source and destination address
    jr .loop ; jump to the loop
.check
    inc hl ; increment hl
    ld a, [hl] ; load next byte into a
    cp $DF ; is it second half of terminator?
    jr z, .done ; we've finished, leave
    dec hl ; otherwise, decrement hl
    ld a, [hl] ; reload the contents of hl into a
    jr .resume ; resume copying
.done
    ret ; yeet the fuck outta there
    db $FE, $EF

; processes wMapHeader to load everything else
map_header_loader_parser::
    ld hl, wMapHeader ; point HL at our map header
    ld a, [hl] ; load ROMBank of tile data into a
    push af ; back this value up for later
    inc hl ; inc source address
    ld a, [hl] ; high byte of address
    ld d, a ; store it into d
    inc hl ; increment source address
    ld a, [hl] ; low byte of source address
    ld e, a ; store it into e
    ; TODO: write loader for map tile information
    pop af
    ret ; we have "finished" loading the map for now

; gets copied into sram and executed
; copeies script from HL into wMapScriptBuffer
map_script_copier:
    ld de, wMapScriptBuffer ; point de at our script buffer
.loop
    ld a, [hl] ; load byte at hl into a
    cp $FD ; is it first half of terminator?
    jr z, .check ; jump to check routine
.resume
    ld [de], a ; otherwise, copy byte a into de
    inc de
    inc hl ; inc dest and source address
    jr .loop ; go loop some more
.check
    inc hl ; increment source address
    ld a, [hl] ; load next byte
    cp $DF ; other half of terminator?
    jr z, .done ; leave
    dec hl ; if not, put the previous byte back into a
    ld a, [hl] ; the usual shit
    jr .resume  ; go back to the copier
.done
    ret ; leave
    db $FE, $EF
