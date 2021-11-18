% example of how to use getJmap
clear all;
AUC = zeros(6);
x1 = 1;
y1 = 1;
% Q1( Quality Factor1) and Q2(Quality Factor2) have been started from 50 and ended to 100 with each at a step size of 10 acheiving a total of 36 cominations
for Q1=50
    y1 = 1;
    for Q2=100
        T_step_size = 0.00001;
        length_step = length(0:0.00001:1);
        pfa_avg = zeros(1,length_step);
        pd_avg = zeros(1,length_step);
        for (i=2)
            % A 1024*1024 image is created for achieving our purpose 
            image_name_tif = char('Dataset/'+string(i)+'.tif');
            mat_tif = imread(image_name_tif);
            size_mat_tif = size(mat_tif);
            x=1;
            y=1;
            
            for i1=(floor(size_mat_tif (1)/2)-512):(floor(size_mat_tif (1)/2)+511)
                y = 1;
                for j1=(floor(size_mat_tif (2)/2)-512):(floor(size_mat_tif (2)/2)+511)
                    mat_new(x,y,1) = mat_tif(i1,j1,1);
                    mat_new(x,y,2) = mat_tif(i1,j1,2);
                    mat_new(x,y,3) = mat_tif(i1,j1,3);
                    y = y+1;
                end
                x = x+1;
            end
            % We now convert the tiff image with a quality factor Q1 to generate a new jpeg image
            image_name_jpg = char('Dataset/'+string(i)+'.jpg');
            imwrite (mat_new,image_name_jpg,'jpg','quality',Q1);
            mat = imread(image_name_jpg);
            % We now agian compress the jpeg image from step 1 to new jpeg image with qulity factor Q2 to generate new untampered image
            image_name_jpg_untamp = char('Dataset/'+string(i)+'ut.jpg');
            imwrite (mat,image_name_jpg_untamp,'jpg','quality',Q2);
            % Now the central porton of jepg image obtained after step1 are introduced to a forgery of 256*256 at the central portions and agin subjected to a Qality factor of Q2 to generate a new tampered image
            mat_size = size(mat);
            r = floor(mat_size (1)/2);
            c = floor(mat_size (2)/2);
            x=1;
            y=1;
            for i1=r-128:r+127
                y=1;
                for j1=c-128:c+127
                    mat(i1,j1,1) = mat_tif(x+i*50,y+i*50,1);
                    mat(i1,j1,2) = mat_tif(x+i*50,y+i*50,2);
                    mat(i1,j1,3) = mat_tif(x+i*50,y+i*50,3);
                    y=y+1;
                end
                x=x+1;
            end
            image_name_jpg_tamp = char('Dataset/'+string(i)+'t.jpg');
            imwrite (mat,image_name_jpg_tamp,'jpg','quality',Q2);

            filename = image_name_jpg_tamp;
            % set parameters
            ncomp = 1;% chanel chosen is set to 1
            c1 = 1;% Starting dct coefficient is set to 1
            c2 = 15;% Ending dct coefficient is set to 15 similar to case in the code of pervious paper

            im = jpeg_read(filename);
            % generating probablity map using the function Jmap which is a defined function
            map = getJmap(im,ncomp,c1,c2);

            % Showing the probablity map
            figure(1)
            subplot(1,2,1), imshow(filename)
            subplot(1,2,2), imagesc(map), axis equal

            i1=1;
            % We now vary the treshold and find pfa(false alarm ate) and pd(correct detection rate) which form the basis of ROC(reciever operating characteristic)
            for T = 0:0.00001:1
                nnmf = 0;% nnmf is number of blocks not maipulated but detected as forged
                nmnf = 0;% nmnf is number of blocks maipulated but not detected as forged
                for i=1:128
                    for j=1:128
                        if (map(i,j)>=T && (i>79 || i<48 || j>79 || j<48))
                            nnmf = nnmf + 1;
                        end
                        if (map(i,j)<T && i<=79 && i>=48 && j<=79 && j>=48)
                            nmnf = nmnf + 1;
                        end
                    end
                end
                n1 = 128*128;% n1 is total blocks in the map obatined
                nm = 1024;% nm is total manipulated blocks in the map obtained
                nnmf1(i1) = nnmf;
                nmnf1(i1) = nmnf;
                pfa(i1) = nnmf1 (i1)/(n1-nm);% Calulation of pfa
                pmd = nmnf/nm;
                pd(i1) = 1 - pmd;% Calculation of pd
                i1 = i1+1;
            end
            pfa_avg = pfa_avg + pfa;
            pd_avg = pd_avg + pd;
        end
        figure(2);
        plot (pfa_avg,pd_avg);
        
        AUC= trapz(flip(pfa_avg),flip(pd_avg))% we now obtain the Area under ROC curve for the QF1=x and QF2=y 
    end
end
