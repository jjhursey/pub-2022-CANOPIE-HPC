CC=mpicc
CFLAGS=-Wall -g -O0

PROGS=init_finalize mpi_sleeper display_version

all: $(PROGS)

init_finalize: init_finalize.c
	$(CC) init_finalize.c $(CFLAGS) -o init_finalize

mpi_sleeper: mpi_sleeper.c
	$(CC) mpi_sleeper.c $(CFLAGS) -o mpi_sleeper

display_version: display_version.c
	$(CC) display_version.c $(CFLAGS) -o display_version

install: all
	mv -f $(PROGS) ../bin/

clean:
	$(RM) $(PROGS) *.o
