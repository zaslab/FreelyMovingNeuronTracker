function [tick_labels, frames_in_tick] = getAxisLabels(numel, msPerFrame)
% GETAXISLABELS calculates the ticks for the neuron activity graph. No
% matter what length of the movie is, there will be no more then 20 ticks
% on x_axis, and they will have relevant time values.
%
% Params:
%       tick_labels - array of 20 values with time values that correspond
%                     to the length of the movie.

fps = round(1000/msPerFrame);
length_in_secs = round(numel/fps);
frames_in_tick = round(numel/25);
tick_rate = round(length_in_secs/25);
tick_labels = 1:tick_rate:length_in_secs;
