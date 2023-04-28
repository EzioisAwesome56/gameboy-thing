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
    call enable_lcd ; turn the lcd on
    buffertextbox intro_textbox_scriptthree ; buffer the final script
    farcall show_textbox ; slide the textbox into view
    farcall do_textbox
    jr @