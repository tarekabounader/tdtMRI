function [params,stimulus] = tonotopyPeriodotopyFilterBW(params,NEpochsPerRun,stimTR,TR)

% stimulus = struct array with fields:    
    %frequency (kHz)
    %bandwidth 
    %amFrequency (Hz)
    %level (dB)
    %duration (ms)  
    %name
    %number


%default parameters: these are the parameters that will appear in the main
%window and can be changed between runs (the first few anyway)
if isNotDefined('params')
  params = struct;
end
if fieldIsNotDefined(params,'nFrequencies')
  params.nFrequencies = 5; 
end
if fieldIsNotDefined(params,'lowFrequency')
  params.lowFrequency = .25;
end
if fieldIsNotDefined(params,'highFrequency')
  params.highFrequency = 6;
end
if fieldIsNotDefined(params,'nAMfrequencies')
  params.nAMfrequencies = 5; 
end
if fieldIsNotDefined(params,'lowAMfrequency')
  params.lowAMfrequency = 2;
end
if fieldIsNotDefined(params,'highAMfrequency')
  params.highAMfrequency = 40;
end
if fieldIsNotDefined(params,'onset')
  params.onset = 2500;
end
if fieldIsNotDefined(params,'bandwidthERB')
  params.bandwidthERB = 1;
end
if fieldIsNotDefined(params,'nPermute')
  params.nPermute = 14;  %number of events over which to randomly permute
end
if fieldIsNotDefined(params,'level')
  params.level = 70;
end

if nargout==1
  return;
end

%---------------- enumerate all different conditions

allFrequencies = lcfInvNErb(linspace(lcfNErb(params.lowFrequency),lcfNErb(params.highFrequency),params.nFrequencies));
lowCuttingFrequencies = lcfInvNErb(lcfNErb(allFrequencies)-params.bandwidthERB/2);
highCuttingFrequencies = lcfInvNErb(lcfNErb(allFrequencies)+params.bandwidthERB/2);
allFrequencies = (lowCuttingFrequencies+highCuttingFrequencies)/2;
allBandwidths = (highCuttingFrequencies-lowCuttingFrequencies);

allAMFrequencies = exp(linspace(log(params.lowAMfrequency), log(params.highAMfrequency), params.nAMfrequencies));

% allFrequencies = repmat(allFrequencies,[1 params.nAMfrequencies]);
% allBandwidths = repmat(allBandwidths,[1 params.nAMfrequencies]);
% allAMFrequencies = repmat(allAMFrequencies, [params.nFrequencies 1]);
% allAMFrequencies = allAMFrequencies(:)';

% for i=1:params.nFrequencies*params.nAMfrequencies+1
%   if i>params.nFrequencies*params.nAMfrequencies
for i=1:params.nFrequencies+params.nAMfrequencies+1
  if i>params.nFrequencies+params.nAMfrequencies
    stimulus(i).name = 'No stimulus';
    stimulus(i).bandwidth = NaN;
    stimulus(i).frequency = NaN;
    stimulus(i).amFrequency = NaN;
    stimulus(i).duration = stimTR;
    stimulus(i).level = NaN;
  elseif i>params.nFrequencies
    stimulus(i).name = sprintf('BB_AM%.1fHz',allAMFrequencies(i-params.nFrequencies));
    stimulus(i).bandwidth = [NaN Inf];
    stimulus(i).amFrequency = [NaN allAMFrequencies(i-params.nFrequencies)];
    stimulus(i).frequency = [NaN 0];
    stimulus(i).duration = [params.onset stimTR-params.onset];
    stimulus(i).level = [NaN params.level];
  else
%     stimulus(i).name = sprintf('%dHzAM%.1fHz',round(allFrequencies(i)*1000),allAMFrequencies(i));
    stimulus(i).name = sprintf('%dHzAM%.1fHz',round(allFrequencies(i)*1000),4);
    stimulus(i).bandwidth = [NaN allBandwidths(i)];
%     stimulus(i).amFrequency = [NaN allAMFrequencies(i)];
    stimulus(i).amFrequency = [NaN 4];
    stimulus(i).frequency = [NaN allFrequencies(i)];
    stimulus(i).duration = [params.onset stimTR-params.onset];
    stimulus(i).level = [NaN params.level];
  end
  stimulus(i).number = i;
end


%------------------------------------- sequence randomization
sequence = [];
for i = 1:NEpochsPerRun
  sequence = [sequence randperm(length(stimulus)-1)];
end    

sequence2 = [];
nPermute = 12; %length of sequence chunks to permute
nNulls = 2; %number of additional silences per chunks
for i = 1:floor(length(sequence)/nPermute)
  thisSequence = [sequence((i-1)*nPermute+1:i*nPermute) length(stimulus)*ones(1,nNulls)];
  sequence2 = [sequence2 thisSequence(randperm(nPermute+nNulls))];
end    

%---------------------------apply sequence to stimuli
stimulus = stimulus(sequence2);


function out = isNotDefined(name)

out = evalin('caller',['~exist(''' name ''',''var'')|| isempty(''' name ''')']);

function out = fieldIsNotDefined(structure,fieldname)

out = ~isfield(structure,fieldname) || isempty(structure.(fieldname));

% ********** lcfNErb **********
function nerb = lcfNErb(f)
  nerb = 21.4*log10(4.37*f+1);

% ***** lcfInvNErb *****
function f = lcfInvNErb(nerb)
  f = 1/4.37*(10.^(nerb/21.4)-1);


