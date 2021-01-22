
boot_os:
;	DisableMultithreading
	call ti.boot.Set48MHzMode

;	ld bc,64 ;setup gpt2
;	xor a,a
;	ld (ti.mpTmr2Load),bc
;	ld (ti.mpTmr2Load+3),a
;	ld hl,ti.mpTmrCtrl
;	res ti.bTmr2Enable,(hl)
;	set ti.bTmr2Crystal,(hl)
;	set ti.bTmr2Overflow,(hl)
;	inc hl
;	res ti.bTmr2CountUp-8,(hl)
;	dec hl
;	set ti.bTmr2Enable,(hl)

;	ld hl,thread_map
;	ld de,thread_map+1
;	ld (hl),l
;	ld bc,thread_memory_end-thread_map
;	ldir
;	ld hl,os_trapper
;	ld (thread_temp_save),hl
;	ld hl,ti.stackTop - 3
;	ld (thread_temp_save+3),hl

;boot_os_thread:
	call flash_unlock
	ld a,$05 ;set privleged code end address to $050000 (up until and including first filesystem sector)
	out0 ($1F),a
	xor a,a
	out0 ($1D),a
	out0 ($1E),a
	call flash_lock
	ld a,4           ;set wait states to 4
	ld ($E00005),a
	call gfx_SetDefaultFont
	call gfx_Set8bpp
	ld hl,bos_UserMem
	ld (bottom_of_RAM),hl
	ld (top_of_UserMem),hl
	ld hl,top_of_RAM
	ld (free_RAM_ptr),hl
	ld bc,-bos_UserMem
	add hl,bc
	ld (remaining_free_RAM),hl
	or a,a
	sbc hl,hl
	ld (asm_prgm_size),hl
	ld hl,op_stack_top
	ld (op_stack_ptr),hl
	ld de,os_DoNothing
	ld hl,on_interrupt_handler
	ld (hl),$C3 ;jp opcode byte
	inc hl
	ld (hl),de
	xor a,a
	ld (flashStatusByte),a

	call fs_SanityCheck
	ld hl,current_working_dir
	ld bc,'/'
	ld (hl),bc

;	EnableMultithreading
;	SpawnThread os_return, ti.stackTop - 18
;	ei
;os_trapper:
;	ld hl,ti.vRam
;	ld a,l
;.loop:
;	ld b,$FF
;.inner:
;	ld (hl),b
;	inc l
;	djnz .inner
;	jq .loop

os_return:
	call sys_GetKey
	cp a,53
	jq z,os_recovery_menu
	call gfx_Set8bpp
	ld bc,$FF0000
	ld hl,str_StartupProgram
	push bc,hl
	call sys_ExecuteFile
	pop bc,bc ;we should only get back here in a severe error case or if the user opens this menu
os_recovery_menu:
	ld a,$FF
	ld (lcd_bg_color),a
	ld (text_bg),a
	xor a,a
	ld (text_fg),a
	ld hl,string_os_recovery_menu
	call gui_DrawConsoleWindow
.keywait:
	call sys_WaitKeyCycle
	cp a,55
	jq z,.reset_fs
	cp a,54
	jq z,.turn_off
	cp a,9
	jq z,.attempt_recovery
	cp a,56
	jq z,.uninstall
	cp a,15
	jq z,boot_os
	
	jq .keywait

.reset_fs:
	ld hl,string_press_enter_confirm
	call gui_Print
	call sys_WaitKeyCycle
	cp a,9
	jq nz,os_recovery_menu
	call fs_Format
	jq boot_os

.turn_off:
	ld a,50 ;delay 500ms
	call ti.DelayTenTimesAms
	call ti.boot.TurnOffHardware
	ei
	halt
	nop
	rst $00

.attempt_recovery:
	call fs_SanityCheck
	jq os_recovery_menu

.uninstall:
	ld hl,string_press_enter_confirm
	call gui_Print
	call sys_WaitKeyCycle
	cp a,9
	jq nz,os_recovery_menu
	ld hl,bos_UserMem
	push hl ;return to usermem which immediately tells the calc to invalidate the OS and reboot
	ld (hl),$CD
	inc hl
	ld de,ti.MarkOSInvalid
	ld (hl),de
	inc hl
	inc hl
	inc hl
	ld (hl),$CF ;rst $08
	ld hl,flashStatusByte
	set bKeepFlashUnlocked,(hl)
	call sys_FlashUnlock
	ld a,2
	jq sys_EraseFlashSector ;erase first OS sector, bootcode will handle the rest

handle_interrupt:
	ld bc,$5015
	in a,(bc)
	jr z,handle_interrupt_2
	ld c,$09
	rla
	rla
	jq c,high_bit_6_int
	rla
	jq c,high_bit_5_int
	rla
	jq c,high_bit_4_int
	rla
	jq c,high_bit_3_int
	ld a,$FF
	out (bc),a
	jq return_from_interrupt
handle_interrupt_2:
	ld c,$14
	in a,(bc)
	jr z,return_from_interrupt
	ld c,$08
	rra
	jq c,low_bit_0_int
	rra
	jq c,low_bit_1_int
	rra
	jq c,low_bit_2_int
	rra
	jq c,low_bit_3_int
	rra
	jq c,low_bit_4_int
	ld a,$FF
	out (bc),a
return_from_interrupt:
	ld iy,$D00080
	res 6,(iy+$1B)
	pop hl
	pop iy,ix
	exx
	exaf
	ei
	reti

low_bit_0_int:
	ld a,1 shl 0
	out (bc),a
	ld c,4
	in a,(bc)
	res 0,a
	out (bc),a
	jq on_interrupt_handler
low_bit_1_int:
	ld a,1 shl 1
	out (bc),a
	ld c,4
	in a,(bc)
	res 1,a
	out (bc),a
	jq return_from_interrupt
low_bit_2_int: ;gpt2 interrupt (used for "thread" switching) (soon :tm:)
	ld a,1 shl 2
	out (bc),a
	ld c,4
	in a,(bc)
	res 2,a
	out (bc),a
	jq return_from_interrupt
;	jq th_HandleInterrupt
low_bit_3_int:
	ld a,1 shl 3
	out (bc),a
	ld c,4
	in a,(bc)
	res 3,a
	out (bc),a
	jq return_from_interrupt
low_bit_4_int: ;OS timer interrupt
	ld a,1 shl 4
	out (bc),a
	ld c,4
	in a,(bc)
	res 4,a
	out (bc),a
	jq return_from_interrupt
high_bit_3_int:
	ld a,1 shl 3
	out (bc),a
	ld c,5
	in a,(bc)
	res 3,a
	out (bc),a
	jq return_from_interrupt
high_bit_4_int:
	ld a,1 shl 4
	out (bc),a
	ld c,5
	in a,(bc)
	res 4,a
	out (bc),a
	jq return_from_interrupt
high_bit_5_int: ;USB interrupt
	ld a,1 shl 5
	out (bc),a
	ld c,5
	in a,(bc)
	res 5,a
	out (bc),a
	jq return_from_interrupt
high_bit_6_int:
	ld a,1 shl 6
	out (bc),a
	ld c,5
	in a,(bc)
	res 6,a
	out (bc),a
	jq return_from_interrupt


handle_safeop:
	ld (ScrapMem),hl
	ld hl,safeRAM
	or a,a
	sbc hl,de
	jq c,.fail
	ld hl,ti.vRam + 320*240*2 - safeRAM
	or a,a
	sbc hl,de
	jq c,.fail
	pop hl
	push hl
	push af
	ld a,(hl)
	or a,a
	jq z,._ldi_0
	dec a
	jq z,._ldi
.done:
	pop af
.fail:
	ld hl,(ScrapMem)
	ret
._ldi_0:
	ld (de),a
	inc de
	jq .done
._ldi:
	ld hl,(ScrapMem)
	ldi
	pop af
	ret

os_GetOSInfo:
	ld hl,string_os_info
os_DoNothing:
	ret

