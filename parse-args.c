#include <getopt.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <strings.h>
#include <string.h>
#include <time.h>
#include "parse-args.h"

#define SOURCE 1000
#define TARGET 1001 
#define INDEX  1002
#define BLOCK  1003
#define SEED   1004

#define STRING_SIZE 100
#define INTERACTIVE "INTERACTIVE"
void error(char *what, int code){
    printf("Error: ");
    printf("%s", what);
    printf("\n");
    exit(code);
}

void safestrcopy(char *dest, char *src){
    dest[0] = '\0';
    strncat(dest, src, STRING_SIZE-1);
}

void parse_args(int argc, char **argv)
{
    json_flag = 0;
    static int verbose_flag  = 0;
    static int platform_flag = 0;
    enum sg_backend backend = INVALID;
    source_len = 0;
    target_len = 0;
    index_len  = 0;
    block_len  = 1;
    seed       = time(NULL); 

	static struct option long_options[] =
    {
    	/* These options set a flag. */
        {"verbose",     no_argument,       &verbose_flag, 1},
        {"backend",     required_argument, NULL, 'b'},
        {"cl-platform", required_argument, NULL, 'p'},
        {"cl-device",   required_argument, NULL, 'd'},
        {"kernel-file", required_argument, NULL, 'f'},
        {"kernel-name", required_argument, NULL, 'g'},
        {"source-len",  required_argument, NULL, SOURCE},
        {"target-len",  required_argument, NULL, TARGET},
        {"index-len",   required_argument, NULL, INDEX},
        {"block-len",   required_argument, NULL, BLOCK},
        {"seed",        required_argument, NULL, SEED},
        {"interactive", no_argument,       0, 'i'},
        {0, 0, 0, 0}
    };  

    int c = 0;
    int option_index = 0;

    while(c != -1){

    	c = getopt_long_only (argc, argv, "i",
                         long_options, &option_index);

        switch(c){
            case 'b':
                if(!strcasecmp("OPENCL", optarg)){
                    backend = OPENCL;
                }
                else if(!strcasecmp("OPENMP", optarg)){
                    backend = OPENMP;
                }
                break;
            case 'p':
                safestrcopy(platform_string, optarg);
                break;
            case 'd':
                safestrcopy(device_string, optarg);
               break;
            case 'i':
                safestrcopy(platform_string, INTERACTIVE);
                safestrcopy(device_string, INTERACTIVE);
                break;
            case 'f':
                safestrcopy(kernel_file, optarg);
                break;
            case 'g':
                safestrcopy(kernel_name, optarg);
                break;
            case SOURCE:
                sscanf(optarg, "%zu", &source_len);
                break;
            case TARGET:
                sscanf(optarg, "%zu", &target_len);
                break;
            case INDEX:
                sscanf(optarg, "%zu", &index_len);
                break;
            case BLOCK:
                sscanf(optarg, "%zu", &block_len);
                break;
            case SEED:
                sscanf(optarg, "%zu", &seed);
                break;
            default:
                break;

        }

    }

    /* Check argument coherency */

    //Check backend
    if(backend != INVALID){
        if(backend == OPENCL){
            if(platform_string[0] == '\0'){
                safestrcopy(platform_string, INTERACTIVE);
                safestrcopy(device_string, INTERACTIVE);
            }
            if(device_string[0] == '\0'){
                safestrcopy(platform_string, INTERACTIVE);
                safestrcopy(device_string, INTERACTIVE);
            }
        }
    }
    else if(backend == INVALID){
        error("SGBench backend not specified or invalid", 1);
    }

    //Check buffer lengths
    if(source_len <= 0){
        error("Unspecified or invalid source-len", 1);
    }
    if(target_len <= 0){
        error("Unspecified or invalid target-len", 1);
    }
    if(index_len <= 0){
        error("Unspecified or invalid index-len", 1);
    }
    if(block_len < 1){
        error("Invalid index-len", 1);
    }

    /* Seed rand */
    srand(seed);


}