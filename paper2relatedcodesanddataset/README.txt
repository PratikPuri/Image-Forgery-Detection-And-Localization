
************************
*Component Description *
************************

getJmap.m: produces tampering probability map (main file)
floor2.m: modified floor function
ceil2.m: modified ceil function     
jpeg_rec.m: simulates decompressed JPEG image from JPEG object
demo.m: demo script
README.txt: this file
gpl.txt: GPL license


***********************
* Set-up Instructions *  
***********************

extract all files to a single directory. Add the directory to the Matlab path, 
or set it as the current Matlab directory. 


********************
* Run Instructions *
********************      

open dataset image using jpeg_read:

im = jpeg_read(<file_name>);

pass JPEG object to main function:

map = getJmap(im, 1, 1, 15);

the above parameters mean that tampering map is obtained using only Y channel 
(ncomp = 1) and DCT coefficients from 1 to 15 (zig-zag ordering).

Run demo1.m for a simple example


**********************
* Output Description *
**********************

The algorithm returns a map of auc values associated with different quantiztion steps QF1 and QF2 and also returns a
probablity map corresponding to it.
