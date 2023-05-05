include "include/hardware.inc/hardware.inc"
include "constants.asm"


SECTION "VBlank Handler", rom0
do_vblank::
    ; backup everything
    push af
    push hl
    push bc
    push de
    ld a, [wVBlankFlags] ; load flags
    bit 0, a ; check bit 0
    jp nz, vblank_blink_textbox ; if its set, skip everything and go there
    bit 2, a ; check if we need to disable the lcd
    call nz, vblank_disablelcd
    bit 4, a ; should we do a DMA transfer?
    jp nz, vblank_do_oamdma
    ; load variable to find out
    ld a, [wVBlankAction]
    cp NOTHING ; if zero, just exit
    jp z, vblank_exit
    cp STRCPY ; if 2, do an strcopy
    jp z, vblank_strcopy
    cp TILECPY ; if 3, copy a line into vram
    jp z, vblank_copy_tile
    cp CLEARLINE ; if 4, we need to clear a line
    jp z, vblank_clear_textbox_line
    cp CLEARFULLLINE ; do thwy want to clear a textbox?
    jp z, vblank_clear_full_line


; copies our routine for waiting on OAMDMA into hram
init_oamdma_hram::
    ld hl, oam_dma_loop ; set hl to our loop address
    ld de, hDMALoop ; set de to our destination
.loop
    ld a, [hl] ; load byte from hl
    cp $FE ; is it the first half of our terminator
    jr z, .check ; check the rest if it is
.back
    ld [de], a ; otherwise, copy into de
    inc hl
    inc de ; increment source and desitnation
    jr .loop ; go back to the loop
.check
    inc hl ; increment source
    ld a, [hl] ; get that byte
    cp $EF ; is it the other half of the terminator?
    jr z, .done ; if yes, exit
    dec hl ; otherwise, decrease hl
    ld a, [hl] ; reload previous byte into a
    jr .back ; jump back into the loop
.done
    ret ; exit back to caller function


; this code gets copied into hram
oam_dma_loop:
    ; copied from pandocs
    ldh [c], a
.wait
    dec b ; decrease b by one
    jr nz, .wait ; if b is not 0, loop more
    ret
    db $FE, $EF ; terminator magic

; runs an OAMDMA transfer from our buffer in wram
vblank_do_oamdma:
    ld a, HIGH(wOAMBuffer) ; get address of where to start the DMA from
    ld bc, $2946 ; b = wait time, c = LOW($FF46) or dma register
    ld de, .exit
    push de
    jp hDMALoop ; jump to our hram code
.exit
    ld hl, wVBlankFlags ; load our flags bit
    res 4, [hl] ; reset bit 4
    jp vblank_exit ; exit vblank

def arrow equ $3D ; where the textbox advance arrow goes
; if drawing to bgmap: $9A32
; if drawing to top of window: $9c72
def arrow_location equ $9C72 ; address the arrow gets put at
def textbox_line equ $21
; blinks the arrow on the textbox
vblank_blink_textbox::
    ldh a, [hVBlank_counter] ; load vblank counter into a
    cp 20 ; have there been 20 vblanks?
    jr nz, .nothing ;  if no, yeet
    ld hl, wVBlankFlags ; load flags into hl
    bit 1, [hl] ; do we display arrow or
    jr nz, .arrow ; display arrow
    ld a, textbox_line ; line
    set 1, [hl] ; sett bit
    jr .draw
.arrow
    ld a, arrow ; put arrow into a
    res 1, [hl] ; reset bit
.draw
    ld [arrow_location], a ; put new tile index into memory
    xor a ; reset a
    ldh [hVBlank_counter], a ; to reset the counter
    jr .done ; exit but differently
.nothing
    inc a ; add one to our counter
    ldh [hVBlank_counter], a ; store it back into memory
.done
    jp vblank_exit ; leave once done 

; clears out textbox lines
; line set via HL
vblank_clear_textbox_line:
    xor a ; zero out a
    ld b, a ; put 0 into b
.loop
    ld a, b ; load b into a
    cp 18 ; have we looped 18 times?
    jr z, .done ; leave if so
    xor a ; 0 into a
    ld [hl], a ; put 0 at hl
    inc hl
    inc b
    jr .loop
.done
    jp vblank_exit ; leave
    


; copies a single tile from wTileBuffer into wTileAddress
vblank_copy_tile::
    ld a, [wTileAddress] ; get high byte of address
    ld h, a ; and put it into h
    ld a, [wTileAddress + 1] ; get low byte
    ld l, a ; and put it into l
    ld de, wTileBuffer ; load tile buffer address into de
    ld a, [de] ; load tile
    ld [hl], a ; into the address where it goes lol
    jp vblank_exit ; we're done here
    

; exit vblank entirely
vblank_exit:
    ; reset the vblank action variable
    xor a
    ld [wVBlankAction], a
    ld hl, wVBlankFlags; load flags byte into a
    bit 3, [hl] ; do we renable the lcd?
    jr z, .skip ; if not, just yeet
    call nz, enable_lcd ; otherwise do so
    res 3, a ; reset bit 3
    ld [wVBlankFlags], a ; store it
.skip
    call gbt_update ; every frame, update our audio
    pop de
    pop bc
    pop hl
    pop af
    reti 
    

vblank_disablelcd:
; disable the LCD
; reset bit 7 of LCDC
    push hl
    ld hl, rLCDC
    res 7, [hl]
    ld hl, wVBlankFlags ; load flags byte
    res 2, [hl] ; reset disable flag
    pop hl
    ret
    
enable_lcd::
; reanable the lcd by setting bit 7 of lcdc
    push hl
    ld hl, rLCDC
    set 7, [hl]
    pop hl
    ret 

charmap "@", $FF

; copies a string from strbuffer to location
vblank_strcopy:
    ; set hl to be the desitnation address
    ; first by loading the high byte
    ld a, [wStringDestHigh]
    ld h, a
    ; then low byte
    ld a, [wStringDestLow]
    ld l, a
    ; move that into de
    push hl
    pop de
    ; load string buffer start
    ld hl, wStringBuffer
.loop
    ; is the current char @?
    ld a, [hl]
    cp "@"
    jr z, .done ; if so, exit
    ; otherwise, copy byte from hl to de
    ld a, [hl]
    ld [de], a
    ; increment de and hl
    inc de
    inc hl
    ; go back to the loop
    jr .loop
.done
    ; exit vblank
    jp vblank_exit

; clears an entire line
; 20 chars per line
vblank_clear_full_line:
    xor a ; put a 0 into a
    ld b, a ; put 0 into b
.loop
    ld [hl], a ; store 0 at hl
    inc hl ; increment dest address
    inc d ; increment b
    ld a, d ; store d into a
    cp 20 ; is it 20?
    jr z, .done ; jump
    xor a ; zero out a
    jr .loop ; keep looping
.done
    jp vblank_exit ; we're done here