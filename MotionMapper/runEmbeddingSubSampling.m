function [trainingSetData,trainingSetAmps,projectionFiles] = ...
            runEmbeddingSubSampling(data,parameters)
%runEmbeddingSubSampling generates a training set given a set of .mat files
%
%   Input variables:
%
%       data -> spectralgram
%       parameters -> struct containing non-default choices for parameters
%
%
%   Output variables:
%
%       trainingSetData -> normalized wavelet training set 
%                           (N x (pcaModes*numPeriods) )
%       trainingSetAmps -> Nx1 array of training set wavelet amplitudes
%       projectionFiles -> cell array of files in 'projectionDirectory'
%
%
% (C) Gordon J. Berman, 2014
%     Princeton University
    
%     addpath(genpath('./utilities/'));
%     addpath(genpath('./t_sne/'));
    
    if nargin < 2
        parameters = [];
    end
    parameters = setRunParameters(parameters);
    
    
%     if matlabpool('size') ~= parameters.numProcessors;
%         matlabpool close force
%         if parameters.numProcessors > 1
%             matlabpool(parameters.numProcessors);
%         end
%     end
    
    
    
%     projectionFiles = findAllImagesInFolders(projectionDirectory,'.mat');
    
    N = parameters.trainingSetSize;
    iterations = 10;
    numPerDataSet = round(N/iterations);
%     numModes = parameters.pcaModes;
%     numPeriods = parameters.numPeriods;
     
    trainingSetData = zeros(numPerDataSet*iterations,size(data,2));
    trainingSetAmps = zeros(numPerDataSet*iterations,1);
    
%     data = vertcat(Spectra{:});
%     amps = sum(data,2);
%     data(:) = bsxfun(@rdivide,data,amps);

    skipLength = round(length(data(:,1))/parameters.trainingSetSize);

    trainingSetData = data(skipLength:skipLength:end,:);

    trainingKey = 1:size(data,1);
    trainingKey = trainingKey(skipLength:skipLength:end);


    for i=1:iterations
        fprintf(1,['Finding training set contributions from data set #' ...
            num2str(i) '\n']);
        
        currentIdx = (1:numPerDataSet) + (i-1)*numPerDataSet;
        
        [yData,signalData,signalAmps,~] = ...
                file_embeddingSubSampling(projectionFiles{i},parameters);
            
        [trainingSetData(currentIdx,:),trainingSetAmps(currentIdx)] = ...
            findTemplatesFromData(signalData,yData,signalAmps,...
                                numPerDataSet,parameters);

    end
    
    
    
%     if parameters.numProcessors > 1  && parameters.closeMatPool
%         matlabpool close
%     end