#!/usr/bin/python
#CS68 Lab 4, By Elana Bogdan and Emily Dolson

import sys, os

def main():
    #make sure command line arguments are valid
    if len(sys.argv) < 4:
        print "Usage: ./weightedParsimony treeFile weightFile seqFile"
        exit()
    for i in range(3):
        if not os.path.exists(sys.argv[i+1]):
            print "Invalid file specified."
            exit()

    #parse files
    tree, root = parseTree(sys.argv[1])
    distances = readDistances(sys.argv[2])
    outlist = [key+": " for key in tree.keys()]

    counter = 0
    score = 0
    alphabet = ["A", "C", "T", "G"]
    while parseSeq(sys.argv[3], tree, counter):
        counter += 1

        #Run all options on root
        for c in alphabet:
            weightedParsimony(tree, root, c, distances, alphabet)

        #Traceback
        score += root.saveTrace()
        for i in range(len(outlist)):
            outlist[i] += tree[tree.keys()[i]].getBest()
        resetTree(tree, alphabet)

    print "\nTotal score:", score,"\n"
    for item in outlist:
        print item
    print

def weightedParsimony(tree, node, character, distances, alphabet):
    """
    Recursively runs the weighted parsimony algorithm to populate internal
    node variables with the correct values for each potential base, and the
    path used to get there.
    Inputs: tree - a dictionary in which keys are the node labels specified in
    the file and the nodes are corresponding node objects
    node - the current node in the recursion (should be root for inital call)
    distances - a dictionary of dictionaries in which the value of the
    second key is the distance between the first key and the second key.
    alphabet - the potential values for each node
    Returns: nothing
    """
    if node.getValue("A") == -1: #node is not a leaf
        i = node.getChildren()[0]
        j = node.getChildren()[1]
        
        for c in alphabet:
            #Variables to hold best choice
            minI = 10000
            minIChar = ''
            minJ = 10000
            minJChar = '' #Variable named in honor of J. Chartove '14

            #Make recursive call to fill in lower portion of tree
            weightedParsimony(tree, i, c, distances, alphabet)
            weightedParsimony(tree, j, c, distances, alphabet)

            #Find lowest-score value to use in this scenario
            for b in alphabet:
                dist = distances[c][b]

                #Best choice for child i
                if dist+i.getValue(b) < minI:
                    minI = dist+i.getValue(b)
                    minIChar = b

                #Best choice for child j
                if dist+j.getValue(b) < minJ:
                    minJ = dist+j.getValue(b)
                    minJChar = b

            #Store best value and path in current node 
            node.setValue(c, minI+minJ)
            node.setPath(c, minIChar, minJChar) 

def printTree(tree):
    """
    Prints all of the nodes in the inputted tree, and their labels.
    """
    keys = tree.keys()
    keys.sort()
    for key in keys:
        print key + ":", tree[key]

def resetTree(tree, alphabet):
    """
    Resets the values in a tree to -1 while preserving the structure
    Inputs: tree - a dictionary in which keys are the node labels specified in
    the file and the nodes are corresponding node objects
    alphabet - a list of all possible values for each node.
    Returns: nothing
    """
    for key in tree.keys():
        for a in alphabet:
            tree[key].setValue(a, -1)
            
def parseTree(treefile):
    """
    Reads a file specifying relations between child and parent nodes.
    Expected format for lines in the file is: child parent
    Input: filename - the name of the file containing the data
    Returns: a dictionary in which keys are the node labels specified in the
    file and the nodes are corresponding node objects, followed by the node
    that is the root of the tree.
    """
    infile = open(treefile, 'r')
    nodes = {}
    root = None

    for line in infile:
        tokens = [token.strip() for token in line.split()]
        if len(tokens) == 1: #This node is the root
            nodes[tokens[0]] = Node()
            root = nodes[tokens[0]]
        else:
            if not nodes.has_key(tokens[1]):
                nodes[tokens[1]] = Node()
            if not nodes.has_key(tokens[0]):
                nodes[tokens[0]] = Node()
            nodes[tokens[1]].addChild(nodes[tokens[0]])

    infile.close()
    return nodes, root

def readDistances(fileName):
    """
    Reads a file containing distances between groups and fills in diagonal.
    Expected format for lines in the file is: group1name group2name distance
    Input: filename - the name of the file containing distances
    Returns: a dictionary of dictionaries in which the value of the
    second key is the distance between the first key and the second key.
    """
    infile = open(fileName, "r")
    distances = {}

    for line in infile:
        line = [i.strip() for i in line.split()]
        if not distances.has_key(line[0]):
            distances[line[0]] = {}
        distances[line[0]][line[1]] = float(line[2])

        if not distances.has_key(line[1]):
            distances[line[1]] = {}
        distances[line[1]][line[0]] = float(line[2])

    #Set diagonal to 0
    for key in distances.keys():
        distances[key][key] = 0

    infile.close()
    return distances

def parseSeq(seqfile, tree, index=0):
    """
    Parses the specified sequence file and sets the values for leaf nodes
    in accordance with their values.
    Input: seqfile - a string representing the name of the file containing
    sequence information
    tree - a dictionary in which keys are the labels of nodes and values are
    the corresponding nodes, representing the tree
    index - the index of the base in the sequence that values should be set for
    (default: 0)

    Returns: a boolean that is True if the next index in the sequence is valid
    and false if it's not.
    """
    infile = open(seqfile, 'r')
    for line in infile:
        tokens = [token.strip(": \n") for token in line.split()]
        if index == len(tokens[1]):
            return False
        tree[tokens[0]].setLeaf(tokens[1][index])
    infile.close()
    return True

class Node:
    """
    The node class holds information about nodes in a phylogenetic tree.
    """
    def __init__(self):
        self.children = [] #will hold child nodes once they're created
        self.paths = {"A": [None, None], "C": [None, None], \
                      "G": [None, None], "T": [None, None]}

        #best-case values for tree so far if value of node is each base
        self.A = -1
        self.T = -1
        self.C = -1
        self.G = -1

        self.best = None

    def __str__(self):
        return "A: " + str(self.A) + " " + str(self.paths["A"]) + "\n" + \
               "C: " + str(self.C) + " " + str(self.paths["C"]) + "\n" +\
               "T: " + str(self.T) + " " + str(self.paths["T"]) + "\n" +\
               "G: " + str(self.G) + " " + str(self.paths["G"]) + "\n"

    def saveTrace(self, character = None):
        """
        Saves the inferred character state for this node in self.best and
        propogates the call forward to child nodes to fill out the entire
        tree.
        Input: character - the inferred character state for this node
        (defaults to none to account for root, which just picks lowest
        score)
        Returns: Score of the best choice for this node.
        """
        if character == None:
            bestValue = 10000
            bestChar = ''
            for char in ['A', 'C', 'T', 'G']:
                if self.getValue(char) < bestValue:
                    bestValue = self.getValue(char)
                    bestChar = char
            self.best = bestChar
        else:
            self.best = character

        for i in range(len(self.children)):
            self.children[i].saveTrace(self.paths[self.best][i])

        return self.getValue(self.best)

    def getBest(self):
        return self.best

    def addChild(self, child):
        """
        Appends the given child node to this node's list of children.
        """
        self.children.append(child)

    def getChildren(self):
        return self.children

    def setValue(self, c, value):
        """
        Set the value of the specified character, c, to the specified value
        """
        if c == "A":
            self.A = value
        elif c == "T":
            self.T = value
        elif c == "C":
            self.C = value
        elif c == "G":
            self.G = value
        else:
            print "Invalid character given to setValue:", c

    def getValue(self, c):
        """
        Get the value of the specified character, c.
        """
        if c == "A":
            return self.A
        elif c == "T":
            return self.T
        elif c == "C":
            return self.C
        elif c == "G":
            return self.G
        else:
            print "Invalid character given to getValue:", c

    def setLeaf(self, value):
        """
        Sets best possible values for bases assuming that the current
        node is a leaf with the specified value.
        """
        self.A = 0 if value == "A" else 100000000
        self.T = 0 if value == "T" else 100000000
        self.C = 0 if value == "C" else 100000000
        self.G = 0 if value == "G" else 100000000
        self.isLeaf = True

    def setPath(self, c, iChar, jChar):
        self.paths[c] = [iChar, jChar]

    def getPath(self, c):
        return self.paths[c]

    
if __name__ == "__main__":
    main()
