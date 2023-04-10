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

; battle engine constants
def player_statbox_length equ 7
def pstatbox_lineskip equ 23