section "Experience handler", romx
include "macros.asm"

; check if a player has enough experience to level up
check_if_eliable_for_levelup::
    push hl
    push bc ; backup registers
    ld a, [wExperienceForNext] ; load high byte into a
    ld d, a ; store it into d
    ld a, [wExperienceForNext + 1] ; load low byte into a
    ld e, a ; store it into e
    ld a, [wCurrentExperiencePoints] ; loadhigh byte of experience points into a
    ld h, a ; store into h
    ld a, [wCurrentExperiencePoints + 1] ; load low byte of EXP into a
    ld l, a ; store it into l
    ; first we check the hight byte
    ld a, h ; put high byte back into h
    cp d ; compare to d
    jr z, .checklow ; check low if equal too the highbyte
    jp c, exit_experience ; exit if is it less than
    jp do_level_up ; if its greater than the high byte, automatic level up
.checklow
    ld a, l ; load load byte into a
    cp e ; compare against e
    jp nc, do_level_up ; if >=, do level up[
    jp exit_experience ; otherwise, leave

; exit this routine
exit_experience:
    pop bc
    pop hl
    ret ; yeetus

; preformed a level up
do_level_up:
    buffertextbox level_up_box ; buffer our text
    farcall clear_textbox ; empty out the textbox
    farcall do_textbox ; display to the screen
    jp exit_experience ; yeetus

