
include 'include/ez80.inc'
include 'include/ti84pceg.inc'
include 'include/bos.inc'

org ti.userMem
	jr explorer_init
	db "REX",0
explorer_init:
	pop bc
	pop hl
	push hl
	push bc
	ld (explorer_args),hl
	call load_libload
	jr z,explorer_init_2
	ld hl,str_FailedToLoadLibload
	scf
	sbc hl,hl
	ret
explorer_init_2:
	ld c,1
	push bc
	call gfx_SetDraw
	pop bc
	ld bc,256
	push bc
	call bos.sys_Malloc
	pop bc
	jp c,bos._ErrMemory
	ld (explorer_path_ptr),hl
	ld de,0
explorer_args:=$-3
	ld a,(de)
	or a,a
	jq z,.default_path
	push hl,de
	call ti._strlen
	ex (sp),hl
	pop bc,de
	ldir
	xor a,a
	ld (de),a
	jq explore_files
.default_path:
	db $11,"C:/"
	ld (hl),de
	inc hl
	inc hl
	inc hl
	ld (hl),0
explorer_main:
	call gfx_ZeroScreen
	ld c,0
	push bc
	call gfx_SetTextTransparentColor
	call gfx_SetTextBGColor
	pop bc
	ld c,$FF
	push bc
	call gfx_SetTextFGColor
	pop bc
	ld hl,initial_strings
	call gfx_PrintStrings
	call gfx_BlitBuffer
.key_loop:
	call bos.sys_WaitKeyCycle
	cp a,56
	jq z,_uninstall_bos
	cp a,15
	jq z,_exit
	cp a,9
	jq nz,.key_loop
explore_files:
	call gfx_ZeroScreen
	ld hl,0
explorer_path_ptr:=$-3
	push hl
	call bos.fs_OpenFile
	pop bc
	push hl
	pop iy
	push af
	ld bc,(explorer_path_ptr)
	or a,a
	sbc hl,hl
	push hl,hl,bc
	call gfx_PrintStringXY
	pop bc,bc,bc
	pop af
	call nc,explorer_draw_files
	ld hl,0
explorer_cursor_y:=$-3
	inc hl
	push hl
	add hl,hl
	add hl,hl
	add hl,hl
	pop de
	add hl,de
	push hl
	ld bc,0
	push bc
	ld bc,str_CursorString
	push bc
	call gfx_PrintStringXY
	pop bc,bc,bc
	call gfx_BlitBuffer
.keyloop:
	call bos.sys_WaitKeyCycle
	cp a,15
	jq z,explorer_main
	ld bc,explore_files
	push bc
	cp a,1
	jq z,explorer_scroll_down
	cp a,4
	jq z,explorer_scroll_up
	
	pop bc
	jq .keyloop
_exit:
	call gfx_ZeroScreen
	call bos._HomeUp
	xor a,a
	sbc hl,hl
	ret
_uninstall_bos:
	ld bc,str_Uninstall
	push bc
	call bos.sys_ExecuteFile
	pop bc
	ret
str_Uninstall:
	db "A:/UNINSTLR.EXE",0
explorer_scroll_down:
	ld hl,(explorer_cursor_y)
	inc hl
	ld bc,23
	or a,a
	sbc hl,bc
	jq nc,explorer_page_down
	add hl,bc
	ld (explorer_cursor_y),hl
	ret
explorer_scroll_up:
	ld hl,(explorer_cursor_y)
	add hl,bc
	or a,a
	sbc hl,bc
	jq z,explorer_page_up
	dec hl
	ld (explorer_cursor_y),hl
	ret
explorer_page_down:
	ld hl,(explorer_dir_offset)
	ld bc,$20
	add hl,bc
	ld a,(hl)
	or a,a
	ret z
	ld (explorer_dir_offset),hl
	ret
explorer_page_up:
	ld hl,(explorer_dir_offset)
	ld bc,$20
	or a,a
	sbc hl,bc
	ret c
	ld (explorer_dir_offset),hl
	ret
explorer_draw_files:
	ld bc,10
	ld (.y_pos),bc
	ld bc,0
explorer_dir_offset:=$-3
	add ix,bc
	push ix
.draw_dirs_loop:
	ld a,(ix)
	or a,a
	jr z,.draw_files
	call .setxy
	bit bos.fd_hidden,(ix+$B)
	jr nz,.next_dir
	bit bos.fd_subdir,(ix+$B)
	call nz,.draw_dir
.next_dir:
	lea ix,ix+$20
	jr .draw_dirs_loop
.draw_files:
	pop ix
.draw_files_loop:
	ld a,(ix)
	or a,a
	ret z
	call .setxy
	bit bos.fd_hidden,(ix+$B)
	jr nz,.next_file
	bit bos.fd_subdir,(ix+$B)
	call z,.draw_file
.next_file:
	lea ix,ix+$20
	jr .draw_files_loop
.setxy:
	ld bc,10
.y_pos:=$-3
	push bc
	ld bc,12
	push bc
	call gfx_SetTextXY
	pop bc,bc
	ret
.draw_dir:
	ld hl,str_SubDir
	push hl
	call gfx_PrintString
	pop bc
.draw_file:
	ld hl,str_FileNameString
	push ix,hl
	call bos.fs_CopyFileName
	call gfx_PrintString
	ld hl,str_Space
	push hl
	call gfx_PrintString
	pop bc
	pop bc,ix
	bit bos.fd_system,(ix+$B)
	call nz,.system
	bit bos.fd_readonly,(ix+$B)
	call nz,.readonly
	bit bos.fd_archive,(ix+$B)
	call nz,.archive
	bit bos.fd_device,(ix+$B)
	call nz,.device
.next_line:
	ld hl,(.y_pos)
	ld bc,9
	add hl,bc
	ld (.y_pos),hl
	ret
.device:
	ld hl,str_Device
	jr .print_hl
.archive:
	ld hl,str_Archive
	jr .print_hl
.readonly:
	ld hl,str_ReadOnly
	jr .print_hl
.system:
	ld hl,str_System
.print_hl:
	push hl
	call gfx_PrintString
	pop bc
	ret

str_System:
	db "SYS ",0
str_ReadOnly:
	db "R/O ",0
str_SubDir:
	db "<DIR" ;flow into next string on purpose
str_CursorString:
	db ">"    ;and again
str_Space:
	db " ",0
str_Archive:
	db "ARC",0
str_Device:
	db "DEV",0


gfx_PrintStrings:
	ld bc,10
	ld (.y_pos),bc
.loop:
	push hl
	ld hl,(hl)
	ld a,(hl)
	or a,a
	jr z,.exit
	ld bc,10
.y_pos:=$-3
	push bc
	ld c,0
	push bc,hl
	call gfx_PrintStringXY
	pop bc,bc,bc
	ld hl,(.y_pos)
	ld bc,10
	add hl,bc
	ld (.y_pos),hl
	pop hl
	inc hl
	inc hl
	inc hl
	jr .loop
.exit:
	pop hl
	ret

load_libload:
	ld hl,libload_name
	push hl
	call bos.fs_OpenFile
	pop bc
	jr c,.notfound
	ld bc,0
	push bc,hl
	call bos.fs_GetClusterPtr
	pop bc,bc
	ld   de,.relocations
	ld   bc,.notfound
	push   bc
;	ld   bc,$aa55aa
	jp   (hl)

.notfound:
	xor   a,a
	inc   a
	ret

.relocations:
	db	$C0, "GRAPHX", $00, 11
gfx_Begin:
	jp 0
gfx_End:
	jp 3
gfx_SetColor:
	jp 6
gfx_FillScreen:
	jp 15
gfx_SetDraw:
	jp 27
gfx_Blit:
	jp 33
gfx_PrintInt:
	jp 45
gfx_PrintString:
	jp 51
gfx_PrintStringXY:
	jp 54
gfx_SetTextXY:
	jp 57
gfx_SetTextBGColor:
	jp 60
gfx_SetTextFGColor:
	jp 63
gfx_SetTextTransparentColor:
	jp 66
gfx_ZeroScreen:
	jp 228

	xor   a,a      ; return z (loaded)
	pop   hl      ; pop error return
	ret

libload_name:
	db   "A:/LibLoad.v21", 0
.len := $ - .

gfx_BlitBuffer:
	ld c,1
	push bc
	call gfx_Blit
	pop bc
	ret

initial_strings:
	dl str_HelloWorld, str_PressToDelete, str_PressToContinue, str_PressToConsole, $FF0000
str_HelloWorld:
	db "Hello World! Welcome to BOS!",0
str_PressToDelete:
	db "Press [del] to uninstall and receive TIOS",0
str_PressToContinue:
	db "Press [enter] to continue",0
str_PressToConsole:
	db "or [clear] to open console",0
str_FailedToLoadLibload:
	db "Failed to load libload.",0
str_CmdExecutable:
	db "CMD",0
.len:=$-.
str_FileNameString:
	db 13 dup 0
