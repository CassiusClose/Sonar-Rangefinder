% Generate a short random noise signal to act as an impulse and save it to
% an audio file. Use random noise because it's louder (the driver is
% pretty weak)


clear
close all

sr = 48000; % Sample Rate
len = 1; % Length of audio file in seconds

% Start and end (in seconds) of the impulse signal. Leave some space at the
% beginning of the audio file so that the recorder can start recording in
% time.
sigStart = 0.5;
sigEnd = 0.501;

% Compute array of sample values
dt = 1/sr;
n = 0:dt:len;

% Init the output array
output = zeros(sr*len+1,1);

% Compute start and end of signal in samples
sampStart = sigStart*48000;
sampEnd = sigEnd*48000;

% The signal is random noise in the specified period, and silence elsewhere
output(sampStart:sampEnd) = rand(sampEnd-sampStart+1,1)-0.5;

figure
plot(n, output);

% Save the audio for use in the rangefinder script
audiowrite('output.wav', output, 48000);