SECTION "Main Overworld Code", romx
include "macros.asm"
def joypad equ $ff00

; window size is 20x by 18y tiles

; main overworld first init routine
run_overworld::
    ; first we copy string1 into the buffer
    loadstr test_string
    displaystr $9801
    queuetiles banana, 1, 76
    ld a, 76 ; load tile index into a
    ld [wOAMSpriteOne + 2], a ; put that into the oam buffer
    xor a
    res 7, a ; do not display bg over this sprite
    ld [wOAMSpriteOne + 3], a
    halt ; wait for vblank to finish loading the tile into memory
    ld a, 3 ; load our tile x coord into a
    ld [wPlayerx], a ; store it
    ld a, 1 ; put 0 into a
    ld [wPlayery], a ; store that as our y coord
    call calculate_overworld_pos
    ; load a map really quick
    ld a, BANK(test_map_header)
    ld hl, test_map_header
    call load_overworld_map
    call select_dpad ; select the dpad
    ld hl, joypad
.loop
    ld a, [hl]
    ld a, [hl]
    ld a, [hl]
    ; check for inputs
    bit 0, a ; right on dpad
    jr z, .right
    bit 1, a ; left press?
    jr z, .left
    bit 2, a ; up press?
    jr z, .up
    bit 3,  a ; down press?
    jr z, .down
    jr .lazy_update ; run map scripts even if the player did not move
.up
    ld a, [wActionBuffer] ; load action buffer into a
    set 3, a ; set bit 3 for negative y movement
    ld [wActionBuffer], a
    jr .update
.down
    ld a, [wActionBuffer] ; load action buffer into a
    set 2, a ; set bit 2 for positive y movement
    ld [wActionBuffer], a ; put it back
    jr .update
.left
    ld a, [wActionBuffer] ; load action buffer into a
    set 1, a ; set bit 1 for negative x movement
    ld [wActionBuffer], a ; put it back into the buffer
    jr .update
.right
    ld a, [wActionBuffer] ; load action buffer into a
    set 0, a ; set bit 0 for postitive x movement
    ld [wActionBuffer], a ; store it back
    jr .update
.update
    push hl ; backup hl
    ld hl, wActionBuffer ; point hl at our action buffer
    call find_new_xy ; find out our new x/y value
    call calc_maptilebuffer_pos ; find what tile we are going to be walking too
    call do_tile_collision ; do tile collision checks
    bit 4, [hl] ; are we allowed to move on this tile?
    call nz, update_player_pos ; update player position if we can walk here
    push hl ; backup hl
    ld hl, wOverworldFlags ; point hl at our flags
    res 0, [hl] ; reset bit 0
    pop hl ; restore hl
    call nz, calculate_overworld_pos ; also update sprite position if we can walk here
    bit 5, [hl] ; is this tile an encounter tile?
    call nz, do_encounter
    xor a ; load 0 into a
    ld [hl], a ; zero out action buffer
    pop hl ; restore hl
    ld a, 78
    ld [wSubLoopCount], a
    call waste_time ; waste time
.lazy_update
    call process_mapscripts ; process map scripts for this map
    jr .loop

; handles doing a random encounter
do_encounter:
    push hl ; back this up
    call random ; get a random number
    push af ; backup our random number
    ld a, 5 ; load 15 into a
    ld c, a ; put that 15 into c
    pop af ; get our random number back
    call simple_divide ; this also serves as modulo (in a)
    cp 4 ; is a 4?
    jr nz, .false ; if no, leave
.true
    buffertextbox encounter_test
    call show_textbox
    call do_textbox
    call clear_textbox
    call hide_textbox
    ld a, bank(evil_cardbox_data)
    ld hl, evil_cardbox_data
    call load_foe_data ; load foe data into the buffer
    call hide_player_sprite ; hide the player sprite
    farcall do_battle
    call select_dpad
.false
    pop hl ; restore hl to what it was before
    ret ; this is test code lul

; hides the player sprite from the LCD
hide_player_sprite:
    xor a ; load 0 into a
    ld [wOAMSpriteOne], a ; store new y coord into the buffer
    call queue_oamdma ; preform a dma transfer
    ret ; leave

; update player position using BC
update_player_pos:
    ld a, b ; load new x into a
    ld [wPlayerx], a ; store that into playerx
    ld a, c ; load new player y into a
    ld [wPlayery], a ; store it into memory
    ret ; get the fuck out

; finds the new XY values, and puts them into bc
; point HL at wActionBuffer first
find_new_xy:
    ld a, [wPlayerx] ; load player x into a
    ld b, a ; put it into b
    ld a, [wPlayery] ; load player y
    ld c, a ; put it into c
    bit 0, [hl] ; positive x movement?
    jr nz, .right
    bit 1, [hl] ; negative x movement?
    jr nz, .left
    bit 2, [hl] ; positive y?
    jr nz, .down
    bit 3, [hl] ; negative y movement?
    jr nz, .up
.right
    inc b ; move right 1 tile
    jr .done
.left
    dec b ; move left 1 tile
    jr .done
.up
    dec c ; move up one tile
    jr .done
.down
    inc c ; move down 1 tile
.done
    xor a ; zero out a
    ld a, [hl] ; zero out the action buffer
    ret ; return to caller routine

; calculate the actual position the sprite should be rendered at, then update OAM
; X coord = (x * 8) + 8
; Y coord = (y * 8) + 16
calculate_overworld_pos:
    push af ; backup af
    push hl ; oops i need HL now too
    ld a, [wPlayerx] ; load our player x coord into a
    inc a ; same as adding 8
    call multiply_by_eight ; get x coord into a
    ld [wOAMSpriteOne + 1], a ; store x coord value
    ; now we do the same thing for y, more or less
    ld a, [wPlayery] ; load  y grid value into a
    inc a ; we just have to add 16
    inc a ; or add 2 before multiplying by 8
    call multiply_by_eight ; get base xcoord into a
    ld [wOAMSpriteOne], a ; and store it into memory
    call queue_oamdma ; do an oamdma transfer
    pop hl
    pop af ; restore our stack values
    ret ; we done here

; processes map scripts based on X/Y value in header
; TODO: check more then the first script lol
process_mapscripts:
    xor a ; put a 0 into a
    ld [wCurrentScript], a ; initialize our current script value to 0
    ld de, wMapHeader ; point de at our header
    inc de
    inc de ; increment DE to the start of X/Y coord events
    inc de
    inc de
    push bc ; backup bc
    ld a, [de] ; load how many mapscripts there are
    ld c, a ; put that into c
    cp 0 ; are there 0 map scripts?
    jr z, .done ; leave
    inc de ; increment de
.loop
    ld a, [wCurrentScript] ; load current script into a
    cp c ; compare to our total amount of scripts
    jr c, .resume ; if it is less then our total scripts, resume execution
    jr .done ; otherwise, leave lol
.resume
    ld a, [wPlayerx] ; load our current x position into a
    ld b, a ; store that into b
    ld a, [de] ; load x byte from first map script
    cp b ; are they equal?
    jr z, .checky ; if yes, check the y position the same way
    jr .nextfromx ; if not, go prepare to read the next script
.checky
    ld a, [wPlayery] ; load our y position into a
    ld b, a ; store it into b
    inc de ; increment source address
    ld a, [de] ; load y position into de
    cp b ; is our y position equel to the script y?
    jr z, .loadscript ; load the script if the x/y match up
    jr .nextfromy ; if not, process next event
.loadscript
    ; backup hl
    push hl
    ld hl, wOverworldFlags ; point hl at overworld flags
    bit 0, [hl] ; is bit 0 set?
    jr nz, .noscriptload ; we already loaded the script so we dont have to reload it
    inc de ; increment de
    ld a, [de] ; load rombank into a
    ld b, a ; store that rombank into b
    inc de ; increment to get the source address low byte
    ld a, [de] ; load low byte into a
    ld l, a ; put it into l
    inc de ; next byte please!
    ld a, [de] ; load high byte into a
    ld h, a ; put it into h
    farcall buffer_map_script ; load the map script into memory
    ld hl, wOverworldFlags ; point hl at our buffer again
    set 0, [hl] ; set script loaded flag
    ; we're back!
.noscriptload
    call script_parser ; parse our script
    pop hl ; once we've finished that, we can get hl back off the stack
    ; then just fall thru execution to done
.done
    pop bc ; pop bc off the stack
    ret ; gtfo lol
.nextfromx
    inc de
.nextfromy
    inc de
    inc de ; increment script source address 5 times
    inc de ; this gets us past y coord and
    inc de ; script pointer
    ld a, [wCurrentScript] ; load current script index
    inc a ; add one
    ld [wCurrentScript], a ; store it back into memory
    jr .loop ; go to the loop of dooooooom


; map script commands
def open_text equ $FD
def close_text EQU $FC
def load_text EQU $FB
def do_text EQU $FA
def script_end equ $F9
def abutton_check EQU $F8
def flag_check equ $F7
def flag_set equ $F6
; parses the currently loaded map script
script_parser:
    ld de, wMapScriptBuffer ; point de at our map script
.loop
    ld a, [de] ; load script byte
    cp open_text ; does it want to open a textbox?
    jr z, .otext
    cp load_text ; does itt want to load text?
    jr z, .loadtext
    cp do_text ; does it want to run the text script?
    jr z, .dotext
    cp close_text ; does it want to close a textbox?
    jr z, .closetext
    cp script_end ; end of script?
    jr z, .end
    cp abutton_check ; does the script want us to press a on this tile?
    jr z, .button ; go check for that
    cp flag_check ; does it want us to check a flag?
    jr z, .flag
    cp flag_set ; do they want to set a flag?
    jr z, .flagset
.otext
    call show_textbox ; simply draw a text box!
    jr .incsc ; go back to the loop
.loadtext
    inc de ; increment to bank number byte
    ld a, [de] ; load that into de
    ld b, a ; put bank number into b
    inc de ; increment by one to get the low byte of text
    ld a, [de] ; get that byte
    ld l, a ; put it into l
    inc de ; increment to high byte
    ld a, [de] ; load into a
    ld h, a ; put into h
    push de
    call buffer_textbox_content ; buffer the content of the textbox
    pop de
    jr .incsc ; go back to the loop
.button
    call select_buttons ; select buttons
    ld hl, joypad ; point hl at the joypad
    ld a, [hl]
    ld a, [hl]
    bit 0, a ; is the a button pressed?
    call select_dpad ; select the dpad
    jr nz, .end ; leave if it is not
    jr z, .incsc ; loop if it is
.dotext
    call do_textbox ; simply run the textbox
    jr .incsc ; go back to the loop
.closetext
    call clear_textbox ; clear the textbox
    call hide_textbox ; get rid of it lol
    call select_dpad
    jr .incsc
.incsc
    inc de
    jr .loop
.end
    ; end of script, we can just leave lol
    ret
.flag
    jp parse_script_flags ; this routine is gonna be big, so move it elsewhere
.flagset
    call set_flag ; set the flag
    jr .incsc ; keep running the script

; sets an event flag to true (or 1)
set_flag:
    inc de ; increment to low byte of flag
    ld a, [de] ; load it into a
    ld l, a ; store it into l
    inc de ; move to high byte
    ld a, [de] ; load it into a
    ld h, a ; store it into h
    ld a, 1 ; load 1 into a
    call bankmanager_sram_bankswitch ; switch to sram bank 1
    call mbc3_enable_sram ; enable sram
    xor a ; 0 out a
    inc a ; a is now 1
    ld [hl], a ; set the flag byte to 1
    call mbc3_disable_sram ; close sram
    ret ; leave


; handle flag checks in a script
parse_script_flags:
    inc de ; increment to low byte of flag location
    ld a, [de] ; load it into a
    ld l, a ; store low byte into l
    inc de ; next byte; high byte of address
    ld a, [de] ; load it into a
    ld h, a ; store it into h
    ; next we have to switch sram banks
    ld a, 1 ; we want bank 1
    call bankmanager_sram_bankswitch ; switch banks
    call mbc3_enable_sram ; open sram for reading
    ld a, [hl] ; load flag into a
    call mbc3_disable_sram ; close sram
    cp 0 ; is the flag 0?
    jr z, .false ; then its false
    cp $FF ; BUT WAIT! it could also be FF
    jr z, .false
.true
    jr .skipinc ; we can reuse this code!
.false
    inc de ; true bank
    inc de ; true low
    inc de ; true high
.skipinc
    inc de ; ah! bank of our script
    ld a, [de] ; load it into a
    ld b, a ; put it into b
    inc de ; move to low byte of script
    ld a, [de] ; load it into de
    ld l, a ; put it into l
    inc de ; high byte of script address
    ld a, [de] ; load it into a
    ld h, a ; store it into h
    farcall buffer_map_script ; load our map script
.done
    ; because we loaded a new script, we need to invalidate whats loaded
    ld hl, wOverworldFlags ; point hl at our flags
    res 0, [hl] ; reset bit 0
    jp script_parser ; jump to the script parser



; multiplies a by 8
multiply_by_eight:
    sla a
    sla a
    sla a ; logical shift left 3 times to multiply by 8
    ret ; if it is 0, return


; loads a map header (and then rest of map) from ROMBank a and address hl
load_overworld_map:
    push bc ; backup bc
    ld b, a ; store rombank into b
    farcall buffer_map_header ; buffer the map header
    farcall map_header_loader_parser ; load the tile information too
    pop bc ; get bc off the stack again
    ret ; we're done for now

; gets current tile at x (b), y (c) and returns its address in hl
calc_maptilebuffer_pos:
    push af ; backup af
    ld hl, wMapTileBuffer ; point hl at our map tile buffer  in work ram
    push de ; backup DE as well
    xor a ; put 0 into a
    ld d, a ; put 0 into d
    ld a, b ; load passed in xcoord into a
    ld e, a ; store it into e
    add hl, de ; add hl and de together
    ld a, 20 ; load 20 into a (how many columns per map)
    ld e, a ; store that into e
    xor a ; store 0 into a
.loop
    cp c ; is a equal to c (y coord?)
    jr z, .done ; leave if yes
    add hl, de ; add 20 to hl's address
    inc a ; increment a
    jr .loop ; go back and loop some more
.done
    pop de ; restore de
    pop af ; restore a
    ret ; yeetus

; tile ids imported from resources.asm
def empty EQU $00 
def wall_tile equ $4D 
def encounter1 equ $4E 
def encounter2 equ $4F 
def info_tile equ $50 
def pathway_tile EQU $51 
; based on tile at hl, preform collision detection
; stores results in wActionBuffer
do_tile_collision:
    ld a, [hl] ; load tile at hl into a
    ld hl, wActionBuffer ; point hl at our buffer
    cp empty ; empty tile?
    jr z, .walkable
    cp pathway_tile ; pathtile?
    jr z, .walkable
    cp encounter1 ; encounter tile?
    jr z, .encounter
    cp encounter2 ; second encounter tile?
    jr z, .encounter
    cp wall_tile ; is it a wall?
    jr z, .done
    cp info_tile ; is it an info tile?
    jr z, .done
.walkable
    set 4, [hl] ; you are allowed to move on this this
    jr .done
.encounter
    set 5, [hl] ; this is an encounter tile!
    jr .walkable ; but also walkable!
.done
    ret ; bascially just leave lol

