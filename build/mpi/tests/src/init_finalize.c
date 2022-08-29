/*
 * MPI_Init / MPI_Finalize application template
 *
 * -- 
 */
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <time.h>
#include "mpi.h"

double my_wtime(void);
double my_wtime(void) {
    double wtime = 0;
    struct timespec tp;

    if( 0 == clock_gettime(CLOCK_MONOTONIC, &tp) ) {
        wtime = (tp.tv_sec * 1e6 + tp.tv_nsec/1000);
    }

    return wtime / 1000000.0;
}

int main(int argc, char* argv[]) {
    double start, mid1, mid2, end;
    int mcw_rank, mcw_size;
    int local_size = 0;

    /*---------------------------------------------------
     * Init
     *---------------------------------------------------*/
    start = my_wtime(); //------------------------- TIME
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &mcw_rank);
    MPI_Comm_size(MPI_COMM_WORLD,&mcw_size);

    if( NULL != getenv("OMPI_COMM_WORLD_LOCAL_SIZE") ) {
        local_size = atoi(getenv("OMPI_COMM_WORLD_LOCAL_SIZE"));
    }
    else if( NULL != getenv("JSM_NAMESPACE_LOCAL_SIZE") ) {
        local_size = atoi(getenv("JSM_NAMESPACE_LOCAL_SIZE"));
    }
    else {
        local_size = 1;
    }


    mid1 = my_wtime(); //-------------------------- TIME

    if( 0 == mcw_rank ) {
        printf("%2d) Size: %d (Running)\n", mcw_rank, mcw_size);
        fflush(NULL);
    }

    MPI_Barrier(MPI_COMM_WORLD);
    /*---------------------------------------------------
     * Optional: Alltoall to establish connectivity
     *---------------------------------------------------*/
    if( 1 < argc ) {
        int MAXLEN = (1024) / 4;
        int *sbuf = NULL;
        int *rbuf  = NULL;
        int i, scount, rcount;

        rbuf = (int*) malloc( sizeof(int) * MAXLEN * mcw_size );
        sbuf = (int*) malloc( sizeof(int) * MAXLEN * mcw_size );
        for( i = 0; i < MAXLEN * mcw_size; ++i ) {
            sbuf[i] = mcw_rank;
        }

        scount = rcount = MAXLEN;

        MPI_Alltoall( sbuf, scount, MPI_INT,
                      rbuf, rcount, MPI_INT,
                      MPI_COMM_WORLD );

        MPI_Barrier(MPI_COMM_WORLD);
    }
    mid2 = my_wtime(); //-------------------------- TIME


    /*---------------------------------------------------
     * Finalize
     *---------------------------------------------------*/
    MPI_Finalize();
    end = my_wtime(); //--------------------------- TIME


    /*---------------------------------------------------
     * Display results - only at rank 0
     *---------------------------------------------------*/
    if( mcw_rank == 0 ) {
        printf("%2d) NP  : %9d procs [%4d Nodes at %3d PPN]\n", mcw_rank, mcw_size, (mcw_size/local_size), local_size);
        printf("%2d) Init: %9.3f sec\n", mcw_rank, (mid1 - start));
        printf("%2d) Barr: %9.3f sec\n", mcw_rank, (mid2 - mid1));
        printf("%2d) Fin : %9.3f sec\n", mcw_rank, (end - mid2));
        printf("%2d) I+F : %9.3f sec\n", mcw_rank, (mid1 - start) + (end - mid2));
        printf("%2d) Time: %9.3f sec\n", mcw_rank, (end - start));
        fflush(NULL);
    }

    return 0;
}
