section "Battle Engine", romx
include "constants.asm"
include "macros.asm"

; starts up the battle engine
do_battle::
    push hl
    push bc ; backup registers
    push de
    call init_ram_variables ; initialize ram for battle system
    call parse_foe_data ; parse foe data
    call init_draw_battle_gui ; draw the battle gui
    call enable_lcd ; turn on the lcd
    call load_arrow_graphic ; configure sprite 4 to be the arrow graphic
    ld a, [wTextboxDrawn] ; load the textbox drawn flag into a
    cp 0 ; is the textbox not drawn?
    jr z, .draw
    jr nz, .skip
.draw
    farcall draw_textbox ; draw the textbox as we'll need it later for various things
.skip
    jp battle_loop ; jump to the battle loop

; process winning a battle
battle_exit_win:
    call emeny_defeat_animation ; delete the foe from the screen
    farcall calculate_experience_points ; find out how much exp we got
    push hl ; back it up for later
    farcall number_to_string_sixteen_fiveplaces ; convert it to a string
    pop hl ; pop our experience point value off the stack
    ld a, [wCurrentExperiencePoints] ; load high byte of current exp into a
    ld b, a ; write to b
    ld a, [wCurrentExperiencePoints + 1] ; get low byte
    ld c, a ; write to bc
    add hl, bc ; add bc to hl
    ld a, h ; get new high byte
    ld [wCurrentExperiencePoints], a ; update high byte
    ld a, l ; get low byte
    ld [wCurrentExperiencePoints + 1], a ; update low byte
    buffertextbox battle_won ; buffer win text
    farcall show_textbox ; show the textbox
    farcall do_textbox ; show the textbox
    farcall check_for_levelup ; check for level up
    farcall hide_textbox ; hide the textbox
    farcall clear_textbox ; clear the textbox
    jp battle_global_exit

; process losing a battle
battle_exit_loss:
    buffertextbox battle_lost ; buffer textbox script
    farcall show_textbox ; show the textbox
    farcall do_textbox ; run script
    farcall hide_textbox ; hide the textbox
    farcall clear_textbox ; delete all text inside of it
    call respawn_player_after_death
    jp battle_global_exit

; does the bare minimum for exiting
battle_exit_flee:
    farcall hide_textbox ; hide the textbox
    farcall clear_textbox ; clear textbox
    jp battle_global_exit ; exit

; global routine for exiting
battle_global_exit:
    ld hl, wActionBuffer
    set 6, [hl] ; set the flag for skipping script parsing
    pop hl ; oops theres an extra hl on the stack
    pop de
    pop bc ; restore everything we backed up at the very start
    pop hl
    ret ; return to caller

; the main battle code loop
battle_loop:
    ld hl, joypad ; point hl at the joypad register
.loop
    call select_dpad ; select the dpad
    ld a, [hl]
    ld a, [hl] ; read the state of the joypad into a
    ld a, [hl]
    bit 3, a ; is down pressed?
    jr z, .down
    bit 2, a ; is up pressed?
    jr z, .up
    bit 1, a ; is left pressed?
    jr z, .left
    bit 0, a ; is right pressed?
    jr z, .right
    call select_buttons ; select the action buttons
    ld a, [hl]
    ld a, [hl] ; load the state of the joypad into hl
    ld a, [hl] 
    bit 0, a ; is the a button pressed
    jr z, .abutton ; go handle that
    jr .loop ; go loop forever
.abutton
    push hl
    call hide_arrow ; hide the arrow
    call do_turn ; run a turn of the battle
    ld a, [wBattleState] ; load battle state  into a
    cp 1 ; did we win?
    jp z, battle_exit_win ; we won!
    cp 2
    jp z, battle_exit_loss ; oh no we fucking lost
    cp 3 ; was the action cancelled?
    jr z, .cancelled ; go handle that
    cp 4 ; did we fleee?
    jp z, battle_exit_flee ; run from battle
    call update_arrow_position ; show the arrow
    pop hl
    jr .loop
.down
    xor a ; load 0 into a
    ld [wBattleActionRow], a ; store it into row
    jr .process
.up
    xor a
    inc a ; load 1 into a
    ld [wBattleActionRow], a ; put it into the row
    jr .process
.left
    xor a ; load 0 into a
    ld [wBattleActionSel], a ; put it into the sel
    jr .process
.right
    xor a
    inc a ; put 1 into a
    ld [wBattleActionSel], a ; put it into the sel
    jr .process
.process
    call update_arrow_position ; update the arrow
    jr .loop ; go back to the loop
.cancelled
    xor a ; put 0 into a
    ld [wBattleState], a ; store it
    pop hl ; restore hl
    jr .process ; update arrow

; run a turn of the battle
do_turn:
    call run_player_turn
    call update_battle_state ; update the state of the battle
    ld a, [wBattleState] ; load battle state
    cp 5 ; is it 5?
    jr z, .fixstate
    cp 0 ; compare against 0
    jr nz, .skipfoe ; if its not 0, foe probably died lol
.dofoe
    call run_foe_turn ; run the foe's turn
    call update_battle_state ; update the state of battle
.skipfoe
    ret ; leave lol
.fixstate
    xor a ; 0 into a
    ld [wBattleState], a ; update battle state
    jr .dofoe ; run the foe's turn

; updates the state of the battle based on various things
update_battle_state:
    ld a, [wFoeState] ; load foe state into a
    cp 1 ; is the foe dead
    jr z, .foedead
    ld a, [wPlayerState] ; load the playerstate into a
    cp 1 ; did player die?
    jr z, .playerdead
    jr .done ; todo: rest of the cases
.playerdead
    xor a ; 0 into a
    inc a ; put 1 into a
    inc a ; make that two
    ld [wBattleState], a ; store it into the player state
    jr .done ; go down
.foedead
    xor a ; 0 out a
    inc a ; put 1 into a
    ld [wBattleState], a ; store it into battle state
.done
    ret ; we have finished, so, leave

; run the emeny's turn
run_foe_turn:
    farcall show_textbox ; show the textbox
    ; TODO: add more things for aimcgee to do
    ; TODO: randomly pick an action to preform
.attack
    buffertextbox battle_foe_attack ; buffer the attack textbox
    farcall do_textbox ; do the textbox script
    farcall check_miss ; roll to see if the foe misses
    ld a, b ; load b into a
    cp 1 ; is b 1?
    jr z, .miss ; FOE misses
    farcall calculate_foe_damage ; find out what our damage is
    push bc ; back it up
    farcall check_criticalhit ; check for a crick
    ld a, b ; load into a
    cp 1 ; did we land a crit?
    pop bc ; restore calculated damage value
    call z, land_crit ; double damage
    ; next we have to load player HP
    ld a, [wPlayerHP] ; high byte of player hp
    ld h, a ; store it into h
    ld a, [wPlayerHP + 1] ; load low byte
    ld l, a ; and put it into l
    ld a, b ; put calculated dmage into a
    call sixteenbit_subtraction ; subtract damage from hp
    ; update player hp in memory
    ld a, h
    ld [wPlayerHP], a ; put high byte into memory
    ld a, l
    ld [wPlayerHP + 1], a ; put low byte into memory
    ld bc, wPlayerState ; point bc at player's state in wram
    farcall check_object_state ; check the state of the object
    call update_player_hp ; update player's displayed hp
    jr .done ; jump over miss block
.miss
    farcall clear_textbox ; clear out textbox
    buffertextbox battle_foe_miss ; buffer new textbox script
    farcall do_textbox ; run new textbox script
    ; we can just flow down to .done from here lol
.done
    ; turn finished, leave
    farcall hide_textbox
    farcall clear_textbox ; hide and then clear the textbox
    ret ; leave
    
; runs the player's turn
run_player_turn:
    farcall show_textbox ; show the textbox
    ; first we need to find what the player actually did
    ld a, [wBattleActionRow] ; get the low into a
    cp 1 ; is it the top row?
    jr z, .top
    jr nz, .bottom
.bottom
    ld a, [wBattleActionSel] ; load the actual selection into a
    cp 0 ; is the selection 0?
    jr z, .magic
    jp nz, .run ; we want to attempt to run, so jump there
.top
    ld a, [wBattleActionSel] ; get actual selection
    cp 0 ; left selected?
    jr z, .attack ; player wants to attack
    jp nz, .item ; use an item
.attack
    buffertextbox battle_player_attack ; buffer attack string
    farcall do_textbox ; run script
    farcall check_miss ; roll to see if we missed
    ld a, b ; put b into a
    cp 1 ; did we miss
    jr z, .miss ; oh no
    farcall calculate_player_damage ; calculate player damage delt
    push bc ; backup bc
    farcall check_criticalhit ; roll the dice for a critical hit
    ld a, b ; load b into a
    cp 1 ; did we land a crit
    pop bc ; restore bc
    call z, land_crit ; fuck yea mr krabs
    ld a, [wFoeHP] ; load foe hp high into a
    ld h, a ; put it into hl
    ld a, [wFoeHP + 1] ; load low byte into a
    ld l, a ; store it into hl
    ld a, b ; load b into a
    call sixteenbit_subtraction ; subtract damage from foe health
    ld a, h ; high byte of new foe hp into a
    ld [wFoeHP], a ; store it into memory
    ld a, l ; low byte of foe hp
    ld [wFoeHP + 1], a ; store it
    ld bc, wFoeState ; point bc at foe state
    farcall check_object_state ; check the state of the foe
    call update_foe_hp ; update the foe's HP display
    jr .done
.magic
    ; player wants to use magic
    farcall do_magic_battle ; call the magic routine
    call update_player_mp ; update the player's MP
    call update_player_hp ; also update the player's HP
    jr .done
.miss
    farcall clear_textbox ; clear textbox
    buffertextbox battle_player_miss ; buffer the correct text
    farcall do_textbox ; display the text
.done
    farcall hide_textbox ; hide the textbox
    farcall clear_textbox ; clear out all text from the textbox
    ret ; leave lol
.run
    call flee_subroutine ; run this sub routine instead
    jr .done ; yeet
.item
    call use_item ; TODO: not stub routine
    jr .done ; yeet

; handles attempting to flee
; also deals with the edge cases
flee_subroutine:
    ld a, [wBattleType] ; load the battle type into a
    cp 0 ; is it a wild battle?
    jr nz, .cantflee ; you can only run from a wild battle!
    ; the rest of the flee code goes here
    farcall calculate_flee ; calculate and see if we can flee
    ld a, b ; load b into a
    cp 1 ; is b 1?
    call nz, flee_failed ; we did not flee
    call z, flee_worked ; we did flee
    jr .done
.cantflee
    ld a, 3 ; load 3 into a
    ld [wBattleState], a ; update the battlestate
    buffertextbox battle_Cant_flee ; buffer the text script
    farcall do_textbox ; run the script
.done
    ret ; leave this sub routine

; stub routine
use_item: ; TODO: add items
    buffertextbox item_stub_text
    farcall do_textbox
    ld a, 3 ; load 3 into a
    ld [wBattleState], a ; update state of battle
    ret ; yeet

; ran if a flee attempt fails
flee_failed:
    ld a, 5 ; load 5 into a
    ld [wBattleState], a ; store into the battle state
    buffertextbox battle_flee_failed ; buffer our textbox script
    farcall do_textbox ; run the script
    ret ; leave

; runjs if a flee worked
flee_worked:
    ld a, 4 ; load 4 into a
    ld [wBattleState], a ; update battle state
    buffertextbox battle_flee_worked ; buffer the correct text
    farcall do_textbox ; run the textbox
    ret ; leave

; preform actions for when a crit is landed
land_crit:
    push bc ; backup current damage value
    buffertextbox battle_landed_crit ; buffer critical hit message
    pop bc ; restore bc
    ld a, b ; load b into a
    ld c, 2 ; put 2 into c
    call simple_multiply ; 2x the damage delt
    ld b, a ; store new damage into  b
    push bc ; backup bc
    farcall do_textbox ; display new script
    pop bc ; restore bc
    ret ; leave


; hide the arrow by moving it off the screen
hide_arrow:
    xor a ; load 0 into a
    ld [wOAMSpriteFour], a ; store it into OAM
    call queue_oamdma ; do a DMA transfer
    ret ; leave


; updates the position of the menu selection arrow
update_arrow_position:
    ld b, battle_base_xpos ; load base xpos into b
    ld c, battle_base_ypos ; load base y pos into c
    ld a, [wBattleActionRow] ; load the row into a
    cp 0 ; is it 0?
    jr z, .movedown
    jr .xcheck
.movedown
    ld a, 8 ; load 8 into a
    add a, c ; put new y pos into y
    ld c, a ; put that into c
.xcheck
    ld a, [wBattleActionSel] ; load selection into a
    cp 1 ; is it one?
    jr z, .moveright
    jr .done
.moveright
    ld a, 32 ; load 32 into a
    add a, b ; add b and a together
    ld b, a ; store new value into b
.done
    ld a, c ; load c into a
    ld [wOAMSpriteFour], a ; update y pos
    ld a, b ; load b into a
    ld [wOAMSpriteFour + 1], a ; update x pos
    call queue_oamdma ; preform a DMA transfer
    ret ; leave

; updates the displayed HP for the foe
update_foe_hp:
    ld a, [wFoeHP] ; load high byte into a
    ld h, a ; store it into h
    ld a, [wFoeHP + 1] ; load low byte
    ld l, a ; store it into a
    farcall number_to_string_sixteen ; convert to string
    ld hl, tilemap_foe_hp ; point hl at the start of the hp tilemap
    call strcpy_vblank ; copy to screen
    ret

; updates the displayed hp for the player
update_player_hp:
    ld de, wPlayerHP ; point de at player hp
    ld a, [de] ; copy high byte
    ld h, a ; store into h
    inc de ; next byte plz
    ld a, [de] ; low byte
    ld l, a ; store into h
    farcall number_to_string_sixteen ; convert to string
    ld hl, tilemap_player_hp ; point tilemap at player hp
    call strcpy_vblank ; update the screen
    ret ; leave

; updates displayed MP for the player
update_player_mp:
    ld a, [wPlayerMP] ; load mp into a
    call number_to_string ; convert to string
    ld hl, tilemap_player_mp ; point hl at desitnation
    call strcpy_vblank ; update screen
    ret ; leave

; init the ram vars for selection
init_ram_variables:
    xor a ; load 0 into a
    ld [wBattleActionSel], a ; default selection to the left
    ld [wFoeState], a ; set foe state to not dead
    ld [wBattleState], a ; set battle state to active
    ld [wPlayerState], a ; set the player state to be not dead
    ld [wBoostDefTurnsLeft], a ; zero out bootdef turns
    ld [wFoeAppliedStatus], a ; make this zero too
    inc a ; add 1 to a
    ld [wBattleActionRow], a ; default to top row
    ret ; we're done, leave

; load the arrow graphic into 
load_arrow_graphic:
    ld a, right_arrow_tile ; load right tile into a
    ld [wOAMSpriteFour + 2], a ; store it into the OAM buffer
    ; TODO: math
    ld a, battle_base_xpos ; load base xpos int a
    ld [wOAMSpriteFour + 1], a
    ld a, battle_base_ypos ; load base y into a
    ld [wOAMSpriteFour], a ; store into the y coord variable
    call queue_oamdma ; do a dma transfer
    ret 

; parse foe data so we can load what is required
parse_foe_data:
    ld hl, wEmenyDataBuffer ; point hl at our data buffer
    ld a, [hl] ; load rom bank into a
    push af ; backup a for now
    inc hl ; move to low byte of graphics data
    ld a, [hl] ; load into hl
    ld e, a ; put it into e
    inc hl ; moive to high byte of graphics data
    ld a, [hl] ; load into a
    ld d, a ; store into d
    pop af ; restore rombank
    push hl ; backup hl
    call buffer_sprite ; buffer the sprite into wram
    pop hl ; restore hl from that
    inc hl ; move to high byte of hp
    ld a, [hl] ; load into a
    ld [wFoeMaxHP], a ; write to foe max hp
    inc hl ; move to low byte
    ld a, [hl] ; load it into a
    ld [wFoeMaxHP + 1], a ; store it
    inc hl ; move to start of name
    xor a ; load 0 into a
    ld c, a ; put 0 into c
    ld de, wFoeName ; point de at foe name
.nameloop
    ld a, c ; load c into a
    cp 8 ; have we copied 8 characters?
    jr z, .stats
    ld a, [hl] ; load byte into a
    ld [de], a ; store that byte into de
    inc hl
    inc de ; increment source and desitnation
    inc c ; add 1 to our counter
    jr .nameloop ; go back to the top
.stats
    ld a, [hl] ; load defense stat into a
    ld [wFoeDefense], a ; store it into memory
    inc hl ; point hl at the attack stat
    ld a, [hl] ; load that into a
    ld [wFoeAttack], a ; then store it into memory
    ld a, [wFoeLevel] ; load the level into a
    dec a ; subtract 1
    call nz, run_scaler
    ld a, [wFoeMaxHP] ; get high byte of max hp
    ld [wFoeHP], a ; store into memory
    ld a, [wFoeMaxHP + 1] ; get low byte
    ld [wFoeHP + 1], a ; write low byte into memory
    ret ; leave

; NZ stub for farcall
run_scaler:
    farcall scale_foe_stats
    ret ; yeetus
     
; deleted the emeny line by line from the screen
emeny_defeat_animation:
    push hl
    push bc ; backup hl and bc
    push de ; backup de
    ld hl, foe_statbox_start ; point hl at our statbox
    xor a ; put 0 into a
    ld c, a ; zero out c
    ld d, a ; zero out d
    ld e, 32 ; line skip to next row
.loop
    ld a, c ; load c into a
    cp 6 ; have we done this 5 times?
    jr z, .done ; leave if so
    ld a, CLEARFULLLINE ; load a with the command to clear a full vblank line
    ld [wVBlankAction], a ; write it into the action
    halt ; wait for vblank
    add hl, de ; add de to hl
    inc c ; increment counter
    halt
    jr .loop ; go loop some more
.done
    pop de
    pop bc ; pop everything off the stack
    pop hl 
    ret ; return to caller function

; draws the battle gui onto the background
init_draw_battle_gui:
    call disable_lcd ; disable the lcd, we will be doing a lot of bullshit to the screen
    call set_textbox_direct ; set the textbox engine to operate in direct mode
    call clear_bg_tilemap ; clear out the bg tilemap
    call load_foe_sprite ; load foe tiles into vram
    call init_draw_bottom_textui ; draw the botttom of the battle gui
    call init_draw_player_healthgui ; draw the player's gui
    call init_draw_player_name ; display the player's name in the box 
    call init_draw_foe_statbox ; draw the foe statbox to the screen
    call init_draw_foe_name ; draw the foe's name to its statbox
    call init_configure_foe_spritearea ; config the foe's sprite area for drawing
    call init_configure_player_spritearea ; configure player sprite area
    call load_player_sprite ; load player sprite into vram
    call init_drawboth_hp ; draw remaining hp for both
    call init_drawplayer_mp ; draw the player's mp to the screen
    call init_draw_foe_level ; draw the foe's level to the screen
    call init_fill_large_textbox ; fill the large textbox at the bottom of the screen
    call init_fill_small_textbox ; fill the smaller sub textbox as well
    call load_battle_hud_icons ; load the battle hud icons into vram
    call display_hud_icons ; display the hud icons in the statboxes
    call set_textbox_vblank ; reset the textbox engine to work in vblank
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
    loadstr battle_magic ; buffer magic string
    ld de, wStringBuffer ; point de at the start of the buffer
    ld hl, tilemap_smallbox_magic ; point at the desitnation
    call strcpy ; draw to the screen
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

; draw player MP to the tilemap
init_drawplayer_mp:
    ld a, [wPlayerMP] ; load mp into a
    call number_to_string ; convert to string
    ld de, wStringBuffer ; point de at the buffer
    ld hl, tilemap_player_mp ; point hgl at the start of the mp location
    call strcpy ; copy to screen
    ld a, "/" ; load slash
    ld [hl], a ; display it to the screen
    inc hl  ; oh also move hl forward
    ld a, [wPlayerMaxMP] ; load max mp
    call number_to_string ; convert to string
    ld de, wStringBuffer ; point de at the buffer again
    call strcpy ; copy to the screen
    ret ; we've finished, leave

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
init_configure_foe_spritearea:
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
init_draw_foe_statbox:
    ld hl, foe_statbox_start ; point hl at the start of the memory region for the statbox
    ld b, 9 ; 9 tiles wide
    ld c, 5 ; 5 tiles tall
    farcall draw_textbox_improved ; draw a textbox
    ret ; we've finished, so leave

; draws the player's name onto the statbox
init_draw_player_name:
    ld de, wPlayerName ; point de at the player's name
    ld hl, battle_playername ; point hl at destination
    jp strcpy
; draw foe name into the tilemap
init_draw_foe_name:
    ld de, wFoeName ; point de at source
    ld hl, foe_name_start ; point hl at desitnation
    jp strcpy

; draw the player's health and other stats box
init_draw_player_healthgui:
    ld hl, start_player_battlegui ; point hl at the start of the battle gui
    ld b, 10 ; 10 tiles wide
    ld c, 5 ; 5 tiles tall
    farcall draw_textbox_improved ; draw a textbox
    ret ; yeet

; draws the main textbox at the bottom of the screen
init_draw_bottom_textui:
    ld b, 11 ; 11 tiles long
    ld c, 4 ; 4 tiles tall
    ld hl, topleft_bg_textbox ; point hl at the top left of where we want the textbox to go
    farcall draw_textbox_improved
    ld b, 9 ; 9 tiles long
    ld c, 4 ; 4 tiles high
    ld hl, $99CB ; start of sub textbox
    farcall draw_textbox_improved ; draw the textbox
    ret

; moves HL forward c bytes
move_address:
    push bc ; backup bc
    xor a ; load 0 into a
    ld b, a ; put 0 into b
    add hl, bc ; add them together
    pop bc ; restore bc to what it was before
    ret ; lea ve lol

; loads batttle hud icons into vram
; LCD must be off!
load_battle_hud_icons:
    push bc
    push de ; back up all the shit
    push hl
    ld de, battle_hud_icons
    ld a, bank(battle_hud_icons) ; point de and a at the hud icons
    call buffer_sprite ; cheat and buffer the icons using this routine
    ld de, wSpriteBuffer ; point de at the sprite buffer
    ld hl, hud_icons_vram_loc ; point hl at the desitnation
    xor a ; load 0 into a
    ld c, a ; zero out c
    ld b, hud_bytes ; load how many bytes we need to copy into b
.loop
    ld a, c ; load c into a
    cp b ; is it equal to b?
    jr z, .done ; yeetus
    ld a, [de] ; load byte from de
    ld [hl], a ; write into vram
    inc hl
    inc de ; increment source and desitnation
    inc c ; increment c
    jr .loop ; go back to the loop
.done
    pop hl
    pop de ; restore everything we backed up
    pop bc
    ret ; yeet the fuck outta here

; display the icons 
display_hud_icons:
    ld a, hud_hp_icoindex ; load hp index into a
    ld [hud_hp_icon], a ; write to tilemap
    ld a, hud_mp_icoindex ; load mp icon index into a
    ld [hud_mp_icon], a ; writte to tile map
    ret ; leave

; display the foe's level to the screen
init_draw_foe_level:
    loadstr battle_foe_level_text ; load the base string
    ld b, 3 ; we need to copy 3 bytes
    ld hl, wStringBuffer ; point at string buffer
    push hl ; put a copy of hl onto the stack
    ld de, wTempBuffer ; copy to larger buffer
    call copy_bytes ; copy
    ld a, [wFoeLevel] ; load foe's level into a
    call number_to_string
    pop hl ; hl is now wStringBuffer
    push hl ; another copy on the stack
    ld de, wTempBuffer2 ; point de at the second temp buffer
    call copy_bytes ; copy the result to wTempBuffer2
    ld hl, wTempBuffer ; point  hl at the buffer
    pop de ; de is now wStringBuffer
    push de ; put another copy on the stack
    call copy_bytes ; copy original string back
    ld hl, wTempBuffer2 ; point hl at tempbuffer2
    call copy_bytes ; copy the number to the thing
    ld a, terminator ; load a with the terminator
    ld [de], a ; append terminator to end
    pop de ; de is now WStringBuffer
    ld hl, tilemap_foe_level ; point it at where the foe's level goes
    call strcpy
    ret ; yeet

; moves the player to the last map they healed at after they died
respawn_player_after_death:
    push hl
    push de
    ld de, wPlayerLastHealData ; point de at the last heal data
    ld a, [de] ; load the bank into a
    ld b, a ; put the bank into b
    inc de ; next byte plz
    ld a, [de] ; load low byte of map into a
    ld l, a ; store into l
    inc de ; move to high byte of map location
    ld a, [de] ; load it
    ld h, a ; save into h
    inc de ; move to player x
    ld a, [de] ; load player x
    ld [wPlayerx], a ; update memory
    inc de ; move to player y
    ld a, [de] ; load into a
    ld [wPlayery], a ; update memory
    farcall load_overworld_map ; load the map
    ld b, predef_invalidate_map
    farcall run_predefined_routine ; invalidate all map data by using a predefined routine
    ld b, predef_slient_heal
    farcall run_predefined_routine ; heal the player as well
    pop de
    pop hl
    ret ; yeet