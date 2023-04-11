; textbox graphic constants
def textbox_toplefttcorner equ $1B
def textbox_topline equ $1F
def textbox_toprightcorner equ $1C
def textbox_vertline_left equ $22
def textbox_vertline_right equ $20
def textbox_bottomleft_corner equ $1D
def textbox_bottomright_corner equ $1E
def textbox_bottomline equ $21
; input constants
def joypad equ $FF00 ; location of joypad

; tilemap location constants
def topleft_bg_textbox equ $99C0
def start_player_battlegui equ $990B
def battle_playername equ $992C
def foe_statbox_start equ $9820
def foe_name_start equ $9841
def foe_sprite_area_start equ $982C

; battle engine constants
def player_statbox_length equ 7
def pstatbox_lineskip equ 23
def tilemap_foe_start equ $8800
def tilemap_player_hp equ $994C
def tilemap_foe_hp equ $9861
def tilemap_bigbox_top equ $99E1
def tilemap_bigbox_bottom equ $9A01
def tilemap_smallbox_atk equ $99EC
def tilemap_smallbox_itm equ $99F0
def tilemap_smallbox_run equ $9A10

; various other constants
def start_of_numbers equ $42

; font constants
charmap "/", $58