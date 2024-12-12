bits 64

section .data
    key dq 0x123456789ABCDEF0  ; Clé 64 bits
    round_constants dq 0x1234ABCD  ; Constantes de round
    message db 0x24, 0x5B, 0x9D, 0xD2, 0x6B, 0x6F, 0xD9, 0x81, 0xAC, 0x1A, 0x43, 0x10, 0x4A, 0x39, 0x94, 0xAF, 0xE5, 0x4A, 0x3A, 0x8E, 0xAA, 0x76, 0x9B, 0x42, 0xB9, 0x80, 0x9E, 0xD8, 0x05, 0xB7, 0x6A, 0x5B, 0xE8, 0xED, 0xD8, 0x70, 0xB5, 0x7B, 0xED, 0xC2, 0xB2, 0x7F, 0xBC, 0x39, 0xCF, 0x03, 0xB6, 0xB0, 0xFD, 0xC4, 0x0E, 0x32, 0x05, 0xCA, 0x7C, 0x84
    message_len equ $ - message  ; Calculer la taille du message (en bytes)

section .bss
    left resd 1                 ; Espace pour left (32 bits)
    right resd 1                ; Espace pour right (32 bits)
    temp resd 1                 ; Espace temporaire pour échanger les valeurs
    block resq 1                  ; Espace pour stocker un bloc de 8 bytes
    current_index resq 1          ; Index pour parcourir le message


section .text
    global _start

_start:
    ; Initialiser l'index à 0
    xor rax, rax
    mov [current_index], rax
    call process_message

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
    call decrypt

    ; Passer au bloc suivant
    add qword [current_index], 8   ; Avancer l'index de 8 bytes
    jmp process_message            ; Retourner dans la boucle

decrypt:
    ; Chargement du bloc chiffré dans left et right
    call load_block

    ; Décryptage du bloc (8 rounds inverses)
    mov ecx, 7
    call reverse_rounds

    ; Afficher le bloc déchiffré
    call display_decrypted_block

; =======================================================================
; Partie 1: Chargement du bloc dans left et right
; =======================================================================

load_block:
    ; Charger le bloc chiffré dans rax
    mov rax, [block]            ; Charger le bloc chiffré (little-endian)

    ; Inverser les octets dans rax (endianness fix)
    ; bswap rax                   ; rax = 4A 21 2B A5 F5 5B 08 CA en mémoire big-endian

    ; Charger les parties haute et basse dans left et right
    mov dword [left], eax       ; right = partie basse du bloc (32 bits)
    shr rax, 32                 ; Décaler pour obtenir la partie haute
    mov dword [right], eax        ; left = partie haute du bloc (32 bits)
    ret


; =======================================================================
; Partie 2: Décryptage du bloc (8 rounds inverses)
; =======================================================================

reverse_rounds:
    ; Calcul de la sous-clé : subkey = key ^ (round * 0x1234ABCD)
    mov eax, ecx                 ; subkey = round
    imul eax, eax, 0x1234ABCD    ; subkey = (subkey * 0x1234ABCD)
    xor eax, [key]               ; subkey = subkey ^ key

    ; Feistel déchiffrement
    mov ebx, [left]              ; r = left
    mov [temp], ebx              ; temp = r

    ; Calculer left = right ^ feistel_function(left, subkey)
    mov esi, [left]
    shl esi, 3
    mov edi, [left]
    shr edi, 29
    or  esi, edi
    ; esi = ((block << 3) | (block >> 29))

    xor [left], eax
    ; [left] = [left] ^ subkey

    add [left], esi             ; [left] = (block ^ subkey) + ((block << 3) | (block >> 29))

    mov eax, [right]
    xor [left], eax

    ; Mettre à jour right
    mov eax, [temp]              ; r = temp
    mov [right], eax             ; right = r

    dec ecx                      ; round--
    jns reverse_rounds           ; si round >= 0 recommence

    ; Recomposer le bloc déchiffré
    mov eax, [left]              ; l = left
    mov edx, [right]             ; r = right
    shl rdx, 32                  ; Décaler right pour le positionner dans la moitié haute
    or rax, rdx                  ; Fusionner left et right
    mov [block], rax             ; Stocker le bloc déchiffré dans block

    ret


; =======================================================================
; Partie 3: Affichage du bloc déchiffré
; =======================================================================
display_decrypted_block:
    mov rdi, 1                     ; stdout
    lea rsi, [block]               ; Adresse du bloc
    mov rdx, 8                     ; Taille du bloc (8 octets)
    mov rax, 1                     ; syscall write
    syscall
    ret

; =======================================================================
; Partie 4: Quitter le programme
; =======================================================================
exit_program:
    mov rax, 60                    ; syscall exit
    xor rdi, rdi                   ; Code de retour 0
    syscall
    ret
