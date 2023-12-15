import h5py
import numpy as np
from mpi4py import MPI

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()
if rank == 0:
  print("rank", " max length ", " lenth"," data\t","dataset")

length = np.random.randint(2,10)
buflength = max(comm.allgather(length))

data = np.asarray([np.random.randint(1, 100) for x in range(length)])

f = h5py.File('parallel_test.hdf5', 'w', driver='mpio', comm=comm)
f.atomic = True

dset = []
for i in range(0,size):
  grp = f.create_group('rank{0}'.format(i))
  dset.append(grp.create_dataset('data',(buflength,),maxshape=(None,),
                                 dtype='i' ))
                                    #chunks=(buflength,)))

dset[rank][:length] = data
dset[rank].resize((length,))
print(rank,"\t",buflength,"\t   ",length," \t ",data, dset[rank][:])
f.close()

