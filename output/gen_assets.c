/* gen_assets.c - Generates small zip archives containing zstd-compressed (method 93)
 * entries, used to validate the miniz zip reader. The zstd frame is produced with
 * libzstd (loaded at runtime); the zip container is written directly.
 * Also emits the raw reference payloads and corrupted/truncated archive variants.
 */
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "miniz.h"

typedef size_t (*zstd_compress_bound_func)(size_t);
typedef size_t (*zstd_compress_func)(void *, size_t, const void *, size_t, int);
typedef unsigned (*zstd_is_error_func)(size_t);

static zstd_compress_func p_ZSTD_compress;
static zstd_compress_bound_func p_ZSTD_compressBound;
static zstd_is_error_func p_ZSTD_isError;

static void load_zstd(void)
{
    void *h = dlopen("libzstd.so.1", RTLD_LAZY);
    if (!h)
        h = dlopen("libzstd.so", RTLD_LAZY);
    if (!h)
    {
        fprintf(stderr, "cannot load libzstd\n");
        exit(1);
    }
    *(void **)&p_ZSTD_compress = dlsym(h, "ZSTD_compress");
    *(void **)&p_ZSTD_compressBound = dlsym(h, "ZSTD_compressBound");
    *(void **)&p_ZSTD_isError = dlsym(h, "ZSTD_isError");
    if (!p_ZSTD_compress || !p_ZSTD_compressBound || !p_ZSTD_isError)
    {
        fprintf(stderr, "cannot resolve zstd symbols\n");
        exit(1);
    }
}

static void put_le16(unsigned char *p, unsigned v) { p[0] = (unsigned char)v; p[1] = (unsigned char)(v >> 8); }
static void put_le32(unsigned char *p, mz_uint32 v) { p[0] = (unsigned char)v; p[1] = (unsigned char)(v >> 8); p[2] = (unsigned char)(v >> 16); p[3] = (unsigned char)(v >> 24); }

/* Writes a single-entry zip archive with the given compression method. */
static int write_zip(const char *path, const char *entry_name, const void *comp_data, size_t comp_size,
                     const void *uncomp_data, size_t uncomp_size, mz_uint16 method)
{
    FILE *f = fopen(path, "wb");
    unsigned char hdr[30], cd[46], eocd[22];
    size_t name_len = strlen(entry_name);
    mz_uint32 crc = (mz_uint32)mz_crc32(MZ_CRC32_INIT, uncomp_data, uncomp_size);
    mz_uint32 cd_ofs;

    if (!f)
        return 0;

    memset(hdr, 0, sizeof(hdr));
    put_le32(hdr + 0, 0x04034b50);
    put_le16(hdr + 4, 20);
    put_le16(hdr + 8, method);
    put_le32(hdr + 14, crc);
    put_le32(hdr + 18, (mz_uint32)comp_size);
    put_le32(hdr + 22, (mz_uint32)uncomp_size);
    put_le16(hdr + 26, (unsigned)name_len);
    fwrite(hdr, 1, sizeof(hdr), f);
    fwrite(entry_name, 1, name_len, f);
    fwrite(comp_data, 1, comp_size, f);

    cd_ofs = (mz_uint32)ftell(f);
    memset(cd, 0, sizeof(cd));
    put_le32(cd + 0, 0x02014b50);
    put_le16(cd + 4, 20);
    put_le16(cd + 6, 20);
    put_le16(cd + 10, method);
    put_le32(cd + 16, crc);
    put_le32(cd + 20, (mz_uint32)comp_size);
    put_le32(cd + 24, (mz_uint32)uncomp_size);
    put_le16(cd + 28, (unsigned)name_len);
    fwrite(cd, 1, sizeof(cd), f);
    fwrite(entry_name, 1, name_len, f);

    memset(eocd, 0, sizeof(eocd));
    put_le32(eocd + 0, 0x06054b50);
    put_le16(eocd + 8, 1);
    put_le16(eocd + 10, 1);
    put_le32(eocd + 12, (mz_uint32)(sizeof(cd) + name_len));
    put_le32(eocd + 16, cd_ofs);
    fwrite(eocd, 1, sizeof(eocd), f);

    return fclose(f) == 0;
}

static void write_file(const char *path, const void *data, size_t size)
{
    FILE *f = fopen(path, "wb");
    fwrite(data, 1, size, f);
    fclose(f);
}

#define MZ_ZSTD_METHOD 93

int main(void)
{
    static const char *out = "output";
    char path[256];
    size_t i;

    load_zstd();

    /* --- Asset 1: small text entry --- */
    {
        char *text = malloc(1 << 20);
        size_t text_size = 0, bound, comp_size;
        unsigned char *comp;
        const char *line = "The partner sent us a zstd-compressed zip entry; miniz must read it back correctly.\n";

        for (i = 0; i < 100; i++)
        {
            int n = sprintf(text + text_size, "[%04zu] %s", i, line);
            text_size += (size_t)n;
        }

        bound = p_ZSTD_compressBound(text_size);
        comp = malloc(bound);
        comp_size = p_ZSTD_compress(comp, bound, text, text_size, 3);
        if (p_ZSTD_isError(comp_size))
        {
            fprintf(stderr, "zstd compress failed\n");
            return 1;
        }

        sprintf(path, "%s/ref_hello.txt", out);
        write_file(path, text, text_size);
        sprintf(path, "%s/zstd_small.zip", out);
        write_zip(path, "hello.txt", comp, comp_size, text, text_size, MZ_ZSTD_METHOD);

        /* Corrupted variant: flip bits inside the zstd frame. */
        for (i = 0; i < 16; i++)
            comp[comp_size / 2 + i] ^= 0xFF;
        sprintf(path, "%s/zstd_corrupt.zip", out);
        write_zip(path, "hello.txt", comp, comp_size, text, text_size, MZ_ZSTD_METHOD);

        /* Truncated variant: zstd frame cut short, zip structure stays valid. */
        sprintf(path, "%s/zstd_trunc.zip", out);
        write_zip(path, "hello.txt", comp, comp_size * 3 / 5, text, text_size, MZ_ZSTD_METHOD);

        printf("small: uncomp=%zu comp=%zu\n", text_size, comp_size);
        free(text);
        free(comp);
    }

    /* --- Asset 2: large but highly compressible entry (archive itself stays small) --- */
    {
        const size_t big_size = 32u << 20; /* 32 MiB uncompressed */
        unsigned char *big = malloc(big_size);
        unsigned char *comp;
        size_t bound, comp_size, pos = 0;

        while (pos + 128 < big_size)
        {
            int n = sprintf((char *)big + pos, "line %08zu: repeated payload for streaming memory check\n", pos);
            pos += (size_t)n;
        }
        memset(big + pos, 'x', big_size - pos);

        bound = p_ZSTD_compressBound(big_size);
        comp = malloc(bound);
        comp_size = p_ZSTD_compress(comp, bound, big, big_size, 3);
        if (p_ZSTD_isError(comp_size))
        {
            fprintf(stderr, "zstd compress failed\n");
            return 1;
        }

        sprintf(path, "%s/ref_big.bin", out);
        write_file(path, big, big_size);
        sprintf(path, "%s/zstd_big.zip", out);
        write_zip(path, "big.bin", comp, comp_size, big, big_size, MZ_ZSTD_METHOD);

        printf("big:   uncomp=%zu comp=%zu\n", big_size, comp_size);
        free(big);
        free(comp);
    }

    return 0;
}
