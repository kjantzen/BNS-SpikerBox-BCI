function result = BYB_UnpackData(data)

%convert the data packet to unsigned integers
data = uint8(data);

%the brain heart spiker box ads a text string at the beginning of the first
%data package so we have to remove it dfirst
ind = strfind(data, 'StartUp!');
if ~isempty(ind)
    data = data(ind+10:end);%eliminate 'StartUp!' string with new line characters (8+2)
end
%fprintf('size of data chunk is %i\n', length(data));

%unpacking data from frames
result = [];
i=1;

%loop through all the data and convert the two 8 bit values into a single
%16 bit value
while (i<length(data)-1)
        if(uint8(data(i))>127)
            %extract one sample from 2 bytes
            intout = uint16(uint16(bitand(uint8(data(i)),127)).*128);
            i = i+1;
            intout = intout + uint16(uint8(data(i)));
            result = [result intout];

            i=i+1;
            bitmask = uint16(data(i));
            
        end
        i = i+1;
end

%return the new data chunk
result = double(result);
end