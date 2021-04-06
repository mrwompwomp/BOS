
	jq cmd_exe_main
	db "FEX",0
cmd_exe_main:
	ld hl,-13
	call ti._frameset
	xor a,a
	sbc hl,hl
	ld (ix-10),a
	ld (ix-6),hl
	ld (ix-9),hl
	ld hl,(ix+6)
	ld a,(hl)
	or a,a
	jq z,cmd_no_cmd_args

	cp a,'-'
	jq nz,cmd_execute_next_line ;if first argument isn't a flag
	inc hl
	ld a,(hl)
	inc hl
	inc hl
	cp a,'h'
	jq z,cmd_print_help_info
	ld (ix-10),a
	cp a,'a'
	jq z,cmd_execute_next_line
	cp a,'i'
	jq z,cmd_execute_next_line

cmd_print_help_info:
	ld hl,cmd_help_info
	call bos.gui_PrintLine
	jq cmd_exit_retzero

;execute argument as if from command line if argument passed
cmd_execute_next_line:
	push hl
	ld bc,$A
	push bc,hl
	call ti._strchr
	pop bc,bc
	add hl,bc
	xor a,a
	sbc hl,bc
	jq z,.dontwritetonull
	ld (hl),a
	inc hl
.dontwritetonull:
	ld (ix-13),hl
	pop hl
	ld a,(hl)
	cp a,'#'
	jq z,.dontexit ;only execute if line not commented
	call execute_program_string
	ld a,(ix-10)
	or a,a
	jq nz,.dontexit
	ld hl,(ix-9)
	add hl,bc
	or a,a
	sbc hl,bc
	jq nz,cmd_exit
.dontexit:
	ld hl,(ix-13)
	add hl,bc
	or a,a
	sbc hl,bc
	jq nz,cmd_execute_next_line ;execute next line if newline is present
	ld a,(ix-10)
	cp a,'i'
	jq nz,.returnerrorcode
	sbc hl,hl
	jq cmd_exit

;exit returning last executable's error code
.returnerrorcode:
	ld hl,(ix-9)
	jq cmd_exit

cmd_no_cmd_args:
	ld hl,bos.current_working_dir
	call bos.gui_DrawConsoleWindow
	ld hl,256
	push hl
	call bos.sys_Malloc
	pop bc
	jq c,cmd_exit
	ld (ix-3),hl
	ld bc,256
	call bos._MemClear
enter_input_clear:
	ld hl,bos.InputBuffer
	ld bc,256
	call bos._MemClear
	jq enter_input
recall_last:
	ld hl,(ix-3)
	add hl,bc
	or a,a
	sbc hl,bc
	jq z,enter_input
	push hl
	call ti._strlen
	add hl,bc
	or a,a
	sbc hl,bc
	ex (sp),hl
	pop bc
	jq z,enter_input
	ld de,bos.InputBuffer
	ldir
enter_input:
	ld bc,255
	push bc
	ld bc,bos.InputBuffer
	push bc
	call bos.gui_InputNoClear
	pop hl,bc
	or a,a
	jq z,cmd_exit_retzero
	cp a,12
	jq z,recall_last
	cp a,10
	jq z,enter_input
	ld a,(hl)
	or a,a
	jq z,enter_input ;don't execute if the input is null
	ld de,(ix-3)
	ld bc,256
	push hl
	ldir
	pop hl
	call execute_program_string
	jq enter_input_clear

execute_program_string:
	push hl
	call ti._strlen ;get length of program+arg string
	ex (sp),hl
	pop bc

	push hl
	ld a,' ' ;locate first ' ' in string to separate program from args
	cpir
	jq nz,.noargs
	dec hl
	ld (hl),0 ;replace the space with null to null-terminate the file name
	inc hl ;bypass the space that is now null
.noargs:
	ex (sp),hl ;store args, restore path
	push hl ;push path
	call bos.fs_OpenFile
	jq c,.system_exe
.execute:
	call bos.sys_ExecuteFile
	ld (ix-9),hl
	pop bc,bc
	ld hl,(ix-6)
	push hl
	call bos.sys_Free
	pop bc
	or a,a
	sbc hl,hl
	ld (ix-6),hl
	ld hl,(ix-9)
	ld a,(ix-7)
	or a,h
	or a,l
	ret z ;don't print anything if program returned 0
	ld a,(ix-10)
	or a,a
	ret nz ;don't print anything if we're ignoring exit codes
	call bos.gfx_BlitBuffer
	xor a,a
	ld (bos.curcol),a
	ld hl,str_ProgramFailedWithCode
	call bos.gui_PrintString
	ld hl,(ix-9)
	call bos.gui_PrintInt
	call bos.gui_NewLine
	jp bos.gfx_BlitBuffer
.system_exe:
	call ti._strlen
	ex (sp),hl
	pop bc
	push bc,hl
	ld hl,str_system_path.len+1
	add hl,bc
	push hl
	call bos.sys_Malloc
	ex hl,de
	pop bc,hl,bc
	jq c,cmd_exit
	push de,bc,hl
	ld hl,str_system_path
	ld bc,str_system_path.len
	ldir
	pop hl,bc
	ldir
	xor a,a
	ld (de),a
	call bos.fs_OpenFile
	jq nc,.execute

	pop bc,bc
	ld a,(ix-10)
	cp a,'i'
	ret z ;return if ignoring errors
;if we got here then we failed to locate the executable
	ld (ix-9),hl
	ld hl,str_CouldNotLocateExecutable
	jp bos.gui_Print

cmd_exit_retzero:
	or a,a
	sbc hl,hl
cmd_exit:
	push af,hl
	ld hl,(ix-3)
	push hl
	call bos.sys_Free
	pop bc
	pop hl,af
	ld sp,ix
	pop ix
	ret

cmd_help_info:
	db " cmd -h",$A,$9,"show this info",$A
	db " cmd commands",$A,$9,"run command(s) but exit if one returns an error",$A
	db " cmd -a commands",$A,$9,"run all commands(s) regardless of error codes",$A,0
	db " cmd -i commands",$A,$9,"run commands(s), ignoring all errors",$A

str_system_path:
	db "/bin/"
.len:=$-.
str_ProgramFailedWithCode:
	db "Error Code ",0
str_CouldNotLocateExecutable:
	db $9,"Could not locate executable",$A,0
