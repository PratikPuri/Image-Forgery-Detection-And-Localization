output = jpeg_write(imIn)
% JPEG_WRITE  Write a JPEG object struct to a JPEG file
%
%    JPEG_WRITE(JPEGOBJ,FILENAME) Reads JPEGOBJ, a Matlab struct returned
%    by the JPEG_READ function, and writes the contents into a JPEG file
%    named FILENAME.
%    See also JPEG_READ.

error("Mex routine jpeg_write.c not compiled\n");
