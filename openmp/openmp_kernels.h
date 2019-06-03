#ifndef OMP_KERNELS_H
#define OMP_KERNELS_H

#include <omp.h>
#include <stdlib.h>
#include "../include/sgtype.h"

void sg_omp(
            sgData_t* restrict target, 
            long*     restrict ti,
            sgData_t* restrict source,
            long*     restrict si,
            size_t n);
void scatter_omp(
            sgData_t* restrict target, 
            long*     restrict ti,
            sgData_t* restrict source,
            long*     restrict si,
            size_t n);
void gather_omp(
            sgData_t* restrict target, 
            long*     restrict ti,
            sgData_t* restrict source,
            long*     restrict si,
            size_t n);
void sg_accum_omp(
            sgData_t* restrict target, 
            long*     restrict ti,
            sgData_t* restrict source,
            long*     restrict si,
            size_t n);
void scatter_accum_omp(
            sgData_t* restrict target, 
            long*     restrict ti,
            sgData_t* restrict source,
            long*     restrict si,
            size_t n);
void gather_accum_omp(
            sgData_t* restrict target, 
            long*     restrict ti,
            sgData_t* restrict source,
            long*     restrict si,
            size_t n);

void gather_stride_noidx(
        sgData_t* restrict target,
        sgData_t* restrict source,
        sgIdx_t*  restrict pat,
        size_t    pat_len,
        size_t    delta,
        size_t    n);
void gather_stride_noidx_os(
        sgData_t* restrict target,
        sgData_t* restrict source,
        sgIdx_t*  restrict pat,
        size_t    pat_len,
        size_t    delta,
        size_t    n, 
        size_t    target_wrap);
void gather_stride_noidx8(
        sgData_t* restrict target,
        sgData_t* restrict source,
        sgIdx_t*  restrict pat,
        size_t    delta,
        size_t    n);
void gather_stride_noidx16(
        sgData_t* restrict target,
        sgData_t* restrict source,
        sgIdx_t*  restrict pat,
        size_t    stride,
        size_t    delta,
        size_t    n);

#endif
