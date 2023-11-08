#include "rams_subdomains.h"
#include <stdio.h>
// #include <malloc.h>
#include <stdlib.h>
#include <mpi.h>
#include <math.h>
#define MAIN_NUM 0
#define DECOMP_TAG 1337

#define USE_HDF5
//#define USE_NC4
//#define USE_HDF5_BZIP
//#define USE_HDF5_SUBSET

#ifdef USE_HDF5
#include <hdf5.h>
#include "hdf5_output.h"
#endif

#ifdef USE_HDF5_BZIP
#include "hdf5_output.h"
#include "H5Zbzip2.h"
#endif

#ifdef USE_NC4
#include "netcdf_output.h"
#endif


#ifdef USE_HDF5_SUBSET
#include <hdf5.h>
#include "hdf5_output.h"

//#include "hdf5_subset.h"
#endif



int td_1d(int x, int y, int z, int nx, int ny, int nz){
	/*
	Calculates the 1D array index given 3D array coordinates.
	*/
	return x*ny*nz+y*nz+z;

}


int t2d_1d(int x, int y, int nx, int ny){
	/*
	Calculates the 1D array index given 2D array coordinates.
	*/
	return x*ny+y;

}


void fill(int* arr, int len, int val){
    for(int i =0; i<len; i++){
        arr[i] = val;
    }
    return;
}


//dies at 98, then 82
int main(int argc, char** argv){
    printf("Test HDF5 code.\n");
    MPI_Init(&argc,&argv);
    printf("After MPI_Init\n");
    int nxp, nyp, nzp;

    nxp = 200;
    nyp = 200;
    nzp = 40;

    //char outloc[]="/nobackupp2/swfreema/hdf5_test/test_hdf5_out.h5";
    // char outloc[]="/nobackupnfs2/swfreema/test_hdf5/small_files/test_hdf5_out.h5";
    
    char outloc[] = "/Users/hyoklee/data/test_hdf5_out.h5";

    int world_size;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);
    int world_rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);
    printf("My world rank: %d\n", world_rank);

    int ncols;
    int nodes = world_size;
    int ixb, ixe, iyb, iye, izb, ize;
    int* ixb_all, *ixe_all, *iyb_all, *iye_all;

    int file_chunks[3];
    fill(file_chunks, 3, -1);

    if(world_rank == MAIN_NUM){
        ixb_all = (int*) malloc(nodes*sizeof(int)); 
        ixe_all = (int*) malloc(nodes*sizeof(int));
        iyb_all = (int*) malloc(nodes*sizeof(int));
        iye_all = (int*) malloc(nodes*sizeof(int));
        


        par_decomp_domain(nxp, nyp, nodes, ixb_all, ixe_all, iyb_all, iye_all);
        printf("Number of nodes: %d\n", nodes);
        
        for(int nnode =0; nnode<nodes; nnode++){
            int ixb_n, ixe_n, iyb_n, iye_n, izb_n, ize_n;
            ixb_n = ixb_all[nnode];
            ixe_n = ixe_all[nnode];
            iyb_n = iyb_all[nnode];
            iye_n = iye_all[nnode];
            izb_n = 0;
            ize_n = nzp-1;
            //loop through all nodes.
            //first, figure out if this node is bigger than the current chunk size.
            
            if((ixe_n-ixb_n+1)>file_chunks[0]){
                file_chunks[0] = (ixe_n-ixb_n+1);
            }
            if((iye_n-iyb_n+1)>file_chunks[1]){
                file_chunks[1] = (iye_n-iyb_n+1);
            }
            if((ize_n-izb_n+1)>file_chunks[2]){
                file_chunks[2] = (ize_n-izb_n+1);
            }
            /*
            printf("file_chunks[0]: %d, file_chunks[1]: %d, file_chunks[2]: %d\n", 
                    file_chunks[0], file_chunks[1], file_chunks[2]);
            */
            

            //except the main one, let's skip that one. 
            if(nnode == MAIN_NUM){
                continue;
            }
            int bounds_to_send[4];
            bounds_to_send[0] = ixb_n;
            bounds_to_send[1] = ixe_n;
            bounds_to_send[2] = iyb_n;
            bounds_to_send[3] = iye_n;
            MPI_Send(bounds_to_send, 4, MPI_INT, nnode, DECOMP_TAG, MPI_COMM_WORLD);
            
        }
        ixb = ixb_all[MAIN_NUM];
        ixe = ixe_all[MAIN_NUM]; 
        iyb = iyb_all[MAIN_NUM];
        iye = iye_all[MAIN_NUM];
        izb =0;
        ize = nzp-1;




    }
    else{
        //we just need to be ready to receive the info. 
        int bounds_to_rec[4];
        MPI_Recv(bounds_to_rec, 4, MPI_INT, MAIN_NUM, DECOMP_TAG, 
        MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        //printf("Received bounds: %d %d %d %d\n", bounds_to_rec[0], bounds_to_rec[1],
        //        bounds_to_rec[2], bounds_to_rec[3]);
        ixb = bounds_to_rec[0];
        ixe = bounds_to_rec[1];
        iyb = bounds_to_rec[2];
        iye = bounds_to_rec[3];
        izb = 0;
        ize = nzp-1;

        

    }
    printf("Finished MPI decomposition info.\n");
    MPI_Barrier(MPI_COMM_WORLD);
    MPI_Bcast(file_chunks, 3, MPI_INT, MAIN_NUM, MPI_COMM_WORLD);

    //ok we need to figure out exactly how big our local array needs to be. 
    int l_nx, l_ny, l_nz;

    l_nx = ixe-ixb+1;
    l_ny = iye-iyb+1;
    l_nz = ize-izb+1;

    printf("proc_num: %d, l_nx: %d, l_ny: %d, l_nz: %d\n", 
            world_rank, l_nx, l_ny, l_nz);

    
    //let's allocate the local arrays. 
    float* data_base;
    float* data_2x;
    float* data_sqrt;

    data_base = malloc(l_nx*l_ny*l_nz*sizeof(float));
    data_2x = malloc(l_nx*l_ny*l_nz*sizeof(float));
    data_sqrt = malloc(l_nx*l_ny*l_nz*sizeof(float));
    //now we need to create our part of the main arrays. 
    for(int i =0; i<l_nx; i++){
        int ival = ixb+i;
        for(int j =0; j<l_ny; j++){
            int jval = iyb+j;
            for(int k = 0; k<l_nz; k++){
                int kval = izb+k;
                data_base[td_1d(i,j,k, l_nx, l_ny, l_nz)] = ival+jval+kval;
                data_2x[td_1d(i,j,k, l_nx, l_ny, l_nz)] = (ival+jval+kval)*2;
                data_sqrt[td_1d(i,j,k, l_nx, l_ny, l_nz)] = sqrtf(ival+jval+kval);


            }
        }
    }
    //printf("Data_base[0,0,0]: %f\n", data_base[0]);

    char data_base_name[] = "data_base";
    char data_2x_name[] = "data_2x";
    char data_sqrt_name[] = "data_sqrt";


#ifdef USE_HDF5
    int64_t hdf5_fileid;
    int hdferr;
    int iphdf5=1;
    int iaccess = 2;
    int data_type_num = 2;
    int m_ndims = 3;
    hsize_t dimsf[] = {nxp, nyp, nzp};
    hsize_t dimsm[] = {l_nx, l_ny, l_nz};
    hsize_t offset[] = {ixb, iyb, izb};
    hsize_t chunks_h5[] = {file_chunks[0], file_chunks[1], file_chunks[2]};

    //open HDF5 file
    fh5f_create (outloc,&iaccess,&iphdf5,&hdf5_fileid,&hdferr);

    /*
    fh5d_write (&hdf5_fileid,data_base_name,&data_type_num,&iphdf5,
                &m_ndims, int *m_select,
                int *f_ndims,int *f_select,int *f_csize,void *buf
                ,int *hdferr);
    */
   
    //my_hdf5_create_write(&m_ndims, chunks_h5, dimsf, dimsm, offset, &hdf5_fileid, 
    //                        data_base_name, data_base);
    
    //my_hdf5_create_write(&m_ndims, chunks_h5, dimsf, dimsm, offset, &hdf5_fileid, 
    //                        data_2x_name, data_2x);
    
    //my_hdf5_create_write(&m_ndims, chunks_h5, dimsf, dimsm, offset, &hdf5_fileid, 
    //                        data_sqrt_name, data_sqrt);
    

    int64_t dsetids[200];
    for(int varnum=0; varnum<200; varnum++){

        char strbuf[13];
        snprintf(strbuf, 13, "data_sqrt%d", varnum);
        if(world_rank==MAIN_NUM){
            printf("Writing variable: %s\n", strbuf);
        }
        MPI_Barrier(MPI_COMM_WORLD);
	//my_hdf5_create_only(&m_ndims, chunks_h5, dimsf,&hdf5_fileid, strbuf, &dsetids[varnum]);
        if(world_rank==MAIN_NUM){
            printf("Before my_hdf5_create_write\n");
        }
	fflush(stdout);
        my_hdf5_create_write(&m_ndims, chunks_h5, dimsf, dimsm, offset, &hdf5_fileid,
                            strbuf, data_sqrt);
        if(world_rank==MAIN_NUM){
            printf("After my_hdf5_create_write\n");
        }
        fflush(stdout);
    }


       H5AC_cache_config_t cache_config = {
  /* int         version                = */ H5AC__CURR_CACHE_CONFIG_VERSION,
  /* hbool_t     rpt_fcn_enabled        = */ 0,
  /* hbool_t     open_trace_file        = */ 0,
  /* hbool_t     close_trace_file       = */ 0,
  /* char        trace_file_name[]      = */ "",
  /* hbool_t     evictions_enabled      = */ 1,
  /* hbool_t     set_initial_size       = */ 1,
  /* size_t      initial_size           = */ ( 2 * 1024 * 1024),
  /* double      min_clean_fraction     = */ 0.3,
  /* size_t      max_size               = */ (32 * 1024 * 1024),
  /* size_t      min_size               = */ ( 1 * 1024 * 1024),
  /* long int    epoch_length           = */ 50000,
  /* enum H5C_cache_incr_mode incr_mode = */ H5C_incr__threshold,
  /* double      lower_hr_threshold     = */ 0.9,
  /* double      increment              = */ 2.0,
  /* hbool_t     apply_max_increment    = */ 1,
  /* size_t      max_increment          = */ (4 * 1024 * 1024),
  /* enum H5C_cache_flash_incr_mode       */
  /*                    flash_incr_mode = */ H5C_flash_incr__add_space,
  /* double      flash_multiple         = */ 1.0,
  /* double      flash_threshold        = */ 0.25,
  /* enum H5C_cache_decr_mode decr_mode = */ H5C_decr__age_out_with_threshold,
  /* double      upper_hr_threshold     = */ 0.999,
  /* double      decrement              = */ 0.9,
  /* hbool_t     apply_max_decrement    = */ 1,
  /* size_t      max_decrement          = */ (1 * 1024 * 1024),
  /* int         epochs_before_eviction = */ 3,
  /* hbool_t     apply_empty_reserve    = */ 1,
  /* double      empty_reserve          = */ 0.1,
  /* int         dirty_bytes_threshold  = */ (256 * 1024)
    };

    //H5Fset_mdc_config((hid_t)hdf5_fileid, &cache_config);
 

    fh5f_close(&hdf5_fileid, &hdferr);
#endif

#ifdef USE_HDF5_BZIP
    int64_t hdf5_fileid;
    int hdferr;
    int iphdf5=1;
    int iaccess = 2;
    int data_type_num = 2;
    int m_ndims = 3;
    herr_t status;
    hsize_t dimsf[] = {nxp, nyp, nzp};
    hsize_t dimsm[] = {l_nx, l_ny, l_nz};
    hsize_t offset[] = {ixb, iyb, izb};
    hsize_t chunks_h5[] = {file_chunks[0], file_chunks[1], file_chunks[2]};
    status=H5Zregister(H5Z_BZIP2);
    //open HDF5 file
    fh5f_create (outloc,&iaccess,&iphdf5,&hdf5_fileid,&hdferr);

    /*
    fh5d_write (&hdf5_fileid,data_base_name,&data_type_num,&iphdf5,
                &m_ndims, int *m_select,
                int *f_ndims,int *f_select,int *f_csize,void *buf
                ,int *hdferr);
    */

    //my_hdf5_create_write(&m_ndims, chunks_h5, dimsf, dimsm, offset, &hdf5_fileid,
    //                        data_base_name, data_base);

    //my_hdf5_create_write(&m_ndims, chunks_h5, dimsf, dimsm, offset, &hdf5_fileid,
    //                        data_2x_name, data_2x);

    //my_hdf5_create_write(&m_ndims, chunks_h5, dimsf, dimsm, offset, &hdf5_fileid,
    //                        data_sqrt_name, data_sqrt);


    int64_t dsetids[200];
    for(int varnum=0; varnum<200; varnum++){

        char strbuf[13];
        snprintf(strbuf, 13, "data_sqrt%d", varnum);
        if(world_rank==MAIN_NUM){
            printf("Writing variable: %s\n", strbuf);
        }
        MPI_Barrier(MPI_COMM_WORLD);
        //my_hdf5_create_only(&m_ndims, chunks_h5, dimsf,&hdf5_fileid, strbuf, &dsetids[varnum]);
        my_hdf5_create_write_bz(&m_ndims, chunks_h5, dimsf, dimsm, offset, &hdf5_fileid,
                            strbuf, data_sqrt);
    }




    fh5f_close(&hdf5_fileid, &hdferr);
#endif


#ifdef USE_NC4
    printf("Using NetCDF4\n");
    char ncfilename[] = "/nobackupp2/swfreema/hdf5_test/test_nc_file.nc";
    int ncid; 
    int m_ndims = 3;

    open_nc_file(ncfilename, &ncid);
    size_t dimsf[] = {nxp, nyp, nzp};
    size_t dimsm[] = {l_nx, l_ny, l_nz};
    size_t offset[] = {ixb, iyb, izb};
    int xdimid, ydimid, zdimid;

    add_dimension(&ncid, "X", &nxp, &xdimid);
    add_dimension(&ncid, "Y", &nyp, &ydimid);
    add_dimension(&ncid, "Z", &nzp, &zdimid);

    int dimids[] = {xdimid, ydimid, zdimid};
    if(world_rank==MAIN_NUM){
	printf("ncid: %d, xdimid: %d, ydimid: %d, zdimid: %d", ncid, xdimid, ydimid, zdimid);
    }

    write_float_var(&ncid, data_base_name, &m_ndims, dimids, 
                    offset, dimsm, data_base);
    write_float_var(&ncid, data_2x_name, &m_ndims, dimids, 
                    offset, dimsm, data_2x);
    write_float_var(&ncid, data_sqrt_name, &m_ndims, dimids, 
                    offset, dimsm, data_sqrt);

    for(int varnum =0; varnum<200; varnum++){
        char strbuf[12];
        snprintf(strbuf, 12, "data_base%d", varnum);
        if(world_rank==MAIN_NUM){
            printf("Writing variable: %s\n", strbuf);
        }        
        write_float_var(&ncid, strbuf, &m_ndims, dimids, 
                    offset, dimsm, data_base);

    }



    close_nc_file(&ncid);
#endif




#ifdef USE_HDF5_SUBSET
    int n_io_tasks = 4;
    if(n_io_tasks>nodes){
        printf("Number of IO Tasks > number of MPI tasks, quitting. \n");
        return -1;
    }
    short amiio; //am I an IO task?
    int which_io_rank; //which IO rank am I?
    int io_tasks[] = {0,6,13,20,112,140,168,196,224,252};

    //find out if I am an IO task.
    amiio = 0;
    which_io_rank=-1;
    for(int i=0; i<n_io_tasks; i++){
        if(io_tasks[i] == world_rank){
            amiio = 1;
            which_io_rank = i;
        }

    }


    //instead of a more complicated approach, we are just going to 
    //write in hyperslabs corresponding to some number of RAMS subdomains.
    int initial_cpu_to_io = world_size/n_io_tasks;
    int extra_cpus = world_size%n_io_tasks;

    int my_io_node;

    int *cpu_to_io = malloc(n_io_tasks*(initial_cpu_to_io+1)*sizeof(int));
    int *num_cpu_subs = malloc(n_io_tasks*sizeof(int));

    int curr_cpu_task = 0;
    for(int ioid = 0; ioid<n_io_tasks; ioid++){
        if(extra_cpus>0){
            num_cpu_subs[ioid] = initial_cpu_to_io+1; 
            extra_cpus--;
        }
        else{
            num_cpu_subs[ioid] = initial_cpu_to_io;
        }

        for(int ncpu = 0; ncpu<num_cpu_subs[ioid]; ncpu++){
            if(curr_cpu_task == world_rank){
                //we have found my IO node!
                my_io_node = io_tasks[ioid];
            }
            cpu_to_io[t2d_1d(ioid, ncpu, n_io_tasks, initial_cpu_to_io+1)] = curr_cpu_task;
            curr_cpu_task++;
        }

    }






    MPI_Barrier(MPI_COMM_WORLD);
    if(world_rank == MAIN_NUM){
        printf("After the barrier \n");
        fflush(stdout);
    }

    //now let's do the writing!
    int64_t hdf5_fileid;
    int hdferr;
    int iphdf5=1;
    int iaccess = 2;
    int data_type_num = 2;
    int m_ndims = 3;

    float* buffer;
    MPI_Comm io_node_comm;
    MPI_Comm_split(MPI_COMM_WORLD, amiio, world_rank,&io_node_comm);

    if(amiio == 1){
        printf("Before creating file.\n");
        //if I am an I/O processor, I need to actually do the IO!
        //so we need to allocate a buffer to receive our data. 
        //FOR NOW, we will allocate this as the chunk size as that is guaranteed to be the largest subdomain size. 
        buffer = malloc(nzp*(file_chunks[0]*file_chunks[1])*2*sizeof(float));
        //create HDF5 file
        fh5f_create_wc (outloc,&iaccess,&iphdf5,&hdf5_fileid,&hdferr, io_node_comm);

    }
    if(world_rank == MAIN_NUM){
        //printf("After malloc \n");
        fflush(stdout);
    }




    MPI_Barrier(MPI_COMM_WORLD);
    int my_dims_offset[] = {l_nx, l_ny, l_nz, ixb, iyb, izb};
    int* dims_offset_from_all = malloc(6*(initial_cpu_to_io+1)*sizeof(int));
    

    for(int varnum =0; varnum<200; varnum++){
        if(world_rank == MAIN_NUM){
            printf("sending data \n");
        }
        MPI_Barrier(MPI_COMM_WORLD);
            
        MPI_Request request;
        printf("I am %d, sending dimensions and offset to %d.\n", world_rank, my_io_node);
        MPI_Isend(my_dims_offset, 6, MPI_INT, my_io_node, 4, MPI_COMM_WORLD, &request);
        printf("I am %d, I have sent dimensions and offset to %d\n", world_rank, my_io_node);
        //printf("Sent first offset stuff.\n");
	if(amiio==1){
                printf("I am %d, Receiving offset stuff as I am IO for varnum %d\n", world_rank, varnum);
                int sz_and_offset[6];
                for(int my_cpu_node = 0; my_cpu_node<num_cpu_subs[which_io_rank]; my_cpu_node++){
                   //we need to get the dims and offset of each of the nodes.
                   //let's receive that!
                   //which node are we receiving from here?
                   int cpu_node_recv = cpu_to_io[t2d_1d(which_io_rank, my_cpu_node, n_io_tasks, initial_cpu_to_io+1)];
                   printf("I am %d, Receiving from %d for varnum %d\n", world_rank, cpu_node_recv, varnum);
                   MPI_Recv(sz_and_offset, 6, MPI_INT, cpu_node_recv, 4, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                   printf("I am %d, reception complete from %d for varnum %d!\n", world_rank, cpu_node_recv, varnum);
                   for(int szofpos = 0; szofpos < 6; szofpos++){
                       dims_offset_from_all[t2d_1d(my_cpu_node, szofpos, (initial_cpu_to_io+1), 6)] = sz_and_offset[szofpos];
                   }
                }
  
        }
        MPI_Barrier(MPI_COMM_WORLD);
        char strbuf[12];
        snprintf(strbuf, 12, "data_base%d", varnum);
	int64_t hdf5_dsetid;
        MPI_Barrier(MPI_COMM_WORLD);
        fflush(stdout);
        if(amiio ==1){
		//go ahead and create the dataset
            hsize_t dimsf[] = {nxp, nyp, nzp};
            hsize_t chunks_h5[] = {file_chunks[0], file_chunks[1], file_chunks[2]};

            char strbuf[12];
            snprintf(strbuf, 12, "data_base%d", varnum);
	    fflush(stdout);
            MPI_Barrier(io_node_comm);
            printf("I am %d, Creating variable: %s\n", world_rank, strbuf);
            //printf("Creation parameters: m_ndims: %d, chunks_h5[0]: %d,
            my_hdf5_create_only(&m_ndims, chunks_h5, dimsf, &hdf5_fileid, strbuf, &hdf5_dsetid);
            printf("I am %d, Finished Creating variable: %s\n", world_rank, strbuf);
            MPI_Barrier(io_node_comm);

	

	}
        
        MPI_Barrier(MPI_COMM_WORLD);
        fflush(stdout);
        //printf("Before sending data_base\n");
        printf("I am %d, sending data_base to  %d! for varnum %d\n", world_rank, my_io_node, varnum);
        MPI_Isend(data_base, l_nx*l_ny*l_nz, 
                    MPI_FLOAT, my_io_node, 5, MPI_COMM_WORLD, &request);
        printf("I am %d, finished sending data_base to  %d for varnum %d!\n", world_rank, my_io_node, varnum);


        if(world_rank == MAIN_NUM){
            printf("Receiving data.\n");
        }
        MPI_Barrier(MPI_COMM_WORLD);

        if(amiio==1){
            //let's start by creating the dataset. 
            
            hsize_t dimsf[] = {nxp, nyp, nzp};
            hsize_t chunks_h5[] = {file_chunks[0], file_chunks[1], file_chunks[2]};

            int *sz_and_offset;// = malloc(6*sizeof(int));
            for(int my_cpu_node = 0; my_cpu_node<num_cpu_subs[which_io_rank]; my_cpu_node++){
                //we need to get the dims and offset of each of the nodes. 
                //let's receive that!
                //which node are we receiving from here?
                int cpu_node_recv = cpu_to_io[t2d_1d(which_io_rank, my_cpu_node, n_io_tasks, initial_cpu_to_io+1)];
                sz_and_offset = &dims_offset_from_all[t2d_1d(my_cpu_node, 0, (initial_cpu_to_io+1), 6)];

                hsize_t dimsm[] = {sz_and_offset[0], sz_and_offset[1], sz_and_offset[2]};
                hsize_t offset[] = {sz_and_offset[3], sz_and_offset[4], sz_and_offset[5]};
                int szrec = sz_and_offset[0]* sz_and_offset[1]* sz_and_offset[2];
                //now let's get the data. 
                printf("I am %d, receiving %s from %d\n", world_rank, strbuf, cpu_node_recv);
                MPI_Recv(buffer, szrec, MPI_FLOAT, cpu_node_recv, 5, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                my_hdf5_write_only(&m_ndims, dimsm, offset, &hdf5_dsetid, buffer);

            }
            MPI_Barrier(io_node_comm);
            printf("I am %d, closing dset: %s\n", world_rank, strbuf);
            my_hdf5_close_dset(&hdf5_dsetid);
            printf("I am %d, closed dset: %s\n", world_rank, strbuf);
           MPI_Barrier(io_node_comm); 

        }
        MPI_Barrier(MPI_COMM_WORLD);
    }//end varnum for loop
    MPI_Barrier(MPI_COMM_WORLD);

    if(amiio==1){
        printf("Before file close\n");
        fh5f_close(&hdf5_fileid, &hdferr);
        printf("After file close\n");
    }




#endif

    //now to free the main arrays.
    free(data_base);
    free(data_2x);
    free(data_sqrt);
    //printf("Hello World!\n");
    if(world_rank == MAIN_NUM){
        free(ixb_all);
        free(ixe_all);
        free(iyb_all); 
        free(iye_all);

    }
    MPI_Finalize();

    return 0;
}
