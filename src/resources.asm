SECTION "Font", romx, bank[2]
font:: incbin "res/fontup.2bpp"
fontlow:: incbin "res/fontlow.2bpp"
punc:: incbin "res/punc.2bpp"
num:: incbin "res/num.2bpp"

section "Graphics", romx
banana:: incbin "res/banana.2bpp"
textboxgfx:: incbin "res/textbox.2bpp"
arrow:: incbin "res/arrow.2bpp"
outdoor_tiles:: incbin "res/outdoor.2bpp"

section "Palette information", romx, BANK[2]
def obj1_pal equ $FF48
obj_pal_1::
    ld hl, wPalletData ; set hl to be our palette buffer location
    ; color one: dark grey
    set 3, [hl]
    res 2, [hl]
    ; color 2: light grey
    set 4, [hl]
    res 5, [hl]
    ; color 3: black
    set 7, [hl]
    set 6, [hl]
    ; zero out the last part too just to be safe
    res 0, [hl]
    res 1, [hl]
    ; we can now load the palette now that it is created
    ld hl, wVBlankFlags ; first we need to point hl at our flags bit
    set 2, [hl] ; tell vblank to disable the lcd
    halt ; wait for vblank to do so
    ; once back, we can do the load
    ld a, [wPalletData] ; put our palette data into a
    ldh [obj1_pal], a ; store it into the first location
    call enable_lcd ; turn the lcd back on
    ; leave
    ret
    

section "Strings", romx, BANK[2]
; setup the charmap here
charmap " ", 0
charmap "A", 1
charmap "B", 2
charmap "C", 3
charmap "D", 4
charmap "E", 5
charmap "F", 6
charmap "G", 7
charmap "H", 8
charmap "I", 9
charmap "J", 10
charmap "K", 11
charmap "L", 12
charmap "M", 13
charmap "N", 14
charmap "O", 15
charmap "P", 16
charmap "Q", 17
charmap "R", 18
charmap "S", 19
charmap "T", 20
charmap "U", 21
charmap "V", 22
charmap "W", 23
charmap "X", 24
charmap "Y", 25
charmap "Z", 26
; lowercase
charmap "a", 35
charmap "b", 36
charmap "c", 37
charmap "d", 38
charmap "e", 39
charmap "f", 40
charmap "g", 41
charmap "h", 42
charmap "i", 43
charmap "j", 44
charmap "k", 45
charmap "l", 46
charmap "m", 47
charmap "n", 48
charmap "o", 49
charmap "p", 50
charmap "q", 51
charmap "r", 52
charmap "s", 53
charmap "t", 54
charmap "u", 55
charmap "v", 56
charmap "w", 57
charmap "x", 58
charmap "y", 59
charmap "z", 60
; punctuation
charmap "!", 62
charmap "?", 63
charmap ",", 64
charmap ".", 65
; numbers
charmap "0", 66
charmap "1", 67
charmap "2", 68
charmap "3", 69
charmap "4", 70
charmap "5", 71
charmap "6", 72
charmap "7", 73
charmap "8", 74
charmap "9", 75
; flow control chars
charmap "@", $FF ; terminator
charmap "<NL>", $FD ; next line
charmap "<BP>", $FC ; prompt for button input
charmap "<PTR>", $FB ; text pointer (3 bytes, ROMbank and address)
charmap "<CLR>", $FA ; clear text

; strings relating to system crashes
crash_string:: db "Gameboy has crashed!@"
rst38str:: db "RST38 crash@"
rst28str:: db "RST28 Crash@"
vba:: db "Visual Boy Advance@"
rst00str:: db "RST00 Crash@"

; strings for other shit
test_string:: db "Nvidia sucks@"
test_string2:: db "BEAN STICKS@"

test_box:: db "Did you know?<NL>"
    db "Linux is neat.<BP><CLR>"
    db "When it works,<NL>"
    db "anyway!<BP><CLR>"
    db "<PTR>", BANK(test_boxtwo), HIGH(test_boxtwo), LOW(test_boxtwo), "@"

test_boxtwo:: db "This text was<NL>"
    db "loaded by txtcmd!<BP>@"

test_boxthree:: db "Wow, now there is<NL>"
    db "a 2nd map event?<BP><CLR>"
    db "This is a cool<NL>"
    db "piece of code!<BP>@"

section "Overworld Map Headers", romx, bank[2]
; Map header format
; Byte 1: ROMBank of map tile information
; Bytes 2-3: Address of map tile information
; Byte 4: tileset ID
; Byte 5: how many events in map (max 6)
; 6 "coord event" entires per header (30 bytes total)
; Byte 1: x coord
; Byte 2: y coord
; Byte 3: ROMBank of Map Script
; Bytes 4-5: address of map script
test_map_header:: db BANK(test_map_tiles)
    dw test_map_tiles
    db 1 ; outdoor tileset
    db 2
    db 0, 0 ; 0 x, 0 y
    db BANK(test_script) ; bank of test script
    db high(test_script), low(test_script)
    db 0, 1 ;0x, 1y
    db bank(test_script2)
    db high(test_script2), low(test_script2)
    db $FD, $DF ; terminator

; MAP SCRIPTS - may be broken out into their own file eventually
; max. 30 bytets in size
; control characters
def open_text equ $FD ; one byte call
def close_text EQU $FC ; one byte call
def load_text EQU $FB ; 4 byte call: func, bank, address
def do_text EQU $FA ; one byte call
def script_end EQU $F9 ; one byte all

test_script:: db load_text, BANK(test_box)
    db high(test_box), low(test_box)
    db open_text, do_text, close_text, script_end
    db $FD, $DF

test_script2:: db load_text, bank(test_boxthree)
    db high(test_boxthree), low(test_boxthree)
    db open_text, do_text, close_text, script_end
    db $FD, $DF

Section "Overworld Map Tile Data", romx
def empty EQU $00 ; slot 0
def wall_tile equ $4D ; slot 77
def encounter1 equ $4E ; slot 78
def encounter2 equ $4F ; slot 79
def info_tile equ $50 ; slot 80
; each map is 20x18 tiles in size
test_map_tiles:: ds 20, wall_tile
    ds 20, "e"
    ds 340, "A" ; fill it with empty garbage data for now
