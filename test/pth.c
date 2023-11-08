#include <hdf5.h>
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#define NUM_THREADS 3

const char* file_names[NUM_THREADS] = {"file1.h5", "file2.h5", "file3.h5"};

void* write_to_file(void* arg) {
  int thread_id = ((int)arg);
  
  FILE *fp = fopen(file_names[thread_id], "w");
  if (fp == NULL) {
    printf("Error opening %s\n", file_names[thread_id]);
    exit(1);
  }

  fprintf(fp, "This is %s\n", file_names[thread_id]);
  fclose(fp);

  return NULL;
}

void* write_to_hdf5(void* arg) {

  int thread_id = ((int)arg);
  printf("thread_id=%d\n", thread_id);
  
  // hid_t file_id = H5Fcreate(file_names[thread_id], H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);
  hid_t file_id = H5Fcreate(file_names[thread_id], H5F_ACC_RDWR, H5P_DEFAULT, H5P_DEFAULT);

  hsize_t dims[2] = {2, 2};
  hid_t dataspace = H5Screate_simple(2, dims, NULL);
  hid_t dataset = H5Dcreate2(file_id, "dataset", H5T_NATIVE_INT, dataspace, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

  int data[2][2] = {{1, 2}, {3, 4}};

  H5Dwrite(dataset, H5T_NATIVE_INT, H5S_ALL, H5S_ALL, H5P_DEFAULT, data);

  H5Dclose(dataset);
  H5Sclose(dataspace);
  H5Fclose(file_id);

}

int main() {
  
  pthread_t threads[NUM_THREADS];
  int thread_ids[NUM_THREADS];

  for (int i = 0; i < NUM_THREADS; i++) {
    thread_ids[i] = i;
    int result = pthread_create(&threads[i], NULL, write_to_hdf5, i); 
    /* int result = pthread_create(&threads[i], NULL, write_to_file, i); */
    if (result) {
      fprintf(stderr, "Error creating thread %d: %d\n", i, result);
      exit(-1);
    }
  }

  for (int i = 0; i < NUM_THREADS; i++) {
    pthread_join(threads[i], NULL);
  }

  return 0;
  
}
