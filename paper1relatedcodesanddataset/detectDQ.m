function [OutputMap, Feature_Vector, coeffArray] = detectDQ( im )
    % Depending on whether im was created using jpeg_read (and thus is a struct) 
    % or CleanUpImage(/imread), call a different version of the algorithm.
    % jpeg_read produces more robust results, but can only open
    % JPEG-compressed images
    
    if isstruct(im)
        [OutputMap, Feature_Vector, coeffArray] = detectDQ_JPEG( im );
    else
        [OutputMap, Feature_Vector, coeffArray] = detectDQ_NonJPEG( im );
    end
    
    
end

