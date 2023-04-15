section "Introduction Screen", romx, bank[2]
include "macros.asm"
def joypad equ $FF00
do_intro_screen::
    call detect_gameboy ; what gameboy do you own?
    call disable_lcd ; turn the lcd off
    loadstr gbdetectstr  ; load the detection str into memory
    call cheap_strcopy_top ; display  it to the screen
    call load_console_name ; get the name of our console
    call cheap_strcopy_bottom ; display it
    loadstr licensestr_pt1
    call cheap_strcopy_furtherabv
    loadstr licensestr_pt2
    call cheap_strcopy_abovelogo
    ld a, [wGameboyType] ; load gameboy type into a
    cp 4 ; is it less then 4?
    jp c, .nologo ; do not print our own logo
    loadstr nintendostr ; otherwise, load nintendo logo
    call cheap_strcopy_nintendo ; put it into place
.nologo
    loadstr pressastr
    call cheap_strcopy_bottomscreen
    call enable_lcd ; turn the lcd on
    ld hl, joypad ; point hl at the joypad
    call select_buttons ; select the buttons for input
.loop
    ld a, [hl]
    ld a, [hl] ; load hl several times
    ld a, [hl]
    bit 0, a ; is the a button pressed?
    jr nz, .loop ; if no, loop some more
    ret ; yeet if a is pressed


; copy strings without vblank
cheap_strcopy_top:
    ld de, $9800 ; setup de to point where we want to write
    jp strcpy_different
cheap_strcopy_bottom:
    ld de, $9820
    jp strcpy_different
cheap_strcopy_abovelogo:
    ld de, $98e4
    jp strcpy_different
cheap_strcopy_furtherabv:
    ld de, $98c4
    jp strcpy_different
cheap_strcopy_nintendo:
    ld de, $9904
    jp strcpy_different
cheap_strcopy_bottomscreen:
    ld de, $9a20
    jp strcpy_different

; simply copy the string into vram
strcpy_different::
    ld hl, wStringBuffer ; point hl at our string buffer
.loop
    ; is the current char @?
    ld a, [hl]
    cp $FF
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
    ret ; leave lol

; buffers the console name into memory
load_console_name:
    ld a, [wGameboyType] ; load our type flag into memory
    cp 0 ; DMG
    jr z, .dmg
    cp 1 ; pocket
    jr z, .pocket
    cp 2 ; SGB
    jr z, .sgb
    cp 3 ; SGB2
    jr z, .sgb2
    cp 4 ; color
    jr z, .color
    cp 5 ; advance
    jr z, .advance
    cp 6 ; unknown
    jr z, .error
.dmg
    loadstr dmgstr
    jr .done
.pocket
    loadstr pocketstr
    jr .done
.sgb
    loadstr sgbstr
    jr .done
.sgb2
    loadstr sgb2str
    jr .done
.color
    loadstr colorstr
    jr .done
.advance
    loadstr advancestr
    jr .done
.error
    loadstr errorstr
    jr .done
.done
    ret 

; detect what model of gameboy we are on
detect_gameboy:
    ld a, [wBootupVars] ; load bootup  value of a into, well, a
    cp $01 ; could be DMG or SGB1
    jr z, dmg_sgb
    cp $FF ; could be Pocket or SGB2
    jr z, pocket_sgb2
    cp $11 ; Color or Advance
    jr z, color_advance
    jr errorboy
.save
    ld [wGameboyType], a ; store it into the variable
    ret ; leave lol

; handle if its an SGB or DMG
dmg_sgb:
    ld a, [wBootupVars + 2] ; state of c on bootup
    cp $13 ; DMG
    jr z, .dmg
    cp $14 ; Super GameBoy
    jr z, .sgb
    jr errorboy
.dmg
    xor a ; put 0 into a
    jr detect_gameboy.save
.sgb
    ld a, 2 ; put 2 into a
    jr detect_gameboy.save

errorboy:
    ; do you have some weird-ass gameboy or smth
    ld a, 6 ; 6 is the IDFK value
    jr detect_gameboy.save

; handle finding out if its a pocket or a super gameboy 2
pocket_sgb2:
    ld a, [wBootupVars + 2] ; get the bootup value of c
    cp $13 ;  pocket
    jr z, .pocket
    cp $14 ; super gameboy 2
    jr z, .sgb2
    jr errorboy
.pocket
    ld a, 1
    jr detect_gameboy.save
.sgb2
    ld a, 3
    jr detect_gameboy.save
    
; handles gbc and gba
color_advance:
    ld a, [wBootupVars + 1] ; get bootup value of b
    cp $00 ; gameboy color
    jr z, .color
    cp  $01 ; Gameboy advance
    jr z, .advance
    jr errorboy
.color
    ld a, 4
    jr detect_gameboy.save
.advance
    ld a, 5
    jr detect_gameboy.save

