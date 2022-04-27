classdef BYB_Chart
    properties 
        scrolling       %flag to know whether the plot is srolling yet
        insertPoint     %the current place that data is being inserted into the plot
        plotHandle      %the handle to the actual plot
        displaySeconds  %the number of seconds to display in the plot
        displayPoints   %the number of points to display in the plot
        tAxis           %the current time axis to display
        sampleRate
        ax
    end
    properties (Access = private)
        tempBuffer;
    end
    methods
        function obj = BYB_Chart(SampleRate, ChartLength, plotAxis)
            %Returns a handle to an chart object for dynamically displaying 
            %timeseries data.
            %
            %Usage:
            %
            %obj = BYB_Chart(Fs) - creates a chart based on data
            %collected at the samplerate Fs.  The default is to create the
            %plotting axis in a new figure and for a plot lenght of 3
            %seconds.
            %
            %obj = BYB_Chart(Fs, ChartLength) - specifies the length of the
            %chart in seconds.  The plot will begin scrolling once
            %ChartLength seconds of data are plotted.
            %
            %obj = BYB_Chart(Fs, ChartLength, axis) - specifies the axis
            %into which the data should be plotted.
            %
            %pass data to the functions UpdateChart method to add data to
            %the plot
            %
            if nargin < 3
                f = figure;
                f.Color = 'w';
                plotAxis = axes(f);
            end
            if nargin < 2
                obj.displaySeconds = 3;
            else
                obj.displaySeconds = ChartLength;
            end
            if nargin < 1 
                error('Please provide a valid sample rate...');
                obj = [];
                return;
            else 
                obj.sampleRate = SampleRate;
            end
            
            obj.scrolling = false;
            obj.insertPoint = 1;
            obj.displayPoints = obj.displaySeconds * SampleRate;
            obj.tempBuffer = zeros(1,obj.displayPoints);
            obj.tAxis = (1:obj.displayPoints)./SampleRate;
            obj.plotHandle = plot(plotAxis, obj.tAxis, zeros(1,obj.displayPoints));
            obj.ax = plotAxis;
            obj.ax.YLabel.String = 'amplitude';
            obj.ax.XLabel.String = 'time (seconds)';
                
        end
        function obj = UpdateChart(obj, dataChunk, plotRange)
            %Adds data the the existing plot for this chart object
            %
            %obj = UpdateChart(d) - adds the timeseries data in d to the
            %existing data chart.
            %
            %obj = UpdateChart(d, scaleRange) - adjust the vertical scale
            %of the axis to the values in 1x2 double array scaleRange. Eg -
            %to scale between -1 and 2 pass [-1,2] as the scaleRagen
            %parameter
            
            if nargin < 3
                autoScale = true;
            else
                autoScale = false;
            end
            ln = length(dataChunk);
            lt = ln ./ obj.sampleRate;
            d = (obj.insertPoint + ln-1) - obj.displayPoints;
            %maybe try accessing the ydata only once to improve speed
            if obj.scrolling 
                
                obj.plotHandle.YData(1:obj.displayPoints-ln) = obj.plotHandle.YData(ln+1:end);
                obj.plotHandle.YData(obj.displayPoints-ln+1:obj.displayPoints) = dataChunk;
                obj.plotHandle.XData = obj.plotHandle.XData + lt;
            elseif d<=0
          
                obj.plotHandle.YData(obj.insertPoint: obj.insertPoint + ln-1) = dataChunk;
                obj.plotHandle.YData(obj.insertPoint + ln: end) = mean(dataChunk);
                obj.insertPoint = obj.insertPoint + ln;
            else 
                obj.plotHandle.YData(1:obj.displayPoints-ln) = obj.plotHandle.YData(d:obj.displayPoints-ln-1+d);
                obj.plotHandle.YData(obj.displayPoints-ln+1:obj.displayPoints) = dataChunk;
         
                obj.plotHandle.XData = obj.plotHandle.XData + (d./obj.sampleRate);
                obj.scrolling = true;
            end
            axis(obj.ax,'tight');
            if ~autoScale
                obj.PlotHandle.YLim = plotRange;
            end
            drawnow();
          
        end
    end
end
