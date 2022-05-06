%Generic data handler template
function outStruct = eyeBlink(inStruct, varargin)
	if nargin == 1
		outStruct = initialize(inStruct);
	else
		outStruct = analyze(inStruct, varargin{1}, varargin{2});
	end
end
%this function gets called when data is passed to the handler
function p = analyze(p,data, event)
   
   peaks = zeros(size(data));
   data = data - .6;
 %  data = p.LPFilter.filter(data);
   p.PeakDetect = p.PeakDetect.Detect(data, 0);
   knobPosition = 'Center'; 
   if ~isempty(p.PeakDetect.Peaks)
       lastPeak = [];
   
       for ii = 1:length(p.PeakDetect.Peaks)
 
           if isempty(lastPeak) %this is the first peak
               lastPeak = p.PeakDetect.Peaks(ii);
           else
               if p.PeakDetect.Peaks(ii).index - lastPeak.index < 100
                   if sign(p.PeakDetect.Peaks(ii).adjvalue) ~= sign(lastPeak.adjvalue)
                       if sign(lastPeak.adjvalue) == 1
                           knobPosition = 'Left';
                       else
                           knobPosition = 'Right';
                       end
                   else
                       lastPeak = p.PeakDetect.Peaks(ii);
                   end
                   lastPeak = p.PeakDetect.Peaks(ii);
               end    
        

           end
           
           if p.PeakDetect.Peaks(ii).index > 0
            peaks(p.PeakDetect.Peaks(ii).index) = sign(p.PeakDetect.Peaks(ii).adjvalue);
           end

       end
       
    
   end
   p.handles.knob.Value = knobPosition;
    data = smoothdata(data, 2, 'movmean', 10);
    p.Chart =  p.Chart.UpdateChart(data, peaks, [-1, 1]);

   

end

%this function gets called when the analyse process is initialized
function p = initialize(p)

    existingFigure = findall(0,'Type', 'figure', 'Name', 'Example of an Eye Blink BCI');
    if ~isempty(existingFigure)
        p.handles.outputFigure = existingFigure(1);
        clf(p.handles.outputFigure);
    else
       %create a new figure to hold all the plots etc
        p.handles.outputFigure = uifigure('Position',[400,400,1000,600]);
        %name it so we can recognize it later if the software is rerun
        p.handles.outputFigure.Name  = 'Example of an Eye Blink BCI';
    end

    ax = uiaxes(p.handles.outputFigure, 'Position', [10,10,700,580]);
    ax.XLabel.String = 'Time (s)';
    ax.YLabel.String = 'Amplitude (mV)';
    ax.Title.String = 'Electrooculogram';
    p.Chart = BYB_Chart(p.sampleRate,5, ax);
    p.PeakDetect = BYB_Peaks(0.15, 10, 10, false, true);
    p.handles.knob = uiknob(p.handles.outputFigure, 'discrete','Position', [780, 50, 150, 200]);
    p.handles.knob.Items = {'Left','Center','Right'};
   
end
