; Assume little-endian here.
; Calling conversion: edi(arg1), esi(arg2)
; void PRINT_DWORD(char *mem, char *video);
PRINT_DWORD:

         ; ---------------------------------
         ; PREPARE DEBUG CHAR
         ; mov     ax, SLT_VIDEO
         ; mov     gs, ax
         ; mov     bh, 0ch
         ; mov     bl, 'B'
         ; mov     esi, (80 * 1 + 1) * 2
         ; mov     [gs:esi], bx
         ; jmp     $
         ; ; END OF PREPARE DEBUG CHAR
         ; ---------------------------------
         push    eax
         push    ebx
         push    ecx
         push    edx

         mov     ebx, [ds:edi]
         mov     ecx, 32
LOOP_BYTE:
         sub     ecx, 8
         mov     edx, ebx
         shr     edx, cl
         call    PRINT_BYTE
         cmp     ecx, 0
         jnz     LOOP_BYTE

         pop     edx
         pop     ecx
         pop     ebx
         pop     eax
         ret

         ; byte stored in edx low 8 bits
PRINT_BYTE:
         mov     al, dl
         shr     al, 4
         call    PRINT_NIBBER
         mov     al, dl
         and     al, 0fh
         call    PRINT_NIBBER
         ret

PRINT_NIBBER:
         cmp     al, 9
         jle     _TO_0_9_
         add     al, 65 - 10
         jmp     PRINT
_TO_0_9_:
         add     al, 48
         mov     ah, 0ch
PRINT:
         mov     [gs:esi], ax
         add     esi, 2
         ret

