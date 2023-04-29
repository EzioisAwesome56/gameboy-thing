include "constants.asm"
include "macros.asm"

section "Overworld Map Scripts", romx, bank[2]
; MAP SCRIPTS - may be broken out into their own file eventually
; max. 30 bytets in size
; control characters
def open_text equ $FD ; one byte call
def close_text EQU $FC ; one byte call
def load_text EQU $FB ; 4 byte call: func, bank, address
def do_text EQU $FA ; one byte call
def script_end EQU $F9 ; one byte all
def abutton_check EQU $F8 ; one byte call
def flag_check equ $F7 ; 9 byte call, flag addr, true bank + addr, false bank + addr
def set_flag equ $F6 ; 3 byte call, flag addr
def run_predef equ $F5 ; two byte call, predef routine
def run_asm equ $F4 ; one byte call, starts executing from next bytte

player_lawn_housewarp_script::
    db abutton_check ; check for a button
    db run_predef, predef_invalidate_map
    db run_asm
    ld a, 15 ; 15 into a
    ld [wPlayerx], a ; update x pos
    ld a, 11 ; 11 into a
    ld [wPlayery], a ; update y post
    load_map player_house_header
    ret ; yeet
    db $FD, $DF

player_house_doorscript::
    db abutton_check ; check if a is pressed
    db run_predef, predef_invalidate_map
    db run_asm ; switch to ASM mode
    ld a, 1 ; load 1 intto a
    ld [wPlayerx], a
    ld a, 11
    ld [wPlayery], a ; update map
    load_map player_lawn_header
    ret ; yeet
    db $FD, $DF

player_house_doorsign_script::
    db abutton_check ; only do the do if a is pressed
    script_loadtext playerhouse_door_sign
    db open_text, do_text, close_text
    db script_end
    db $FD, $DF

player_house_signone_script:: db abutton_check
    db load_text, bank(playerhouse_information_sign)
    dw playerhouse_information_sign
    db open_text, do_text, close_text
    db script_end
    db $FD, $DF

player_house_firstaid_script::
    db abutton_check
    script_loadtext playerhouse_firstaid_box
    db open_text, do_text
    db run_predef, predef_heal
    db close_text
    db script_end
    db $FD, $DF


demo_sign_script:: db abutton_check
    db open_text ; open the textbox
    db run_predef, predef_demo_runminiboxx
    db close_text
    db script_end
    db $FD, $DF

test_sign_script:: db abutton_check ; check for a button
    ;db flag_check
    ;dw sTestEvent ; check this flag in sram
    ;db BANK(sign_true_script) 
    ;dw sign_true_script
    ;db BANK(sign_false_script)
    ;dw sign_false_script
    db script_end
    db $FD, $DF

sign_true_script::
    db load_text, bank(sign_text2)
    dw sign_text2
    db open_text, do_text, close_text
    db script_end
    db $FD, $DF


sign_false_script:: db load_text, bank(sign_text)
    dw sign_text
    db open_text, do_text, close_text 
    ;db set_flag
    ;dw sTestEvent ; set the test event flag
    db script_end
    db $FD, $DF

heal_script:: db abutton_check
    ;db load_text, bank(tent_script)
    ;dw tent_script
    db open_text, do_text
    db run_predef, predef_heal ; run the heal script
    db close_text
    db script_end
    db $FD, $DF