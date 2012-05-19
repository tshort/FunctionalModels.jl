
// Tom Short, tshort@epri.com


// Copyright (c) 2012, Electric Power Research Institute 
// BSD license - see the LICENSE file
 

#include "../../src/julia.h"
#include <stdio.h>

//
// This attempts to define a callback function for the residual function for the DAE
// solver. The Julia function is a global function as are some of the arguments.
//
void res_callback(double *t, double *y, double *yp, double *res, int32_t *ires, double *rpar, int32_t *ipar) {

    // Now, call the Julia function that does the work
    jl_value_t *f = jl_get_global(jl_base_module,jl_symbol("__dassl_res_callback"));
    jl_array_t *_t = jl_get_global(jl_base_module,jl_symbol("__dassl_t"));
    jl_array_t *_y = jl_get_global(jl_base_module,jl_symbol("__dassl_y"));
    jl_array_t *_yp = jl_get_global(jl_base_module,jl_symbol("__dassl_yp"));
    jl_array_t *_res = jl_get_global(jl_base_module,jl_symbol("__dassl_res"));
    _t->data = (void *)t;
    _t->length = 1;
    _t->nrows = 1;
    _y->data = (void *)y;
    _y->length = ipar[0];
    _y->nrows = ipar[0];
    _yp->data = (void *)yp;
    _yp->length = ipar[0];
    _yp->nrows = ipar[0];
    _res->data = (void *)res;
    _res->length = ipar[0];
    _res->nrows = ipar[0];
    int count = 3;
    jl_value_t *args[3];
    args[0] = _t;
    args[1] = _y;
    args[2] = _yp;
    
    JL_GC_PUSHARGS(args,count);   // I don't know what this does.
    jl_array_t *fres = jl_apply((jl_function_t*)f, args, count);
    JL_GC_POP();
    for (int i = 0; i < ipar[0]; i++) {
        res[i] = ((double *)(fres->data))[i];
    }
}
