include "include/hardware.inc/hardware.inc"
; vram constants go here
; tilemap
DEF VRAM_TILE EQU $8000
; vblank actions
def NOTHING EQU 0
def LOADTILES EQU 1
def STRCPY equ 2
def TILECPY equ 3
def CLEARLINE equ 4
def CLEARFULLLINE equ 5


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
    cp LOADTILES ; if one, load the font
    jp z, vblank_load_tiles
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
    jp vblank_do_oamdma.exit ; what the fuck
    db $FE, $EF ; terminator magic

; runs an OAMDMA transfer from our buffer in wram
vblank_do_oamdma::
    ld a, HIGH(wOAMBuffer) ; get address of where to start the DMA from
    ld bc, $2846 ; b = wait time, c = LOW($FF46) or dma register
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


; used to load tiles into vram
; wTileLocation: address to tile data
; wTileCount: how many there are to load
; wTileSlot: starting slot to load tiles into
vblank_load_tiles:
    ; make sure our loop variable is set to 0
    xor a
    ld [wSmallLoop], a
    ; load the address of the tiles into hl
    ld a, [wTileLocation] ; get high byte
    ld h, a ; and put it into h
    ld a, [wTileLocation + 1] ; get low byte
    ld l, a ; and put it into l
    ; load 16 into bc for later
    ld a, 16
    call bc_set
.loop
    ld a, [wTileCount] ; load how many tiles there are into a
    push bc ; backup bc
    ld b, a ; and then put that into b
    ld a, [wSmallLoop] ; load how many times we have looped
    cp b ; compare with what is in our b value
    pop bc ; get bc off the stack now that we dont need it
    jp z, .exit ; if we have finished, exit
    ; otherwise, setup the variables for calling the load tile routine
    call load_tile
    ; if we are back here, we need to keep going
    add hl, bc ; add bc to hl to inc source addr
    ; increment our loop variable
    ld a, [wSmallLoop]
    inc a
    ld [wSmallLoop], a
    ; increment tile slot
    ld a, [wTileSlot]
    inc a
    ld [wTileSlot], a
    ; loop again
    jr .loop
.exit
    ; we are done loading the font. exit
    jp vblank_exit


; load a single tile from hl into slot wTileSlot
load_tile:
    ; backup bc and hl
    push bc
    push hl
    ; move hl into de
    push hl
    pop de
    ; load the desintation tile address into hl
    call calc_tile_address
    ; clean out the loop counter
    xor a
    ld [wTileLoop], a
    ; set bc to one
    inc a
    call bc_set
.loop
    ; have we looped 16 times?
    ld a, [wTileLoop]
    cp 16
    ; if yes, exit
    jr z, .exit
    ; otherwise load the current byte into memory
    ld a, [de]
    ld [hl], a
    ; inc destination address by 1
    add hl, bc
    ; inc source address by one via moving data around
    push hl
    push de
    pop hl
    add hl, bc
    push hl
    pop de
    pop hl
    ; increment our loop flag
    ld a, [wTileLoop]
    inc a
    ld [wTileLoop], a
    ; loop again
    jr .loop
.exit
    ; we are done here, exit
    pop hl
    pop bc
    ret


; quick routine to load a 8bit number into bc
bc_set:
    ld c, a
    xor a
    ld b, a
    ret 


calc_tile_address:
; used to find what address we need to write too
; returns staring addr in hl
    ; backup DE
    push de
    push bc
    ld hl, VRAM_TILE
    ; check if its zero
    ld a, [wTileSlot]
    cp 0
    jr z, .exit
    ; otherwise, reset the tile loop address to 0
    xor a
    ld [wTileLoop], a
    ; we need 16 in bc so go call that function
    ld a, 16
    call bc_set
.loop
    ; add bc to hl (increments by one tile)
    add hl, bc
    ; load our loop counter, and inc it
    ld a, [wTileLoop]
    inc a
    ; move a to d
    ld d, a
    ; load slot number into a
    ld a, [wTileSlot]
    ; is a eual to d?
    cp d
    jr z, .exit
    ; otherwise, store updated loop var and go again
    ld a, d
    ld [wTileLoop], a
    jr .loop
.exit
    ; we're done here, return
    pop bc
    pop de
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