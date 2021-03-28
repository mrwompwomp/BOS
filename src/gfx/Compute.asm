;@DOES compute draw location on the current lcd buffer from XY coodinate.
;@INPUT HL X coordinate
;@INPUT E Y coordinate
;@OUTPUT HL pointer to draw location
;@DESTROYS HL,DE
gfx_Compute:
	ld	d,LCD_WIDTH / 2
	mlt	de
	add	hl,de
	add	hl,de
	ld	de,(cur_lcd_buffer)
	add	hl,de
	ret

