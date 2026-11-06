clear;
close all;
clc;

% Load IMU data from Excel file (adjust the filename and sheet name accordingly)
data = xlsread('faisal.xlsx'); % Change 'imudata.xlsx' to the actual file name

% Extract necessary columns from the data
time = data(:, 1);
accX = data(:, 8);
accY = data(:, 9);
accZ = data(:, 10);
gyroX = data(:, 11);
gyroY = data(:, 12);
gyroZ = data(:, 13);

% Define sample period
Fs = 1 / mean(diff(time)); % Calculate the sample rate
samplePeriod=1/Fs;
% Convert gyroscope data from degrees/s to radians/s

accX = accX * 9.81;
accY = accY * 9.81;
accZ = accZ * 9.81;

% Create an imufilter System object™ with a specified decimation factor to reduce computational cost
decim = 1;
fuse = imufilter('SampleRate', Fs, 'DecimationFactor', decim);

% Pass accelerometer and gyroscope readings to the imufilter object to estimate orientation
[orientation, angularVelocity] = fuse([accX, accY, accZ], [gyroX, gyroY, gyroZ]);

% Convert orientation quaternion to rotation matrix
rotmatrix = quat2rotm(orientation);

% Define gravity vector in sensor frame
gravity_sensor = [0, -9.81,-2.75]; % Assuming gravity along y-axis

% Rotate gravity vector to Earth's frame using the inverse of the rotation matrix
invertedRotmatrix = permute(rotmatrix, [2,1,3]); % Transpose of the rotation matrix

% Convert gravity vector from sensor's frame to Earth's frame
gravity_earth = zeros(3, 1, length(time));
for m = 1:length(time)
    gravity_earth(:,:,m) = invertedRotmatrix(:,:,m) * gravity_sensor';
end

accelerometerReadings = [accX accY accZ];

% Reshape gravity_earth to be a 1x3x11285 matrix
reshapedGravity = reshape(gravity_earth, 1, 3, []);

% Replicate the reshapedGravity matrix to match the size of accelerometerReadings
replicatedGravity = repmat(reshapedGravity, size(accelerometerReadings, 1), 1, 1);

% Subtract the replicatedGravity from accelerometerReadings
accelWithoutGravity = accelerometerReadings - replicatedGravity;

%filtering Gyro Vertical through a bandpass filter
% Define bandpass filter parameters
filterOrder = 1; % Filter order
lowCutoff = 0.5; % Low cutoff frequency (Hz)
highCutoff = 5; % High cutoff frequency (Hz)

% Design bandpass Butterworth filter
[b, a] = butter(filterOrder, [lowCutoff, highCutoff] / (Fs / 2), 'bandpass');
GyroZ = filtfilt(b, a, gyroZ);

% Load vertical gyroscope data from the file
gyroVertical = GyroZ;

% Define parameters for peak detection
peakThreshold = 200;
minPeakDistance = 100;
negativePeakThreshold = -30;
minNegativePeakSeparation = 120;

% Find positive peaks in the vertical gyroscope data
[positivePeaks, positivePeakIndices] = findpeaks(gyroVertical, 'MinPeakHeight', peakThreshold, 'MinPeakDistance', minPeakDistance);

% Find high negative peaks in the vertical gyroscope data
[highNegativePeaks, highNegativePeakIndices] = findpeaks(-gyroVertical, 'MinPeakHeight', -negativePeakThreshold, 'MinPeakDistance', minNegativePeakSeparation);

% Plot the gyroscope data with labeled peaks
figure;
plot(gyroVertical);
hold on;

% Mark the positive peaks with blue circles
plot(positivePeakIndices, positivePeaks, 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');

% Mark the high negative peaks with red circles
plot(highNegativePeakIndices, -highNegativePeaks, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');

% Initialize vectors to store swing and stance times
swingTimes = [];
strideTimes = [];
swingStartPoints = [];
stanceStartPoints = [];

for i = 2:length(positivePeakIndices)
    beforeIndex = max(highNegativePeakIndices(highNegativePeakIndices < positivePeakIndices(i)));
    afterIndex = min(highNegativePeakIndices(highNegativePeakIndices > positivePeakIndices(i)));
    
    if ~isempty(beforeIndex) && ~isempty(afterIndex)
        swingStartPoints = [swingStartPoints, beforeIndex];
        stanceStartPoints = [stanceStartPoints, afterIndex];
    end
end
% Iterate through positive peaks to find associated swing and stance times
for i = 2:length(positivePeakIndices) % Start from 2 to avoid index out of bounds
    % Find closest negative peak before and after the positive peak
    beforeIndex = max(highNegativePeakIndices(highNegativePeakIndices < positivePeakIndices(i)));
    afterIndex = min(highNegativePeakIndices(highNegativePeakIndices > positivePeakIndices(i)));
    
    % Calculate swing and stance times
    if ~isempty(beforeIndex) && ~isempty(afterIndex)
        swingTime = (afterIndex - beforeIndex) * samplePeriod;
        
        
        % Store swing and stance times
        swingTimes = [swingTimes, swingTime];
       
        % Calculate stride time and store it
        strideTime = (positivePeakIndices(i) - positivePeakIndices(i-1)) * samplePeriod; % Assuming i > 1
        strideTimes = [strideTimes, strideTime];
        
        % Plot vertical lines to indicate swing and stance phases
        plot([beforeIndex, beforeIndex], ylim, 'g--', 'LineWidth', 1.5);
        plot([afterIndex, afterIndex], ylim, 'r--', 'LineWidth', 1.5);
    end
end

% Create a legend to explain the labeled points
legend({'Gyroscope Data', 'Positive Peaks', 'High Negative Peaks', 'Swing Phase Start', 'Stance Phase Start'});

%Stance Time Calculation
stanceTime=strideTimes-swingTimes;

%Mean of Stride Times
meanStride=mean(strideTimes);
disp('Stride Time:');
disp(meanStride);

%Standard Deviation of Stride Times
stdStride=std(strideTimes);
disp('Standard Deviation of Stride Times');
disp(stdStride);

%Mean of Stance Times
meanStance=mean(stanceTime);

disp('Stance Time');
disp(meanStance);

%Standard Deviation of Stance Time
stdStance=std(stanceTime);
disp('Standard Deviation of Stance Times');
disp(stdStance);

%Mean of Swing Times
meanSwing=mean(swingTimes);
disp('Swing Time');
disp(meanSwing);

%Standard Deviation of Swing Times
stdSwing=std(swingTimes);
disp('Standard Deviation of Swing Times');
disp(stdSwing);
hold off;

% Initialize variables to store stance phase information
stanceStartTimes = [];
stanceEndTimes = [];

% Iterate through positive peaks to find stance phase start and end times
for i = 1:length(positivePeakIndices) - 1
    beforeIndex = max(highNegativePeakIndices(highNegativePeakIndices < positivePeakIndices(i)));
    afterIndex = min(highNegativePeakIndices(highNegativePeakIndices > positivePeakIndices(i)));
    
    if ~isempty(beforeIndex) && ~isempty(afterIndex)
        nextBeforeIndex = max(highNegativePeakIndices(highNegativePeakIndices < positivePeakIndices(i+1)));
        
        if ~isempty(nextBeforeIndex)
            % Calculate stance phase start and end times
            stanceStartTimes = [stanceStartTimes, time(afterIndex)];
            stanceEndTimes = [stanceEndTimes, time(nextBeforeIndex)];
        end
    end
end




% Plot accelerometer data after gravity removal and fusion for each axis
figure;

subplot(3, 1, 1);
plot(time, accelWithoutGravity(:, 1));
title('Accelerometer Data without Gravity (X-axis)');
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');

subplot(3, 1, 2);
plot(time, accelWithoutGravity(:, 2));
title('Accelerometer Data without Gravity (Y-axis)');
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');

subplot(3, 1, 3);
plot(time, accelWithoutGravity(:, 3));
title('Accelerometer Data without Gravity (Z-axis)');
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');


% Define bandpass filter parameters
filterOrder = 1; % Filter order
lowCutoff = 0.1; % Low cutoff frequency (Hz)
highCutoff = 10; % High cutoff frequency (Hz)

% Design bandpass Butterworth filter
[b, a] = butter(filterOrder, [lowCutoff, highCutoff] / (Fs / 2), 'bandpass');

% Apply the filter to each axis of acceleration data
accX_filtered = filtfilt(b, a, accelWithoutGravity(:,1));
accY_filtered = filtfilt(b, a, accelWithoutGravity(:,2));
accZ_filtered = filtfilt(b, a, accelWithoutGravity(:,3));



% Plot original and filtered acceleration data (X-axis)
figure;
subplot(2, 1, 1);
plot(time, accX, 'b');
hold on;
plot(time, accX_filtered, 'r');
title('Acceleration Data (X-axis)');
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');
legend('Original', 'Filtered');
grid on;

% Plot stance and swing phase lines on filtered accX data
for i = 1:length(positivePeakIndices)
    beforeIndex = max(highNegativePeakIndices(highNegativePeakIndices < positivePeakIndices(i)));
    afterIndex = min(highNegativePeakIndices(highNegativePeakIndices > positivePeakIndices(i)));
    
    if ~isempty(beforeIndex) && ~isempty(afterIndex)
        % Plot vertical lines to indicate swing and stance phases
        plot([time(beforeIndex), time(beforeIndex)], ylim, 'g--', 'LineWidth', 1.5);
        plot([time(afterIndex), time(afterIndex)], ylim, 'r--', 'LineWidth', 1.5);
    end
end

% Plot original and filtered acceleration data (Y-axis)
subplot(2, 1, 2);
plot(time, accY, 'b');
hold on;
plot(time, accY_filtered, 'r');
title('Acceleration Data (Y-axis)');
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');
legend('Original', 'Filtered');
grid on;

% Plot stance and swing phase lines on filtered accY data
for i = 1:length(positivePeakIndices)
    beforeIndex = max(highNegativePeakIndices(highNegativePeakIndices < positivePeakIndices(i)));
    afterIndex = min(highNegativePeakIndices(highNegativePeakIndices > positivePeakIndices(i)));
    
    if ~isempty(beforeIndex) && ~isempty(afterIndex)
        % Plot vertical lines to indicate swing and stance phases
        plot([time(beforeIndex), time(beforeIndex)], ylim, 'g--', 'LineWidth', 1.5);
        plot([time(afterIndex), time(afterIndex)], ylim, 'r--', 'LineWidth', 1.5);
    end
end

% Adjust figure layout
sgtitle('Acceleration Data Comparison (Before and After Filtering)');
% Apply ZUPT algorithm to make the parts of accX and accY stationary
zuptAccX = accX_filtered; % Use the filtered accX data for ZUPT
zuptAccY = -accY_filtered; % Use the filtered accY data for ZUPT

% ... (your existing code)

% Iterate through stance start and end times to zero out x-axis accel data
%for i = 1:length(stanceStartTimes)
 %  stanceStartTime = stanceStartTimes(i);
 %  stanceEndTime = stanceEndTimes(i);
    
    
    % Find the indices corresponding to the stance phase
  % stanceStartIndex = find(time >= stanceStartTime, 1);
  % stanceEndIndex = find(time <= stanceEndTime, 1, 'last');
  % 
    % Zero out x-axis accel data for the stance phase
  %  accX_filtered(stanceStartIndex:stanceEndIndex) = 0;
 % accY_filtered(stanceStartIndex:stanceEndIndex) = 0;
%end

% Initialize variables for velocity and displacement for x and y axes
stationaryThreshold=5;
velX = zeros(size(accX_filtered));

velY = zeros(size(accY_filtered));


% Loop through time to calculate velocity and displacement for x-axis
for t = 2:length(time)
     if abs(accX_filtered(t) - 1) < stationaryThreshold
        velX(t,:) = [0];     % force zero velocity when foot stationary
     else
         velX(t,:) = velX(t-1,:) + accX_filtered(t,:) * samplePeriod;
    end
    

   
end

for t = 2:length(time)
     if abs(accY_filtered(t) - 1) < stationaryThreshold
        velY(t,:) = [0];     % force zero velocity when foot stationary
     else
         velY(t,:) = velY(t-1,:) + accY_filtered(t,:) * samplePeriod;
     end
   
end

% Plot the acceleration, velocity, and displacement for x-axis
figure;
subplot(2, 1, 1);
plot(time, accX_filtered, 'r');
title('Acceleration (X-axis)');
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');
grid on;

subplot(2, 1, 2);
plot(time, velX, 'b');
title('Velocity(X-axis) with ZUPT applied');
xlabel('Time (s)');
ylabel('Velocity (m/s)');
grid on;



% Plot the acceleration, velocity, and displacement for y-axis
figure;
subplot(2, 1, 1);
plot(time, accY_filtered, 'r');
title('Acceleration Data (Y-axis)');
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');
grid on;

subplot(2, 1, 2);
plot(time, velY, 'b');
title('Velocity (Y-axis)');
xlabel('Time (s)');
ylabel('Velocity (m/s)');
grid on;



% Adjust figure layouts
sgtitle('Acceleration and Velocity Data');



% Find positive peaks above a threshold in the y-axis acceleration data
positivePeakThreshold = 3; % Adjust the threshold value
minPositivePeakSeparation = 100; % Adjust the minimum peak distance
[positivePeaks, positivePeakIndices] = findpeaks(accX_filtered, 'MinPeakHeight', positivePeakThreshold, 'MinPeakDistance', minPositivePeakSeparation);

% Calculate step lengths based on the time difference between consecutive positive peaks
stepLengths = zeros(size(positivePeakIndices));
for i = 2:length(positivePeakIndices)
    timeDifference = time(positivePeakIndices(i)) - time(positivePeakIndices(i-1));
    averageVelocity = (velX(positivePeakIndices(i)) + velX(positivePeakIndices(i-1))) / 2;
    stepLengths(i) = (averageVelocity * timeDifference);
end

% Display  average step lengths
disp('Average Step Length:');
Mstep=mean(stepLengths);
disp(Mstep);

%display Standard Deviation of Step length
disp('Standard Devaition in Step Length:');
stdStep=std(stepLengths);
disp(stdStep);

% Calculate cadence based on the number of positive peaks and total stride time
cadence = length(positivePeakIndices) / sum(strideTimes);
disp('Cadence ');
spm=cadence*60;
disp(spm);

% Calculate speed using step length and cadence
speed = Mstep * cadence;
disp('Speed (m/s):');
disp(speed)

% Initialize an array to store stance times
stanceTimes = zeros(size(stanceStartIndex));

% Calculate stance times for each pair of indices
for i = 1:length(stanceStartIndex)
    stanceTimes(i) = time(stanceEndIndex(i)) - time(stanceStartIndex(i));
end

% Calculate the mean stance time
meanStanceTime = mean(stanceTimes);


disp('Mean Stance Time:');
disp(meanStanceTime);

% Load your accelerometer data for X, Y, and Z axes here

% Calculate the RMS value for each axis
rmsX = rms(accX_filtered);
rmsY = rms(accY_filtered);
rmsZ = rms(accZ_filtered);

% Calculate the combined RMS value
combinedRMS = rms(sqrt(accX_filtered.^2 + accY_filtered.^2 + accZ_filtered.^2));

% Display the results
fprintf('RMS X-axis: %.2f\n', rmsX);
fprintf('RMS Y-axis: %.2f\n', rmsY);
fprintf('RMS Z-axis: %.2f\n', rmsZ);
fprintf('Combined RMS: %.2f\n', combinedRMS);

% Compute the FFT for left and right accelerometer data
fft_X = fft(accX_filtered);
fft_Y = fft(accY_filtered);

% Calculate the frequency axis
N = length(accX_filtered); % Number of data points
f = (0:N-1) * (Fs/N); % Frequency axis

% Plot the magnitude of the FFT for left and right accelerometer data
figure;
subplot(2, 1, 1);
plot(f, abs(fft_X));
title('FFT - X axis Accelerometer Data');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
grid on;

subplot(2, 1, 2);
plot(f, abs(fft_Y));
title('FFT - Y Accelerometer Data');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
grid on;

% Find dominant frequency for each leg
dominant_frequency_X = f(find(abs(fft_X) == max(abs(fft_X))));
dominant_frequency_Y = f(find(abs(fft_Y) == max(abs(fft_Y))));

disp('Dominant Frequency in X-axis');
disp(dominant_frequency_X);
disp('Dominant Frequency in Y-axis');
disp(dominant_frequency_Y);

% Find positive peaks in the X-axis acceleration data
positiveAccXThreshold = 10; % Initial threshold value
minPositiveAccXPeakSeparation = 100; % Adjust the minimum peak distance
[positiveAccXPeaks, positiveAccXPeakIndices] = findpeaks(accX_filtered, 'MinPeakHeight', positiveAccXThreshold, 'MinPeakDistance', minPositiveAccXPeakSeparation);

% Find positive peaks in the Y-axis acceleration data
positiveAccYThreshold = 3.5; % Initial threshold value
minPositiveAccYPeakSeparation = 150; % Adjust the minimum peak distance
[positiveAccYPeaks, positiveAccYPeakIndices] = findpeaks(accY_filtered, 'MinPeakHeight', positiveAccYThreshold, 'MinPeakDistance', minPositiveAccYPeakSeparation);

% Create a time vector for X and Y axes
timeX = linspace(0, length(accX_filtered) * samplePeriod, length(accX_filtered));
timeY = linspace(0, length(accY_filtered) * samplePeriod, length(accY_filtered));

% Plot the X and Y axes acceleration data with labeled peaks
figure;
subplot(2, 1, 1);
plot(timeX, accX_filtered, 'r');
hold on;
plot(timeX(positiveAccXPeakIndices), positiveAccXPeaks, 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
title('Acceleration Data (X-axis) with Peaks');
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');
legend('Acceleration', 'Positive Peaks');
grid on;
hold off;

subplot(2, 1, 2);
plot(timeY, accY_filtered, 'r');
hold on;
plot(timeY(positiveAccYPeakIndices), positiveAccYPeaks, 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
title('Acceleration Data (Y-axis) with Peaks');
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');
legend('Acceleration', 'Positive Peaks');
grid on;
hold off;

% Calculate average peak values for X and Y axes
averagePeakAccX = mean(positiveAccXPeaks);
stdPeakAccX=std(positiveAccXPeaks);

averagePeakAccY = mean(positiveAccYPeaks);
stdPeakAccY=std(positiveAccYPeaks);

% Display the results
fprintf('Average Peak Acceleration (X-axis): %.2f\n', averagePeakAccX);
fprintf('Standard Deviation in Acceleration (X-axis): %.2f\n', stdPeakAccX);
fprintf('Average Peak Acceleration (Y-axis): %.2f\n', averagePeakAccY);
fprintf('Standard Deviation in Acceleration (Y-axis): %.2f\n', stdPeakAccY);

