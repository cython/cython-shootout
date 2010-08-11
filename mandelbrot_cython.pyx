# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org/
#
# contributed by Robert Bradshaw

import sys

def main(int size, outfile=sys.stdout):

    cdef int i, x, y
    cdef double step = 2.0 / size
    cdef double Cx, Cy, Zx, Zy, Tx, Ty

    cdef line = ' ' * ((size+7) // 8)
    cdef char *buf = line
    cdef unsigned char byte_acc

    write = outfile.write
    write("P4\n%s %s\n" % (size, size))

    for y in range(size):

        byte_acc = 0

        for x in range(size):

            i = 50
            Zx = Cx = step*x - 1.5
            Zy = Cy = step*y - 1.0

            Tx = Zx * Zx
            Ty = Zy * Zy
            while True:
                # Z = Z^2 + C
                Zx, Zy = Tx - Ty + Cx, Zx * Zy + Zx * Zy + Cy
                Tx = Zx * Zx
                Ty = Zy * Zy
                i -= 1
                if (i == 0) | (Tx + Ty > 4.0):
                    break

            byte_acc = (byte_acc << 1) | (i == 0)
            if x & 7 == 7:
                buf[x >> 3] = byte_acc

        if size & 7 != 0:
            # line ending on non-byte boundary
            byte_acc <<= 8 - (size & 7)
            buf[size >> 3] = byte_acc
        write(line)


if __name__ == '__main__':
    main(int(sys.argv[1]), sys.stdout)
