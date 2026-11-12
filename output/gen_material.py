#!/usr/bin/env python3
"""Generates the small self-contained test material used by the gzip container demo.
Deterministic (fixed seed), total size < 300KB."""
import random
import os

HERE = os.path.dirname(os.path.abspath(__file__))
MAT = os.path.join(HERE, "material")


def main():
    random.seed(42)
    os.makedirs(os.path.join(MAT, "docs"), exist_ok=True)

    # report.txt: compressible log-like text (~240KB)
    words = ["alpha", "beta", "gamma", "delta", "miniz", "gzip", "container", "stream", "crc32", "deflate"]
    with open(os.path.join(MAT, "report.txt"), "w") as f:
        for i in range(12000):
            f.write("%06d %s %s\n" % (i, random.choice(words), random.choice(words)))

    # docs/data.bin: incompressible random bytes (30KB)
    with open(os.path.join(MAT, "docs", "data.bin"), "wb") as f:
        f.write(bytes(random.randrange(256) for _ in range(30000)))

    # docs/readme.txt: highly compressible repeated text (~10KB)
    with open(os.path.join(MAT, "docs", "readme.txt"), "w") as f:
        f.write("deterministic test material for the miniz gzip container demo\n" * 200)

    # fixed mtimes keep any produced archives byte-deterministic
    epoch = 1577934245  # 2020-01-02 03:04:05 UTC
    for root, dirs, files in os.walk(MAT):
        for name in dirs + files:
            os.utime(os.path.join(root, name), (epoch, epoch))
    os.utime(MAT, (epoch, epoch))

    total = sum(os.path.getsize(os.path.join(r, n)) for r, _, ns in os.walk(MAT) for n in ns)
    print("material generated under %s (%d bytes total)" % (MAT, total))


if __name__ == "__main__":
    main()
