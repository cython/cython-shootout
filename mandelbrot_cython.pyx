# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org/
#
# contributed by Robert Bradshaw

# Doesn't quite match the test output. Numerical noise? 

import sys    

def main(int size, outfile=sys.stdout):
    cdef int iter = 50
    cdef double step = 2.0 / size
    cdef double Cx, Cy, Zx, Zy
    cdef int i, xi, yi
    cdef double square_abs
    
    cdef line = ' ' * ((size+7) // 8)
    cdef char* buf = line
    cdef unsigned char byte_acc
    
    write = outfile.write
    write("P4\n%s %s\n" % (size, size))
    
    
    for yi in range(size):
        byte_acc = 0
        for xi in range(size):
            Zx = Cx = step*xi - 1.5
            Zy = Cy = step*yi - 1.0
            i = iter
            while True:
                # Soon (hopefully) Cython will have native c complex types
                # Z = Z^2 + C
                Zx, Zy = Zx*Zx - Zy*Zy + Cx , 2*Zx*Zy + Cy
                square_abs = Zx*Zx + Zy*Zy
                i -= 1
                if (i == 0) | (square_abs > 4.0):
                    break
                    
            byte_acc = (byte_acc << 1) | (square_abs < 4.0)
            if xi & 7 == 7:
                buf[xi >> 3] = byte_acc
        
        if size & 7 != 0:
            # line ending on non-byte boundary
            byte_acc <<= 8 - (size % 8)
            buf[size >> 3] = byte_acc
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
