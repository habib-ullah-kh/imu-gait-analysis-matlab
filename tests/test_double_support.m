% Analytical cases only; NOT substitute participant measurements.
addpath(fullfile(fileparts(mfilename('fullpath')),'..','matlab'));
[intervals,total,avg]=calculate_double_support([0,2],[1.2,3],[0.8,2.5],[1.5,2.8]);
assert(size(intervals,1)==2);
assert(abs(total-0.7)<1e-12);
assert(abs(avg-0.35)<1e-12);
assert(isempty(calculate_double_support(0,1,2,3)));
assert(abs(calculate_symmetry_index(1,1)) < 1e-12);
assert(abs(calculate_symmetry_index(1,2)-66.6666666667)<1e-7);
disp('Unit test assertions passed');
