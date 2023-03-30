
; interupt setups go here
SECTION "RST 28 Crash Handler", rom0[$0028]
	call crash_handler
SECTION "RST 38 Crash Handler", rom0[$0038]
	call crash_handler
SECTION "VBlank Interupt", rom0[$0040]
	jp do_vblank

SECTION "Header", ROM0[$100]

	; This is your ROM's entry point
	; You have 4 bytes of code to do... something
	di
	jp EntryPoint

	; Make sure to allocate some space for the header, so no important
	; code gets put there and later overwritten by RGBFIX.
	; RGBFIX is designed to operate over a zero-filled header, so make
	; sure to put zeros regardless of the padding value. (This feature
	; was introduced in RGBDS 0.4.0, but the -MG etc flags were also
	; introduced in that version.)
	ds $150 - @, 0

SECTION "Entry point", ROM0
include "include/hardware.inc/hardware.inc"
include "macros.asm"

EntryPoint:
	xor a ; load 0 into a
	ldh [hVBlank_counter], a
	ld [wVBlankFlags], a
	ld [wVBlankAction], a ; zero out vblank related flags
	ld sp, StackTop ; init the stack pointer
	call bankmanager_init ; now that call works, we can init the bankmanager via its own subroutine
	; set tthe tile data memory area to $8000
	ld hl, rLCDC
	set 4, [hl]
	; set background tilemap area to be 9800-9bFF
	res 3, [hl]
	; init intetrupts
	; first load interupt enable into hl
	ld  hl, rIE
	; enable only vblank for now
	set 0, [hl]
	; before we enable interupts, we need to tell vblank we want to load the charset
	queuetiles font, 26, 1
	; enable interupts
	ei
	; wait for vblank to load the font
	halt
	; load lowercase font
	queuetiles fontlow, 26, 35
	halt
	; load arrow graphic
	queuetiles arrow, 1, 61
	halt
	queuetiles textboxgfx, 8, 27
	halt ; load the textbox gfx as well
	queuetiles punc, 4, 62
	halt ; load punctuation
	queuetiles num, 10, 66 ; load numbers into vram
	halt   
	; jump to our main loop
	jp run_game

SECTION "ROM0 Short Routines", rom0

; generates a random number between 0 and 255
; based on https://wikiti.brandonw.net/index.php?title=Z80_Routines:Math:Random
; returns number in a
random::
	push hl
	push de ; back up registers
	; step 1: load HL with rdiv data
	ldh a, [rDIV] ; load a with data
	ld h, a ; and put it into h
	ldh a, [rDIV] ; now do it
	ld l, a ; again!
	; step 2: prepare DE
	ldh a, [rDIV] ; we need another rdiv value
	ld d, a ; store that into d
	ld a, [hl] ; read a byte from god-knows-where into a
	ld e, a ; write that into e
	; step 3: math to achieve final value
	add hl, de
	add a, l
	; step 4: pop off the stack and return
	pop de
	pop hl
	ret 

; borrowed from pokecrystal
; divides a by c; answer in b and remainder in a
simple_divide::
	ld b, 0 ; put 0 into b
.loop
	inc b ; add 1 to b
	sub c ; subtract c from a
	jr nc, .loop ; if there is not a carry set
	dec b ; decrase n
	add c ; add c to a
	ret


