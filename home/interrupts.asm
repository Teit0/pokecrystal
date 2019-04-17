; Game Boy hardware interrupts

SECTION "vblank", ROM0[$0040]
vblank:
	jp VBlank

SECTION "lcd", ROM0[$0048]
lcd:
	jp LCD

SECTION "timer", ROM0[$0050]
timer:
	jp Timer

SECTION "serial", ROM0[$0058]
serial:
	jp Serial

SECTION "joypad", ROM0[$0060]
joypad:
	jp JoypadInt
