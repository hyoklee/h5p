#ifndef NETCDF_OUTPUT_H
#define NETCDF_OUTPUT_H
#include <netcdf.h>
#include <netcdf_par.h>
#include <mpi.h>
void open_nc_file(char* filename, int* ncid);
void close_nc_file(int* ncid);
void add_dimension(int* ncid, char* name, int* num_pts, int*dimid);
void write_float_var(int* ncid, char* varname, int* ndims, int* dimids, 
                    size_t * offset, size_t * count, float* var);
//void add_nc_att_text(int* ncid, )
void print_err(int err);

#endif
