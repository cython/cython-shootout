# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org/
#
# contributed by Tupteq
# modified by Simon Descarpentries

import sys
from array import array

def main():
    cout = sys.stdout.write
    size = int(sys.argv[1])
    fsize = float(size)
    xr_size = xrange(size)
    xr_iter = xrange(50)
    bit_num = 7
    byte_acc = 0
    result = []
    local_abs = abs

    cout ("P4\n%d %d\n" % (size, size))

    for y in xr_size:
        fy = 2j * y / fsize - 1j
        for x in xr_size:
            z = 0j
            c = 2. * x / fsize - 1.5 + fy

            for i in xr_iter:
                z = z * z + c
                if local_abs(z) >= 2.: break
            else:
                byte_acc += 1 << bit_num

            if bit_num == 0:
                result.append (byte_acc)
                bit_num = 7
                byte_acc = 0
            else:
                bit_num -= 1

        if bit_num != 7:
            result.append (byte_acc)
            bit_num = 7
            byte_acc = 0

    cout (array ('B', result).tostring ())

main()

