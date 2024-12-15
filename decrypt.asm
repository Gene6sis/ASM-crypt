bits 64

section .text
    global _start

_start:
    xor r15, r15
    sub rsp, 8                    ; Réserver 8 octets sur la pile pour `block`

; Boucle pour parcourir le message
process_message:
    mov rax, r15                  ; Charger l'index actuel
    cmp rax, message_len          ; Comparer avec la taille totale
    jge exit_program              ; Si l'index dépasse la taille, fin

    ; Charger un bloc de 8 bytes à partir de l'index
    lea rsi, [message + rax]      ; Adresse du bloc actuel
    mov rdx, [rsi]                ; Charger 8 bytes dans rdx
    mov [rsp], rdx                ; Stocker le bloc dans `block` (sur la pile)

decrypt:
    ; Chargement du bloc chiffré dans left et right
    mov r12, [rsp]                ; Charger le bloc chiffré (little-endian)

    ; Charger les parties haute et basse dans left et right
    mov r14d, r12d                ; right = partie basse du bloc (32 bits)
    shr r12, 32                   ; Décaler pour obtenir la partie haute
    mov r13d, r12d                ; left = partie haute du bloc (32 bits)

    ; Décryptage du bloc (8 rounds inverses)
    mov ecx, 0x7

reverse_rounds:
    ; Calcul de la sous-clé : subkey = key ^ (round * 0x1234ABCD)
    mov eax, ecx                  ; subkey = round
    imul eax, eax, 0x1234ABCD     ; subkey = (subkey * 0x1234ABCD)
    xor eax, [key]                ; subkey = subkey ^ key

    ; Feistel déchiffrement
    mov r11d, r14d                ; temp = left

    ; Calculer left = right ^ feistel_function(left, subkey)
    mov esi, r14d
    shl esi, 3
    mov edi, r14d
    shr edi, 29
    or  esi, edi
    ; esi = ((block << 3) | (block >> 29))

    xor r14d, eax
    ; [left] = [left] ^ subkey

    add r14d, esi                 ; [left] = (block ^ subkey) + ((block << 3) | (block >> 29))

    mov eax, r13d
    xor r14d, eax

    ; Mettre à jour right
    mov eax, r11d                 ; r = temp
    mov r13d, eax                 ; right = r

    dec ecx                       ; round--
    jns reverse_rounds            ; si round >= 0 recommence

    ; Recomposer le bloc déchiffré
    shl r13, 32                   ; Décaler right pour le positionner dans la moitié haute
    or r14, r13                   ; Fusionner left et right
    mov [rsp], r14                ; Stocker le bloc déchiffré dans `block` (pile)

; =======================================================================
; Partie 3: Affichage du bloc déchiffré
; =======================================================================
display_decrypted_block:
    mov rdi, 1                    ; stdout
    lea rsi, [rsp]                ; Adresse du bloc sur la pile
    mov rdx, 8                    ; Taille du bloc (8 octets)
    mov rax, 1                    ; syscall write
    syscall
    
    ; Passer au bloc suivant
    add r15, 8                    ; Avancer l'index de 8 bytes
    jmp process_message           ; Retourner dans la boucle

; =======================================================================
; Partie 4: Quitter le programme
; =======================================================================
exit_program:
    add rsp, 8                    ; Libérer l'espace alloué sur la pile
    mov rax, 60                   ; syscall exit
    xor rdi, rdi                  ; Code de retour 0
    syscall

message:
    db 0x8B, 0x13, 0xD3, 0x9A, 0x1C, 0x59, 0x9F, 0x8D,\
    0xB3, 0x9C, 0xE0, 0x50, 0xC2, 0x01, 0x82, 0xCF, \
    0xA4, 0x88, 0x70, 0x86, 0x71, 0x24, 0x5C, 0x73, \
    0xC9, 0x3F, 0x25, 0xCC, 0x9E, 0x2D, 0x0B, 0xA9, \
    0xAA, 0xD9, 0xD4, 0xFE, 0x27, 0x6F, 0x83, 0x63, \
    0x59, 0x19, 0x0A, 0x6C, 0x48, 0x71, 0xD6, 0xF5, \
    0x42, 0xEF, 0xFD, 0x6A, 0x7E, 0x5A, 0xD1, 0xA9, \
    0x4B, 0xCA, 0x82, 0x7A, 0x69, 0xC7, 0x2F, 0xBC, \
    0x55, 0x9B, 0x2F, 0x23, 0x8C, 0xCD, 0x23, 0xD3, \
    0x93, 0xD1, 0xE1, 0x2F, 0x74, 0xD1, 0x46, 0xDD, \
    0x4C, 0x4A, 0xE6, 0x26, 0x54, 0x5B, 0x6C, 0x0B, \
    0xB0, 0xD3, 0x16, 0xB7, 0x70, 0xCB, 0xCF, 0xFD, \
    0xCE, 0xF8, 0x80, 0xE0, 0xD6, 0x35, 0x95, 0x51, \
    0x7D, 0x65, 0x9E, 0xFD, 0x12, 0xC2, 0x67, 0x8C, \
    0x81, 0x1F, 0x9F, 0x2F, 0x54, 0x49, 0x68, 0xFA, \
    0x08, 0x7D, 0x6B, 0x4A, 0x18, 0x2F, 0x75, 0x74, \
    0x4E, 0x6A, 0x8D, 0xF5, 0xF2, 0xF6, 0x79, 0x9E, \
    0x47, 0x03, 0xCD, 0x66, 0x0F, 0xBD, 0x56, 0xF5, \
    0xD1, 0xF8, 0x34, 0x05, 0x6B, 0x88, 0xF8, 0x6E
message_len equ $ - message              ; Longueur du message

key dq 0x7d0a3bba426aa887
