_HandlePlayerStep::
	ld a, [wPlayerStepFlags]
	and a
	ret z
	bit PLAYERSTEP_START_F, a
	jr nz, .update_overworld_map
	bit PLAYERSTEP_STOP_F, a
	jr nz, .update_player_coords
	bit PLAYERSTEP_CONTINUE_F, a
	jr nz, .finish
	ret

.update_overworld_map
	ld a, 2
	ld [wHandlePlayerStep], a
	call UpdateOverworldMap
	jr .finish

.update_player_coords
	call UpdatePlayerCoords
	jr .finish

.finish
	call HandlePlayerStep
	ld a, [wPlayerStepVectorX]
	ld d, a
	ld a, [wPlayerStepVectorY]
	ld e, a
	ld a, [wPlayerBGMapOffsetX]
	sub d
	ld [wPlayerBGMapOffsetX], a
	ld a, [wPlayerBGMapOffsetY]
	sub e
	ld [wPlayerBGMapOffsetY], a
	ret

ScrollScreen::
	ld a, [wPlayerStepVectorX]
	ld d, a
	ld a, [wPlayerStepVectorY]
	ld e, a
	ldh a, [hSCX]
	add d
	ldh [hSCX], a
	ldh a, [hSCY]
	add e
	ldh [hSCY], a
	ret

HandlePlayerStep:
	ld hl, wHandlePlayerStep
	ld a, [hl]
	and a
	ret z
	dec [hl]
	ld a, [hl]
	ld hl, .Jumptable
	rst JumpTable
	ret

.Jumptable:
	dw GetMovementPermissions
	dw BufferScreen

UpdatePlayerCoords:
	ld a, [wPlayerStepDirection]
	and a
	jr nz, .check_step_down
	ld hl, wYCoord
	inc [hl]
	ret

.check_step_down
	cp UP
	jr nz, .check_step_left
	ld hl, wYCoord
	dec [hl]
	ret

.check_step_left
	cp LEFT
	jr nz, .check_step_right
	ld hl, wXCoord
	dec [hl]
	ret

.check_step_right
	cp RIGHT
	ret nz
	ld hl, wXCoord
	inc [hl]
	ret

UpdateOverworldMap:
	ld a, [wPlayerStepDirection]
	and a
	jr z, .step_down
	cp UP
	jr z, .step_up
	cp LEFT
	jr z, .step_left
	cp RIGHT
	jr z, .step_right
	ret

.step_down
	call .ScrollOverworldMapDown
	call LoadMapPart
	call ScrollMapUp
	ret

.step_up
	call .ScrollOverworldMapUp
	call LoadMapPart
	call ScrollMapDown
	ret

.step_left
	call .ScrollOverworldMapLeft
	call LoadMapPart
	call ScrollMapRight
	ret

.step_right
	call .ScrollOverworldMapRight
	call LoadMapPart
	call ScrollMapLeft
	ret

.ScrollOverworldMapDown:
	ld a, [wBGMapAnchor]
	add 2 * BG_MAP_WIDTH
	ld [wBGMapAnchor], a
	jr nc, .not_overflowed
	ld a, [wBGMapAnchor + 1]
	inc a
	and %11
	or HIGH(vBGMap0)
	ld [wBGMapAnchor + 1], a
.not_overflowed
	ld hl, wMetatileStandingY
	inc [hl]
	ld a, [hl]
	cp 2 ; was 1
	jr nz, .done_down
	ld [hl], 0
	call .Add6ToOverworldMapAnchor
.done_down
	ret

.Add6ToOverworldMapAnchor:
	ld hl, wOverworldMapAnchor
	ld a, [wMapWidth]
	add 6
	add [hl]
	ld [hli], a
	ret nc
	inc [hl]
	ret

.ScrollOverworldMapUp:
	ld a, [wBGMapAnchor]
	sub 2 * BG_MAP_WIDTH
	ld [wBGMapAnchor], a
	jr nc, .not_underflowed
	ld a, [wBGMapAnchor + 1]
	dec a
	and %11
	or HIGH(vBGMap0)
	ld [wBGMapAnchor + 1], a
.not_underflowed
	ld hl, wMetatileStandingY
	dec [hl]
	ld a, [hl]
	cp -1 ; was 0
	jr nz, .done_up
	ld [hl], $1
	call .Sub6FromOverworldMapAnchor
.done_up
	ret

.Sub6FromOverworldMapAnchor:
	ld hl, wOverworldMapAnchor
	ld a, [wMapWidth]
	add 6
	ld b, a
	ld a, [hl]
	sub b
	ld [hli], a
	ret nc
	dec [hl]
	ret

.ScrollOverworldMapLeft:
	ld a, [wBGMapAnchor]
	ld e, a
	and $e0
	ld d, a
	ld a, e
	sub $2
	and $1f
	or d
	ld [wBGMapAnchor], a
	ld hl, wMetatileStandingX
	dec [hl]
	ld a, [hl]
	cp -1
	jr nz, .done_left
	ld [hl], 1
	call .DecrementwOverworldMapAnchor
.done_left
	ret

.DecrementwOverworldMapAnchor:
	ld hl, wOverworldMapAnchor
	ld a, [hl]
	sub 1
	ld [hli], a
	ret nc
	dec [hl]
	ret

.ScrollOverworldMapRight:
	ld a, [wBGMapAnchor]
	ld e, a
	and $e0
	ld d, a
	ld a, e
	add $2
	and $1f
	or d
	ld [wBGMapAnchor], a
	ld hl, wMetatileStandingX
	inc [hl]
	ld a, [hl]
	cp 2
	jr nz, .done_right
	ld [hl], 0
	call .IncrementwOverworldMapAnchor
.done_right
	ret

.IncrementwOverworldMapAnchor:
	ld hl, wOverworldMapAnchor
	ld a, [hl]
	add 1
	ld [hli], a
	ret nc
	inc [hl]
	ret
