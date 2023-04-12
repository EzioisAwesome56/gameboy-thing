section "Battle Engine Math Routines", romx
include "macros.asm"
include "constants.asm"

def temp_modifyer equ 1 ; modifyer of 1

; calculate how much damage a player does with an attack
; returns damage delt in b
calculate_player_damage::
    push de ; backup registers
    ld a, [wPlayerAttack] ; first load the player attack stat into a
    ld c, temp_modifyer ; load c with the modifer
    call simple_multiply ; multiply attack by modifyer
    ld d, a ; put result into d for now
    ld a, [wFoeDefense] ; load foe defense into a
    ld c, temp_modifyer ; load c with our modifyer
    call simple_multiply ; apply modifyer to defense
    ld e, a ; put that into e
    ld a, d ; restore calculated attack value
    sub a, e ; subtract defense value from attack value
    cp 0 ; is a 0?
    jr z, .baseatk
    jr .done
.baseatk
    inc a ; add 1 to a
.done
    pop de ; restore registers
    ld b, a ; put attack into b
    ret ; leave

; take in foe health in hl and find out if its 0
check_foe_state::
    ld a, h ; load high byte into a
    cp 0 ; is it 0
    jr z, .check ; check low byte if yes
    jr nz, .done ; otrherwise leave
.check
    ld a, l ; load low byte into a
    cp 0 ; is it 0
    jr z, .dead ; they're dead lol
    jr nz, .done ; theyre fine, leave
.dead
    xor a ; 0 out a
    inc a ; a is 1
    ld [wFoeState], a ; put 1 into foestate
.done
    ret ; leave

; checks if the player landed  a critical hit
; returns 1 in b if itt landed
check_criticalhit::
    call random ; get a random number
    ld c, 7 ; one in 7 chance to land a crit
    call simple_divide ; preform modulo c on a
    cp 5 ; is a 5?
    jr z, .crit ; crit landed!
    xor a ; 0 into a
    ld b, a ; put 0 into b
    jr .done ; no crit 4 you
.crit
    xor a ; 0 into a
    inc a ; 1 into a
    ld b, a ; put that 1 into b
.done
    ret ; leave
    

