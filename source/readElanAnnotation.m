function annotationTable = readElanAnnotation(trackFilename, useFilter, annotationTrackName)
% READELANANNOTATION Read utterance annotations from default ELAN 
% tab-delimited export to MATLAB table. If useFilter is true, regions 
% labeled other as neutral and disappointed are ignored.

    [annotationFolder, name, ~] = fileparts(trackFilename);
    annFilename = append(name, ".txt");
    annotationFolder = append(annotationFolder,'/');
    annotationPathRelative = append(annotationFolder, annFilename);
    
    annotationPathFull = fullfile(pwd, annotationPathRelative);

    % throw error if the annotation file does not exist
    if ~isfile(annotationPathFull)
        ME = MException('readElanAnnotation:fileNotFound', ...
        'Annotation file %s not found', annotationPathRelative);
        throw(ME);
    end

    importOptions = delimitedTextImportOptions( ...
        'Delimiter', {'\t'}, ...
        'VariableNames', {'tier', 'startTime', 'startTimeShort', 'endTime', 'endTimeShort', 'duration', 'durationShort', 'label'}, ...
        'VariableTypes', {'string', 'duration', 'duration', 'duration', 'duration', 'duration', 'duration', 'string'}, ...
        'SelectedVariableNames', {'tier', 'startTime', 'endTime', 'duration', 'label'}, ...
        'ConsecutiveDelimitersRule', 'join' ...
        );
    
    annotationTable = readtable(annotationPathFull, importOptions);
    
    % if filter argument was passed, delete rows with labels other than "n"
    % "nn" "d" "dd" "do" "ds" "dg" "dr" or "p", as well as rows with a tier
    % different from the annotationTrackName
    if useFilter
        toDelete = ismember(annotationTable.label, ["n" "nn" "d" "dd" "do" "ds" "dg" "dr" "p"]) & ...
            annotationTable.tier == annotationTrackName;
        annotationTable(~toDelete, :) = [];
    end
    
end

