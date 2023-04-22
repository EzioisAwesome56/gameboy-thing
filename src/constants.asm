; textbox graphic constants
def textbox_toplefttcorner equ $1B
def textbox_topline equ $1F
def textbox_toprightcorner equ $1C
def textbox_vertline_left equ $22
def textbox_vertline_right equ $20
def textbox_bottomleft_corner equ $1D
def textbox_bottomright_corner equ $1E
def textbox_bottomline equ $21

; overworld engine constants
def encounter_table_buffer_size equ 21
def encounter_chance equ 20

; input constants
def joypad equ $FF00 ; location of joypad

; tilemap location constants
def topleft_bg_textbox equ $99C0
def start_player_battlegui equ $990A
def battle_playername equ $992B
def foe_statbox_start equ $9820
def foe_name_start equ $9841
def foe_sprite_area_start equ $982C
def tilemap_player_start equ $9902

; tile index constants
def foe_tile_start equ $80
def player_tile_start equ $AA
def largesprite_lineskip equ 25
def largesprite_vertloops equ 5
def largesprite_linelen equ 7

; battle engine constants
def player_statbox_length equ 8
def foe_statbox_length equ 7
def pstatbox_lineskip equ 22
def foe_statbox_lineskip equ 23
def tiledata_foe_start equ $8800
def tiledata_player_start equ $8AA0
def tilemap_player_hp equ $994B
def tilemap_foe_hp equ $9861
def tilemap_player_mp equ $996b
def tilemap_bigbox_top equ $99E1
def tilemap_bigbox_bottom equ $9A01
def tilemap_smallbox_atk equ $99EC
def tilemap_smallbox_itm equ $99F0
def tilemap_smallbox_run equ $9A10
def tilemap_smallbox_magic equ $9A0C
def battle_base_xpos equ 98
def battle_base_ypos equ 136
def hud_icons_vram_loc equ $8D40
def hud_hp_icon equ $9952
def hud_mp_icon equ $9972
def hud_hp_icoindex equ $D4
def hud_mp_icoindex equ $D5

; various other constants
def start_of_numbers equ $42
def foe_buffer_size equ 16
def right_arrow_tile equ $57
def hud_bytes equ 32
def temp_buffer_size equ 8

; font constants
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
; others
charmap "/", 88
charmap "+", 89

; textbox engine constants
; text command bytes
def terminator equ $FF
def newline equ $FD
def button equ $FC
def pointer equ $FB
def clear equ $FA
def print_foe equ $F9
def print_player equ $F8
def print_string_buffer equ $F7
; for BG: 99c0 = bottom 4 rows
; window is 9C00 = top 4 rows of the window
def textbox_upleft equ $9C00

; yes no box constants
def yesno_top equ $9C80
def yesline equ $9CA2
def noline equ $9CC2

; vblank constants
; vblank actions
def NOTHING EQU 0
; one is empty
def STRCPY equ 2
def TILECPY equ 3
def CLEARLINE equ 4
def CLEARFULLLINE equ 5

; magic engine constants
def large_textbox_start equ $9c80
def large_textbox_height equ 12
def spell0loc equ $9CA1
def magic_arrow_basey equ 72
def boostdef_mp_cost equ 4
def bless_mp_cost equ 12
def shieldbreak_mp_cost equ 24

; experience engine constants
def start_totalstatbox equ $9C80
def statbox_length equ 8
def hp_stat_line equ $9CA1
def mp_stat_line equ $9CC1
def atk_stat_line equ $9CE1
def def_stat_line equ $9D01
def exp_arrow_basex equ 102
def exp_arrow_basey equ 120
def exp_start_roulette equ $9CAF
def exp_roulette_number equ $9CD0

; window manipulation constants
def window_x equ $FF4B
def window_y equ $FF4A ; note: ypos 112 is where the textbox is perfectly visible
; tile ID constants
def empty EQU $00 ; slot 0
def wall_tile equ $4D ; slot 77
def encounter1 equ $4E ; slot 78
def encounter2 equ $4F ; slot 79
def info_tile equ $50 ; slot 80
def pathway_tile EQU $51 ; slot 81
def heal_tile equ $52 ; slot 82

; predef constants
def predef_heal equ 0

; vram constants go here
; tilemap
DEF VRAM_TILE EQU $8000