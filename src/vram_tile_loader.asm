include "constants.asm"

Section "VRAM Tile Loader ROM0", rom0
; switches to bank a and then loads tiles
switch_n_load:
    call bankmanager_switch ; switch rombanks
    xor a ; 0 out a
    ld c, a ; load 0 into c
    ld b, a ; load 0 into b
.loop
    ld a, c ; load c into a
    cp 16 ; have we done this 16 times?
    jr z, .next ; go to the larger loop body
    ld a, [hl] ; load byte at hl into a
    ld [de], a ; write to de
    inc hl
    inc de ; increment source and destination
    inc c ; add 1 to c
    jr .loop ; go to the top of the loop body
.next
    push de ; put DE on the stack
    ld a, [wTileCount] ; load the tile count into a
    dec a ; subtract 1 from a
    ld e, a ; write to e
    ld a, b ; load b into a
    cp e ; have we loaded all the tiles we need?
    pop de ; get DE off the stack now
    jr z, .done ; if yes, leave
    inc b ; otherwise, add 1 to b
    xor a ; load 0 into a
    ld c, a ; load into c
    jr .loop ; go and loop some more
.done
    call bankswitch_return ; switch back to previous rombank
    ret ; leave



section "VRAM Tile Loader ROMX", romx
; loads tiles into VRAM while the LCD is OFF
; starts at $8000
; loads from wTileLocation at wTileBank
; loads (16 * wTileCount) bytes into ($8000 + (16 * wTileSlot))
load_tiles_vram::
    call calculate_tile_address ; store the destination tile address into de
    ld a, [wTileLocation] ; load high byte of source address
    ld h, a ; store into h
    ld a, [wTileLocation + 1] ; low byte
    ld l, a ; into l
    ld a, [wTileBank] ; load rom bank into a
    call switch_n_load ; run the actual loader
    ret ; leave


; loads the starting address into DE
calculate_tile_address:
    ld de, VRAM_TILE ; point de at the start of the vram tile map
    ld a, [wTileSlot] ; load destination slot into a
    cp 0 ; is it slot 0?
    jr z, .done ; leave if yes
    ld b, a ; store that into b
    xor a ; load 0 into a
    ld c, a ; 0 out c
.loop
    ld a, c ; load c into a
    cp b ; have we finished the loop
    jr z, .done ; we have finished the loop, leave
    ld a, 16 ; load 16 into a
    add a, e ; a is now e + a
    ld e, a ; update e
    ld a, 0 ; load 0 into a
    adc a, d ; a is now d + a + carry
    ld d, a ; update d
    inc c ; add 1 to c
    jr .loop ; go loop some more
.done
    ret ; we've finished, leave

; do an OAM transfer while the LCD is off
do_oam_lcdoff::
    push de
    push bc
    ld a, HIGH(wOAMBuffer) ; load a with the high byte of our buffer
    ld bc, $2946 ; b = wait time, c = LOW of DMA register
    ld de, .exit
    push de
    jp hDMALoop ; jump to hram to preform the transfer
.exit
    pop bc
    pop de
    ret ; yeet