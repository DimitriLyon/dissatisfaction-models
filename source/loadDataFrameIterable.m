% loadDataFrame.m
% Loads data for frame-level models.

featureSpec = getfeaturespec('./source/mono.fss');

tracklistDirectory = 'tracklists-frame/';

tracklistTrainFrame = gettracklist(append(tracklistDirectory,'train.tl'));
tracklistDevFrame = gettracklist(append(tracklistDirectory,'dev.tl'));
tracklistTestFrame = gettracklist(append(tracklistDirectory,'test.tl'));

    
    % compute train data
    [XtrainFrame, yTrainFrame, trackNumsTrainFrame, ...
        utterNumsTrainFrame, frameTimesTrainFrame] = ...
        getXYfromTrackListIterable(tracklistTrainFrame, featureSpec, silenceSpeakRatio);
    
    % compute dev data
    [XdevFrame, yDevFrame, trackNumsDevFrame, ...
        utterNumsDevFrame, frameTimesDevFrame] = ...
        getXYfromTrackListIterable(tracklistDevFrame, featureSpec, silenceSpeakRatio);

    % compute test data
    [XtestFrame, yTestFrame, trackNumsTestFrame, ...
        utterNumsTestFrame, frameTimesTestFrame] = ...
        getXYfromTrackListIterable(tracklistTestFrame, featureSpec, silenceSpeakRatio);

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
            idxToDrop = randsample(idxDissatisfied, numDifference);
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

    % normalize dev and test data using the same centering values and scaling 
    % values used to normalize the train data
    XdevFrame = normalizeMod(XdevFrame, 'center', centeringValuesFrame, ...
        'scale', scalingValuesFrame);
    XtestFrame = normalizeMod(XtestFrame, 'center', centeringValuesFrame, ...
        'scale', scalingValuesFrame);

    %% save variables
    %save(append(dataDir, '/train.mat'), 'XtrainFrame', ...
    %    'yTrainFrame', 'trackNumsTrainFrame', ...
    %    'utterNumsTrainFrame', 'frameTimesTrainFrame');
    %save(append(dataDir, '/dev.mat'), 'XdevFrame', ...
    %    'yDevFrame', 'trackNumsDevFrame', ...
    %    'utterNumsDevFrame', 'frameTimesDevFrame');
    %save(append(dataDir, '/test.mat'), 'XtestFrame', ...
    %    'yTestFrame', 'trackNumsTestFrame', ...
    %    'utterNumsTestFrame', 'frameTimesTestFrame');

% clear unnecessary variables here