
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
	call start_intro_sequence ; do the intro sequence first
	call disable_lcd
	farcall obj_pal_1 ; load a palette into vram
	farcall background_pal ; also load background palette
	call enable_lcd ; turn the lcd back on
	call queue_oamdma ; transfer the now-empty oamdma memory into OAM
	queuetiles font, 26, 1 ; load uppercase font
	queuetiles arrow, 1, 61 ; load arrow graphic
	queuetiles textboxgfx, 8, 27 ; load the textbox gfx as well
	queuetiles punc, 4, 62 ; load punctuation
	queuetiles num, 10, 66 ; load numbers into vram
	call vba_detection ; check if we are using very bad amulator
	; jump to our main loop
	jp run_overworld

section "ROM0 Init Routines", rom0
start_intro_sequence:
	farcall do_intro_screen
	ret ; leave lol

section "Rom 0 short routines", rom0
; queues up a LCD disable
disable_lcd::
	push hl ; backup hl
	ld hl, wVBlankFlags ; point hl at our flags byte
	set 2, [hl] ; set bit 2
	halt ; wait for vblank to do the do
	pop hl ; retore hl
	ret ; leave

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
	ld b, 0 ; load 0 into b
.loop
	inc b ; increment b
	sub c ; subtract c from a
	jr nc, .loop ; if not 0, loop more
	dec b ; decrement b
	add c ; add c to a
	ret

; queues tiles to be loaded by vblank 
queue_tiles::
	; first, we have to preform a rombank switch
	ld a, [wTileBank] ; get the bank of our tile
	call bankmanager_switch ; switch to rombank a
	halt ; wait for vblank to go do the thing
	; vblank code goes here
	xor a
    set 2, a ; disable lcd
    set 3, a ; re-enable lcd once done
    ld [wVBlankFlags], a ; tell vblank to turn off LCD but turn it back on when its done
    xor a
    inc a
    ld [wVBlankAction], a ; tell vblank to load tiles
	halt ; wait for vblank to finish
	call bankswitch_return ; switch back to previous bank
	ret ; we're done here lol

; queues a OAMDMA transfer
queue_oamdma::
	push hl ; backup hl
	ld hl, wVBlankFlags ; point hl at our flags
    set 4, [hl] ; bit 4 is oam dma transfer
    halt ; wait
	pop hl ; pop hl off the stack
	ret ; return to caller function

def joypad equ $FF00
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
