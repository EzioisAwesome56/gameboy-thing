section "BSD checksum engine", romx
; calculates checksum starting from HL of length b
calculate_checksum::
    push hl ; backup hl
    pop de ; oh wait move it to de instead
    xor a ; 0 into a
    ld h, a ; 0 into d
    ld l, a ; 0 into e
    ld c, a ; 0 into c
.loop
    ld a, c ; load c into a
    cp b ; are we done?
    ret z ; yeet
    push bc ; backup bc
    ld b, h
    ld c, l ; copy hl to bc
    ; step 1: shift HL right 1
    srl h ; shift h right logical
    rr l ; rotate l right thru carry
    ; step 2: AND a copy of the checksum with 1
    xor a
    inc a ; a is now one
    and b ; a = a & b
    ld b, a
    xor a
    inc a
    and c ; a = a & c
    ld c, a ; put the new c back into c
    ; step 3: shift BC left 15 times
    rr c ; rotate c right
    ld bc, 0 ; bc is now 0
    rr b ; rotate b right
    ; step 4: add BC to HL
    add hl, bc
    ; step 5: add next byte into the checksum
    ld a, [de] ; get next byte from de
    inc de ; move de forward
    call sixteenbit_addition ; add A to HL
    ; step 6: AND  hl with 0xFFFF
    ld a, $FF
    and h
    ld h, a
    ld a, $ff
    and l
    ld l, a
    ; back to regular shit
    pop bc ; restore our counter
    inc c ; add 1 to c
    jr .loop
    