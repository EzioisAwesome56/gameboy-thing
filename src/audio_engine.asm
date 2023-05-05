; Most of this file is from the GBT-Player project
; which can be found at this URL: https://github.com/AntonioND/gbt-player
; said project is licensed under the MIT license
; with a few minor changes
; - removed all checks for MBC5_512 banks
; - condensed gbt_player.asm, gbt_player_bank1.asm into one file
; - updated include statements to point at the correct files
; - changed RAM bank to x instead of 0
; - changed name of RAM Section
; - changed name of ROM sections
; - applied minor LDH optimizations as per assembler reccomendations
; - cleaned up spacing and shit

section "GBT Rom0 Extras", rom0
; handles updating and rombanking weirdness
; called from vblank
do_gbt_update::
    call bankmanager_push_current_bank ; push current bank onto the stack
    call gbt_update ; every frame, update our audio
    call bankswitch_return ; return to previous rombank
    ret ; yeet

section "GBT Additional Routines", romx
; does what it says on the tin
init_clear_gbt_ram::
    ld de, gbt_playing ; point de at the playing variable in memory
.loop
    ld a, d ; load high byte into a
    cp high(gbt_update_pattern_pointers) ; is d  equal to the high byte?
    jr z, .checklow
.resume
    xor a ; load  0 into a
    ld [de], a ; zero out the byte at de
    inc de ; move to next byte
    jr .loop
.checklow
    ld a, e ; low low byte into a
    cp low(gbt_update_pattern_pointers) ; is it ending address
    ret z ; yeet
    jr .resume ; otherwise keep going

;###############################################################################
;
; GBT Player v3.1.0
;
; SPDX-License-Identifier: MIT
;
; Copyright (c) 2009-2021, Antonio Niño Díaz <antonio_nd@outlook.com>
;
;###############################################################################

include "include/hardware.inc/hardware.inc"

;###############################################################################

SECTION "Gameboy Tracker RAM",WRAMX

;-------------------------------------------------------------------------------

gbt_playing: DS 1

; pointer to the pattern pointer array
gbt_pattern_array_ptr:  DS 2 ; LSB first
gbt_pattern_array_bank: DS 1

; playing speed
gbt_speed:: DS 1

; Up to 12 bytes per step are copied here to be handled in functions in bank 1
gbt_temp_play_data:: DS 12

gbt_loop_enabled:            DS 1
gbt_ticks_elapsed::          DS 1
gbt_current_step::           DS 1
gbt_current_pattern::        DS 1
gbt_current_step_data_ptr::  DS 2 ; pointer to next step data - LSB first
gbt_current_step_data_bank:: DS 1 ; bank of current pattern data

gbt_channels_enabled:: DS 1

gbt_pan::   DS 4*1 ; Ch 1-4
gbt_vol::   DS 4*1 ; Ch 1-4
gbt_instr:: DS 4*1 ; Ch 1-4
gbt_freq::  DS 3*2 ; Ch 1-3

gbt_channel3_loaded_instrument:: DS 1 ; current loaded instrument ($FF if none)

; Arpeggio -> Ch 1-3
gbt_arpeggio_freq_index:: DS 3*3 ; {base index, base index+x, base index+y} * 3
gbt_arpeggio_enabled::    DS 3*1 ; if 0, disabled
gbt_arpeggio_tick::       DS 3*1

; Cut note
gbt_cut_note_tick:: DS 4*1 ; If tick == gbt_cut_note_tick, stop note.

; Last step of last pattern this is set to 1
gbt_have_to_stop_next_step:: DS 1

gbt_update_pattern_pointers:: DS 1 ; set to 1 by jump effects

;###############################################################################

SECTION "Gameboy Tracker ROM0",ROM0

;-------------------------------------------------------------------------------

gbt_get_pattern_ptr:: ; a = pattern number

; loads a pointer to pattern a into gbt_current_step_data_ptr and
; gbt_current_step_data_bank

ld      e,a
ld      d,0

ld      a,[gbt_pattern_array_bank]
ld      [rROMB0],a ; MBC1, MBC3, MBC5 - Set bank

ld      hl,gbt_pattern_array_ptr
ld      a,[hl+]
ld      h,[hl]
ld      l,a

; hl = pointer to list of pointers
; de = pattern number

add     hl,de
add     hl,de
add     hl,de

; hl = pointer to pattern bank

ld      a,[hl+]
ld      [gbt_current_step_data_bank+0],a

; hl = pointer to pattern data

ld      a,[hl+]
ld      h,[hl]
ld      l,a

ld      a,l
ld      [gbt_current_step_data_ptr],a
ld      a,h
ld      [gbt_current_step_data_ptr+1],a

ret

;-------------------------------------------------------------------------------

gbt_get_pattern_ptr_banked:: ; a = pattern number

push    de
call    gbt_get_pattern_ptr
pop     de

ld      hl,gbt_current_step_data_ptr
ld      a,[hl+]
ld      b,a
ld      a,[hl]
or      a,b
jr      nz,.dont_loop
xor     a,a
ld      [gbt_current_pattern], a
.dont_loop:
ld      a,$01
ld      [$2000],a ; MBC1, MBC3, MBC5 - Set bank 1

ret

;-------------------------------------------------------------------------------

gbt_play:: ; de = data, bc = bank, a = speed

ld      hl,gbt_pattern_array_ptr
ld      [hl],e
inc     hl
ld      [hl],d

ld      [gbt_speed],a

ld      a,c
ld      [gbt_pattern_array_bank+0],a

ld      a,0
call    gbt_get_pattern_ptr

xor     a,a
ld      [gbt_current_step],a
ld      [gbt_current_pattern],a
ld      [gbt_ticks_elapsed],a
ld      [gbt_loop_enabled],a
ld      [gbt_have_to_stop_next_step],a
ld      [gbt_update_pattern_pointers],a

ld      a,$FF
ld      [gbt_channel3_loaded_instrument],a

ld      a,$0F
ld      [gbt_channels_enabled],a

ld      hl,gbt_pan
ld      a,$11 ; L and R
ld      [hl+],a
add     a,a
ld      [hl+],a
add     a,a
ld      [hl+],a
add     a,a
ld      [hl],a

ld      hl,gbt_vol
ld      a,$F0 ; 100%
ld      [hl+],a
ld      [hl+],a
ld      a,$20 ; 100%
ld      [hl+],a
ld      a,$F0 ; 100%
ld      [hl+],a

ld      a,0

ld      hl,gbt_instr
ld      [hl+],a
ld      [hl+],a
ld      [hl+],a
ld      [hl+],a

ld      hl,gbt_freq
ld      [hl+],a
ld      [hl+],a
ld      [hl+],a
ld      [hl+],a
ld      [hl+],a
ld      [hl+],a

ld      [gbt_arpeggio_enabled+0],a
ld      [gbt_arpeggio_enabled+1],a
ld      [gbt_arpeggio_enabled+2],a

ld      a,$FF
ld      [gbt_cut_note_tick+0],a
ld      [gbt_cut_note_tick+1],a
ld      [gbt_cut_note_tick+2],a
ld      [gbt_cut_note_tick+3],a

ld      a,$80
ldh      [rNR52],a
ld      a,$00
ldh      [rNR51],a
ld      a,$00 ; 0%
ldh      [rNR50],a

xor     a,a
ldh [rNR10],a
ldh [rNR11],a
ldh [rNR12],a
ldh [rNR13],a
ldh [rNR14],a
ldh [rNR21],a
ldh [rNR22],a
ldh [rNR23],a
ldh [rNR24],a
ldh [rNR30],a
ldh [rNR31],a
ldh [rNR32],a
ldh [rNR33],a
ldh [rNR34],a
ldh [rNR41],a
ldh [rNR42],a
ldh [rNR43],a
ldh [rNR44],a

ld      a,$77 ; 100%
ldh [rNR50],a

ld      a,$01
ld      [gbt_playing],a

ret

;-------------------------------------------------------------------------------

gbt_pause:: ; a = pause/unpause
ld      [gbt_playing],a
or      a,a
jr      nz,.gbt_pause_unmute

; Silence all channels
xor     a,a
ldh [rNR51],a

ret

.gbt_pause_unmute: ; Unmute sound if playback is resumed

; Restore panning status
ld      hl,gbt_pan
ld      a,[hl+]
or      a,[hl]
inc     hl
or      a,[hl]
inc     hl
or      a,[hl]
ldh [rNR51],a

ret

;-------------------------------------------------------------------------------

gbt_loop:: ; a = loop/don't loop
ld      [gbt_loop_enabled],a
ret

;-------------------------------------------------------------------------------

gbt_stop::
xor     a,a
ld      [gbt_playing],a
ld      [rNR50],a
ld      [rNR51],a
ld      [rNR52],a
ret

;-------------------------------------------------------------------------------

gbt_enable_channels:: ; a = channel flags (channel flag = (1<<(channel_num-1)))
ld      [gbt_channels_enabled],a
ret

;-------------------------------------------------------------------------------

EXPORT  gbt_update_bank1

gbt_update::

ld      a,[gbt_playing]
or      a,a
ret     z ; If not playing, return

; Handle tick counter

ld      hl,gbt_ticks_elapsed
ld      a,[gbt_speed] ; a = total ticks
ld      b,[hl] ; b = ticks elapsed
inc     b
ld      [hl],b
cp      a,b
jr      z,.dontexit

; Tick != Speed, update effects and exit
ld      a,$01
ld      [$2000],a ; MBC1, MBC3, MBC5 - Set bank 1
; Call update function in bank 1 (in gbt_player_bank1.s)
call    gbt_update_effects_bank1

ret

.dontexit:
ld      [hl],$00 ; reset tick counter

; Clear tick-based effects
; ------------------------

xor     a,a
ld      hl,gbt_arpeggio_enabled ; Disable arpeggio
ld      [hl+],a
ld      [hl+],a
ld      [hl],a
dec     a ; a = $FF
ld      hl,gbt_cut_note_tick ; Disable cut note
ld      [hl+],a
ld      [hl+],a
ld      [hl+],a
ld      [hl],a

; Update effects
; --------------
ld      a,$01
ld      [$2000],a ; MBC1, MBC3, MBC5 - Set bank 1
; Call update function in bank 1 (in gbt_player_bank1.s)
call    gbt_update_effects_bank1

; Check if last step
; ------------------

ld      a,[gbt_have_to_stop_next_step]
or      a,a
jr      z,.dont_stop

call    gbt_stop
ld      a,0
ld      [gbt_have_to_stop_next_step],a
ret

.dont_stop:

; Get this step data
; ------------------

; Change to bank with song data
ld      a,[gbt_current_step_data_bank]
ld      [$2000],a ; MBC1, MBC3, MBC5 - Set bank

; Get step data

ld      a,[gbt_current_step_data_ptr]
ld      l,a
ld      a,[gbt_current_step_data_ptr+1]
ld      h,a ; hl = pointer to data

ld      de,gbt_temp_play_data

ld      b,4
.copy_loop: ; copy as bytes as needed for this step

ld      a,[hl+]
ld      [de],a
inc     de
bit     7,a
jr      nz,.more_bytes
bit     6,a
jr      z,.no_more_bytes_this_channel

jr      .one_more_byte

.more_bytes:

ld      a,[hl+]
ld      [de],a
inc     de
bit     7,a
jr      z,.no_more_bytes_this_channel

.one_more_byte:

ld      a,[hl+]
ld      [de],a
inc     de

.no_more_bytes_this_channel:
dec     b
jr      nz,.copy_loop

ld      a,l
ld      [gbt_current_step_data_ptr],a
ld      a,h
ld      [gbt_current_step_data_ptr+1],a ; save pointer to data

; Increment step/pattern
; ----------------------

; Increment step

ld      a,[gbt_current_step]
inc     a
ld      [gbt_current_step],a
cp      a,64
jr      nz,.dont_increment_pattern

; Increment pattern

ld      a,0
ld      [gbt_current_step],a ; Step 0

ld      a,[gbt_current_pattern]
inc     a
ld      [gbt_current_pattern],a

call    gbt_get_pattern_ptr

ld      a,[gbt_current_step_data_ptr]
ld      b,a
ld      a,[gbt_current_step_data_ptr+1]
or      a,b
jr      nz,.not_ended ; if pointer is 0, song has ended

ld      a,[gbt_loop_enabled]
and     a,a

jr      z,.loop_disabled

; If loop is enabled, jump to pattern 0

ld      a,0
ld      [gbt_current_pattern],a

call    gbt_get_pattern_ptr

jr      .end_handling_steps_pattern

.loop_disabled:

; If loop is disabled, stop song
; Stop it next step, if not this step won't be played

ld      a,1
ld      [gbt_have_to_stop_next_step],a

.not_ended:

.dont_increment_pattern:

.end_handling_steps_pattern:
ld      a,$01
ld      [$2000],a ; MBC1, MBC3, MBC5 - Set bank 1
; Call update function in bank 1 (in gbt_player_bank1.s)
call    gbt_update_bank1

; Check if any effect has changed the pattern or step

ld      a,[gbt_update_pattern_pointers]
and     a,a
ret     z
; if any effect has changed the pattern or step, update

xor     a,a
ld      [gbt_update_pattern_pointers],a ; clear update flag

ld      [gbt_have_to_stop_next_step],a ; clear stop flag

ld      a,[gbt_current_pattern]
call    gbt_get_pattern_ptr ; set ptr to start of the pattern

; Search the step

; Change to bank with song data
ld      a,[gbt_pattern_array_bank+0]
ld      [$2000],a ; MBC1, MBC3, MBC5

ld      a,[gbt_current_step_data_ptr]
ld      l,a
ld      a,[gbt_current_step_data_ptr+1]
ld      h,a ; hl = pointer to data

ld      a,[gbt_current_step]
and     a,a
ret     z ; if changing to step 0, exit

add     a,a
add     a,a
ld      b,a ; b = iterations = step * 4 (number of channels)
.next_channel:

ld      a,[hl+]
bit     7,a
jr      nz,.next_channel_more_bytes
bit     6,a
jr      z,.next_channel_no_more_bytes_this_channel

jr      .next_channel_one_more_byte

.next_channel_more_bytes:

ld      a,[hl+]
bit     7,a
jr      z,.next_channel_no_more_bytes_this_channel

.next_channel_one_more_byte:

ld      a,[hl+]

.next_channel_no_more_bytes_this_channel:
dec     b
jr      nz,.next_channel

ld      a,l
ld      [gbt_current_step_data_ptr],a
ld      a,h
ld      [gbt_current_step_data_ptr+1],a ; save pointer to data

ret

SECTION "Gameboy Tracker Rombank 1 code",ROMX,BANK[1]

gbt_wave: ; 8 sounds
DB $A5,$D7,$C9,$E1,$BC,$9A,$76,$31,$0C,$BA,$DE,$60,$1B,$CA,$03,$93 ; random
DB $F0,$E1,$D2,$C3,$B4,$A5,$96,$87,$78,$69,$5A,$4B,$3C,$2D,$1E,$0F
DB $FD,$EC,$DB,$CA,$B9,$A8,$97,$86,$79,$68,$57,$46,$35,$24,$13,$02 ; up-downs
DB $DE,$FE,$DC,$BA,$9A,$A9,$87,$77,$88,$87,$65,$56,$54,$32,$10,$12
DB $AB,$CD,$EF,$ED,$CB,$A0,$12,$3E,$DC,$BA,$BC,$DE,$FE,$DC,$32,$10 ; tri. broken
DB $FF,$EE,$DD,$CC,$BB,$AA,$99,$88,$77,$66,$55,$44,$33,$22,$11,$00 ; triangular
DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00 ; square
DB $79,$BC,$DE,$EF,$FF,$EE,$DC,$B9,$75,$43,$21,$10,$00,$11,$23,$45 ; sine

gbt_noise: ; 16 sounds
    ; 7 bit
    DB  $5F,$5B,$4B,$2F,$3B,$58,$1F,$0F
    ; 15 bit
    DB  $90,$80,$70,$50,$00
    DB  $67,$63,$53

gbt_frequencies:
    DW    44,  156,  262,  363,  457,  547,  631,  710,  786,  854,  923,  986
    DW  1046, 1102, 1155, 1205, 1253, 1297, 1339, 1379, 1417, 1452, 1486, 1517
    DW  1546, 1575, 1602, 1627, 1650, 1673, 1694, 1714, 1732, 1750, 1767, 1783
    DW  1798, 1812, 1825, 1837, 1849, 1860, 1871, 1881, 1890, 1899, 1907, 1915
    DW  1923, 1930, 1936, 1943, 1949, 1954, 1959, 1964, 1969, 1974, 1978, 1982
    DW  1985, 1988, 1992, 1995, 1998, 2001, 2004, 2006, 2009, 2011, 2013, 2015

;-------------------------------------------------------------------------------

_gbt_get_freq_from_index: ; a = index, bc = returned freq
    ld      hl,gbt_frequencies
    ld      c,a
    ld      b,$00
    add     hl,bc
    add     hl,bc
    ld      c,[hl]
    inc     hl
    ld      b,[hl]
    ret

;-------------------------------------------------------------------------------
; ---------------------------------- Channel 1 ---------------------------------
;-------------------------------------------------------------------------------

gbt_channel_1_handle:: ; de = info

    ld      a,[gbt_channels_enabled]
    and     a,$01
    jr      nz,.channel1_enabled

    ; Channel is disabled. Increment pointer as needed

    ld      a,[de]
    inc     de
    bit     7,a
    jr      nz,.more_bytes
    bit     6,a
    jr      z,.no_more_bytes_this_channel

    jr      .one_more_byte

.more_bytes:

    ld      a,[de]
    inc     de
    bit     7,a
    jr      z,.no_more_bytes_this_channel

.one_more_byte:

    inc     de

.no_more_bytes_this_channel:

    ret

.channel1_enabled:

    ; Channel 1 is enabled

    ld      a,[de]
    inc     de

    bit     7,a
    jr      nz,.has_frequency

    ; Not frequency

    bit     6,a
    jr      nz,.instr_effects

    ; Set volume or NOP

    bit     5,a
    jr      nz,.just_set_volume

    ; NOP

    ret

.just_set_volume:

    ; Set volume

    and     a,$0F
    swap    a
    ld      [gbt_vol+0],a

    jr      .refresh_channel1_regs

.instr_effects:

    ; Set instrument and effect

    ld      b,a ; save byte

    and     a,$30
    add     a,a
    add     a,a
    ld      [gbt_instr+0],a ; Instrument

    ld      a,b ; restore byte

    and     a,$0F ; a = effect

    call    gbt_channel_1_set_effect

    jr      .refresh_channel1_regs

.has_frequency:

    ; Has frequency

    and     a,$7F
    ld      [gbt_arpeggio_freq_index+0*3],a
    ; This destroys hl and     a. Returns freq in bc
    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+0*2+0],a
    ld      a,b
    ld      [gbt_freq+0*2+1],a ; Get frequency

    ld      a,[de]
    inc     de

    bit     7,a
    jr      nz,.freq_instr_and_effect

    ; Freq + Instr + Volume

    ld      b,a ; save byte

    and     a,$30
    add     a,a
    add     a,a
    ld      [gbt_instr+0],a ; Instrument

    ld      a,b ; restore byte

    and     a,$0F ; a = volume

    swap    a
    ld      [gbt_vol+0],a

    jr      .refresh_channel1_regs

.freq_instr_and_effect:

    ; Freq + Instr + Effect

    ld      b,a ; save byte

    and     a,$30
    add     a,a
    add     a,a
    ld      [gbt_instr+0],a ; Instrument

    ld      a,b ; restore byte

    and     a,$0F ; a = effect

    call    gbt_channel_1_set_effect

    ;jr      .refresh_channel1_regs

.refresh_channel1_regs:

    ; fall through!!!!!

; -----------------

channel1_refresh_registers:

    xor     a,a
    ld      [rNR10],a
    ld      a,[gbt_instr+0]
    ld      [rNR11],a
    ld      a,[gbt_vol+0]
    ld      [rNR12],a
    ld      a,[gbt_freq+0*2+0]
    ld      [rNR13],a
    ld      a,[gbt_freq+0*2+1]
    or      a,$80 ; start
    ld      [rNR14],a

    ret

; ------------------

channel1_update_effects: ; returns 1 in a if it needed to update sound registers

    ; Cut note
    ; --------

    ld      a,[gbt_cut_note_tick+0]
    ld      hl,gbt_ticks_elapsed
    cp      a,[hl]
    jp      nz,.dont_cut

    dec     a ; a = $FF
    ld      [gbt_cut_note_tick+0],a ; disable cut note

    xor     a,a ; vol = 0
    ld      [rNR12],a
    ld      a,$80 ; start
    ld      [rNR14],a

.dont_cut:

    ; Arpeggio
    ; --------

    ld      a,[gbt_arpeggio_enabled+0]
    and     a,a
    ret     z ; a is 0, return 0

    ; If enabled arpeggio, handle it

    ld      a,[gbt_arpeggio_tick+0]
    and     a,a
    jr      nz,.not_tick_0

    ; Tick 0 - Set original frequency

    ld      a,[gbt_arpeggio_freq_index+0*3+0]

    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+0*2+0],a
    ld      a,b
    ld      [gbt_freq+0*2+1],a ; Set frequency

    ld      a,1
    ld      [gbt_arpeggio_tick+0],a

    ret ; ret 1

.not_tick_0:

    cp      a,1
    jr      nz,.not_tick_1

    ; Tick 1

    ld      a,[gbt_arpeggio_freq_index+0*3+1]

    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+0*2+0],a
    ld      a,b
    ld      [gbt_freq+0*2+1],a ; Set frequency

    ld      a,2
    ld      [gbt_arpeggio_tick+0],a

    dec     a
    ret ; ret 1

.not_tick_1:

    ; Tick 2

    ld      a,[gbt_arpeggio_freq_index+0*3+2]

    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+0*2+0],a
    ld      a,b
    ld      [gbt_freq+0*2+1],a ; Set frequency

    xor     a,a
    ld      [gbt_arpeggio_tick+0],a

    inc     a ; ret 1
    ret

; -----------------

; returns a = 1 if needed to update registers, 0 if not
gbt_channel_1_set_effect: ; a = effect, de = pointer to data.

    ld      hl,.gbt_ch1_jump_table
    ld      c,a
    ld      b,0
    add     hl,bc
    add     hl,bc

    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ld      a,[de] ; load args
    inc     de

    jp      hl

.gbt_ch1_jump_table:
    DW  .gbt_ch1_pan
    DW  .gbt_ch1_arpeggio
    DW  .gbt_ch1_cut_note
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_jump_pattern
    DW  gbt_ch1234_jump_position
    DW  gbt_ch1234_speed
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop

.gbt_ch1_pan:
    and     a,$11
    ld      [gbt_pan+0],a
    xor     a,a
    ret ; ret 0 do not update registers, only NR51 at end.

.gbt_ch1_arpeggio:
    ld      b,a ; b = params

    ld      hl,gbt_arpeggio_freq_index+0*3
    ld      c,[hl] ; c = base index
    inc     hl

    ld      a,b
    swap    a
    and     a,$0F
    add     a,c

    ld      [hl+],a ; save first increment

    ld      a,b
    and     a,$0F
    add     a,c

    ld      [hl],a ; save second increment

    ld      a,1
    ld      [gbt_arpeggio_enabled+0],a
    ld      [gbt_arpeggio_tick+0],a

    ret ; ret 1

.gbt_ch1_cut_note:
    ld      [gbt_cut_note_tick+0],a
    xor     a,a ; ret 0
    ret

;-------------------------------------------------------------------------------
; ---------------------------------- Channel 2 ---------------------------------
;-------------------------------------------------------------------------------

gbt_channel_2_handle:: ; de = info

    ld      a,[gbt_channels_enabled]
    and     a,$02
    jr      nz,.channel2_enabled

    ; Channel is disabled. Increment pointer as needed

    ld      a,[de]
    inc     de
    bit     7,a
    jr      nz,.more_bytes
    bit     6,a
    jr      z,.no_more_bytes_this_channel

    jr      .one_more_byte

.more_bytes:

    ld      a,[de]
    inc     de
    bit     7,a
    jr      z,.no_more_bytes_this_channel

.one_more_byte:

    inc     de

.no_more_bytes_this_channel:

    ret

.channel2_enabled:

    ; Channel 2 is enabled

    ld      a,[de]
    inc     de

    bit     7,a
    jr      nz,.has_frequency

    ; Not frequency

    bit     6,a
    jr      nz,.instr_effects

    ; Set volume or NOP

    bit     5,a
    jr      nz,.just_set_volume

    ; NOP

    ret

.just_set_volume:

    ; Set volume

    and     a,$0F
    swap    a
    ld      [gbt_vol+1],a

    jr      .refresh_channel2_regs

.instr_effects:

    ; Set instrument and effect

    ld      b,a ; save byte

    and     a,$30
    add     a,a
    add     a,a
    ld      [gbt_instr+1],a ; Instrument

    ld      a,b ; restore byte

    and     a,$0F ; a = effect

    call    gbt_channel_2_set_effect

    jr      .refresh_channel2_regs

.has_frequency:

    ; Has frequency

    and     a,$7F
    ld      [gbt_arpeggio_freq_index+1*3],a
    ; This destroys hl and a. Returns freq in bc
    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+1*2+0],a
    ld      a,b
    ld      [gbt_freq+1*2+1],a ; Get frequency

    ld      a,[de]
    inc     de

    bit     7,a
    jr      nz,.freq_instr_and_effect

    ; Freq + Instr + Volume

    ld      b,a ; save byte

    and     a,$30
    add     a,a
    add     a,a
    ld      [gbt_instr+1],a ; Instrument

    ld      a,b ; restore byte

    and     a,$0F ; a = volume

    swap    a
    ld      [gbt_vol+1],a

    jr      .refresh_channel2_regs

.freq_instr_and_effect:

    ; Freq + Instr + Effect

    ld      b,a ; save byte

    and     a,$30
    add     a,a
    add     a,a
    ld      [gbt_instr+1],a ; Instrument

    ld      a,b ; restore byte

    and     a,$0F ; a = effect

    call    gbt_channel_2_set_effect

    ;jr      .refresh_channel2_regs

.refresh_channel2_regs:

    ; fall through!!!!!

; -----------------

channel2_refresh_registers:

    ld      a,[gbt_instr+1]
    ld      [rNR21],a
    ld      a,[gbt_vol+1]
    ld      [rNR22],a
    ld      a,[gbt_freq+1*2+0]
    ld      [rNR23],a
    ld      a,[gbt_freq+1*2+1]
    or      a,$80 ; start
    ld      [rNR24],a

    ret

; ------------------

channel2_update_effects: ; returns 1 in a if it needed to update sound registers

    ; Cut note
    ; --------

    ld      a,[gbt_cut_note_tick+1]
    ld      hl,gbt_ticks_elapsed
    cp      a,[hl]
    jp      nz,.dont_cut

    dec     a ; a = $FF
    ld      [gbt_cut_note_tick+1],a ; disable cut note

    xor     a,a ; vol = 0
    ld      [rNR22],a
    ld      a,$80 ; start
    ld      [rNR24],a

.dont_cut:

    ; Arpeggio
    ; --------

    ld      a,[gbt_arpeggio_enabled+1]
    and     a,a
    ret     z ; a is 0, return 0

    ; If enabled arpeggio, handle it

    ld      a,[gbt_arpeggio_tick+1]
    and     a,a
    jr      nz,.not_tick_0

    ; Tick 0 - Set original frequency

    ld      a,[gbt_arpeggio_freq_index+1*3+0]

    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+1*2+0],a
    ld      a,b
    ld      [gbt_freq+1*2+1],a ; Set frequency

    ld      a,1
    ld      [gbt_arpeggio_tick+1],a

    ret ; ret 1

.not_tick_0:

    cp      a,1
    jr      nz,.not_tick_1

    ; Tick 1

    ld      a,[gbt_arpeggio_freq_index+1*3+1]

    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+1*2+0],a
    ld      a,b
    ld      [gbt_freq+1*2+1],a ; Set frequency

    ld      a,2
    ld      [gbt_arpeggio_tick+1],a

    dec     a
    ret ; ret 1

.not_tick_1:

    ; Tick 2

    ld      a,[gbt_arpeggio_freq_index+1*3+2]

    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+1*2+0],a
    ld      a,b
    ld      [gbt_freq+1*2+1],a ; Set frequency

    xor     a,a
    ld      [gbt_arpeggio_tick+1],a

    inc     a ; ret 1
    ret

; -----------------

; returns a = 1 if needed to update registers, 0 if not
gbt_channel_2_set_effect: ; a = effect, de = pointer to data

    ld      hl,.gbt_ch2_jump_table
    ld      c,a
    ld      b,0
    add     hl,bc
    add     hl,bc

    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ld      a,[de] ; load args
    inc     de

    jp      hl

.gbt_ch2_jump_table:
    DW  .gbt_ch2_pan
    DW  .gbt_ch2_arpeggio
    DW  .gbt_ch2_cut_note
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_jump_pattern
    DW  gbt_ch1234_jump_position
    DW  gbt_ch1234_speed
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop

.gbt_ch2_pan:
    and     a,$22
    ld      [gbt_pan+1],a
    xor     a,a
    ret ; ret 0 do not update registers, only NR51 at end.

.gbt_ch2_arpeggio:
    ld      b,a ; b = params

    ld      hl,gbt_arpeggio_freq_index+1*3
    ld      c,[hl] ; c = base index
    inc     hl

    ld      a,b
    swap    a
    and     a,$0F
    add     a,c

    ld      [hl+],a ; save first increment

    ld      a,b
    and     a,$0F
    add     a,c

    ld      [hl],a ; save second increment

    ld      a,1
    ld      [gbt_arpeggio_enabled+1],a
    ld      [gbt_arpeggio_tick+1],a

    ret ; ret 1

.gbt_ch2_cut_note:
    ld      [gbt_cut_note_tick+1],a
    xor     a,a ; ret 0
    ret

;-------------------------------------------------------------------------------
; ---------------------------------- Channel 3 ---------------------------------
;-------------------------------------------------------------------------------

gbt_channel_3_handle:: ; de = info

    ld      a,[gbt_channels_enabled]
    and     a,$04
    jr      nz,.channel3_enabled

    ; Channel is disabled. Increment pointer as needed

    ld      a,[de]
    inc     de
    bit     7,a
    jr      nz,.more_bytes
    bit     6,a
    jr      z,.no_more_bytes_this_channel

    jr      .one_more_byte

.more_bytes:

    ld      a,[de]
    inc     de
    bit     7,a
    jr      z,.no_more_bytes_this_channel

.one_more_byte:

    inc     de

.no_more_bytes_this_channel:

    ret

.channel3_enabled:

    ; Channel 3 is enabled

    ld      a,[de]
    inc     de

    bit     7,a
    jr      nz,.has_frequency

    ; Not frequency

    bit     6,a
    jr      nz,.effects

    ; Set volume or NOP

    bit     5,a
    jr      nz,.just_set_volume

    ; NOP

    ret

.just_set_volume:

    ; Set volume

    and     a,$0F
    swap    a
    ld      [gbt_vol+2],a

    jr      .refresh_channel3_regs

.effects:

    ; Set effect

    and     a,$0F ; a = effect

    call    gbt_channel_3_set_effect
    and     a,a
    ret     z ; if 0, don't refresh registers

    jr      .refresh_channel3_regs

.has_frequency:

    ; Has frequency

    and     a,$7F
    ld      [gbt_arpeggio_freq_index+2*3],a
    ; This destroys hl and     a. Returns freq in bc
    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+2*2+0],a
    ld      a,b
    ld      [gbt_freq+2*2+1],a ; Get frequency

    ld      a,[de]
    inc     de

    bit     7,a
    jr      nz,.freq_instr_and_effect

    ; Freq + Instr + Volume

    ld      b,a ; save byte

    and     a,$0F
    ld      [gbt_instr+2],a ; Instrument

    ld      a,b ; restore byte

    and     a,$30 ; a = volume
    add     a,a
    ld      [gbt_vol+2],a

    jr      .refresh_channel3_regs

.freq_instr_and_effect:

    ; Freq + Instr + Effect

    ld      b,a ; save byte

    and     a,$0F
    ld      [gbt_instr+2],a ; Instrument

    ld      a,b ; restore byte

    and     a,$70
    swap    a    ; a = effect (only 0-7 allowed here)

    call    gbt_channel_3_set_effect

    ;jr      .refresh_channel3_regs

.refresh_channel3_regs:

    ; fall through!!!!!

; -----------------

channel3_refresh_registers:

    xor     a,a
    ld      [rNR30],a ; disable

    ld      a,[gbt_channel3_loaded_instrument]
    ld      b,a
    ld      a,[gbt_instr+2]
    cp      a,b
    call    nz,gbt_channel3_load_instrument ; a = instrument

    ld      a,$80
    ld      [rNR30],a ; enable

    xor     a,a
    ld      [rNR31],a
    ld      a,[gbt_vol+2]
    ld      [rNR32],a
    ld      a,[gbt_freq+2*2+0]
    ld      [rNR33],a
    ld      a,[gbt_freq+2*2+1]
    or      a,$80 ; start
    ld      [rNR34],a

    ret

; ------------------

gbt_channel3_load_instrument:

    ld      [gbt_channel3_loaded_instrument],a

    swap    a ; a = a * 16
    ld      c,a
    ld      b,0
    ld      hl,gbt_wave
    add     hl,bc

    ld      c,$30
    ld      b,16
.loop:
    ld      a,[hl+]
    ld      [$FF00+c],a
    inc     c
    dec     b
    jr      nz,.loop

    ret

; ------------------

channel3_update_effects: ; returns 1 in a if it needed to update sound registers

    ; Cut note
    ; --------

    ld      a,[gbt_cut_note_tick+2]
    ld      hl,gbt_ticks_elapsed
    cp      a,[hl]
    jp      nz,.dont_cut

    dec     a ; a = $FF
    ld      [gbt_cut_note_tick+2],a ; disable cut note

    ld      a,$80
    ld      [rNR30],a ; enable

    xor     a,a ; vol = 0
    ld      [rNR32],a
    ld      a,$80 ; start
    ld      [rNR34],a

.dont_cut:

    ; Arpeggio
    ; --------

    ld      a,[gbt_arpeggio_enabled+2]
    and     a,a
    ret     z ; a is 0, return 0

    ; If enabled arpeggio, handle it

    ld      a,[gbt_arpeggio_tick+2]
    and     a,a
    jr      nz,.not_tick_0

    ; Tick 0 - Set original frequency

    ld      a,[gbt_arpeggio_freq_index+2*3+0]

    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+2*2+0],a
    ld      a,b
    ld      [gbt_freq+2*2+1],a ; Set frequency

    ld      a,1
    ld      [gbt_arpeggio_tick+2],a

    ret ; ret 1

.not_tick_0:

    cp      a,1
    jr      nz,.not_tick_1

    ; Tick 1

    ld      a,[gbt_arpeggio_freq_index+2*3+1]

    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+2*2+0],a
    ld      a,b
    ld      [gbt_freq+2*2+1],a ; Set frequency

    ld      a,2
    ld      [gbt_arpeggio_tick+2],a

    dec     a
    ret ; ret 1

.not_tick_1:

    ; Tick 2

    ld      a,[gbt_arpeggio_freq_index+2*3+2]

    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+2*2+0],a
    ld      a,b
    ld      [gbt_freq+2*2+1],a ; Set frequency

    xor     a,a
    ld      [gbt_arpeggio_tick+2],a

    inc     a
    ret ; ret 1

; -----------------

; returns a = 1 if needed to update registers, 0 if not
gbt_channel_3_set_effect: ; a = effect, de = pointer to data

    ld      hl,.gbt_ch3_jump_table
    ld      c,a
    ld      b,0
    add     hl,bc
    add     hl,bc

    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ld      a,[de] ; load args
    inc     de

    jp      hl

.gbt_ch3_jump_table:
    DW  .gbt_ch3_pan
    DW  .gbt_ch3_arpeggio
    DW  .gbt_ch3_cut_note
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_jump_pattern
    DW  gbt_ch1234_jump_position
    DW  gbt_ch1234_speed
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop

.gbt_ch3_pan:
    and     a,$44
    ld      [gbt_pan+2],a
    xor     a,a
    ret ; ret 0 do not update registers, only NR51 at end.

.gbt_ch3_arpeggio:
    ld      b,a ; b = params

    ld      hl,gbt_arpeggio_freq_index+2*3
    ld      c,[hl] ; c = base index
    inc     hl

    ld      a,b
    swap    a
    and     a,$0F
    add     a,c

    ld      [hl+],a ; save first increment

    ld      a,b
    and     a,$0F
    add     a,c

    ld      [hl],a ; save second increment

    ld      a,1
    ld      [gbt_arpeggio_enabled+2],a
    ld      [gbt_arpeggio_tick+2],a

    ret ; ret 1

.gbt_ch3_cut_note:
    ld      [gbt_cut_note_tick+2],a
    xor     a,a ; ret 0
    ret

;-------------------------------------------------------------------------------
; ---------------------------------- Channel 4 ---------------------------------
;-------------------------------------------------------------------------------

gbt_channel_4_handle:: ; de = info

    ld      a,[gbt_channels_enabled]
    and     a,$08
    jr      nz,.channel4_enabled

    ; Channel is disabled. Increment pointer as needed

    ld      a,[de]
    inc     de
    bit     7,a
    jr      nz,.more_bytes
    bit     6,a
    jr      z,.no_more_bytes_this_channel

    jr      .one_more_byte

.more_bytes:

    ld      a,[de]
    inc     de
    bit     7,a
    jr      z,.no_more_bytes_this_channel

.one_more_byte:

    inc     de

.no_more_bytes_this_channel:

    ret

.channel4_enabled:

    ; Channel 4 is enabled

    ld      a,[de]
    inc     de

    bit     7,a
    jr      nz,.has_instrument

    ; Not instrument

    bit     6,a
    jr      nz,.effects

    ; Set volume or NOP

    bit     5,a
    jr      nz,.just_set_volume

    ; NOP

    ret

.just_set_volume:

    ; Set volume

    and     a,$0F
    swap    a
    ld      [gbt_vol+3],a

    jr      .refresh_channel4_regs

.effects:

    ; Set effect

    and     a,$0F ; a = effect

    call    gbt_channel_4_set_effect
    and     a,a
    ret     z ; if 0, don't refresh registers

    jr      .refresh_channel4_regs

.has_instrument:

    ; Has instrument

    and     a,$0F
    ld      hl,gbt_noise
    ld      c,a
    ld      b,0
    add     hl,bc
    ld      a,[hl] ; a = instrument data

    ld      [gbt_instr+3],a

    ld      a,[de]
    inc     de

    bit     7,a
    jr      nz,.instr_and_effect

    ; Instr + Volume

    and     a,$0F ; a = volume

    swap    a
    ld      [gbt_vol+3],a

    jr      .refresh_channel4_regs

.instr_and_effect:

    ; Instr + Effect

    and     a,$0F ; a = effect

    call    gbt_channel_4_set_effect

    ;jr      .refresh_channel4_regs

.refresh_channel4_regs:

    ; fall through!!!!!

; -----------------

channel4_refresh_registers:

    xor     a,a
    ld      [rNR41],a
    ld      a,[gbt_vol+3]
    ld      [rNR42],a
    ld      a,[gbt_instr+3]
    ld      [rNR43],a
    ld      a,$80 ; start
    ld      [rNR44],a

    ret

; ------------------

channel4_update_effects: ; returns 1 in a if it needed to update sound registers

    ; Cut note
    ; --------

    ld      a,[gbt_cut_note_tick+3]
    ld      hl,gbt_ticks_elapsed
    cp      a,[hl]
    jp      nz,.dont_cut

    dec     a ; a = $FF
    ld      [gbt_cut_note_tick+3],a ; disable cut note

    xor     a,a ; vol = 0
    ld      [rNR42],a
    ld      a,$80 ; start
    ld      [rNR44],a

.dont_cut:

    xor     a,a
    ret ; a is 0, return 0

; -----------------

; returns a = 1 if needed to update registers, 0 if not
gbt_channel_4_set_effect: ; a = effect, de = pointer to data

    ld      hl,.gbt_ch4_jump_table
    ld      c,a
    ld      b,0
    add     hl,bc
    add     hl,bc

    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ld      a,[de] ; load args
    inc     de

    jp      hl

.gbt_ch4_jump_table:
    DW  .gbt_ch4_pan
    DW  gbt_ch1234_nop ; gbt_ch4_arpeggio
    DW  .gbt_ch4_cut_note
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_jump_pattern
    DW  gbt_ch1234_jump_position
    DW  gbt_ch1234_speed
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop
    DW  gbt_ch1234_nop

.gbt_ch4_pan:
    and     a,$88
    ld      [gbt_pan+3],a
    xor     a,a
    ret ; ret 0 do not update registers, only NR51 at end.

.gbt_ch4_cut_note:
    ld      [gbt_cut_note_tick+3],a
    xor     a,a ; ret 0
    ret

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------

; Common effects go here:

gbt_ch1234_nop:
    xor     a,a ;ret 0
    ret

gbt_ch1234_jump_pattern:
    ld      [gbt_current_pattern],a
    xor     a,a
    ld      [gbt_current_step],a
    ld      [gbt_have_to_stop_next_step],a ; clear stop flag
    ld      a,1
    ld      [gbt_update_pattern_pointers],a
    xor     a,a ;ret 0
    ret

gbt_ch1234_jump_position:
    ld      [gbt_current_step],a
    ld      hl,gbt_current_pattern
    inc     [hl]

    ; Check to see if jump puts us past end of song
    ld      a,[hl]
    call    gbt_get_pattern_ptr_banked
    ld      a,1
    ld      [gbt_update_pattern_pointers],a
    xor     a,a ;ret 0
    ret

gbt_ch1234_speed:
    ld      [gbt_speed],a
    xor     a,a
    ld      [gbt_ticks_elapsed],a
    ret ;ret 0

;-------------------------------------------------------------------------------

gbt_update_bank1::

    ld      de,gbt_temp_play_data

    ; each function will return in de the pointer to next byte

    call    gbt_channel_1_handle

    call    gbt_channel_2_handle

    call    gbt_channel_3_handle

    call    gbt_channel_4_handle

    ; end of channel handling

    ld      hl,gbt_pan
    ld      a,[hl+]
    or      a,[hl]
    inc     hl
    or      a,[hl]
    inc     hl
    or      a,[hl]
    ld      [rNR51],a ; handle panning...

    ret

;-------------------------------------------------------------------------------

gbt_update_effects_bank1::

    call    channel1_update_effects
    and     a,a
    call    nz,channel1_refresh_registers

    call    channel2_update_effects
    and     a,a
    call    nz,channel2_refresh_registers

    call    channel3_update_effects
    and     a,a
    call    nz,channel3_refresh_registers

    call    channel4_update_effects
    and     a,a
    call    nz,channel4_refresh_registers

    ret

;###############################################################################