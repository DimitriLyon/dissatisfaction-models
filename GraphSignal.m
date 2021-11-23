featureSpec = getfeaturespec('./source/mono.fss');
tracklist = gettracklist('tracklists-frame/train.tl');
track = tracklist{1};
annotationFolder = 'Processed-Fireboy-Annotations/';
[~,name,~] = fileparts(track.filename);
annotationPath = append(annotationFolder, name, '.txt');
if track.side == 'l'
    annotationSide = 'left';
else
    annotationSide = 'right';
end
annotationTable = readElanAnnotation(annotationPath, useFilter, annotationSide);

