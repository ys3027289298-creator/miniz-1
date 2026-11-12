/* Add two stored files (each < 4GB) whose sum pushes the archive past 4GB.
 * Before the fix, mz_zip_writer_finalize_archive() failed with
 * MZ_ZIP_TOO_MANY_FILES; now it automatically switches to ZIP64. */
#include <stdio.h>
#include <string.h>
#include "miniz.h"

int main(int argc, char **argv)
{
    mz_zip_archive zip;
    memset(&zip, 0, sizeof(zip));

    if (argc != 4)
    {
        fprintf(stderr, "usage: %s <out.zip> <file1> <file2>\n", argv[0]);
        return 2;
    }

    if (!mz_zip_writer_init_file(&zip, argv[1], 0))
    {
        printf("init failed: %s\n", mz_zip_get_error_string(mz_zip_get_last_error(&zip)));
        return 1;
    }
    if (!mz_zip_writer_add_file(&zip, "part1.bin", argv[2], NULL, 0, MZ_NO_COMPRESSION))
    {
        printf("add1 failed: %s\n", mz_zip_get_error_string(mz_zip_get_last_error(&zip)));
        return 1;
    }
    if (!mz_zip_writer_add_file(&zip, "part2.bin", argv[3], NULL, 0, MZ_NO_COMPRESSION))
    {
        printf("add2 failed: %s\n", mz_zip_get_error_string(mz_zip_get_last_error(&zip)));
        return 1;
    }
    printf("archive size before finalize: %llu bytes (>4GB)\n", (unsigned long long)zip.m_archive_size);
    if (!mz_zip_writer_finalize_archive(&zip))
    {
        printf("finalize FAILED: %s\n", mz_zip_get_error_string(mz_zip_get_last_error(&zip)));
        mz_zip_writer_end(&zip);
        return 1;
    }
    printf("finalize OK, archive is zip64: %d\n", mz_zip_is_zip64(&zip));
    mz_zip_writer_end(&zip);
    return 0;
}
