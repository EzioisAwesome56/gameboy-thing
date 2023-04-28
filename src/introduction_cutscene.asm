section "Introduction Cutscene Engine", romx
include "macros.asm"

; runs the intro cutscene
; also does things like prompt for player name
do_intro_cutscene::
    call disable_lcd ; turn off the LCD
    call clear_bg_tilemap ; get rid of anything that was on the tilemap before
    call enable_lcd ; turn that bitchass LCD back on
    farcall draw_textbox ; make sure the textbox is drawn correctly
    buffertextbox intro_textbox_scriptone
    farcall show_textbox ; slide the textbox into view
    farcall do_textbox ; run the textbox script
    buffertextbox intro_textbox_scripttwo ; load the second script
    farcall do_textbox ; run the new script
    farcall hide_textbox ; hide the textbox
    farcall clear_textbox ; empty out the textbox
    loadstr intro_name_prompt ; buffer our prompt into wStringBuffer
    farcall prompt_for_text ; prompt the user for text
    ; we need to copy 8 bytes to wPlayerName
    ld hl, wStringBuffer
    ld de, wPlayerName
    ld b, 8
    call copy_bytes ; copy inputted text to the player's name
    call init_setup_new_player ; setup a new player object
    call enable_lcd ; turn the lcd on
    buffertextbox intro_textbox_scriptthree ; buffer the final script
    farcall show_textbox ; slide the textbox into view
    farcall do_textbox
    farcall hide_textbox ; hide the textbox
    farcall clear_textbox ; empty the textbox
    call game_init_load_map
    ret ; yeet the fuck ouutta here

; init a brand new player with base stats
init_setup_new_player:
    xor a ; 0 into a
    ld [wPlayerHP], a
    ld [wPlayerMaxHP], a ; upper byte of HP is 0
    ld a, 20 ; the player will start with 20 HP
    ld [wPlayerHP + 1], a
    ld [wPlayerMaxHP + 1], a ; store that into the lower byte
    ld b, 6 ; base attack stat is 6
    push bc ; backup b
    call random ; random number into a
    ld c, 3 ; 3 into c
    call simple_divide ; do A mod C
    pop bc ; restore b
    add a, b ; add b to a
    ld [wPlayerAttack], a ; store it into attack
    ld b, 4 ; def is base 4
    push bc ; backup bc
    call random ; get a random value
    ld c, 4 ; 4 into c
    call simple_divide ; A mod C
    pop bc ; restore bc
    add a, b ; add b to a
    ld [wPlayerDefense], a ; write the new defense stat
    ld a, 10 ; players start with 10 mp
    ld [wPlayerMP], a
    ld [wPlayerMaxMP], a ; store it into both places
    xor a ; 0 into a
    ld [wCurrentExperiencePoints], a
    ld [wCurrentExperiencePoints + 1], a ; we have no experience points
    ld [wExperienceForNext], a ; the high byte of this needs to get set to 0
    ld a, 16 ; a is now 16
    ld [wExperienceForNext + 1], a ; we need 16 EXP for the next level up
    xor a
    inc a ; a is now 1
    ld [wPlayerLevel], a ; the player starts at level 1
    xor a ; a is now 0
    ld [wUnlockedMagic], a ; no  magic unlocked at the start
    ret ; yeet

; load the very first map of the game
game_init_load_map:
    ld a, 9 ; load our tile x coord into a
    ld [wPlayerx], a ; store it
    ld a, 9 ; put 0 into a
    ld [wPlayery], a ; store that as our y coord
    ld b, BANK(player_house_header)
    ld hl, player_house_header
    farcall load_overworld_map
    ret