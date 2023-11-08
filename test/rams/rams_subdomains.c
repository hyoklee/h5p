#include <stdio.h>
#include <math.h>
#include <stdlib.h>
// #include <malloc.h>
#include "rams_subdomains.h"
#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))
void calc_ibeg_iend_values(int npts, int nintervals, float* weights, int* ibeg, int* iend){

    float* dist, *ends;

    ends = (float*) malloc(nintervals*sizeof(float));
    dist = (float*) malloc(nintervals*sizeof(float));

    for(int i=0; i<nintervals; i++){
        dist[i] = ((float)(npts))*weights[i];
    }

    ibeg[0] = 0;
    ends[0] = 0.0+dist[0];
    iend[0] = round(ends[0]);
    for(int i=1; i<nintervals; i++){
        ends[i] = ends[i-1] + dist[i];
        iend[i] = round(ends[i]);
        ibeg[i] = iend[i-1]+1;
    }

    iend[nintervals-1] = npts-1;
    free(ends);
}


void par_decomp_domain(int nxp, int nyp, int nodes, int* ixb, int* ixe, int* iyb, int* iye){
    float anodes, aslabs;
    int nslabs, min_blocks, nbigslabs;
    int* nblocks;
    int islab, inode, iblock;
    int* temp_ixb, *temp_ixe, *temp_iyb, *temp_iye;
    float* weights;

    anodes = nodes;
    aslabs = sqrtf(anodes*((float)nyp/((float)(nxp))));
    nslabs = MIN(nodes, MAX(1, round(aslabs)));
    
    //printf("%f, %f, %d\n", anodes, aslabs, nslabs);
    nblocks = (int*) malloc(nslabs*sizeof(int));
    temp_iyb = (int*) malloc(nslabs*sizeof(int));
    temp_iye = (int*) malloc(nslabs*sizeof(int));


    min_blocks = nodes/nslabs;
    nbigslabs = nodes%nslabs;

    for(int islab = 0; islab<nslabs; islab++){
        if((islab+1)<=nbigslabs){
            nblocks[islab] = min_blocks + 1;
        }
        else{
            nblocks[islab] = min_blocks;
        }
    }

    weights = (float*) malloc(nslabs*sizeof(float));
    for(int islab = 0; islab<nslabs; islab++){
        weights[islab] = ((float)nblocks[islab])/((float)(nodes));
    }

    calc_ibeg_iend_values(nyp, nslabs, weights, temp_iyb, temp_iye);
    for(int i = 0; i<nslabs; i++){
        //printf("nslab %d temp_iyb: %d temp_iye: %d\n", i, temp_iyb[i], temp_iye[i]);
    }
    free(weights);

    inode = -1;

    for(int islab=0; islab<nslabs; islab++){
        temp_ixb = malloc(nblocks[islab]*sizeof(int));
        temp_ixe = malloc(nblocks[islab]*sizeof(int));
        weights = malloc(nblocks[islab]*sizeof(float));

        for(int iblock=0; iblock<nblocks[islab]; iblock++){
            weights[iblock] = 1.0/((float)nblocks[islab]);
        }
        calc_ibeg_iend_values(nxp, nblocks[islab], weights, temp_ixb, temp_ixe);

        for(int iblock=0; iblock<nblocks[islab]; iblock++){
            inode++;
            ixb[inode] = temp_ixb[iblock];
            ixe[inode] = temp_ixe[iblock];
            iyb[inode] = temp_iyb[islab];
            iye[inode] = temp_iye[islab];

        }

        free(temp_ixb);
        free(temp_ixe);
        free(weights);
    }

    if(nodes>1){
        for(int inode=0; inode<nodes; inode++){
            if(iye[inode]-iyb[inode] <1 || ixe[inode]-ixb[inode]<1){
                printf("grid: %d %d subdomain too small on node %d\n", nxp, nyp, inode);
                printf("(ixb, ixe, iyb, iye) = %d %d %d %d\n", ixb[inode], 
                       ixe[inode], iyb[inode], iye[inode]);
            }
        }
    }
    //printf("Before end\n");

    free((void*)nblocks);
    free((void*)temp_iyb);
    free((void*)temp_iye);
    //printf("After free\n");

}



