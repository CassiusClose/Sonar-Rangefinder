% The code for a sonar rangefinding device. The first sections play back
% an impulse out of a speaker driver and records audio from a microphone
% located next to the speaker. The last section analyzes the recorded audio
% and detects the original impulse and the 1st reflection (or the lack of
% one, if the device is not pointed at anything close enough). It
% calculates the distance from the device to the object it's pointing at.

clear
close all

%% Record Silence
% Record a clip of background noise without an impulse, so it can better
% determine what is background noise and what is reflected impulse.

fprintf("Recording background noise. Be quiet...\n")

% Record background noise for better reflection detection
sr = 48000;
recorder = audiorecorder(sr, 24, 1);
recordblocking(recorder, 1);

% Save to file
data = getaudiodata(recorder);
audiowrite('bg.wav', data, sr);

fprintf("Done\n");


%% Playback & Record
% Play the impulse while recording audio to capture the reflection.

fprintf("Initializing audio objects...\n");

% Open impulse audio file
freader = dsp.AudioFileReader('output.wav', 'SamplesPerFrame', 512);
sr = freader.SampleRate;

% Open recorded audio file for writing
fwriter = dsp.AudioFileWriter('input.wav', 'SampleRate', sr);


% Object that plays and records audio in sync
apr = audioPlayerRecorder('SampleRate', sr);

fprintf("Playing & recording...\n");

% Frame by frame, play & record audio
while ~isDone(freader)
    % Get next frame of output
    outputFrame = freader();
    
    % Output audio and record simultaneously
    [inputFrame, underruns, overruns] = apr(outputFrame);
    
    % Write the recorded audio to the file
    fwriter(inputFrame);
end

fprintf("Done\n");

release(fwriter);
release(freader);
release(apr);


%% Signal Processing
% Analyzes the recorded reflection and background noise files to calculate
% the object's distance away from the rangefinding device.

close all

fprintf("Processing data...\n");

% Open the most recently recorded audio file
% [input, sr] = audioread('input.wav'); % 

% Open a previously recorded audio file
[input, sr] = audioread('SampleDatasets/2ft_in.wav');

% Background noise file
[bg, sr] = audioread('bg.wav');


% Speed of sound in m/s
soundSpeed = 343;



% ----CALCULATE RMS VALUES----
% Calculate RMS values for each consecutive N samples, to better define the
% large peaks and simplify the analysis by making the signal only positive.

% Each frame (set of samples) will be converted to 1 RMS value. With the
% given speed of sound, how many meters should one RMS value represent.
% This will be the granularity of the distance calculation (it won't be
% able to differentiate between distance values smaller than this).
metersPerFrame = 0.1; 

% Num of samples in each frame for the RMS calculation
rmsFrameSize = round(sr /(soundSpeed/metersPerFrame));
% Calculate total number of frames 
numFrames = ceil(length(input)/rmsFrameSize);

% Init RMS values of the signal
inputRMS = zeros(1, numFrames);

% Calculate RMS value for each frame
for i=1:numFrames
    % Starting sample for current frame
    sIndex = (i-1)*rmsFrameSize + 1;
    % Ending sample for current frame
    eIndex = sIndex + rmsFrameSize - 1;
    if(eIndex > length(input))
        eIndex = length(input);
    end
    
    % Calc RMS value
    inputRMS(i) = rms(input(sIndex:eIndex));
end


% Convert the background noise audio to RMS values using the same frame
% size as before, for proper comparison.

% Total number of frames
numbgFrames = ceil(length(input)/rmsFrameSize);
% Init background noise RMS values
bgRMS = zeros(1, numbgFrames);

% For each frame, calculate RMS value
for i=1:numFrames
    % Starting sample for current frame
    sIndex = (i-1)*rmsFrameSize + 1;
    % Ending sample for current frame
    eIndex = sIndex + rmsFrameSize - 1;
    if(eIndex > length(bg))
        eIndex = length(bg);
    end
    
    bgRMS(i) = rms(bg(sIndex:eIndex));
end



% ----CHOOSE LOCAL MAXIMA----
% To identify where the peaks are (the original impulse and the 1st
% reflection), we find local maxima of the audio signal and then compare
% those points to find the two peaks.

% The local maxima are found in a specialized way. Picking every local
% maximum is not very helpful, since often there are little one-sample
% peaks halfway down the descent of the impulse. So once it picks a local
% maxmimum, it can't pick another one until the audio signal drops a
% certain amount. It also can't pick another one unless the signal has been
% increasing consecutively for a certain distance. This is a better
% algorithm for detecting only the tops of peaks.

% This also figures out roughly where the noise floor is from the recorded
% clip of background noise and rejects any local maxima that fall below
% that floor.


% Use the biggest drop 
rmsMaxVal = max(inputRMS);
localmaxGap = rmsMaxVal*(4/10);

% Using a gaplocalmax(), a point can be a local max as long as the signal
% has dropped a certain amount since the last local max
rmsMax = gaplocalmax(inputRMS, localmaxGap, 0.001);
% rmsMax = thresholdlocalmax(inputRMS, bgMax);


% The highest value from the background noise
bgMax = max(bgRMS)*2;

% Reject any local maxima below the noise floor, keep count of how many
% peaks are left over. Presumably there should only be two: the original
% signal and the first reflection.
maxCount = 0;
for i=1:length(rmsMax)
    if(rmsMax(i) == 1 && inputRMS(i) <= bgMax)
        rmsMax(i) = 0;
    end
    if(rmsMax(i) == 1)
        maxCount = maxCount + 1;
    end
end


% ----PICK ORIGINAL SIGNAL & 1ST REFLECTION PEAKS----
% Get the positions of the original signal and the 1st reflection. By now,
% the local maxima should have been reduced down to the two big peaks (or,
% if the object was too far away, only one peak).

% Sample positions of the two peaks
peak1pos = 0;
peak2pos = 0;

% Find the positions of each peak. 
if(maxCount == 2)
    for i=1:length(inputRMS)
        % If 1st peak hasn't been found
        if(peak1pos == 0)
            if(rmsMax(i) == 1)
                peak1pos = i;
            end
        % If 1st peak has been found
        else
            if(rmsMax(i) == 1)
                peak2pos = i;
                break;
            end
        end
    end
else
    % Find the position of the first peak (the highest local max)
    peak1pos = 1;
    for i=1:length(inputRMS)
        if(rmsMax(i) == 1 && inputRMS(i) > inputRMS(peak1pos))
            peak1pos = i;
        end
    end

    % Find the second peak, the highest local max located after the first
    % peak
    peak2pos = 0;
    % If there are no more maxima (no reflected sound), then the 2nd peak
    % will be at position 0
    for i=peak1pos+1:length(inputRMS)
        % If haven't chosen one yet, choose the first max it comes across
        if(peak2pos == 0)
            if(rmsMax(i) == 1)
                peak2pos = i;
            end
        % If we have chosen one, but this one is higher, use this one
        elseif(rmsMax(i) == 1 && inputRMS(i) > inputRMS(peak2pos))
            peak2pos = i;
        end
    end
end


% ----DISTANCE CALCULATION----
% Calculate the distance between the rangefinder device and the object it's
% pointed at.

% If there was no reflected signal, then the object was too far away/there
% was nothing in front of the device.
if(peak2pos == 0)
    fprintf("The object was too far away to calculate distance.");
else
    % The number of seconds elapsed between the chosen peaks
    dt = (peak2pos - peak1pos)*rmsFrameSize/sr;

    % Distance to object (full distance traveled / 2)
    distMeters = dt*soundSpeed/2;
    distFeet = 3.28084 * distMeters;


    fprintf('The audio traveled for %f s. Your object is %f m or %f ft away.\n',...
        dt, distMeters, distFeet);
end



% ----PLOTTING----
% Plot enlightening information about the analysis

% Compute x-axis time & sample arrays (to plot local maxima from logical
% arrays)
t = 0:1/sr:(length(input)-1)/sr;
rms_t = 1:length(inputRMS);


% Plot the recorded signal
figure;
plot(t, input);
xlabel("Time (seconds)");
ylabel("Amplitude");
title("Recorded Signal", "FontSize", 14);

% % Plot the recorded signal's RMS values
% figure;
% plot(rms_t*rmsFrameSize/sr, inputRMS);
% xlabel("Time (seconds)");
% ylabel("Amplitude (RMS)");
% title("Input Signal - RMS", "FontSize", 14);
% 
% % Plot all the chosen local maxima from the RMS values
% figure;
% plot(rms_t*rmsFrameSize/sr, inputRMS);
% hold on;
% plot(rms_t(rmsMax)*rmsFrameSize/sr, inputRMS(rmsMax), 'r*');
% yline(bgMax, 'r--');
% xlabel("Time (seconds)");
% ylabel("Amplitude (RMS)");
% title("Local Maxima", "FontSize", 14);
% % 


% Plot the original recorded signal, with the ranges of values
% corresponding to the chosen RMS peak values highlighted
figure;
plot(t, input);
hold on;
xlabel("Time (seconds)");
ylabel("Amplitude");
title("Original Wave with Chosen RMS Ranges Highlighted", "FontSize", 14);

if(peak2pos ~= 0)
    % Each chosen RMS peak corresponds to a frame of input samples, so
    % calculate the starting and ending time indices of each frame
    peak1start = peak1pos*rmsFrameSize;
    peak1end = peak1start + rmsFrameSize - 1;
    peak2start = peak2pos*rmsFrameSize;
    peak2end = peak2start + rmsFrameSize - 1;

    % Highlight each chosen frame
    plot(t(peak1start:peak1end), input(peak1start:peak1end), 'g');
    plot(t(peak2start:peak2end), input(peak2start:peak2end), 'g');
end


% Plot the recorded signal's RMS values with the local maxima chosen for
% the two peaks, and a line displaying the noise floor
figure;
plot(rms_t*rmsFrameSize/sr, inputRMS);
hold on;
xlabel("Time (seconds)");
ylabel("Amplitude (RMS)");
title("Chosen Points & Background Exclusion Level", "FontSize", 14);

% Mark the two selected peaks used to calculate distance
plot(peak1pos*rmsFrameSize/sr, inputRMS(peak1pos), 'g*');
if(peak2pos ~= 0)
    plot(peak2pos*rmsFrameSize/sr, inputRMS(peak2pos), 'g*');
end


% Plot a line marking the background noise level (below which, no maxima
% can be chosen)
yline(bgMax, 'r--');

% Plot a line at the y-value corresponding to the localmaxGap
% yline(localmaxGap, 'g--');

% Plot all local maxes (from gaplocalmax())
% plot(rms_t(rmsMax)*rmsFrameSize/sr, inputRMS(rmsMax), 'r*')
