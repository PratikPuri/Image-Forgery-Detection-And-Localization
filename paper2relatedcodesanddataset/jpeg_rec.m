function [I,YCbCr] = jpeg_rec(image)
%
% [I,YCbCr] = jpeg_rec(image)
%
% simulate decompressed JPEG image from JPEG object 
%
% Matlab JPEG Toolbox is required, available at: 
% http://www.philsallee.com/jpegtbx/index.html
%
% image: JPEG object from jpeg_read
%
% I: decompressed image (RGB)
% YCbCr: decompressed image (YCbCr)


Y = ibdct(dequantize(image.coef_arrays{1}, image.quant_tables{1}));
Cb = ibdct(dequantize(image.coef_arrays{2}, image.quant_tables{2}));
Cr = ibdct(dequantize(image.coef_arrays{3}, image.quant_tables{2}));

Y = Y + 128;
[r,c] = size(Y);
Cb = kron(Cb,ones(2)) + 128;
Cr = kron(Cr,ones(2)) + 128;
Cb = Cb(1:r,1:c);
Cr = Cr(1:r,1:c);


I(:,:,1) = (Y + 1.402 * (Cr -128));
I(:,:,2) = (Y - 0.34414 *  (Cb - 128) - 0.71414 * (Cr - 128));
I(:,:,3) = (Y + 1.772 * (Cb - 128));

YCbCr = cat(3,Y,Cb,Cr);

return