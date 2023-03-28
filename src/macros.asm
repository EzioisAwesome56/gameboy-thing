MACRO loadstr ; loads a string from a rombank
    ld a, BANK(\1) ; get bank number
    ld b, a ; put it where it goes
    ld hl, \1
    call prepare_buffer
ENDM

MACRO displaystr ; displays a string at an address of the tilemap
    ld hl, \1
    ld a, h
    ld [wStringDestHigh], a ; put high byte into buffer
    ld a, l
    ld [wStringDestLow], a ; put low byte into buffer
    ; next we need to tell vblank to display it
    xor a
    inc a
    inc a
    ld [wVBlankAction], a ; by setting vblank action to two
ENDM

MACRO queuetiles ; queue tiles to be loaded during vblank, needs address, total and starting slot
    ld hl, \1
    ld a, h
    ld [wTileLocation], a
    ld a, l
    ld [wTileLocation + 1], a
    ld a, \2
    ld [wTileCount], a
    ld a, \3
    ld [wTileSlot], a
    xor a
    inc a
    inc a
    ld [wDisableLCD], a ; tell vblank to turn off LCD but turn it back on when its done
    dec a
    ld [wVBlankAction], a ; tell vblank to load tiles
ENDM

MACRO updatetile ; queues vblank to update the tile at selected address
    ld a, h ; get high byte of hl
    ld [wTileAddress], a ; store it
    ld a, l ; get low byte of hl
    ld [wTileAddress + 1], a ; store it
    xor a ; 0 to a
    inc a
    inc a
    inc a
    ld [wVBlankAction], a ; set vblank action to copy tile
    halt ; wait for vblank to do the thing
ENDM

