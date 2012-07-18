
// Tom Short, tshort@epri.com


// Copyright (c) 2012, Electric Power Research Institute 
// BSD license - see the LICENSE file
 

#include <julia.h>
#include <stdio.h>

#define MAX(a,b) ((a) > (b) ? a : b)

//
// This attempts to define a callback function for the residual function for the DAE
// solver. The Julia function is a global function as are some of the arguments.
//
void res_callback(double *t, double *y, double *yp, double *cj, double *res, int32_t *ires, double *rpar, int32_t *ipar) {

    // Now, call the Julia function that does the work
    jl_value_t *f = jl_get_global(jl_base_module,jl_symbol("__daskr_res_callback"));
    jl_array_t *_t = jl_get_global(jl_base_module,jl_symbol("__daskr_t"));
    jl_array_t *_y = jl_get_global(jl_base_module,jl_symbol("__daskr_y"));
    jl_array_t *_yp = jl_get_global(jl_base_module,jl_symbol("__daskr_yp"));
    jl_array_t *_res = jl_get_global(jl_base_module,jl_symbol("__daskr_res"));
    JL_GC_PUSH(&f, &_t, &_y, &_yp, &_res);
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
    jl_value_t *args[count];
    JL_GC_PUSHARGS(args,count);  
    args[0] = _t;
    args[1] = _y;
    args[2] = _yp;
    
    jl_array_t *fres = jl_apply((jl_function_t*)f, args, count);
    for (int i = 0; i < ipar[0]; i++) {
        res[i] = ((double *)(fres->data))[i];
    }
    JL_GC_POP();
    JL_GC_POP();
}

void event_callback(int32_t *Neq, double *t, double *y, double *yp, int32_t *Nrt, double *res, double *rpar, int32_t *ipar) {

    // Now, call the Julia function that does the work
    jl_value_t *f = jl_get_global(jl_base_module,jl_symbol("__daskr_event_callback"));
    jl_array_t *_t = jl_get_global(jl_base_module,jl_symbol("__daskr_t"));
    jl_array_t *_y = jl_get_global(jl_base_module,jl_symbol("__daskr_y"));
    jl_array_t *_yp = jl_get_global(jl_base_module,jl_symbol("__daskr_yp"));
    jl_array_t *_res = jl_get_global(jl_base_module,jl_symbol("__daskr_res"));
    JL_GC_PUSH(&f, &_t, &_y, &_yp, &_res);
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
    _res->length = ipar[1];
    _res->nrows = ipar[1];
    
    int count = 3;
    jl_value_t *args[count];
    JL_GC_PUSHARGS(args,count);   // I don't know what this does.
    args[0] = _t;
    args[1] = _y;
    args[2] = _yp;
    
    jl_array_t *fres = jl_apply((jl_function_t*)f, args, count);
    for (int i = 0; i < ipar[1]; i++) {
        res[i] = ((double *)(fres->data))[i];
    }
    JL_GC_POP();
    JL_GC_POP();
}
