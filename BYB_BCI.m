function BYB_BCI()
%main function that loads the parameters
%and builds the UI

    makeNewDataHandlerFromTemplate('test3')
    addPaths
    p.handles = buildUI;
    set(p.handles.fig, 'UserData', p);
   
    
end
%
function p = initializeParameters(p)
    %call this function whenever some key parameters list below changes

    %hard code these for now, but give the option to select them from a
    %user interface later
    
    ports = serialportlist;

    p.serialPortName = ports(1);
    p.bufferDuration = 0.25;
    p.sampleRate = 1000;

    %also hard code the two functions for initializing the data processing
    %and for handling the data stream.  These also could be selectable
    %using the interface
    p.DataHandler = eval('@sampleDataHandler');

    %create the spiker box object here
    %first delete any existing one that may exist
    if isfield(p, 'SpikerBox')
        delete(p.SpikerBox);
    end
    p.SpikerBox = HBSpikerBox(p.serialPortName, p.bufferDuration, p.DataHandler);

    %call the initialization version of the data handler, i.e. call it
    %without passing any data.
    p.SpikerBox.ProcessObjects = p.DataHandler(p);
     


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

    h.menu_config = uimenu('Parent',h.fig,'Text','Configure');
    h.menu_port = uimenu('Parent', h.menu_config, 'Text', 'Port');
    h.menu_chunk = uimenu('Parent', h.menu_config, 'Text', 'Buffer Length');
    

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
        'Text','Initialize Acquisition',...
        'ButtonPushedFcn',@callback_initButton);

    h.button_start = uibutton('Parent', h.fig,...
        'Position', [10,60,160,40],...
        'BackgroundColor',[.1,.8,.1],...
        'Text','Start Acquisition',...
        'ButtonPushedFcn',@callback_startButton);
    
     h.button_stop = uibutton('Parent', h.fig,...
        'Position', [10,10,160,40],...
        'BackgroundColor',[.8,.1,.1],...
        'FontColor', 'w',...
        'Text','Stop Acquisition',...
        'ButtonPushedFcn',@callback_stopButton);
   

end
function callback_initButton(src, ~)
    %get the handle to the figure
    fig = ancestor(src, 'figure', 'toplevel');

    %get the data structure from the figures user data
    p = fig.UserData;
    p = initializeParameters(p);  
    
    p.handles.button_start.Enable = 'on';

    %enable the stop button
    p.handles.button_stop.Enable = 'off';
    p.handles.collect_status.Text = 'Ready to Collect';
    p.handles.collect_status.FontColor = [0,.5,0];

    %update the display
    drawnow;

    %save the data back to the figures user data
    fig.UserData = p;


end
function callback_startButton(src,~)
 
    %get the handle to the figure
    fig = ancestor(src, 'figure', 'toplevel');

    %get the data structure from the figures user data
    p = fig.UserData;

    %disable this button since we are toggling states
    src.Enable = 'off';
    p.handles.button_init.Enable = 'off';

    %enable the stop button
    p.handles.button_stop.Enable = 'on';
    p.handles.collect_status.Text = 'Collecting...';
    p.handles.collect_status.FontColor = [0,.5,0];

    %update the display
    drawnow;

    %turn on acquisition in the SpikerBox object
    p.SpikerBox = p.SpikerBox.Start();

    %save the data back to the figures user data
    fig.UserData = p;

    
end
function callback_stopButton(src,~)
 
    %get a handle to the figure
    fig = ancestor(src, 'figure', 'toplevel');

    %get all the stored data from the figures user data storage
    p = fig.UserData;

    %toggle the state of this button to off
    src.Enable = 'off';

    %turn on the start button
    p.handles.button_start.Enable = 'on';
    p.handles.button_init.Enable = 'on';
    p.handles.collect_status.Text = 'Collection stopped';
    p.handles.collect_status.FontColor = 'r';

    %stop the data collection process
    p.SpikerBox = p.SpikerBox.Stop();

    %update the display
    drawnow();
    
    %save the data again
    fig.UserData = p;
    
end
%%
function addPaths()

 thisPath = mfilename('fullpath');
 indx = strfind(thisPath, filesep);
 thisPath = thisPath(1:max(indx)-1);
 
 newFolder{1}  = fullfile(thisPath, 'Extensions');
 newFolder{2}  = fullfile(thisPath, 'Handlers');
 
 pathCell = strsplit(path, pathsep);
 for ii = 1:length(newFolder)
     if ispc  % Windows is not case-sensitive
      onPath = any(strcmpi(newFolder{ii}, pathCell));
    else
      onPath = any(strcmp(newFolder{ii}, pathCell));
     end
    if ~onPath
        addpath(newFolder{ii})
    end
 end
 

end
%%
function makeNewDataHandlerFromTemplate(scriptName)

scriptName = sprintf('%s.m', scriptName);

homePath = mfilename("fullpath");
[homePath,~,~] = fileparts(homePath);
newFile = fullfile(homePath, 'Handlers', scriptName);
if ~isempty(dir(newFile))
    msgbox(sprintf('The handler file %s already exists.\n Please choose a different name.', scriptName));
    return
end
fid = fopen(newFile, 'wt');
  

fprintf(fid, '%%Generic data handler template\n\n');
fprintf(fid, 'function outStruct = sampleDataHandler(inStruct, varargin)\n');
fprintf(fid, '\tif nargin == 1\n');
fprintf(fid, '\t\toutSruct = initialize(inStruct);\n');
fprintf(fid, '\telse\n\t\toutStruct = analyze(p, varargin{1}, varargin{2});\n\tend\n\n');
fprintf(fid, '%%this function gets called when data is passed to the handler\n');
fprintf(fid, 'function p = analyze(p,data, event)\n\n\t%%your analysis code goes here\nend\n\n');
fprintf(fid, '%%this function gets called when the analyse process is initialized\n');
fprintf(fid, 'function p = initialize(p)\n%%your initialization code goes here\nend\n');

fclose(fid);
edit(newFile);

end

