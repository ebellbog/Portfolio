from node import *
from library import *
from math import log, e

class ProfileHMM:
  def __init__ (self, length):
    """
    Creates and initializes list of nodes with following properties:

    1 begin node, 1 end node

    # of match nodes = length
    # of insert nodes = length+1
    # of delete nodes = length
    
    order as follows: begin, insert0, delete1, match1, insert1...
                                      deleteN, matchN, insertN, end
    """
    print "Sequence length "+str(length)+"."
    
    self.stateorder = []
    
    for i in range(length+1):
      matchNode = Node(i==0, "Begin" if i==0 else "M_"+str(i)) #starts as begin state
      insertNode = Node(False, "I_0" if i==0 else "I_"+str(i))

      matchNode.addEdge(insertNode, 0.1)
      insertNode.addEdge(insertNode, 0.8)

      if (i > 0): #i.e. not at begin state
        l = len(self.stateorder)
        deleteNode = Node(True, "D_" + str(i))
        
        prevMatch = self.stateorder[l-2]
        prevInsert = self.stateorder[l-1]

        prevMatch.addEdge(deleteNode, 0.1)
        prevMatch.addEdge(matchNode, 0.8)

        prevInsert.addEdge(matchNode, 0.2)

        if (i > 1): #i.e. did not come from begin state
          prevDelete = self.stateorder[l-3]
          prevDelete.addEdge(deleteNode, 0.2)
          prevDelete.addEdge(matchNode, 0.8)

        self.stateorder.append(deleteNode)
      self.stateorder.append(matchNode)
      self.stateorder.append(insertNode)

    endNode = Node(True, "End")
    l = len(self.stateorder)
    penultimateInsert = self.stateorder[l-1]
    penultimateMatch = self.stateorder[l-2]
    penultimateDelete = self.stateorder[l-3]

    penultimateInsert.addEdge(endNode, 0.2)
    penultimateMatch.addEdge(endNode, 0.9)
    penultimateDelete.addEdge(endNode, 1.0)
    self.stateorder.append(endNode)
    print "Added "+str(len(self.stateorder))+" nodes."

  def forward(self, sequence, toIndex):
    """
    Runs the forward algorithm on the given sequence from the beginning to the
    specified toIndex (int).
    Returns: The matrix containing all intermediate values in the algorithm.
    """
    fMat = []
    for k in range(len(self.stateorder)):
      fMat.append([])

    for i in range(0, toIndex+1):
      fMat[0].append(int(i == 0))#initialize top row of matrix
                      #(begin = 1 at index 0, 0 everywhere else)
      for k in range(1, len(self.stateorder)):
        prevStates = self.getPrevStates(k, i)
        summyThing = 0
        for state in prevStates:
          prevValue = fMat[state][i-1*((k-2)%3!=0)] #For silent states,
                                                #do not increment index
          itsTransitionWeight = self.stateorder[state].getTransition(self.stateorder[k])
          summyThing += prevValue*itsTransitionWeight
        if i > 0:
          summyThing *= self.stateorder[k].getEmission(sequence[i-1])
        fMat[k].append(summyThing)

    return fMat

  def backward(self, sequence, fromIndex):
    """
    Runs the backward algorithm on the given sequence from the specified
    fromIndex to the end.
    Returns: The matrix containing all intermediate values in the algorithm.
    """
    bMat = {}
    for state in self.stateorder:
      bMat[state] = []

    endState = self.stateorder[-1]
    for i in range(0, len(sequence)-fromIndex+1):
      bMat[endState].append(int(i == 0))#initialize top row of matrix
      for k in range(len(self.stateorder)-2, -1, -1):
        summyThing = 0
        adjusted_i = i-(1 - state.isSilent())
        other_i = i-(1-self.stateorder[k].isSilent())
        for state in self.stateorder[k].getNextStates():
          prevValue = 0
          other_i = i-1+state.isSilent()
          if other_i >= 0: 
             prevValue = bMat[state][other_i]
  
          ourTransitionWeight = self.stateorder[k].getTransition(state)
          emissionProb = 1
  
          if i > 0:
            emissionProb = state.getEmission(sequence[-i])
            
          summyThing += prevValue*ourTransitionWeight*emissionProb
        bMat[self.stateorder[k]].append(summyThing)

    return bMat

  def viterbi(self, sequence, toIndex):
    """
    Runs the Viterbi algorithm on the given sequence from the beggining to the
    specified toIndex.
    Returns: The pointer matrix containing all intermediate pointers in the algorithm.
    """
    vMat = []
    pMat = []
    for k in range(len(self.stateorder)):
      vMat.append([])
      pMat.append([])

    for i in range(0, toIndex+1):
      vMat[0].append(0 if i == 0 else float("-inf"))#initialize top row of matrix
                                        #(begin = 1 at index 0, 0 everywhere else)
      pMat[0].append(None)
      for k in range(1, len(self.stateorder)):
        prevStates = self.getPrevStates(k, i)
        product = float("-inf")
        ptr = None
        for state in prevStates:
          prevValue = vMat[state][i-1*((k-2)%3!=0)] #For silent states,
                                                #do not increment index
          itsTransitionWeight = self.stateorder[state].getTransition(self.stateorder[k])
          if product <= prevValue+log(itsTransitionWeight):
            product = prevValue+log(itsTransitionWeight)
            if product != float("-inf"):
              ptr = (i-1*((k-2)%3!=0), state)
        if i > 0:
          product += log(self.stateorder[k].getEmission(sequence[i-1]))
        vMat[k].append(product)
        pMat[k].append(ptr)
        
    return pMat

  def Baum_Welch(self, sequences, iterations):
    """
    Run the Baum-Welch algorithm to estimate weights for the model.
    Input: sequences - a list of sequences to use in training
    iterations - the number of iterations to run Baum-Welch for
    Returns: Nothing - just updates internal weights
    """
    print "Training Baum-Welch on",len(sequences),"sequence(s)..."

    aaAlphabet = "ARNDCEQGHILKMFPSTWYV"
    
    for iteration in range(iterations):
      print
      print "Iteration:",iteration+1
      
      #Initialize dictionaries
      emissionCounts = {}
      transitionCounts = {}

      #Store matrices for efficiency
      f_ends = [self.forward(seq, len(seq)) for seq in sequences]
      b_ends = [self.backward(seq, 0) for seq in sequences]


      #E step

      #Get emission counts
      for k in range(0,len(self.stateorder)):
        state = self.stateorder[k]
        emissionCounts[k] = {}
        for aa in aaAlphabet:
          emissionCounts[k][aa] = 1.0 #Laplace estimates
        if state.isSilent():
          continue
        for aa in aaAlphabet:
          for s in range(len(sequences)):
            seq = sequences[s]
            f = f_ends[s]
            b = b_ends[s]

            if aa == "A" and k == 1:
              print "P(x_"+str(s)+"):",f[len(self.stateorder)-1][len(seq)],\
                    "=",b[self.stateorder[0]][len(seq)]
            
            for i in range(len(seq)): #column 1 of fMat is character 0 of sequence
              if seq[i] == aa:
                emissionCounts[k if k%3 != 1 else 1][aa] += \
                                 (f[k][i+1]*b[state][len(seq)-i-1])\
                                 /f[len(self.stateorder)-1][len(seq)]


      #Get transition counts
      for k in range(0,len(self.stateorder)):
        state1 = self.stateorder[k]
        transitionCounts[k] = {}
        for state2 in state1.getNextStates():
          transitionCounts[k][state2] = 1.0 #Laplace estimates
          for s in range(len(sequences)):
            seq = sequences[s]
            f = f_ends[s]
            b = b_ends[s]
            for i in range(0,len(seq)+state.isSilent()):
              transitionCounts[k][state2] += (f[k][i]*state1.getTransition(state2)\
                                *b[state2][len(seq)-i-1+state2.isSilent()])\
                                *state2.getEmission(seq[i-state.isSilent()])\
                                /f[len(self.stateorder)-1][len(seq)]
        

      #M-step
      

      #Update emission probabilities
      
      for k in range(len(self.stateorder)):
        if not (self.stateorder[k].isSilent() or (k%3 == 1 and k>1)):
          totalCount = sum(emissionCounts[k].values())
          for aa in aaAlphabet:
            self.stateorder[k].setEmission(aa, emissionCounts[k][aa]/totalCount)

      #Update transition probabilities
      for key in transitionCounts.keys():
        totalCount = sum(transitionCounts[key].values())
        for state in self.stateorder[key].getNextStates():
          self.stateorder[key].setTransition(state, transitionCounts[key][state]/totalCount)


  def performMSA(self, sequences):
    paths = []
    for seq in sequences:
      pointers = self.viterbi(seq, len(seq))
      path = []

      k = len(self.stateorder)-1
      i = len(seq)
      
      currentNode = self.stateorder[k]      
      while currentNode != self.stateorder[0]:
        if k%3 == 1:
          path.append(str(seq[i-1]).lower())
        elif k%3 == 0:
          path.append(str(seq[i-1]))
        elif k < len(self.stateorder)-1:
          path.append("-")
          
          
        new_k = pointers[k][i][1]
        new_i = pointers[k][i][0]
        k = new_k
        i = new_i
        currentNode = self.stateorder[k]

      path.reverse()
      paths.append(path)
      
    return paths
  
  def getPrevStates(self, state, index):
    """
    Helper function for forward and Viterbi algorithms. Given a state (int) and
    index (int indicating number of bases emitted), returns a list of potential
    states that could have preceded the given one.
    """
    if state == 0 or (index == 0 and (state-2)%3 != 0):#begin state or non-delete at first index
      return []
    
    elif state == 1: #first insert state
      if index < 2:
        return [0]
      else:          #first insert with chance of self as predecessor
        return range(2)
      
    elif state == 2: #first delete state
      return [0]

    elif state == 3: #first match state
      return [0, 1]

    elif state == len(self.stateorder)-1: #end state
      return [state-i for i in range (1, 4)]

    elif (state-2)%3 == 0: #any other delete state
      return [state-3, state-2]

    elif (state-2)%3 == 1: #any other match state (deleteN-1, matchN-1, insertN-1, deleteN, matchN)
      return [state-i for i in range(2,5)]

    elif (state-2)%3 == 2: #any other insert state
      return [state, state-1]
