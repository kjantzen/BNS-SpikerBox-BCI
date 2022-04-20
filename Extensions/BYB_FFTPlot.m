classdef BYB_FFTPlot
    properties 
        plotHandle      %the handle to the actual plot
        fAxis           %the current time axis to display
        sampleRate
        bufferSeconds
        bufferPoints
        dataBuffer
        fftData
        fftPoints
        nyquist
        ax
    end
    methods
        function obj = BYB_FFTPlot(SampleRate, BufferSeconds, plotAxis)
            if nargin < 2
                obj.bufferSeconds = 3;
            else
                obj.bufferSeconds = BufferSeconds;
            end
            if nargin < 1 
                obj.sampleRate = 10000;
            else 
                obj.sampleRate = SampleRate;
            end
            obj.nyquist = obj.sampleRate /2;
            obj.bufferPoints = obj.bufferSeconds * obj.sampleRate;
            obj.fftPoints = obj.bufferPoints/2+1;
            obj.dataBuffer = zeros(1,obj.bufferPoints);
            
            obj.fAxis = obj.sampleRate * (0:(obj.bufferPoints/2))/obj.bufferPoints;
            obj = computeFFT(obj);

            obj.plotHandle = plot(plotAxis, obj.fAxis, obj.fftData);
            obj.ax = plotAxis;
            obj.ax.YLabel.String = 'amplitude^2';
            obj.ax.XLabel.String = 'frequency (Hz)';
                
        end
        function obj = computeFFT(obj)
            twoSided = abs(fft(obj.dataBuffer)/obj.bufferPoints);
            obj.fftData  = twoSided(1:obj.bufferPoints/2+1);
            obj.fftData(2:end-1) = 2 * obj.fftData(2:end-1);
        end
        function obj = updateChart(obj, dataChunk, fRange)
            
            ln = length(dataChunk);
            obj.dataBuffer(1:obj.bufferPoints-ln) = obj.dataBuffer(ln + 1: obj.bufferPoints);
            obj.dataBuffer(obj.bufferPoints-ln+1:obj.bufferPoints) = dataChunk;
            obj = computeFFT(obj);
            obj.plotHandle.YData = obj.fftData;
      
            obj.ax.XLim = fRange/obj.nyquist * length(obj.fftData);
            drawnow();
          
        end
    end
end