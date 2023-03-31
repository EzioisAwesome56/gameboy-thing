SECTION "Font", romx
font:: incbin "res/fontup.2bpp"
fontlow:: incbin "res/fontlow.2bpp"
textboxgfx:: incbin "res/textbox.2bpp"
arrow:: incbin "res/arrow.2bpp"
punc:: incbin "res/punc.2bpp"
num:: incbin "res/num.2bpp"

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