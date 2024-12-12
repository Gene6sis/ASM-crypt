#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>

#define BLOCK_SIZE 8
#define MAX_MESSAGE_LEN 1024
#define SUBKEY 0x1234ABCD

// Génération d'une clé aléatoire
uint64_t generate_random_key() {
    int fd = open("/dev/urandom", O_RDONLY);
    if (fd == -1) {
        perror("open");
        exit(EXIT_FAILURE);
    }

    uint64_t key;
    if (read(fd, &key, sizeof(key)) != sizeof(key)) {
        perror("read");
        close(fd);
        exit(EXIT_FAILURE);
    }

    close(fd);
    return key;
}

// Fonction de mélange
uint32_t feistel_function(uint32_t block, uint32_t subkey) {
    // printf("\tblock = %08X\n", block);
    // printf("\tblock << 3 = %08X\n", (block << 3));
    // printf("\tblock >> 29 = %08X\n", (block >> 29));
    // printf("\t((block << 3) | (block >> 29)) = %08X\n", ((block << 3) | (block >> 29)));
    // printf("\tblock ^ subkey = %08X\n", block ^ subkey);
    // printf("\tres = %08X\n", (block ^ subkey) + ((block << 3) | (block >> 29)));
    
    
    return (block ^ subkey) + ((block << 3) | (block >> 29));
}

// Chiffrement d'un seul bloc
void feistel_encrypt_block(uint32_t *left, uint32_t *right, uint64_t key) {
    // printf("Begin: left = %08X, right = %08X\n", *left, *right);
    for (int round = 0; round < 8; round++) {
        uint32_t subkey = key ^ (round * SUBKEY);
        // printf("In round %d: subkey : %08X\n", round, subkey);
        uint32_t temp = *right;
        *right = *left ^ feistel_function(*right, subkey);
        *left = temp;
        // printf("After round %d: left = %08X, right = %08X\n", round, *left, *right);
    }
}

// Déchiffrement d'un seul bloc
void feistel_decrypt_block(uint32_t *left, uint32_t *right, uint64_t key) {
    // printf("Begin: left = %08X, right = %08X\n", *left, *right);
    for (int round = 7; round >= 0; round--) {
        uint32_t subkey = key ^ (round * SUBKEY);
        // printf("In round %d: subkey : %08X\n", round, subkey);
        uint32_t temp = *left;
        *left = *right ^ feistel_function(*left, subkey);
        *right = temp;
        // printf("After round %d: left = %08X, right = %08X\n", round, *left, *right);
    }
}

// Padding pour les blocs
size_t add_padding(uint8_t *message, size_t len, size_t block_size) {
    size_t padding_len = block_size - (len % block_size);
    for (size_t i = 0; i < padding_len; i++) {
        message[len + i] = (uint8_t)0;
    }
    return len + padding_len;
}

// Suppression du padding après déchiffrement
size_t remove_padding(uint8_t *message, size_t len) {
    uint8_t padding_len = message[len - 1];
    return len - padding_len;
}

// Chiffrement d'un message complet
void feistel_encrypt_message(uint8_t *message, size_t len, uint64_t key) {
    printf("Encrypt : \n");
    for (size_t i = 0; i < len; i += BLOCK_SIZE) {
        uint32_t *left = (uint32_t *)&message[i];
        uint32_t *right = (uint32_t *)&message[i + 4];
        for (size_t j = 0; j < BLOCK_SIZE; j += 1) {
            printf("%02x", message[i+j]);
        }
        printf(" -> ");
        // printf("%ld : Message déchiffré : %08hhn\n", i, &message[i]);
        feistel_encrypt_block(left, right, key);
        for (size_t j = 0; j < BLOCK_SIZE; j += 1) {
            printf("%02x", message[i+j]);
        }
        printf("\n");
    }
}

// Déchiffrement d'un message complet
void feistel_decrypt_message(uint8_t *message, size_t len, uint64_t key) {
    printf("Decrypt : \n");
    for (size_t i = 0; i < len; i += BLOCK_SIZE) {
        uint32_t *left = (uint32_t *)&message[i];
        uint32_t *right = (uint32_t *)&message[i + 4];
        for (size_t j = 0; j < BLOCK_SIZE; j += 1) {
            printf("%02x", message[i+j]);
        }
        printf(" -> ");
        feistel_decrypt_block(left, right, key);
        for (size_t j = 0; j < BLOCK_SIZE; j += 1) {
            printf("%02x", message[i+j]);
        }
        printf("\n");
    }
}

int main(int argc, char *argv[]) {
    uint64_t key;
    
    // Vérification des arguments
    if (argc == 2) {
        key = generate_random_key();
        printf("Clé générée : %08lx\n", key);
    } else if (argc == 3) {
        key = strtoul(argv[2], NULL, 16);
    }
    else {
        fprintf(stderr, "Usage: %s <message> <key>\n", argv[0]);
        return EXIT_FAILURE;
    }

    // Récupération du message
    char *input = argv[1];

    // Préparation du message
    size_t len = strlen(input);
    if (len > MAX_MESSAGE_LEN) {
        fprintf(stderr, "Erreur: Le message est trop long. Taille maximale autorisée: %d\n", MAX_MESSAGE_LEN);
        return EXIT_FAILURE;
    }

    uint8_t message[MAX_MESSAGE_LEN] = {0}; // Tableau fixe pour stocker le message
    memcpy(message, input, len);
    
    // Padding du message
    size_t padded_len = add_padding(message, len, BLOCK_SIZE);

    printf("Message original : %s\n", input);

    // Chiffrement
    feistel_encrypt_message(message, padded_len, key);
    printf("Message chiffré : ");
    for (size_t i = 0; i < padded_len; i++) {
        printf("0x%02X, ", message[i]);
    }
    printf("\n");

    // Déchiffrement
    feistel_decrypt_message(message, padded_len, key);
    padded_len = remove_padding(message, padded_len);

    printf("Message déchiffré : %.*s\n", (int)padded_len, message);

    return 0;
}
