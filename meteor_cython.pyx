# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org/
#
# contributed by Christian Vosteen
# cythonized by Robert Bradshaw

# cython: infer_types=True
 
from stdio cimport *
from stdlib cimport *

cdef extern from *:
    void qsort (void *base, unsigned short n, unsigned short w, int (*cmp_func)(void*, void*))


# The board is a 50 cell hexagonal pattern.  For    . . . . .
# maximum speed the board will be implemented as     . . . . .
# 50 bits, which will fit into a 64 bit long long   . . . . .
# int.                                               . . . . .
#                                                   . . . . .
# I will represent 0's as empty cells and 1's        . . . . .
# as full cells.                                    . . . . .
#                                                    . . . . .
#                                                   . . . . .
#                                                    . . . . .
#

cdef unsigned long long board = 0xFFFC000000000000ULL

# The puzzle pieces must be specified by the path followed
# from one end to the other along 12 hexagonal directions.
#
#   Piece 0   Piece 1   Piece 2   Piece 3   Piece 4
#
#  O O O O    O   O O   O O O     O O O     O   O
#         O    O O           O       O       O O
#                           O         O         O
#
#   Piece 5   Piece 6   Piece 7   Piece 8   Piece 9
#
#    O O O     O O       O O     O O        O O O O
#       O O       O O       O       O O O        O
#                  O       O O
#
# I had to make it 12 directions because I wanted all of the
# piece definitions to fit into the same size arrays.  It is
# not possible to define piece 4 in terms of the 6 cardinal
# directions in 4 moves.
#

cdef char E     = 0
cdef char ESE   = 1
cdef char SE    = 2
cdef char S     = 3
cdef char SW    = 4
cdef char WSW   = 5
cdef char W     = 6
cdef char WNW   = 7
cdef char NW    = 8
cdef char N     = 9
cdef char NE    = 10
cdef char ENE   = 11
cdef char PIVOT = 12

piece_list = [
    [  E,  E,  E, SE],
    [ SE,  E, NE,  E],
    [  E,  E, SE, SW],
    [  E,  E, SW, SE],
    [ SE,  E, NE,  S],
    [  E,  E, SW,  E],
    [  E, SE, SE, NE],
    [  E, SE, SE,  W],
    [  E, SE,  E,  E],
    [  E,  E,  E, SW]
]
cdef char piece_def[10][4]
for i, piece in enumerate(piece_list):
    for j, dir in enumerate(piece):
        piece_def[i][j] = dir


# To minimize the amount of work done in the recursive solve function below,
# I'm going to allocate enough space for all legal rotations of each piece
# at each position on the board. That's 10 pieces x 50 board positions x
# 12 rotations.  However, not all 12 rotations will fit on every cell, so
# I'll have to keep count of the actual number that do.
# The pieces are going to be unsigned long long ints just like the board so
# they can be bitwise-anded with the board to determine if they fit.
# I'm also going to record the next possible open cell for each piece and
# location to reduce the burden on the solve function.
#
cdef unsigned long long pieces[10][50][12]
cdef int piece_counts[10][50]
cdef char next_cell[10][50][12]


# Returns the direction rotated 60 degrees clockwise
cdef char rotate(char dir):
    return (dir + 2) % PIVOT

# Returns the direction flipped on the horizontal axis
cdef char flip(char dir):
    return (PIVOT - dir) % PIVOT


# Returns the new cell index from the specified cell in the
# specified direction.  The index is only valid if the
# starting cell and direction have been checked by the
# out_of_bounds function first.
#
cdef char shift(char cell, char dir):
# TODO don't branch on %2
        if dir == E:
            return cell + 1
        elif dir == ESE:
            if (cell / 5) % 2:
                return cell + 7
            else:
                return cell + 6
        elif dir == SE:
            if (cell / 5) % 2:
                return cell + 6
            else:
                return cell + 5
        elif dir == S:
            return cell + 10
        elif dir == SW:
            if (cell / 5) % 2:
                return cell + 5
            else:
                return cell + 4
        elif dir == WSW:
            if (cell / 5) % 2:
                return cell + 4
            else:
                return cell + 3
        elif dir == W:
            return cell - 1
        elif dir == WNW:
            if (cell / 5) % 2:
                return cell - 6
            else:
                return cell - 7
        elif dir == NW:
            if (cell / 5) % 2:
                return cell - 5
            else:
                return cell - 6
        elif dir == N:
            return cell - 10
        elif dir == NE:
            if (cell / 5) % 2:
                return cell - 4
            else:
                return cell - 5
        elif dir == ENE:
            if (cell / 5) % 2:
                return cell - 3
            else:
                return cell - 4
        else:
            return cell

# Returns wether the specified cell and direction will land outside
# of the board.  Used to determine if a piece is at a legal board
# location or not.
#
cdef bint out_of_bounds(char cell, char dir):
        cdef char i
        if dir == E:
            return cell % 5 == 4
        elif dir == ESE:
            i = cell % 10
            return i == 4 or i == 8 or i == 9 or cell >= 45
        elif dir == SE:
            return cell % 10 == 9 or cell >= 45
        elif dir == S:
            return cell >= 40
        elif dir == SW:
            return cell % 10 == 0 or cell >= 45
        elif dir == WSW:
            i = cell % 10
            return i == 0 or i == 1 or i == 5 or cell >= 45
        elif dir == W:
            return cell % 5 == 0
        elif dir == WNW:
            i = cell % 10
            return i == 0 or i == 1 or i == 5 or cell < 5
        elif dir == NW:
            return cell % 10 == 0 or cell < 5
        elif dir == N:
            return cell < 10
        elif dir == NE:
            return cell % 10 == 9 or cell < 5
        elif dir == ENE:
            i = cell % 10
            return i == 4 or i == 8 or i == 9 or cell < 5
        else:
            return False

# Rotate a piece 60 degrees clockwise
cdef void rotate_piece(int piece):
    for i in range(4):
        piece_def[piece][i] = rotate(piece_def[piece][i])

# Flip a piece along the horizontal axis
cdef void flip_piece(int piece):
    for i in range(4):
        piece_def[piece][i] = flip(piece_def[piece][i])

# Convenience function to quickly calculate all of the indices for a piece
cdef void calc_cell_indices(char *cell, int piece, char index):
    cell[0] = index
    cell[1] = shift(cell[0], piece_def[piece][0])
    cell[2] = shift(cell[1], piece_def[piece][1])
    cell[3] = shift(cell[2], piece_def[piece][2])
    cell[4] = shift(cell[3], piece_def[piece][3])


# Convenience function to quickly calculate if a piece fits on the board
cdef int cells_fit_on_board(char *cell, int piece):
    return (not out_of_bounds(cell[0], piece_def[piece][0]) and
            not out_of_bounds(cell[1], piece_def[piece][1]) and
            not out_of_bounds(cell[2], piece_def[piece][2]) and
            not out_of_bounds(cell[3], piece_def[piece][3]))

# Returns the lowest index of the cells of a piece.
# I use the lowest index that a piece occupies as the index for looking up
# the piece in the solve function.
#
cdef char minimum_of_cells(char *cell):
     # TODO min(...)
    cdef char minimum = cell[0]
    if cell[1] < minimum: minimum = cell[1]
    if cell[2] < minimum: minimum = cell[2]
    if cell[3] < minimum: minimum = cell[3]
    if cell[4] < minimum: minimum = cell[4]
    return minimum

# Calculate the lowest possible open cell if the piece is placed on the board.
# Used to later reduce the amount of time searching for open cells in the
# solve function.
#
cdef char first_empty_cell(char *cell, char minimum):
    cdef char first_empty = minimum
    # TODO: in ...
    while(first_empty == cell[0] or first_empty == cell[1] or
            first_empty == cell[2] or first_empty == cell[3] or
            first_empty == cell[4]):
        first_empty += 1
    return first_empty


# Generate the unsigned long long int that will later be anded with the
# board to determine if it fits.
#
cdef unsigned long long bitmask_from_cells(char *cell):
    cdef unsigned long long piece_mask = 0ULL
    for i in range(5):
        piece_mask |= 1ULL << cell[i]
    return piece_mask

# Record the piece and other important information in arrays that will
# later be used by the solve function.
#
cdef void record_piece(int piece, int minimum, char first_empty,
        unsigned long long piece_mask):
    pieces[piece][minimum][piece_counts[piece][minimum]] = piece_mask
    next_cell[piece][minimum][piece_counts[piece][minimum]] = first_empty
    piece_counts[piece][minimum] += 1



# Fill the entire board going cell by cell.  If any cells are "trapped"
# they will be left alone.
#
cdef void fill_contiguous_space(char *board, int index):
    if board[index] == 1:
        return
    board[index] = 1
    if not out_of_bounds(index, E):
        fill_contiguous_space(board, shift(index, E))
    if not out_of_bounds(index, SE):
        fill_contiguous_space(board, shift(index, SE))
    if not out_of_bounds(index, SW):
        fill_contiguous_space(board, shift(index, SW))
    if not out_of_bounds(index, W):
        fill_contiguous_space(board, shift(index, W))
    if not out_of_bounds(index, NW):
        fill_contiguous_space(board, shift(index, NW))
    if not out_of_bounds(index, NE):
        fill_contiguous_space(board, shift(index, NE))


# To thin the number of pieces, I calculate if any of them trap any empty
# cells at the edges.  There are only a handful of exceptions where the
# the board can be solved with the trapped cells.  For example:  piece 8 can
# trap 5 cells in the corner, but piece 3 can fit in those cells, or piece 0
# can split the board in half where both halves are viable.
#
cdef bint has_island(char *cell, int piece):
    cdef char temp_board[50]
    cdef char c
    cdef int i
    # TODO: memset
    for i in range(50):
        temp_board[i] = 0
    for i in range(5):
        temp_board[<int>cell[i]] = 1
    i = 49
    while temp_board[i] == 1:
        i -= 1
    fill_contiguous_space(temp_board, i)
    c = 0
    for i in range(50):
        if temp_board[i] == 0:
            c += 1
    return not (c == 0 or (c == 5 and piece == 8) or (c == 40 and piece == 8) or
            (c % 5 == 0 and piece == 0))


# Calculate all six rotations of the specified piece at the specified index.
# We calculate only half of piece 3's rotations.  This is because any solution
# found has an identical solution rotated 180 degrees.  Thus we can reduce the
# number of attempted pieces in the solve algorithm by not including the 180-
# degree-rotated pieces of ONE of the pieces.  I chose piece 3 because it gave
# me the best time )
#
cdef void calc_six_rotations(char piece, char index):
    cdef char rotation, cell[5]
    cdef char minimum, first_empty
    cdef unsigned long long piece_mask

    for rotation in range(6):
        if piece != 3 or rotation < 3:
            calc_cell_indices(cell, piece, index)
            if cells_fit_on_board(cell, piece) and not has_island(cell, piece):
                minimum = minimum_of_cells(cell)
                first_empty = first_empty_cell(cell, minimum)
                piece_mask = bitmask_from_cells(cell)
                record_piece(piece, minimum, first_empty, piece_mask)
        rotate_piece(piece)

# Calculate every legal rotation for each piece at each board location.
cdef void calc_pieces():
    cdef char piece, index

    for piece in range(10):
        for index in range(50):
            calc_six_rotations(piece, index)
            flip_piece(piece)
            calc_six_rotations(piece, index)


# Calculate all 32 possible states for a 5-bit row and all rows that will
# create islands that follow any of the 32 possible rows.  These pre-
# calculated 5-bit rows will be used to find islands in a partially solved
# board in the solve function.
#
cdef unsigned long long ROW_MASK = 0x1F
cdef unsigned long long TRIPLE_MASK = 0x7FFF
cdef char all_rows[32]

# We need a better way to do this...
# range?
for i,v in enumerate([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]):
     all_rows[i] = v

cdef int bad_even_rows[32][32]
cdef int bad_odd_rows[32][32]
cdef int bad_even_triple[32768]
cdef int bad_odd_triple[32768]

cdef int rows_bad(char row1, char row2, bint even):
    # even is referring to row1
    cdef int i, in_zeroes, group_okay
    cdef char block, row2_shift
    # Test for blockages at same index and shifted index
    if even:
        row2_shift = ((row2 << 1) & ROW_MASK) | 0x01
    else:
        row2_shift = (row2 >> 1) | 0x10
    block = ((row1 ^ row2) & row2) & ((row1 ^ row2_shift) & row2_shift)
    # Test for groups of 0's
    in_zeroes = False
    group_okay = False
    for i in range(5):
        if row1 & (1 << i):
            if in_zeroes:
                if not group_okay:
                    return True
                in_zeroes = False
                group_okay = False
        else:
            if not in_zeroes:
                in_zeroes = True
            if not (block & (1 << i)):
                group_okay = True
    if in_zeroes:
        return not group_okay
    else:
        return False

# Check for cases where three rows checked sequentially cause a False
# positive.  One scenario is when 5 cells may be surrounded where piece 5
# or 7 can fit.  The other scenario is when piece 2 creates a hook shape.
#
cdef int triple_is_okay(char row1, char row2, char row3, int even):
    if even:
        # There are four cases:
        #  row1: 00011  00001  11001  10101
        #  row2: 01011  00101  10001  10001
        #  row3: 011??  00110  ?????  ?????
        
        return (((row1 == 0x03) and (row2 == 0x0B) and ((row3 & 0x1C) == 0x0C)) or
                ((row1 == 0x01) and (row2 == 0x05) and (row3 == 0x06)) or
                ((row1 == 0x19) and (row2 == 0x11)) or
                ((row1 == 0x15) and (row2 == 0x11)))
    else:
        # There are two cases:
        #  row1: 10011  10101
        #  row2: 10001  10001
        #  row3: ?????  ?????
        
        return ((row1 == 0x13) and (row2 == 0x11)) or ((row1 == 0x15) and (row2 == 0x11))


cdef void calc_rows():
    cdef int row1, row2, row3
    cdef int result1, result2
    for row1 in range(32):
        for row2 in range(32):
            bad_even_rows[row1][row2] = rows_bad(row1, row2, True)
            bad_odd_rows[row1][row2] = rows_bad(row1, row2, False)
    for row1 in range(32):
        for row2 in range(32):
            for row3 in range(32):
                result1 = bad_even_rows[row1][row2]
                result2 = bad_odd_rows[row2][row3]
                if (result1 == False and result2 == True
                        and triple_is_okay(row1, row2, row3, True)):
                    bad_even_triple[row1+(row2*32)+(row3*1024)] = False
                else:
                    bad_even_triple[row1+(row2*32)+(row3*1024)] = result1 or result2

                result1 = bad_odd_rows[row1][row2]
                result2 = bad_even_rows[row2][row3]
                if (result1 == False and result2 == True
                        and triple_is_okay(row1, row2, row3, False)):
                    bad_odd_triple[row1+(row2*32)+(row3*1024)] = False
                else:
                    bad_odd_triple[row1+(row2*32)+(row3*1024)] = result1 or result2


# Calculate islands while solving the board.
#
cdef bint boardHasIslands(char cell):
    # Too low on board, don't bother checking
    if cell >= 40:
        return False
    cdef int current_triple = (board >> ((cell / 5) * 5)) & TRIPLE_MASK
    if (cell / 5) % 2:
        return bad_odd_triple[current_triple]
    else:
        return bad_even_triple[current_triple]


# The recursive solve algorithm.  Try to place each permutation in the upper-
# leftmost empty cell.  Mark off available pieces as it goes along.
# Because the board is a bit mask, the piece number and bit mask must be saved
# at each successful piece placement.  This data is used to create a 50 char
# array if a solution is found.
#
cdef short avail = 0x03FF
cdef char sol_nums[10]
cdef unsigned long long sol_masks[10]
cdef signed char solutions[2100][50]
cdef int solution_count = 0
cdef int max_solutions = 2100

cdef void record_solution():
    global solution_count
    cdef int sol_no, index
    cdef unsigned long long sol_mask
    for sol_no in range(10):
        sol_mask = sol_masks[sol_no]
        for index in range(50):
            if sol_mask & 1ULL:
                solutions[solution_count][index] = sol_nums[sol_no]
                # Board rotated 180 degrees is a solution too!
                solutions[solution_count+1][49-index] = sol_nums[sol_no]
            sol_mask = sol_mask >> 1
    solution_count += 2

cdef void solve(int depth, int cell):
    global board, avail
    cdef int piece, rotation, max_rots
    cdef unsigned long long *piece_mask
    cdef short piece_no_mask

    if solution_count >= max_solutions:
        return

    while board & (1ULL << cell):
        cell += 1

    for piece in range(10):
        piece_no_mask = 1 << piece
        if not (avail & piece_no_mask):
            continue
        avail ^= piece_no_mask
        max_rots = piece_counts[piece][cell]
        piece_mask = pieces[piece][cell]
        for rotation in range(max_rots):
            if not (board & (piece_mask + rotation)[0]):
                sol_nums[depth] = piece
                sol_masks[depth] = (piece_mask + rotation)[0]
                if depth == 9:
                    # Solution found!!!!!11!!ONE!
                    record_solution()
                    avail ^= piece_no_mask
                    return
                board |= (piece_mask + rotation)[0]
                if not boardHasIslands(next_cell[piece][cell][rotation]):
                    solve(depth + 1, next_cell[piece][cell][rotation])
                board ^= (piece_mask + rotation)[0]
        avail ^= piece_no_mask


# qsort comparator - used to find first and last solutions
cdef int solution_sort(void *elem1, void *elem2):
    cdef signed char *char1 = <signed char *> elem1
    cdef signed char *char2 = <signed char *> elem2
    cdef int i = 0
    while i < 50 and char1[i] == char2[i]:
        i += 1
    return char1[i] - char2[i]


# pretty print a board in the specified hexagonal format
cdef bint pretty(signed char *b) except -1:
    cdef int i
    for i in range(0, 50, 10):
        print (' '.join([str(c) for c in b[i:i+5]]) +
                ' \n ' +
                ' '.join([str(c) for c in b[i+5:i+10]]))
    print

if __name__ == '__main__':
    from sys import argv
    if len(argv) > 1:
        max_solutions = int(argv[1])
    calc_pieces()
    calc_rows()
    
    if 0:
        print "pieces"
        for i in range(10):
            for j in range(50):
                print i, j, ' '.join([hex(pieces[i][j][k])[2:-1] for k in range(12)])

        print "piece_counts"
        for i in range(10):
            print [piece_counts[i][j] for j in range(50)]

        print "next_cell"
        for i in range(10):
            for j in range(50):
                print [next_cell[i][j][k] for k in range(12)]

    
    solve(0, 0)
    printf("%d solutions found\n\n", solution_count)
    qsort(solutions, solution_count, 50 * sizeof(signed char), solution_sort)
    pretty(solutions[0])
    pretty(solutions[solution_count-1])
