SECTION "ROM Bank Manager", rom0


def MBC3_rombank EQU $2000

; takes bank # in a and dest address in de
; does not trash bc or hl
bankswitch_exec::
    ; backup af and de
    push af
    push de
    ld de, wBankStack ; load the address of the bank stack into de
    ld a, [wBankPointer] ; load the pointer into a
    push bc ; backup bc
    push af ; backup our newly loaded a value
    ; zero out b
    xor a
    ld b, a
    pop af ; restore our a value
    ld c, a ; and load it into c
    ; backup HL, move DE to it
    push hl
    push de
    pop hl
    add hl, bc ; add hl and bc together; this gets the current open stack spot
    ; move hl to de, restore HL
    push hl
    pop de
    pop hl
    pop bc ; pop bc back off the stack
    ; we need to store the current rombank on the stack now
    ld a, [hCurrentBank] ; load said current bank value
    ld [de], a ; and then store it on the stack
    ld a, [wBankPointer] ; load the bank pointer...
    inc a ; add one to it
    ld [wBankPointer], a ; and then store it back into wram
    ; finally, we can pop what we need off the stack
    pop de ; the execution address is first on the stack so we need to move it out of the way
    pop af ; pop our new rombank value off the stack
    push de ; then we can put it back ;)
    ld [MBC3_rombank], a ; preform the bank switch
    ld [hCurrentBank], a ; update the tracker for current rom bank
    ; next we need to backup BC to wram
    ld a, b
    ld [wBankTemp], a
    ld a, c
    ld [wBankTemp + 1], a
    pop bc ; pop our execution address to bc
    ld de, bankswitch_return ; get the address of our return function...
    push de ; and push it on the stack!
    ; move bc to de
    push bc
    pop de
    ; restore bc
    ld a, [wBankTemp]
    ld b, a
    ld a, [wBankTemp + 1]
    ld c, a
    ; jump to our destination address in DE
    push de ; we cant use jp de so instead we can abuse pushing it to the stack
    ret ; and then returning to the value we just put on the stack!


; return from an executed bankswitch
; only hoses a and de
bankswitch_return::
    ld de, wBankStack ; load the address of the bankstack to de
    push bc ; backup bc
    xor a ; set a to 0
    ld b, a ; set b to 0 using a
    ld a, [wBankPointer] ; load the current pointer value
    dec a ; subtract one because we want the previous value
    ld c, a ; set c to our bank pointer addr
    ; now we have to add bc to de, but we cant do it directly
    ; instead we have to use hl for just a second
    push hl
    push de
    pop hl
    add hl, bc
    push hl
    pop de
    pop hl
    ; there, bc is now added to bc
    ld a, [de] ; load previous rom bank into a
    ld [MBC3_rombank], a ; switch the bank
    ld [hCurrentBank], a ; update what the current bank is
    pop bc ; restore bc to what it was before
    ret ; the return address should still be on the stack, so go there
    


bankmanager_init:: ; initialize the bankmanager
    ; set a to 0
    xor a
    ; store it in the current bank pointer
    ld [wBankPointer], a
    ; also store the currently loaded bank (default is 1)
    inc a
    ld [hCurrentBank], a
    ; return
    ret 
