#include <sys/types.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <hdf5.h>
#include "H5Zbzip2.h"


const H5Z_class2_t H5Z_BZIP2[1] = {{
    H5Z_CLASS_T_VERS,       /* H5Z_class_t version */
    (H5Z_filter_t)H5Z_FILTER_BZIP2,         /* Filter id number             */
    1,              /* encoder_present flag (set to true) */
    1,              /* decoder_present flag (set to true) */
    "bzip2",                  /* Filter name for debugging    */
    NULL,                       /* The "can apply" callback     */
    NULL,                       /* The "set local" callback     */
    (H5Z_func_t)H5Z_filter_bzip2,         /* The actual filter function   */
}};

size_t H5Z_filter_bzip2(unsigned int flags, size_t cd_nelmts,
             const unsigned int cd_values[], size_t nbytes,
             size_t *buf_size, void **buf);


size_t H5Z_filter_bzip2(unsigned int flags, size_t cd_nelmts,
                     const unsigned int cd_values[], size_t nbytes,
                     size_t *buf_size, void **buf)
{
  char *outbuf = NULL;
  size_t outbuflen, outdatalen;
  int ret;

  if (flags & H5Z_FLAG_REVERSE) {

    /** Decompress data.
     **
     ** This process is troublesome since the size of uncompressed data
     ** is unknown, so the low-level interface must be used.
     ** Data is decompressed to the output buffer (which is sized
     ** for the average case); if it gets full, its size is doubled
     ** and decompression continues.  This avoids repeatedly trying to
     ** decompress the whole block, which could be really inefficient.
     **/

    bz_stream stream;
    char *newbuf = NULL;
    size_t newbuflen;

    /* Prepare the output buffer. */
    outbuflen = nbytes * 3 + 1;  /* average bzip2 compression ratio is 3:1 */
    outbuf = malloc(outbuflen);
    if (outbuf == NULL) {
      fprintf(stderr, "memory allocation failed for bzip2 decompression\n");
      goto cleanupAndFail;
    }

    /* Use standard malloc()/free() for internal memory handling. */
    stream.bzalloc = NULL;
    stream.bzfree = NULL;
    stream.opaque = NULL;

    /* Start decompression. */
    ret = BZ2_bzDecompressInit(&stream, 0, 0);
    if (ret != BZ_OK) {
      fprintf(stderr, "bzip2 decompression start failed with error %d\n", ret);
      goto cleanupAndFail;
    }

    /* Feed data to the decompression process and get decompressed data. */
    stream.next_out = outbuf;
    stream.avail_out = outbuflen;
    stream.next_in = *buf;
    stream.avail_in = nbytes;
    do {
      ret = BZ2_bzDecompress(&stream);
      if (ret < 0) {
    fprintf(stderr, "BUG: bzip2 decompression failed with error %d\n", ret);
    goto cleanupAndFail;
      }

      if (ret != BZ_STREAM_END && stream.avail_out == 0) {
        /* Grow the output buffer. */
        newbuflen = outbuflen * 2;
        newbuf = realloc(outbuf, newbuflen);
        if (newbuf == NULL) {
          fprintf(stderr, "memory allocation failed for bzip2 decompression\n");
          goto cleanupAndFail;
        }
        stream.next_out = newbuf + outbuflen;  /* half the new buffer behind */
        stream.avail_out = outbuflen;  /* half the new buffer ahead */
        outbuf = newbuf;
        outbuflen = newbuflen;
      }
    } while (ret != BZ_STREAM_END);

    /* End compression. */
    outdatalen = stream.total_out_lo32;
    ret = BZ2_bzDecompressEnd(&stream);
    if (ret != BZ_OK) {
      fprintf(stderr, "bzip2 compression end failed with error %d\n", ret);
      goto cleanupAndFail;
    }

  } else {

    /** Compress data.
     **
     ** This is quite simple, since the size of compressed data in the worst
     ** case is known and it is not much bigger than the size of uncompressed
     ** data.  This allows us to use the simplified one-shot interface to
     ** compression.
     **/

    unsigned int odatalen;  /* maybe not the same size as outdatalen */
    int blockSize100k = 9;

    /* Get compression block size if present. */
    if (cd_nelmts > 0) {
      blockSize100k = cd_values[0];
      if (blockSize100k < 1 || blockSize100k > 9) {
    fprintf(stderr, "invalid compression block size: %d\n", blockSize100k);
    goto cleanupAndFail;
      }
    }

    /* Prepare the output buffer. */
    outbuflen = nbytes + nbytes / 100 + 600;  /* worst case (bzip2 docs) */
    outbuf = malloc(outbuflen);
    if (outbuf == NULL) {
      fprintf(stderr, "memory allocation failed for bzip2 compression\n");
      goto cleanupAndFail;
    }

    /* Compress data. */
    odatalen = outbuflen;
    ret = BZ2_bzBuffToBuffCompress(outbuf, &odatalen, *buf, nbytes,
                                   blockSize100k, 0, 0);
    outdatalen = odatalen;
    if (ret != BZ_OK) {
      fprintf(stderr, "bzip2 compression failed with error %d\n", ret);
      goto cleanupAndFail;
    }
  }

  /* Always replace the input buffer with the output buffer. */
  free(*buf);
  *buf = outbuf;
  *buf_size = outbuflen;
  return outdatalen;

 cleanupAndFail:
  if (outbuf)
    free(outbuf);
  return 0;
}

void my_hdf5_create_write_bz(int *m_ndims,hsize_t* chunks, hsize_t *dimsf, hsize_t *dimsm, hsize_t* offset,
                        int64_t *hdf5_fileid, char* data_base_name,
                        void* data_base){
       hid_t filespace;
   hid_t memspace;
    hid_t dset_id;
    hid_t plist_id;
    hid_t fileid_h5 = (hid_t)*hdf5_fileid;
    const unsigned cd_values[1] = {9}; //bzip level
    herr_t status;
   filespace = H5Screate_simple(*m_ndims, dimsf, NULL);
   plist_id = H5Pcreate(H5P_DATASET_CREATE);
   H5Pset_chunk(plist_id, *m_ndims, chunks);
   unsigned szip_options_mask = H5_SZIP_EC_OPTION_MASK;
   unsigned szip_pixels_per_block = 10;
    H5Pset_shuffle(plist_id);
    H5Pset_filter(plist_id, (H5Z_filter_t)H5Z_FILTER_BZIP2, H5Z_FLAG_MANDATORY, (size_t)1, cd_values);
    //H5Pset_deflate(plist_id, 6);
    //H5Pset_szip(plist_id, szip_options_mask, szip_pixels_per_block);


    dset_id = H5Dcreate(fileid_h5, data_base_name, H5T_NATIVE_FLOAT,
                        filespace, H5P_DEFAULT, plist_id, H5P_DEFAULT);
    H5Sclose(filespace);
    H5Pclose(plist_id);


    memspace = H5Screate_simple(*m_ndims, dimsm, NULL);

    filespace = H5Dget_space(dset_id);
    H5Sselect_hyperslab(filespace, H5S_SELECT_SET, offset, NULL, dimsm, NULL);

    plist_id = H5Pcreate(H5P_DATASET_XFER);
    H5Pset_dxpl_mpio(plist_id, H5FD_MPIO_COLLECTIVE);
    status = H5Dwrite(dset_id, H5T_NATIVE_FLOAT, memspace, filespace,
                      plist_id, data_base);


    H5Dclose(dset_id);
    H5Sclose(filespace);
    H5Sclose(memspace);
    H5Pclose(plist_id);
}
