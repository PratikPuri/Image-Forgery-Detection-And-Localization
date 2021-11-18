function [OutputMap, Feature_Vector, coeffArray] = detectDQ_NonJPEG( im )
  % How many DCT coeffs to take into account
    MaxCoeffs=15;
    % JPEG zig-zag sequence
    coeff = [1 9 2 3 10 17 25 18 11 4 5 12 19 26 33 41 34 27 20 13 6 7 14 21 28 35 42 49 57 50 43 36 29 22 15 8 16 23 30 37 44 51 58 59 52 45 38 31 24 32 39 46 53 60 61 54 47 40 48 55 62 63 56 64];
    
    % Which channel to take: always keep Y only
    channel=1;
    % Using the im.coef_arrays from JPEG toolbox to decode the DCT
    % coefficients
    coeffArray = im.coef_arrays{channel};
    % Converting the coeffarray into perfect 8*8 DCT blocks 
    if mod(im.image_height,8)~=0
        coeffArray=coeffArray(1:end-8,:);
    end
    if mod(im.image_width,8)~=0
        coeffArray=coeffArray(:,1:end-8);
    end
    %% Now we cluster the DCT blocks of a specfic coeff into a single array coe which will be used for histogram plotting
    for coeffIndex=1:MaxCoeffs
        coe = coeff(coeffIndex);
        startY = mod(coe,8);
        if startY == 0
            startY = 8;
        end
        startX=ceil(coe/8);
        selectedCoeffs=coeffArray(startX:8:end, startY:8:end);
        %Reshaping the matrix into a row matrix with a all the DCT
        %coefficients belonging to a certain frequency
        coeffList=reshape(selectedCoeffs,1,numel(selectedCoeffs));       
        minHistValue=min(coeffList)-1;
        maxHistValue=max(coeffList)+1;
        % Creating a histogram of these DCt values
        coeffHist=hist(coeffList,minHistValue:maxHistValue);
        
%% Calculating the period
        % Using the first defination in paper to calculate the period
        if numel(coeffHist>0)    
            %Finding out maximum s_0 coresponding to highest peak in the
            %histogram
            [MaxHVal,s_0]=max(coeffHist);
            s_0_Out(coeffIndex)=s_0;
            dims(coeffIndex)=length(coeffHist);
            H=zeros(floor(length(coeffHist)/4),1);
            % varying the index form 1 to s0/20 to find out the period
            for coeffInd=1:(length(coeffHist)-1)
                vals=[coeffHist(s_0:coeffInd:end) coeffHist(s_0-coeffInd:-coeffInd:1)];
                H(coeffInd)=mean(vals);
            end
            H_Out{coeffIndex}=H;
            % The period will be the coeffInd when H(coeffInd will be
            % maximum)
            [~,p_h_avg(coeffIndex)]=max(H);
        else
            % If numel(coeffHistogarm=0) then p is taken to be 1 as stated
            % in the paper and does not show DQ effect
            s_0_Out(coeffIndex)=0;
            dims(coeffIndex)=0;
            H_Out{coeffIndex}=[];
            p_h_avg(coeffIndex)=1;
        end
        
        % Using the second defination in paper to calculate the period
        %Find period by max peak in the FFT minus DC term
        FFT=abs(fft(coeffHist));
        FFT_Out{coeffIndex}=FFT;
        if ~isempty(FFT)
            DC=FFT(1);           
            %Find first local minimum, to remove DC peak
            FreqValley=1;
            while (FreqValley<length(FFT)-1) && (FFT(FreqValley)>= FFT(FreqValley+1))
                FreqValley=FreqValley+1;
            end
            % We are trying to find maxima of FFT by looking at a snipped
            % of the FFT to identify the period
            FFT=FFT(FreqValley:floor(length(FFT)/2));
            FFT_smoothed{coeffIndex}=FFT;
            [maxPeak,FFTPeak]=max(FFT);
            FFTPeak=FFTPeak+FreqValley-1-1; % -1 because FreqValley appears twice, and -1 for the 0-freq DC term
            % p_h_fft will give us the period arising from the FFT
            % alogrithm
            if isempty(FFTPeak) || maxPeak<DC/5 || min(FFT)/maxPeak>0.9 % threshold at 1/5 the DC and 90% the remaining lowest to only retain significant peaks
                p_h_fft(coeffIndex)=1;
            else
                p_h_fft(coeffIndex)=round(length(coeffHist)/FFTPeak);
            end
        else
            % If FFT_Out{coeffIndex}=[] then p is taken to be 1 as stated
            % in the paper and does not show DQ effect
            FFT_Out{coeffIndex}=[];
            FFT_smoothed{coeffIndex}=[];
            p_h_fft(coeffIndex)=1;
        end
        
        %period is the minimum of the two methods
        p_final(coeffIndex)=p_h_fft(coeffIndex);
        
        %calculate per-block probabilities using bayesian approach
        % possibility of an unchanged block which contributes to that
        % period occurring in the (s0 + i)bin has been estimated
        if p_final(coeffIndex)~=1
            adjustedCoeffs=selectedCoeffs-minHistValue+1;
            period_start=adjustedCoeffs-(rem(adjustedCoeffs-s_0_Out(coeffIndex),p_final(coeffIndex)));
            for kk=1:size(period_start,1)
                for ll=1:size(period_start,2)
                    if period_start(kk,ll)>=s_0_Out(coeffIndex)
                        period=period_start(kk,ll):period_start(kk,ll)+p_final(coeffIndex)-1;                
                        if period_start(kk,ll)+p_final(coeffIndex)-1>length(coeffHist)
                            period(period>length(coeffHist))=period(period>length(coeffHist))-p_final(coeffIndex);
                        end
                        num(kk,ll)=coeffHist(adjustedCoeffs(kk,ll));
                        denom(kk,ll)=sum(coeffHist(period));
                    else
                        period=period_start(kk,ll):-1:period_start(kk,ll)-p_final(coeffIndex)+1;
                        if period_start(kk,ll)-p_final(coeffIndex)+1<= 0
                            period(period<=0)=period(period<=0)+p_final(coeffIndex);
                        end
                        num(kk,ll)=coeffHist(adjustedCoeffs(kk,ll));
                        denom(kk,ll)=sum(coeffHist(period));
                    end
                end
            end
            P_u=num./denom;
            P_t=1./p_final(coeffIndex);
            %From the naive Bayesian approach, if a block contributes to the (s0 +i)-th bin,
            %then the posteriorprobability of it being a tampered block or an unchanged block is,respectively,
            P_tampered(:,:,coeffIndex)=P_t./(P_u+P_t);
            P_untampered(:,:,coeffIndex)=P_u./(P_u+P_t);
            
        else
            
            P_tampered(:,:,coeffIndex)=ones(ceil(size(coeffArray,1)/8),ceil(size(coeffArray,2)/8))*0.5;
            P_untampered(:,:,coeffIndex)=1-P_tampered(:,:,coeffIndex);
        end
    end
    
    
    P_tampered_Overall=prod(P_tampered,3)./(prod(P_tampered,3)+prod(P_untampered,3));
    P_tampered_Overall(isnan(P_tampered_Overall))=0;
    % OutputMap(BPPM map) is generated here
    OutputMap=P_tampered_Overall;
 %% Faeture extraction
    % calulation of variance of P_tamepered_overall
    s=var(reshape(P_tampered_Overall,numel(P_tampered_Overall),1));
    % Segregation of the two classes on basis of Treahold
    for T=0.01:0.01:0.99
        Class0=P_tampered_Overall<T;
        Class1=~Class0;
        s0=var(P_tampered_Overall(Class0));
        s1=var(P_tampered_Overall(Class1));
        Teval(round(T*100))=s/(s0+s1);
    end
    
    [val,Topt]=max(Teval);
    Topt=Topt/100-0.01;
    
    Class0=P_tampered_Overall<Topt;
    Class1=~Class0;
    % Calculating inclass variance for both the classes Class0 and Class1
    s0=var(P_tampered_Overall(Class0));
    s1=var(P_tampered_Overall(Class1));
    % Applying median filtering for reductiojn of noise
    Class1_filt=medfilt2(Class1,[3 3]);
    Class0_filt=medfilt2(Class0,[3 3]);
    % Now calculating component connectivity K_0 inspired by the perimeter–area ratio for shape description.
    e_i=(Class0_filt(1:end-2,2:end-1)+Class0_filt(2:end-1,1:end-2)+Class0_filt(3:end,2:end-1)+Class0_filt(2:end-1,3:end)).*Class1_filt(2:end-1,2:end-1);
    if sum(sum(Class0)) > 0 && sum(sum(Class0)) < numel(Class0)
        K_0=sum(sum(max(e_i-2,0)))/sum(sum(Class0));
    else
        K_0=1;
        s0=0;
        s1=0;    
    end
    % Extraction of Feature Vector
    Feature_Vector=[Topt, s, s0+s1, K_0];
