#
# Descriptor base, limit, attr
#     base:  dd
#     limit: dd low 20 bits available
#     attr:  dw low nibble of higher byte always 0
#
.macro Descriptor base, limit, attr
       .word \limit & 0xFFFF
       .word \base & 0xFFFF
       .byte (\base >> 16) & 0xFF 
       .word ((\limit >> 8) & 0xF00) | (\attr & 0xF0FF)
       .byte (\base >> 24) & 0xFF
.endm
