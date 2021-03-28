
	jp boot_os
	jp handle_interrupt
	jp HandleInstruction ;thread control soon (tm)
	jp HandleThreadSpawn ;spawn thread soon (tm)
	jp handle_safeop ;handle_rst20
	jp DONOTHING ;handle_rst28
	jp DONOTHING ;handle_rst30
	jp sys_ExecuteFile
	jp os_GetOSInfo
	jp fs_OpenFile
	jp fs_GetSectorAddress
	jp fs_CheckDirExists
	jp fs_GetPathLastName
	jp fs_CopyFileName
	jp fs_Read
	jp fs_Write
	jp sys_AddHLAndA
	jp sys_AnyKey
	jp sys_FreeAll
	jp sys_GetKey
	jp sys_KbScan
	jp sys_Malloc
	jp sys_MemCmp
	jp sys_MemSet
	jp sys_Mult24x8
	jp sys_WaitKey
	jp sys_WaitKeyCycle
	jp gui_DrawConsoleWindow
	jp gui_Input
	jp gui_NewLine
	jp gui_Print
	jp gui_PrintInt
	jp gui_Scroll
	jp gfx_BlitBuffer
	jp gfx_PrintString
	jp _MemClear
	jp _PushOP1
	jp _PopOP1
	jp _Mov9ToOP1
	jp _CpHLDE
	jp _Mov8b
	jp _ChkFindSym
	jp _LoadDEInd_s
	jp _EnoughMem
	jp _InsertMem
	jp _SetHLUTo0
	jp _PutS
	jp _GetCSC
	jp _NewLine
	jp _ClrScrn
	jp _HomeUp
	jp _ErrMemory
	jp _DrawStatusBar
	jp _os_GetSystemInfo
	jp _UsbPowerVbus
	jp _UsbUnpowerVbus
	jp sys_EraseFlashSector
	jp sys_FlashUnlock
	jp sys_FlashLock
	jp fs_CreateFile
	jp strupper
	jp strlower
	jp fs_AbsPath
	jp fs_MultByBytesPerSector
	jp _LoadLibraryOP1
	jp fs_OpenFileInDir
	jp fs_SetSize
	jp fs_WriteFile
	jp sys_HLToString
	jp fs_DeleteFile
	jp _DelVar
	jp _CreateVar
	jp gui_InputNoClear
	jp fs_InitClusterMap
	jp sys_WriteFlash
	jp sys_WriteFlashA
	jp sys_WriteFlashFull
	jp sys_WriteFlashByteFull
	jp fs_ParentDir
	jp fs_StrToFileEntry
	jp fs_DirList
	jp sys_Free
	jp sys_CallExecuteFile
	jp sys_JumpExecuteFile
	jp sys_InitDevice
	jp sys_DeinitDevice
	jp sys_GetDeviceAddress
	jp sys_ReadDevice
	jp sys_WriteDevice
	jp fs_GetSector
	jp fs_WriteByte
	jp fs_RenameFile
	jp _SetCursorPos
	jp fs_CreateDir
	jp gfx_BufClear
	jp gfx_LcdClear
	jp fs_SanityCheck
	jp sys_SetupOnInterruptHandler
	jp gui_PrintChar

