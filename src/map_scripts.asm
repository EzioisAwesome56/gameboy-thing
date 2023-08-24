include "constants.asm"
include "macros.asm"
include "eventflag_constants.asm"

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
def flag_check equ $F7 ; 9 byte call, flag no, bit no, true bank + addr, false bank + addr
def set_flag equ $F6 ; 3 byte call, flag #, bit #
def run_predef equ $F5 ; two byte call, predef routine
def run_asm equ $F4 ; one byte call, starts executing from next byte
def start_encounter equ $F3 ; six byte call; foe data (bank, addr), level, flag pointer

route1_lawnwarp_script::
    db abutton_check
    db run_predef, predef_invalidate_map
    db run_asm
    ld a, 16
    ld [wPlayerx], a
    ld a, 12
    ld [wPlayery], a
    load_map player_lawn_header
    ret ; yeet
    db $FD, $DF

player_lawn_mailbox_script::
    db abutton_check
    script_loadtext playerlawn_mailbox_Script ; load the script
    db open_text, do_text, close_text
    db script_end
    db $FD, $DF

player_lawn_sign_script::
    db abutton_check
    script_loadtext playerlawn_sign_textscript
    db open_text, do_text, close_text
    db script_end
    db $FD, $DF

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

player_lawn_route1_warp::
    db abutton_check
    db run_predef, predef_invalidate_map
    db run_asm
    ld a, 1
    ld [wPlayerx], a ; update the x coord
    ld a, 15
    ld [wPlayery], a ; update y coord
    load_map route1_header
    ret ; yeet?
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

route1_exitwarp_script::
    db abutton_check ;  check if a is pressed
    db run_predef, predef_invalidate_map ; invalidate current map information
    db run_asm ; switch to assembly mode
    ld a, 1 ; x coord is 1
    ld [wPlayerx], a
    ld a, 8 ; y coord is 8
    ld [wPlayery], a
    load_map route2_header
    ret ; leave
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

tent_heal_script:: 
    db abutton_check
    script_loadtext outdoor_tent_text
    db open_text, do_text
    db run_predef, predef_heal ; run the heal script
    db close_text
    db script_end
    db $FD, $DF

route1_boss_script::
    db flag_check ; we want to check a flag
    script_flagptr beat_route1_miniboss ; we want to check this flag
    script_true_false route1_boss_alreadybeat, route1_boss_notfought
    db script_end ; end the script
    db $FD, $DF

route1_boss_alreadybeat:
    ; TODO: make this script not suck
    db abutton_check ; check if a is pressed
    db run_predef, predef_hide_player
    db run_predef, predef_invalidate_map
    script_loadtext route1_boss_afterfight_text ; just use some dummy text
    db open_text, do_text, close_text
    db script_end ; end of script
    db $FD, $DF
    
route1_boss_notfought:
    script_loadtext route1_boss_prefighttext
    db run_predef, predef_hide_player ; hide the player's sprite
    db open_text, do_text, close_text
    db start_encounter ; start a scripted encounter
    script_encounterdata mailbox_boss_data, 4, beat_route1_miniboss
    db flag_check
    script_flagptr beat_route1_miniboss
    script_true_false route1_boss_wonfight, no_script
    db script_end
    db $FD, $DF ; copier terminator

route1_boss_wonfight:
    db run_predef, predef_hide_player ; hide the player
    db run_predef, predef_invalidate_map ; invalidate to force a reload after
    script_loadtext route1_boss_wintext ; load the textbox script
    db open_text, do_text, close_text
    db script_end
    db $FD, $DF

no_script:
    db run_predef, predef_slient_heal
    db script_end
    db $FD, $DF

route2_sign_script::
    db abutton_check ; only activate if the abutton is pressed
    script_loadtext route2_sign_text
    db open_text, do_text, close_text
    db script_end
    db $FD, $DF

route1_sign_script::
    db abutton_check ; only activate if the a button is pressed
    db run_predef, predef_hide_player ; hide the player
    db run_predef, predef_invalidate_map ; invalidate to force a reload after
    script_loadtext route1_sign_text
    db open_text, do_text, close_text
    db script_end
    db $FD, $DF