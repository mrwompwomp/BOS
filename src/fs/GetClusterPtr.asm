
;@DOES read a given cluster of a file descriptor
;@INPUT void *fs_GetClusterPtr(void *fd, int cluster);
;@OUTPUT hl = pointer to sector. hl = -1 if failed.
;@NOTE this does not guarantee a contiguous memory space, as files can be fragmented in FAT filesystems.
fs_GetClusterPtr:
	pop bc
	pop hl
	pop de
	push de
	push hl
	push bc
	add hl,de  ;check if fd is null
	or a,a
	sbc hl,de
	jr z,.fail
	inc hl     ;check if fd is -1
	add hl,de
	or a,a
	sbc hl,de
	jr z,.fail
	dec hl
	push de
	push hl
	ld bc,$14
	add hl,bc
	ld a,(hl)  ;upper byte of file starting cluster
	ld c,$1A - $14
	add hl,bc
	ld bc,(hl) ;low two bytes of file starting cluster
	ld (ScrapMem),bc
	ld (ScrapMem+2),a
	ld hl,(ScrapMem)
	add hl,hl  ;multiply by 4
	add hl,hl
	ex (sp),hl
	call fs_DriveLetterFromPtr
	ld (ScrapByte),a
	call nc,fs_ClusterMap
	ld (ScrapMem),hl
	pop bc
	pop de
	jq c,.fail
.loop:
	add hl,bc
	ex hl,de
	add hl,de
	or a,a
	sbc hl,de
	ex hl,de
	jr z,.exit
	push de
	ld a,(hl)
	cp a,$FF
	jr nz,.next
	inc hl
	ld hl,(hl)
	ld de,$0FFFFF
	or a,a
	sbc hl,de
	add hl,de
.next:
	pop de
	jr z,.fail
	dec de
	ld hl,(hl)
	add hl,hl
	add hl,hl
	ld bc,(ScrapMem)
	jr .loop
.fail:
	scf
	sbc hl,hl
	ret
.exit:
	ld bc,(ScrapMem)
	or a,a
	sbc hl,bc
	ld b,7     ;multiply by sector size / cluster map entry size
.mult_loop:
	add hl,hl
	djnz .mult_loop
	call fs_MultBySectorsPerCluster
	push hl
	ld a,(ScrapByte)
	call fs_DataSection
	pop bc
	jq c,.fail ;hope this doesn't happen
	add hl,bc
	push hl
	ld hl,-512 ;subtract "invisible" cluster
	call fs_MultBySectorsPerCluster
	pop bc
	add hl,bc
	or a,a
	ret
