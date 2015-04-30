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
LDT_DATA:   Descriptor  0A00000h,             0ffffh,        DA_DRW
LDT_CODE16: Descriptor        0h,             0ffffh,  DA_C + DA_32
LDT_NORMAL: Descriptor        0h,             0ffffh,        DA_DRW

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
SELDATA    equ   LDT_DATA - GDT
SELCODE16  equ   LDT_CODE16 - GDT
SELNORMAL  equ   LDT_NORMAL - GDT

[SECTION .s16]
[BITS 16]
begin:
         mov     ax, cs
         mov     ds, ax
         mov     es, ax
         mov     ss, ax
         mov     sp, 100h
         mov     [GOBACK_TO_REAL + 3], ax

         ; init 16 bits code section descripor
         xor     eax, eax
         mov     ax, cs
         shl     eax, 4
         add     eax, CODE16
         mov     word [LDT_CODE16 + 2], ax
         shr     eax, 16
         mov     byte [LDT_CODE16 + 4], al
         mov     byte [LDT_CODE16 + 7], ah

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
         mov     ax, SELDATA
         mov     ds, ax
         ; (x, y) location
         mov     ebx,0
         mov     ecx,8
         mov     edi, (80 * 1 + 2) * 2
         call    PRINT8BY
         mov     ecx,8
         call    STORE8BY
         mov     ecx,8
         mov     edi, (80 * 3 + 2) * 2
         call    PRINT8BY

         nop
         nop
         ;prepare back to real
         jmp     SELCODE16:0

STORE8BY:
         mov     ah, 0
loop1:   mov     [ds:ebx], ah
         inc     ebx
         inc     ah
         dec     ecx
         jnz     loop1
         mov     ebx,0
         ret

         ; use ecx as count, ebx as base register 
PRINT8BY:
         mov     ah, 0ch
loop:    mov     al, [ds:ebx]
         add     al, CHAROFF
         mov     [gs:edi], ax
         add     edi, 2
         inc     ebx
         dec     ecx
         jnz     loop
         mov     ebx,0
         ret

[BITS 16]
CODE16:
         ; mov     ax, SELNORMAL
         ; mov     ds, ax
         ; mov     es, ax
         ; mov     fs, ax
         ; mov     gs, ax
         ; mov     ss, ax

         mov     eax, cr0
         and     al, 11111110b
         mov     cr0, eax
GOBACK_TO_REAL:
         jmp     0:REAL_ENTRY

REAL_ENTRY:
         mov     ax, cs
         mov     ds, ax
         mov     es, ax
         mov     ss, ax

         in      al, 92h
         and     al, 11111101b
         out     92h, al

         sti

         mov     ax, 4c00h
         int     21h


SEG_CODE32_LEN   equ  $ - CODE32
CHAROFF  equ     '0'
times    326 - ($ - $$) db 0
dw       0xaa55
; command reference:
;     nasm protected_mode.asm -o pm.bin
;     dd if=pm.bin of=pm.img bs=512 count=1
