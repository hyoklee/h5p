#include <pthread.h>
#include <hdf5.h>

#define NUM_THREADS 3

typedef struct {
  char *filename;
  int thread_id;
} thread_data_t;

void *thread_function(void *arg) {
  thread_data_t *data = (thread_data_t *)arg;

  // Create a new HDF5 file
  hid_t file_id = H5Fcreate(data->filename, H5F_ACC_RDWR, H5P_DEFAULT, H5P_DEFAULT);
  if (file_id < 0) {
    printf("Error creating HDF5 file for thread %d\n", data->thread_id);
    return NULL;
  }
  hsize_t dims[1] = {1};
  // Create a dataset for the thread
  hid_t dataset_id = H5Dcreate(file_id, "dataset", H5T_NATIVE_INT, H5Screate_simple(1, dims, NULL), H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
  if (dataset_id < 0) {
    printf("Error creating dataset for thread %d\n", data->thread_id);
    H5Fclose(file_id);
    return NULL;
  }

  // Write the thread ID to the dataset
  int value = data->thread_id;
  H5Dwrite(dataset_id, H5T_NATIVE_INT, H5S_ALL, H5S_ALL, H5P_DEFAULT, &value);

  // Close the dataset and file
  H5Dclose(dataset_id);
  H5Fclose(file_id);

  return NULL;
}

int main() {
  // Create the filenames for the three HDF5 files
  char filenames[NUM_THREADS][1024];
  for (int i = 0; i < NUM_THREADS; i++) {
    sprintf(filenames[i], "thread_%d.hdf5", i);
  }

  // Create the threads and wait for them to finish
  pthread_t threads[NUM_THREADS];
  thread_data_t data[NUM_THREADS];
  for (int i = 0; i < NUM_THREADS; i++) {
    data[i].filename = filenames[i];
    data[i].thread_id = i;

    if (pthread_create(&threads[i], NULL, thread_function, &data[i]) != 0) {
      printf("Error creating thread %d\n", i);
      return 1;
    }
  }

  for (int i = 0; i < NUM_THREADS; i++) {
    pthread_join(threads[i], NULL);
  }

  return 0;
}
