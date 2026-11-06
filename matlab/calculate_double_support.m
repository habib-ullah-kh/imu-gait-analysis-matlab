function [overlaps,totalTime,meanTime] = calculate_double_support(leftStart,leftEnd,rightStart,rightEnd)
% Calculate positive intersections of original stance intervals (seconds).
% Pass arrays from approved left/right gait event annotations.
leftStart=leftStart(:);leftEnd=leftEnd(:);rightStart=rightStart(:);rightEnd=rightEnd(:);
assert(numel(leftStart)==numel(leftEnd),'Left interval lengths differ');
assert(numel(rightStart)==numel(rightEnd),'Right interval lengths differ');
assert(all(isfinite([leftStart;leftEnd;rightStart;rightEnd])),'Times must be finite');
assert(all(leftEnd>=leftStart) && all(rightEnd>=rightStart),'Invalid interval');
overlaps=zeros(0,3);
for i=1:numel(leftStart)
  for j=1:numel(rightStart)
    startT=max(leftStart(i),rightStart(j));
    endT=min(leftEnd(i),rightEnd(j));
    if startT < endT % Ignore zero-duration contact at boundaries.
      overlaps(end+1,:)=[startT,endT,endT-startT]; %#ok<AGROW>
    end
  end
end
if isempty(overlaps),totalTime=0;meanTime=NaN;
else,totalTime=sum(overlaps(:,3));meanTime=mean(overlaps(:,3));end
end
