% logisticRegressionDialog.m
%% prepare the data used in the frame-level model
% to get 'normalizeCenteringValues' and 'normalizeScalingValues' to
% normalize the dialog-level data using the same values
prepareData;

% clear unecessary variables left over from the prepareData script
clear frameTimesCompare frameTimesTrain
clear frameTrackNumsCompare frameTrackNumsTrain
clear frameUtterNumsCompare frameUtterNumsTrain
clear numDifference
clear Xcompare Xtrain yCompare yTrain

%% predict on the train set and compare set to build their feature sets
trackListTrain = gettracklist('train-dialog.tl');
trackListCompare = gettracklist('dev-dialog.tl');
% trackListCompare = gettracklist('test-dialog.tl');

[XsummaryTrain, yActualTrain] = getSummaryXy(trackListTrain, ...
    normalizeCenteringValues, normalizeScalingValues);
[XsummaryCompare, yActualCompare] = getSummaryXy(trackListCompare, ...
    normalizeCenteringValues, normalizeScalingValues);

%% plot histograms for summary features
% for neutral versus dissatisfied dialogs in combined train and compare set

XsummaryCombined = [XsummaryTrain; XsummaryCompare];
yActualCombined = [yActualTrain yActualCompare];

% separate XsummaryCombined into XsummaryCombNeutral and XsummaryCombDiss
XsummaryCombNeutral = [];
XsummaryCombDiss = [];
for dialogNum = 1:length(yActualCombined)
    label = yActualCombined(dialogNum);
    if label == 0
        XsummaryCombNeutral = [XsummaryCombNeutral; XsummaryCombined(dialogNum, :)];
    elseif label == 1
        XsummaryCombDiss = [XsummaryCombDiss; XsummaryCombined(dialogNum, :)];
    else
        error('unexpected label');
    end
end

% plot a histogram for each summary feature
% NOTE: featureNames are hardcoded and need to match the order seen in the
% getSummaryXy function at the bottom of this script
featureNames = ["ratio" "min" "max" "average" "range" "std"];
nBins = 32;
barColorN = '#1e88e5'; 
barColorD = '#fb8c00';
imageDir = append(pwd, "\src\histograms-summary-features\");

mkdir(imageDir);

for featureNum = 1:length(featureNames)
    f = figure('Visible', 'off');
    
    % histogram for neutral
    hN = histogram(XsummaryCombNeutral(:, featureNum), nBins);
    hN.FaceColor = barColorN;
    
    hold on
   
    % histogram for dissatisfied
    hD = histogram(XsummaryCombDiss(:, featureNum), nBins);
    hD.FaceColor = barColorD;
    
    % normalize the histograms so that all bar heights add to 1
    hN.Normalization = 'probability';
    hD.Normalization = 'probability';
    
    % adjust bars so that both plots align
    hN.BinWidth = hD.BinWidth;
    hN.BinEdges = hD.BinEdges;
    
    % add titles, axes labels, and legend
    featureName = featureNames(featureNum);
    titleText = sprintf('feature %d (%s)', featureNum, featureName);
    subtitleText = sprintf('train and dev data, %d bins, normalized bars', nBins);
    title(titleText, subtitleText);
    ylabel('Number in bin');
    xlabel('Bin');
    legend('neutral','dissatisfied')
    
    % save image
    imageFilepath = append(imageDir, titleText, ".png");
    saveas(f, imageFilepath);
    fprintf('Saved image to %s\n', imageFilepath);
    
    clf;
end

%% train the second regressor
secondLinearRegressor = fitlm(XsummaryTrain, yActualTrain);

%% use the second regressor to predict on compare data
yPred = predict(secondLinearRegressor, XsummaryCompare);

% the baseline always predicts dissatisfied (1 for positive class)
yBaseline = ones(size(yPred));

mse = @(actual, pred) (mean((actual - pred) .^ 2));
secondMse = mse(yPred', yActualCompare);

%% try different thresholds

thresholdMin = 0;
thresholdMax = 1;
thresholdNum = 50;
thresholdStep = (thresholdMax - thresholdMin) / (thresholdNum - 1);
thresholds = thresholdMin:thresholdStep:thresholdMax;
beta = 0.25;

varTypes = ["double", "double", "double", "double", "double"];
varNames = {'threshold', 'mse', 'fscore', 'precision', 'recall'};
sz = [thresholdNum, length(varNames)];
resultTable = table('Size', sz, 'VariableTypes', varTypes, ...
    'VariableNames', varNames);

fprintf('beta=%.2f min(yPred)=%.2f max(yPred)=%2.f mean(yPred)=%.2f\n', ...
    beta, min(yPred), max(yPred), mean(yPred));

for thresholdNum = 1:length(thresholds)
    threshold = thresholds(thresholdNum);
    yPredAfterThreshold = yPred >= threshold;
    [score, precision, recall] = fScore(yActualCompare, ...
        yPredAfterThreshold, 1, 0, beta);
    resultTable{thresholdNum, 1} = threshold;
    resultTable{thresholdNum, 2} = mse(yPredAfterThreshold, yActualCompare');
    resultTable{thresholdNum, 3} = score;
    resultTable{thresholdNum, 4} = precision;
    resultTable{thresholdNum, 5} = recall;
end

[bestScoreValue, bestScoreIdx] = max(resultTable{:, 3});
bestScoreThreshold = resultTable{bestScoreIdx, 1};
fprintf('bestScoreThreshold=%.3f, bestScoreValue=%.3f\n', ...
    bestScoreThreshold, bestScoreValue);

yBaselineAfterThreshold = yBaseline >= bestScoreThreshold;
baselineMse = mse(yBaselineAfterThreshold, yActualCompare');
[baselineScore, baselinePrecision, baselineRecall] = ...
    fScore(yActualCompare, yBaselineAfterThreshold, 1, 0, beta);
fprintf('baselineMse=%.2f, baselineScore=%.2f, baselinePrecision=%.2f, baselineRecall=%.2f\n', ...
    baselineMse, baselineScore, baselinePrecision, baselineRecall);

function [Xsummary, yActual] = getSummaryXy(tracklist, ...
    normalizeCenteringValues, normalizeScalingValues)

    % load the linear regressor saved in linearRegressionFrame.m
    load('linearRegressor.mat', 'linearRegressor');

    featureSpec = getfeaturespec('.\mono-extended.fss');
    nTracks = size(tracklist, 2);

    numSummaryFeatures = 5;
    Xsummary = zeros([nTracks numSummaryFeatures]);
    yActual = zeros(size(tracklist));

    for trackNum = 1:nTracks

        track = tracklist{trackNum};
        fprintf('[%d/%d] %s\n', trackNum, nTracks, track.filename);

        % get the X for that dialog
        % try to load the precomputed data, else compute it and save it for 
        % future runs
        customerSide = 'l';
        filename = track.filename;
        trackSpec = makeTrackspec(customerSide, filename, '.\calls\');
        [~, name, ~] = fileparts(filename);
        saveFilename = append(pwd, '\data\dialog-level-linear\', ...
            name, '.mat');
        try
            monster = load(saveFilename);
            monster = monster.monster;
        catch 
            [~, monster] = makeTrackMonster(trackSpec, featureSpec);
            save(saveFilename, 'monster');
        end

        % replace NaNs with zero
        % TODO remove this code after recomputing monsters
        % numNan = length(find(isnan(monster)));
        monster(isnan(monster)) = 0;
        % fprintf('\t%d NaNs replaced with zero\n', numNan);

        % normalize X (monster) using the same centering values and scaling 
        % values used to normalize the data used for training the 
        % frame-level model
        monster = normalize(monster, 'center', ...
            normalizeCenteringValues, 'scale', normalizeScalingValues);

        % get the known Y for that dialog
        % from call-log.xlsx, load the 'filename' and 'label' columns
        opts = spreadsheetImportOptions('NumVariables', 2, 'DataRange', ...
            'H2:I203', 'VariableNamesRange', 'H1:I1');
        callTable = readtable('call-log.xlsx', opts);
        matchingIdx = strcmp(callTable.filename, track.filename);
        actualLabel = callTable(matchingIdx, :).label{1};
        actualFloat = labelToFloat(actualLabel);

        yActual(trackNum) = actualFloat;

        % predict on X using the linear regressor
        % take the average of the predictions and make it the final one
        dialogPred = predict(linearRegressor, monster);

        % feature 1 - number of frames in dialogPred above the best 
        % threshold (the threshold with best F_0.25 score, found in 
        % linearRegressionFrame.m) divided by the number of total frames
        % feature 2 - min of dialogPred
        % feature 3 - max of dialogPred
        % feature 4 - average of dialogPred
        % feature 5 - range of dialogPred 
        % feature 6 - standard deviation of dialogPred
        bestThreshold = 0.555;
        Xsummary(trackNum, 1) = nnz(dialogPred > bestThreshold) / ...
            length(dialogPred);
        Xsummary(trackNum, 2) = min(dialogPred);
        Xsummary(trackNum, 3) = max(dialogPred);
        Xsummary(trackNum, 4) = mean(dialogPred);
        Xsummary(trackNum, 5) = range(dialogPred);
        Xsummary(trackNum, 6) = std(dialogPred);
        
    end

end