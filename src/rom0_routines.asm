include "macros.asm"
include "constants.asm"
include "include/hardware.inc/hardware.inc"

section "ROM0 Init Routines", rom0
start_intro_sequence::
	farcall do_intro_screen
	ret ; leave lol

section "Rom 0 MATH routines", rom0
; borrowed from pokecrystal
; divides a by c; answer in b and remainder in a
simple_divide::
	ld b, 0 ; load 0 into b
.loop
	inc b ; increment b
	sub c ; subtract c from a
	jr nc, .loop ; if not 0, loop more
	dec b ; decrement b
	add c ; add c to a
	ret

; subtracts DE from HL
; preserves BC
; Thanks Chjara
sixteen_sixteen_subtraction::
	ld a,l ; load l into a
	sub e ; subtract e from a
	ld l,a ; put a back into l
	ld a,h ; load h into a
	sbc d ; subtract d from a including carry if applicatable
	ld h,a ; put a back into h
	ret ; leave

; returns a * c
simple_multiply::
	and a
	ret z ; return if 0
	push bc ; backup bc
	ld b, a ; load a into b
	xor a ; 0 into a
.loop
	add c ; add c to a
	jr c, .overflow ; oops, we mightve overflowed
	dec b ; decrease b by 1
	jr nz, .loop ; loop if 0 is not 0
.exit
	pop bc ; restore bc
	ret ; leave
.overflow
	ld a, $FF ; max out a
	jr .exit

; subtract HL by a
; if both h and l are 0, leaves
sixteenbit_subtraction::
	ld c, a ; load c into a
	xor a ; 0 into a
	ld b, a ; load 0 into b
.loop
	ld a, b ; load b into a
	cp c ; is a c?
	jr z, .done ; leave
	dec hl ; subtract 1 from hl
	ld a, l ; load l into a
	cp 0 ; is l 0?
	jr z, .checkh
	inc b ; add 1 to b
	jr .loop ; go to loop
.checkh
	ld a, h ; load h into a
	cp 0 ; is h also 0?
	jr z, .done ; leave
	inc b ; increment our counter
	jr .loop ; go back to the loop then
.done 
	ret ; leave
	
; adds A to HL
; stolen from https://plutiedev.com/z80-add-8bit-to-16bit
sixteenbit_addition::
	add a, l ; a = a + l
	ld l, a ; l = a + l
	adc a, h ; a = a + l + h + carry
	sub l ; a = h + carry
	ld h, a ; h = h + carry
	ret ; leave

; multiplies a by 8
multiply_by_eight::
    sla a
    sla a
    sla a ; logical shift left 3 times to multiply by 8
    ret ; if it is 0, return

; divides hl by c
; quotient in hl and remainder in a
; borrowed from https://wikiti.brandonw.net/index.php?title=Z80_Routines:Math:Division
div_hl_c::
	xor a ; put 0 into a
	ld b, 16 ; put 16 into b
.loop:
	add hl, hl ; add hl to hl
	rla ; rotate a left thru carry (????????????)
	jr c, .djnz ; carry set? leave
	cp c ; compare a to c
	jr c, .djnz ; leave
	sub c ; subttract c from a
	inc l ; add 1 to l
.djnz
	dec b ; subttract 1 from b
	jr nz, .loop ; jump to loop if not 0 (replaced djnz)
.done
	ret ; leave

; divides DE by BC. DE is result, BC is remainder
; trashes HL
div_16_by_16::
	ld hl, w16DivisionTemp ; point hl at the tempspace we provided for it
	ld [hl], c ; load address at hl with c
	inc hl ; move hl forward 1 address
	ld [hl], b ; store b at address hl
	inc hl ; move hl forward 1
	ld [hl], 17 ; store 17 at adress hl
	xor a ; 0 into a
	ld b, a ; put 0 into b
	ld c, a ; also put 0 into c
.loop
	ld hl, w16DivisionCount ; point hl at the count
	ld a, e ; load e into a
	rla ; do something uhhhh idk
	ld e, a ; put a into e
	ld a, d ; put d into a
	rla ; do the thing uhhh idk
	ld d, a ; put the result back into d
	dec [hl] ; decrease value at hl by 1
	ret z ; return if value is 0
	ld a, c ; load c into a
	rla ; wow its the thing again
	ld c, a ; put a back into c
	ld a, b ; pput b into a
	rla ; sus
	ld b, a ; put a into b
	dec hl
	dec hl ; move hl backwards 2
	ld a, c ; load c into a
	sub [hl] ; subtract value at hl from a?
	ld c, a ; load a into c
	inc hl ; move hl forward 1
	ld a, b ; load b into a
	sbc [hl] ; subtract with carry at hl
	ld b, a ; load a back into b
	jr nc, .dontadd ; if carry not set, do not add
	dec hl ; move hl backwards 1
	ld a, c ; load c into a
	add a, [hl] ; add address hl to a
	ld c, a ; load a into c
	inc hl ; move hl forward 1
	ld a, b ; load b into a
	adc a, [hl] ; do some funky math shit
	ld b, a ; load a into b
.dontadd
	ccf ; ?????????
	jr .loop ; go back to the loop


section "Rom 0 Bankswitch loader routines", rom0
; loads enemy data from ROMBank a at address hl
load_foe_data::
	push bc ; backup bc
	push de ; backup de
	call bankmanager_switch ; switch to rombank A
	xor a ; load 0 into a
	ld b, a ; put 0 into b
	ld de, wEmenyDataBuffer ; point de at our buffer
.loop
	ld a, b ; load b into a
	cp foe_buffer_size ; have we reached the max capcity of our buffer?
	jr z, .done ; leave
	ld a, [hl] ; else, load byte from source address
	ld [de], a ; and write to buffer
	inc hl
	inc de ; increment source and destination
	inc b ; increment our counter
	jr .loop ; go and loop some more
.done
	call bankswitch_return ; switch back to previous rombank
	pop de
	pop bc ; pop old values off the stack
	ret ; leave

; loads encounter table from de and bank a into wEncounterTableBuffer
load_encounter_table::
	push hl ; backup hl
	push bc ; also backup bc
	call bankmanager_switch ; switch rombanks
	ld c, encounter_table_buffer_size ; load c with our buffer size
	xor a ; put 0 into a
	ld b, a ; put 0 into b
	ld hl, wEncounterTableBuffer ; point hl at the buffer
.loop
	ld a, b ; load b into a
	cp c ; have we copied all the bytes?
	jr z, .done ; if yes, leave
	ld a, [de] ; load byte at de
	ld [hl],  a ; write it to our buffer
	inc hl
	inc de ; increment source and desitnation
	inc b ; increment counter
	jr .loop
.done
	call bankswitch_return ; switch back to previous bank
	pop bc
	pop hl ; restore
	ret ; leave

section "Rom 0 short routines", rom0
; returns A with only bit B set
; thanks koa
find_bit::
	ld a, 1 ; load 1 into a
	inc b ; add 1 to b
.loop
	dec b ; subtract 1 from b
	jr z, .done ; if b is 0, we are done
	add a ; add a to a
	jr .loop ; go back to the loop
.done
	ret ; yeet

; set textbox mode to vblank
set_textbox_vblank::
	push af
	xor a ; 0 into a
	ld [wTextboxDrawMode], a ; 0 into the mode
	pop af
	ret

; set textbox mode to direct
set_textbox_direct::
	push af
	xor a
	inc a ; a is now 1
	ld [wTextboxDrawMode], a ; put that into the mode
	pop af
	ret ; yeet

; draw tile d e times starting at hl
tile_draw_loop::
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

; quickly copy a string from wram into tilemap
; copies from de to HL
strcpy::
    ld a, [de] ; load byte at de into a
    cp $FF ; string terminator?
    jr z, .done ; leave
    ld [hl], a ; ottherwise write to hl
    inc hl
    inc de ; increment destination and source address
    jr strcpy ; go loop some more
.done
    ret ; leave lol

; copies wStringBuffer to hl during vblank
strcpy_vblank::
    ld de, wStringBuffer ; point de at the string buffer
.loop
    ld a, [de] ; load byte from de
    cp $FF ; is it string terminator?
    jr z, .done ; leave
    ld [wTileBuffer], a ; store byte into buffer
    updatetile ; make vblank update it
    inc hl ; move dest forward
    inc de ; move source forward
    jr .loop ; go loop some more
.done
    ret ; we've finished, so leave

; draws tile d e times starting at hl using vblank
tile_draw_loop_vblank::
	xor a ; put 0 into a
	ld c, a ; put 0 into c
.loop
	ld a, c ; load c into a
	cp e ; have we finished?
	jr z, .done
	ld a, d ; load tile into d
	ld [wTileBuffer], a ; put it into buffer
	updatetile ; make vblank update it
	inc hl ; move desitnation forward
	inc c ; increment  countter
	jr .loop ; go back to the loop
.done
	ret ; leave

; cleans the BG tilemap
; LCD must be off before you call
clear_bg_tilemap::
	push hl
	push af
	push bc
	push de ; backup literally everything
	ld hl, $9800 ; point hl at the start of our tilemap
	xor a ; put 0 into a
	ld b, a ; put 0 into b
	ld c, a ; put 0 into c
	ld d, a ; put 0 into d
	ld a, 12 ; load 12 into a
	ld e, a ; put that into e
.loop
	ld a, c ; load c into a
	cp 20 ; have we cleared 20 tiles?
	jr z, .linecheck ; move down to the line check
	xor a ; put 0 into a
	ld [hl], a ; put 0 into hl
	inc hl ; next byte please
	inc c ; also increment our counter
	jr .loop ; go loop some more
.linecheck
	ld a, b ; load b into a
	cp 17 ; have we done this `18 times?
	jr z, .done ; leave
	add hl, de ; otherwise, add de to hl
	xor a ; put 0 into a
	ld c, a ; set c to 0
	inc b ; add 1 to b
	jr .loop ; go back to the main loop body
.done
	pop de
	pop bc
	pop af
	pop hl ; pop everything off the stack
	ret ; leave

; queues up a LCD disable
disable_lcd::
	push hl ; backup hl
	ld hl, wVBlankFlags ; point hl at our flags byte
	set 2, [hl] ; set bit 2
	halt ; wait for vblank to do the do
	pop hl ; retore hl
	ret ; leave

; seeds the 2 rng bytes
seed_rng::
	push hl
	push af
	ld hl, wRNGSeed
	ldh a, [rDIV] ; get 1 rdiv byte
	ld [hl], a ; write to hl
	inc hl ; move forward 1
	ldh a, [rDIV] ; get another byte
	inc a ; add 1
	ld [hl], a ; write to seed
	pop af
	pop hl
	ret ; yeet

; based on https://wikiti.brandonw.net/index.php?title=Z80_Routines:Math:Random
; returns number in a
random::
	push hl ; backup hl
	ld a, [wRNGSeed]
	ld h, a ; l now has a seed of atleast 1
	ld a, [wRNGSeed + 1]
	ld l, a ; HL now has the seed inside of it
	; RNG algo starts here
	ld a, h ; load h into a
	rra
	ld a,l ; load l into a
	rra
	xor h ; xor a with h
	ld h,a ; load a into h
	ld a,l ; load l into a
	rra
	ld a,h ; load h into a
	rra
	xor l ; xor a with l
	ld l,a ; load a into l
	xor h ; xor a with h
	ld h,a ; load a into h
	; update the SEED
	ld a, h
	ld [wRNGSeed], a
	ld a, l
	ld [wRNGSeed + 1], a
	; HL now has our random number
	ld a, l ; we throw out h and keep l as the result
	pop hl
	ret

; queues a OAMDMA transfer
queue_oamdma::
	push hl ; backup hl
	ld hl, wVBlankFlags ; point hl at our flags
    set 4, [hl] ; bit 4 is oam dma transfer
    halt ; wait
	pop hl ; pop hl off the stack
	ret ; return to caller function

; selects the dpad
select_dpad::
	push hl
	ld hl, joypad ; point hl at joypad
    set 5, [hl] ; do not select the action buttons
    res 4, [hl] ; select the dpad
	pop hl
	ret

; selects action buttons
select_buttons::
	push hl
	ld hl, joypad ; point hl at our joypad
    res 5, [hl] ; select action buttons
    set 4, [hl] ; do not select dpad
	pop hl
	ret

; enables the window layer 
enable_window::
	push hl ; backup hl
	ld hl, rLCDC ; point hl at the LCD register
	set 5, [hl] ; enable tthe window
	pop hl ; restore hl
	ret ; leave

; disables the window layer
disable_window::
	push hl ; bnack up hl
	ld hl, rLCDC ; pointt hl at LCD control register
	res 5, [hl] ; disable window
	pop hl ; restore hl
	ret ; leave

; copies B bytes from hl to de
copy_bytes::
    xor a ; 0 into a
    ld c, a ; put 0 into c
.loop
    ld a, c ; load c into a
    cp b ; have we done this 3 times?
    jr z, .leave ; we're done
    ld a, [hl] ; load first byte into a
    ld [de], a ; write into de
    inc hl
    inc de ; increment source and desitnation
    inc c ; inc counter
    jr .loop ; go loop
.leave
    ret ; leave

; converts number A into string
; resulting string is in wStringBuffer
number_to_string::
    push bc ; backup bc
    push hl ; backup hl
    ld de, wStringBuffer ; point de at the string buffer
    ld c, 100 ; load 100 into c
    call simple_divide ; a / c
    push af ; backup a
    ld a, b ; put b into a
    call .append ; append to buffer
    pop af ; restore af
    ld c, 10 ; load 10 into c
    call simple_divide ; a / c
    push af ; backup a again
    ld a, b ; put b (answer) into a
    call .append ; append to buffer
    pop af ; restore af (a is the remainder)
    call .append ; append the remainder to the buffer
    ld a, terminator ; load a with terminator
    ld [de], a ; write it to the end of the buffer
    pop hl
    pop bc ; pop everything off the stack we backed up
    jr .leave
.append
    ld c, start_of_numbers ; load with the start of numbers
    add a, c ; add c to a
    ld [de], a ; write to buffer
    inc de
.leave
    ret ; leave