SECTION "Stack", wramx
StackBottom:: ds 199
StackTop:: ds 1

SECTION "VBlank state variables", wramx
wDisableLCD:: db

wSmallLoop:: ; general purpose loop variable (only use with vblank)
wVBlankAction:: db

wTileSlot:: db
wTileLoop:: db

; vblank string copier shit
wStringBuffer:: ds 20
wStringDestHigh:: db
wStringDestLow:: db

section "BankSwitch CallStack", wramx
; store a very limited amount of previous bank ids in memory
wBankStack:: ds 6
wBankPointer:: db ; for keeping track of where we are in the bank stack
wBankTemp:: ds 2


section "hram current loaded bank tracker", hram[$FF8B]
hCurrentBank:: db