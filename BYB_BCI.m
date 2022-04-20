function BYB_BCI()
%main function that loads the parameters
%and builds the UI

    params = [];
    params = getParams(params);
    params.Collecting = false;
    params.handles = buildUI;
    set(params.handles.fig, 'UserData', params);
    addPaths
    

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
   %high pass filtering, but will speed up the refresh rate of your BCI
   %try to keep this value at or above 200 ms (.2).  Depending on the
   %amount of plotting you are doing, it will not be able to keep up with
   %faster speeds
   p.bufferTime = .2; 
   
   %THE FOLLOWING PARAMETERS SHOULD NOT BE CHANGED
    %sample rate is set by the EEG box and cannot be changed externally
    p.channels = 1;
    p.sampleRate = 1000 / p.channels;
    p.serialPort = []; %this is a placeholder and will hold the port address once we open it
    %this is the size of the buffer in points and is calculated from
    %previosuly set values
   %p.bufferPnts = p.bufferTime * p.sampleRate * 2;
    p.bufferPnts = p.bufferTime * p.sampleRate * 3; %this allows for including the digital trigger byte

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

    h.menu_config = uimenu('Configure');
    h.menu_port = uimenu('Parent', 'h.menu_config', 'Text', 'Port');
    h.menu_chunk = uimenu('Parent', 'h.menu_config', 'Text', 'Packet Length');
    

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
    params = initializeSerialCommunication(params);
    params = initializeProcessing(params);
    params.handles.fig.UserData = params;
    
    runBCI(params);
    
    
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
function p = initializeSerialCommunication(p)

    %clear out any open serial ports
    x = instrfind;
    delete(x);
    clear x;
    
    p = getParams(p);
    %set up communication with the adruino
    p.serialPort  = serial(p.serialPortName);%change this to your com port
    set(p.serialPort,'BaudRate',230400);
    p.serialPort.InputBufferSize = p.bufferPnts;  %multiply by 3 because each sample is two bytes and the digial trigger is 1
    p.serialPort.Terminator = '';

    %open the port and make sure it worked
    fopen(p.serialPort);
    fprintf('The status of communications is %s\n',p.serialPort.Status);

    
end
function addPaths()

 thisPath = mfilename('fullpath');
 indx = strfind(thisPath, filesep);
 thisPath = thisPath(1:max(indx)-1);
 
 extensionsPath  = fullfile(thisPath, 'Extensions');
 pathCell = strsplit(path, pathsep);
 if ispc  % Windows is not case-sensitive
  onPath = any(strcmpi(extensionsPath, pathCell));
else
  onPath = any(strcmp(extensionsPath, pathCell));
 end
if ~onPath
    addpath(extensionsPath)
end
 

end

