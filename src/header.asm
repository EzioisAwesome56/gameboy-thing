
; interupt setups go here
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

EntryPoint:
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
	; load 1 into the action flag; this is for load font
	ld a, 1
	ld [wVBlankAction], a
	; also tell it to disable the LCD for it (and turn it back one when its done)
	inc a
	ld [wDisableLCD], a
	; enable interupts
	ei
	; wait for vblank to load the font
	halt
	; prepare a vblank strcopy
	; first set the string into hl
	ld hl, test_string
	; call our prep routine
	ld a, BANK(prepare_buffer)
	ld de, prepare_buffer
	call bankswitch_exec
	; set hl to be the start of tilemap
	ld hl, $9800
	; store it in the location it needs to go
	ld a, h
	ld [wStringDestHigh], a
	ld a, l
	ld [wStringDestLow], a
	; set vblank action to 2
	xor a
	inc a
	inc a
	ld [wVBlankAction], a



memes:
	halt
	jr memes

