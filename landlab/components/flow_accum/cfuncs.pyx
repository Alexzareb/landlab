import numpy as np
cimport numpy as np
cimport cython


DTYPE_INT = np.int
ctypedef np.int_t DTYPE_INT_t

DTYPE_FLOAT = np.double
ctypedef np.double_t DTYPE_FLOAT_t


@cython.boundscheck(False)
cpdef _add_to_stack(DTYPE_INT_t l, DTYPE_INT_t j,
                    np.ndarray[DTYPE_INT_t, ndim=1] s,
                    np.ndarray[DTYPE_INT_t, ndim=1] delta,
                    np.ndarray[DTYPE_INT_t, ndim=1] donors):

    """
    Adds node l to the stack and increments the current index (j).
    """
    cdef int m, n, delta_l, delta_lplus1

    s[j] = l
    j += 1
    delta_l = delta[l]
    delta_lplus1 = delta[l+1]

    for n in range(delta_l, delta_lplus1):
        m = donors[n]
        if m != l:
            j = _add_to_stack(m, j, s, delta, donors)

    return j


@cython.boundscheck(False)
cpdef _accumulate(DTYPE_INT_t np,
                  np.ndarray[DTYPE_INT_t, ndim=1] s,
                  np.ndarray[DTYPE_INT_t, ndim=1] r,
                  np.ndarray[DTYPE_FLOAT_t, ndim=1] drainage_area,
                  np.ndarray[DTYPE_FLOAT_t, ndim=1] discharge):
    """
    Accumulates drainage area and discharge, permitting transmission losses.
    """
    cdef int donor, recvr, i
    cdef float accum

    # Iterate backward through the list, which means we work from upstream to
    # downstream.
    for i in range(np-1, -1, -1):
        donor = s[i]
        recvr = r[donor]
        if donor != recvr:
            drainage_area[recvr] += drainage_area[donor]
            accum = discharge[recvr] + discharge[donor]
            if accum < 0.:
                accum = 0.
            discharge[recvr] = accum
