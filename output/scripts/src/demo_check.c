/* List a zip's entries with per-entry CRC-32 of the uncompressed data,
 * computed by streaming extraction (constant memory).
 * Usage: demo_check <zip> */
#include <stdio.h>
#include <string.h>
#include "miniz.h"

static size_t crc_callback(void *opaque, mz_uint64 ofs, const void *buf, size_t n)
{
    mz_ulong *crc = (mz_ulong *)opaque;
    (void)ofs;
    *crc = mz_crc32(*crc, (const mz_uint8 *)buf, n);
    return n;
}

int main(int argc, char **argv)
{
    mz_zip_archive zip;
    mz_uint i, n;
    memset(&zip, 0, sizeof(zip));

    if (argc != 2)
    {
        fprintf(stderr, "usage: %s <zip>\n", argv[0]);
        return 2;
    }
    if (!mz_zip_reader_init_file(&zip, argv[1], 0))
    {
        printf("reader init FAILED: %s\n", mz_zip_get_error_string(mz_zip_get_last_error(&zip)));
        return 1;
    }
    n = mz_zip_reader_get_num_files(&zip);
    printf("files=%u zip64=%d\n", n, mz_zip_is_zip64(&zip));
    for (i = 0; i < n; ++i)
    {
        mz_zip_archive_file_stat st;
        mz_ulong crc = MZ_CRC32_INIT;
        if (!mz_zip_reader_file_stat(&zip, i, &st))
            return 1;
        if (!mz_zip_reader_extract_to_callback(&zip, i, crc_callback, &crc, 0))
        {
            printf("extract FAILED: %s\n", mz_zip_get_error_string(mz_zip_get_last_error(&zip)));
            return 1;
        }
        printf("%s size=%llu crc=%08lx\n", st.m_filename,
               (unsigned long long)st.m_uncomp_size, (unsigned long)crc);
    }
    mz_zip_reader_end(&zip);
    return 0;
}
