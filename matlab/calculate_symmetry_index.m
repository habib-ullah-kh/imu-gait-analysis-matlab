function si = calculate_symmetry_index(leftValues,rightValues)
% Percent Robinson-style index described in thesis: 100*abs(L-R)/mean(abs(L),abs(R)).
% Values are paired measures; zero/zero pairs return NaN (undefined).
assert(isequal(size(leftValues),size(rightValues)),'Paired arrays must match dimensions');
den=(abs(leftValues)+abs(rightValues))/2;
si=100*abs(leftValues-rightValues)./den;
si(den==0)=NaN;
end
