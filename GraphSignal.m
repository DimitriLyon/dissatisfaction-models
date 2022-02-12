featureSpec = getfeaturespec('./source/mono.fss');
track = makeTrackspec('r','game_1.wav','Fire-boy-sound/');
annotationFolder = 'Processed-Fireboy-Annotations/';
[~,name,~] = fileparts(track.filename);
if track.side == 'l'
    annotationSide = 'left';
    sideNum = 1;
else
    annotationSide = 'right';
    sideNum = 2;
end
filename = track.filename;
filename_100hz = append('mod',filename);
path_100hz = append(track.directory,filename_100hz);
%The full on these refer to the fact that the audio is the full 16khz
%version and not the 100hz version
[rate_full,signal_pair_full] = readtracks(track.path);
relevant_full_sig = signal_pair_full(:,sideNum);
%read tracks only works on files with a sample rate of 16khz or 8khz
%So I have to use audioread
[signal_pair_100hz,rate_100hz] = audioread(path_100hz);
relevant_100hz_sig = signal_pair_100hz(:,sideNum);
%The 100 hz is better to graph than graphing every 160th sample.

%% Sets up vectors to track which frames are annotated
nFrames = length(signal_pair_100hz);
isFrameAnnotated = false([nFrames 1]); 
isFrameAnnotDis = false([nFrames 1]);
isFrameAnnotNeu = false([nFrames 1]);
isFrameAutoAnnot = false([nFrames 1]);

%% Looks at the elan file and checks which frames are annotated.
annotationPath = append(annotationFolder, name, '.txt');
useFilter = true;
annotationTable = readElanAnnotation(annotationPath, useFilter, annotationSide);
nRows = size(annotationTable, 1);
for rowNum = 1:nRows
    row = annotationTable(rowNum, :);
    frameStart = round(milliseconds(row.startTime) / 10);
    frameEnd = round(milliseconds(row.endTime) / 10);
    y = labelToFloat(row.label);
    isFrameAnnotated(frameStart:frameEnd) = true; 
    if y==1
        isFrameAnnotDis(frameStart:frameEnd) = true;
    elseif y==0
        isFrameAnnotNeu(frameStart:frameEnd) = true;
    end
end

%% Gets the frames where someone is speaking and annotates them if necessary.

logEng = computeLogEnergy(relevant_full_sig', rate_full/100);
spokenFrames = speakingFrames(logEng)';
sFIndices = find(spokenFrames);
iFAIndices = find(isFrameAnnotated);
framestoSetToNeutral = setdiff(sFIndices,iFAIndices);
isFrameAnnotated(framestoSetToNeutral) = true;
isFrameAutoAnnot(framestoSetToNeutral) = true;

%% Gets the cpps for this signal

CPPS = lookupOrComputeCpps(track.directory, [track.filename track.side], relevant_full_sig, rate_full);
CPPSWindowed = windowize(CPPS',500)';
lengthDifference = length(isFrameAnnotated) - length(CPPSWindowed);
%Pad CPPS with frames if it is shorter than isFrameAnnotated

if lengthDifference > 0
    CPPSWindowed = [CPPSWindowed; zeros(lengthDifference,1)];
%Else, Chop CPPS
elseif lengthDifference < 0
    CPPSWindowed = CPPSWindowed(1:end+lengthDifference);
end

%Make CPPS smaller
CPPSWindowed = CPPSWindowed./5000;


%% Graph the Signal data.

x = [0:.01:(nFrames-1)/100];
y_notAnnot = zeros([nFrames 1]);
y_AutoAnnot = zeros([nFrames 1]);
y_neu = zeros([nFrames 1]);
y_dis = zeros([nFrames 1]);

y_notAnnot(isFrameAnnotated == 0) = relevant_100hz_sig(isFrameAnnotated == 0);
y_AutoAnnot(isFrameAutoAnnot) = relevant_100hz_sig(isFrameAutoAnnot);
y_neu(isFrameAnnotNeu) = relevant_100hz_sig(isFrameAnnotNeu);
y_dis(isFrameAnnotDis) = relevant_100hz_sig(isFrameAnnotDis);


blue = [0,0,250]./255;
pale_green = [141,222,141]./255;
red = [187,0,0]./255;
black = [0,0,0];

p_notAnnot = plot(x,y_notAnnot);
hold on
p_neu = plot(x,y_neu);
p_dis = plot(x,y_dis);
p_autoAnnot = plot(x,y_AutoAnnot);

%Set Colors
p_notAnnot.Color = black;
p_neu.Color = blue;
p_dis.Color = red;
p_autoAnnot.Color = pale_green;

%% Graph CPPS
y_CPPSnotAnnot = zeros([nFrames 1]);
y_CPPSAutoAnnot = zeros([nFrames 1]);
y_CPPSneu = zeros([nFrames 1]);
y_CPPSdis = zeros([nFrames 1]);

y_CPPSnotAnnot(isFrameAnnotated == 0) = CPPSWindowed(isFrameAnnotated == 0);
y_CPPSAutoAnnot(isFrameAutoAnnot) = CPPSWindowed(isFrameAutoAnnot);
y_CPPSneu(isFrameAnnotNeu) = CPPSWindowed(isFrameAnnotNeu);
y_CPPSdis(isFrameAnnotDis) = CPPSWindowed(isFrameAnnotDis);

vertical_offset = -.4;

y_CPPSnotAnnot = y_CPPSnotAnnot + vertical_offset;
y_CPPSAutoAnnot = y_CPPSAutoAnnot + vertical_offset;
y_CPPSneu = y_CPPSneu + vertical_offset;
y_CPPSdis = y_CPPSdis + vertical_offset;

p_CPPSnotAnnot = plot(x,y_CPPSnotAnnot);
hold on
p_CPPSneu = plot(x,y_CPPSneu);
p_CPPSdis = plot(x,y_CPPSdis);
p_CPPSautoAnnot = plot(x,y_CPPSAutoAnnot);

%Set Colors
p_CPPSnotAnnot.Color = black;
p_CPPSneu.Color = blue;
p_CPPSdis.Color = red;
p_CPPSautoAnnot.Color = pale_green;

