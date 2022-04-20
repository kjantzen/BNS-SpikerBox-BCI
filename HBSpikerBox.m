classdef HBSpikerBox
    properties
        PortName   %the port for communicating with the spiker box
        InputBufferFilledCallback = [] %called when new data is recieved from the spiker box
        InputBufferDuration = .2 %length of the input buffer in seconds
        InputBufferSamples  %number of samples in the input buffer
        Collecting          %flag used to start and stop acquisition
    end
    properties (Access = private)
        SerialPort
    end
    properties (Constant = true)
        SampleRate = 1000;
    end

    methods
        function obj = HBSpikerBox(port, varargin)
        %The HBSPikerBox object controls communication with and acquisition from
        %the Backyardbrains Heart Brain SpikerBox.  This object will establish
        %communication with the SpikerBox over the serial port, acquire
        %data, store it in a circular buffer (at least is will eventually
        % see BYB_CircularBuffer) and return data frames to a user defined 
        % callback for further processing.
        %
        %USAGE:
        %
        %mySpikerBox = HBSPikerBox(port, inputbufferlength, callback) 
        %
        %Input parameters
        %   port - a string or character vector specifying the 
        %   communications port to which the SpikerBox is connected. E.g. "COM3"
        %
        %   inputbufferlength - a scalar specifying the length in seconds
        %   of the buffer that holds data from the SpikerBox.  
        %
        %   callback - the function to call everytime the input buffer is
        %   filled.  The frequency of this call should be approximately
        %   equal to the input buffer length.  The callback must accept the two
        %   input parameters signal, event.  Signal is the signal recorded
        %   from the electrode inputs.  Event is a record of the activity
        %   on the digital pins D9 and D11.  The length of each vector will
        %   equal the input buffer length * the sample rate (1000 Hz)
        %
        %Methods
        %   Start - starts collection 
        %   Stop  - stops collection
        %
        %Example - to communicate with a Heart Brain Spiker Box  connected to 
        %COM3 and send data in 200 ms chunks to a function called
        %plot_callback
        %
        %   mySpikerBox = HBSpikerBox('COM3', .2, @plot_callback)
        %   mySpikerBox.Start
        %
        %the callback function would have the following structure
        %
        %   function plot_callback(signal, event)
        %       
        %       t = [1:1:length(signal)]./1000  %create a time axis
        %       plot(t, signal) %plot the recorded signal against time
        %
        %   end
        %
            
            if nargin < 3
                obj.InputBufferFilledCallback = [];
            else
                if isa(varargin{2}, 'function_handle')
                    obj.InputBufferFilledCallback = varargin{2};
                else
                    warning('The InputBufferFilledCallback must be a function reference.  You passed a %s', class(varargin{2}));
                end
            end
            if nargin > 1
                if isnumeric(varargin{1})
                    obj.InputBufferDuration = varargin{1};
                else
                    warning('The Input Buffer Duration parameter must be nunberic.  You passed a %s.', class(varargin{1}));
                end
            end


            obj.InputBufferSamples = obj.InputBufferDuration * obj.SampleRate;
            obj.Collecting = false;
            obj = obj.setPort(port);
          
        end
        function obj = Start(obj)
            obj.SerialPort.flush
            obj.Collecting = true;
            configureCallback(obj.SerialPort,"byte",obj.InputBufferSamples * 3, @obj.readSerialCallback);
        end
        function obj = Stop(obj)
            obj.Collecting = false;
            configureCallback(obj.SerialPort,"off");
        end
        function delete(obj)
            delete(obj.SerialPort);  %make sure the serial port object is deleted

        end
 
    end
    methods (Access = private)
        %create the serial port object
         function obj = setPort(obj, portname)
        
            if ~any(contains(serialportlist, portname))
                error('The port %s was not found on this device.', portname);
            end
            
            delete(obj.SerialPort); %delete the old handle
            obj.PortName = portname;
            obj.SerialPort =  serialport(obj.PortName,230400);


            %configure the serialport to fire a callback when the expected
            %number of bytes are placed in the buffer. This is three times
            %the number of samples becaue each EEG sample is two bytes and
            %the digital line is a third byte
            %turn the callback off
            configureCallback(obj.SerialPort,"off");

                   
         end
         %read data from the serial port when the buffer is full
         function readSerialCallback(obj,src, evt)
         
             inputBytes = read(src, obj.InputBufferSamples, "int8");
             [InputBuffer, Events] = obj.UnpackData(inputBytes);

             %send the data to the callback
             if isa(obj.InputBufferFilledCallback, 'function_handle')
                 obj.InputBufferFilledCallback(InputBuffer, Events);
             end

         end
         %covert data from the input stream to samples
         function [EEG, Event] = UnpackData(obj, data)

             %convert the data packet to unsigned integers
             data = uint8(data);

             %the brain heart spiker box ads a text string at the beginning of the first
             %data package so we have to remove it dfirst
             ind = strfind(data, 'StartUp!');
             if ~isempty(ind)
                 data = data(ind+10:end);%eliminate 'StartUp!' string with new line characters (8+2)
             end
             %unpacking data from frames
             EEG = [];
             Event = [];
             i=1;

             %loop through all the data and convert the two 8 bit values into a single
             %16 bit value
             while (i<length(data)-1)
                 if(uint8(data(i))>127)
                     %extract one sample from 2 bytes
                     %the first byte uses only the first 3 bits all
                     %onther bits should be zero except the MSB so we
                     %can mask with a bitand operaiton with 127 and then
                     %shift it up to MSB side by multiplying by 128
                     intout = uint16(uint16(bitand(uint8(data(i)),127)).*128);
                     i = i+1;
                     %the second byte uses 7 bits and the last will be
                     %zero so a straight addition here is good
                     intout = intout + uint16(uint8(data(i)));
                     EEG = [EEG intout];
                     i = i + 1;

                     intout = uint8(data(i)); %could use a mask here for only hte 3 lsb if we get noise on the channel
                     Event = [Event,intout];
                 end
                 i = i+1;
             end

             %return the new data chunk
             EEG = double(EEG);

         end
    end
end