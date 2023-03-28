include "include/hardware.inc/hardware.inc"
; vram constants go here
; tilemap
DEF VRAM_TILE EQU $8000
; vblank actions
def NOTHING EQU 0
def LOADTILES EQU 1
def STRCPY equ 2
def TILECPY equ 3


SECTION "VBlank Handler", rom0
do_vblank::
    ; backup everything
    push af
    push hl
    push bc
    push de
    ; check if we should disable the LCD
    ld a, [wDisableLCD]
    cp 1
    call z, vblank_disablelcd
    ; if its 2, then still disable it but then set the flag to 2
    ; so we know to reanable it after we leave this routine
    cp 2
    call z, vblank_disablelcd.subtract
    ; what action should we take?
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
    ; load the lcd disabled flag into a
    ld a, [wDisableLCD]
    ; is it 1?
    cp 1
    call z, enable_lcd
    jr nz, .skip
    ; save it
    dec a
    ld [wDisableLCD], a
    ; pop everything off the stack and return
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
    pop hl
    ret
.subtract
    dec a
    ld [wDisableLCD], a
    jr vblank_disablelcd
    
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