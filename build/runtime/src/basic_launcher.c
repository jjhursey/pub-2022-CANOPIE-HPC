#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define MAX_HOSTNAME 256

extern char **environ;

int main(int argc, char** argv) {
    int i, a, d_idx;
    int arg_sep = -1;
    char *nodelist_file = NULL;
    char nodename[MAX_HOSTNAME];
    int num_nodes;
    pid_t *daemon_pids = NULL;
    FILE *node_fp = NULL;
    char ** daemon_argv = NULL;
    int daemon_argc = 0;
    bool be_quiet = false;

    // Scan for -q = be_quiet
    for(i = 0; i < argc; ++i) {
        if( 0 == strcmp(argv[i], "--") ) {
            break;
        }
        else if( 0 == strncmp(argv[i], "-q", 2) ) {
            be_quiet = true;
            break;
        }
    }

    /*
     * Display the argument set
     */
    if (!be_quiet) {
        printf("--------------------\n");
        printf("------- Arguments\n");
        printf("--------------------\n");
    }
    for(i = 0; i < argc; ++i) {
        if( arg_sep < 0) {
            if( 0 == strcmp(argv[i], "--") ) {
                arg_sep = i;
            }

            if (!be_quiet) {
                printf("---- %3d) \"%s\"\n", i, argv[i]);
            }
            if( 0 == strncmp(argv[i], "-f", 2) ) {
                ++i;
                if( i >= argc ) {
                    printf("Error: Expected argument after \"-f\"\n");
                    exit(1);
                }
                if (!be_quiet) {
                    printf("---- %3d) \"%s\"\n", i, argv[i]);
                }
                nodelist_file = strdup(argv[i]);
            }
        } else if (!be_quiet){
            printf("PRTE %3d) \"%s\"\n", i, argv[i]);
        }
    }

    /*
     * Display the environment variables
     */
#if 0
    if (!be_quiet) {
        printf("--------------------\n");
        printf("------- Environment\n");
        printf("--------------------\n");
        for(i = 0; NULL != environ[i]; ++i) {
            printf("%3d) %s\n", i, environ[i]);
        }
        printf("\n");
    }
#endif

    /*
     * Display the nodelist
     */
    if( NULL != nodelist_file ) {
        if (!be_quiet) {
            printf("--------------------\n");
            printf("------- Nodelist\n");
            printf("--------------------\n");
        }
        node_fp = fopen(nodelist_file, "r");
        if( NULL == node_fp ) {
            fprintf(stderr, "ERROR: Failed to open the nodelist file: %s\n", nodelist_file);
            exit(1);
        }

        num_nodes = 0;
        for(i = 0; NULL != fgets(nodename, MAX_HOSTNAME, node_fp); ++i) {
            if( '\n' == nodename[strlen(nodename)-1] ) {
                nodename[strlen(nodename)-1] = '\0';
            }
            if (!be_quiet) {
                printf("%3d) \"%s\" Set envar: PRTE_ESS_K8SGO_ID=%d\n", i, nodename, i);
            }
            ++num_nodes;
        }
        fclose(node_fp);
        fflush(NULL);

        /*
         * Display the launch commands per node
         * Launch them as we go via 'ssh'
         */
        if (!be_quiet) {
            printf("--------------------\n");
            printf("------- Pernode launch command\n");
            printf("--------------------\n");
        }
        daemon_argc = argc - arg_sep; // Number of daemon arguments (includes NULL)
        daemon_argc += 3; // 'ssh' + 'nodename' + 'PRTE_ESS_K8SGO_ID'
        daemon_argv = (char**)malloc(sizeof(char*) * daemon_argc);
        daemon_pids = (int*)malloc(sizeof(int) * num_nodes);

        node_fp = fopen(nodelist_file, "r");
        for(i = 0; NULL != fgets(nodename, MAX_HOSTNAME, node_fp); ++i) {
            if( '\n' == nodename[strlen(nodename)-1] ) {
                nodename[strlen(nodename)-1] = '\0';
            }

            if( 0 == i ) {
                // Launcher
                daemon_argv[0] = strdup("ssh");

                // Node
                daemon_argv[1] = strdup(nodename);

                // 'vpid' Offset for this daemon
                asprintf(&(daemon_argv[2]), "PRTE_ESS_K8SGO_ID=%d", i);
                d_idx = 3;

                // Daemon to launch with arguments
                for(a = arg_sep+1; a < argc && NULL != argv[a]; ++a) {
                    daemon_argv[d_idx++] = strdup(argv[a]);
                }

                // exec requires the last arg to be NULL
                daemon_argv[daemon_argc-1] = NULL;
            }
            else {
                free(daemon_argv[1]);
                daemon_argv[1] = strdup(nodename);

                free(daemon_argv[2]);
                asprintf(&daemon_argv[2], "PRTE_ESS_K8SGO_ID=%d", i);
            }

            if (!be_quiet) {
                printf("Node %s)", nodename);
                for(d_idx = 0; d_idx < daemon_argc-1; ++d_idx) {
                    printf(" %s", daemon_argv[d_idx]);
                }
                printf("\n");
            }

            // Create the process
            daemon_pids[i] = fork();
            if(daemon_pids[i] < 0) {
                fprintf(stderr, "Error: Failed to create a process\n");
                exit(1);
            }
            else if(0 == daemon_pids[i]) {
                execvp(daemon_argv[0], daemon_argv);
                fprintf(stderr, "Error: Failed to execvp\n");
                exit(1);
            }
            else {
                ;//sleep(1);
            }
        }
        fclose(node_fp);
        fflush(NULL);

        // Cleanup
        for(d_idx = 0; d_idx < daemon_argc; ++d_idx) {
            if(NULL != daemon_argv[d_idx]) {
                free(daemon_argv[d_idx]);
            }
        }
        free(daemon_argv);
        free(nodelist_file);

        if (!be_quiet) {
            printf("-------------------- Waiting for daemons\n");
            fflush(NULL);
        }
        for(i = 0; i < num_nodes; ++i) {
            waitpid(daemon_pids[i], NULL, 0);
            if (!be_quiet) {
                printf("Pid %d Done\n", daemon_pids[i]);
            }
        }
        free(daemon_pids);
    }

    if (!be_quiet) {
        printf("-------------------- DONE\n");
    }

    return 0;
}
