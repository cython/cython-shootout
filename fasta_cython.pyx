# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org/
#
# modified by Ian Osgood
# modified again by Heinrich Acker

cdef extern from *:
    void memcpy(void *, void *, int)

import sys

alu = (
   'GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG'
   'GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA'
   'CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT'
   'ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA'
   'GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG'
   'AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC'
   'AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA')

iub = zip('acgtBDHKMNRSVWY', [0.27, 0.12, 0.12, 0.27] + [0.02]*11)

homosapiens = [
    ('a', 0.3029549426680),
    ('c', 0.1979883004921),
    ('g', 0.1975473066391),
    ('t', 0.3015094502008),
]

cdef unsigned long seed = 42
cdef inline float pseudo_random(float lim):
    cdef unsigned long ia = 3877, ic = 29573, im = 139968
    cdef float imf = im
    global seed
    seed = (seed * ia + ic) % im
    return lim * <long>seed / imf

def makeCumulative(table):
    P = []
    C = []
    prob = 0.
    for char, p in table:
        prob += p
        P += [prob]
        C += [char]
    return (P, C)

def repeatFasta(src, int n):
    cdef int i, j, r = len(src)
    cdef int width = 60
    s = src * 2
    line = ' ' * width
    cdef char* ss = s
    cdef char* buf = line
    i = 0
    for j in xrange(n // width):
        memcpy(buf, ss + i, width)
        print line
        i += width
        i -= r * (i>r)
    if n % width:
        memcpy(buf, ss + i, width)
        print line[:n % width]

def randomFasta(table, int n):

    probs, chars = makeCumulative(table)
    cdef int width = 60
    cdef float cprobs[15]
    cdef char  cchars[15]
    cdef int i, j, k
    cdef float r
    line = ' ' * width
    # buf is a pointer to the contents of line
    cdef char* buf = line
    cdef int bisect
    cdef float bisect_prob
    for i in range(len(table)):
        cprobs[i] = probs[i]
        cchars[i] = ord(chars[i])
    
    for j in xrange(n // width):
        for i in range(width):
            r = pseudo_random(1.0)
            k = (r >= cprobs[0]) + (r >= cprobs[1]) + (r >= cprobs[2])
            while cprobs[k] < r:
                k += 1            
            buf[i] = cchars[k]
        print line

    if n % width:
        for i in range(n % width):
            r = pseudo_random(1.0)
            k = 0
            while cprobs[k] < r:
                k += 1            
            buf[i] = cchars[k]
        print line[:n % width]

if __name__ == '__main__':
    try:
        n = int(sys.argv[1])
    except IndexError:
        n = 25000000

    print '>ONE Homo sapiens alu'
    repeatFasta(alu, n*2)

    print '>TWO IUB ambiguity codes'
    randomFasta(iub, n*3)

    print '>THREE Homo sapiens frequency'
    randomFasta(homosapiens, n*5)
