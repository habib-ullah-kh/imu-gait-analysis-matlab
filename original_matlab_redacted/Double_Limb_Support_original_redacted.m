clear all;
clc;

% Sample stance start and end times for both legs
leftLegStanceStart = []; % Original trial-level event timestamps withheld pending data-sharing permission
leftLegStanceEnd = []; % Original trial-level event timestamps withheld pending data-sharing permission

rightLegStanceStart = []; % Original trial-level event timestamps withheld pending data-sharing permission
rightLegStanceEnd = []; % Original trial-level event timestamps withheld pending data-sharing permission

% Initialize variables
doubleLegSupportTimes = [];

% Determine double-leg support times
for i = 1:numel(leftLegStanceStart)
    leftStart = leftLegStanceStart(i);
    leftEnd = leftLegStanceEnd(i);
    
    for j = 1:numel(rightLegStanceStart)
        rightStart = rightLegStanceStart(j);
        rightEnd = rightLegStanceEnd(j);
        
        % Calculate overlapping time interval (double-leg support)
        overlapStart = max(leftStart, rightStart);
        overlapEnd = min(leftEnd, rightEnd);
        
        % Check if there is an overlap
        if overlapStart <= overlapEnd
            doubleLegSupportTime = overlapEnd - overlapStart;
            doubleLegSupportTimes = [doubleLegSupportTimes, doubleLegSupportTime];
        end
    end
end

% Calculate the total double-leg support time
totalDoubleLegSupportTime = sum(doubleLegSupportTimes);
meanD=mean(doubleLegSupportTimes);

% Display the double-leg support times and the total double-leg support time
disp('Double-Leg Support Times:');
disp(doubleLegSupportTimes);
disp('Total Double-Leg Support Time:');
disp(totalDoubleLegSupportTime);
disp('Average Double leg Support Time');
disp(meanD);
