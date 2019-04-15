; rst vectors

SECTION "rst0", ROM0
rst0:
	di
	jp Start

SECTION "rst8", ROM0 ; rst FarCall
rst8:
	jp FarCall_hl

SECTION "rst10", ROM0 ; rst Bankswitch
rst10:
	ldh [hROMBank], a
	ld [MBC3RomBank], a
	ret

SECTION "rst18", ROM0
rst18:
	rst $38

SECTION "rst20", ROM0
rst20:
	rst $38

SECTION "rst28", ROM0 ; rst JumpTable
rst28:
	push de
	ld e, a
	ld d, 0
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop de
	jp hl

; SECTION "rst30", ROM0
; rst30 is midst rst28

SECTION "rst38", ROM0
rst38:
	rst $38
