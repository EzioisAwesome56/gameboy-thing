
; interupt setups go here
SECTION "RST 00 Crash Handler", rom0[$0000]
	call crash_handler
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
	; right away we backup the state of the registers a and bc on boot
	ld [wBootupVars], a ; first a
	ld  a, b ; put b into a
	ld [wBootupVars + 1], a ; then b
	ld a, c ; load c into a
	ld [wBootupVars + 2], a ; finally, c
	; resume normally initilization procedure
	; clear stack memory
	ld hl, StackBottom ; point hl at the bottom of stack memory
	xor a ; load 0 into a
	ld b, a ; put 0 into b
.loop
	ld a, b ; load b into a
	cp 200 ; is it 200?
	jr z, .done ; if it is, we have finished clearing stack memory
	xor a ; otherwise, put 0 into a
	ld [hl], a ; put 0 at address hl
	inc hl ; increment hl
	inc b ; increment our counter
	jr .loop
.done
	ld sp, StackTop ; init the stack pointer
	xor a
	ldh [hVBlank_counter], a
	ld [wVBlankFlags], a
	ld [wVBlankAction], a ; zero out vblank related flags
	ld [wTextboxDrawn], a ; set textbox flag to 0
	ld [wActionBuffer], a ; zero out the action buffer
	ld [wOverworldFlags], a ; zero out overworld flags as well
	call bankmanager_init ; now that call works, we can init the bankmanager via its own subroutine
	call  init_oamdma_hram ; copy OAM DMA routine into hram
	farcall clear_oam ; clear OAM Buffer in RAM
	ld hl, rLCDC ; point HL at the lcd control register
	set 4, [hl] ; set tthe tile data memory area to $8000
	res 3, [hl] ; set background tilemap area to be 9800-9bFF
	set 1, [hl] ; enable OBJs
	set 6, [hl] ; point window at $9c00
	; init intetrupts
	ld  hl, rIE ; first load interupt enable into hl
	set 0, [hl] ; enable vblank interupt
	ei ; enable interupts
	queuetiles fontlow, 26, 35 ; load lowercase font
	queuetiles num, 10, 66 ; load numbers into vram
	call queue_oamdma ; transfer the now-empty oamdma memory into OAM
	call start_intro_sequence ; do the intro sequence first
	call disable_lcd
	farcall obj_pal_1 ; load a palette into vram
	farcall background_pal ; also load background palette
	call enable_lcd ; turn the lcd back on
	queuetiles font, 26, 1 ; load uppercase font
	queuetiles arrow, 1, 61 ; load arrow graphic
	queuetiles textboxgfx, 8, 27 ; load the textbox gfx as well
	queuetiles punc, 4, 62 ; load punctuation
	queuetiles arrow_right, 1, $57 ; load right facing arrow into vram
	queuetiles forslash, 1, $58 ; load forward slash
	call vba_detection ; check if we are using very bad amulator
	farcall do_titlescreen ; run the title screen first
	; jump to our main loop
	farcall setup_test_data
	jp run_overworld

