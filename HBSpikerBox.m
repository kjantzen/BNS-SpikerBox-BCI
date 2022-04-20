classdef HBSpikerBox
    properties
        PortName   %the port for communicating with the spiker box
        
        InputBufferFilledCallback = [] %called when new data is recieved from the spiker box
        SampleRate = 500;   %not changeable for now
        InputBufferDuration = .2 %length of the input buffer in seconds
        InputBufferSamples  %number of samples in the input buffer
        Collecting          %flag used to start and stop acquisition
    end
    properties (Access = private)
        InputBuffer
        SerialPort
    end

    methods
        function obj = HBSpikerBox(port, varargin)
            %The HBSPikerBox object controls communication with and acquisition from
            %the Backyarbrains Heart Brain SpikerBox.  The object will establish
            %communication with the SpikerBox over the serial port, acquire
            %data, store it in a circular buffer (see BYB_CircularBuffer)
            %and return data frames to a user defined callback for further
            %processing.
            %
            %USAGE:
            %
            %mySpikerBox = HBSpikerBox(port) - creates a new HBSpikerBox
            %object that communicates over port which can be any of port of
            %the form 'comx' where x is the port number.
            %
            %mySpikerBox = HBSpikerBox(port, ibd) - sets the input buffer
            %duration to the number specified in ibd.  The default is 0.2.
            %
            %mySpikerBox = HBSPikerBox(port, ibd, callback) - will call the
            %callback function whenever data is recieved from the
            %SpikerBox.  The new data will be passed to the callback.  I am
            %still working out the specific input parameters the callback 
            % will requireshould recieve
            %
            %
            
        end
 
    end
    methods (Access = private)
         function obj = setPort(obj, portname)
        
            if ~any(contains(serialportlist, portname))
                error('The port %s was not found on this device.', portname);
            end
            if isvalid(obj.SerialPort)  %if there is already a valid serial port object
                if strcmpi(obj.SerialPort.Port, portname)
                    return %do nothing if the port is the same
                end
                delete(obj.SerialPort); %delete the old handle
            end

            obj.PortName = portname;
            obj.SerialPort =  serialport(Obj.PortName,230400);
                   
         end
         function serialCallback(src, evt)
         
             inputBytes = read(src, )
         end


    end
end