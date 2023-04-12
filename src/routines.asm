SECTION "Non-essential routines", ROMX
include "macros.asm"
include "constants.asm"

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

; converts number in HL into a string
; written too wStringBuffer
; only works for numbers <1000
number_to_string_sixteen::
    push bc ; backup bc
    push de ; also backup de
    ld de, wStringBuffer ; point de at the string buffer
    ld c, 100 ; load 100 into c
    call div_hl_c ; do the division
    call .appendchar ; append the char
    ld l, a ; load remainder into l
    ld c, 10 ; load 10 into c
    call div_hl_c ; do the division
    call .appendchar ; add the char to the string
    ld l, a ; put remainder into l
    call .appendchar ; then append to string
    ld a, $FF ; put terminator into a
    ld [de], a ; put it at the end of the string
    pop de
    pop bc ; restore what we backed up
    jr .leave ; jump down to return call
.appendchar
    ld b, start_of_numbers ; put 42 into b
    push af ; backup a
    ld a, l ; load answer into a
    add a, b ; add b to a
    ld [de], a ; write it to the buffer
    inc de ; move de forward 1
    pop af ; restore a
.leave
    ret ; go back to caller


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
    ld a, [hl] ; low byte of address
    ld e, a ; store it into e
    inc hl ; increment source address
    ld a, [hl] ; high byte of source address
    ld d, a ; store it into d
    pop af ; get rombank off the stack
    push hl ; backup hl before function call
    call load_map_tiles ; load map tiles into our buffer
    pop hl ; get hl back
    inc hl ; move to map tileset information
    ld a, [hl] ; load that into a
    call load_vram_maptiles ; load map tileset into vram
    call display_map ; display the map to the screen
    ret ; we have "finished" loading the map for now

; loads tileset a into vram
load_vram_maptiles:
    cp 0 ; is a 0?
    jr z, .outdoor ; load outdoor tileset
.outdoor
    queuetiles outdoor_tiles, 5, 77
    jr .done
.done
    ret ; we're done here

def map_start equ $9800 ; start of tilemap in vram
def map_end equ $9a33 ; end of tilemap
; displays the map at wMapTileBuffer into vram
display_map::
    ld hl, wVBlankFlags ; point hl at our vblank flags byte
    set 2, [hl] ; set the bit to disable the lcd
    halt ; wait for vblank
    ld hl, map_start ; point hl at the start of the tile map
    ld de, wMapTileBuffer ; point de at map tile buffer
    push bc ; backup bc
    xor a ; load 0 into a
    ld b, a ; put 0 into b
    ld c, a ; put 0 into c
.loop
    ld a, c ; load c into a
    cp 20 ; have we copied an entire line?
    jr z, .linecheck ; prepare the next line, if any
    ld a, [de] ; load current byte at de
    ld [hl], a ; store it into hl
    inc hl ; increment destination address
    inc de ; increment source address
    inc c ; increment counter
    jr .loop ; go back to the loop
.linecheck
    ld a, b ; load b into a
    cp 17 ; have we done this 18 times?
    jr z, .done ; leave
    push bc ; otherwise, we need to backup bc
    xor a ; 0 into a
    ld b, a ; put 0 into b
    ld a, 12 ; put 12 into a
    ld c, a ; put 12 into c via a
    add hl, bc ; add bc and hl together, this moves destination address to the next line
    pop bc ; get bc off the stack
    xor a ; 0 into a
    ld c, a ; reset counter
    inc b ; add 1 to b
    jr .loop ; go back to the loop
.done
    pop bc ; pop bc off the stack
    call enable_lcd ; turn on the LCD
    ret ; return to caller function



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

; load map tiles from de in bank a
; does not preserve hl
load_map_tiles:
    ld hl, sram_map_copier ; point hl at our map copier routine
    call mbc_copytosram ; copy our routine into sram
    push de ; move de onto the stack
    pop hl ; and put it into hl
    ld de, sCodeBlock ; point de at our sram codeblock
    call mbc3_enable_sram ; open sram
    call bankswitch_exec ; execute our code
    call mbc3_disable_sram ; close sram
    ret ; yeet out of there

; gets copied into sram
; copies 360 bytes to wMapTileBuffer from hl
sram_map_copier:
    ld de, wMapTileBuffer ; point de at our tile buffer in memory
    push bc ; backup bc
    ld bc, wEndMapBuffer ; point bc at the end of our buffer
.loop
    ld a, c ; load c into a
    cp e ; is it equal to e?
    jr z, .check ; check the high byte
.resume
    ld a, [hl] ; load byte into a
    ld [de], a ; store byte at de
    inc hl ; increment source address
    inc de ; increment desitnation address
    jr .loop ; go look some more
.check
    ld a, b ; load b (high byte) into a
    cp d ; is a equal to d?
    jr nz, .resume ; if not, go loop
.done
    pop bc ; pop bc off the stack
    ret ; return to caller
    db $FE, $EF ; sram copier terminator
