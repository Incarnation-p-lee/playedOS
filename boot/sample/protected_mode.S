.include "../inc/descriptor.S"
.include "../inc/define.S"

.section .data

# GDT
#                          base                  limit         property
GDT:        Descriptor        0,                    0,                0
LDT_CODE32: Descriptor        0, (SEG_CODE32_LEN - 1),   (DA_C + DA_32)
LDT_VIDEO:  Descriptor  0xB8000,               0xffff,           DA_DRW

.equ GDT_LEN, . - GDT
GDT_PTR:
    .short GDT_LEN - 1
    .int   0

.equ     SEL_CODE32, LDT_CODE32 - GDT
.equ     SEL_VIDEO, LDT_VIDEO - GDT
.short   0xaa55

.section .text
.globl _start
.code16
_start:
         mov      %cs, %ax
         mov      %ax, %ds
         mov      %ax, %es
         mov      %ax, %ss
         mov      $0x100, %sp

         # init 32 bits code section descriptor
         xor      %eax, %eax
         mov      %cs, %ax
         shl      $0x4, %eax
         add      $CODE32, %eax
         mov      $LDT_CODE32, %esi
         mov      %ax, 0x2(%esi)
         shr      $0x10, %eax
         mov      %al, 0x4(%esi)
         mov      %ah, 0x7(%esi)

         # prepare for loading GDT register
         xor      %eax, %eax
         mov      %ds, %ax
         shl      $0x4, %eax
         add      $GDT, %eax
         mov      $GDT_PTR, %esi
         mov      %eax, 0x2(%esi)

         lgdt     (%esi)

         cli

         in       $0x92, %al
         or       $0x2, %al
         out      %al, $0x92

         mov      %cr0, %eax
         or       $0x1, %eax
         mov      %eax, %cr0

         #jmpl     SEL_CODE32:$0
         ljmp      $SEL_CODE32, $0x00

.code32
CODE32:
         mov      $SEL_VIDEO, %ax
         mov      %ax, %gs
         # (x, y) location, start from (16, 16)
         mov      $(80 * 4 + 16) * 2, %edi
         # init
         mov      $0x1, %ah
         xor      %esi, %esi
         mov      msglen, %ecx

printchar:
         # use label as offset without $ in memory access
         mov      bootmsg(%esi), %al
         mov      %ax, %gs:(%edi)
         inc      %esi
         inc      %ah
         #and      $0xf, %ah
         add      $0x2, %edi
         cmp      %ecx, %esi
         jne      printchar
         jmp      .

bootmsg:
         .asciz   "WELCOME TO THE PLAYED OS!"
msglen:
         .int     . - bootmsg
         

.equ     SEG_CODE32_LEN, (. - CODE32)

#.section .data
# command reference:
#     as -o boot.o boot_sample.s
#     ld --oformat binary -Ttext 7c00 -N -o boot
#     ld --oformat binary -Ttext 7c00 -Tdata 7de0 -o boot
