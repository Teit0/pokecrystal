; Game Boy hardware interrupts

SECTION "vblank", ROM0
vblank:
	jp VBlank

SECTION "lcd", ROM0
lcd:
	jp LCD

SECTION "timer", ROM0
timer:
	jp Timer

SECTION "serial", ROM0
serial:
	jp Serial

SECTION "joypad", ROM0
joypad:
	jp JoypadInt
