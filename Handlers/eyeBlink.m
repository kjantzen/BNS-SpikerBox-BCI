%Generic data handler template
function outStruct = eyeBlink(inStruct, varargin)
    if nargin == 1
        outStruct = initialize(inStruct);
    else
        outStruct = analyze(inStruct, varargin{1}, varargin{2});
    end
end
%%
%this function gets called when data is passed to the handler
function p = analyze(p,data, event)
    
    %erase any digital triggers that may be in the event vector
    event(1:end) = 0;
    
    %smooth the data and remove the baseline
    data = smoothdata(data, 2, 'movmean', 10);
    data = data - .65;
    
    
    %detect the peaks 
    p.PeakDetect = p.PeakDetect.Detect(data, 0);
    
    if ~isempty(p.PeakDetect.Peaks)
    
        %loop through each peak
        for ii = 1:length(p.PeakDetect.Peaks)
    
            %get the direction of the peak - peak value and slope (not
            %available yet) may also be important for how to interpret the peak
            direction = sign(p,PeakDetect.Peaks(ii));
    
            %if the direction is negative we assume that is a look to the right
            if direction < 0
                if strcmp(p.BCI_State,'Left')  %if the current state is left, it will change to center
                    p.BCI_State = 'Center';
                else
                    p.BCI_State = 'Right';  %otherwise it will change to right
                end
            else % this is the other case when the movement is the the left
                if strcmp(p.BCI_State,'Right')  %if the current state is right, it moves to the center
                    p.BCI_State = 'Center';
                else
                    p.BCI_State = 'Left'; %otherwise it becomes left
                end
            end
           p.handles.knob.Value = p.BCI_State; %update the knob
           drawnow;
    
           if p.PeakDetect.Peaks(ii).index > 0
               event(p.PeakDetect.Peaks(ii).index) = sign(p.PeakDetect.Peaks(ii).adjvalue);
           end
    
        end
    
    end
    p.Chart =  p.Chart.UpdateChart(data, event, [-1, 1]);



end
%% THIS FUNCTION IS CALLED WHEN INITIALIZING THE BCI
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
    p.BCI_State = 'Center';
    p.handles.knob.Value = p.BCI_State;

end
