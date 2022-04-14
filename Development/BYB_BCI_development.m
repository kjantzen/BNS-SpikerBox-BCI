function BYB_BCI()
%main function that loads the parameters
%and builds the UI

    params = [];
    params = getParams(params);
    params.Collecting = false;
    params.handles = buildUI;
    set(params.handles.fig, 'UserData', params);
    

end
%%  this is the main function that collects data and impliments the analysis stream
function runBCI(p)

    p.plotf = figure;
    p.plotax = axes(figure);
    
    p.circBuff = CircularBuffer(p.bufferTime * p.sampleRate);
    p.chart = BYB_chart(p.sampleRate, 3, p.plotax);
    
    p.serialPort.ReadAsyncMode = 'continuous';
    %write the start collection string to the Arduino
    %the parameters appear to be mute since the sample rate does not change
    %and there is only one channel on the device anyway, but we will keep
    %them since this is sample code from BYB
    commandStr = sprintf('conf s:10000;c:%i;\n', p.channels);
    fprintf(p.serialPort,commandStr);%this will initiate sampling on Arduino
    fprintf('sampling started...\n');
 
    p.packets = 0;
    
    %load the parameter data into a different variable (params versus the passed variable p)
    %just so we can get at the Collecting variable.
    params = p.handles.fig.UserData;
    while params.Collecting
   
        data = fread(p.serialPort)';
        p.packets = p.packets + 1;
        p.handles.collect_packets.Text = sprintf('%i',p.packets);
        p.handles.collect_time.Text = sprintf('%.2f sec', p.packets * p.bufferTime);
        drawnow();
        
        p.circBuff = p.circBuff.AddChunkToBuffer(data);
        p.chart.updateChart(p.circBuff.Chunk);
        
     %   data = p.circBuff.Chunk;
        
        
      %  data = BYB_unpackData(data);
      %  sample_offset =  rem(length(data), p.channels);
      %  if sample_offset > 0;
      %      data = data(1:end-sample_offset);
      %  end
            
      %  size(data)
      %  data = reshape(data, p.channels, length(data)/p.channels);
        
        %remove the mean of the chunk
     %  chunk_mean = mean(data,2);
     %  baseline = repmat(chunk_mean,1,length(data));
     %   data = data - baseline;
        
     %   p.chart_chan1 = p.chart_chan1.updateChart(data(1,:));  
     %   p.fftplot_chan1 = p.fftplot_chan1.updateChart(data(1,:), [0,100]);
     
     %   params = p.handles.fig.UserData;
        drawnow();
      
    end
    fclose(p.serialPort);
    delete(p.serialPort);
    clear s

end
%% load the stored parameters from disk
function p = getParams(p)
%sets teh default parameters
%for now just change the parameters you want to update and restart the
%program.

%these are the only two parameters that are changeable right now.

   p.serialPortName = 'COM3'; %the name of the port to configure
   %the size of the buffer to record from the device.  This is the length
   %in seconds of each chunck of data that is collected.  Longer chunks
   %will allow better data processing but will slow down your BCI and
   %shorter chunks will decrease the ability to do some operations like
   %high pass , but will speed up the refresh rate of your BCI
   p.bufferTime = .1;
   
   %THE FOLLOWING PARAMETERS SHOULD NOT BE CHANGED
    %sample rate is set by the EEG box and cannot be changed externally
    p.channels = 1;
    p.baseSampleRate = 10000;
    p.sampleRate = 10000 / p.channels;
    p.serialPort = []; %this is a placeholder and will hold the port address once we open it
    %this is the size of the buffer in points and is calculated from
    %previosuly set values
    p.bufferPnts = p.channels * p.bufferTime * p.baseSampleRate * 2;

end

%% function to create the simple user interface
function h = buildUI()
    

    sz = get(0, 'ScreenSize');
  
    %see if the figure already exists
    %if it does not create it and if it does clear it and start over
    existingFigureHandle = findall(0,'Name', 'BYB BCI');
     
    if ~isempty(existingFigureHandle) 
        close(existingFigureHandle(1));
    end
    
    h.fig = uifigure;
    h.fig.Position = [0,sz(4)-195,330,170];
    h.fig.Name = 'BYB BCI';

    h.panel_time = uipanel('Parent', h.fig, ...
        'Title', 'Duration',...
        'Units', 'pixels',...
        'Position', [180,10,140,40]);
 
    h.panel_packets = uipanel('Parent', h.fig, ...
        'Title', 'Packets Collected',...
        'Units', 'pixels',...
        'Position', [180,60,140,40]);
   
    %panel for the current acquisition status
    h.panel_status = uipanel('Parent', h.fig, ...
        'Title', 'Acquisition status',...
        'Units', 'pixels',...
        'Position', [180,110,140,40]);
    
    h.collect_status = uilabel('Parent', h.panel_status,...
        'Text', 'Collection Stopped',...
        'FontColor', 'r',...
        'Position', [0,0,140,20],...
        'HorizontalAlignment', 'center',...
        'VerticalAlignment', 'bottom');
    
    h.collect_packets = uilabel('Parent', h.panel_packets,...
        'Text', '0',...
        'FontColor', 'b',...
        'Position', [0,0, 140,20],...
        'HorizontalAlignment', 'center',...
        'VerticalAlignment', 'bottom');
  
    h.collect_time = uilabel('Parent', h.panel_time,...
        'Text', '0',...
        'FontColor', 'b',...
        'Position', [0,0,140,20],...
        'HorizontalAlignment', 'center',...
        'VerticalAlignment', 'bottom');
 
    
    h.button_start = uibutton('Parent', h.fig,...
        'Position', [10,110,160,40],...
        'BackgroundColor',[.1,.8,.1],...
        'Text','Start Acquisition',...
        'ButtonPushedFcn',@callback_startButton);
    
     h.button_stop = uibutton('Parent', h.fig,...
        'Position', [10,60,160,40],...
        'BackgroundColor',[.8,.1,.1],...
        'FontColor', 'w',...
        'Text','Stop Acquisition',...
        'ButtonPushedFcn',@callback_stopButton);
   

end
function callback_startButton(src,~)
 
    fig = ancestor(src, 'figure', 'toplevel');
    params = fig.UserData;
    params.Collecting = true;
    fig.UserData = params;
    src.Enable = 'off';
    params.handles.button_stop.Enable = 'on';
    params.handles.collect_status.Text = 'Collecting...';
    params.handles.collect_status.FontColor = [0,.5,0];
    drawnow;
    initializeCollection(params);
    
end
function callback_stopButton(src,~)
 
    fig = ancestor(src, 'figure', 'toplevel');
    params = fig.UserData;

    params.Collecting = false;
    fig.UserData = params;
    src.Enable = 'off';
    params.handles.button_start.Enable = 'on';
    params.handles.collect_status.Text = 'Collection stopped';
    params.handles.collect_status.FontColor = 'r';
    drawnow();
    
end
function initializeCollection(p)

    %clear out any open serial ports
    x = instrfind;
    delete(x);
    clear x;
    
    p = getParams(p);
    %set up communication with the adruino
    p.serialPort  = serial(p.serialPortName);%change this to your com port
    set(p.serialPort,'BaudRate',230400);
    p.serialPort.InputBufferSize = p.bufferPnts + 2;

    %open the port and make sure it worked
    fopen(p.serialPort);
    fprintf('The status of communications is %s\n',p.serialPort.Status);
    
%    p = initializeProcesses(p);
    
    runBCI(p);
    
end


