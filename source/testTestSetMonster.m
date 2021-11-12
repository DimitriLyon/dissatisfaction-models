dataDir = append(pwd, '/data/frame-level');

featureSpec = getfeaturespec('./source/mono.fss');

tracklistTestFrame = gettracklist('tracklists-frame/test.tl');

    % compute test data
    [XtestFrame, yTestFrame, trackNumsTestFrame, ...
        utterNumsTestFrame, frameTimesTestFrame] = ...
        getXYfromTrackList(tracklistTestFrame, featureSpec);
    