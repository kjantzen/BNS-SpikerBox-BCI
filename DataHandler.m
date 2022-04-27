function p = DataHandler(p,data, event)

        data = data - mean(data);
        p.chartPlot1 = p.chartPlot1.UpdateChart(data);  
        p.fftPlot1 = p.fftPlot1.updateChart(data, [0,100]);

        data = p.filter.filter(data);
        p.chartPlot2 = p.chartPlot2.UpdateChart(data);
        p.fftPlot2 = p.fftPlot2.updateChart(data, [0,100]);
        
    
        data = data.^2;
        data = p.lpfilt.filter(data);
        p.chartPlot3 = p.chartPlot3.UpdateChart(data);
        p.barplot.Value = (mean(data)); 


end