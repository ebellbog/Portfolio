//By Elana Bogdan and Emily Dolson
//CS 68, lab 8

#include <vector>
#include <math.h>
#include <time.h>
#include <cstdlib>
#include <limits>
#include <iostream>

using namespace std;
typedef vector<vector<float> > PtList;

//calculates Manhattan distance between two given vectors
float manhattanDistance (vector<float> a, vector<float> b) {
    float d = 0;
    for (int i = 0; i < a.size(); i++) {
        d += fabs(a[i]-b[i]);
    }
    return d;
}

//Finds centroid of specified cluster
vector<float> getCentroid (PtList *points, vector<int> cluster) {
    vector<float> centroid;
    int dimensions = (*points)[0].size();
    for (int i = 0; i < dimensions; i++) centroid.push_back(0.);
    
    for (int i = 0; i < cluster.size(); i++) {
        for (int j = 0; j < dimensions; j++) {
            centroid[j] += (*points)[cluster[i]][j]/cluster.size();
        }
    }
    return centroid;
}

//Runs k-means
PtList k_means (PtList points, int k, int iterations, vector<int>* clusters) {
    PtList means;
    srand(time(NULL));
    
    for (int i = 0; i < k; i++) means.push_back(points[rand()%points.size()]);
    
    for (int i = 0; i < iterations; i++) {
        for (int j = 0; j < points.size(); j++) {
            float dist, min_dist = numeric_limits<float>::max();
            int closest_cluster = -1;
            for (int l = 0; l < k; l++) {
                dist = manhattanDistance(points[j], means[l]);
                if (dist < min_dist) {
                    min_dist = dist;
                    closest_cluster = l;
                }
            }

            clusters[closest_cluster].push_back(j);
        }
        
        bool stable = true;
        vector<float> old_mean;
        for (int j = 0; j < k; j++) {
            old_mean = means[j];
            if (clusters[j].size() == 0) {
                means[j] = points[rand()%points.size()];
            }
            else means[j] = getCentroid(&points, clusters[j]);
            
            stable = stable && (manhattanDistance(old_mean, means[j]) < 0.01); //Threshold for convergence
        }
        
        
        if (stable) {
            cout << "Converged after " << i << " iterations." << endl << endl;
            break;
        }
        if (i != iterations-1) {
            for (int j = 0; j < k; j++) {
                clusters[j].clear(); //Don't clear if ready to return
            }
        }

    }
    return means;
}

//Calculate SSE for given clusters with given means
float sumOfSquaredError(vector<int> *clusters, PtList means, PtList *points) {
    float totalError = 0;
    for (int i = 0; i < means.size(); i++) {
        for (int j = 0; j < clusters[i].size(); j++) {
            totalError += pow(manhattanDistance(means[i], (*points)[clusters[i][j]]), 2.);
        }
    }
    return floor(100*totalError)/100;
}

//Calculate Solhouette value for given clusters with given means
float silhouetteValue(vector<int> *clusters, PtList means, PtList *points) {
    float *s = new float[points->size()];
    for (int i = 0; i < points->size(); i++) s[i] = 0; //Initialize array to hold all s values
    
    float S = 0;
    for (int k = 0; k < means.size(); k++) {
        float clusterSum = 0;
        for (int i = 0; i < clusters[k].size(); i++) {
            float a = 0, b = numeric_limits<float>::max();
            
            for (int j = 0; j < means.size(); j++) { //Compare against *other* means
                if (j != k) b = min(b, manhattanDistance((*points)[clusters[k][i]], means[j]));
            }
            
            if (clusters[k].size() == 1) a = 0;
            else {
                for (int j = 0; j < clusters[k].size(); j++) { //Compare against *other* points within cluster
                    if (j != i) a += manhattanDistance((*points)[clusters[k][i]], (*points)[clusters[k][j]]);
                }
                a /= clusters[k].size()-1;
            }
            s[clusters[k][i]] = (b-a)/max(a,b);
            clusterSum += s[clusters[k][i]];
        }
        S += clusterSum/clusters[k].size();
    }
    return floor(100*S/means.size())/100;
}

