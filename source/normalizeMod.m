%Written specifically for this code. 
function [N,C,S] = normalizeMod(A, varargin)
    if nargin > 1
        C = varargin{2};
        S = varargin{4};
    else
        C = mean(A,1,'omitnan');
        S = std(A,0,1,'omitnan');
    end
    N = (A - C) ./ S;
end