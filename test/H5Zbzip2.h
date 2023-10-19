#include "bzlib.h"

/* use an integer greater than 256 to be id of the registered filter. */
#define H5Z_FILTER_BZIP2 305

const H5Z_class2_t H5Z_BZIP2[1]; 


/* declare a filter function */
size_t H5Z_filter_bzip2(unsigned flags,size_t cd_nelmts,const unsigned cd_values[],
                    size_t nbytes,size_t *buf_size,void**buf);

void my_hdf5_create_write_bz(int *m_ndims,hsize_t* chunks, hsize_t *dimsf, hsize_t *dimsm, hsize_t* offset,
                        int64_t *hdf5_fileid, char* data_base_name,
                        void* data_base);
