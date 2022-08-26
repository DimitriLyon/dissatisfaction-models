function [X, y, frameTrackNums, frameUtterances, frameTimes] = ...
    getXYfromTrackListIterable(trackList, featureSpec,silenceSpeakRatio)
% GETXYFROMTRACKLIST Features are stored in X, labels are stored in y. 
% For frame i, frameTrackNums is the frame's track number relative to 
% trackList. See GETXYFROMFILE for more information on frameUtterances and
% frameTimes. frameTrackNums is used in failure analysis only.

    X = [];
    y = [];
    frameTrackNums = [];
    frameUtterances = [];
    frameTimes = [];
    
    %Dimitri - Magic value for my specific annotation directory
    %For utep call corpus
    %annotationFolder = 'annotations';
    %For Watergirl corpus
    annotationFolder = 'Processed-Fireboy-Annotations';
    nTracks = size(trackList, 2);
    for trackNum = 1:nTracks
        
        track = trackList{trackNum};
        
        %fprintf('[%d/%d] Getting X and y for %s\n', trackNum, nTracks, ...
        %    track.filename);
    
        %Modify getXYfromFile to take the track's side.
        [dialogX, dialogY, dialogFrameUtterances, dialogFrameTimes] = ...
            getXYfromFileIterable(track.filename, track.side, featureSpec,...
            annotationFolder, track.directory, silenceSpeakRatio);
        
        % skip this track if there are no useable annotations for it
        if ~size(dialogX, 1)
            continue
        end
        
        X = [X; dialogX]; % TODO appending is slow
        y = [y; dialogY];
        nFramesInDialog = size(dialogX, 1);
        trackNumsToAppend = ones(nFramesInDialog, 1) * trackNum;
        frameTrackNums = [frameTrackNums; trackNumsToAppend];
        frameUtterances = [frameUtterances; dialogFrameUtterances];
        frameTimes = [frameTimes; dialogFrameTimes];
        
    end

end