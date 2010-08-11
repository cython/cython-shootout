# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org/
#
# contributed by Robert Bradshaw

import sys    

def main(int size, outfile=sys.stdout):

    cdef int iter = 50
    cdef int i, xi, yi
    cdef double step = 2.0 / size
    cdef double Cx, Cy, Zx, Zy, Tx, Ty
    
    cdef line = ' ' * ((size+7) // 8)
    cdef char* buf = line
    cdef unsigned char byte_accumulate
    
    write = outfile.write
    write("P4\n%s %s\n" % (size, size))
    
    for yi in range(size):

        byte_accumulate = 0

        for xi in range(size):

            i = iter
            Zx = Cx = step*xi - 1.5
            Zy = Cy = step*yi - 1.0
            
            Tx = Zx * Zx
            Ty = Zy * Zy
            while True:
                # Z = Z^2 + C
                Zx, Zy = Tx - Ty + Cx , Zx * Zy + Zx * Zy + Cy
                Tx = Zx * Zx
                Ty = Zy * Zy
                i -= 1
                if (i == 0) | (Tx + Ty > 4.0):
                    break
                    
            byte_accumulate = (byte_accumulate << 1) | (i == 0)
            if xi & 7 == 7:
                buf[xi >> 3] = byte_accumulate
                byte_accumulate = 0 # TESTING
        
        if size & 7 != 0:
            # line ending on non-byte boundary
            byte_accumulate <<= 8 - (size & 7)
            buf[size >> 3] = byte_accumulate
        write(line)


if __name__ == '__main__':
    n = 16000
    out = sys.stdout
    try:
        n = int(sys.argv[1])
        file = open(sys.argv[2])
    except IndexError:
        pass
    main(n, out)
