#ifndef HDF5_OUTPUT_H
#define HDF5_OUTPUT_H
#define RAMS_MPI
#include <stdint.h>
#include "hdf5.h"
#define HDF5_FLOAT_TYPE H5T_NATIVE_FLOAT
#define HDF5_MAX_DIMS 10

struct hdf5_select_type
{
    int ndims;
    int dims[HDF5_MAX_DIMS];
    int block[HDF5_MAX_DIMS];
    int count[HDF5_MAX_DIMS];
    int stride[HDF5_MAX_DIMS];
    int offset[HDF5_MAX_DIMS];
};
void shdf5_build_select(struct hdf5_select_type hs_select, int *ndims, int* select_array);

void shdf5_set_hs_select(int ivar_type, char io_type, int igrid, struct hdf5_select_type *m_select,
                         struct hdf5_select_type *f_select, int* f_chunks);


void fh5f_create_wc (char *locfn,int *iaccess,int *iphdf5,int64_t *fileid,int *hdferr, MPI_Comm comm);

void fh5f_create (char *locfn,int *iaccess,int *iphdf5,int64_t *fileid,int *hdferr);

void fh5f_close (int64_t *fileid,int *hdferr);

void fh5d_write (int64_t *fileid,char *dname,int *h5type,int *iphdf5,int *m_ndims
                ,int *m_select,int *f_ndims,int *f_select,int *f_csize,void *buf
                ,int *hdferr);

hid_t fh5_set_hdf5_dtype (int type_code);


 void fh5_convert_array (int n,int *i_array,hsize_t *h_array,char *dir);
void my_hdf5_create_write(int *m_ndims,hsize_t* chunks, hsize_t *dimsf, hsize_t *dimsm, hsize_t* offset,
                        int64_t *hdf5_fileid, char* data_base_name, 
                        void* data_base);

void my_hdf5_create_only(int *m_ndims,hsize_t* chunks, hsize_t *dimsf,
                        int64_t *hdf5_fileid, char* data_base_name, int64_t* hdf5_dsetid);
void my_hdf5_write_only(int *m_ndims, hsize_t *dimsm, hsize_t* offset,
                        int64_t *hdf5_dsetid,
                        void* data_base);

void my_hdf5_close_dset(int64_t* hdf5_dsetid);
#endif
