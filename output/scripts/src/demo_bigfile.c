/* Write a huge file to a zip, read it back and extract it, streaming all the
 * way (constant memory). Usage: demo_bigfile <zip> <srcfile> <extracted> [level] */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "miniz.h"

int main(int argc, char **argv)
{
    mz_zip_archive zip;
    mz_zip_archive_file_stat st;
    mz_uint level = MZ_DEFAULT_LEVEL;
    memset(&zip, 0, sizeof(zip));

    if (argc < 4)
    {
        fprintf(stderr, "usage: %s <zip> <srcfile> <extracted> [level]\n", argv[0]);
        return 2;
    }
    if (argc > 4)
        level = (mz_uint)atoi(argv[4]);

    if (!mz_zip_writer_init_file(&zip, argv[1], 0))
        return 1;
    if (!mz_zip_writer_add_file(&zip, "big.bin", argv[2], NULL, 0, level))
    {
        printf("add failed: %s\n", mz_zip_get_error_string(mz_zip_get_last_error(&zip)));
        return 1;
    }
    if (!mz_zip_writer_finalize_archive(&zip))
    {
        printf("finalize failed: %s\n", mz_zip_get_error_string(mz_zip_get_last_error(&zip)));
        return 1;
    }
    printf("write OK, zip64=%d\n", mz_zip_is_zip64(&zip));
    mz_zip_writer_end(&zip);

    memset(&zip, 0, sizeof(zip));
    if (!mz_zip_reader_init_file(&zip, argv[1], 0))
    {
        printf("reader init failed: %s\n", mz_zip_get_error_string(mz_zip_get_last_error(&zip)));
        return 1;
    }
    if (!mz_zip_reader_file_stat(&zip, 0, &st))
        return 1;
    printf("read OK: uncomp=%llu comp=%llu zip64=%d\n",
           (unsigned long long)st.m_uncomp_size, (unsigned long long)st.m_comp_size, mz_zip_is_zip64(&zip));
    if (!mz_zip_reader_extract_to_file(&zip, 0, argv[3], 0))
    {
        printf("extract failed: %s\n", mz_zip_get_error_string(mz_zip_get_last_error(&zip)));
        return 1;
    }
    printf("extract OK\n");
    mz_zip_reader_end(&zip);
    return 0;
}
