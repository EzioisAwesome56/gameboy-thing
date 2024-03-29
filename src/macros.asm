MACRO loadstr ; loads a string from a rombank
    ld a, BANK(\1) ; get bank number
    ld b, a ; put it where it goes
    ld hl, \1
    farcall prepare_buffer
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
    halt
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
    ld a, BANK(\1) ; get rombank of tiles
    ld [wTileBank], a ; put that into memory
    farcall load_tiles_vram
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

MACRO farcall ; call a function in another rom bank
    ld a, BANK(\1)
    ld de, \1
    call bankswitch_exec
ENDM

MACRO buffertextbox ; buffer textbox content from an address
    ; first, get rom bank
    ld a, BANK(\1)
    ld b, a ; load the bank into b
    ld hl, \1 ; point hl at source address
    farcall buffer_textbox_content
ENDM

; macros used for map scripts/map headers
MACRO coord_event ; add a new coordinate event to a map script
    db \1, \2 ; x and y coords
    db BANK(\3) ; get bank of label
    dw \3 ; address of script
ENDM

MACRO script_loadtext ; loads a textbox script
    db load_text
    db BANK(\1)
    dw \1
ENDM

MACRO load_map ; loads a map based on label
    ld b, BANK(\1)
    ld hl, \1
    farcall load_overworld_map
ENDM

MACRO map_tile_pointer ; easy macro for defining tile data in memory
    db BANK(\1)
    dw \1
endm

MACRO waste_cycles ; easily waste cycles doing nothing!
    ld a, \1
    ld [wSubLoopCount], a
    farcall waste_time
ENDM

MACRO define_encounter ; shortcut for defining an encounter
    db bank(\1)
    dw \1 ; data pointer
    db \2 ; level information
ENDM

MACRO encounter_table ; shortcut for map header encounter table shit
    db BANK(\1)
    dw \1
ENDM

MACRO script_true_false ;inserts the scripts for true and false after a flag check
    db bank(\1)
    dw \1
    db bank(\2)
    dw \2
ENDM

MACRO script_flagptr ; inserts a pointer to the flag into the code
    db HIGH(\1)
    db LOW(\1)
ENDM

MACRO script_encounterdata ; inserts properly formatted encounter data into a map script 
    db bank(\1) ; bank of foe data
    dw \1 ; address of foe data
    db \2 ; level of foe
    db high(\3), low(\3) ; flag to set if battle is won
ENDM