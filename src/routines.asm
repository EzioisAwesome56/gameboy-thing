SECTION "Non-essential routines", ROMX, BANK[2]

charmap "@", $FF
; take string from hl and copy it to the string buffer
prepare_buffer::
    ; backup de since we will be using it
    push af
    push de
    ; set de to the string buffer location
    ld de, wStringBuffer
.loop
    ; load current character from hl
    ld a, [hl]
    cp "@" ; is it @?
    jr z, .done ; if yes, we're done copying the string lol
    ; otherwise, copy the current byte
    ld [de], a
    ; increment de and hl
    inc hl
    inc de
    ; loop again
    jr .loop
.done
    ; write the @ to de too because we need it
    ld [de], a
    ; pop shit off the stack
    pop de
    pop af
    ; return
    ret 
