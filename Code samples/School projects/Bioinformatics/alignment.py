#! /usr/bin/env python
#By Elana Bogdan and Emily Dolson
#CPSC 68: Bioinformatics, Lab 2

from sys import *
import copy

def main():
    if len(argv) != 5:
        print "Usage: seq file, sub matrix, gap init penalty, extend penalty"
        exit()

    #Attempt to load files
    try:
        subfile = open(argv[2], "r")
    except:
        exit("Could not access substitution matrix.")

    try:
        seqfile = open(argv[1], "r")
    except:
        exit("Could not access sequences.")

    d = setsub(subfile)
    subfile.close()

    s = storeseq(seqfile)
    seqfile.close()

    M, I_x, I_y, PM, PI_x, PI_y = initMats(len(s[0])+1, len(s[1])+1)
    h, g = argv[3:]
    h = int(h) #gap initialization penalty
    g = int(g) #gap extension penalty

    #define functions to be used within main for ease of updating matrices
    def setM(i, j):
        """
        Sets values in the M matrix and associated pointer matrix by selecting
        the move with the highest value from the available in the M matrix.
        Input: i - current row, j - current column
        """
        subscore = d[s[0][i-1]][s[1][j-1]] #We subtract 1 from i and
                       #j because of the header row and column in the matrix
        values = [I_x[i-1][j-1]+subscore, M[i-1][j-1]+subscore,\
                  I_y[i-1][j-1]+subscore, 0] #possible moves
        M[i][j] = max(values)
        PM[i][j] = values.index(max(values))

    def setI_x(i, j):
        """
        Sets values in the Ix matrix and associated pointer matrix by selecting
        the move with the highest value from the available in the Ix matrix.
        Input: i - current row, j - current column
        """
        values = [I_x[i-1][j]+g, M[i-1][j]+h+g] #possible moves
        I_x[i][j] = max(values)
        PI_x[i][j] = values.index(max(values))

    def setI_y(i, j):
        """
        Sets values in the Iy matrix and associated pointer matrix by selecting
        the move with the highest value from the available in the Iy matrix.
        Input: i - current row, j - current column
        """
        values = [M[i][j-1]+h+g, I_y[i][j-1]+g] #possible moves
        I_y[i][j] = max(values)
        PI_y[i][j] = values.index(max(values))

    best = [0, 0]

    #iterate through matrices filling in optimal values
    for i in range(1, len(M)):
        for j in range(1, len(M[0])):
            setM(i, j)
            setI_x(i, j)
            setI_y(i, j)

            if M[i][j] >= M[best[0]][best[1]]: #Updates to hold best score
                best[0], best[1] = i, j       #found so far
            
    print "\nTotal alignment score: "+str(M[best[0]][best[1]])

    alignX, alignY = traceback([I_x, M, I_y], [PI_x, PM, PI_y], s, best, 1)
    print "\nAlignment: "
    print alignX[::-1]+"\n"+alignY[::-1]+"\n"

def printMats(mats):
    """
    Formats and cleanly displays list of matrices for debugging purposes
    Input: mats - a list of matrices to be printed
    """
    for mat in mats:
        for line in mat:
            outstring = ''
            for elt in line:
                outstring += ("\t"+str(elt))
            print outstring
        print "\n"

def setsub(infile):
    """
    Reads in a substitution score matrix and generates a dictionary of
    dictionaries for he putposes of easily looking up the score between two
    amino acids.
    Input: infile - a file object containing a text table of amino acids and
    substitution values. The first line should indicate which column represents
    each amino acid, and all subsequent lines should start with an amino acid
    code and then contain scores associated with substituting that amino acid
    for the others.
    Returns: A dictionary containing dictionaries for each amino acid in which
    the keys are all other amino acids and the values are the substitution
    scores.
    """
    D = {}

    ref = [aa.strip() for aa in infile.readline().split()]

    for line in infile:
        line = line.split()
        line = [item.strip() for item in line]
        D[line[0]] = {}
        for i in range(1, len(line)):
            D[line[0]][ref[i-1]] = int(line[i])
    return D


def storeseq(infile):
    """
    Extracts two sequences from a file.
    Inputs: infile - a file object containing two sequences to align.
    The sequences should each be on their own lines. Lines starting with
    whitespace or a # will be ignored.
    Returns: A list containing two strings representing the two sequences.
    """
    S = ['','']
    n = 0

    while n < 2:
        line = infile.readline()
        if not line[0] in ('#','\n','\r',' '):
            S[n] = line.strip()
            n = n+1
    return S


def initMats(x, y):
    """
    Create and initialize working matrices Inputs: x - the number of
    rows, y - the number of columns Returns: a list of six matrics: M
    (the matrix where bases are aligned with each other), I_x (the
    matrix where sequence Y is aligned with a gap), I_y (the matrix
    where sequence X is aligned with a gap, PM (the matrix
    representing the optimal directions to go in from each square in
    M), PI_x (the matrix representing the optimal directions to go in
    from each square in PI_x), PI_y (the matrix representing the
    optimal directions to go in from each square in PI_y)
    """
    M = [[-float('inf')]*y for i in range(x)] #First seq runs down (i), second runs across (j)
    I_x = copy.deepcopy(M)
    I_y = copy.deepcopy(M)
    PM = copy.deepcopy(M)
    PI_x = copy.deepcopy(M)
    PI_y = copy.deepcopy(M)

    for i in M:
        i[0] = 0

    for j in range(len(M[0])): #Alternately, M[0] = [0]*len(M[0])
        M[0][j] = 0

    return M, I_x, I_y, PM, PI_x, PI_y


def traceback(mats, pmats, seqs, pos, level):
    """
    Recursively traces back through the matrices to determine the optimal
    alignment path through them.
    Inputs: mats - a list of value matrices in the order [I_x, M, I_y]
    pmats - a list of pointer matrices in the order [PI_x, PM, PI_y]
    seqs - a list of two strings representing the sequences being aligned
    pos - a list of two ints representing the current location in the matrices
    level - an int specifying which matrix to move in (0 - I_x, 1 = M, 2 = I_y)
    Returns: two strings containing amino acid codes and gaps to represent
    the best local alignment between the two sequences.
    """
    if mats[level][pos[0]][pos[1]] == 0: #beggining of local alignment
        return "",""
    elif level == 1: #In matrix M
        temp = traceback(mats, pmats, seqs, [pos[0]-1, pos[1]-1],\
                         pmats[level][pos[0]][pos[1]])
        #add an element from each sequence
        return seqs[0][pos[0]-1]+temp[0], seqs[1][pos[1]-1]+temp[1]
    
    elif level == 0: #In matrix I_x
        temp = traceback(mats, pmats, seqs, [pos[0]-1, pos[1]],
                         pmats[level][pos[0]][pos[1]])
        #add an element from the first sequence and a gap for the second
        return seqs[0][pos[0]-1]+temp[0], "-"+temp[1]
    
    elif level == 2: #In matrix I_y
        temp = traceback(mats, pmats, seqs, [pos[0], pos[1]-1], \
                         pmats[level][pos[0]][pos[1]]+1)
        #add a gap for the first sequence and an element from the second
        return "-"+temp[0], seqs[1][pos[1]-1]+temp[1]
    
    else: #this should never happen
        print "Error in traceback"

if __name__ == "__main__":
    main()
