%include "../inc/descriptor.asm"
%include "../inc/define.asm"

org     7c00h
        jmp  begin

; GDT
;                       base               limit       property
[SECTION .gdt]
GDT:        Descriptor         0,                  0,             0
LDT_CODE32: Descriptor         0, SEG_CODE32_LEN - 1,  DA_C + DA_32
LDT_VIDEO:  Descriptor   0B8000h,             0ffffh,        DA_DRW

GDTLEN     equ   $ - GDT
GDTPTR     dw    GDTLEN - 1
           dd    0
; GDT, global descriptor table, each for one cpu core
;     defined the characteristics of memory areas used during execution.
;     8-bytes for each table entry. (bytes)
;     seg base address, limit, property..
;     
;     
; GDTR, global descriptor table register, 6-bytes.
;     format: (bytes)
;     2 - GDT table lenght
;     4 - physcial base address of GDT

SELCODE32  equ   LDT_CODE32 - GDT
SELVIDEO   equ   LDT_VIDEO - GDT

[SECTION .s16]
[BITS 16]
begin:
         mov     ax, cs
         mov     ds, ax
         mov     es, ax
         mov     ss, ax
         mov     sp, 100h

         ; init 32 bits code section descriptor
         xor     eax, eax
         mov     ax, cs
         shl     eax, 4
         add     eax, CODE32
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

         jmp     dword SELCODE32:0

[SECTION .s32]
[BITS 32]
CODE32:
         mov     ax, SELVIDEO
         mov     gs, ax
         ; (x, y) location
         mov     edi, (80 * 1 + 2) * 2
         ; print PAN LI from (1, 2)
         mov     ah, 0ch
         mov     al, 'P'
         mov     [gs:edi], ax
         mov     al, 'A'
         add     edi, 2
         mov     [gs:edi], ax
         mov     al, 'N'
         add     edi, 2
         mov     [gs:edi], ax
         mov     al, ' '
         add     edi, 2
         mov     [gs:edi], ax
         mov     al, 'L'
         add     edi, 2
         mov     [gs:edi], ax
         mov     al, 'I'
         add     edi, 2
         mov     [gs:edi], ax
         jmp     $

SEG_CODE32_LEN   equ  $ - CODE32
times    382 - ($ - $$) db 0
dw       0xaa55
; command reference:
;     nasm protected_mode.asm -o pm.bin
;     dd if=pm.bin of=pm.img bs=512 count=1
