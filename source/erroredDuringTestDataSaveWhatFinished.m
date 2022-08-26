%% Introduction
% Frankenstein's monster script to salvage the data from the test set (38 tracks!)
% does not call functions that would overwrite the data in the workspace.
%
%% part that initializes paths
% loadDataFrame.m
% Loads data for frame-level models.

dataDir = append(pwd, '/data/frame-level');

featureSpec = getfeaturespec('./source/mono.fss');

tracklistTrainFrame = gettracklist('tracklists-frame/train.tl');
tracklistDevFrame = gettracklist('tracklists-frame/dev.tl');
tracklistTestFrame = gettracklist('tracklists-frame/test.tl');

    %% balance train data
    rng(20210419); % set seed for reproducibility

    idxNeutral = find(yTrainFrame == 0); % assume 0 for neutral
    idxDissatisfied = find(yTrainFrame == 1); % assume 1 for dissatisfied

    numNeutral = length(idxNeutral);
    numDissatisfied = length(idxDissatisfied);
    numDifference = abs(numNeutral - numDissatisfied);

    if numDifference
        if numNeutral > numDissatisfied
            idxToDrop = randsample(idxNeutral, numDifference);
        elseif numDissatisfied > numNeutral
            idxToDrop = randsample(numDissatisfied, numDifference);
        end
        trackNumsTrainFrame(idxToDrop) = [];
        utterNumsTrainFrame(idxToDrop) = [];
        XtrainFrame(idxToDrop, :) = [];
        yTrainFrame(idxToDrop) = [];
    end
    %% normalize
    % normalize training data
    [XtrainFrame, centeringValuesFrame, scalingValuesFrame] = ...
        normalizeMod(XtrainFrame);

    % normalize dev data using the same centering values and scaling 
    % values used to normalize the train data
    XdevFrame = normalizeMod(XdevFrame, 'center', centeringValuesFrame, ...
        'scale', scalingValuesFrame);
    %% save variables
    save(append(dataDir, '/train.mat'), 'XtrainFrame', ...
        'yTrainFrame', 'trackNumsTrainFrame', ...
        'utterNumsTrainFrame', 'frameTimesTrainFrame');
    save(append(dataDir, '/dev.mat'), 'XdevFrame', ...
        'yDevFrame', 'trackNumsDevFrame', ...
        'utterNumsDevFrame', 'frameTimesDevFrame');