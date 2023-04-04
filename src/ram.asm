SECTION "Stack", wramx
StackBottom:: ds 199
StackTop:: ds 1

section "Random shit", wramx
wLargeStringBuffer:: ds 200
wSubLoopCount:: db
wDebugByte:: db
wTextboxDrawn:: db ; keeps track of weather or not the textbox is on the window tilemap

section "Overworld RAM", wramx
wPlayerx:: db
wPlayery:: db

section "Overworld Map Buffers", wramx
wMapTileBuffer:: ds 360 ; one byte for each of the 20x18 tiles
wEndMapBuffer::
wMapHeader:: ds 35 ; map headers can be max size of 33 bytes in size
wMapScriptBuffer:: ds 30 ; map scripts are loaded here to be ran by our engine
wCurrentScript:: db 

section "OAM DMA Buffer", wramx[$DF00]
; each OAM entry is 4 bytes long; total 160 or $a0 bytes long
; OAM Entry layout:
; Byte 0: y position
; Byte 1: x position
; Byte 2: tile index
; Byte 3: flags
union
wOAMBuffer:: ds 160 ; the start of the OAM buffer
wEndOfOAM::
nextu
wOAMSpriteOne:: ds 4 ; sprite number 1
wOAMSpriteTwo:: ds 4 ; sprite number 2
endu

SECTION "VBlank state variables", wramx
wDisableLCD:: db

wPalletData:: db ; basically a buffer for holding a pallete

wSmallLoop:: ; general purpose loop variable (only use with vblank)
wVBlankAction:: db
wTileCount:: db ; how many tiles to loop thru
wTileAddress:: ; where to copy the tile to in memory
wSramCopyDestination:: ; used to store where the source data comes from
wTileLocation:: ds 2 ; where the tiles are in memory
wTileBank:: db ; rom bank of which a tileset is stored in

wTileSlot:: db
wTileLoop:: db

; vblank string copier shit
wStringBuffer:: ds 21
wStringDestHigh:: db
wTileBuffer:: ; used to store current tile for vblank to copy lol
wStringDestLow:: db

; set of bit flags to monitor state of various things (and not waste more bytes lol)
; bit 0: blink arrow flag
; bit 1: set: arrow, reset: line
; bit 2: disable LCD
; bit 3: renable LCD after vblank finishes
; bit 4: do OAMDMA transfer
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
; used for counting how many vblank cycles there have been
hVBlank_counter:: db
; code to run while waiting for a OAMDMA to finish
hDMALoop:: ds 8