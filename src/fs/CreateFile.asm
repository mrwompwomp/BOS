;@DOES Create a file given a path and return a file descriptor.
;@INPUT void *fs_CreateFile(const char *path, uint8_t flags, int len);
;@OUTPUT file descriptor. Returns 0 if failed to create file.
fs_CreateFile:
	ld hl,-25
	call ti._frameset
	ld hl,flashStatusByte
	set bKeepFlashUnlocked,(hl)
	call sys_FlashUnlock
	or a,a
	sbc hl,hl
	ld (ix-25),hl
	ld hl,(ix+6)
	ld a,(hl)
	or a,a
	jq z,.fail
	cp a,' '
	jq z,.fail
	push hl
	call fs_AbsPath
	ex (sp),hl
	call fs_OpenFile
	jq nc,.fail ;fail if file exists
	call ti._strlen
	ex (sp),hl
	pop bc
	push hl
	ld a,c
	or a,b
	jq z,.found_last_slash
	ld a,'/'
	add hl,bc
	cp a,(hl)
	jq nz,.find_last_slash
	dec hl
.find_last_slash:
	cpdr ;find last '/' in path string
.found_last_slash:
	pop de
	push hl
	sbc hl,de
	inc hl
	push de,hl
	call sys_Malloc
	ld (ix-25),hl
	ex hl,de
	pop bc,hl
	push de
	ldir ;copy the path up until last '/'
	xor a,a
	ld (de),a ;terminate the string
	inc hl ;bypass last '/' in source path
	push hl
	call ti._strlen
	pop de
	add hl,de
	ld a,(hl)
	cp a,'/'
	call z,.malloc_tail
	pop hl
	push de,hl
	call fs_OpenFile
	jq c,.fail ;fail if parent dir doesn't exist
	ex (sp),hl
	pop iy,hl
	bit fsbit_subdirectory,(iy+fsentry_fileattr)
	jq z,.fail ;fail if parent dir is not a dir
	lea de,ix-19
	push iy,hl,de
	call fs_StrToFileEntry
	pop bc,bc,iy
	ld de,(iy+fsentry_filelen)
	ex.s hl,de
	ld (ix-22),hl
	ld de,16
	add hl,de
	push iy,hl
	call fs_SetSize ;resize parent directory up 16 bytes
	jq c,.fail
	ld hl,(ix+12)
	ld (ix + fsentry_filelen - 19),l
	ld (ix + fsentry_filelen+1 - 19),h
	push hl
	call fs_Alloc ;allocate space for new file
	jq c,.fail
	pop bc,bc,iy

	ld a, (ix+9)
	ld (ix + fsentry_fileattr - 19), a     ;setup new file descriptor contents
	ld (ix + fsentry_filesector - 19),l
	ld (ix + fsentry_filesector+1 - 19),h

	ld de,(iy+fsentry_filelen)
	ex.s hl,de
	ld bc,-32 ;write 32 bytes behind the new end of file, to overwrite the end of directory marker
	add hl,bc
	push hl,iy
	ld bc,16
	push bc
	ld c,1
	push bc
	pea ix-19
	call fs_Write ;write new file descriptor to parent directory
	pop bc,bc,bc,iy,bc

	ld de,(iy+fsentry_filelen)
	ex.s hl,de
	ld bc,-16 ;write 16 bytes behind the new end of file to write new end of directory marker
	add hl,bc
	push hl,iy
	ld bc,16
	push bc
	ld c,1
	push bc
	ld bc,$03FFF0
	push bc
	call fs_Write ;write new file descriptor to parent directory
	pop bc,bc,bc,iy,bc

	ld hl,flashStatusByte
	res bKeepFlashUnlocked,(hl)
	call sys_FlashLock
	ld hl,(ix+6)
	push hl
	call fs_OpenFile ; get pointer to new file descriptor
	pop bc
	db $01
.fail:
	xor a,a
	sbc hl,hl
	push hl,af
	ld hl,(ix-25)
	add hl,bc
	or a,a
	sbc hl,bc
	push hl
	call nz,sys_Free
	pop bc,af,hl
	ld sp,ix
	pop ix
	ret
.malloc_tail:
	push de
	call ti._strlen
	push hl
	call sys_Malloc
	jq c,.fail
	ld (ix-25),hl
	pop bc
	ex hl,de
	pop hl
	push de
	ldir
	xor a,a
	ld (de),a
	pop de
	ret


