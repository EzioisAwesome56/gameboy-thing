include "constants.asm"
include "macros.asm"

SECTION "Font", romx, bank[2]
font:: incbin "res/fontup.2bpp"
fontlow:: incbin "res/fontlow.2bpp"
punc:: incbin "res/punc.2bpp"
num:: incbin "res/num.2bpp"
forslash:: incbin "res/forslash.2bpp"
plus:: incbin "res/plus.2bpp"

section "Graphics", romx
banana:: incbin "res/banana.2bpp"
textboxgfx:: incbin "res/textbox.2bpp"
arrow:: incbin "res/arrow.2bpp"
arrow_right:: incbin "res/arrow_right.2bpp"
battle_hud_icons:: incbin "res/hud_icons.2bpp"
player_ow:: incbin "res/player_ow.2bpp"

section "Map Tilesets", romx, bank[2]
outdoor_tiles:: incbin "res/outdoor.2bpp"
indoor_wood:: incbin "res/indoor_wood.2bpp"

section "Battle Graphics", romx, bank[2]
evil_cardbox:: incbin "res/evil_cardbox.2bpp"
player_back:: incbin "res/player.2bpp"
blobcat:: incbin "res/blobcat.2bpp"
tux:: incbin "res/tux.2bpp"
envelope:: incbin "res/envelope.2bpp"

section "Palette information", romx, BANK[2]
def obj1_pal equ $FF48
def bgp_pal equ $ff47
obj_pal_1::
    ld hl, wPalletData ; set hl to be our palette buffer location
    ; color one: dark grey
    res 0, [hl]
    res 1, [hl]
    ; color 2: light grey
    set 2, [hl]
    res 3, [hl]
    ; color 3: dark grey
    res 4, [hl]
    set 5, [hl]
    ; color 4: black
    set 6, [hl]
    set 7, [hl]
    ; we can now load the palette now that it is created
    ld a, [wPalletData] ; put our palette data into a
    ldh [obj1_pal], a ; store it into the first location
    ; leave
    ret
background_pal::
    ld hl, wPalletData
    ; color 1: white
    res 0, [hl]
    res 1, [hl]
    ; color 2: light grey
    set 2, [hl]
    res 3, [hl]
    ; color 3: dark grey
    res 4, [hl]
    set 5, [hl]
    ; color 4: black
    set 6, [hl]
    set 7, [hl]
    ld a, [hl] ; load our shiny new palette into a
    ldh [bgp_pal], a ; store it into the bgp pal location
    ; leave
    ret
    

section "Strings", romx, BANK[2]
; flow control chars
charmap "@", $FF ; terminator
charmap "<NL>", $FD ; next line
charmap "<BP>", $FC ; prompt for button input
charmap "<PTR>", $FB ; text pointer (3 bytes, ROMbank and address)
charmap "<CLR>", $FA ; clear text
charmap "<PFN>", $F9 ; print foe name
charmap "<PPN>", $F8 ; print player name
charmap "<PSB>", $F7 ; print contents of wStringBuffer

; strings relating to system crashes
crash_string:: db "Gameboy has crashed!@"
rst38str:: db "RST38 crash@"
rst28str:: db "RST28 Crash@"
vba:: db "Visual Boy Advance@"
rst00str:: db "RST00 Crash@"
; intro screen strings
gbdetectstr:: db "detected gameboy is@"
dmgstr:: db "original@"
sgbstr:: db "super gameboy@"
sgb2str:: db "super gameboy 2@"
pocketstr:: db "pocket@"
colorstr:: db "color@"
advancestr:: db "advance@"
errorstr:: db "something weird@"
licensestr_pt1:: db "proudly not@"
licensestr_pt2:: db "licensed by@"
nintendostr:: db "nintendo@"
pressastr:: db "push a to start@"

; strings for other shit
test_string:: db "Nvidia sucks@"
test_name:: db "Emily@"
loading:: db "Loading...@"

; strings for battle engine
battle_bigtext_top:: db "Pick an@"
battle_bigtext_bottom:: db "action!@"
battle_atk:: db "ATK@"
battle_run:: db "RUN@"
battle_item:: db "ITM@"
battle_magic:: db "MAG@"

; strings for magic engine
magic_info_box:: db "A select B back<NL>SEL information@"

dank:: db "<PSB><BP>@"

; TODO: remove this lol
; TESTING ONLY: copies testname into wram
copy_test_name::
    push hl
    push de
    ld hl, wPlayerName
    ld de, test_name
.loop
    ld a, [de]
    cp "@"
    jr z, .done
    ld [hl], a
    inc hl
    inc de
    jr .loop
.done
    ld a, "@"
    ld [hl], a
    pop de
    pop hl
    ret

test_box:: db "Did you know?<NL>"
    db "Linux is neat.<BP><CLR>"
    db "When it works,<NL>"
    db "anyway!<BP><CLR>"
    db "<PTR>", BANK(test_boxtwo), HIGH(test_boxtwo), LOW(test_boxtwo), "@"

test_boxtwo:: db "This text was<NL>"
    db "loaded by txtcmd!<BP>@"

sign_text2:: db "Why did you<NL>"
    db "talk to me twice?<BP>@"

sign_text:: db "Hello, I am a<NL>"
    db "talking sign!<BP>@"

encounter_test:: db "Wild Encounter!<BP>@"

section "Title Screen Resources", romx, bank[2]
; title screen strings
title_placeholder:: db "Placeholder Title@"
title_newgame:: db "New Game@"
title_loadgame:: db "Resume Game@"
title_clearsram:: db "Clear SRAM@"
clearsram_textbox:: db "Do you really want<NL>"
    db "to clear SRAM?@"
clearsram_cancel:: db "<CLR>SRAM clear aborted<BP>@"
clearsram_finish:: db "<CLR>SRAM cleared!<BP>@"

section "Level up Strings", romx, bank[2]
; strings for the experience 
level_up_box:: db "<PPN><NL>leveled up!<BP>@"
hp_stat_text:: db "HP@"
mp_stat_text:: db "MP@"
def_stat_text:: db "DEF@"
level_up_afterstats:: db "<CLR><PPN> is now<NL>level <PSB>!<BP>@"
levelup_picka_stat:: db "<CLR>Pick a stat to<NL>give a boost!@"
levelup_roulette_text:: db "<CLR>A to stop wheel<NL>B to cancel@"
levelup_boost_applied:: db "<CLR>Boost applied!<BP>@"
levelup_new_spell:: db "<CLR>You unlocked a<NL>new spell!<BP>@"

; spell display strings for the menu
section "Magic Engine Internal Strings", romx, bank[2]
spell_0_menudisplay:: db "BoostDef / 4MP@"
spell_1_menudisplay:: db "Bless / 12MP@"
spell_2_menudisplay:: db "ShieldBreak / 24MP@"
spell_3_menudisplay:: db "Pillowify / 32MP@"

section "Text Entry Strings", romx, bank[2]
osk_done:: db "Done@"
osk_instructions_1:: db "B del, A add@"
osk_instructions_2:: db "START done@"
osk_confirmation:: db "Is this text<NL>correct?@"
osk_no_text:: db "You must input<NL>some text!<BP>@"

; scripts for when you actually cast a spell
section "Magic Engine Textbox Scripts", romx, bank[2]
spell_no_mp:: db "You do not have<NL>enough MP!@"
spell_0_cast:: 
    db "<PPN> cast spell<NL>BoostDef!<BP>"
    db "<CLR>Defense boosted<NL>for 4 turns!<BP>@"
spell_not_unlocked:: db "You have not<NL>found this spell!@"
spell_1_cast:: 
    db "<PPN> cast spell<NL>Bless!<BP>"
    db "<CLR><PPN> was healed!<BP>@"
shield_already_broken:: db "Cannot use this!<NL>Shield is broken.@"
spell_2_cast:: 
    db "<PPN> cast spell<NL>ShieldBreak!<BP>"
    db "<CLR>Foe defense<NL>lowered by 5!<BP>@"
spell_3_cast:: 
    db "<PPN> cast spell<NL>Pillowify!<BP>"
    db "<CLR>Foe attack<NL>lowered by 6!<BP>@"
foe_already_pillow:: db "<CLR>Cannot use this!<NL>Foe already pillow!@"

section "Textbox Engine Internal Strings", romx, bank[2]
yesno_yes:: db "Yes@"
yesno_no:: db "No@"

section "Battle Engine Textbox Scripts", romx, bank[2]
battle_test:: 
    db "Wow! you pressed<NL>"
    db "the A button!<BP>@"
battle_player_attack:: db "<PPN> attacked!<BP>@"
battle_player_miss:: db "<PPN> missed<NL>their attack!<BP>@"
battle_foe_attack:: db "<PFN> attacked!<BP>@"
battle_foe_miss:: db "<PFN> missed<NL>their attack!<BP>@"
battle_landed_crit:: db "<CLR>CRITICAL HIT!<BP>@"
battle_won:: 
    db "<CLR>You Won!<BP><NL>"
    db "<CLR>You gained <PSB><NL>Experience Points!<BP>@"
battle_lost:: 
    db "<CLR>You lost and<NL>"
    db "blacked out...<BP>@"
battle_flee_failed:: db "<CLR><PPN> could not<NL>flee!<BP>@"
battle_flee_worked:: db "<CLR><PPN> escaped from<NL>battle!<BP>@"

item_stub_text:: db "<CLR>You have no items!<BP>@"
battle_foe_level_text:: db "Lv.@"

section "Introduction Cutscene Resources", romx, bank[2]
; scripts n shit for the intro cutscene
intro_textbox_scriptone:: db "Hello, player!<NL>Welcome to this<BP><CLR>world inside the<NL>game!<BP>"
    db "<CLR>This is where the<NL>story will go when<BP><CLR>I get around to<NL>finishing it.<BP>"
    db "<CLR>And finishing the<NL>game itself, too.<BP>"
    db "<CLR>Right now, this is<NL>filler text.<BP>@"
intro_textbox_scripttwo:: db "<CLR>How about you<NL>enter your name?<BP>@"
intro_name_prompt:: db "Enter your name!@"
intro_textbox_scriptthree:: db "<CLR>So your name is<NL><PPN>, eh?<BP>"
    db "<CLR>That is a very<NL>nice name!<BP>"
    db "<CLR>Anyway, it is<NL>time for the game<BP><CLR>to start!<BP>@"

section "Player's house textboxes", romx, bank[2]
playerhouse_information_sign:: 
    db "<CLR>Did you know?<BP>"
    db "<CLR>Outside these<NL>walls are glitches<BP>"
    db "<CLR>They will murder<NL>you.<BP>@"
playerhouse_door_sign:: 
    db "<CLR>That tile is a<NL>door tile.<BP>"
    db "<CLR>If you stand on a<NL>door and press A,<BP>"
    db "<CLR>it will take you<NL>to another map!<BP>@"
playerhouse_firstaid_box::
    db "<CLR>There is a first<NL>aid box here.<BP>@"
playerlawn_mailbox_Script::
    db "You open your<NL>mailbox to check<BP><CLR>for any new boxes.<BP>"
    db "<CLR>However, there is<NL>a note inside.<BP>"
    db "<CLR>The note reads<NL>as follows<BP>"
    db "<CLR>Haha!<BP>"
    db "<CLR>I stole your new<NL>cardboard box!<BP>"
    db "<CLR>Come and get it<NL>if you dare!<BP>@"
playerlawn_sign_textscript::
    db "If you see tall<NL>grass, watch out!<BP>"
    db "<CLR>If you walk in it,<NL>you might get<BP>"
    db "<CLR>attacked by wild<NL>monsters!<BP>@"


section "Overworld Map Encounter Tables", romx, bank[2]
; Encounter table format (buffer max size: 21 bytes)
; 1 byte: number of encounters in the table
; 4 bytes per entry (maximum of 5 entries): encounter information
; ENCOUNTER FORMAT:
; 1 byte: rombank of foe data
; 2 bytes (low, high): address of foe data
; 1 byte: level of foe (automatically increases stats on load)
test_map_table:: db 3
    db bank(evil_cardbox_data)
    dw evil_cardbox_data
    db 2 ; level 1 cardboard box
    db bank(envelope_data)
    dw envelope_data
    db 1 ; level 1 envelope
    db bank(tux_data)
    dw tux_data
    db 1 ; level 1 penguin
    db bank(tux_data)
    dw tux_data
    db 3 ; level 3 tux

route1_table:: 
    db 4 ; 4 encounter
    define_encounter evil_cardbox_data, 1
    define_encounter envelope_data, 1
    define_encounter evil_cardbox_data, 2
    define_encounter envelope_data, 3


section "Demo Strings", romx, bank[2]
demo_opening:: db "Hello there,<NL><PPN>.<BP><CLR>You look stronger<NL>then before.<BP>@"
demo_areyousure:: db "<CLR>Do you want to<NL>fight?@"



section "Foe Data Storage", romx, bank[2]
; data blocks for foes are as follows
; 3 bytes: bank, address to graphics
; 2 bytes: maximum hp
; 8 bytes: foe name
; 1 byte: foe defense
; 1 byte: foe attack stat
evil_cardbox_data::
    db bank(evil_cardbox)
    dw evil_cardbox
    db $00, 9
    db "EvilBox@"
    db 5, 4 
    db $FF

blobcat_data::
    db bank(blobcat)
    dw blobcat
    db $00, 10
    db "BlobCat@"
    db 4, 4
    db $FF

tux_data::
    db bank(tux)
    dw tux
    db $00, 11
    db "Mad Tux@"
    db 3, 4
    db $FF

envelope_data::
    db bank(envelope)
    dw envelope
    db $00, 8 ; 8 hp
    db "MadMail@"
    db 2, 5
    db $FF


section "Overworld Map Headers", romx, bank[2]
; Map header format
; Byte 1: ROMBank of map tile information
; Bytes 2-3: Address of map tile information
; Byte 4: tileset ID
; Byte 5: bank of encounter table (0 for no encounters)
; Byte 6-7: address of encounter table
; Byte 8: how many events in map (max 6)
; 6 "coord event" entires per header (30 bytes total)
; Byte 1: x coord
; Byte 2: y coord
; Byte 3: ROMBank of Map Script
; Bytes 4-5: address of map script
test_map_header:: db BANK(test_map_tiles)
    dw test_map_tiles
    db 0 ; outdoor tileset
    db bank(test_map_table)
    dw test_map_table
    db 4 ; number of events in a map
    db 4, 5 ; 3 x, 1 y
    db BANK(test_sign_script) ; bank of test script
    dw test_sign_script
    db 5, 4 ;1x, 2y
    db bank(test_sign_script)
    dw test_sign_script
    db 14, 4 ; 14x, 4y
    db bank(heal_script)
    dw heal_script
    db 12, 2 ; 12x, 2y
    db bank(demo_sign_script)
    dw demo_sign_script
    db $FD, $DF ; terminator

player_house_header:: db BANK(player_house_tiles)
    dw player_house_tiles
    db 1 ; indoor_wood tileset
    db 0, 0, 0 ; no encounter table
    db 6
    coord_event 11, 7, player_house_signone_script
    coord_event 10, 6, player_house_signone_script
    coord_event 12, 6, player_house_signone_script
    coord_event 13, 11, player_house_doorsign_script
    coord_event 6, 6, player_house_firstaid_script
    coord_event 15, 11, player_house_doorscript
    db $FD, $DF ; map header terminator

player_lawn_header::
    map_tile_pointer player_lawn_tiles ; point at the lawn tiles
    db 0 ; outdoor tileset
    db 0, 0, 0 ; no encounter table
    db 4  ; 4 events
    coord_event 1, 11, player_lawn_housewarp_script
    coord_event 2, 9, player_lawn_mailbox_script
    coord_event 13, 10, player_lawn_sign_script
    coord_event 16, 12, player_lawn_route1_warp
    db $FD, $DF

route1_header::
    map_tile_pointer route1_tiles
    db 0 ; outdoor tileset
    encounter_table route1_table
    db 0 ; no  events
    db $FF
    db $FD, $DF

Section "Overworld Map Tile Data", romx
; each map is 20x18 tiles in size
test_map_tiles:: incbin "res/test.bin"
player_house_tiles:: incbin "res/player_house.bin"
player_lawn_tiles:: incbin "res/player_lawn.bin"
route1_tiles:: incbin "res/route1.bin"

Section "Reusable Map Script Information", romx, bank[2]
heal_text:: db "<CLR>Would you like<NL>to heal?@"
healed_text:: db "Your HP and MP are<NL>fully restored!<BP>@"
