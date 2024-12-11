bits 64

global _start

_start:
    mov eax, 1
    mov ebx, 42
    mov ebx, 12
    int 0x80

