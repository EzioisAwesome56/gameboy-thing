include "macros.asm"
include "constants.asm"
section "Rom0 Save File Routines", rom0
; copies b bytes from de to hl
memcopy::
	xor a ; 0 out a
	ld c, a ; put that 0 into c
.loop
	ld a, b ; load b into a
	cp c ; have we copied all the bytes we need?
	ret z ; yeet the fuck outta here
	ld a, [de] ; load 1 byte into a
	ld [hl], a
	inc de
	inc hl
	inc c ; increment all the things
	jr .loop ; go back to the loop

; saves the game
; doesnt really do anything else
save_game::
	push bc
	push hl
	push de
	buffertextbox save_game_prompt
	farcall clear_textbox ; empty the textbox
	farcall do_textbox
	farcall prompt_yes_no
	; once the yes no prompt has finished, check what they answered
	ld a, [wYesNoBoxSelection]
	cp 1 ; did they pick yes?
	jr z, .yes
	jp .exit
.yes
	buffertextbox saving_text
	farcall do_textbox ; display the saving... text to the screen
	; WRITING THE SAVE FILE BEGINS HERE
	xor a
	inc a ; a is now 1
	call bankmanager_sram_bankswitch ; switch sram banks
	call mbc3_enable_sram ; open sram for writing
	; first: player name
	ld b, 8 ; 8 into b
	ld de, wPlayerName ; source
	ld hl, sSavedName ; desitnation
	call memcopy ; copy it
	; next: experience point stats
	ld b, 4 ; load 4 into b
	ld de, wCurrentExperiencePoints ; point de at the source
	ld hl, sSavedEXP ; point hl at destination
	call memcopy ; copy it into place
	; next: current hp and maximum hp
	ld b, 4
	ld de, wPlayerHP
	ld hl, sSavedHP
	call memcopy ; copy it to sram
	; next: attack and defense (they are next to eachother in memory so)
	ld b, 2
	ld de, wPlayerAttack
	ld hl, sSavedAttack
	call memcopy
	; next: copy map header pointer to sram
	ld a, [wCurrentMapBank] ; load bank into a
    ld [sSaveMapHeaderPtr], a ; write bank to save file
    ld a, [wCurrentMapAddress + 1] ; get high byte
    ld [sSaveMapHeaderPtr + 1], a ; save it
    ld a, [wCurrentMapAddress] ; get low byte
    ld [sSaveMapHeaderPtr + 2], a ; save it
	; next: copy MP stats to the save file
	ld b, 2 ; we need to copy 2 bytes
	ld de, wPlayerMP ; source is current mp
	ld hl, sSavedMP ; destination is in the save file
	call memcopy ; copy it
	; next: copy player level
	ld a, [wPlayerLevel] ; it is one byte so we can do it by hand
	ld [sSavedLevel], a ; done
	; next: save currently unlocked magic
	ld a, [wUnlockedMagic] ; again, one byte, so we can do it like this
	ld [sSavedMagicUnlock], a ; done
	; next: player last heal information
	ld b, 5 ; we have 5 bytes to copy
	ld de, wPlayerLastHealData ; source
	ld hl, sSavedHealData ; destination
	call memcopy ; copy it to sram
	; next: copy player x and y to save file
	ld a, [wPlayerx]
	ld [sSavedX], a
	ld a, [wPlayery]
	ld [sSavedY], a ; done!
	; finally: copy events to the save file
	ld b, 255 ; we gotta copy a TON of shit
	ld de, wEventFlags ; source is event flags
	ld hl, sSavedEventFlags ; destination is the save file
	call memcopy ; copy it to the save file
	; now we need to calculate checksums for both halfs
	; first, the player stat information
	ld b, player_save_size ; we have 32 bytes we need to checksum
	ld hl, sSavedData ; this is where we want to checksum
	farcall calculate_checksum ; should be in hl now
	ld de, sSaveFileChecksum ; point de at the first checksum storage
	ld a, h ; get high byte
	ld [de], a ; write it
	inc de ; move forward 1
	ld a, l ; get low byte
	ld [de], a ; write to save file
	; next we need to checksum the event flags
	ld b, 255 ; yep theres a lot of them
	ld hl, sSavedEventFlags ; the data we want to checksum
	farcall calculate_checksum ; calculate a new checksum
	ld de, sSaveEventChecksum ; point de at the place to store checksum
	ld a, h ; get high byte
	ld [de], a ; write to save file
	inc de ; move forward 1
	ld a, l ; get low byte
	ld [de], a ; write to save file
	; we're done, almost
	ld a, 4 ; a is now 4
	ld [sHasSaveFile], a ; set save file flag
	; NOW we're done
	call mbc3_disable_sram ; close sram
	xor a ; a is now 0
	call bankmanager_sram_bankswitch ; go back to bank 0
	; END OF SAVE WRITING
	buffertextbox save_done_text
	farcall do_textbox ; display "save completed" text
	farcall textbox_wait_abutton ; wait for a button to be pressed 
.exit
	farcall hide_textbox ; hide the textbox
	farcall clear_textbox ; empty the textbox
	pop de
	pop hl
	pop bc
	ret ; leave this routine

; loads a saved game
load_save_game::
    push bc
    push de
    push hl ; backup everything
    ; first we need to switch banks
    ld a, BANK(sSavedData)
    call bankmanager_sram_bankswitch ; switch to bank 1
    call mbc3_enable_sram ; open sram for reading
    ; and now, we can begin to move everything into place
    ; first, get the map they saved on
    ld de, sSaveMapHeaderPtr ; first we start with the map header pointer
    ld a, [de] ; get bank
    ld b, a ; store into b
    inc de
    ld a, [de] ; high byte
    ld h, a ; store into h
    inc de ; next byte
    ld a, [de] ; load low byte
    ld l, a ; store into l
    farcall load_overworld_map ; load the map into memory
    ; scripts not loading fix:
    ; because loading an overworld map required using sram bank 0, that code
    ; closes sram once its done, which causes weirdness
    ; we need to switch to the correct bank and reopen sram
    ; ourselves as a fix
    ld a, BANK(sSavedData)
    call bankmanager_sram_bankswitch ; switch to bank 1
    call mbc3_enable_sram ; re-enable sram
    call disable_lcd ; turn the lcd off again
    ; next we will load the player's X and Y coords
    ld a, [sSavedX]
    ld [wPlayerx], a
    ld a, [sSavedY]
    ld [wPlayery], a
    ; next: copy player's name
    ld b, 8 ; player's name can be 8 bytes max
    ld de, sSavedName ; source
    ld hl, wPlayerName ; destination
    call memcopy ; write the name into memory
    ; next: player's HP
    ld b, 4 ; we need to copy 4 bytes
    ld de, sSavedHP ; source
    ld hl, wPlayerHP ; destination
    call memcopy ; copy it into wram
    ; next: attack and defense stats
    ld a, [sSavedAttack]
    ld [wPlayerAttack], a
    ld a, [sSavedDefense]
    ld [wPlayerDefense], a
    ; next: mp and max mp
    ld a, [sSavedMP]
    ld [wPlayerMP], a
    ld a, [sSavedMaxMP]
    ld [wPlayerMaxMP], a
    ; next: magic unlock and level
    ld a, [sSavedLevel]
    ld [wPlayerLevel], a
    ld a, [sSavedMagicUnlock]
    ld [wUnlockedMagic], a
    ; next: experience point information
    ld b, 4 ; we need to copy 4 bytes
    ld de, sSavedEXP
    ld hl, wCurrentExperiencePoints
    call memcopy ; copy the values into place
    ; next: heal data
    ld b, 5 ; we need to copy 5 bytes
    ld de, sSavedHealData
    ld hl, wPlayerLastHealData
    call memcopy ; copy 5 bytes to the correct place
    ; finally, we need to load event flags
    ld b, 255
    ld de, sSavedEventFlags
    ld hl, wEventFlags
    call memcopy ; this might take a hot second
    ; we're done
    ; switch back to sram bank 0
    xor a
    call bankmanager_sram_bankswitch
    ; disable sram
    call mbc3_disable_sram
    ; turn the LCD back on
    call enable_lcd
    pop hl
    pop de ; pop everything off the stack we pushed onto it
    pop bc 
    ret ; we are finally allowed to leave