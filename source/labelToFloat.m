function float = labelToFloat(label)
    if strcmp(label, "n") || strcmp(label, "nn") || ...
            strcmp(label, "successful") || strcmp(label, "p")
        float = 0;
    elseif strcmp(label, "d") || strcmp(label, "dd") || ...
            strcmp(label, "doomed_1") || strcmp(label, "doomed_2") || ...
            strcmp(label, "ds") || strcmp(label, "do") || ...
            strcmp(label, "dg") || strcmp(label, "dr")
        float = 1;
    elseif strcmp(label,"o")
        %Use -1 as a do not annotate this flag.
        float = -1;
    else
        error('labelToFloat: unknown label: "%s"\n', label);
    end    
end