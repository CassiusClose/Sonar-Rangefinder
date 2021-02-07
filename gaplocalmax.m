% A customized localmax function used to find local maxima for the
% rangefinding program. Of all the local maxima of the function, the chosen
% maxima are chosen based on certain conditions:
%   - If the value of the input has dropped more than a certain amount
%           since the last local maximum was chosen (if the local
%           maximum in consideration is greater than the previously chosen
%           maximum, this rule is ignored).
%   - If the value of the input has been consecutively increasing more than
%           a certain amount.
% These conditions are meant to only choose maxima that are at the top of
% large peaks. Specifically, once a local maximum at a large peak has been
% chosen, they're meant to ignore maxima that occur on the way down from
% that peak and only choose the maximum at the top of the next large peak.

% input: The array of values to choose maxima from
% decmin: How much the value of the input must decrease before choosing
%           another local maximum. (can increase again, but has to be
%           below that threshold for at least a sample first)
% incmin: How far the values must have been consecutively increasing
%           before a local maximum can be chosen.
% returns: A boolean array equal in length to 'input', that stores
%           whether or not that sample from the input array is
%           considered a local maximum.

function max = gaplocalmax(input, decmin, incmin)
    
    % Whether or not it can accept a point as a local maximum. If this is
    % false, the point may be a local maximum, but other conditions are not
    % met
    criteriaMet = true;
    
    % The value of the previously chosen local maximum
    lastVal = 0;
    
    % init boolean array, whether each sample is a chosen local maximum
    max = false(1, length(input));
    
    % Are we currently increasing in value?
    inc = true;
    
    % How far the values have decreased since the last chosen maximum
    decGap = 0;
    % How far the values have increased since the last chosen maximum, or 0
    % if the values are decreasing
    incGap = 0;
    
    % Go through all the samples (ignore the first one, can't be a max)
    for i=2:length(input)-1
        % For a point to be a local maximum, it must meet several criteria:
        %   - The values must be currently increasing and the next value is
        %           smaller than the current value
        %   - The values must have increased at least the specified amount
        %           (incmin) since they started increasing (resets every
        %           time the values decrease)
        %   - The criteria for picking a max have been met (the values have
        %           decreased enough since the previously chosen maximum,
        %           as specified by (decmin). 
        %       - This can be overridden if the point in question is a
        %           local maximum greater than previously chosen local max.
        %           This is because we want to choose maxima on the highest
        %           peaks that exist in the signal.
        if(inc && input(i+1) <= input(i) && incGap >= incmin &&...
                (criteriaMet || input(i) > lastVal))
            max(i) = true;
            
            % Reset increasing and decreasing counters
            decGap = 0;
            incGap = 0;
            lastVal = input(i);
            criteriaMet = false;
        end
        
        % If the values are decreasing
        if(input(i+1) <= input(i))
            inc = false;
            
            % Update increasing & decreasing counts
            decGap = decGap + input(i+1) - input(i);
            incGap = 0;
            
            % If the values have decreased enough since the previously
            % chosen maximum, then it's possible to choose another local
            % maximum.
            if(abs(decGap) >= decmin)
                criteriaMet = true;
            end
        % If the values are increasing
        else
            inc = true;
            % Update increasing count
            incGap = incGap + input(i+1) - input(i);
        end
    end

end