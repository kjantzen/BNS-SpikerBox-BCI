%Generic data handler template

function outStruct = sampleDataHandler(inStruct, varargin)
	if nargin == 1
		outSruct = initialize(inStruct);
	else
		outStruct = analyze(p, varargin{1}, varargin{2});
	end

%this function gets called when data is passed to the handler
function p = analyze(p,data, event)

	%your analysis code goes here
end

%this function gets called when the analyse process is initialized
function p = initialize(p)
%your initialization code goes here
end
