cdef extern from "binary_tree_cython.h":
    object PY_NEW(object, args)
    void disable_gc(object)

cdef class Node:
    cdef Node left
    cdef Node right
    cdef long item

cdef Node make_tree(long item, long depth):
    cdef Node t = <Node>PY_NEW(Node, ())
    t.item = item
    if depth:
        depth -= 1
        item <<= 1
        t.left = make_tree(item - 1, depth)
        t.right = make_tree(item, depth)
    return t

cdef long check_tree(Node t):
    if t.left is None:
        return t.item
    else:
        return t.item + check_tree(t.left) - check_tree(t.right)


def test(int n):

    # By definition, trees can't have cycles. However, Python's garbage
    # collector will do lots of wasteful tree traversals to try to collect 
    # circular references. Normal reference counting still happens. 
    import gc
    gc.disable()

    cdef int min_depth, max_depth, stretch_depth, depth
    min_depth = 4
    max_depth = max(min_depth + 2, n)
    stretch_depth = max_depth + 1
    
    cdef int i, iterations
    cdef long check

    print "stretch tree of depth %d\t check:" % stretch_depth, check_tree(make_tree(0, stretch_depth))

    long_lived_tree = make_tree(0, max_depth)

    iterations = 1 << max_depth
    for depth in xrange(min_depth, stretch_depth, 2):

        check = 0
        for i in xrange(1, iterations + 1):
            check += check_tree(make_tree(i, depth))
            check += check_tree(make_tree(-i, depth))

        print "%d\t trees of depth %d\t check:" % (iterations * 2, depth), check
        iterations /= 4

    print "long lived tree of depth %d\t check:" % max_depth, check_tree(long_lived_tree)
