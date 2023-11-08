#include "netcdf_output.h"
#include <stdio.h>
#define ERR {if(err!=NC_NOERR)printf("Error at line=%d: %s\n", __LINE__, nc_strerror(err));}

void open_nc_file(char* filename, int* ncid){
    //opens a NetCDF file in parallel.
    int err;
    err = nc_create_par(filename, NC_NETCDF4, MPI_COMM_WORLD, MPI_INFO_NULL, ncid);ERR
    //print_err(err);

}
void add_dimension(int* ncid, char* name, int* num_pts, int*dimid){
    int err;
    err = nc_def_dim(*ncid, name, *num_pts, dimid);ERR
}
void write_float_var(int* ncid, char* varname, int* ndims, int* dimids, 
                    size_t * offset, size_t * count, float* var){
    

    int varid;
    int err;
    int shuffle = NC_SHUFFLE;
    int deflate = 1;
    int deflate_level = 1;
    //size_t chunking[] = {20,20,100};

    err = nc_def_var(*ncid, varname,NC_FLOAT, *ndims, dimids, &varid);ERR
    //err = nc_def_var_chunking(*ncid, varid, NC_CHUNKED, chunking);ERR
    err = nc_def_var_deflate(*ncid, varid, shuffle, deflate, deflate_level);ERR
    err = nc_put_vara_float(*ncid, varid, offset, count, var);ERR
}


void close_nc_file(int* ncid){
    nc_close(*ncid);
}

void print_err(int err){
    switch(err){
        case NC_ENOPAR:
            printf("Library not built with parallel IO\n");
            break;
        case NC_EPERM:
            printf("No write permission\n");
            break;
        case NC_ENOTBUILT:
            printf("Library not built (what?)\n");
            break;
        case NC_EINVAL:
            printf("Invalid parameters \n");
            break;
        case NC_ENOTNC:
            printf("Not a NetCDF file.\n");
            break;
        case NC_EHDFERR:
            printf("HDF5 error.\n");
            break;
        case NC_EDIMMETA:
            printf("Error in netcdf5 dimension metadata.\n");
            break;

    }
    fflush(stdout);
}
