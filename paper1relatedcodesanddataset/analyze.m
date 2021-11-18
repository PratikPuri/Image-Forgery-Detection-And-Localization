function [OutputMap, Feature_Vector, coeffArray] = analyze( imPath )
    try
        %try_catch is used instead of simply checking the extension
        %because often jpeg files have a wrong extension
        %evalc is used to suppress output when the file is not jpeg
        [~,im] = evalc('jpeg_read(imPath);');
    catch
        % This function serves as a replacement for imread(), covering many extreme
        % cases that occasionally appear in real-world datasets. This includes images 
        % with other than three channels and uint16 images. These images are all
        % converted to 3-channel uint8 images.
        im=CleanUpImage(imPath);
    end
    % Here we detect the presence of DQ effect using the function detectDq
    % defined in another matlab file
    [OutputMap, Feature_Vector, coeffArray] = detectDQ(im);
end

