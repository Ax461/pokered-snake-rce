Bootstrap:
; Patch the current room script every time we load another room
	ld hl, wMapScriptPtr + 1
	ld de, $d66b
	ld a, [hld]
	cp $80
	jr nc, alreadyPatchedScript
	ld [de], a
	dec de
	ld a, [hl]
	ld [de], a

alreadyPatchedScript:
	ld [hl], $83
	inc hl
	ld [hl], $d6
	ld a, $c3 ; important for DMARoutine
	ret

; Patch hram code to always call the code at d66c
	ld hl, $ff80
	ld [hl], $18 ; jr 78 (to fffa)
	inc hl
	ld [hl], $78
	ld hl, $fffa
	ld [hl], $cd ; call $d66c
	inc hl
	ld [hl], $6c
	inc hl
	ld [hl], $d6
	inc hl
	ld [hl], $18 ; jr 83 (to ff82)
	inc hl
	ld [hl], $83
	 
	ld a, [hJoyInput]
	cp B_BUTTON + SELECT
	jr z, execMainPayload

	ld a, [wCurMap]
	cp TRADE_CENTER
	jr z, execVirusPayload
	 
returnFromRoomSpecificScript:
	ld hl, $d66a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp [hl]
	 
execMainpayload:
	ld hl, MainPayload
	jr loadExtraCodeFromSram
	 
execVirusPayload:
	ld hl, VirusPayload
	 
loadExtraCodeFromSram:
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a ;enable sram
	ld a, 1
	ld [MBC1SRamBank], a
	 
	ld de, $c800
	ld bc, $0200
	call CopyData

	ld h, SRAM_DISABLE
	ld [hl], h
	call $c800
	jr returnFromRoomSpecificScript
