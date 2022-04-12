classdef CircularBuffer
    properties
        EEGBuffer
        EventBuffer
        BufferLength
        EEGChunk
        EventChunk
        ChunkLength
        NextWriteIndex
        NextReadIndex
        UnreadChunks  %this is the number of chunks that have not been read out
        MaxChunks
        ErpLimits = [];
        ReturnERPTrial = false;
    end
    methods
        function obj = CircularBuffer(ChunkLength, varargin)
        %constructor method for creating an instance of the circular buffer class
        %
        %buffer = CircularBuffer(ChunkLength) will create a circular buffer
        %that will accept indivudal data packets containing ChunkLength samples 
        % and will have total length of 10 * ChunkLength samples.
        %
        %Note that ChunkLength refers to the number of samples in the buffer
        %and not the number of bytes.  Each sample will consist of 2 bytes
        %(2 for the 10 bit ADC value representing the EEG recording and 1 
        %for the 8 bit digital event marker).  So this ChunkLength should
        %be 1/3 the size of the buffer you use to read from the serial port
        %
        %buffer = CircularBuffer(ChunkLength, BufferLength) -  Creates a
        %buffer with BufferLength Points.  BufferLength should be several 
        %times longer than ChunkLength and should be long enough to contain
        %your ERP trial wihout overwriting.  For safety I suggest it should
        %be twice the length of your ERP.  If BufferLength is not a
        %multiple of ChunkLength it will be rounded up to the next multiple
        %
        %
            obj.ChunkLength = ChunkLength;
            if nargin < 2
                %default to a buffer length that is 10 times the length of
                %the individual data chunks
                obj.MaxChunks = 10;
            else
                %if a bufferlength is passed, make sure it is a multiple of
                %the chunklength
                obj.MaxChunks = ciel(varargin{1} / ChunkLength);
            end
            
            obj.BufferLength = ChunkLength * obj.MaxChunks;
            %initialize the buffer and write index
            obj.EEGBuffer = zeros(1,obj.BufferLength);
            obj.EventBuffer = uint8(zeros(1,obj.BufferLength));
            obj.NextWriteIndex = 1;
            obj.NextReadIndex = 1;
            obj.UnreadChunks = 0;
        end
        function obj = AddChunkToBuffer(obj,rawdata)
        %function for adding a new chunk of data to the circular buffer
            
            %use the internal function to convert the data to 16 bit
            [obj.EEGChunk, obj.EventChunk] = obj.unpack(rawdata);
            %sometimes there are bytes missing
            actualChunkLength = length(obj.Chunk);
            %add the chunk of data to the circular buffer
            obj.EEGBuffer(obj.NextWriteIndex:obj.NextWriteIndex + actualChunkLength-1) = obj.EEGChunk;
            obj.EventBuffer(obj.NextWriteIndex:obj.NextWriteIndex + actualChunkLength-1) = obj.EventChunk;
            %update the write index and wrap it around to 1 if it exceeds
            %the length of the buffer
            obj.NextWriteIndex = obj.NextWriteIndex + obj.ChunkLength;
            if obj.NextWriteIndex > obj.BufferLength
                obj.NextWriteIndex = 1;
            end
        
        end
      
        
    end
    methods (Access = private)
        function 
        function [EEG, event] = unpack(obj,data)
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
            event = [];
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
                        event = [event,intout];
                    end
                    i = i+1;
             end
          
            %return the new data chunk
            EEG = double(EEG);
        end
    
    end
    
end
