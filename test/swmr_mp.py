import multiprocessing
import multiprocessing.shared_memory
import numpy as np
import time

def writer_process(shared_memory_name, array_shape, array_dtype):
    """Writes data to the shared memory array."""
    try:
        # Attach to the existing shared memory block
        shared_mem = multiprocessing.shared_memory.SharedMemory(name=shared_memory_name)

        # Create a NumPy array using the shared memory
        shared_array = np.ndarray(array_shape, dtype=array_dtype, buffer=shared_mem.buf)

        print("Writer: Starting to write data...")
        for i in range(10):  # Write 10 "chunks" of data
            data = np.ones(array_shape, dtype=array_dtype) * i  # Example data
            shared_array[:] = data # Write to shared memory
            print(f"Writer: Wrote data {i}")
            time.sleep(1) # Simulate some work

        print("Writer: Finished writing data.")

    finally:
        shared_mem.close()  # Release the shared memory (important!)
        # shared_mem.unlink() # Only the writer should unlink, after all readers are done.  We'll do this outside the process.


def reader_process(shared_memory_name, array_shape, array_dtype, reader_id):
    """Reads data from the shared memory array."""
    try:
        # Attach to the existing shared memory block
        shared_mem = multiprocessing.shared_memory.SharedMemory(name=shared_memory_name)
        shared_array = np.ndarray(array_shape, dtype=array_dtype, buffer=shared_mem.buf)

        print(f"Reader {reader_id}: Starting to read...")

        for i in range(10): # Read 10 "chunks"
            print(f"Reader {reader_id}: Read data: {shared_array[0,0]} (Iteration {i})")  # Read and print a value
            time.sleep(0.5) # Simulate some work

        print(f"Reader {reader_id}: Finished reading.")

    finally:
        shared_mem.close()  # Release the shared memory


if __name__ == "__main__":
    array_shape = (5, 5)  # Example shape
    array_dtype = np.int32

    # Create the shared memory block *only once*
    shared_mem = multiprocessing.shared_memory.SharedMemory(create=True, size=np.prod(array_shape) * np.dtype(array_dtype).itemsize)
    shared_memory_name = shared_mem.name  # Get the name for the other processes
    shared_array = np.ndarray(array_shape, dtype=array_dtype, buffer=shared_mem.buf) # Create the array in main process so we can initialize it
    shared_array[:] = -1 # Initialize shared memory

    # Create and start the writer process
    writer = multiprocessing.Process(target=writer_process, args=(shared_memory_name, array_shape, array_dtype))
    writer.start()

    # Create and start multiple reader processes
    readers = []
    for i in range(3):  # Create 3 readers
        reader = multiprocessing.Process(target=reader_process, args=(shared_memory_name, array_shape, array_dtype, i))
        readers.append(reader)
        reader.start()

    # Wait for all processes to finish
    writer.join()
    for reader in readers:
        reader.join()

    # Clean up the shared memory *only once* after all processes are done
    shared_mem.close()
    shared_mem.unlink()

    print("All processes finished.")
    
