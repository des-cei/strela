#include "polybench_cpu.h"

void gemm_cpu(
    DATA_TYPE *alpha, 
    DATA_TYPE *beta,
    DATA_TYPE *A,
    DATA_TYPE *B,
    DATA_TYPE *C)
{
    int i, j, k;

    for (i = 0; i < GEMM_NI; i++) {
        for (j = 0; j < GEMM_NJ; j++)
            C[i*GEMM_NJ+j] *= *beta;
        for (k = 0; k < GEMM_NK; k++) {
            for (j = 0; j < GEMM_NJ; j++)
                C[i*GEMM_NJ+j] += *alpha * A[i*GEMM_NK+k] * B[k*GEMM_NJ+j];
        }
    }
}

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
    DATA_TYPE *z)
{
    int i, j;

    for (i = 0; i < GEMVER_N; i++)
        for (j = 0; j < GEMVER_N; j++)
            A[i*GEMVER_N+j] = A[i*GEMVER_N+j] + u1[i] * v1[j] + u2[i] * v2[j];

    for (i = 0; i < GEMVER_N; i++)
        for (j = 0; j < GEMVER_N; j++)
            x[i] = x[i] + *beta * A[j*GEMVER_N+i] * y[j];

    for (i = 0; i < GEMVER_N; i++)
        x[i] = x[i] + z[i];

    for (i = 0; i < GEMVER_N; i++)
        for (j = 0; j < GEMVER_N; j++)
            w[i] = w[i] +  *alpha * A[i*GEMVER_N+j] * x[j];
}

void gesummv_cpu(
    DATA_TYPE *alpha, 
    DATA_TYPE *beta,
    DATA_TYPE *A,
    DATA_TYPE *B, 
    DATA_TYPE *tmp,
    DATA_TYPE *x,
    DATA_TYPE *y)
{
  int i, j;

    for (i = 0; i < GESUMMV_N; i++) {
        tmp[i] = 0;
        y[i] = 0;
        for (j = 0; j < GESUMMV_N; j++) {
            tmp[i] = A[i*GESUMMV_N+j] * x[j] + tmp[i];
            y[i] = B[i*GESUMMV_N+j] * x[j] + y[i];
        }
        y[i] = *alpha * tmp[i] + *beta * y[i];
    }   
}

void symm_cpu(
    DATA_TYPE *alpha, 
    DATA_TYPE *beta,
    DATA_TYPE *A,
    DATA_TYPE *B,
    DATA_TYPE *C)
{
    int i, j, k;
    DATA_TYPE temp2;

    for (i = 0; i < SYMM_M; i++)
        for (j = 0; j < SYMM_N; j++) {
            temp2 = 0;
            for (k = 0; k < i; k++) {
                C[k*SYMM_N+j] += *alpha*B[i*SYMM_N+j] * A[i*SYMM_M+k];
                temp2 += B[k*SYMM_N+j] * A[i*SYMM_M+k];
            }
            C[i*SYMM_N+j] = *beta * C[i*SYMM_N+j] + *alpha*B[i*SYMM_N+j] * A[i*SYMM_M+i] + *alpha * temp2;
        }
}

void twomm_cpu(
    DATA_TYPE *alpha, 
    DATA_TYPE *beta,
    DATA_TYPE *tmp,
    DATA_TYPE *A,
    DATA_TYPE *B,
    DATA_TYPE *C,
    DATA_TYPE *D)
{
    int i, j, k;

    /* D := alpha*A*B*C + beta*D */
    for (i = 0; i < TWOMM_NI; i++)
        for (j = 0; j < TWOMM_NJ; j++) {
            tmp[i*TWOMM_NJ+j] = 0;
        for (k = 0; k < TWOMM_NK; ++k)
            tmp[i*TWOMM_NJ+j] += *alpha * A[i*TWOMM_NK+k] * B[k*TWOMM_NJ+j];
        }
    for (i = 0; i < TWOMM_NI; i++)
        for (j = 0; j < TWOMM_NL; j++) {
            D[i*TWOMM_NL+j] *= *beta;
        for (k = 0; k < TWOMM_NJ; ++k)
            D[i*TWOMM_NL+j] += tmp[i*TWOMM_NJ+k] * C[k*TWOMM_NL+j];
    }
}

void threemm_cpu(
    DATA_TYPE *A,
    DATA_TYPE *B,
    DATA_TYPE *C,
    DATA_TYPE *D,
    DATA_TYPE *E,
    DATA_TYPE *F,
    DATA_TYPE *G)
{
    int i, j, k;

    /* E := A*B */
    for (i = 0; i < THREEMM_NI; i++)
        for (j = 0; j < THREEMM_NJ; j++) {
            E[i*THREEMM_NJ+j] = 0;
            for (k = 0; k < THREEMM_NK; ++k)
                E[i*THREEMM_NJ+j] += A[i*THREEMM_NK+k] * B[k*THREEMM_NJ+j];
        }
    /* F := C*D */
    for (i = 0; i < THREEMM_NJ; i++)
        for (j = 0; j < THREEMM_NL; j++) {
            F[i*THREEMM_NL+j] = 0;
            for (k = 0; k < THREEMM_NM; ++k)
                F[i*THREEMM_NL+j] += C[i*THREEMM_NM+k] * D[k*THREEMM_NL+j];
        }
    /* G := E*F */
    for (i = 0; i < THREEMM_NI; i++)
        for (j = 0; j < THREEMM_NL; j++) {
            G[i*THREEMM_NL+j] = 0;
            for (k = 0; k < THREEMM_NJ; ++k)
                G[i*THREEMM_NL+j] += E[i*THREEMM_NJ+k] * F[k*THREEMM_NL+j];
        }
}

void atax_cpu(
    DATA_TYPE *A,
    DATA_TYPE *x,
    DATA_TYPE *y,
    DATA_TYPE *tmp)
{
    int i, j;

    for (i = 0; i < ATAX_N; i++)
        y[i] = 0;
    for (i = 0; i < ATAX_M; i++) {
        tmp[i] = 0;
        for (j = 0; j < ATAX_N; j++)
            tmp[i] = tmp[i] + A[i*ATAX_N+j] * x[j];
        for (j = 0; j < ATAX_N; j++)
            y[j] = y[j] + A[i*ATAX_N+j] * tmp[i];
    }
}

void bicg_cpu(
    DATA_TYPE *A,
    DATA_TYPE *s,
    DATA_TYPE *q,
    DATA_TYPE *p,
    DATA_TYPE *r)
{
    int i, j;

    for (i = 0; i < BICG_M; i++)
        s[i] = 0;
    for (i = 0; i < BICG_N; i++) {
        q[i] = 0;
        for (j = 0; j < BICG_M; j++) {
            s[j] = s[j] + r[i] * A[i*BICG_M+j];
            q[i] = q[i] + A[i*BICG_M+j] * p[j];
        }
    }
}

void doitgen_cpu(
    DATA_TYPE *A,
    DATA_TYPE *C4,
    DATA_TYPE *sum)
{
    int r, q, p, s;

    for (r = 0; r < DOITGEN_NR; r++)
        for (q = 0; q < DOITGEN_NQ; q++)  {
            for (p = 0; p < DOITGEN_NP; p++)  {
                sum[p] = 0;
                for (s = 0; s < DOITGEN_NP; s++)
                    sum[p] += A[(r*DOITGEN_NQ+q)*DOITGEN_NP+s] * C4[s*DOITGEN_NP+p];
            }
            for (p = 0; p < DOITGEN_NP; p++)
                A[(r*DOITGEN_NQ+q)*DOITGEN_NP+p] = sum[p];
        }
}

void mvt_cpu(
    DATA_TYPE *x1,
    DATA_TYPE *x2,
    DATA_TYPE *y_1,
    DATA_TYPE *y_2,
    DATA_TYPE *A)
{
    int i, j;

    for (i = 0; i < MVT_N; i++)
        for (j = 0; j < MVT_N; j++)
            x1[i] = x1[i] + A[i*MVT_N+j] * y_1[j];
    for (i = 0; i < MVT_N; i++)
        for (j = 0; j < MVT_N; j++)
            x2[i] = x2[i] + A[j*MVT_N+i] * y_2[j];
}