/*
 * MPI_Init / MPI_Finalize application template - Sleeper
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
    int sleep_time = 0;
    int mcw_rank, mcw_size, len;
    int wait_for_rescue = 0;
    char hname[MPI_MAX_PROCESSOR_NAME];

    if( 1 < argc ) {
        sleep_time = atoi(argv[1]);
    }
    if( 2 < argc ) {
        if( 0 == strcmp(getenv("PMIX_RANK"), "0") ) {
            wait_for_rescue = 1;
            printf("Waiting for rescue - %d\n", getpid());
        }
    }

    while( 1 == wait_for_rescue ) {
        sleep(1);
    }

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &mcw_rank);
    MPI_Comm_size(MPI_COMM_WORLD,&mcw_size);
    MPI_Get_processor_name(hname, &len);

    MPI_Barrier(MPI_COMM_WORLD);

    printf("%2d/%2d) Sleeping for %d sec on %s\n", mcw_rank, mcw_size, sleep_time, hname);
    sleep(sleep_time);

    MPI_Finalize();


    return 0;
}
