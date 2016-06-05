#!/usr/bin/python
#CS68: Bioinformatics, Lab 5, 4/1/13
#By Elana Bogdan and Emily Dolson

import sys, os
from math import log

def main():

    #Make sure command line arguments are valid
    if len(sys.argv) < 6:
        print "Usage: ./geneFinder.py modelOrder inhomogeneous? seqFile knownGenes testSeqs"
        exit()

    order = sys.argv[1]
    try:
        order = int(order)
    except:
        print "Invalid model order. Integer required."
        print "Usage: ./geneFinder.py modelOrder inhomogeneous? seqFile knownGenes testSeqs"
        exit()

    inhomogeneous = sys.argv[2]
    try:
        inhomogeneous = bool(eval(inhomogeneous))
    except:
        print "Invalid homogeneity. Bool required."
        print "Usage: ./geneFinder.py modelOrder inhomogeneous? seqFile knownGenes testSeqs"
        exit()

    #Check that file names are valid
    for i in range(3,6):
        if not os.path.exists(sys.argv[i]):
            print "Invalid file name entered: "+sys.argv[i]
            print "Usage: ./geneFinder.py modelOrder inhomogeneous? seqFile knownGenes testSeqs"
            exit()

    #Parse files
    sequence = parseSeqFile(sys.argv[3])
    knownSeqs = parseIndexFile(sys.argv[4])
    testSeqs = parseIndexFile(sys.argv[5])

    #Train model
    coding, noncoding = sortData(sequence, knownSeqs)
    codingWeights, codingStatic = trainModel(coding, order, inhomogeneous)
    noncodingWeights, noncodingStatic = trainModel(noncoding, order, inhomogeneous)

    #Test model
    evaluateSequences([codingWeights, noncodingWeights], \
                      [codingStatic, noncodingStatic], \
                      testSeqs, sequence, order, inhomogeneous)

    
def parseSeqFile(seqFile):
    """
    Parses a file containing a sequence.
    Input: seqfile - a string indicating the name of the file containing the sequence
    Returns sequence (list of characters)
    """
    infile = open(seqFile, "r")
    sequence = []
    for line in infile:
        for ch in line.strip():
            sequence.append(ch)

    infile.close()
    return sequence

def parseIndexFile(indexFile):
    """
    Parses a file containing indices in the sequence where coding regions or
    suspected coding regions start and stop.
    Input: indexFile - string indicating name of file containing indices for
    either training or testing
    Returns: Contents of file in list form
    """
    infile = open(indexFile, "r")
    data = []
    for line in infile:
        cleanedLine = line.strip().split()
        try: # This simultaneously ignores invalid lines and casts indices to ints;
             # 1s are subtracted to simplify indexing in rest of the program.
            cleanedLine[len(cleanedLine)-2] = int(cleanedLine[len(cleanedLine)-2])-1
            cleanedLine[len(cleanedLine)-3] = int(cleanedLine[len(cleanedLine)-3])-1
            data.append(cleanedLine)
        except:
            continue
        
    infile.close()
    return data

def sortData(sequence, indices):
    """
    Sorts out coding regions and noncoding regions
    Input: sequence - the entire DNA sequence
    indices - the indices at which genese start and stop
    Returns: two lists of lists of characters indicating codingRegions and noncodingRegions
    """
    cursor = 0
    codingRegions = []
    noncodingRegions = []
    for gene in indices:
        #If extra space between genes, assign to noncoding
        if cursor < gene[2]:
            noncoding = sequence[cursor:gene[2]]
            noncodingRegions.append(noncoding)
            noncodingRegions.append(invert(noncoding))

        coding = sequence[gene[2]:gene[3]+1]

        #Adjust for genes on complementary strand
        if gene[4] == "<":
            coding = invert(coding)
        codingRegions.append(coding)

        #Only move cursor forwards (handles genes within genes)
        if cursor < gene[3] + 1:
            cursor = gene[3] + 1
            
    return codingRegions, noncodingRegions
        

def invert(sequence):
    """
    Generates the complementary strand from the given sequence.
    Input: sequence - a list of characters
    Returns a list of characters contining the complement of the sequence
    """
    cDict = {"a":"t", "t":"a", "c":"g", "g":"c"}
    compStrand = []
    for i in range(len(sequence)-1, -1, -1):
        compStrand.append(cDict[sequence[i]])
    return compStrand

def trainModel(sequences, order, inhomogeneous):
    """
    Takes a list of either coding or noncoding lists and returns dictionaries
    containing order-length sequences as keys and either probabilities (for 0-
    order) or further dictionaries (pairing transitional bases with probalities
    of transition) as values
    """
    edgeWeights = [initDict(order)]
    for i in range(2*inhomogeneous):
        edgeWeights.append(initDict(order))
    
    for seq in sequences:
        for i in range(len(seq)-order):
            key = "".join(seq[i:i+max(order, 1)])
            if order == 0:
                edgeWeights[i%3*inhomogeneous][key] += 1
                
            else:
                nextBase = seq[i+order]
                edgeWeights[i%3*inhomogeneous][key][nextBase] += 1   

    staticProbs = {}
    if order > 0:
        #Calculate total counts of sequences of length "order"
        denominator = 0
        for value in edgeWeights[0].values():
            denominator += sum(value.values())

        #Calculate probability of starting with given order-length sequence
        for key in edgeWeights[0].keys():
            staticProbs[key] = sum(edgeWeights[0][key].values())/denominator

        #Convert counts to probabilities through normalization
        for frame in edgeWeights:
            for prefix in frame.keys():
                totalCount = sum(frame[prefix].values())
                for symbol in frame[prefix].keys():
                    frame[prefix][symbol] /= totalCount
                     
    else:
        #Normalize for 0-order
        for frame in edgeWeights:
            totalCount = sum(frame.values())
            for base in frame.keys():
                frame[base] /= totalCount

    return edgeWeights, staticProbs

def initDict(order):
    """
    Takes value indicating number of antecedent bases in Markov
    dependency and generates dictionary in which to store edge scores.
    """
    zeroth = (order == 0)
    order = max(order-1, 0)
    alphabet = ["a","c","g","t"]
    modOrder = 4**order
    keys = ["" for i in range(4**(order+1))]

    #Builds up index of all possible sequences of length "order"
    while (modOrder > 0):
        for i in range(4**(order+1)):
            keys[i] += alphabet[(i/modOrder)%4]
        modOrder /= 4
        
    if zeroth:
        #Initializes to 1 for Laplace
        return dict.fromkeys(keys, 1.)
    else:
        returnDict = {}
        for key in keys:
            returnDict[key] = {}
            for alpha in alphabet:
                #Again sets to 1 for Laplace
                returnDict[key][alpha] = 1.
        return returnDict

def evaluateSequences(weights, statics, testSeqs, sequence, order, inhomogeneous):
    """
    Compares scoring based on coding and noncoding models for each test sequence,
    then prints the results, along with precision, recall, and overall accuracy.
    """
    truePos = 0.
    falsePos = 0.
    trueNeg = 0.
    falseNeg = 0.
    
    for seq in testSeqs:
        scores = [0, 0]
        for i in range(2):
            scores[i] = calculateScore(weights[i], statics[i], \
                                       sequence[seq[0]:seq[1]+1], \
                                       order, inhomogeneous)
        result = ""
        if scores[0] > scores[1]:
            result = "+"
        else:
            result = "-"

        if result == seq[2]:
            if result == "+":
                truePos += 1
            else:
                trueNeg += 1
        else:
            if result == "+":
                falsePos += 1
            else:
                falseNeg += 1
            
        print seq[0]+1, seq[1]+1, seq[2], result, scores[1], scores[0]

    precision = truePos/(truePos+falsePos)
    recall = truePos/(truePos + falseNeg)
    accuracy = (truePos + trueNeg)/(falsePos+falseNeg+truePos+trueNeg)
    print "Precision:", precision
    print "Recall:", recall
    print "Overall Accuracy:", accuracy
        

def calculateScore(weights, static, testSeq, order, inhomogeneous):
    """
    Helper function which uses log odds to assess probability of
    deriving sequence testSeq from the parameters contained in
    weights and static.
    """
    #Initialize score 
    score = 0 if order == 0 else log(static["".join(testSeq[:order])])
    for i in range(len(testSeq)-order):
        if order > 0:
            score += log(weights[i%3*inhomogeneous]["".join(testSeq[i:i+order])][testSeq[i+order]])
        else:
            score += log(weights[i%3*inhomogeneous][testSeq[i]])
    return score
        

main()
