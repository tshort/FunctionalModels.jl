
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
    /* printf("ipar = %d", ipar[0]); */
    // Find the Julia function that does the work
    jl_value_t *f = jl_get_global(jl_base_module,jl_symbol("__daskr_res_callback"));
    jl_array_t *junk = jl_get_global(jl_base_module,jl_symbol("__daskr_t"));
    // Allocate Julia arrays pointing to those called from Fortran:
    // ipar[0] should have the length of each array.
    // We pull the type from a global variable that's Array{Float64, 1}. That
    // type isn't exported, so it can't be entered directly.
    jl_array_t *_t = (jl_array_t *)jl_ptr_to_array_1d(junk->type, t, 1, 0);
    jl_array_t *_y = (jl_array_t *)jl_ptr_to_array_1d(junk->type, y, ipar[0], 0);
    jl_array_t *_yp = (jl_array_t *)jl_ptr_to_array_1d(junk->type, yp, ipar[0], 0);
    jl_array_t *_res = (jl_array_t *)jl_ptr_to_array_1d(junk->type, res, ipar[0], 0);
    
    int count = 3;
    jl_value_t *args[count];
    args[0] = _t;
    args[1] = _y;
    args[2] = _yp;

    JL_GC_PUSHARGS(args,count);  
    jl_array_t *fres = jl_apply((jl_function_t*)f, args, count);
    JL_GC_POP();
    for (int i = 0; i < ipar[0]; i++) {
        res[i] = ((double *)(fres->data))[i];
    }
}

void event_callback(int32_t *Neq, double *t, double *y, double *yp, int32_t *Nrt, double *res, double *rpar, int32_t *ipar) {

    // Now, call the Julia function that does the work
    jl_value_t *f = jl_get_global(jl_base_module,jl_symbol("__daskr_event_callback"));
    jl_array_t *junk = jl_get_global(jl_base_module,jl_symbol("__daskr_t"));
    // Allocate Julia arrays pointing to those called from Fortran:
    // ipar[0] should have the length of each array.
    jl_array_t *_t = (jl_array_t *)jl_ptr_to_array_1d(junk->type, t, 1, 0);
    jl_array_t *_y = (jl_array_t *)jl_ptr_to_array_1d(junk->type, y, ipar[0], 0);
    jl_array_t *_yp = (jl_array_t *)jl_ptr_to_array_1d(junk->type, yp, ipar[0], 0);
    jl_array_t *_res = (jl_array_t *)jl_ptr_to_array_1d(junk->type, res, ipar[1], 0);
    // Here's what I tried before Jameson let me know that jl_array_type (and similar)
    // are not exported.
    /* jl_array_t *_t = (jl_array_t *)jl_ptr_to_array_1d((jl_type_t *)jl_array_type, t, 1, 0); */
    
    int count = 3;
    jl_value_t *args[count];
    args[0] = _t;
    args[1] = _y;
    args[2] = _yp;
    
    JL_GC_PUSHARGS(args,count);   // I don't know what this does.
    jl_array_t *fres = jl_apply((jl_function_t*)f, args, count);
    JL_GC_POP();
    for (int i = 0; i < ipar[1]; i++) {
        res[i] = ((double *)(fres->data))[i];
    }
}
