%%  this is the main function that collects data and impliments the analysis stream
function runBCI(p)

    p.serialPort.ReadAsyncMode = 'continuous';
    %write the start collection string to the Arduino
    %the parameters appear to be mute since the sample rate does not change
    %and there is only one channel on the device anyway, but we will keep
    %them since this is sample code from BYB
    fprintf(p.serialPort,'conf s:%i;c:2;\n', p.sampleRate);%this will initiate sampling on Arduino
    fprintf('sampling started...\n');
 
    p.packets = 0;
    
    %load the parameter data into a different variable (params versus the passed variable p)
    %just so we can get at the Collecting variable.
    params = p.handles.fig.UserData;

    tic
    while params.Collecting
   
        data = fread(p.serialPort)';
        toc
        tic
        p.packets = p.packets + 1;
      
        p.handles.collect_packets.Text = sprintf('%i',p.packets);
        p.handles.collect_time.Text = sprintf('%.2f sec', p.packets * p.bufferTime);

        data = BYB_UnpackData(data);
     
        p.chartPlot1 = p.chartPlot1.UpdateChart(data);  
        p.fftPlot1 = p.fftPlot1.updateChart(data, [0,100]);
        
        data = p.filter.filter(data);
        p.chartPlot2 = p.chartPlot2.UpdateChart(data);
        p.fftPlot2 = p.fftPlot2.updateChart(data, [0,100]);
        
        data = data - mean(data);
        data = data.^2;
        data = p.lpfilt.filter(data);
        p.chartPlot3 = p.chartPlot3.UpdateChart(data);
        
        p.barplot.Value = (mean(data)); 
        params = p.handles.fig.UserData;
        drawnow();
      
    end
    
    fclose(p.serialPort);
    delete(p.serialPort);
 

end
