close all; clear all; %To clear all the variables in workspace and to close all the figures

final_result = [];
% Setting different quantization steps at an interval of 5 form 50 to 95
% for both Q1(first quantization step) and Q2( second quantization step)
for Q1 = 50:5:95
    result = [];
    for Q2 = 50:5:95
        for (i=1:20)
            % Here we are calling 20 different files saved as tiff images
            image_name_tif = char('Dataset/'+string(i)+'.tif');
            mat_tif = imread(image_name_tif);
            % Here we are saving these 20 images in jpg format with
            % quantization Q1
            image_name_jpg = char('Dataset/'+string(i)+'.jpg');
            imwrite (mat_tif,image_name_jpg,'jpg','quality',Q1);
            mat = imread(image_name_jpg);
            % Now we create a subset of untampered images in jpg format with quantization step Q2 and store them
            image_name_jpg_untamp = char('Dataset/'+string(i)+'ut.jpg');
            imwrite (mat,image_name_jpg_untamp,'jpg','quality',Q2);
            mat_size = size(mat_tif);
            % Now we perform tampering in the central portion of the singly
            % compressed file with a snipped version of tiff image 
            r = floor(mat_size(1)/2);
            c = floor(mat_size(2)/2);
            x=1;
            y=1;
            for i1=r:r+500
                y=1;
                for j1=c:c+500
                    mat(x+i*50,y+i*50,1) = mat_tif(i1,j1,1);
                    mat(x+i*50,y+i*50,2) = mat_tif(i1,j1,2);
                    mat(x+i*50,y+i*50,3) = mat_tif(i1,j1,3);
                    y=y+1;
                end
                x=x+1;
            end
            % Now we create a subset of tampered images in jpg format with quantization step Q2 and store them
            image_name_jpg_tamp = char('Dataset/'+string(i)+'t.jpg');
            imwrite (mat,image_name_jpg_tamp,'jpg','quality',Q2);
        end
        
        X = [];
        Y = [];
        for (i=1:20)
            image_name_jpg = char('Dataset/'+string(i)+'.jpg');
            subplot(2,3,1);
            % CleanupImage function serves as a replacement for imread(), covering many extreme
            % cases that occasionally appear in real-world datasets. This includes images 
            % with other than three channels and uint16 images. These images are all
            % converted to 3-channel uint8 images.
            imshow(CleanUpImage(image_name_jpg));
            % Analyze detects if image is in jpeg format and gives output
            % as a Probablity map , Feature Vector and DCT coefficients
            % array as output
            [OutputMap, Feature_Vector, coeffArray] = analyze(image_name_jpg);
            subplot(2,3,4);
            % Here we display the output map as a function of tampered
            % probablities for untampered singly compressed images
            imagesc(OutputMap);
            title('Untampered singly compressed');
            image_name_jpg = char('Dataset/'+string(i)+'ut.jpg');
            subplot(2,3,2);
            imshow(CleanUpImage(image_name_jpg));
            [OutputMap, Feature_Vector, coeffArray] = analyze(image_name_jpg);
            subplot(2,3,5);
            % Here we display the output map as a function of tampered
            % probablities for untampered doubly compressed images
            imagesc(OutputMap);
            title('Untampered doubly compressed');
            X = [X;Feature_Vector];
            Y = [Y;0];
            image_name_jpg_tamp = char('Dataset/'+string(i)+'t.jpg');
            im2 = imread(image_name_jpg_tamp);
            subplot(2,3,3);
            imshow(CleanUpImage(image_name_jpg_tamp));
            [OutputMap, Feature_Vector, coeffArray] = analyze(image_name_jpg_tamp);
            subplot(2,3,6);
            % Here we display the output map as a function of tampered
            % probablities for tampered images
            imagesc(OutputMap);
            X = [X;Feature_Vector];
            Y = [Y;1];
            title('Tampered with DQ effect');
        end
        
        %% Training an SVM model for identifying the two classes ( Tampered(1) and Untampered(0))
        model = fitcsvm(X,Y);
        X1 = [];
        for i = 21:40
            image_name_jpg = char('Test/'+string(i)+'.jpg');
            [OutputMap, Feature_Vector, coeffArray] = analyze(image_name_jpg);
            % Providing feature vectors to predict whether the image is tampered or not
            X1 = [X1; Feature_Vector];
        end
        % Setting the known tampered / untampered classes for each of the
        % input images
        Y1 = [0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1];
        Y2 = predict(model,X1);
        correct = 0;
        % Calculating the percentages of the correctly identified images
        for h=1:20
            if (Y1(h) == Y2(h))
                correct = correct+1;
            end
        end
        fraction_correct = correct/20;
        result = [result fraction_correct];
    end
    final_result = [final_result result];
end
final_result_size = size(final_result);
figure;
% Now we plot our result and compare the output result for different Q2
% from 50 to 95 at a size step of 5 for each interval
for (i=1:final_result_size(1))
    subplot (4,3,i)
    plot (final_result(i));
    final_result(i) = mean(final_result(i));
end
figure;
plot (50:5:95,final_result);
ylabel("Detection rate");
xlable("Q2");

