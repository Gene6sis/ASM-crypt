#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>

int main()
{
    uint32_t block = 0x4a212ba5;

    printf("\tblock = %08X\n", block);
    printf("\tblock << 3 = %08X\n", (block << 3));

    return 0;
}