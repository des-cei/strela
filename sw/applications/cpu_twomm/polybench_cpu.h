#ifndef _POLYBENCH_CPU_H
#define _POLYBENCH_CPU_H

#include "polybench.h"

void gemm_cpu(
    DATA_TYPE *alpha,
    DATA_TYPE *beta,
    DATA_TYPE *A,
    DATA_TYPE *B,
    DATA_TYPE *C);

void gemver_cpu(
    DATA_TYPE *alpha,
    DATA_TYPE *beta,
    DATA_TYPE *A,
    DATA_TYPE *u1,
    DATA_TYPE *v1,
    DATA_TYPE *u2,
    DATA_TYPE *v2,
    DATA_TYPE *w,
    DATA_TYPE *x,
    DATA_TYPE *y,
    DATA_TYPE *z);

void gesummv_cpu(
    DATA_TYPE *alpha,
    DATA_TYPE *beta,
    DATA_TYPE *A,
    DATA_TYPE *B, 
    DATA_TYPE *tmp,
    DATA_TYPE *x,
    DATA_TYPE *y);

void symm_cpu(
    DATA_TYPE *alpha, 
    DATA_TYPE *beta,
    DATA_TYPE *A,
    DATA_TYPE *B,
    DATA_TYPE *C);

void twomm_cpu(
    DATA_TYPE *alpha,
    DATA_TYPE *beta,
    DATA_TYPE *tmp,
    DATA_TYPE *A,
    DATA_TYPE *B,
    DATA_TYPE *C,
    DATA_TYPE *D);

void threemm_cpu(
    DATA_TYPE *A,
    DATA_TYPE *B,
    DATA_TYPE *C,
    DATA_TYPE *D,
    DATA_TYPE *E,
    DATA_TYPE *F,
    DATA_TYPE *G);

void atax_cpu(
    DATA_TYPE *A,
    DATA_TYPE *x,
    DATA_TYPE *y,
    DATA_TYPE *tmp);

void bicg_cpu(
    DATA_TYPE *A,
    DATA_TYPE *s,
    DATA_TYPE *q,
    DATA_TYPE *p,
    DATA_TYPE *r);

void doitgen_cpu(
    DATA_TYPE *A,
    DATA_TYPE *C4,
    DATA_TYPE *sum);

void mvt_cpu(
    DATA_TYPE *x1,
    DATA_TYPE *x2,
    DATA_TYPE *y_1,
    DATA_TYPE *y_2,
    DATA_TYPE *A);

#endif
