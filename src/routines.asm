SECTION "Non-essential routines", ROMX

charmap "@", $FF
; take string HL and rombank B and copies it into the StringBuffer
prepare_buffer::
    push hl ; backup hl as we will be using it for something else
    ld hl, sram_copy ; load address of copy routine into hl
    call mbc_copytosram ; copy it into sram
    pop hl ; pop source address off stack again
    ; we need to set the desitnation address
    ld de, wStringBuffer
    ld a, d ; load high byte into a
    ld [wSramCopyDestination], a ; store it into ram
    ld a, e ; get low byte
    ld [wSramCopyDestination + 1], a ; store it into ram
    ld a, b ; move rombank number into a
    ld de, sCodeBlock ; set destination execution address to sram
    call mbc3_enable_sram ; enable sram
    call bankswitch_exec ; switch banks and execute our code in sram
    call mbc3_disable_sram ; disable sram
    ret ; we're done, so leave


; code to be copied from ROM to SRAM
; does the actual copting of data from a rom bank
sram_copy:
    ld a, [wSramCopyDestination] ; load high byte of destination into a
    ld d, a ; store it in d
    ld a, [wSramCopyDestination + 1] ; load low byte into sram
    ld e, a ; store it in e
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

; loads textbox text into the sram buffer
; loads from bank B at address HL
buffer_textbox_content::
    push hl ; backup HL
    ld hl, sram_copy ; load our copy routine into hl
    call mbc_copytosram ; copy it to sram
    pop hl ; pop hl off the stack
    ; setup destination address
    ld de, wLargeStringBuffer
    ld a, d ; get high byte of desitnation
    ld [wSramCopyDestination], a ; store it
    ld a, e ; get low byte
    ld [wSramCopyDestination + 1], a ; store it too
    ld de, sCodeBlock ; set execuation address
    ld a, b ; load rom bank address into a
    call mbc3_enable_sram ; open sram
    call bankswitch_exec ; switch banks and jump to de
    call mbc3_disable_sram ; once done, disable sram
    ret ; gtfo
