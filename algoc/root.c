#include <math.h>

#include "nummeths.h"

int root(double (*f)(double x), double (*g)(double x), 
                                   double *x, int *n, double delta)
{
        int satisfied, i;

        i = 0;
        satisfied = 0;

        while (!satisfied && i + 1 < *n) {
                x[i + 1] = x[i] - (f(x[i]) / g(x[i]));

                if (fabs(x[i + 1] - x[i]) < delta)
                        satisfied = 1;

                i++;
        }

        if (i == 0)
                *n = 1;
        else
                *n = i + 1;

        return (satisfied == 1);
}
