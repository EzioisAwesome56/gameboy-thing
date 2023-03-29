SECTION "Font", romx
font:: incbin "res/fontup.2bpp"
fontlow:: incbin "res/fontlow.2bpp"
textboxgfx:: incbin "res/textbox.2bpp"
arrow:: incbin "res/arrow.2bpp"

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
; flow control chars
charmap "@", $FF ; terminator
charmap "$", $FD ; next line
charmap "%", $FC ; prompt for button input
charmap "&", $FB ; text pointer (3 bites, bank address)
charmap "*", $FA ; clear text
test_string:: db "Nvidia sucks@"
test_string2:: db "BEAN STICKS@"

test_box:: db "BEANSBEANSBEANSBEA$"
.line2: db "BEANS BEANS BEANS%*@"