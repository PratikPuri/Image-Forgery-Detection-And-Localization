function [maskTampered, q1table, alphatable] = getJmap(image,ncomp,c1,c2)
% detect and localize tampered areas in doubly compressed JPEG images
% Matlab JPEG Toolbox is required, available at: 
% http://www.philsallee.com/jpegtbx/index.html
% image: JPEG object from jpeg_read
% ncomp: index of color component (1 = Y, 2 = Cb, 3 = Cr)
% c1: first DCT coefficient to consider (1 <= c1 <= 64)
% c2: last DCT coefficient to consider (1 <= c2 <= 64)
%
% maskTampered: estimated probability of being tampered for each 8x8 image block
% q1table: estimated quantization table of primary compression
% alphatable: mixture parameter for each DCT frequency
% DCT coefficients are obtained from the Jpeg toolbox using function image.coef_arrays
coeffArray = image.coef_arrays{ncomp};
% Quantization table is obtained from the Jpeg toolbox using function image.quant_tables
qtable = image.quant_tables{image.comp_info(ncomp).quant_tbl_no};

% estimate rounding and truncation error
I = jpeg_rec(image);
E = I - double(uint8(I));
% bdct performs DCT(Discrete Cosine Transform ) for a block
% we perform DCT for normalized coefficents from the 3 chanels
Edct = bdct(0.299 * E(:,:,1) +  0.587 * E(:,:,2) + 0.114 * E(:,:,3));
% We now reshape the Edct into a row vector so that we can obtain the variance
Edct2 = reshape(Edct,1,numel(Edct));
varE = var(Edct2);

% simulate coefficients without DQ effect
% dequatization and inverse DCT is performed to generste the original coefficients
Y = ibdct(dequantize(coeffArray, qtable));
% We now take a snipped version of the obtained matrix as stated in paper to obatin h~(x)
coeffArrayS = bdct(Y(2:end,2:end,1));

sizeCA = size(coeffArray);
sizeCAS = size(coeffArrayS);
% zig zag coefficients
coeff = [1 9 2 3 10 17 25 18 11 4 5 12 19 26 33 41 34 27 20 13 6 7 14 21 28 35 42 49 57 50 43 36 29 22 15 8 16 23 30 37 44 51 58 59 52 45 38 31 24 32 39 46 53 60 61 54 47 40 48 55 62 63 56 64];
coeffFreq = zeros(1, numel (coeffArray)/64);
coeffSmooth = zeros(1, numel (coeffArrayS)/64);
errFreq = zeros(1, numel (Edct)/64);
% Assigning bppm and bppm tampered 
bppm = 0.5 * ones(1, numel (coeffArray)/64);
bppmTampered = 0.5 * ones(1, numel (coeffArray)/64);
%% Estimation of Q1 for finding n(x)
q1table = 100 * ones(size(qtable));
alphatable = ones(size(qtable));
Q1up = [20*ones(1,10) 30*ones(1,5) 40*ones(1,6) 64*ones(1,7) 80*ones(1,8), 99*ones(1,28)]; % Maybe quality factor

for index = c1:c2
    
    coe = coeff(index);
    % load DCT coefficients at position index
    % This process is similar to the previous code and gives us DCT coefficients for a certain frequency for different postion of 8*8 blocks
    k = 1;
    start = mod(coe,8); 
    if start == 0
        start = 8;
    end
    for l = start:8:sizeCA(2)
        for i = ceil(coe/8):8:sizeCA(1)
            coeffFreq(k) = coeffArray(i,l);
            errFreq(k) = Edct(i,l);
            k = k+1;
        end
    end
    k = 1;
    for l = start:8:sizeCAS(2)
        for i = ceil(coe/8):8:sizeCAS(1)
            coeffSmooth(k) = coeffArrayS(i,l);
            k = k+1;
        end
    end
    % get histogram of DCT coefficients
    binHist = (-2^11:1:2^11-1);
    num4Bin = hist(coeffFreq,binHist);
    
    % get histogram of DCT coeffs w/o DQ effect (prior model for
    % uncompressed image)
    Q2 = qtable(floor((coe-1)/8)+1,mod(coe-1,8)+1);
    hsmooth = hist(coeffSmooth,binHist*Q2);
    
    % get estimate of rounding/truncation error
    biasE = mean(errFreq);
    
    % Gaussian kernel for histogram smoothing
    sig = sqrt (varE) / Q2;
    f = ceil(6*sig);
    p = -f:f;
    g = exp(-p.^2/sig^2/2);
    g = g/sum(g);
    % Initialzing the depended parameters
    lidx = binHist ~= 0;
    hweight = 0.5 * ones(1, 2^12);
    E = inf;
    Etmp = inf(1,99);
    alphaest = 1;
    Q1est = 1;
    biasest = 0;
    
    if index == 1
        bias = biasE;
    else
        bias = 0;
    end
    
    % estimate Q-factor of first compression
    for Q1 = 1:Q1up(index)
        for b = bias
            alpha = 1;
            if mod(Q2, Q1) == 0
                diff = (hweight .* (hsmooth - num4Bin)).^2;
            else
                % nhist * hsmooth = prior model for doubly compressed coefficient
                nhist = Q1/Q2 * (floor2((Q2/Q1)*(binHist + b/Q2 + 0.5)) - ceil2((Q2/Q1)*(binHist + b/Q2 - 0.5)) + 1);
                nhist = conv(g, nhist); 
                % nhist = n(x); g - gaussian kernel; hsmooth = h~(x)
                nhist = nhist(f+1:end-f);
                a1 = hweight .* (nhist .* hsmooth - hsmooth);
                a2 = hweight .* (hsmooth - num4Bin);
                % exclude zero bin from fitting
                alpha = -(a1(lidx) * a2 (lidx)') / (a1(lidx) * a1 (lidx)');
                alpha = min(alpha, 1);
                diff = (hweight .* (alpha * a1 + a2)).^2;
            end
            KLD = sum(diff(lidx));
            % Since Q1 is a discrete paramter the minimization can be solved iteratively by trying every possible q1 and using the corresponding alpha
            if KLD < E && alpha > 0.25
                E = KLD;
                Q1est = Q1;
                alphaest = alpha;
            end
            if KLD < Etmp(Q1)
                Etmp(Q1) = KLD;
                biasest = b;
            end
        end
    end
  
    Q1 = Q1est;
    biasest; % biasest should be subtracted instead it is added
    % new n(x) is defined taking into account the effect of bias
    nhist = Q1/Q2 * (floor2((Q2/Q1)*(binHist + biasest/Q2 + 0.5)) - ceil2((Q2/Q1)*(binHist + biasest/Q2 - 0.5)) + 1);
    % performing convloution with the kernel to reduce the rounding and truncating errors
    nhist = conv(g, nhist);
    nhist = nhist(f+1:end-f); % naya wala n(x)
    nhist = alpha * nhist + 1 - alpha;
    % since we have found out n(x) we can start assigning probablities
    ppt = mean (nhist) ./ (nhist + mean(nhist));
    alpha = alphaest;
    q1table(floor((coe-1)/8)+1,mod(coe-1,8)+1) = Q1est;
    alphatable(floor((coe-1)/8)+1,mod(coe-1,8)+1) = alpha;
    % compute probabilities if DQ effect is present
    if mod(Q2,Q1est) > 0
        % index
        nhist = Q1est/Q2 * (floor2((Q2/Q1est)*(binHist + biasest/Q2 + 0.5)) - ceil2((Q2/Q1est)*(binHist + biasest/Q2 - 0.5)) + 1);
        % histogram smoothing (avoids false alarms)
        nhist = conv(g, nhist);
        nhist = nhist(f+1:end-f);
        nhist = alpha * nhist + 1 - alpha;
        % ppu gives probality that block is untampered
        ppu = nhist ./ (nhist + mean(nhist));
        % ppt gives us probalit that block is tampered
        ppt = mean (nhist) ./ (nhist + mean(nhist));
        % set zeroed coefficients as non-informative
        ppu(2^11 + 1) = 0.5;
        ppt(2^11 + 1) = 0.5;
        % Setting bppm and bppmtampered using ppu and ppt obtained
        bppm = bppm .* ppu(coeffFreq + 2^11 + 1);
        bppmTampered = bppmTampered .* ppt(coeffFreq + 2^11 + 1);
    end
end
% setting the mask tampered with the bbpm and bppmtampered obatined above
maskTampered = bppmTampered ./ (bppm + bppmTampered);
maskTampered = reshape(maskTampered,sizeCA (1)/8,sizeCA (2)/8);
% apply median filter to highlight connected regions
maskTampered = medfilt2(maskTampered, [5 5]);

return
