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
; For Paging
L_PAGE_DIR: Descriptor PAGE_DIR_BASE,   1h, DA_DRW | DA_ELEMENT_4K
L_PAGE_TBL: Descriptor PAGE_TBL_BASE, 400h, DA_DRW | DA_ELEMENT_4K

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

; All selectors
SELCODE32  equ   LDT_CODE32 - GDT
SELVIDEO   equ   LDT_VIDEO - GDT
; Paging
SLTR_PAGE_DIR equ L_PAGE_DIR - GDT
SLTR_PAGE_TBL equ L_PAGE_TBL - GDT

; Enable Paging
PAGE_DIR_BASE equ 200000h ; PDT start at 2M
PAGE_TBL_BASE equ 201000h ; PDE start at 2M + 4K

[SECTION .s16]
[BITS 16]
begin:
         mov     ax, cs
         mov     ds, ax
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

         jmp     $

SETUP_PAGING:
         ; initial PDE
         mov     ax, SLTR_PAGE_DIR
         mov     es, ax
         mov     ecx, 400h ; 1024
         xor     edi, edi
         xor     eax, eax
         ; The physical address high 20-bits of PAGE TABLE ENTRY
         ; Start at PAGE_TBL_BASE
         mov     eax, PAGE_TBL_BASE | PG_P | PG_US_U | PG_RW_W
PAGE_DIR_LOOP:
         stosd   ; store eax to es:edi, then edi += 4
         add     eax, 1000h ; 4096
         loop    PAGE_DIR_LOOP

         ; initial PTE
         mov     ax, SLTR_PAGE_TBL
         mov     es, ax
         mov     ecx, 10000h ; 1024 * 1024
         xor     edi, edi
         xor     eax, eax
         mov     eax, PG_P | PG_US_U | PG_RW_W
PAGE_TBL_LOOP:
         stosd
         add     eax, 1000h
         loop    PAGE_TBL_LOOP

         ; Set up CR register and start to paging
         mov     eax, PAGE_DIR_BASE
         mov     cr3, eax
         mov     eax, cr0
         or      eax, 80000000h ; Set PG bit of CR0
         mov     cr0, eax
         jmp     $

SEG_CODE32_LEN   equ  $ - CODE32
times    370 - ($ - $$) db 0
dw       0xaa55
; command reference:
;     nasm protected_mode.asm -o pm.bin
;     dd if=pm.bin of=pm.img bs=512 count=1
