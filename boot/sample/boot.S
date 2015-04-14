.section .text
.globl _start
.code16
_start:
           mov     %cs, %ax
           mov     %ax, %ds
           mov     %ax, %es

           mov     $bootmsg, %bp
           mov     msg_len, %cx
           mov     $0x13, %ah
           mov     $0x1, %al
           mov     $0x01, %bl
           mov     $0x0, %bh
           # location (dh, dl)
           mov     $2, %dl
           mov     $2, %dh
           int     $0x10

           jmp     .
bootmsg:
           .asciz      "Hello, Incarnation P. Lee, this is the OS world!"
msg_len:
           .int        . - bootmsg
           .org        0x1fe, 0x90
           .short      0xaa55
# command reference:
#     as -o boot.o boot_sample.s
#     ld --oformat binary -Ttext 7c00 -N -o boot
#     dd if=./boot/boot.bin of=/dev/fd0 bs=512 count=1
#     dd if=./boot/boot.bin of=boot.img bs=512 count=1
# if use hard disk, of=/dev/sdb instead of sdb1
#     write the boot.bin file to hard disk,
#     not partition(sdb1) of hard disk.
