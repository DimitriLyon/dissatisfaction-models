% linearRegressionFrame.m
% A frame-level linear regression model.

% configuration
useTestSet = true; % to set the "compare" set as either the dev or test set
beta = 0.25; % to calculate F-score

loadDataFrame;

% depending on useTestSet, the "compare" set is either the dev or test set
if useTestSet
    XcompareFrame = XtestFrame; %#ok<*UNRCH>
    yCompareFrame = yTestFrame;
    trackNumsCompareFrame = trackNumsTestFrame;
    tracklistCompareFrame = tracklistTestFrame;
    frameTimesCompareFrame = frameTimesTestFrame;
    utterNumsCompareFrame = utterNumsTestFrame;
else
    XcompareFrame = XdevFrame;
    yCompareFrame = yDevFrame;
    trackNumsCompareFrame = trackNumsDevFrame;
    tracklistCompareFrame = tracklistDevFrame;
    frameTimesCompareFrame = frameTimesDevFrame;
    utterNumsCompareFrame = utterNumsDevFrame;
end

disp(length(yCompareFrame));

%% cull data
%  take only 1/1000 of frames

rng(20210419);
trainLength = length(yTrainFrame);
trainCullSize = floor(trainLength / 100);

trainIndices = randsample(trainLength, trainCullSize);
XtrainFrame = XtrainFrame(trainIndices,:);
yTrainFrame = yTrainFrame(trainIndices,:);

compareLength = length(yCompareFrame);
compareCullSize = floor(compareLength/100);
disp(compareLength);
disp(compareCullSize);
compareIndices = randsample(compareLength, compareCullSize);
XcompareFrame = XcompareFrame(compareIndices, :);
yCompareFrame = yCompareFrame(compareIndices, :);


%% train regressor
knnModel = fitcknn(XtrainFrame, yTrainFrame, 'Distance', 'euclidean', ...
    'NSMethod', 'exhaustive', 'NumNeighbors', 1);



%%  predict on the compare set
yPred = predict(knnModel, XcompareFrame);

% the baseline always predicts dissatisfied (assume 1 for dissatisfied)
yBaseline = ones(size(yPred));

%% try different dissatisfaction thresholds to find the best F-score
mse = @(actual, pred) (mean((actual - pred) .^ 2));


predMSE = mse(yPred, yCompareFrame);
[score, precision, recall] = fScore(yCompareFrame, ...
        yPred, 1, 0, beta);
% print yPred stats
fprintf('min(yPred)=%.2f, max(yPred)=%.2f, mean(yPred)=%.2f\n', ...
    min(yPred), max(yPred), mean(yPred));



% print regressor stats

fprintf('regressorFscore=%.2f, regressorPrecision=%.2f, regressorRecall=%.2f, regressorMSE=%.2f\n', ...
    score, precision, recall, predMSE);

% print baseline stats

baselineMSE = mse(yBaseline, yCompareFrame);
[baselineFscore, baselinePrecision, baselineRecall] = ...
    fScore(yCompareFrame, yBaseline, 1, 0, beta);
fprintf('baselineFscore=%.2f, baselinePrecision=%.2f, baselineRecall=%.2f, baselineMSE=%.2f\n', ...
    baselineFscore, baselinePrecision, baselineRecall, baselineMSE);

%% failure analysis

% configuration
clipSizeSeconds = 6;
nClipsToCreatePerDirection = 30;
ignoreSizeSeconds = 2;

yDifference = abs(yCompareFrame - yPred);

sortDirections = ["descend" "ascend"];
for sortDirNum = 1:size(sortDirections, 2)
    
    % sort yDifference in sortDirection
    sortDirection = sortDirections(sortDirNum);    
    [~, sortIndex] = sort(yDifference, sortDirection);
    
    % create the directory for this direction's clips
    clipDir = sprintf('%s/failure-analysis/clips-%s', pwd, sortDirection);
    [status, msg, msgID] = mkdir(clipDir);
    
    % create an output file to write clip details to
    outputFilename = append(clipDir, '/clip-details.txt');
    fileID = fopen(outputFilename, 'w');
    
    % write sort direction to file
    fprintf(fileID, 'sortDirection=%s\n\n', sortDirection);

    framesToIgnore = zeros(size(yDifference));
    
    % create clips until numClipsCreated is reached or 
    % all frames have been probed
    numClipsCreated = 0;
    for i = 1:length(sortIndex)
        
        if numClipsCreated >= nClipsToCreatePerDirection
            break;
        end

        frameNumToProbe = sortIndex(i);

        % ignore this frame if it has already been included in a clip
        % (within ignoreSizeSeconds of an existing clip)
        if framesToIgnore(frameNumToProbe)
            continue;
        end
        
        frameTime = frameTimesCompareFrame(frameNumToProbe);
        
        trackNum = trackNumsCompareFrame(frameNumToProbe);
        track = tracklistCompareFrame{trackNum};
        [audioData, sampleRate] = audioread(track.filename);
        
        %Set up variable to get the proper audio channel
        if track.side == 'r'
            audioChannelNum = 2;
        else
            audioChannelNum = 1;
        end

        % write the clip to file, clipSizeSeconds with probing frame in the
        % middle
        timeStart = frameTime - (clipSizeSeconds/2);
        timeEnd = frameTime + (clipSizeSeconds/2);
        %Bandaid fix, if a clip starts before the audio, move clip over
        if timeStart <= 0
            timeStart = 0.001;
            timeEnd = clipSizeSeconds;
        end
        idxStart = round(seconds(seconds(timeStart) * sampleRate));
        idxEnd = round(seconds(seconds(timeEnd) * sampleRate));
        if idxEnd > size(audioData,1)
            start_end_diff = idxEnd - size(audioData,1);
            idxEnd = idxEnd - start_end_diff;
            idxStart = idxStart - start_end_diff;
        end
        newFilename = sprintf('%s\\clip%d-%dseconds.wav', clipDir, ...
            frameNumToProbe, clipSizeSeconds);
        clipData = audioData(idxStart:idxEnd, audioChannelNum).';
        audiowrite(newFilename, clipData, sampleRate);

        fprintf(fileID, 'clip%d  timeSeconds=%.2f  filename=%s  side=%s\n', ...
            frameNumToProbe, frameTime, track.filename, track.side);
        fprintf(fileID, '\tpredicted=%.2f  actual=%.2f\n', ...
            yPred(frameNumToProbe), yCompareFrame(frameNumToProbe));
        
        numClipsCreated = numClipsCreated + 1;

        % zero out the 
        % check if any other frame number is within this frame's utterance
        % monster frames are 10ms
        clipSizeFrames = seconds(ignoreSizeSeconds) / milliseconds(10);
        frameNumCompareStart = frameNumToProbe - clipSizeFrames / 2;
        frameNumCompareEnd = frameNumToProbe + clipSizeFrames / 2;
        
        % adjust compare start and compare end if out of bounds
        if frameNumCompareStart < 1
            frameNumCompareStart = 1;
        end
        if frameNumCompareEnd > length(yDifference)
            frameNumCompareEnd = length(yDifference);
        end

        for i = frameNumCompareStart:frameNumCompareEnd
            % if this frame is in the same track and utterance as the 
            % original, mark the frame to ignore it
            if trackNumsCompareFrame(i) ~= ...
                    trackNumsCompareFrame(frameNumToProbe)
                continue;
            end
            if utterNumsCompareFrame(i) ~= ...
                    utterNumsCompareFrame(frameNumToProbe)
                continue;
            end
            framesToIgnore(i) = 1;
        end
    end
    
    fclose(fileID);
    fprintf('Output written to %s\n', outputFilename);
end