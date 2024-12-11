bits 64

section .data
    key dq 0x123456789ABCDEF0  ; Clé 64 bits
    round_constants dq 0x1234ABCD  ; Constantes de round
    block dq 0x4A212BA5F55B08CA  ; Bloc chiffré (exemple de "coucou")

section .bss
    left resd 1                 ; Espace pour left (32 bits)
    right resd 1                ; Espace pour right (32 bits)
    temp resd 1                 ; Espace temporaire pour échanger les valeurs

section .text
    global _start
_start:
    ; Chargement du bloc chiffré dans left et right
    call load_block

    ; Décryptage du bloc (8 rounds inverses)
    call decrypt_block

    ; Afficher le bloc déchiffré
    call display_decrypted_block

    ; Quitter le programme
    call exit_program

; =======================================================================
; Partie 1: Chargement du bloc dans left et right
; =======================================================================

load_block:
    ; Charger le bloc chiffré dans rax
    mov rax, [block]            ; Charger le bloc chiffré (little-endian)

    ; Inverser les octets dans rax (endianness fix)
    bswap rax                   ; rax = 4A 21 2B A5 F5 5B 08 CA en mémoire big-endian

    ; Charger les parties haute et basse dans left et right
    mov dword [left], eax       ; right = partie basse du bloc (32 bits)
    shr rax, 32                 ; Décaler pour obtenir la partie haute
    mov dword [right], eax        ; left = partie haute du bloc (32 bits)
    ret


; =======================================================================
; Partie 2: Décryptage du bloc (8 rounds inverses)
; =======================================================================

decrypt_block:
    ; Initialiser le compteur de round (8 rounds)
    mov ecx, 7                  ; round = 7

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
