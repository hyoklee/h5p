#ifndef RAMS_SUBDOMAINS_H
#define RAMS_SUBDOMAINS_H

void calc_ibeg_iend_values(int npts, int nintervals, float* weights, int* ibeg, int* iend);

void par_decomp_domain(int nxp, int nyp, int nodes, int* ixb, int* ixe, int* iyb, int* iye);

#endif