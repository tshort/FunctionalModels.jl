try
    run(`gfortran -O2 -shared -o daskr.so DASKR/ddaskr.f DASKR/dlinpk.f DASKR/daux.f`) 
end
