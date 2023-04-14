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

; font constants
charmap "/", $58

; textbox engine constants
; text command bytes
def terminator equ $FF
def newline equ $FD
def button equ $FC
def pointer equ $FB
def clear equ $FA
def print_foe equ $F9
def print_player equ $F8

; vblank constants
; vblank actions
def NOTHING EQU 0
def LOADTILES EQU 1
def STRCPY equ 2
def TILECPY equ 3
def CLEARLINE equ 4
def CLEARFULLLINE equ 5