#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include "kernels/openmp_kernels.h"
#include "cl-helper.h"
#include "parse-args.h"
#include "sgtype.h"
#include "sgbuf.h"

#define alloc(size) aligned_alloc(64, size)

void random_data(SGTYPE *buf, size_t len){
    for(size_t i = 0; i < len; i++){
        buf[i] = rand() % 10; 
    }
}

void linear_indices(cl_ulong *idx, size_t len, size_t worksets){
    cl_ulong *idx_cur = idx;
    for(size_t j = 0; j < worksets; j++){
        for(size_t i = 0; i < len; i++){
            idx_cur[i] = i;
        }
        idx_cur = idx_cur + len;
    }
}

cl_mem clCreateBufferSafe(cl_context context, cl_mem_flags flags, size_t size, void *host_ptr){
    cl_int err;
    cl_mem buf = clCreateBuffer(context, flags, size, host_ptr, &err);
    CHECK_CL_ERROR(err, "clCreateBuffer");
    return buf;
}


enum sg_backend backend = INVALID;

char platform_string[STRING_SIZE];
char device_string[STRING_SIZE];
char kernel_file[STRING_SIZE];
char kernel_name[STRING_SIZE];

size_t source_len;
size_t target_len;
size_t index_len;
size_t block_len;
size_t seed;

int json_flag;

int main(int argc, char **argv)
{
    cl_context context;
    cl_command_queue queue;
    cl_device_id device;
    cl_mem_flags flags; 
    cl_kernel sgp;

    sgDataBuf  source;
    sgDataBuf  target;
    sgIndexBuf si; //source_index
    sgIndexBuf ti; //target_index

    size_t cpu_cache_size = 30720 * 1000; 
    size_t cpu_flush_size = cpu_cache_size * 8;
    cl_ulong device_cache_size = 0;
    size_t device_flush_size = 0;
    size_t worksets = 1;
    
    char *kernel_string;

    /* Parse command line arguments */
    parse_args(argc, argv);


    /* Create a context and corresponding queue */
    if (backend == OPENCL) {
        create_context_on(platform_string, device_string, 0, 
                      &context, &queue, &device, 1);
    }

    source.len = source_len;
    target.len = target_len;
    si.len     = index_len;
    ti.len     = index_len;

    /* Determine how many worksets we will need to flush the cache */
    if (backend == OPENMP) {
        worksets = cpu_flush_size / 
            ((source.len + target.len) * sizeof(SGTYPE) 
            + (si.len + ti.len) * sizeof(cl_ulong)) + 1;
    }
    else if (backend == OPENCL) {
        clGetDeviceInfo(device, CL_DEVICE_GLOBAL_MEM_CACHE_SIZE, 
                sizeof(device_cache_size), &device_cache_size, NULL); 
        device_flush_size = device_cache_size * 8;
        worksets = device_flush_size / 
            ((source.len + target.len) * sizeof(SGTYPE) 
            + (si.len + ti.len) * sizeof(cl_ulong)) + 1;
    }

    /* These are the total size of the data allocated for each buffer */
    source.size = worksets * block_len * source.len * sizeof(SGTYPE);
    target.size = worksets * block_len * target.len * sizeof(SGTYPE);
    si.size     = worksets * si.len * sizeof(cl_ulong);
    ti.size     = worksets * ti.len * sizeof(cl_ulong);

    /* This is the number of SGTYPEs in a workset */
    source.block_len = block_len * source.len;
    target.block_len = block_len * target.len;

    /* Create the kernel */
    kernel_string = read_file(kernel_file);
    sgp = kernel_from_string(context, kernel_string, kernel_name, NULL);
    free(kernel_string);

    /* Create buffers on host */
    source.host_ptr = (SGTYPE*) alloc(source.size); 
    target.host_ptr = (SGTYPE*) alloc(target.size); 
    si.host_ptr = (cl_ulong*) alloc(si.size); 
    ti.host_ptr = (cl_ulong*) alloc(ti.size); 

    /* Populate buffers on host */
    random_data(source.host_ptr, source.len * worksets);
    linear_indices(si.host_ptr, si.len, worksets);
    linear_indices(ti.host_ptr, ti.len, worksets);

    /* Create buffers on device and transfer data from host */
    flags = CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR | CL_MEM_HOST_WRITE_ONLY;
    source.dev_ptr = clCreateBufferSafe(context, flags, source.size, source.host_ptr);
    si.dev_ptr = clCreateBufferSafe(context, flags, si.size, si.host_ptr);
    ti.dev_ptr = clCreateBufferSafe(context, flags, ti.size, ti.host_ptr);

    flags = CL_MEM_READ_WRITE | CL_MEM_HOST_READ_ONLY;
    target.dev_ptr = clCreateBufferSafe(context, flags, target.size, NULL); 

    /* Run Kernel */
    size_t R = 100;
    
    SET_10_KERNEL_ARGS(sgp, target.dev_ptr, ti.dev_ptr, source.dev_ptr, 
            si.dev_ptr, target.block_len, source.block_len, 
            index_len, worksets, R, block_len);

    cl_uint work_dim = 1;
    size_t global_work_size = 1;
    size_t local_work_size = 1;
    cl_event e;
    CALL_CL_GUARDED(clEnqueueNDRangeKernel, (queue, sgp, work_dim, NULL, 
               &global_work_size, &local_work_size, 
              0, NULL, &e)); 
    clWaitForEvents(1, &e);


    /* Validate results */
    clEnqueueReadBuffer(queue, target.dev_ptr, 1, 0, target.size, 
            target.host_ptr, 0, NULL, &e);
    clWaitForEvents(1, &e);

    SGTYPE *target_backup_host = (SGTYPE*) alloc(target.size); 
    memcpy(target_backup_host, target.host_ptr, target.size);

    sg_omp(target.host_ptr, ti.host_ptr, source.host_ptr, si.host_ptr, 
            target.block_len, source.block_len, index_len, worksets, R, 
            block_len);

    for (size_t i = 0; i < target.len * worksets; i++){
        if (target.host_ptr[i] != target_backup_host[i]){
            printf(":(\n");
        }
    }

    /* Print output */
    
    for(int i = 0; i < source.len * worksets; i++){
        //printf("%.0lf ", source.host_ptr[i]);
    }
    //printf("\n");
    for(int i = 0; i < target.len * worksets; i++){
        //printf("%.0lf ", target.host_ptr[i]);
    }
    //printf("\n");
    printf("done\n");
}
