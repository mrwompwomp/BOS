;@DOES Free as block of memory malloc'd by sys_Malloc
;@INPUT void sys_Free(void *ptr);
;@DESTROYS All
sys_Free:
	pop bc,hl
	push hl,bc
	ld de,bottom_of_malloc_RAM
	or a,a
	sbc hl,de ;ptr - bottom_of_malloc_RAM
	ret c
	ld hl,65536
	sbc hl,bc
	ccf
	ret c
	add hl,bc
	ld bc,32
	call ti._idivu
	ld de,malloc_cache ;index the malloc cache
	add hl,de ;hl now points to 8-bit malloc cache entry
	ld bc,4096
.loop2:
	ld a,(hl)
	inc a
	ret nz
	ld (hl),a
	dec bc
	ld a,c
	or a,b
	jq nz,.loop2
	ret

