/* Feed the reader hand-crafted ZIP64 end-of-central-directory records that
 * exceed miniz's practical ZIP64 limits, and show the returned error codes. */
#include <stdio.h>
#include <string.h>
#include "miniz.h"

static void put16(mz_uint8 *p, mz_uint16 v) { p[0] = (mz_uint8)v; p[1] = (mz_uint8)(v >> 8); }
static void put32(mz_uint8 *p, mz_uint32 v) { put16(p, (mz_uint16)v); put16(p + 2, (mz_uint16)(v >> 16)); }
static void put64(mz_uint8 *p, mz_uint64 v) { put32(p, (mz_uint32)v); put32(p + 4, (mz_uint32)(v >> 32)); }

static void make_archive(mz_uint8 *buf, mz_uint64 total_entries, mz_uint64 cdir_size)
{
    memset(buf, 0, 98);
    put32(buf + 0, 0x06064b50);       /* zip64 EOCD signature */
    put64(buf + 4, 44);               /* size of zip64 EOCD record */
    put16(buf + 12, 45);              /* version made by */
    put16(buf + 14, 45);              /* version needed */
    put64(buf + 24, total_entries);   /* entries on this disk */
    put64(buf + 32, total_entries);   /* total entries */
    put64(buf + 40, cdir_size);       /* central directory size */
    put64(buf + 48, 0);               /* central directory offset */
    put32(buf + 56, 0x07064b50);      /* zip64 locator signature */
    put64(buf + 64, 0);               /* offset of zip64 EOCD */
    put32(buf + 72, 1);               /* total number of disks */
    put32(buf + 76, 0x06054b50);      /* classic EOCD signature */
    put16(buf + 84, 0xFFFF);          /* entries on this disk */
    put16(buf + 86, 0xFFFF);          /* total entries */
    put32(buf + 88, 0xFFFFFFFF);      /* central directory size */
    put32(buf + 92, 0xFFFFFFFF);      /* central directory offset */
}

static int expect_error(const char *what, mz_uint64 entries, mz_uint64 cdir_size, mz_zip_error expected)
{
    mz_uint8 buf[98];
    mz_zip_archive zip;
    mz_zip_error err;
    memset(&zip, 0, sizeof(zip));

    make_archive(buf, entries, cdir_size);
    if (mz_zip_reader_init_mem(&zip, buf, sizeof(buf), 0))
    {
        printf("%s: UNEXPECTEDLY succeeded\n", what);
        mz_zip_reader_end(&zip);
        return 1;
    }
    err = mz_zip_get_last_error(&zip);
    printf("%s: rejected with %s\n", what, mz_zip_get_error_string(err));
    if (err != expected)
    {
        printf("  expected %s\n", mz_zip_get_error_string(expected));
        return 1;
    }
    return 0;
}

int main(void)
{
    int fails = 0;
    fails += expect_error("entries = 2^32 (beyond zip64 practical limit)", 0x100000000ULL, 0, MZ_ZIP_TOO_MANY_FILES);
    fails += expect_error("central dir = 4GB (beyond zip64 practical limit)", 1, 0x100000000ULL, MZ_ZIP_UNSUPPORTED_CDIR_SIZE);
    if (!fails)
        printf("all over-limit cases returned the expected error codes\n");
    return fails;
}
