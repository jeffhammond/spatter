#include <stdio.h>
#include "cuda_kernels.h"
#include "../include/parse-args.h"

#define typedef uint unsigned int

template<int v>
__global__ void scatter_t(double* target, 
                        double* source, 
                        long* ti, 
                        long* si) 
{
    extern __shared__ char space[];

    int gid = v*(blockIdx.x * blockDim.x + threadIdx.x);

    double buf[v];
    long idx[v]; 

    for(int i = 0; i < v; i++){
        buf[i] = source[gid+i];    
    }

    for(int i = 0; i < v; i++){
       idx[i] = ti[gid+i]; 
    }

    for(int i = 0; i < v; i++){
        target[idx[i]] = buf[i];
    }
}


template<int v>
__global__ void gather_t(double* target, 
                        double* source, 
                        long* ti, 
                        long* si)
{
    extern __shared__ char space[];

    int gid = v*(blockIdx.x * blockDim.x + threadIdx.x);
    double buf[v];

    for(int i = 0; i < v; i++){
        buf[i] = source[si[gid+i]];
    }

    for(int i = 0; i < v; i++){
        target[gid+i] = buf[i];
    }

}

//__global__ void gather_new(double *target, 

template<int v>
__global__ void sg_t(double* target, 
                    double* source, 
                    long* ti, 
                    long* si)
{
    extern __shared__ char space[];

    int gid = v*(blockIdx.x * blockDim.x + threadIdx.x);
    long sidx[v];
    long tidx[v];

    for(int i = 0; i < v; i++){
        sidx[i] = si[gid+i];
    }
    for(int i = 0; i < v; i++){
        tidx[i] = ti[gid+i];
    }
    for(int i = 0; i < v; i++){
        target[tidx[i]] = source[sidx[i]];
    }

}
#define INSTANTIATE(V)\
template __global__ void scatter_t<V>(double* target, double* source, long* ti, long* si);\
template __global__ void gather_t<V>(double* target, double* source, long* ti, long* si); \
template __global__ void sg_t<V>(double* target, double* source, long* ti, long* si);
INSTANTIATE(1);
INSTANTIATE(2);
INSTANTIATE(4);
INSTANTIATE(5);
INSTANTIATE(8);
INSTANTIATE(16);
INSTANTIATE(32);
INSTANTIATE(64);

extern "C" int translate_args(unsigned int dim, unsigned int* grid, unsigned int* block, dim3 *grid_dim, dim3 *block_dim){
    if (!grid || !block || dim == 0 || dim > 3) {
        return 1;
    }
    if (dim == 1) {
        *grid_dim  = dim3(grid[0]);
        *block_dim = dim3(block[0]);
    }else if (dim == 2) {
        *grid_dim  = dim3(grid[0],  grid[1]);
        *block_dim = dim3(block[0], block[1]);
    }else if (dim == 3) {
        *grid_dim  = dim3(grid[0],  grid[1],  grid[2]);
        *block_dim = dim3(block[0], block[1], block[2]);
    } 
    return 0;

}

extern "C" float cuda_sg_wrapper(enum sg_kernel kernel, 
                                size_t vector_len, 
                                uint dim, uint* grid, uint* block, 
                                double* target, double *source, 
                                long* ti, long* si, 
                                unsigned int shmem){
    dim3 grid_dim, block_dim;
    cudaEvent_t start, stop;

    if(translate_args(dim, grid, block, &grid_dim, &block_dim)) return 0;

    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaDeviceSynchronize();
    cudaEventRecord(start);
    if(kernel == SCATTER)
    {
        if (vector_len == 1)
            scatter_t<1><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 2)
            scatter_t<2><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 4)
            scatter_t<4><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 5)
            scatter_t<5><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 8)
            scatter_t<8><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 16)
            scatter_t<16><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 32)
            scatter_t<32><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 64)
            scatter_t<64><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else 
        {
            printf("ERROR: UNSUPPORTED VECTOR LENGTH\n");
            exit(1);
        }
    }
    else if(kernel == GATHER)
    {
        if (vector_len == 1)
            gather_t<1><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 2)
            gather_t<2><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 4)
            gather_t<4><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 5)
            gather_t<5><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 8)
            gather_t<8><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 16)
            gather_t<16><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 32)
            gather_t<32><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 64)
            gather_t<64><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else 
        {
            printf("ERROR: UNSUPPORTED VECTOR LENGTH\n");
            exit(1);
        }
    }
    else if(kernel == SG)
    {
        if (vector_len == 1)
            sg_t<1><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 2)
            sg_t<2><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 4)
            sg_t<4><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 5)
            sg_t<5><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 8)
            sg_t<8><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 16)
            sg_t<16><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 32)
            sg_t<32><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 64)
            sg_t<64><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else 
        {
            printf("ERROR: UNSUPPORTED VECTOR LENGTH\n");
            exit(1);
        }
    }
    else
    {
        printf("ERROR UNRECOGNIZED KERNEL\n");
        exit(1);
    }
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float time_ms = 0;
    cudaEventElapsedTime(&time_ms, start, stop);
    return time_ms;

}

//todo -- add WRAP 
template<int V>
__global__ void gather_new(double* source, 
                        sgIdx_t* idx, size_t delta)
{
    int gid = (blockIdx.x * blockDim.x + threadIdx.x);
    double *sl = source + gid*delta;

    double buf[V];

    for (int i = 0; i < V; i++) {
        buf[i] = sl[idx[i]];
        //source[i+gid*delta] = 8;
        //sl[i] = sl[idx[i]];
    }

    for (int i = 0; i < V; i++) {
        if (buf[i] == 199402) {
            printf("oop\n");
        }
    }

        //printf("idx[1]: %d\n", idx[1]);
        /*
        for (int i = 0; i < V; i++) {
            printf("idx %d is %zu", i, idx[i]);
        }
        printf("\n");
        */

}

#define INSTANTIATE2(V)\
template __global__ void gather_new<V>(double* source, sgIdx_t* idx, size_t delta);

//INSTANTIATE2(1);
//INSTANTIATE2(2);
//INSTANTIATE2(4);
//INSTANTIATE2(5);
INSTANTIATE2(8);
//INSTANTIATE2(16);
//INSTANTIATE2(32);
//INSTANTIATE2(64);

extern "C" float cuda_new_wrapper(uint dim, uint* grid, uint* block,
        enum sg_kernel kernel,
        double *source, 
        sgIdx_t* pat_dev, 
        sgIdx_t* pat, 
        size_t pat_len, 
        size_t delta, 
        size_t n, 
        size_t wrap)
{
    dim3 grid_dim, block_dim;
    cudaEvent_t start, stop;

    if(translate_args(dim, grid, block, &grid_dim, &block_dim)) return 0;
    cudaMemcpy(pat_dev, pat, sizeof(sgIdx_t)*pat_len, cudaMemcpyHostToDevice); 

    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaDeviceSynchronize();
    cudaEventRecord(start);
    // KERNEL 
    if (pat_len == 8) {
        gather_new<8><<<grid_dim,block_dim>>>(source, pat_dev, (long)delta);
    } else {
        printf("ERROR NOT SUPPORTED\n");
    }
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float time_ms = 0;
    cudaEventElapsedTime(&time_ms, start, stop);
    return time_ms;

}
/*
    dim3 grid_dim, block_dim;
    cudaEvent_t start, stop;

    if(translate_args(dim, grid, block, &grid_dim, &block_dim)) return 0;

    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaDeviceSynchronize();
    cudaEventRecord(start);
    if(kernel == SCATTER)
    {
        if (vector_len == 1)
            scatter_t<1><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 2)
            scatter_t<2><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 4)
            scatter_t<4><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 5)
            scatter_t<5><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 8)
            scatter_t<8><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 16)
            scatter_t<16><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 32)
            scatter_t<32><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 64)
            scatter_t<64><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else 
        {
            printf("ERROR: UNSUPPORTED VECTOR LENGTH\n");
            exit(1);
        }
    }
    else if(kernel == GATHER)
    {
        if (vector_len == 1)
            gather_t<1><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 2)
            gather_t<2><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 4)
            gather_t<4><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 5)
            gather_t<5><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 8)
            gather_t<8><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 16)
            gather_t<16><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 32)
            gather_t<32><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 64)
            gather_t<64><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else 
        {
            printf("ERROR: UNSUPPORTED VECTOR LENGTH\n");
            exit(1);
        }
    }
    else if(kernel == SG)
    {
        if (vector_len == 1)
            sg_t<1><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 2)
            sg_t<2><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 4)
            sg_t<4><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 5)
            sg_t<5><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 8)
            sg_t<8><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 16)
            sg_t<16><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 32)
            sg_t<32><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else if (vector_len == 64)
            sg_t<64><<<grid_dim,block_dim,shmem>>>(target, source, ti, si);
        else 
        {
            printf("ERROR: UNSUPPORTED VECTOR LENGTH\n");
            exit(1);
        }
    }
    else
    {
        printf("ERROR UNRECOGNIZED KERNEL\n");
        exit(1);
    }
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float time_ms = 0;
    cudaEventElapsedTime(&time_ms, start, stop);
    return time_ms;

}*/
