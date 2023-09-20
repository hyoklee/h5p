all:
	rm -f output.dat.gz
	mpicc b.c -o b -lz
	mpirun -np 2 ./b
	zlib-flate -uncompress < output.dat.gz > output.dat
