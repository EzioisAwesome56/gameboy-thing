SECTION "Font", romx
font:: incbin "res/fontup.2bpp"

section "Strings", romx, bank[2]
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
charmap "Z", 16
charmap "@", $FF
test_string:: db "NVIDIA SUCKS@"