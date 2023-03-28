SECTION "Non-essential routines", ROMX

charmap "@", $FF
; take string HL and rombank B and copies it into the StringBuffer
prepare_buffer::
    push hl ; backup hl as we will be using it for something else
    ld hl, sram_copy ; load address of copy routine into hl
    call mbc_copytosram ; copy it into sram
    pop hl ; pop source address off stack again
    ld a, b ; move rombank number into a
    ld de, sCodeBlock ; set destination execution address to sram
    call mbc3_enable_sram ; enable sram
    call bankswitch_exec ; switch banks and execute our code in sram
    call mbc3_disable_sram ; disable sram
    ret ; we're done, so leave


; code to be copied from ROM to SRAM
; does the actual copting of data from a rom bank
sram_copy:
    ld de, wStringBuffer ; load the address of the buffer into DE
.loop
    ld a, [hl] ; load character into a
    cp "@" ; is it our terminator?
    jr z, .done ; if yes, exit this loop
    ; otherwise, copy char into de
    ld [de], a
    inc hl ; inc source address
    inc de ; inc destination address
    jr .loop
.done
    ld [de], a ; a should still have the terminator so store it
    ret ; return from the function
    db $FE ; terminator half 1
    db $EF ; terminator half 2