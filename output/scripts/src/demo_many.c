/* Create a zip with N tiny entries, then read it back.
 * Usage: demo_many <zip> <count> */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "miniz.h"

int main(int argc, char **argv)
{
    mz_zip_archive zip;
    long count, i;
    char name[64];
    const char data = 'x';
    memset(&zip, 0, sizeof(zip));

    if (argc != 3)
    {
        fprintf(stderr, "usage: %s <zip> <count>\n", argv[0]);
        return 2;
    }
    count = atol(argv[2]);

    if (!mz_zip_writer_init_file(&zip, argv[1], 0))
        return 1;
    for (i = 0; i < count; ++i)
    {
        snprintf(name, sizeof(name), "file%06ld.txt", i);
        if (!mz_zip_writer_add_mem(&zip, name, &data, 1, MZ_NO_COMPRESSION))
        {
            printf("add FAILED at %ld: %s\n", i, mz_zip_get_error_string(mz_zip_get_last_error(&zip)));
            return 1;
        }
    }
    if (!mz_zip_writer_finalize_archive(&zip))
    {
        printf("finalize FAILED: %s\n", mz_zip_get_error_string(mz_zip_get_last_error(&zip)));
        return 1;
    }
    printf("write OK: %u files, zip64=%d\n", zip.m_total_files, mz_zip_is_zip64(&zip));
    mz_zip_writer_end(&zip);

    memset(&zip, 0, sizeof(zip));
    if (!mz_zip_reader_init_file(&zip, argv[1], 0))
    {
        printf("reader init FAILED: %s\n", mz_zip_get_error_string(mz_zip_get_last_error(&zip)));
        return 1;
    }
    printf("read OK: %u files, zip64=%d\n", mz_zip_reader_get_num_files(&zip), mz_zip_is_zip64(&zip));
    mz_zip_reader_end(&zip);
    return 0;
}
