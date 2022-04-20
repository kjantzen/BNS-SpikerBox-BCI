function [EEG, Event] = BYB_UnpackData(data)

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