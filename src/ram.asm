SECTION "Stack", wramx
StackBottom:: ds 199
StackTop:: ds 1

SECTION "VBlank state variables", wramx
wDisableLCD:: db

wSmallLoop:: ; general purpose loop variable (only use with vblank)
wVBlankAction:: db
wTileCount:: db ; how many tiles to loop thru
wTileAddress:: ; where to copy the tile to in memory
wTileLocation:: ds 2 ; where the tiles are in memory

wTileSlot:: db
wTileLoop:: db

; vblank string copier shit
wStringBuffer:: ds 20
wStringDestHigh:: db
wTileBuffer:: ; used to store current tile for vblank to copy lol
wStringDestLow:: db

; set of bit flags to monitor state of various things (and not waste more bytes lol)
; no uses currently (oops)
wVBlankFlags:: db

section "BankSwitch CallStack", wramx
; store a very limited amount of previous bank ids in memory
wBankStack:: ds 6
wBankPointer:: db ; for keeping track of where we are in the bank stack
wBankTemp:: ds 2

section "SRAM Bank 0", sram, bank[0]
sCodeBlock:: ds 100


section "HRAM Configuration", hram
hCurrentBank:: db
hCurrentSramBank:: db