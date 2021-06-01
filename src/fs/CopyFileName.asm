
;@DOES copies file name from file descriptor
;@INPUT char *fs_CopyFileName(void *fd);
;@OUTPUT returns -1 on fail
;@NOTE Allocates space for copied file name
fs_CopyFileName:
	ld hl,-3
	call ti._frameset
	ld hl,(ix+6)
	ld a,(hl)
	cp a,fsentry_longfilename
	jq z,.long_file_name
	ld bc,14
	push bc
	call sys_Malloc ;allocate space for file name
	pop bc
	jq c,.return_hl
	ld (ix-3),hl
	ex hl,de
	ld hl,(ix+6)
	ld b,8
.copynameloop:
	ld a,(hl)
	cp a,' '
	jq z,.endname
	ld (de),a
	inc hl
	inc de
	djnz .copynameloop
	db $01
.endname:
	inc hl
	djnz .endname
.putdot:
	ld a,(hl)
	cp a,' '
	jq z,.return ;don't add a dot if there's no file extension
	ld a,'.'
	ld (de),a
	inc de
	ld b,3
.copyext:
	ld a,(hl)
	cp a,' '
	jq z,.return
	ld (de),a
	inc hl
	inc de
	djnz .copyext
	jq .return
.long_file_name:
	ld de,(ix+6)
	inc de
	ld a,(de)
;	or a,a ;assumes Cf unset when jumped here
	sbc hl,hl
	ld l,a
	inc hl
	push hl
	call sys_Malloc ;allocate space for file name
	pop bc
	jq c,.return_hl
	ld (ix-3),hl
	ld de,16
	ld hl,(ix+6)
	add hl,de
	ld de,(ix-3)
	ldir
.return:
	xor a,a
	ld (de),a
	ld hl,(ix-3)
.return_hl:
	ld sp,ix
	pop ix
	ret
	; pop bc
	; pop de
	; pop hl
	; push hl
	; push de
	; push bc
	; push de
	; ld a,(hl)
	; or a,a
	; jq z,.enda
	; cp a,fsentry_deleted
	; jq z,.end
	; cp a,fsentry_longfilename
	; jq z,.end
	; ld (de),a
	; inc de
	; cp a,'.'
	; jq z,.dotentry
; .enterloop:
	; inc hl
	; push hl
	; ld b,7
; .loop:
	; ld a,(hl)
	; inc hl
	; cp a,' '
	; jq z,.ext_start
	; ld (de),a
	; inc de
	; djnz .loop
; .ext_start:
	; pop hl
	; ld bc,7
	; add hl,bc
	; ld a,(hl)
	; cp a,' '
	; jr z,.end
	; ld a,'.'
	; ld (de),a
	; inc de
; .ext:
	; ld b,3
; .extloop:
	; ld a,(hl)
	; inc hl
	; cp a,' '
	; jq z,.end
	; ld (de),a
	; inc de
	; djnz .extloop
	; jq .end
; .dotentry:
	; inc hl
	; ld a,(hl)
	; cp a,'.'
	; jq z,.enda
; .end:
	; xor a,a
; .enda:
	; ld (de),a
	; inc de
	; xor a,a
	; ld (de),a
	; pop hl
	; ret

