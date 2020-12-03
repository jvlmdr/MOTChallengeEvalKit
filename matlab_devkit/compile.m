setenv('CXXFLAGS', [getenv('CXXFLAGS') ' --std=c++11'])
setenv('COMPFLAGS', ['/openmp ' getenv('COMPFLAGS')])

mex utils/MinCostMatching.cpp -o utils/MinCostMatching
mex utils/clearMOTMex.cpp -o utils/clearMOTMex
mex utils/costBlockMex.cpp -o utils/costBlockMex
