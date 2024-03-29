include "constants.asm"

SECTION "Stack", wramx
StackBottom:: ds 199
StackTop:: ds 1

section "Random shit", wramx
union
wLargeStringBuffer:: ds 320 ; buffer for storing textbox scripts
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
; define space for 16 bit division
w16DivisionTemp:: ds 2
w16DivisionCount:: db
wTextboxDrawTemp:: db ; fucking hell i NEED THIS
wTempBuffer:: ds temp_buffer_size ; we just need a small handful of bytes
wTempBuffer2:: ds 3 ; yes, we need another one of these
wExperienceSelection:: db ; what stat gets selected to boost
wTextboxDrawMode:: db ; 0 for vblank, 1 for direct
wSaveFileValid:: db ; 0 if no save, 1 if valid, 2 if corrupt
wRNGSeed:: ds 2 ; 2 bytes to hold the seed for RNG

section "Text Entry RAM", wramx
wTextEntryBuffer:: ds 7 ; this buffer holds chars as they are entered by the OSK
wTextArrowRow:: db ; the row the arrow is currently in
wTextArrowColumn:: db ; the column the arrow is in
wTextIndex:: db ; current letter to modify

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
; bit 6: skip script processor (set = yes)
wActionBuffer:: db
; bit flag byte for other stuff
; bit 0: is script loaded?
; bit 1: update position on script exit
wOverworldFlags:: db
wCurrentMapBank:: db ; ROMbank of currently loaded map
wCurrentMapAddress:: ds 2 ; address to where the map is, LOW HI

section "Overworld Map Buffers", wramx
wMapTileBuffer:: ds 360 ; one byte for each of the 20x18 tiles
wEndMapBuffer::
wMapHeader:: ds 40 ; map headers can be max size of 40 bytes in size
wMapScriptBuffer:: ds 80 ; map scripts are loaded here to be ran by our engine
wCurrentScript:: db 
wEncounterTableBuffer:: ds encounter_table_buffer_size ; how large the encounter table can be

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
wOAMSpriteFive:: ds 4
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
wPlayerDefense:: db ; player defense stat
wPlayerState:: db ; 1 means dead lol
wPlayerMP:: db ; max 255 mp points
wPlayerMaxMP:: db ; see above
; array of 8 bit flags!
; bit 0: unlocked bless spell
; bit 1: unlocked ShieldBreak
; bit 2: unlocked Pillowinator
; the rest are unused for now...
wUnlockedMagic:: db
wCurrentExperiencePoints:: ds 2 ; 16bit number, max 65536
wExperienceForNext:: ds 2 ; 16bit number, holds how much you need for the next level
wPlayerLevel:: db ; a single byte for holding the player's level
; IN ORDER
; bank of map
; address to map (lo, hi)
; player x
; player y
wPlayerLastHealData:: ds 5

section "Event Flags", wramx
wEventFlags:: ds 256 ; we address using a single byte, so we can have 256 of these total

section "Battle Engine Enemy storage", wramx
wFoeName:: ds 8 ; 7 chars long, terminated with $FF
wFoeHP:: ds 2 ; max 999 but stored as 2 bytes
wFoeMaxHP:: ds 2 ; same deal as above
wFoeDefense:: db ; stores defense byte 
wFoeState:: db ; 1 means dead
wFoeAttack:: db ; current foe's attack stat
wFoeLevel:: db ; current foe's level

section "Magic Engine RAM Variables", wramx
wMagicSelection:: db ; 0 is the top of the list, goes down
wBoostDefTurnsLeft:: db ; decreases by 1 each turn if not zero
; is a bitflag array
; bit 0: is sheild broken?
; bit 1: is pillowified
; the rest are empty
wFoeAppliedStatus:: db ; if 1, cannot further debuff

section "Battle Engine Ram Variables", wramx
wBattleActionRow:: db ; 0 = bottom, 1 = top
wBattleActionSel:: db ; 0 = left, 1 = right
; byte flag
; 0 = battle active
; 1 = battle won
; 2 = battle lost
; 3 = selected sub-menu cancelled
; 4 = flee attempt worked
; 5 = flee failed...
wBattleState:: db
; byte flag
; 0 - wild encounter
; 1 - scripted encounter (cant flee)
wBattleType:: db

section "BankSwitch CallStack", wramx
; store a very limited amount of previous bank ids in memory
wBankStack:: ds 6
wBankPointer:: db ; for keeping track of where we are in the bank stack
wBankTemp:: ds 2

section "Battle Engine Buffers", wramx 
wSpriteBuffer:: ds 672 ; wow thats a lot of RAM
union
wEmenyDataBuffer:: ds foe_buffer_size ; should be enough for now
nextu
wEmenyLocationInfo:: ds 3
wEmenyBufferMaxHP:: ds 2
wEmenyBufferName:: ds 8
wEmenyBufferDef:: db
wEmenyBufferAtk:: db
endu

section "SRAM Bank 0", sram, bank[0]
sCodeBlock:: ds 100

section "SRAM Bank 1: Player's save file", sram, bank[1]
sHasSaveFile:: db ; if 4, there is a save file!
sSaveFileChecksum:: ds 2 ; 2 byte checksum
sSaveEventChecksum:: ds 2 ; also a two byte checksum
; actual save data starts below
sSavedData::
sSaveMapHeaderPtr:: ds 3 ; bank + address
sSavedName:: ds 8 ; the normal player name is 8 bytes long, so this is too
sSavedHP:: ds 2 ; current player hp
sSavedMaxHP:: ds 2 ; current player max hp
sSavedAttack:: db ; single byte
sSavedDefense:: db ; defense is a single byte
sSavedMP:: db ; first byte is current mp, second byte is maximum MP
sSavedMaxMP:: db ; see above; was ds 2 but changed it
sSavedMagicUnlock:: db ; one byte to hold the state of wUnlockedMagic
sSavedLevel:: db ; level is a single byte, so store it as such
sSavedEXP:: ds 2
sSavedNextEXP:: ds 2 ; 2 bytes each for current exp and saved EXP
sSavedHealData:: ds 5 ; byte for byte copy of wPlayerLastHealData
sSavedX:: db ; player x coord
sSavedY:: db ; player y coord


sSavedEventFlags:: ds 256 ; copy of wEventFlags

section "HRAM Configuration", hram
hCurrentBank:: db
hCurrentSramBank:: db
; used for counting how many vblank cycles there have been
hVBlank_counter:: db
; code to run while waiting for a OAMDMA to finish
hDMALoop:: ds 8