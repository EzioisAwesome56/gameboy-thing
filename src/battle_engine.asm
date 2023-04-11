section "Battle Engine", romx
include "constants.asm"
include "macros.asm"

; starts up the battle engine
do_battle::
    push hl
    push bc ; backup registers
    farcall copy_test_name ; remove this later lol
    call test_data
    call draw_battle_gui ; draw the battle gui
    call enable_lcd ; turn on the lcd
    jr @

test_data:
    ld a, $03
    ld [wPlayerHP], a
    ld [wFoeHP], a
    ld a, $E7
    ld [wPlayerHP + 1], a
    ld [wFoeHP + 1], a
    ret


; draws the battle gui onto the background
draw_battle_gui:
    call disable_lcd ; disable the lcd, we will be doing a lot of bullshit to the screen
    call clear_bg_tilemap ; clear out the bg tilemap
    call draw_bottom_textui ; draw the botttom of the battle gui
    call draw_player_healthgui ; draw the player's gui
    call draw_player_name ; display the player's name in the box 
    call draw_foe_statbox ; draw the foe statbox to the screen
    call draw_foe_name ; draw the foe's name to its statbox
    call configure_foe_spritearea ; config the foe's sprite area for drawing
    call load_foe_sprite ; display foe sprite
    call init_configure_player_spritearea ; configure player sprite area
    call load_player_sprite ; load player sprite into vram
    call init_drawboth_hp ; draw remaining hp for both
    call init_fill_large_textbox ; fill the large textbox at the bottom of the screen
    call init_fill_small_textbox ; fill the smaller sub textbox as well
    ret

; fills the small textbox with the actions you can take
init_fill_small_textbox:
    loadstr battle_atk ; load attack string first
    ld de, wStringBuffer ; point de at the buffer
    ld hl, tilemap_smallbox_atk ; point hl at desitnation
    call strcpy ; copy to the tilemap
    loadstr battle_item ; buffer battle string
    ld de, wStringBuffer ; repoint de at the buffer
    ld hl, tilemap_smallbox_itm ; point hl at destination
    call strcpy ; display to screen
    loadstr battle_run ; buffer run string
    ld de, wStringBuffer ; point de at buffer
    ld hl, tilemap_smallbox_run ; point hl at desitnation
    call strcpy ; copy to tilemap
    ret ; leave, we're done here

; puts the string into the larger textbox to the left
init_fill_large_textbox:
    loadstr battle_bigtext_top ; buffer the top text first
    ld de, wStringBuffer ; point de at the string buffer
    ld hl, tilemap_bigbox_top ; point hl at destination in tilemap
    call strcpy ; copy string to the screen
    loadstr battle_bigtext_bottom ; load bottom text
    ld de, wStringBuffer ; repoint de at the start of the string buffer
    ld hl, tilemap_bigbox_bottom ; point hl at the bottom
    call strcpy ; copy to the tilemap
    ret ; leave

; draws both player and foe's hp to the screen
init_drawboth_hp:
    ld a, [wPlayerHP] ; load high byte into a
    ld h, a ; store it into h
    ld a, [wPlayerHP + 1] ; load low byte into a
    ld l, a ; store it into l
    farcall number_to_string_sixteen ; convert HP into string
    ld de, wStringBuffer ; point de at our string buffer
    ld hl, tilemap_player_hp ; point hl at desitnation
    call strcpy ; write the string to the screen
    ld a, "/" ; load forward slash into a
    ld [hl], a ; write it to the tilemap
    inc hl ; move it forward
    push hl ; backup hl
    ld a, [wPlayerMaxHP] ; high byte of player hp
    ld h, a ; put it into h
    ld a, [wPlayerMaxHP + 1] ; low byte
    ld l, a ; put it into l
    farcall number_to_string_sixteen ; convert to string
    ld de, wStringBuffer ; repoint de at the buffer
    pop hl ; restore hl
    call strcpy ; copy the max hp string to the screen
    ; do the same for foe's hp
    ld a, [wFoeHP] ; high byte
    ld h, a ; into h
    ld a, [wFoeHP + 1] ; low byte
    ld l, a ; into l
    farcall number_to_string_sixteen ; convert to string
    ld de, wStringBuffer ; point de at the buffer again
    ld hl, tilemap_foe_hp ; hl att where foe HP goes
    call strcpy ; update the tilemap
    ld a, "/" ; load forward slash
    ld [hl], a ; write it to tile map
    inc hl ; move hl forward 1 byte
    push hl ; backup hl as a cheat
    ld a, [wFoeMaxHP] ; load high byte of max hp into a
    ld h, a ; into h
    ld a, [wFoeMaxHP + 1] ; low byte
    ld l, a ; into l
    farcall number_to_string_sixteen ; convert to string-
    ld de, wStringBuffer ; repoint de at the buffer
    pop hl ; hl is now where we need it
    call strcpy ; display max hp in the hud
    ret ; we're done, so leave

; configure the foe sprite area for drawing
configure_foe_spritearea:
    ld hl, foe_sprite_area_start ; point hl at the start of the tilemap
    xor a ; load 0 into a
    ld c, a ; put 0 into a
    ld d, a ; put 0 into d also
    ld b, foe_tile_start ; load 80 into a
.loop
    ld a, c ; load c into a
    cp largesprite_linelen ; have we done a row?
    jr z, .check ; leave it yes
    ld a, b ; put b back into a
    ld [hl], a ; store a into hl
    inc hl ; move hl forward 1
    inc b ; increment b
    inc c ; increment c
    jr .loop ; go back to the loop
.check
    ld a, d ; load d into a
    cp largesprite_vertloops ; have we done this 6 times?
    jr z, .done ; leave if so
    xor a ; otherwise, load 0 into a
    ld c, a ; put c into c
    inc d ; increment d by one
    push bc ; backup bc
    ld c, largesprite_lineskip ; load 27 into c
    call move_address ; move hl forward 27 bytes
    pop bc ; restore bc
    jr .loop ; go back to the loop
.done
    ret ; leave lol

; configures the player's sprite area for displaying her sprite
init_configure_player_spritearea:
    ld hl, tilemap_player_start ; point hl at the start of our player tile location
    xor a ; put 0 into a
    ld c, a ; put 0 into c
    ld d, a ; 0 into d also
    ld b, player_tile_start
.loop
    ld a, c ; load c into a
    cp largesprite_linelen ; have we done a row?
    jr z, .check ; check high byte
    ld a, b ; put b back into a
    ld [hl], a ; store a into hl
    inc hl ; move hl forward 1
    inc b
    inc c ; increment counter and tile index
    jr .loop ; go loop some more
.check
    ld a, d ; load d into a
    cp largesprite_vertloops ; have we done this 6 times?
    jr z, .done ; leave if yes
    xor a ; 0 into a
    ld c, a ; put a into c
    inc d ; increment d by one
    push bc ; backup bc
    ld c, largesprite_lineskip ; 25 into c
    call move_address ; move address 25 chars
    pop bc ; restore bc
    jr .loop ; go loop some more
.done
    ret ; leave

; load all 672 bytes of the foe's battle sprite into vram
load_player_sprite:
    ld de, player_back ; point de at the player's back sprite graphics
    ld a, bank(player_back) ; put bank  into a
    call buffer_sprite ; buffer the graphics into vram
    ld de, tiledata_player_start ; point de at the start of the tile buffer
    call copy_sprite_vram ; copy the graphics into vram
    ret ; leave

; load all 672 bytes of the foe's battle sprite into vram
load_foe_sprite:
    ; first we need to copy the sprite into the wRAM buffer
    ld de, evil_cardbox ; point de at our graphics data
    ld a, bank(evil_cardbox) ; load a with our rombank of cardbox
    call buffer_sprite ; buffer the sprite into wram
    ld de, tiledata_foe_start ; point de at the start of foe tiledata
    call copy_sprite_vram ; load the sprite into vram
    ret ; leave 

; loads whatever is in the buffer into vram at de
copy_sprite_vram:
    ld hl, wSpriteBuffer ; point hl at the buffer
    xor a ; load 0 into a
    ld b, a ; put 0 into b
    ld c, a ; also put 0 into c
.loop
    ld a, c ; load c into a
    cp $A0 ; check if c matches
    jr z, .checkb
.resume
    ld a, [hl] ; otherwise, load byte from hl
    ld [de], a ; and put it into de
    inc de
    inc hl ; increment source and desitnation address
    inc bc ; increment counter
    jr .loop ; go loop some more
.checkb
    ld a, b ; load b into a
    cp $02 ; is b 02?
    jr z, .done ; leave
    jr .resume ; otherwise go loop some more
.done
    ret ;leave


; buffers sprite from bank a and addr DE into wram
buffer_sprite:
    push de ; backup de for a sec
    push bc ; also backup bc too
    ld hl, sram_sprite_copier ; load de with the routine of the copier
    call mbc_copytosram ; copy the routine into sram
    pop bc
    pop de ; restore our registers
    ld h, d ; move high byte
    ld l, e ; move low byte
    ld de, sCodeBlock ; point de at our code block
    call mbc3_enable_sram ; open sram
    call bankswitch_exec ; jump to copier
    call mbc3_disable_sram ; close sram
    ret ; leave

; gets loaded into sram
; copies sprite from hl into wSpriteBuffer
sram_sprite_copier:
    xor a ; load 0 into a
    ld b, a ; store it into b
    ld c, a ; also store it into c
    ld de, wSpriteBuffer ; point de at our sprite buffer
.loop
    ld a, c ; load c into a
    cp $A0 ; is the lower half of c correct?
    jr z, .checkb
.resume
    ld a, [hl] ; otherwise, load byte from hl
    ld [de], a ; store it into de
    inc hl
    inc de ; increment source and destination address
    inc bc ; increment counter
    jr .loop ; go and loop some more lol
.checkb
    ld a, b ; load b into a
    cp $02 ; is b correct?
    jr z, .done ; leave if yes
    jr nz, .resume ; resume copying if not
.done
    ret ; leave
    db $FE, $EF


; draw the thing you are fighting's statbox to the screen
draw_foe_statbox:
    ld hl, foe_statbox_start ; point hl at the start of the memory region for the statbox
    ld a, textbox_toplefttcorner ; load top left corner gfx into a
    ld [hl], a ; writtet to tilemap
    inc hl ; move 1 byte forward
    ld d, textbox_topline ; load topline tile into d
    ld e, player_statbox_length ; load e with how long the statboxes are
    call tile_draw_loop ; draw that many tiles
    ld a, textbox_toprightcorner ; load a with the top right corner of textbox
    ld [hl], a ; write it to the tilemap
    inc hl ; move destination forward 1 byte
    xor a ; zero out a
    ld b, a ; store 0 into b
.middle
    ld c, pstatbox_lineskip ; load c with the linekip value
    call move_address ; move address to next line
    ld a, textbox_vertline_left ; load a with the left vertical line graphic
    ld [hl], a ; store it into hl
    inc hl ; next destination byte plz
    ld c, player_statbox_length ; load c with the length of the statbox
    call move_address ; move forward that many bytes into memory
    ld a, textbox_vertline_right ; load the right vert line into a
    ld [hl], a ; store it into the tilemap
    inc hl ; move forward forward 1 byte
    ld a, b ; load b into a
    cp 2 ; have we  been here twice
    jr z, .resume ; leave this loop
    inc b ; add 1 to our counter
    jr .middle
.resume
    ld c, pstatbox_lineskip ; load c with the lineskip
    call move_address ; move addres to next line
    ld a, textbox_bottomleft_corner ; load bottom left corner into a
    ld [hl], a ; write that to the tilemap
    inc hl ; move forward 1 byte
    ld d, textbox_bottomline ; load d with the bottom line
    ld e, player_statbox_length ; load e with how long the statbox is
    call tile_draw_loop ; draw the tile to the tilemap
    ld a, textbox_bottomright_corner ; load bottom right corner graphic
    ld [hl], a ; store it into the tilemap
    ret ; we've finished, so leave

; draws the player's name onto the statbox
draw_player_name:
    ld de, wPlayerName ; point de at the player's name
    ld hl, battle_playername ; point hl at destination
    jp strcpy
; draw foe name into the tilemap
draw_foe_name:
    ld de, wFoeName ; point de at source
    ld hl, foe_name_start ; point hl at desitnation
    jp strcpy
; quickly copy a string from wram into tilemap
strcpy:
    ld a, [de] ; load byte at de into a
    cp $FF ; string terminator?
    jr z, .done ; leave
    ld [hl], a ; ottherwise write to hl
    inc hl
    inc de ; increment destination and source address
    jr strcpy ; go loop some more
.done
    ret ; leave lol

; draw the player's health and other stats box
draw_player_healthgui:
    ld hl, start_player_battlegui ; point hl at the start of the battle gui
    ld a, textbox_toplefttcorner ; load top left corner graphic into a
    ld [hl], a ; store that into the tilemap
    inc hl ; move forward 1 byte
    ld d, textbox_topline ; load topline graphic into d
    ld e, player_statbox_length ; put 5 into e
    call tile_draw_loop ; draw 5 tiles to the screen
    ld a, textbox_toprightcorner ; load right corner graphic into a
    ld [hl], a ; store it into the tilemap
    inc hl ; move forward 1 byte in tilemap memory
    xor a ; 0 into a
    ld b, a ; store a into b
.mid
    ld c, pstatbox_lineskip ; put 25 into c
    call move_address ; move hl forward 25 bytes
    ld a, textbox_vertline_left ; put the left line graphic into a
    ld [hl], a ; store it into the tilemap
    inc hl ; next byte plz
    ld c, player_statbox_length ; put 5 into c
    call move_address ; advance 5
    ld a, textbox_vertline_right ; load right veritcal line tile into a
    ld [hl], a ; write that to the tilemap
    inc hl ; move forward 1
    ld a, b ; load b into a
    cp 2 ; have we done this twice?
    jr z, .resume ; leave if yes
    inc b ; increment our counter
    jr .mid ; do it again!
.resume
    ld c, pstatbox_lineskip ; load 25 into c
    call move_address ; move forward 25 bytes
    ld a, textbox_bottomleft_corner ; load bottom left corner into a
    ld [hl], a ; store it into the tilemap
    inc hl ; move forward 1 byte
    ld d, textbox_bottomline ; load bottome line into d
    ld e, player_statbox_length ; load 5 into e
    call tile_draw_loop ; draw 5 bottom line tiles
    ld a, textbox_bottomright_corner ; load bottom right corner into a
    ld [hl], a ; store it into the tilemap
    ret ; leave

; draws the main textbox at the bottom of the screen
draw_bottom_textui:
    ld hl, topleft_bg_textbox ; point hl at the top left of where we want the textbox to go
    ld a, textbox_toplefttcorner ; load our corner graphic into a
    ld [hl], a ; store it into vram
    inc hl ; move to next destination address
    ld d, textbox_topline ; load the top line graphic intto d
    ld e, 9 ; put 9 into e
    call tile_draw_loop ; draw loop the tiles the spesified times
    ld a, textbox_toprightcorner ; load top right corner into a
    ld [hl], a ; write that into the tilemap
    inc hl ; move to next address
    ld a, textbox_toplefttcorner ; again load the corner into a
    ld [hl], a ; store that into hl
    inc hl ; move hl forward 1
    ld e, 7 ; put 7 into e
    call tile_draw_loop ; d should still be our tile
    ; first we have to draw the top right corner for the sub textbox
    ld a, textbox_toprightcorner ; ...so load the graphic
    ld [hl], a ; then store it
    inc hl ; move hl forward 1
    ld c, 12 ; put 12 into c
    call move_address ; increment hl forward 12 tiles
    xor a ; load 0 into a
    ld b, a ; store 0 into b
.middle
    ld a, textbox_vertline_left ; load vertical line tile into a
    ld [hl], a ; store it into hl
    inc hl ; next byte please
    ld d, 0 ; put the blank tile into d
    ld e, 9 ; put 9 into e
    call tile_draw_loop ; draw blank tiles
    ld a, textbox_vertline_right ; load right vertical line character into a
    ld [hl], a ; store it into vram
    inc hl ; next byte plz
    ld a, textbox_vertline_left ; load the vertical line left char
    ld [hl], a ; write it to the tilemap\
    inc hl ; next byte please
    ld e, 7 ; lad 7 into a
    call tile_draw_loop ; draw blank tiles
    ld a, textbox_vertline_right ; load the right line into a
    ld [hl], a ; store it into the tilemap
    inc hl ; increment hl
    ld c, 12 ; put 12 into c
    call move_address ; move hl forward 12 bytes
    ld a, b ; load b into a
    cp 1 ; have we done this before?
    jr z, .bottom ; leave this loop if so
    inc b ; otherwise, add 1 to b
    jr .middle ; go back to the start of this routine
.bottom
    ld a, textbox_bottomleft_corner ; load the bottom left corner gfx into a
    ld [hl], a ; store it into the tilemap
    inc hl ; move forward 1 in the tilemap
    ld e, 9 ; load 9 into e
    ld d, textbox_bottomline ; load bottom line graphic into d
    call tile_draw_loop ; draw bottom 9 tiles
    ld a, textbox_bottomright_corner ; load nottom right corner into a
    ld [hl], a ; store it into the tilemap
    inc  hl
    ld a, textbox_bottomleft_corner ; bottom left corner now
    ld [hl], a ; write it to the tilemap
    inc hl ; move hl forward by 1
    ld e, 7 ; load e with 7
    call tile_draw_loop ; draw 7 bottom lines lol
    ld a, textbox_bottomright_corner ; load the bottom right corner into a
    ld [hl], a ; store that into hl
    ret ; yeett


; draw tile d e times starting at hl
tile_draw_loop:
    xor a ; zero into a
    ld c, a ; put 0 into c
.loop
    ld a, c ; load c into a
    cp e ; have we looped the required number of times?
    jr z, .done ; if yes, LEAVE
    ld a, d ; load the tile into a
    ld [hl], a ; store it into destination address
    inc hl ; move forward 1  byte
    inc c ; increment our counter
    jr .loop
.done
    ret ; leave lmao

; moves HL forward c bytes
move_address:
    push bc ; backup bc
    xor a ; load 0 into a
    ld b, a ; put 0 into b
    add hl, bc ; add them together
    pop bc ; restore bc to what it was before
    ret ; lea ve lol


