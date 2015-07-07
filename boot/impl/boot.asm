%include "../inc/descriptor.asm"
%include "../inc/define.asm"

org     7c00h
        jmp  0:begin
; -----------------------------------------------------------------------
; Const variable
STACK_BASE  EQU  1000000h       ; 16M
DATA_BASE   EQU  2000000h       ; 32M
STACK_SIZE  EQU     8000h       ; 32K
STACK_LIMIT EQU  1008000h       ; 16M + 32K
DATA_SIZE   EQU   100000h       ;  1M

; GDT and LDT
; Descriptor                  base               limit        property
[SECTION .gdt]
GDT:        Descriptor           0,                  0,              0
LDT_CODE32: Descriptor           0, SEG_CODE32_LEN - 1,   DA_C + DA_32
LDT_VIDEO:  Descriptor     0B8000h,             0ffffh,         DA_DRW
LDT_STACK:  Descriptor  STACK_BASE,     STACK_SIZE - 1, DA_DRWD + DA_B
LDT_DATA:   Descriptor   DATA_BASE,      DATA_SIZE - 1,         DA_DRW

GDTLEN EQU $ - GDT
GDTPTR DW  GDTLEN - 1
       DD  0

; Selectors
SLT_CODE32 EQU LDT_CODE32 - GDT
SLT_VIDEO  EQU LDT_VIDEO - GDT
SLT_STACK  EQU LDT_STACK - GDT
SLT_DATA   EQU LDT_DATA - GDT
; -----------------------------------------------------------------------


; Real mode code
[SECTION .s16]
[BITS 16]
begin:
         mov     ax, cs
         mov     ds, ax

         ; init 32 bits code section descriptor
         xor     eax, eax
         mov     ax, cs
         shl     eax, 4
         add     eax, code32
         mov     word [LDT_CODE32 + 2], ax
         shr     eax, 16
         mov     byte [LDT_CODE32 + 4], al
         mov     byte [LDT_CODE32 + 7], ah

         ; prepare for loading gdtr
         xor     eax, eax
         mov     ax, ds
         shl     eax, 4
         add     eax, GDT
         mov     dword [GDTPTR + 2], eax

         lgdt    [GDTPTR]

         cli

         in      al, 92h
         or      al, 10b
         out     92h, al

         mov     eax, cr0
         or      eax, 1
         mov     cr0, eax

         jmp     dword SLT_CODE32:0

; protected mode code
[SECTION .s32]
[BITS 32]
code32:
         mov     ax, SLT_VIDEO
         mov     gs, ax
         mov     ax, SLT_STACK
         mov     ss, ax
         mov     esp, STACK_BASE
         mov     ax, SLT_DATA
         mov     ds, ax

         mov     eax, 012345678h
         push    eax
         pop     ebx
         mov     [ds:0], ebx

         ; set arg1 and arg2
         mov     edi, 0
         mov     esi, (80 * 1 + 1) * 2
         call    PRINT_DWORD
         jmp     $

         ; ---------------------------------
         ; ; PREPARE DEBUG CHAR
         ; mov     ax, SLT_VIDEO
         ; mov     gs, ax
         ; mov     bh, 0ch
         ; mov     bl, 'B'
         ; mov     esi, (80 * 1 + 1) * 2
         ; mov     [gs:esi], bx
         ; jmp     $
         ; ; END OF PREPARE DEBUG CHAR
         ; ---------------------------------

%include "../inc/print_dword.asm"

SEG_CODE32_LEN EQU $ - code32
times    370 - ($ - $$) db 0
dw       0xaa55
; command reference:
;     nasm protected_mode.asm -o pm.bin
;     dd if=pm.bin of=pm.img bs=512 count=1

