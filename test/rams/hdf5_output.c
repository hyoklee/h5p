#include <string.h>
#include <stdint.h>
#include <stdio.h>
// #include <malloc.h>
#include <stdlib.h>

#include "hdf5.h"
#include "hdf5_output.h"
// Size of temporary hsize_t arrays
#define HDF5_MAX_DIMS 10

void shdf5_build_select(struct hdf5_select_type hs_select, int *ndims, int* select_array){
    int isa;
    int temp_array[HDF5_MAX_DIMS];

    select_array = malloc(5*hs_select.ndims*sizeof(int));
    isa = 0;
    *ndims = hs_select.ndims;

    //0: dims
    for(int i = 0; i<*ndims; i++){
        select_array[isa] = hs_select.dims[i];
        isa++;
    }

    //1: block
    for(int i =0; i<*ndims; i++){
        select_array[isa] = hs_select.block[i];
        isa++;
    }

    //2: count
    for(int i = 0; i<*ndims; i++){
        select_array[isa] = hs_select.count[i];
        isa++;
    }

    //3: offset
    for(int i = 0; i<*ndims; i++){
        select_array[isa] = hs_select.offset[i];
        isa++;
    }
    //4: stride
    for(int i = 0; i<*ndims; i++){
        select_array[isa] = hs_select.stride[i];
        isa++;
    }

}

void shdf5_set_hs_select(int ivar_type, char io_type, int igrid, struct hdf5_select_type *m_select,
                         struct hdf5_select_type *f_select, int* f_chunks){
    int m_xblk, m_yblk, m_xoff;
}





   void fh5f_create (char *locfn,int *iaccess,int *iphdf5,int64_t *fileid,int *hdferr){
   fh5f_create_wc (locfn, iaccess, iphdf5, fileid, hdferr, MPI_COMM_WORLD);
 }


 void fh5f_create_wc (char *locfn,int *iaccess,int *iphdf5,int64_t *fileid,int *hdferr, MPI_Comm comm)
  {
unsigned flags;
  hid_t access_id,create_id;
  hid_t fileid_h5;
  fileid_h5 = (hid_t)(*fileid);
  if (*iphdf5 == 1)
    {
#if defined (RAMS_MPI)
    // open a parallel file collectively
    access_id = H5Pcreate (H5P_FILE_ACCESS);
    H5Pset_fapl_mpio (access_id,comm,MPI_INFO_NULL);

H5AC_cache_config_t cache_config = {
  /* int         version                = */ H5AC__CURR_CACHE_CONFIG_VERSION,
  /* hbool_t     rpt_fcn_enabled        = */ 0,
  /* hbool_t     open_trace_file        = */ 0,
  /* hbool_t     close_trace_file       = */ 0,
  /* char        trace_file_name[]      = */ "",
  /* hbool_t     evictions_enabled      = */ 0,
  /* hbool_t     set_initial_size       = */ 1,
  /* size_t      initial_size           = */ ( 2 * 1024 * 1024),
  /* double      min_clean_fraction     = */ 0.3,
  /* size_t      max_size               = */ (32 * 1024 * 1024),
  /* size_t      min_size               = */ ( 1 * 1024 * 1024),
  /* long int    epoch_length           = */ 50000,
  /* enum H5C_cache_incr_mode incr_mode = */ H5C_incr__off,
  /* double      lower_hr_threshold     = */ 0.9,
  /* double      increment              = */ 2.0,
  /* hbool_t     apply_max_increment    = */ 1,
  /* size_t      max_increment          = */ (4 * 1024 * 1024),
  /* enum H5C_cache_flash_incr_mode       */
  /*                    flash_incr_mode = */ H5C_flash_incr__off,
  /* double      flash_multiple         = */ 1.0,
  /* double      flash_threshold        = */ 0.25,
  /* enum H5C_cache_decr_mode decr_mode = */ H5C_decr__off,
  /* double      upper_hr_threshold     = */ 0.999,
  /* double      decrement              = */ 0.9,
  /* hbool_t     apply_max_decrement    = */ 1,
  /* size_t      max_decrement          = */ (1 * 1024 * 1024),
  /* int         epochs_before_eviction = */ 3,
  /* hbool_t     apply_empty_reserve    = */ 1,
  /* double      empty_reserve          = */ 0.1,
  /* int         dirty_bytes_threshold  = */ (256 * 1024)
};
//H5Pset_mdc_config(access_id, &cache_config);

#else
    access_id = H5P_DEFAULT;
#endif
    }
  else
    {
    access_id = H5P_DEFAULT;
    }
  create_id = H5P_DEFAULT;
  
  if(*iaccess == 1) flags = H5F_ACC_TRUNC;
  if(*iaccess == 2) flags = H5F_ACC_EXCL ;
  
  fileid_h5 = H5Fcreate (locfn,H5F_ACC_TRUNC,create_id,access_id);
  *fileid = (int64_t)fileid_h5;
  //printf("fh5f_create: fileid: %d\n",*fileid);
  if (*fileid < 0) { *hdferr = *fileid; return;}
  
  // Parallel mode created a property which needs to be closed
  if (*iphdf5 == 1)
    {
#if defined (RAMS_MPI)
    *hdferr = H5Pclose (access_id);
#else
    *hdferr = 0;
#endif
    }
  else
    {
    // no errors if we made it here
    *hdferr = 0;
    }
  
  return;
  }




 void fh5f_close (int64_t *fileid,int *hdferr)
  {
  herr_t herr;
  hid_t fileid_h5;
  fileid_h5 = (hid_t)(*fileid);
  
  // Don't use H5close() to close everything since there might be more than one
  // file open (due to REVU for example).
  
  herr = H5Fclose (fileid_h5);
  
  *hdferr = herr;
  
  return;
  }

 void fh5d_write (int64_t *fileid,char *dname,int *h5type,int *iphdf5,int *m_ndims
                ,int *m_select,int *f_ndims,int *f_select,int *f_csize,void *buf
                ,int *hdferr)
  {
  hid_t dsetid, fspcid, mspcid, propid;
  int i;
  herr_t herr;
  hid_t memtype;
  hid_t fileid_h5;
  fileid_h5 = (hid_t)(*fileid);


  hsize_t m_dims[HDF5_MAX_DIMS];   // memory selection description
  hsize_t m_block[HDF5_MAX_DIMS];
  hsize_t m_count[HDF5_MAX_DIMS];
  hsize_t m_offset[HDF5_MAX_DIMS];
  hsize_t m_stride[HDF5_MAX_DIMS];

  hsize_t f_dims[HDF5_MAX_DIMS];   // file selection description
  hsize_t f_block[HDF5_MAX_DIMS];
  hsize_t f_count[HDF5_MAX_DIMS];
  hsize_t f_offset[HDF5_MAX_DIMS];
  hsize_t f_stride[HDF5_MAX_DIMS];

  hsize_t chunk_size[HDF5_MAX_DIMS]; // for the file data space
  
  //******************* CONVERT INPUT ARGUMENTS *************************

  // Extract and convert the input int arrays into hsize_t arrays
  // Note: &(array[i]) gives the address of the ith element of array[] making
  // it appear to fh5_convert_array() that this is the zeroth element of
  // its argument array.
  fh5_convert_array (*m_ndims, &(m_select[0]),            m_dims,   "i2h");
  fh5_convert_array (*m_ndims, &(m_select[*m_ndims]),     m_block,  "i2h");
  fh5_convert_array (*m_ndims, &(m_select[(*m_ndims)*2]), m_count,  "i2h");
  fh5_convert_array (*m_ndims, &(m_select[(*m_ndims)*3]), m_offset, "i2h");
  fh5_convert_array (*m_ndims, &(m_select[(*m_ndims)*4]), m_stride, "i2h");

  fh5_convert_array (*f_ndims, &(f_select[0]),            f_dims,   "i2h");
  fh5_convert_array (*f_ndims, &(f_select[*f_ndims]),     f_block,  "i2h");
  fh5_convert_array (*f_ndims, &(f_select[(*f_ndims)*2]), f_count,  "i2h");
  fh5_convert_array (*f_ndims, &(f_select[(*f_ndims)*3]), f_offset, "i2h");
  fh5_convert_array (*f_ndims, &(f_select[(*f_ndims)*4]), f_stride, "i2h");

  fh5_convert_array (*f_ndims,f_csize,chunk_size,"i2h");

  // Set HDF5 data type
  memtype = fh5_set_hdf5_dtype (*h5type);

  //******************* CREATE THE FILE DATASET ***********************

  // This must be done before the selection section

  // Create description of data space for the file dataset
  fspcid = H5Screate_simple (*f_ndims,f_dims,f_dims);
  if (fspcid < 0) { 
    *hdferr = fspcid; 
    printf("Error in H5Screate_simple, fspcid: %d", fspcid);
    return;}
  
  // Create properties for chunking, gzip compression. Can't do
  // compression for PHDF5 file.
  propid = H5Pcreate (H5P_DATASET_CREATE);
  //printf("fh5d_write - propid: %d\n",propid);
  if (propid < 0) { 
    *hdferr = propid; 
    printf("Error in H5Pcreate, propid: %d", propid);
    return;}
  
  herr = H5Pset_chunk (propid,*f_ndims,chunk_size);
  //if (*iphdf5 != 1)
    //{
    herr = H5Pset_shuffle (propid);
    herr = H5Pset_deflate (propid,6);
    //}
  if (herr < 0) { 
    *hdferr = herr; 
    printf("Error in chunking, herr: %d", herr);
    return;}
  
  // Create the dataset
  dsetid = H5Dcreate (fileid_h5,dname,memtype,fspcid,H5P_DEFAULT,propid,H5P_DEFAULT);
  if (dsetid < 0) { 
    *hdferr = dsetid; 
    printf("Error in H5Dcreate, dsetid: %lld \n",dsetid);
    printf("Fileid_h5: %lld, dname: %s \n",fileid_h5,dname);
    printf("memtype: %d, fspcid: %d, propid: %d \n",memtype,fspcid, propid);
    for(int i=0; i<*f_ndims; i++){
      printf("Chunk size [%d], %lld \n",i,chunk_size[i]);
    }
    return;}

    

  // Close the items used for this section, but keep dsetid open for
  // subsequent use
  H5Pclose (propid);
  H5Sclose (fspcid);
  
  //******************* SET UP SELECTION ******************************
  
  // Create descriptions of the file and memory data spaces

  fspcid = H5Dget_space (dsetid);
  if (fspcid < 0) { *hdferr = fspcid; return;}
  
  mspcid = H5Screate_simple (*m_ndims,m_dims,NULL); // memory data space
  if (mspcid < 0) { *hdferr = mspcid; return;}
  
  // Make the hyperslab selections

  // file
  herr = H5Sselect_hyperslab (fspcid,H5S_SELECT_SET,f_offset,f_stride
                             ,f_count,f_block);
  if (herr < 0) { *hdferr = herr; return;}

  // memory
  herr = H5Sselect_hyperslab (mspcid,H5S_SELECT_SET,m_offset,m_stride
                             ,m_count,m_block); 
  if (herr < 0) { *hdferr = herr; return;}
  
  //******************* DO THE WRITE ******************************

  if (*iphdf5 == 1)
    {
#if defined (RAMS_MPI)
    propid = H5Pcreate (H5P_DATASET_XFER);
    H5Pset_dxpl_mpio (propid,H5FD_MPIO_COLLECTIVE);
#else
    propid = H5P_DEFAULT;
#endif
    }
  else
    {
    propid = H5P_DEFAULT;
    }
  
  herr = H5Dwrite (dsetid,memtype,mspcid,fspcid,propid,buf);
  if (herr < 0) { *hdferr = herr; return;}
  
  // Close
  if (*iphdf5 == 1)
    {
#if defined (RAMS_MPI)
    H5Pclose (propid);
#endif
    }
  herr = H5Sclose (mspcid);
  herr = H5Sclose (fspcid);
  herr = H5Dclose (dsetid);
  
  *hdferr = herr;
  
  return;
  }

//*************************** Utilities **************************************

//****************************************************************************
// This routine will translate the type codes from FORTAN to the built in
// HDF5 type codes.

hid_t fh5_set_hdf5_dtype (int type_code)
  {
  hid_t dtype;

  if (type_code == 1) dtype = H5T_NATIVE_INT32;
  if (type_code == 2) dtype = HDF5_FLOAT_TYPE;
  if (type_code == 3) dtype = H5T_STRING;
  if (type_code == 4) dtype = H5T_NATIVE_DOUBLE;
  if (type_code == 5) dtype = H5T_NATIVE_HBOOL;

  return dtype;
  }

//****************************************************************************
// This routine will copy the contents between an integer array and an hsize_t
// array. It is likely to encounter a system where hsize_t and int are not the same
// length. As an example, this would necessitate the need to convert back and
// forth when the integer array is used as an argument from FORTRAN for example.
//
// dir == 'i2h' --> convert int to hsize_t
// dir == 'h2i' --> convert hsize_t to int

 void fh5_convert_array (int n,int *i_array,hsize_t *h_array,char *dir)
  {
  int i;

  if (strcmp(dir, "i2h") == 0)
    {
    // copy int array into the hsize_t array
    for (i = 0; i < n; i++)
      {
      h_array[i] = i_array[i];
      }
    }
  else if (strcmp(dir, "h2i") == 0)
    {
    // copy hsize_t array into the int array
    for (i = 0; i < n; i++)
      {
      i_array[i] = h_array[i];
      }
    }
  else
    {
    printf ("ERROR: fh5_convert_array:");
    printf ("Do not recognize dir argument value: %d\n", dir);
    }

  return;
  }


void my_hdf5_create_write(int *m_ndims,hsize_t* chunks, hsize_t *dimsf, hsize_t *dimsm, hsize_t* offset,
                        int64_t *hdf5_fileid, char* data_base_name, 
                        void* data_base){
       hid_t filespace;
   hid_t memspace;
    hid_t dset_id;
    hid_t plist_id;
    hid_t fileid_h5 = (hid_t)*hdf5_fileid;

    herr_t status;
   filespace = H5Screate_simple(*m_ndims, dimsf, NULL);
   plist_id = H5Pcreate(H5P_DATASET_CREATE);
   H5Pset_chunk(plist_id, *m_ndims, chunks);
   //unsigned szip_options_mask = H5_SZIP_EC_OPTION_MASK;
   //unsigned szip_pixels_per_block = 10;
    H5Pset_shuffle(plist_id);
    H5Pset_deflate(plist_id, 6);
    //H5Pset_szip(plist_id, szip_options_mask, szip_pixels_per_block);
   
    //printf("Before H5Dcreate\n");
    fflush(stdout);
    dset_id = H5Dcreate(fileid_h5, data_base_name, H5T_NATIVE_FLOAT, 
                        filespace, H5P_DEFAULT, plist_id, H5P_DEFAULT);
    //printf("After H5Dcreate\n");
    fflush(stdout);
    H5Sclose(filespace);
    H5Pclose(plist_id);

    
    memspace = H5Screate_simple(*m_ndims, dimsm, NULL);

    filespace = H5Dget_space(dset_id);
    H5Sselect_hyperslab(filespace, H5S_SELECT_SET, offset, NULL, dimsm, NULL);

    plist_id = H5Pcreate(H5P_DATASET_XFER);
    H5Pset_dxpl_mpio(plist_id, H5FD_MPIO_COLLECTIVE);
    //printf("Before H5Dwrite\n");
    fflush(stdout);
    status = H5Dwrite(dset_id, H5T_NATIVE_FLOAT, memspace, filespace, 
                      plist_id, data_base);
    //printf("After H5Dwrite\n");
    fflush(stdout);
    
    H5Dclose(dset_id);
    //printf("After H5Dclose\n");
    fflush(stdout);
    H5Sclose(filespace);
    H5Sclose(memspace);
    H5Pclose(plist_id);

}

void my_hdf5_create_only(int *m_ndims,hsize_t* chunks, hsize_t *dimsf, 
                        int64_t *hdf5_fileid, char* data_base_name, int64_t *hdf5_dsetid){
   hid_t filespace;
   hid_t memspace;
    hid_t dset_id;
    hid_t plist_id;
    hid_t fileid_h5 = (hid_t)*hdf5_fileid;

    herr_t status;
   filespace = H5Screate_simple(*m_ndims, dimsf, NULL);
   plist_id = H5Pcreate(H5P_DATASET_CREATE);
   H5Pset_chunk(plist_id, *m_ndims, chunks);
   unsigned szip_options_mask = H5_SZIP_EC_OPTION_MASK;
   unsigned szip_pixels_per_block = 10;
    H5Pset_shuffle(plist_id);
    //H5Pset_deflate(plist_id, 6);
    //H5Pset_szip(plist_id, szip_options_mask, szip_pixels_per_block);


    dset_id = H5Dcreate(fileid_h5, data_base_name, H5T_NATIVE_FLOAT,
                        filespace, H5P_DEFAULT, plist_id, H5P_DEFAULT);
    *hdf5_dsetid = (int64_t)dset_id;
    H5Sclose(filespace);
    H5Pclose(plist_id);
}
void my_hdf5_write_only(int *m_ndims, hsize_t *dimsm, hsize_t* offset,
                        int64_t *hdf5_dsetid,
                        void* data_base){

       hid_t filespace;
   hid_t memspace;
    hid_t dset_id = (hid_t)*hdf5_dsetid;
    hid_t plist_id;

    herr_t status;
    memspace = H5Screate_simple(*m_ndims, dimsm, NULL);

    filespace = H5Dget_space(dset_id);
    H5Sselect_hyperslab(filespace, H5S_SELECT_SET, offset, NULL, dimsm, NULL);

    plist_id = H5Pcreate(H5P_DATASET_XFER);
    H5Pset_dxpl_mpio(plist_id, H5FD_MPIO_COLLECTIVE);
    status = H5Dwrite(dset_id, H5T_NATIVE_FLOAT, memspace, filespace,
                      plist_id, data_base);


    H5Sclose(filespace);
    H5Sclose(memspace);
    H5Pclose(plist_id);

}

void my_hdf5_close_dset(int64_t* hdf5_dsetid){
H5Dclose((hid_t)*hdf5_dsetid);

}
