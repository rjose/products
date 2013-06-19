#ifndef NUMMETHS_H
#define NUMMETHS_H

int interpol(const double *x, const double *fx, int n,
                                                  double *z, double *pz, int m);

void lsqe(const double *x, const double *y, int n, double *b1, double *b0);

#endif
