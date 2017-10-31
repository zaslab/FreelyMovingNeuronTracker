function [value] = evaluateRatio(pixel_value, base_level)

%
% EVALUATERATIO Function that calculates the ratio [((X(t)-X(1:5))/X(1:5)]*100
% that should be shown on a plot of neuro
%
% Usage Example:
%       >> evaluateRatio(pixel_value, base_level) - pixel_value is the
%       value of fluorescence that was measured, base_level is a constant, the average
%       over few pixel values.
%
%
%                               **   written by Alexkaz 11.2014   **
if (isnan(pixel_value))
    value = 0;
else
    value = ((pixel_value - base_level)/base_level)*100;
end
