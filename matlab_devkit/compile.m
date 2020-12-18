setenv('CXXFLAGS', [getenv('CXXFLAGS') ' --std=c++11'])
setenv('COMPFLAGS', ['/openmp ' getenv('COMPFLAGS')])

mex utils/MinCostMatching.cpp -o utils/MinCostMatching
mex utils/clearMOTMex.cpp -o utils/clearMOTMex
mex utils/costBlockMex.cpp -o utils/costBlockMex
mex utils/ismember_mex.cpp -o utils/ismember_mex
