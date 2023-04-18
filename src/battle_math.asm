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

; check if HL is not above BC
; if it is, correct it
check_hp_not_above_max::
    ld a, h ; load h into a
    cp b ; compare to b
    jr z, .lower
    jr c, .lower ; check lower byte
    ; if the high byte is higer, then we should just reset the entire thing
    ld a, b ; load b into a
    ld h, a ; load high byte of max hp into h
    jr .fixlower
.lower
    ld a, l ; load l into a
    cp c ; comapare with c
    jr z, .done
    jr c, .done ; if lower, then dont worry about it lol
.fixlower
    ld a, c ; load c into a
    ld l, a ; and then put low byte back into l
.done
    ret ; leave

; calculates the damage a foe will do
; returns it in b
calculate_foe_damage::
    push de ; backup de
    ld a, [wFoeAttack] ; load foe attack stat
    ; foes dont have modifiers for attack, so we can skip this step
    ld d, a ; put attack stat into d
    ld a, [wPlayerDefense] ; load player defense into a
    ld c, temp_modifyer ; load the modifier into a
    call simple_multiply ; a * c = ?
    ld e, a ; put result into e
    ; NEW: check for boostdef spell active
    ld a, [wBoostDefTurnsLeft] ; check if we have any turns left
    cp 0 ; is it 0?
    call nz, apply_boost_def ; apply buff
    ld a, d ; put attack back into a
    sub a, e ; subtract e from a
    jr c, .underflow ; prevent the calculated damage from underflowing to 255
    cp 0 ; is it 0?
    jr z, .baseatk ; atleast 1 dmg must be dealt
    jr .done
.underflow
    xor a ; put 0 into a
.baseatk
    inc a ; add 1 to 1
.done
    pop de ; restore de
    ld b, a ; put result into a
    ret ; leave

; apply the extra defense for the boostdef spell
apply_boost_def:
    ld a, 3 ; load 3 into a
    add a, e ; add e to a
    ld e, a ; store new defense into e
    ld a, [wBoostDefTurnsLeft] ; load current turns left
    dec a ; subtract 1
    ld [wBoostDefTurnsLeft], a ; update the turns
    ret ; leave

; take in foe health in hl and find out if its 0, writes 1 to bc if it is 0
check_object_state::
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
    ld [bc], a ; put 1 into foestate
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

; runs RNG to check if the attacker missed their attack
; returns 1 in b if they missed
check_miss::
    call random ; get a random number
    ld c, 10 ; load 72 into c
    call simple_divide ; divide random by c
    cp 5 ; is a (the remainder) 5?
    jr z, .miss ; if yes, they missed
    xor a ;  zero out a
    jr .done
.miss
    ld a, 1 ; put 1 into a
.done
    ld b, a ; put a into b
    ret ; leave

; calculates how many experience points the player should get after a fight
; returns total gained in HL
calculate_experience_points::
    xor a ; load 0 into a
    ld h, a ; load 0 into h
    ld l, a ; load 0 into l
    ld a, [wFoeDefense] ; load current foe's defense stat into a
    ld c, 2 ; load 2 into c
    call simple_divide
    push af ; backup a
    ld a, b ; load answer into a
    call sixteenbit_addition ; add to hl
    pop af ; restore a
    call sixteenbit_addition ; also add the remainder
    ld a, [wFoeAttack] ; load foe's attack stat into a
    ld c, 2 ; load 2 into c
    call simple_divide ; a / c
    push af ; backup af
    ld a, b ; load b into a
    call sixteenbit_addition ; add a to hl
    pop af ; restore our remainder
    call sixteenbit_addition ; add remiainder to hl also
    call random ; get a random number
    ld c, 4 ; load 4 into c
    call simple_divide ; a / c again
    call sixteenbit_addition ; add remainder into  hl
    ret ; leave

; checks if a flee succeeded
; b is 1 if yes
calculate_flee::
    call random ; get a random number
    ld c, 7 ; load 7 into c
    call simple_divide ; A mod C
    cp 4 ; is a 4?
    jr z, .doflee
    xor a ; 0 into a
    ld b, a ; 0 into b
    jr .done
.doflee
    ld b, 1 ; load 1 into b
.done
    ret ; leave
