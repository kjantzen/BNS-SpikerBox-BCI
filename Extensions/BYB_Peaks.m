classdef BYB_Peaks
    properties 
        AmpThreshold = 0.8;
        WidthThreshold = 10;    %default of +- 10 ms with a sample rate of 1000Hz
        SmoothPoints = 0;
        AdjustThreshold = false;
        SearchAcrossChunks = true;
        Peaks = []
    end
    properties(Access = private)
        Buffer = [];
        LastPeaks;
    end
    methods
        function obj = BYB_Peaks(AmpThreshold, WidthThreshold, SmoothPoints, AdjustThreshold, SearchAcrossChunks)
            %BYB_Peaks - an object for performing peaks detection on real
            %time data collected with the BYB spiker box,
            %USAGE:
            %   obj = BYB_Peaks() - creates an object using default
            %   parameters
            %
            %   obj = BYB_Peaks(AmpThreshold, WidthThreshold, SmoothPoints,
            %   AdjustThreshold, SearchAcrossChunks)
            %
            %   Optional Inputs
            %
            %   AmpThreshold - when detecting positive peaks, only samples 
            %   that exceed this threshold will be evaluated. Default = 0.8
            %
            %   WidthThreshold - an integer value indicating the minimum width
            %   of peak.  For WidthThreshold = n, a peak must be the maximum
            %   absolute value with +- n samples.  Thus the minimum peak width 
            %   is 2n + 1. Default = 10;
            %
            %   SmoothPints - number of points to use in smoothing the data
            %   before search for peaks. Set this value to 0 if no smoothing
            %   is desired.  Default = 0.  For more information see the
            %   Matlab smoothdata function.
            %
            %   AdjustThreshold - perform a crude adjustment to  AmpThreshold 
            %   to account for signal amplitude loss due to smoothing.
            %   Smoothing will reduce the amplitude of sharp peaks in the
            %   data.  if AdjustThreshold = True, the threhsold will be
            %   adjusted down by multiplying it by 
            %   (max(abs(preSmooth))/max(abs(postSmooth)). Default = false.
            %
            %   SearchAcrossChunks - prepends the last (2 * WidthThreshold)
            %   points from the previous data segment to the current data
            %   segment to accound for peaks that may have occured at the
            %   very end of the previous segment. Default = true;
            %
            %RETURNS
            %   
            %   Information about identified peaks will be stored in a 
            %   structure array stored in obj.Peaks.  The array will have
            %   one element per peak identified.  If no peaks were
            %   identified, the array will be empty ([]).
            %   The strucure has the following fields
            %       index - the index or sample into the sample vector at
            %       which the peak was located. A negative index indicated
            %       the peak occured in the previous data segment.
            %       value - the baseline adjusted value of the sample at the peak.
            %
            % EXAMPLE
            %   %
            %   create a simulated eye blink
            %Fs = 1000;
            %        Si = 1/Fs;
            %        Duration = 4;
            %        
            %        BlinkFreq = 3;
            %        BlinkTime = 1/BlinkFreq;
            %        
            %        t = 0:Si:Duration -Si;
            %       
            %       d = ones(1,length(t));
            %       
            %       b = sin([0:Si:BlinkTime-Si] * 2 * pi *BlinkFreq);
            %       
            %       insertIndex = round((length(d) - length(b))/2);
            %       range = insertIndex:insertIndex + length(b) -1;
            %       d(range) = d(range) + b;
            %       d(d<1) = (d(d<1)-1) * .2 + 1  ;
            %       plot(t,d);
            %   
            % creates a peak object with a threshold suited to detect only
            % the positive component
            %   p = BYB_Peak(1.3, 10,0, false,false)
            %
            % search for peaks and display the results
            %   p = p.Detect(d);
            %   p.Peaks
            %
            % adjust the threshold so it is suitable for also finding the
            % negative component
            %   p.AmpThreshold = 1.1;
            %   p = p.Detect(d);
            %
           
           if nargin > 4
               obj.SearchAcrossChunks = SearchAcrossChunks;
           end
           if nargin > 3
               obj.AdjustThreshold = AdjustThreshold;
           end
           if nargin > 2
               obj.SmoothPoints = SmoothPoints;
           end
           if nargin > 1
               obj.WidthThreshold = WidthThreshold;
           end
           if nargin > 0 
               obj.AmpThreshold = AmpThreshold;
           end
           
        end
    
        function obj = Detect(obj, data, baseline)
            %the peak detection method
            %INPUT:
            % data - a real valued vector in which to search for peaks
            %
            %OPTIONAL
            %   baseline - the value to remove from all samples in the
            %   vector before searching,  If baseline is excluded the
            %   median of the data will be used
            %
tic
            if nargin < 3
                baseline = median(data);
            end

            needsIndexCorrection = false;

           %combine with the previous input chunk if the search across flag
           %is set and if this is not the first chunk
            if isempty(obj.Buffer) || ~obj.SearchAcrossChunks
                tempBuffer = data;
            else
                %combine the last part of the data that could not be
                %evaluated on the last run to make sure no peaks are missed
                indx = length(obj.Buffer) - 2 * obj.WidthThreshold;
                tempBuffer = horizcat(obj.Buffer(indx:end), data);
                needsIndexCorrection = true;
            end
            %set the object buffer to store the current data in case it
            %needs to be combined with the next chunk
            obj.Buffer = data;
            
            %remove the baseline from the data
            tempBuffer = tempBuffer - baseline;

            %adjust the threshold by the same amount
            actualThreshold = obj.AmpThreshold - baseline;


            %smooth the data if  smoothpoints is not set to zero
            if obj.SmoothPoints > 0
                [origMax, mIndx] = max(abs(tempBuffer));
                tempBuffer = smoothdata(tempBuffer, 1, "movmean", obj.SmoothPoints);
                if obj.AdjustThreshold 
                    newMax = abs(tempBuffer(mIndx));
                    adjRatio = newMax/origMax;
                    actualThreshold = actualThreshold * adjRatio;
                end
            end

            %find any peaks
            obj.Peaks = obj.findPeaks(tempBuffer,actualThreshold, obj.WidthThreshold, needsIndexCorrection);
toc
        end
 
    end
    methods (Access = private)
            function peaks = findPeaks(obj, input, ampThresh, widthThresh, needsCorrection)
        
            %to find the peaks we will loop over all values that exceed the
            %threshold and determine if there is a value within the width 
            % threshold distance that is greater. If not we have found a
            % peak
            

            absInput = abs(input);

            minPosition = widthThresh;
            maxPosition = length(absInput) - widthThresh;
       
            peakCount = 0;
            peaks = [];
            
            %initialize a counter for where to look in the possible peak
            %indexes array (ppi)
            ii = minPosition;

            while ii < maxPosition
         
                if absInput(ii) < ampThresh
                    ii = ii + 1;
                    continue;
                end

                %define a search window around the current point
                searchPoints = ii-widthThresh:ii+widthThresh;

                %look for the maximum value in that region
                [~, indx] = max(absInput(searchPoints));
                indx = indx + min(searchPoints) -1;
                %if the current point is the maximum then it is a peak
                if indx == ii
                    peakCount = peakCount + 1;
                    if needsCorrection
                        peaks(peakCount).index = ii - 2 * widthThreshold;
                    else
                        peaks(peakCount).index = ii;
                    end
                    peaks(peakCount).value = input(ii);
                    ii = ii + widthThresh;
                else
                    %if the current point is not the maximum, move the
                    %maximum point and try again
                    if indx > ii
                        ii = indx;
                    else 
                        ii = ii + 1;
                    end
                end
                
            end

        end
    end
end
