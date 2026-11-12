// example7.c - Demonstrates how to use miniz.c's deflateInit2()/inflateInit2() gzip container support
// (window_bits = MZ_DEFAULT_WINDOW_BITS + 16) to read and write .gz files (RFC 1952), including CRC-32
// error detection on decompression. With no arguments a self-test is run instead.
// Public domain. See "unlicense" statement at the end of tinfl.c.
// For simplicity, this example is limited to files smaller than 4GB, but this is not a limitation of miniz.c.
#include <stdio.h>
#include <string.h>
#include "miniz.h"

typedef unsigned char uint8;
typedef unsigned int uint;

#define BUF_SIZE (64 * 1024)
static uint8 s_inbuf[BUF_SIZE];
static uint8 s_outbuf[BUF_SIZE];

#define GZIP_WINDOW_BITS (MZ_DEFAULT_WINDOW_BITS + 16)

static int compress_file_to_gzip(const char *pSrc_filename, const char *pDst_filename, int level)
{
    FILE *pInfile, *pOutfile;
    mz_stream stream;
    int status = MZ_OK, flush = MZ_NO_FLUSH, ret = EXIT_FAILURE;

    pInfile = fopen(pSrc_filename, "rb");
    if (!pInfile)
    {
        printf("Failed opening %s for reading!\n", pSrc_filename);
        return EXIT_FAILURE;
    }
    pOutfile = fopen(pDst_filename, "wb");
    if (!pOutfile)
    {
        printf("Failed opening %s for writing!\n", pDst_filename);
        fclose(pInfile);
        return EXIT_FAILURE;
    }

    memset(&stream, 0, sizeof(stream));
    if (mz_deflateInit2(&stream, level, MZ_DEFLATED, GZIP_WINDOW_BITS, 9, MZ_DEFAULT_STRATEGY) != MZ_OK)
    {
        printf("mz_deflateInit2() failed!\n");
        goto done;
    }

    while (status != MZ_STREAM_END)
    {
        if (!stream.avail_in)
        {
            stream.next_in = s_inbuf;
            stream.avail_in = (mz_uint)fread(s_inbuf, 1, BUF_SIZE, pInfile);
            if (feof(pInfile))
                flush = MZ_FINISH;
        }
        stream.next_out = s_outbuf;
        stream.avail_out = BUF_SIZE;
        status = mz_deflate(&stream, flush);
        if ((status != MZ_OK) && (status != MZ_STREAM_END) && (status != MZ_BUF_ERROR))
        {
            printf("mz_deflate() failed with status %d!\n", status);
            mz_deflateEnd(&stream);
            goto done;
        }
        if (fwrite(s_outbuf, 1, BUF_SIZE - stream.avail_out, pOutfile) != BUF_SIZE - stream.avail_out)
        {
            printf("Failed writing to output file!\n");
            mz_deflateEnd(&stream);
            goto done;
        }
    }

    printf("Compressed %s (%lu bytes) -> %s (%lu bytes)\n", pSrc_filename, (mz_ulong)stream.total_in, pDst_filename, (mz_ulong)stream.total_out);
    ret = (mz_deflateEnd(&stream) == MZ_OK) ? EXIT_SUCCESS : EXIT_FAILURE;

done:
    fclose(pInfile);
    fclose(pOutfile);
    return ret;
}

static int decompress_gzip_to_file(const char *pSrc_filename, const char *pDst_filename)
{
    FILE *pInfile, *pOutfile;
    mz_stream stream;
    int status = MZ_OK, ret = EXIT_FAILURE;

    pInfile = fopen(pSrc_filename, "rb");
    if (!pInfile)
    {
        printf("Failed opening %s for reading!\n", pSrc_filename);
        return EXIT_FAILURE;
    }
    pOutfile = fopen(pDst_filename, "wb");
    if (!pOutfile)
    {
        printf("Failed opening %s for writing!\n", pDst_filename);
        fclose(pInfile);
        return EXIT_FAILURE;
    }

    memset(&stream, 0, sizeof(stream));
    if (mz_inflateInit2(&stream, GZIP_WINDOW_BITS) != MZ_OK)
    {
        printf("mz_inflateInit2() failed!\n");
        goto done;
    }

    while (status != MZ_STREAM_END)
    {
        if (!stream.avail_in)
        {
            stream.next_in = s_inbuf;
            stream.avail_in = (mz_uint)fread(s_inbuf, 1, BUF_SIZE, pInfile);
            if ((!stream.avail_in) && (feof(pInfile)))
            {
                printf("Truncated gzip stream in %s!\n", pSrc_filename);
                mz_inflateEnd(&stream);
                goto done;
            }
        }
        stream.next_out = s_outbuf;
        stream.avail_out = BUF_SIZE;
        status = mz_inflate(&stream, MZ_NO_FLUSH);
        if (status == MZ_DATA_ERROR)
        {
            // The gzip CRC-32/size footer (or the stream itself) failed verification.
            printf("mz_inflate() reported MZ_DATA_ERROR: %s is corrupt or fails its CRC-32 check!\n", pSrc_filename);
            mz_inflateEnd(&stream);
            goto done;
        }
        if ((status != MZ_OK) && (status != MZ_STREAM_END) && (status != MZ_BUF_ERROR))
        {
            printf("mz_inflate() failed with status %d!\n", status);
            mz_inflateEnd(&stream);
            goto done;
        }
        if (fwrite(s_outbuf, 1, BUF_SIZE - stream.avail_out, pOutfile) != BUF_SIZE - stream.avail_out)
        {
            printf("Failed writing to output file!\n");
            mz_inflateEnd(&stream);
            goto done;
        }
    }

    printf("Decompressed %s (%lu bytes) -> %s (%lu bytes), CRC-32 verified OK\n", pSrc_filename, (mz_ulong)stream.total_in, pDst_filename, (mz_ulong)stream.total_out);
    ret = (mz_inflateEnd(&stream) == MZ_OK) ? EXIT_SUCCESS : EXIT_FAILURE;

done:
    fclose(pInfile);
    fclose(pOutfile);
    return ret;
}

// Streaming in-memory round trip using awkwardly small buffers, to prove the gzip container
// works when fed a few bytes at a time. Returns 0 on success.
static int selftest_roundtrip(const uint8 *pSrc, uint src_len, uint in_chunk, uint out_chunk)
{
    static uint8 s_comp[BUF_SIZE * 2];
    static uint8 s_decomp[BUF_SIZE * 2];
    mz_stream stream;
    uint in_ofs, out_ofs, comp_size;
    int status;

    memset(&stream, 0, sizeof(stream));
    if (mz_deflateInit2(&stream, MZ_DEFAULT_COMPRESSION, MZ_DEFLATED, GZIP_WINDOW_BITS, 9, MZ_DEFAULT_STRATEGY) != MZ_OK)
        return 1;
    stream.next_in = pSrc;
    stream.avail_in = src_len;
    stream.next_out = s_comp;
    stream.avail_out = sizeof(s_comp);
    status = mz_deflate(&stream, MZ_FINISH);
    comp_size = (uint)stream.total_out;
    mz_deflateEnd(&stream);
    if (status != MZ_STREAM_END)
        return 2;

    memset(&stream, 0, sizeof(stream));
    if (mz_inflateInit2(&stream, GZIP_WINDOW_BITS) != MZ_OK)
        return 3;
    in_ofs = out_ofs = 0;
    for (;;)
    {
        stream.next_in = s_comp + in_ofs;
        stream.avail_in = (comp_size - in_ofs < in_chunk) ? (comp_size - in_ofs) : in_chunk;
        stream.next_out = s_decomp + out_ofs;
        stream.avail_out = ((uint)sizeof(s_decomp) - out_ofs < out_chunk) ? ((uint)sizeof(s_decomp) - out_ofs) : out_chunk;
        status = mz_inflate(&stream, MZ_NO_FLUSH);
        in_ofs = (uint)(stream.next_in - s_comp);
        out_ofs = (uint)(stream.next_out - s_decomp);
        if (status == MZ_STREAM_END)
            break;
        if (((status != MZ_OK) && (status != MZ_BUF_ERROR)) || ((status == MZ_BUF_ERROR) && (in_ofs >= comp_size)))
        {
            mz_inflateEnd(&stream);
            return 4;
        }
    }
    mz_inflateEnd(&stream);

    if ((out_ofs != src_len) || (memcmp(s_decomp, pSrc, src_len)))
        return 5;

    printf("  round trip OK: %u bytes -> %u byte gzip stream -> %u bytes (in chunks of %u/%u)\n", src_len, comp_size, out_ofs, in_chunk, out_chunk);
    return 0;
}

// Corrupts a copy of a valid gzip stream and checks that mz_inflate() reports MZ_DATA_ERROR.
static int selftest_corruption(const uint8 *pSrc, uint src_len, uint corrupt_ofs, const char *pWhat)
{
    static uint8 s_comp[BUF_SIZE * 2];
    static uint8 s_decomp[BUF_SIZE * 2];
    mz_stream stream;
    uint comp_size;
    int status;

    memset(&stream, 0, sizeof(stream));
    mz_deflateInit2(&stream, MZ_DEFAULT_COMPRESSION, MZ_DEFLATED, GZIP_WINDOW_BITS, 9, MZ_DEFAULT_STRATEGY);
    stream.next_in = pSrc;
    stream.avail_in = src_len;
    stream.next_out = s_comp;
    stream.avail_out = sizeof(s_comp);
    status = mz_deflate(&stream, MZ_FINISH);
    comp_size = (uint)stream.total_out;
    mz_deflateEnd(&stream);
    if (status != MZ_STREAM_END)
        return 1;

    s_comp[corrupt_ofs] ^= 0x5A;

    memset(&stream, 0, sizeof(stream));
    mz_inflateInit2(&stream, GZIP_WINDOW_BITS);
    stream.next_in = s_comp;
    stream.avail_in = comp_size;
    stream.next_out = s_decomp;
    stream.avail_out = sizeof(s_decomp);
    status = mz_inflate(&stream, MZ_FINISH);
    mz_inflateEnd(&stream);

    if (status != MZ_DATA_ERROR)
    {
        printf("  corruption test FAILED (%s): expected MZ_DATA_ERROR, got %d\n", pWhat, status);
        return 2;
    }
    printf("  corruption detected OK (%s): mz_inflate() returned MZ_DATA_ERROR\n", pWhat);
    return 0;
}

static int run_selftest(void)
{
    static uint8 s_test_data[32768];
    uint i, comp_size;
    mz_stream stream;
    static uint8 s_comp[BUF_SIZE * 2];
    int status;

    printf("Running gzip container self-test...\n");

    // Fill the test buffer with compressible data.
    for (i = 0; i < sizeof(s_test_data); ++i)
        s_test_data[i] = (uint8)("The quick brown fox jumps over the lazy dog. "[i % 45] + (i & 1));

    if (selftest_roundtrip(s_test_data, sizeof(s_test_data), 7, 13))
        return EXIT_FAILURE;
    if (selftest_roundtrip(s_test_data, sizeof(s_test_data), sizeof(s_test_data), sizeof(s_test_data)))
        return EXIT_FAILURE;
    if (selftest_roundtrip(s_test_data, 0, 7, 13))
        return EXIT_FAILURE;

    // Corrupt a payload byte, then a CRC-32 trailer byte: both must be caught.
    memset(&stream, 0, sizeof(stream));
    mz_deflateInit2(&stream, MZ_DEFAULT_COMPRESSION, MZ_DEFLATED, GZIP_WINDOW_BITS, 9, MZ_DEFAULT_STRATEGY);
    stream.next_in = s_test_data;
    stream.avail_in = sizeof(s_test_data);
    stream.next_out = s_comp;
    stream.avail_out = sizeof(s_comp);
    status = mz_deflate(&stream, MZ_FINISH);
    comp_size = (uint)stream.total_out;
    mz_deflateEnd(&stream);
    if (status != MZ_STREAM_END)
        return EXIT_FAILURE;

    if (selftest_corruption(s_test_data, sizeof(s_test_data), comp_size / 2, "deflate payload bit flip"))
        return EXIT_FAILURE;
    if (selftest_corruption(s_test_data, sizeof(s_test_data), comp_size - 6, "CRC-32 trailer bit flip"))
        return EXIT_FAILURE;
    if (selftest_corruption(s_test_data, sizeof(s_test_data), 0, "header magic bit flip"))
        return EXIT_FAILURE;

    printf("gzip container self-test PASSED\n");
    return EXIT_SUCCESS;
}

int main(int argc, char *argv[])
{
    printf("miniz.c version: %s\n", MZ_VERSION);

    if (argc < 2)
        return run_selftest();

    if ((argc == 4) && (!strcmp(argv[1], "c")))
        return compress_file_to_gzip(argv[2], argv[3], MZ_DEFAULT_LEVEL);

    if ((argc == 4) && (!strcmp(argv[1], "d")))
        return decompress_gzip_to_file(argv[2], argv[3]);

    printf("Usage: example7 [mode:c or d] infile outfile\n");
    printf("\nModes:\n");
    printf("c - Compresses file infile to a gzip (.gz) stream in file outfile\n");
    printf("d - Decompresses gzip stream in file infile to file outfile, verifying the CRC-32 footer\n");
    printf("\nWith no arguments a self-test is run.\n");
    return EXIT_FAILURE;
}
