classdef BYB_FFT
    properties 
        sampleRate
        bufferSeconds
        bufferPoints
        dataBuffer
        fftData
        fftPoints
        nyquist
        bins
    end
    properties (Constant)
        freqBinNames = {'delta', 'theta', 'alpha', ;'beta1', 'beta2', 'gamma'}
        freqBinRange = [0, 3; 3, 8; 8, 12; 12,20; 20; 20, 30];
    end
    properties (Hidden)
        freqBinPnts
    end
    methods
        function obj = BYB_FFT(SampleRate, BufferSeconds)
            if nargin < 2
                obj.bufferSeconds = 1;
            else
                obj.bufferSeconds = BufferSeconds;
            end
            if nargin < 1 
                obj.sampleRate = 1000;
            else 
                obj.sampleRate = SampleRate;
            end
            obj.nyquist = obj.sampleRate /2;
            obj.bufferPoints = obj.bufferSeconds * obj.sampleRate;
            obj.bufferPoints = pow2(nextpow2(obj.bufferPoints));

            obj.fftPoints = obj.bufferPoints/2+1;
            obj.dataBuffer = zeros(1,obj.bufferPoints);
            
            obj.fAxis = obj.sampleRate * (0:(obj.bufferPoints/2))/obj.bufferPoints;
            obj.fftData = zeros();

            %convert the bin range values to actual offsets into the fft
            %array
            obj.freqBinPnts = obj.freqBinRange * obj.bufferPoints / obj.sampleRate;
                
        end
    
        function obj = FFT(obj)
            twoSided = abs(fft(obj.dataBuffer)/obj.bufferPoints);
            obj.fftData  = twoSided(1:obj.bufferPoints/2+1);
            obj.fftData(2:end-1) = 2 * obj.fftData(2:end-1);

            for ii = 1:size(obj.freqBinPnts, 1);
                obj.bins(ii) = mean(obj.fftData(obj.freqBinPnts(ii,1)+1 : obj.freqBinPnts(ii,2)));
            end
        end
 
    end
end
