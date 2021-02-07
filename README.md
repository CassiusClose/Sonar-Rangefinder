<h1> Sonar Rangefinder </h1>

This is the MATLAB code that powers a sonar rangefinding device. This
was a project for AME292: Acoustics Portfolio at University of Rochester.

For a more in-depth description of how this works, see `EXPLANATION.md`.

<h2> Usage </h2>

`wavgen.m` is used to generate a short audio impulse, saved in `output.wav`. 

`rangefinder.m` will play that audio through the computer's default
output device and simulatneously record audio through the computer's
default input device.

The rangefinding device consists of a speaker driver and a microphone
placed next to each other. The speaker and microphone should be connected
to the computer via an audio interface, which should be set as the default
audio device. Point the speaker

`rangefinder.m` will then analyze its recorded audio to find the peaks of
the original wave and its reflection off of the object the device is
pointed at. It will measure the time elapsed between the original wave and
its reflection, and use this to determine how far away the object is from
the rangefinding device.

<h2> Sample Data </h2>

By default, rangefinder.m will save recorded audio in `bg.wav` and
`input.wav`. Sample data files are included in the `SampleDatasets/` folder.
To see the results of anaylzing different input files, scroll down to the
`Signal Processing` section of `rangefinder.m`. There, you will be
able to change the value of the `input` variable to whatever file you want
to analyze.



