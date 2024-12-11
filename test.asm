bits 64

section .data
    message db 0x24, 0x5B, 0x9D, 0xD2, 0x6B, 0x6F, 0xD9, 0x81, \
             0xAC, 0x1A, 0x43, 0x10, 0x4A, 0x39, 0x94, 0xAF, \
             0xE5, 0x4A, 0x3A, 0x8E, 0xAA, 0x76, 0x9B, 0x42, \
             0xB9, 0x80, 0x9E, 0xD8, 0x05, 0xB7, 0x6A, 0x5B, \
             0xE8, 0xED, 0xD8, 0x70, 0xB5, 0x7B, 0xED, 0xC2, \
             0xB2, 0x7F, 0xBC, 0x39, 0xCF, 0x03, 0xB6, 0xB0, \
             0x7C, 0x1C, 0x2C, 0x77, 0xA2, 0x5D, 0xBF, 0x55
    message_len equ $ - message  ; Calculer la taille du message (en bytes)

section .bss
    block resq 1                  ; Espace pour stocker un bloc de 8 bytes
    current_index resq 1          ; Index pour parcourir le message

section .text
    global _start
_start:
    ; Initialiser l'index à 0
    xor rax, rax
    mov [current_index], rax

; Boucle pour parcourir le message
process_message:
    mov rax, [current_index]       ; Charger l'index actuel
    cmp rax, message_len           ; Comparer avec la taille totale
    jge exit_program                ; Si l'index dépasse la taille, fin

    ; Charger un bloc de 8 bytes à partir de l'index
    lea rsi, [message + rax]       ; Adresse du bloc actuel
    mov rdx, [rsi]                 ; Charger 8 bytes dans rdx
    mov [block], rdx               ; Stocker le bloc dans `block`

    ; [DEBUG] Afficher le bloc (optionnel)
    call display_block

    ; Passer au bloc suivant
    add qword [current_index], 8   ; Avancer l'index de 8 bytes
    jmp process_message            ; Retourner dans la boucle

; =======================================================================
; Sous-programmes
; =======================================================================

display_block:
    ; Afficher le bloc de 8 bytes
    mov rax, 1                     ; syscall write
    mov rdi, 1                     ; stdout
    lea rsi, [block]               ; Adresse du bloc
    mov rdx, 8                     ; Taille du bloc (8 bytes)
    syscall
    ret

exit_program:
    mov rax, 60                    ; syscall exit
    xor rdi, rdi                   ; Code de retour 0
    syscall
