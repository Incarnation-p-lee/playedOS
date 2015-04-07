           org     07c00h
           mov     ax, cs
           mov     ds, ax
           mov     es, ax
           call    dispstring
           jmp     $

dispstring:
           mov     ax, bootmsg
           mov     bp, ax
           mov     cx, 16
           mov     ax, 01301h
           mov     bx, 000ch
           mov     dl, 0
           int     10h
           ret

bootmsg:
           db      "Hello, OS world!"
times      510-($-$$) db 0
dw         0xaa55
# command reference:
#     nasm boot_sample.asm -o boot.bin
#     dd if=./boot/boot.bin of=/dev/fd0 bs=512 count=1
# if use hard disk, of=/dev/sdb instead of sdb1
#     write the boot.bin file to hard disk,
#     not partition(sdb1) of hard disk.
