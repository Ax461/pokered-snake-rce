; Ported from https://pastebin.com/t8Qu6Pc2

MainPayload:

OBJECT EQU $74

	jr InitGame

; Place 20 black tiles starting from hl
DrawHorizontalBorder:
	ld bc, SCREEN_WIDTH
	xor a
	jp FillMemory

; Entry point
InitGame:
	xor a
	ld [hSCX], a
	ld [hSCY], a

	call DisableLCD
	ld hl, VChars2
	ld bc, 16
	ld a, $ff
	call FillMemory
	call EnableLCD

	ld a, 1
	ld [hAutoBGTransferEnabled], a
	ld hl, rLCDC
	set 3, [hl]
	call ClearScreen
	call UpdateSprites

Restart:
; wOverworldMap will store the position of the snake in the screen
	ld hl, wOverworldMap
	ld bc, 100
	xor a
	call FillMemory

; Draw BG
InitScreen:
	call DrawHorizontalBorder

	ld hl, wTileMap

; Draw top Border
	call DrawHorizontalBorder

; Draw background
	ld bc, SCREEN_WIDTH * SCREEN_HEIGHT - 2 * SCREEN_WIDTH
	ld a, " "
	call FillMemory

; Draw bottom border
	call DrawHorizontalBorder

; Draw vertical borders
	coord hl, 19, 0
	ld bc, SCREEN_WIDTH - 1
	xor a
	ld d, SCREEN_HEIGHT - 1
.loop
	ld [hli], a
	ld [hl], a
	add hl, bc
	dec d
	jr nz, .loop

; Set starting movement direction to right
	ld a, D_RIGHT
	ld [hSnakeDirection], a

; Draw snake
	coord de, 8, 8

; Place the three-tile snake in the screen and save its position and length
	ld b, 3
	ld a, b
	ld [hSnakeLength], a
	xor a
	ld hl, wOverworldMap
.loop2
	ld [de], a
	ld [hl], d
	inc hl
	ld [hl], e
	inc hl
	dec b
	inc de
	jr nz, .loop2

; Draw the object that can be eaten in a random position in the screen
DrawObject:
	ld a, [hTileRotation]
	xor 1
	ld [hTileRotation], a

.drawObject
	ld a, [hRandomAdd]
	cp SCREEN_WIDTH * SCREEN_HEIGHT / 2
	jr nc, .drawObject

	ld b, 0
	ld c, a
	ld hl, wTileMap
	add hl, bc
	add hl, bc
	ld a, [hTileRotation]
	and a
	jr z, .ok
	inc hl
.ok
	ld a, " "
	cp [hl]
	jr nz, .drawObject

; Place object
	ld a, OBJECT
	ld [hl], a

; Move snake in the wOverworldMap buffer
ShiftPositions:
	ld de, wOverworldMap
	ld a, [hSnakeLength]
	dec a
	add a
	ld b, a
	ld a, [hAteObject]
	and a
	jr nz, .ateObject

; Remove the snake's tail
	ld a, [de]
	ld h, a
	inc de
	ld a, [de]
	ld l, a
	dec de
	ld a, " "
	ld [hl], a

.loop
; Move every snake tile one space
	inc de
	inc de
	ld a, [de]
	dec de
	dec de
	ld [de], a
	inc de
	dec b
	jr nz, .loop
	dec de
	dec de
	jr .goOn

.ateObject
	xor a
	ld [hAteObject], a
	ld a, [hSnakeLength]
	inc a
	ld [hSnakeLength], a
	dec a
	dec a
.loop2
	inc de
	inc de
	dec a
	jr nz, .loop2

.goOn
	ld a, [de]
	ld h, a
	inc de
	ld a, [de]
	ld l, a
	inc de

ReadUserInput:
	ld a, [hJoyInput]
	and $f0
	jr nz, .newMovement
	ldh a, [hSnakeDirection]
.newMovement
	ldh [hSnakeDirection], a
	cp D_RIGHT
	jr z, MovePositionRight
	cp D_LEFT
	jr z, MovePositionLeft
	cp D_UP
	jr z, MovePositionUp

MovePositionDown:
	ld bc, 14
	jr MovePosition
MovePositionUp:
	ld bc, -14
	jr MovePosition
MovePositionLeft:
	ld bc, -1
	jr MovePosition
MovePositionRight:
	ld bc, 1

; Calculate the new snake head and save it in the buffer
MovePosition:
	add hl, bc

; Check if the snake ate the object
	ld a, OBJECT
	cp [hl]
	jr nz, .checkCollision
	ldh [hAteObject], a
	jr .didEat

.checkCollision
; Check if the snake collided so the player lost
	ld a, " "
	cp [hl]
	jp nz, Restart

.didEat
; Save the new snake head tile in the buffer and draw the new head
	xor a
	ld [hl], a
	ld a, h
	ld [de], a
	inc de
	ld a, l
	ld [de], a

; Delay frames (the longer the snake is the faster the game goes)
.delayFrames
	ld a, [hSnakeLength]
	ld c, a
	ld a, 40
	sub c
	sub c
	ld c, a
	call DelayFrames

	ldh a, [hAteObject]
	and a
	jp nz, DrawObject
	jp ShiftPositions
