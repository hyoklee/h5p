#CC = /home1/swfreema/CAMP2Ex_2019_basin_HDF5_110/HDF5_110/bin/h5pcc
#CC=/nobackupp19/swfreema/INCUS/basin_simulations/philippines_camp2ex_summer/rams_code/hdf5-zfp-2/HDF5-1.13.2/bin/h5pcc
#CC=/nobackupp19/swfreema/INCUS/basin_simulations/philippines_camp2ex_summer/rams_code/hdf5-zfp-2/HDF5-1.10.7/bin/h5pcc
#CC=/nobackupp19/swfreema/hdf5_test/hdf5_versions/HDF5-1.10.8/bin/h5pcc
#CC=/nobackupp19/swfreema/hdf5_test/hdf5_versions/HDF5-1.10.9/bin/h5pcc
#CC=/nobackupp19/swfreema/hdf5_test/hdf5_versions/HDF5-IMPI/HDF5-1.10.9/bin/h5pcc
CC=/Users/hyoklee/src/hdf5/build/install/bin/h5pcc
CFLAGS=-lm -std=c99 -lz -g -Wall

DEPS = rams_subdomains.h hdf5_output.h #H5Zbzip2.h 
OBJ = rams_subdomains.o driver.o hdf5_output.o #H5Zbzip2.o
EXE_NM = test_hdf5

%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

$(EXE_NM): $(OBJ)
	$(CC) -o $@ $^ $(CFLAGS)

.PHONY: clean

clean:
	rm -f *.o $(EXE_NM)
