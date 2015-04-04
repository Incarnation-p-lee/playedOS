.code16
.section .text
.globl _start
_start:
           mov     %cs, %ax
           mov     %ax, %ds
           mov     %ax, %es
           call    dispstring
           jmp     _start

dispstring:
           mov     bootmsg, %ax
           mov     %ax, %bp
           mov     $0x10, %cx
           mov     $0x1301, %ax
           mov     $0x00c, %bx
           mov     $0, %dl
           int     $0x10
           ret
.section .data
bootmsg:
           .ascii      "Hello, OS world!"
           .short      0xaa55
# command reference:
#     as -o boot.o boot_sample.s
#     ld --oformat binary -Ttext 7c00 -Tdata 7dee -o boot
#     dd if=./boot/boot.bin of=/dev/fd0 bs=512 count=1
# if use hard disk, of=/dev/sdb instead of sdb1
#     write the boot.bin file to hard disk,
#     not partition(sdb1) of hard disk.
