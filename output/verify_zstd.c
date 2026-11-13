/* verify_zstd.c - Validates miniz zip-reader handling of zstd (method 93) entries
 * through the repository's public API only (miniz.h).
 *
 * Usage: verify_zstd <archive> <entry> <reference> <heap|file|iter> [--expect-fail]
 *
 * Exit code 0 when extraction matches the reference (or fails as expected with
 * --expect-fail), non-zero otherwise. Prints the miniz error code on failure and
 * the process peak RSS so memory growth can be checked.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include "miniz.h"

static long peak_rss_kb(void)
{
    struct rusage ru;
    getrusage(RUSAGE_SELF, &ru);
    return ru.ru_maxrss;
}

/* Streaming compare callback: matches decompressed data against the reference file. */
typedef struct
{
    FILE *ref;
    int mismatch;
} cmp_ctx;

static size_t cmp_callback(void *opaque, mz_uint64 ofs, const void *buf, size_t n)
{
    cmp_ctx *ctx = (cmp_ctx *)opaque;
    unsigned char tmp[16384];
    size_t done = 0;
    const unsigned char *p = (const unsigned char *)buf;

    (void)ofs; /* callbacks arrive in order */
    while (done < n)
    {
        size_t chunk = n - done;
        if (chunk > sizeof(tmp))
            chunk = sizeof(tmp);
        if (fread(tmp, 1, chunk, ctx->ref) != chunk || memcmp(tmp, p + done, chunk) != 0)
        {
            ctx->mismatch = 1;
            return done; /* short write signals failure */
        }
        done += chunk;
    }
    return n;
}

static void print_error(mz_zip_archive *zip, const char *what)
{
    mz_zip_error err = mz_zip_get_last_error(zip);
    printf("  %s failed: error=%d (%s)\n", what, (int)err, mz_zip_get_error_string(err));
}

int main(int argc, char **argv)
{
    const char *archive_path, *entry_name, *ref_path, *mode;
    int expect_fail = 0, failed = 0, mismatch = 0;
    mz_zip_archive zip;
    mz_zip_archive_file_stat st;
    mz_uint idx;

    if (argc < 5)
    {
        fprintf(stderr, "usage: %s <archive> <entry> <reference> <heap|file|iter> [--expect-fail]\n", argv[0]);
        return 2;
    }
    archive_path = argv[1];
    entry_name = argv[2];
    ref_path = argv[3];
    mode = argv[4];
    expect_fail = (argc > 5) && !strcmp(argv[5], "--expect-fail");

    memset(&zip, 0, sizeof(zip));
    if (!mz_zip_reader_init_file(&zip, archive_path, 0))
    {
        print_error(&zip, "reader_init");
        if (expect_fail)
            printf("REJECTED as expected\n");
        return expect_fail ? 0 : 1;
    }

    idx = mz_zip_reader_locate_file(&zip, entry_name, NULL, 0);
    if ((int)idx < 0 || !mz_zip_reader_file_stat(&zip, idx, &st))
    {
        print_error(&zip, "locate/stat");
        mz_zip_reader_end(&zip);
        return 1;
    }

    printf("entry='%s' method=%u comp=%llu uncomp=%llu supported=%d\n", st.m_filename, (unsigned)st.m_method,
           (unsigned long long)st.m_comp_size, (unsigned long long)st.m_uncomp_size, (int)st.m_is_supported);

    if (!strcmp(mode, "heap"))
    {
        /* extract_to_heap -> extract_to_mem path */
        size_t size = 0;
        void *data = mz_zip_reader_extract_to_heap(&zip, idx, &size, 0);
        if (!data)
        {
            print_error(&zip, "extract_to_heap");
            failed = 1;
        }
        else
        {
            FILE *ref = fopen(ref_path, "rb");
            unsigned char tmp[16384];
            size_t done = 0;
            while (!failed && done < size)
            {
                size_t chunk = size - done;
                if (chunk > sizeof(tmp))
                    chunk = sizeof(tmp);
                if (fread(tmp, 1, chunk, ref) != chunk || memcmp(tmp, (const unsigned char *)data + done, chunk) != 0)
                    failed = 1;
                done += chunk;
            }
            if (!failed && (fgetc(ref) != EOF || size != (size_t)st.m_uncomp_size))
                failed = 1;
            fclose(ref);
            free(data);
            if (failed)
                printf("  heap path: content mismatch\n");
        }
    }
    else if (!strcmp(mode, "file"))
    {
        /* extract_to_callback path (same engine as extract_to_file) */
        FILE *ref = fopen(ref_path, "rb");
        cmp_ctx ctx;
        ctx.ref = ref;
        ctx.mismatch = 0;
        if (!mz_zip_reader_extract_to_callback(&zip, idx, cmp_callback, &ctx, 0))
        {
            print_error(&zip, "extract_to_callback");
            failed = 1;
        }
        if (ctx.mismatch)
        {
            printf("  callback path: content mismatch\n");
            failed = 1;
        }
        fclose(ref);
    }
    else /* iter */
    {
        /* streaming iterator path, deliberately odd chunk size */
        mz_zip_reader_extract_iter_state *it = mz_zip_reader_extract_file_iter_new(&zip, entry_name, 0);
        unsigned char buf[7000], tmp[7000];
        FILE *ref = fopen(ref_path, "rb");
        size_t n;
        if (!it)
        {
            print_error(&zip, "iter_new");
            failed = 1;
        }
        while (it && (n = mz_zip_reader_extract_iter_read(it, buf, sizeof(buf))) > 0)
        {
            if (fread(tmp, 1, n, ref) != n || memcmp(tmp, buf, n) != 0)
            {
                printf("  iter path: content mismatch\n");
                failed = 1;
                break;
            }
        }
        if (it && !mz_zip_reader_extract_iter_free(it))
        {
            print_error(&zip, "iter_free");
            failed = 1;
        }
        fclose(ref);
    }

    mz_zip_reader_end(&zip);
    printf("peak_rss=%ld KB\n", peak_rss_kb());

    if (expect_fail)
    {
        if (failed)
        {
            printf("REJECTED as expected\n");
            return 0;
        }
        printf("ERROR: bad input was accepted\n");
        return 1;
    }

    printf(failed ? "FAIL\n" : "OK\n");
    return failed ? 1 : 0;
}
