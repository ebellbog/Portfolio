#By Elana Bogdan and Emily Dolson
#CS68 Lab 8

from math import sqrt
from random import shuffle

def euclideanDist(p1, p2):
    """
    Calculates the euclidean distance between the two given points
    """
    if len(p1) != len(p2):
        print "ERROR: Cannot get distance between points of different lengths."
        return -1

    dist = 0
    for i in range(len(p1)):
        dist += (p1[i] - p2[i])**2

    return sqrt(dist)

def generateCVData(numFolds, origData):
    """
    Arranges data into training and test sets for the specified number of
    folds. Returns training and test folds as lists of lists of ints.
    """
    indexList = range(len(origData))
    shuffle(indexList)

    shuffledData = []
    for index in indexList:
        shuffledData.append(index)

    foldSize = len(origData)/numFolds

    testingFolds = []
    trainingFolds = []

    for i in range(numFolds):
        leftEnd = i*foldSize
        rightEnd = (i+1)*foldSize
        testingFolds.append(shuffledData[leftEnd:rightEnd])
        trainingFolds.append(shuffledData[:leftEnd] + shuffledData[rightEnd:])

    return trainingFolds, testingFolds

def getKNearest(allData, trainSet, point, k):
    """
    Find the K nearest neighbors to the given point in the specified training
    set. Returns a list of tupples in which the first value is the distance
    and the second is the index of the point corresponding to that distance.
    """
    distances = []

    for i in range(len(trainSet)):
        distances.append((euclideanDist(point, allData[trainSet[i]][:-1]), i))

    distances = sorted(distances, key=lambda dataPoint: dataPoint[0])

    kClosest = []
    for i in range(k):
        kClosest.append(distances[i])

    return kClosest

def kNearestNeighbors(allData, k, numFolds):
    """
    Runs the K nearest neighbors algorithm on the given data, for the given
    value of k, running crossvalidation using the given number of folds.
    Prints results, returns nothing.
    """
    trainingFolds, testingFolds = generateCVData(numFolds, allData)

    # Keep track of accuracy
    truePos = 0.0
    trueNeg = 0.0
    falsePos = 0.0
    falseNeg = 0.0

    #Repeat for all folds
    for i in range(numFolds):
        train = trainingFolds[i]
        test = testingFolds[i]

        for point in test:
            neighs = getKNearest(allData, train, allData[point][:-1], k)
            totals = {}
            for n in neighs:
                if totals.has_key(allData[n[1]][-1]):
                    totals[allData[n[1]][-1]] += 1/(n[0]+1)
                else:
                    totals[allData[n[1]][-1]] = 1/(n[0]+1)
                    
            counts = sorted(totals.items(), key=lambda value: value[1])
            counts.reverse() #highest count first
            winner = counts[0][0]
            
            if winner == allData[point][-1]:
                if winner == 1:
                    truePos += 1
                else:
                    trueNeg += 1
            else:
                if winner == 1:
                    falsePos += 1
                else:
                    falseNeg += 1

    accuracy = (truePos + trueNeg)/(truePos + trueNeg + falsePos + falseNeg)
    sensitivity = truePos/(truePos + falseNeg)
    specificity = trueNeg/(trueNeg + falsePos)

    print "Results: \n"
    print "Accuracy:", accuracy
    print "Sensitivity:", sensitivity
    print "Specificity:", specificity
                
