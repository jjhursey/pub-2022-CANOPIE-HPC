#
# Makefile for the k8sgo PLM helper
#
BIN = basic_launcher

all: $(BIN)

basic_launcher: basic_launcher.c
	$(CC) -g -O0 basic_launcher.c -o basic_launcher

clean:
	$(RM) $(BIN) *.o
