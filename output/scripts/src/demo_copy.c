/* Copy all entries from one or more source zips into a new zip using
 * mz_zip_writer_add_from_zip_reader(). Usage: demo_copy <dst.zip> <src1.zip> [src2.zip ...] */
#include <stdio.h>
#include <string.h>
#include "miniz.h"

static int copy_all(mz_zip_archive *dst, const char *src_path)
{
    mz_zip_archive src;
    mz_uint i, n;
    memset(&src, 0, sizeof(src));

    if (!mz_zip_reader_init_file(&src, src_path, 0))
    {
        printf("cannot open %s: %s\n", src_path, mz_zip_get_error_string(mz_zip_get_last_error(&src)));
        return 0;
    }
    n = mz_zip_reader_get_num_files(&src);
    for (i = 0; i < n; ++i)
    {
        if (!mz_zip_writer_add_from_zip_reader(dst, &src, i))
        {
            printf("copy FAILED at %u: %s\n", i, mz_zip_get_error_string(mz_zip_get_last_error(dst)));
            mz_zip_reader_end(&src);
            return 0;
        }
    }
    mz_zip_reader_end(&src);
    return 1;
}

int main(int argc, char **argv)
{
    mz_zip_archive zip;
    int i;
    memset(&zip, 0, sizeof(zip));

    if (argc < 3)
    {
        fprintf(stderr, "usage: %s <dst.zip> <src1.zip> [src2.zip ...]\n", argv[0]);
        return 2;
    }
    if (!mz_zip_writer_init_file(&zip, argv[1], 0))
        return 1;
    for (i = 2; i < argc; ++i)
        if (!copy_all(&zip, argv[i]))
            return 1;
    if (!mz_zip_writer_finalize_archive(&zip))
    {
        printf("finalize FAILED: %s\n", mz_zip_get_error_string(mz_zip_get_last_error(&zip)));
        return 1;
    }
    printf("copy OK: %u files, zip64=%d\n", zip.m_total_files, mz_zip_is_zip64(&zip));
    mz_zip_writer_end(&zip);
    return 0;
}
