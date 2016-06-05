//By Elana Bogdan and Emily Dolson
//(we decided to try using C++ for a change)
//CS 68, Lab 8

#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include "clusterAlgos.cpp"

#define MAX_ITERATIONS 50

using namespace std;
typedef vector<vector<float> > PtList;

void parseInstances(char *instanceFile, vector< vector<float> > *instances);
void parseAnnotations(char *annotationFile, vector<string> *annotations);
void printClusts(vector<int> *clusters, PtList means, PtList *points, vector<string> *annotations);
void saveClusts(vector<int> *clusters, PtList means, PtList *points, vector<string> *annotations);

int main(int argc, const char * argv[]) {
    if (argc < 3) {
        cout << "Error: too few arguments" << endl;
        cout << "Usage: numberOfClusters instanceFile [annotations]" << endl;
        exit(0);
    }
    
    int k = atoi(argv[1]);
    if (k < 1) {
        cout << "Error: invalid number of clusters" << endl;
        exit(0);
    }
    
    PtList instances;
    parseInstances((char *)argv[2], &instances);
    
    vector<string> annotations;
    if (argc > 3) parseAnnotations((char *)argv[3], &annotations);
    
    cout << "Clustering using k-means with k = " << k << endl << endl;
    
    vector<int>* clusters = new vector<int>[k];
    PtList means = k_means(instances, k, MAX_ITERATIONS, clusters);
    

    float SSE = sumOfSquaredError(clusters, means, &instances);
    cout << "SSE: " << SSE << endl;
    cout << "AIC: " << SSE+2*k*instances[0].size() << endl;
    cout << "Silhouette: " << silhouetteValue(clusters, means, &instances) << endl;
    
    saveClusts(clusters, means, &instances, &annotations);
    
    return 0;
}

//Get data points from file
void parseInstances(char *instanceFile, PtList *instances){
    string line;
    vector<string> lines;
    
    int lineCount = 0;
    ifstream instanceStream (instanceFile);
    
    if (instanceStream.is_open()) {
        while (instanceStream.good()) {
            getline(instanceStream, line);
            if (line.length() > 0) {
                lines.push_back(line);
                lineCount++;
            }
        }
        instanceStream.close();
    } else {
        cout << "Failed to open instance file: " << instanceFile << endl;
        exit(0);
    }
        
    for (int i = 0; i < lines.size(); i++) {
        float f;
        vector<float> data;
        stringstream ss(lines[i]);
        while (ss >> f) {
            data.push_back(f);
            if (ss.peek() == ',') ss.ignore();
        }
        instances->push_back(data);
    }
}

//Get annotations from file
void parseAnnotations(char *annotationFile, vector<string>*annotations){
    string line;
    
    int lineCount = 0;
    ifstream annotationStream (annotationFile);
    
    if (annotationStream.is_open()) {
        while (annotationStream.good()) {
            getline(annotationStream, line);
            if (line.length() > 0) {
                annotations->push_back(line);
                lineCount++;
            }
        }
        annotationStream.close();
    } else {
        cout << "Failed to open annotations file: " << annotationFile << endl;
        exit(0);
    }
}

//Helper function to print clusters out in a human-readable manner
void printClusts(vector<int> *clusters, PtList means, PtList *points, vector<string> *annotations) {
    cout << "Clustering using k-means with k = " << means.size() << endl << endl;
    for (int i = 0; i < means.size(); i++) {
        cout << "mu_" << i << ": ( ";
        for (int j = 0; j < means[i].size(); j++) {
            cout << floor(100*means[i][j])/100;
            if (j != means[i].size() -1) cout << ", ";
            else cout << " )" << endl;
        }
        
        if (annotations -> size() > 0) {
            for (int j = 0; j < clusters[i].size(); j++) cout << (*annotations)[clusters[i][j]] << endl;
        }
        else {
            for (int j = 0; j < clusters[i].size(); j++) cout << "x" << clusters[i][j] << endl;
        }
        cout << endl;
    }
}

//Prints clusters to outfile.
void saveClusts(vector<int> *clusters, PtList means, PtList *points, vector<string> *annotations) {
    ofstream saveStream;
    saveStream.open("kmeans.out");
    saveStream << "Clustering using k-means with k = " << means.size() << endl << endl;
    for (int i = 0; i < means.size(); i++) {
        saveStream << "mu_" << i << ": ( ";
        for (int j = 0; j < means[i].size(); j++) {
            saveStream << floor(100*means[i][j])/100;
            if (j != means[i].size() -1) saveStream << ", ";
            else saveStream << " )" << endl;
        }
        
        if (annotations -> size() > 0) {
            for (int j = 0; j < clusters[i].size(); j++) saveStream << (*annotations)[clusters[i][j]] << endl;
        }
        else {
            for (int j = 0; j < clusters[i].size(); j++) saveStream << "x" << clusters[i][j] << endl;
        }
        saveStream << endl;
    }
    saveStream.close();
}
