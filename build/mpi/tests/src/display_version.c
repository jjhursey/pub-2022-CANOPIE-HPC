/*
 * MPI_Init / MPI_Finalize application template - Displays version information
 *
 * -- 
 */
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>
#include "mpi.h"

int main(int argc, char* argv[]) {
    int mcw_rank, mcw_size, len;
    char hname[MPI_MAX_PROCESSOR_NAME];
    char version[MPI_MAX_LIBRARY_VERSION_STRING];

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &mcw_rank);
    MPI_Comm_size(MPI_COMM_WORLD,&mcw_size);
    MPI_Get_processor_name(hname, &len);
    MPI_Get_library_version(version, &len);

    MPI_Barrier(MPI_COMM_WORLD);

    printf("%2d/%2d on %s: Version %s\n", mcw_rank, mcw_size, hname, version);

    MPI_Finalize();

    return 0;
}
