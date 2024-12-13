bits 64


section .bss
    block resq 1                    ; Espace pour stocker un bloc de 8 bytes


section .text
    global _start

_start:
    ;r15d current index
    ;r14d [left]
    ;r13d [right]
    ;r11d [temp]

    ; Initialiser l'index à 0
    xor r15, r15

; Boucle pour parcourir le message
process_message:
    mov rax, r15                    ; Charger l'index actuel
    cmp rax, message_len            ; Comparer avec la taille totale
    jge exit_program                ; Si l'index dépasse la taille, fin

    ; Charger un bloc de 8 bytes à partir de l'index
    lea rsi, [message + rax]       ; Adresse du bloc actuel
    mov rdx, [rsi]                 ; Charger 8 bytes dans rdx

decrypt:
    ; Chargement du bloc chiffré dans left et right

    ; Charger les parties haute et basse dans left et right
    mov r14d, edx                 ; right = partie basse du bloc (32 bits)
    shr rdx, 32                  ; Décaler pour obtenir la partie haute
    mov r13d, edx                 ; left = partie haute du bloc (32 bits)

    ; Décryptage du bloc (8 rounds inverses)
    mov ecx, 0x7

reverse_rounds:
    ; Calcul de la sous-clé : subkey = key ^ (round * 0x1234ABCD)
    mov eax, ecx                 ; subkey = round
    imul eax, eax, 0x1234ABCD    ; subkey = (subkey * 0x1234ABCD)
    xor eax, [key]               ; subkey = subkey ^ key

    ; Feistel déchiffrement
    mov r11d, r14d                 ; temp = left

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

    dec ecx                      ; round--
    jns reverse_rounds           ; si round >= 0 recommence

    ; Recomposer le bloc déchiffré
    shl r13, 32                  ; Décaler right pour le positionner dans la moitié haute
    or r14, r13                  ; Fusionner left et right
    mov rax, r14

    ;rax = l + r

; =======================================================================
; Partie 3: Affichage du bloc déchiffré
; =======================================================================
display_decrypted_block:
    mov rdi, 1                     ; stdout
    lea rsi, rax          ; Charger l'adresse dans rsi
    mov rdx, 8                     ; Taille du bloc (8 octets)
    mov rax, 1                     ; syscall write
    syscall
    
    ; Passer au bloc suivant
    add r15, 8   ; Avancer l'index de 8 bytes
    jmp process_message            ; Retourner dans la boucle

; =======================================================================
; Partie 4: Quitter le programme
; =======================================================================
exit_program:
    mov rax, 60                    ; syscall exit
    xor rdi, rdi                   ; Code de retour 0
    syscall
    ret

message:
    db 0x24, 0x5B, 0x9D, 0xD2, 0x6B, 0x6F, 0xD9, 0x81, 0xAC, 0x1A, 0x43, 0x10, 0x4A, 0x39, 0x94, 0xAF, 0xE5, 0x4A, 0x3A, 0x8E, 0xAA, 0x76, 0x9B, 0x42, 0xB9, 0x80, 0x9E, 0xD8, 0x05, 0xB7, 0x6A, 0x5B, 0xE8, 0xED, 0xD8, 0x70, 0xB5, 0x7B, 0xED, 0xC2, 0xB2, 0x7F, 0xBC, 0x39, 0xCF, 0x03, 0xB6, 0xB0, 0xFD, 0xC4, 0x0E, 0x32, 0x05, 0xCA, 0x7C, 0x84
message_len equ $ - message              ; Longueur du message

key dq 0x123456789ABCDEF0       ; Clé 64 bits
round_constants dq 0x1234ABCD