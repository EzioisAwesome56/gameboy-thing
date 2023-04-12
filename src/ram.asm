include "constants.asm"

SECTION "Stack", wramx
StackBottom:: ds 199
StackTop:: ds 1

section "Random shit", wramx
union
wLargeStringBuffer:: ds 200 ; buffer for storing textbox scripts
nextu
wBootupVars:: ds 3 ; a, b, c in that order
endu
wSubLoopCount:: db
wDebugByte:: db
wTextboxDrawn:: db ; keeps track of weather or not the textbox is on the window tilemap
; types of gameboys:
; 0: DMG
; 1: Pocket
; 2: Super Gameboy
; 3: Super Gameboy 2
; 4: Color
; 5: Advance
; 6: Unknown
wGameboyType:: db
; used for the title screen option selection
wTitleScreenOption:: db
wYesNoBoxSelection:: db ; 1 for yes, 0 for no

section "Overworld RAM", wramx
wPlayerx:: db
wPlayery:: db
; bit flag byte
; bit 0: move in positive x
; bit 1: move in negative x
; bit 2: move in positive y
; bit 3: move in negative y
; BITS USED FOR NOT-MOVEMENT
; bit 4: is ok to move (set = yes)
; bit 5: is encounter tile? (set = yes)
wActionBuffer:: db
; bit flag byte for other stuff
; bit 0: is script loaded?
wOverworldFlags:: db

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
wOAMSpriteThree:: ds 4 ; sprite number 3
wOAMSpriteFour:: ds 4 ; sprite 4
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

section "Loaded Player information", wramx
wPlayerName:: ds 8 ; max 7 chars long, terminated with $FF
wPlayerHP:: ds 2 ; max 999, but stored as 2 bytes
wPlayerMaxHP:: ds 2 ; same as above, just slightly different
wPlayerAttack:: db ; player attack stat

section "Battle Engine Enemy storage", wramx
wFoeName:: ds 8 ; 7 chars long, terminated with $FF
wFoeHP:: ds 2 ; max 999 but stored as 2 bytes
wFoeMaxHP:: ds 2 ; same deal as above
wFoeDefense:: db ; stores defense byte 
wFoeState:: db ; 1 means dead

section "Battle Engine Ram Variables", wramx
wBattleActionRow:: db ; 0 = bottom, 1 = top
wBattleActionSel:: db ; 0 = left, 1 = right
; byte flag
; 0 = battle active
; 1 = battle won
; 2 = battle lost
wBattleState:: db

section "BankSwitch CallStack", wramx
; store a very limited amount of previous bank ids in memory
wBankStack:: ds 6
wBankPointer:: db ; for keeping track of where we are in the bank stack
wBankTemp:: ds 2

section "Battle Engine Buffers", wramx 
wSpriteBuffer:: ds 672 ; wow thats a lot of RAM
wEmenyDataBuffer:: ds foe_buffer_size ; should be enough for now

section "SRAM Bank 0", sram, bank[0]
sCodeBlock:: ds 100

section "SRAM Bank 1", sram, bank[1]
; event flags for tracking shit in the game
sTestEvent:: db


section "HRAM Configuration", hram
hCurrentBank:: db
hCurrentSramBank:: db
; used for counting how many vblank cycles there have been
hVBlank_counter:: db
; code to run while waiting for a OAMDMA to finish
hDMALoop:: ds 8