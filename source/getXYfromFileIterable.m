function [X, y, frameUtterances, frameTimes] = ...
    getXYfromFileIterable(filename, side, featureSpec, annotationFolder,...
    soundFolder, silenceSpeakRatio)
    %Dimitri - Add another parameter for the aud

    % get the annotation filename from the dialog filename, assuming they 
    % have the same name, then use this to get the annotation table
    [~, name, ~] = fileparts(filename);
    annFilename = append(name, ".txt");
    if(annotationFolder(end) ~= '/') 
        annotationFolder = append(annotationFolder, '/');
    end
    
    if side == 'l'
        annotationSide = 'left';
    else
        annotationSide = 'right';
    end
    %For UTEP diss call corpus
    %annotationSide = 'default';
    
    annotationPath = append(annotationFolder, annFilename);
    useFilter = true;
    annotationTable = readElanAnnotation(annotationPath, useFilter, annotationSide);
    
    % get the monster
    customerSide = side;
    %Dimitri change - instead of ./calls/, use the sound folder parameter
    trackSpec = makeTrackspec(customerSide, filename, soundFolder);
    %Cache monster for later
    monsterDir = [trackSpec.directory 'monsterCache/'];
    monsterSavekey = [trackSpec.filename trackSpec.side];
    monsterFileName = [monsterDir monsterSavekey '.mat'];
    
    if ~exist(monsterDir, 'dir')
        mkdir (monsterDir);
    end
    
    if exist(monsterFileName, 'file') ~= 2
        [~, monster] = makeTrackMonster(trackSpec, featureSpec);
        save(monsterFileName, 'monster');
    else
        load(monsterFileName,'monster');
    end
    nFrames = size(monster, 1);
    
    % iterate annotation rows and keep track of which frames are
    % annotated, what their labels are, and which utterance they belong to 
    isFrameAnnotated = false([nFrames 1]); % assume frame is not annotated (false)
    y = ones([nFrames 1]) * -1; % assume frame label does not exist (-1)
    frameUtterances = ones([nFrames 1]) * -1; % assume frame does not belong to labeled utterance (-1)
    nRows = size(annotationTable, 1);
    for rowNum = 1:nRows
        row = annotationTable(rowNum, :);
        frameStart = round(milliseconds(row.startTime) / 10);
        if frameStart == 0
            frameStart = 1;
        end
        frameEnd = round(milliseconds(row.endTime) / 10);
        isFrameAnnotated(frameStart:frameEnd) = true;
        y(frameStart:frameEnd) = labelToFloat(row.label);
        frameUtterances(frameStart:frameEnd) = rowNum;
    end
    
    %Dissatisfied is 1
    %Neutral is 0
    %Out of character is -1.  These frames are annotated so that
    %isFrameAnnotated is set to true for these frames.  This is so that the
    %code that automatically detects speech does not annotate the out of
    %character frames as neutral.
    
    
    %Used for both the automatic neutral annotations and the debug
    %graph.
    [rate,signalS] =  readtracks(trackSpec.path);
    if trackSpec.side == 'l'
        relevantSig = signalS(:,1);
    else
        relevantSig = signalS(:,2);
    end
    logEng = computeLogEnergy(relevantSig', rate/100);
    spokenFrames = speakingFramesIterable(logEng,silenceSpeakRatio)';
    %Boolean condition to determine if to set the frames where speech is
    %detected that aren't already annotated to neutral (0)
    setNotAnnotatedSpeakingToNeutral = false;
    if setNotAnnotatedSpeakingToNeutral
        sFIndices = find(spokenFrames);
        iFAIndices = find(isFrameAnnotated);
        framestoSetToNeutral = setdiff(sFIndices,iFAIndices);
        y(framestoSetToNeutral) = 0;
        isFrameAnnotated(framestoSetToNeutral) = true;
    end
    
    
    
    
    
    %Deals with edge case related to annotations that go to the very end of
    %the audio
    [monsterHeight,~] = size(monster);
    [isFAHeight,~] = size(isFrameAnnotated);
    yHeight = length(y);
    newHeight = min([monsterHeight,isFAHeight,yHeight]);
    monster = monster(1:newHeight,:);
    isFrameAnnotated = isFrameAnnotated(1:newHeight,:);
    y = y(1:newHeight,:);
    
    
    %Remove out of character frames from isFrameAnnotated.
    isFrameAnnotated(y == -1) = false;
    
    
    % TODO remove isFrameAnnotated and use y directly
    matchingFrameNums = find(isFrameAnnotated);
    %matchingFrameNums = find(y ~= -1)
    %This assert no longer works.
    %assert(isequal(find(y~=-1),find(isFrameAnnotated)))
    
    X = monster(isFrameAnnotated, :);
    y = y(isFrameAnnotated);
    frameTimes = arrayfun(@(frameNum) frameNumToTime(frameNum), ...
        matchingFrameNums);
    frameUtterances = frameUtterances(isFrameAnnotated);
    
    frameTimes = seconds(frameTimes);

    X = [X frameTimes];

end
