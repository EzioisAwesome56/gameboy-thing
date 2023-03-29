SECTION "ROM Bank Manager", rom0


def MBC3_rombank EQU $2000
def MBC3_srambank EQU $4000
def MBC3_sramenable EQU $0000

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

; jumps to address HL at bank A
; does not setup any return addresses or note previous bank
bankswitch_lazy_exec::
    ld [MBC3_rombank], a ; switch banks
    ld [hCurrentBank], a ; oops we should probably do this too
    jp hl ; jump to address



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
    ldh [hCurrentSramBank], a ; also set our sram bank to  0 bc that is default
    ; also store the currently loaded bank (default is 1)
    inc a
    ldh [hCurrentBank], a
    ; return
    ret

; switches sram to bank A
bankmanager_sram_bankswitch::
    ld [MBC3_srambank], a ; switch bank
    ldh [hCurrentSramBank], a ; notate that we did
    ret 

; enable sram read/write
mbc3_enable_sram::
    push af
    ld a, $0A ; load magic value
    ld [MBC3_sramenable], a ; store it to the sram register
    pop af
    ret 

; locks sram from reads or writes
mbc3_disable_sram::
    push af
    ld a, $00 ; load magic to lock sram
    ld [MBC3_sramenable], a ; write to disable sram
    pop af
    ret 

; copies code from HL to sCodeBlock
; uses DE and A
; terminate code block with $FEEF
mbc_copytosram::
    push af ; backup a
    push de ; also backup DE
    ldh [hCurrentSramBank], a ; load current sram bank into a
    cp 0 ; is it bank 0?
    call nz, loadbank0 ; switch bank to 0
    call mbc3_enable_sram ; unlock sram
    ld de, sCodeBlock ; set de to our code buffer in sram
.loop
    ld a, [hl] ; load current char into a
    cp $FE ; is it the first half of terminator?
    jr z, .check ; if so, we need to check the other half
.resume
    ld [de], a ; otherwise, write a to de
    ; increment source and desitnation address
    inc de
    inc hl
    jr .loop
.check
    ; we need to check the second half of the terminator
    push af ; backup a
    inc hl ; inc hl to get next byte
    ld a, [hl] ; load byte
    cp $EF ; is it the other half?
    jp z, .done ; if yes, quit
    ; otherwise, we need to keep going
    dec hl ; restore hl to what it was before
    pop af ; restore a
    jr .resume ; resume copying
.done
    pop af ; we have an extra af on the stack so get rid of it
    ; lock sram again
    call mbc3_disable_sram
    ; pop de and af off the stack
    pop de
    pop af
    ret ; exit


; internal function to load bank 0
loadbank0:
    xor a ; sett a to zero
    call bankmanager_sram_bankswitch ; switch banks
    ret ; return to caller

