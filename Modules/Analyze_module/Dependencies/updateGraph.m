function updateGraph(multiPlotY, multiPlotX, plot_place, values, axisDim, graph_color, xlabel_title, ylabel_title,graph_title , numOfFrames, msPerFrame, gridOn)
%%% UPDATEGRAPH function that print data to a plot area.
% Params:
%   multiPlotY - Height of the plot area: subplot(_2_, 2, 1)
%   multiPlotX - Width of the plot area: subplot(2, _2_, 1)
%   plot_place - array of the slots that are devoted to the plot
%   values - The array of data to plot
%   axisDim - The ticks of the axis [x_min, x_max, y_min, y_max]- [0, movie_length, -50,250]
%   graph_color - Color of the graph line (RGB triple or code 'red')
%   xlabel_title - Y title
%   ylabel_title - Y title
%   graph_title - title
%   numOfFrames - number of frames in the movie segment that is processed
%   msPerFrame - Exposure time
%   gridOn - add grid to the plot
%
% Example:     
%       >> updateGraph(8, 8, [49:56 57:64], ratio_values, [0, movie_length, -50,250],[0.2, 0.5, 0.9], 'Time(sec)', 'Activity changes in %','Some data', numOfFrames, msPerFrame);
%
%
%                               **  written by Alexkaz  5.2015     **

    subplot(multiPlotY,multiPlotX,plot_place);
    plot(values,'Color',graph_color,'LineWidth',4); % skip first 5 values since ratio skip as well.
    axis(axisDim);
    xlabel(xlabel_title,'FontSize', 14);
    ylabel(ylabel_title,'FontSize', 14);
    [tick_labels, tick_rate] = getAxisLabels(numOfFrames, msPerFrame);
    title(graph_title,'FontSize', 16,'fontweight','bold');
    set(gca, 'XTick', 1:tick_rate:numOfFrames,'FontSize', 13); % Change x-axis ticks
    set(gca, 'XTickLabel', tick_labels,'FontSize', 13); % Change x-axis ticks
    if(gridOn)
        grid minor;
    end
end