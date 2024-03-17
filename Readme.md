<h1>Image Forgery Detection And Localization</h1>
<p align ="right">
<h3 align = "right">Team members:</h3>
<p align = "right">- Pratik Puri Goswami<br>
- Vasu Bhalothia</p>
<h3>Papers evaluated:</h3>
<ol>
<li>Fast, automatic and fine-grained tampered JPEG image detection via DCT coefficient analysis</li>
<li>Improved DCT coefficient analysis for forgery localization in JPEG images</li>
</ol>
<hr>
<h3>Introduction</h3>
<p>There has been a long history of image forgery. In the early days, dark-room skills were used to print multiple fragments of photos onto a single photograph paper. In the current digital era, image/video forgery becomes much easier. The techniques involve naive cutting and pasting, matting for perfect blending texture synthesis for synthesizing new contents.<br>
mage forensic technologies can be categorized as active ones and passive ones.<br>
Active image forensic methods mainly insert digital watermark to images/videos at the instant of their acquisition. The integrity of images/videos can be checked by detecting the change in the watermark. In contrast, passive image forensic aims at developing technologies for tampered image/video detection without using knowledge beyond the image/video itself.</p>
<p>In the first paper, a fast and fully automatic detection method for JPEG images is proposed. The reason we target JPEG images is because JPEG is the most widely used image format. Particularly in digital cameras, JPEG may be the most preferred image format due to its efficiency of storage. Our method is based on the DQ effect. Intuitively speaking, the DQ effect is the exhibition of periodic peaks and valleys in the histograms of the discrete cosine transform, DCT, coefficients.</p>
<p>In the second paper, a proposal using a statistical test to discriminate between original and forged regions in JPEG images is made under the hypothesis that the former are doubly compressed while the latter are singly compressed. New probability models for the DCT coefficients of singly and doubly compressed regions are proposed, together with a reliable method for estimating the primary quantization factor in the case of double compression.</p>

---
<h3>Basic outline of the Algorithm for the first paper</h3>

<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/algorithmOutline.jpg"></p>

<p>Given a JPEG image, we first dump its DCT coefficients and quantization matrices for YUV channels. If the image is originally stored in other lossless format, we first convert it to the JPEG format at the highest compression quality. Then we build histograms for each channel and each frequency. Note that the DCT coefficients are of 64 frequencies in total, varying from (0,0) to (7,7). For each frequency, the DCT coefficients of all the blocks can be gathered to build a histogram. Moreover, a color image is always converted into the YUV space for JPEG compression. Therefore, we can build at most 64 × 3 = 192 histograms of DCT coefficients of different frequencies and different channels.However, as high
frequency DCT coefficients are often quantized to zeros, only the histograms of low frequencies of each channel are useful. For each block in the image, using one histogram we can compute one probability of it being a tampered block, by checking the DQ effect of this histogram. With all the available histograms, we can accumulate the probabilities to give the posterior probability of this block being unchanged . Then the block posterior probability map (BPPM)is thresholded to differentiate the possibly tampered region and possibly unchanged region. With such a segmentation, a four-dimensional feature vector is computed for the image. Finally, a trained SVM is applied to decide whether the image is tampered. If it is tampered, then the segmented tampered region is also output.</p>

<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/blockPosteriorProbabilityMap.jpg"></p>

---
<h3>Basic outline for the Algorithm for the second paper</h3>

<p>DCT coefficients of unmodified areas will undergo a double JPEG compression thus exhibiting double quantization (DQ) artifacts, while DCT coefficients of forged areas will result from a single compression and will likely present no artifacts. In the following, we will refer to this scenario as the single compression forgery (SCF) hypothesis.The idea is to use Bayesian inference to assign to each DCT coefficient a probability of being doubly quantized. Such probabilities,accumulated over each 8 × 8 block, will provide a DQ probability map allowing us to tell original areas (high DQ probability) from tampered areas (low DQ probability).Bayesian inference is based on the probability distribution of DCT coefficients conditional to the hypothesis of being tampered, i.e., p(x|H0), where x is the value of the DCT coefficient and H0 (H1) indicates the hypothesis of being tampered (original).</p>

---
<h3>Background</h3>
JPEG compression The compression of JPEG images involves three basic steps: 
<ol>
<li>DCT: An image is first divided into DCT blocks. Each block is subtracted by 128 and transformed to the YUV color space. Finally DCT is applied to each channel of the block.</li>
<li>Quantization: the DCT coefficients are divided by a quantization step and rounded to the nearest integer.</li>
<li>Entropy coding: lossless entropy coding of quantized DCT coefficients.
</ol>
The quantization steps for different frequencies are stored in quantization matrices (luminance matrix for Y channel or chroma matrix for U and V channels). Two important points to be noted are- 
<ol>
<li>The higher the compression quality is, the smaller the quantization step will be, and vice versa.</li>
<li>The quantization step may be different for different frequencies and different channels.</li>
</ol>
The decoding of a JPEG image involves the inverse of the previous three steps taken in reverse order: entropy decoding, de-quantization, and inverse DCT (IDCT). Unlike the other two operations, the quantization step is not invertible.<br>
Consequently, when an image is doubly JPEG-compressed, it will undergo the following steps and the DCT coefficients will change accordingly: 
<ol>
    <li>The first compression:</li>
    <ol>
        <li>DCT (suppose after this step a coefficient value u is obtained)</li>
        <li>The first quantization with quantization step Q1</li>
    </ol>
    <li>The first decompression:</li>
    <ol>
        <li>Dequantization with Q1 </li>
        <li>IDCT </li>
    </ol>
    <li>The second compression: </li>
    <ol>
        <li> DCT </li>
        <li> The second quantization with quantization step Q2</li>
    </ol>
</ol>

---
<h3>DQ effect</h3>

<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/dqEffectDerivation1.jpg"></p>
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/dqEffectDerivation2.jpg"></p>

Observation: The period is chosen as q1/gcd(q1,q2) otherwise q1/q2 is also a period but it is not an integer.

---
<h3>Period Estimation for paper1</h3>
Suppose s0 is the index of the bin that has the largest value. For each p between 1 and smax/20, we compute the following quantity:
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/periodEstimation1.jpg"></p>
where imax = (smax − s0)/p, imin = (smin − s0)/p, smax and smin are the maximum and minimum index of the bins in the histogram, respectively, and is a parameter (can be simply chosen as 1).<br>
Here we consider an example:
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/periodEstimation2.jpg"></p>
From the figure it is quite intuitive that the H(p) when p is equal to period and hence we can confirm this postulate.<br>
The portion of code that computes this period is given as-
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/periodEstimation3.jpg"></p>
we can use the fast Fourier transform to find the peak of the spectrum of the histogram with the direct current component removed. This gives another estimate pFFT of the period p. The portion of code that computes this period is given as-
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/periodEstimation4.jpg"></p>

---
<h3>Bayesian approach to detecting tampered blocks applicable for both papers</h3>
From the above analysis, we see that tampered blocks and unchanged blocks have different bias in terms of contributing to the bins of a histogram h: an unchanged one favors the high peaks of h, while a tampered one tends to contribute randomly to the bins of h.Our inference is based on this key observation.<br>
Suppose a period starts from the s0-bin and ends at the (s0+p−1)th bin, then the possibility of an unchanged block which contributes to that period occurring in the (s0 + i)-bin can be estimated as Here, h(k) denotes the value of the k-th bin of the DCT coefficient histogram h. On the other hand, the possibility of a tampered block which contributes to that period appearing in the bin (s0 + i) can be estimated as
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/bayesianApproach1.jpg"></p>

Here, h(k) denotes the value of the k-th bin of the DCT coefficient histogram h. On the other hand, the possibility of a tampered block which contributes to that period appearing in the bin (s0 + i) can be estimated as
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/bayesianApproach2.jpg"></p>

due to its randomness of contribution. From the naive Bayesian approach, if a block contributes to the (s0 +i)-th bin, then the posterior probability of it being a tampered block or an unchanged block is<br>
P(tampered|s0 + i) = Pt/(Pt + Pu)<br>
P(unchanged|s0 + i) = Pu/(Pt + Pu)<br>
The portion of code that computes this period is given as-<br>
For paper 1
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/bayesianApproach3.jpg"></p>
For paper 2
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/bayesianApproach4.jpg"></p>

---
<h3>Feature extraction for paper 1</h3>
If the image is tampered, we expect that tampered blocks cluster, i.e., the BPPM should be segmented into a small number of regions, where each region has a high probability of being either unchanged or tampered. While any image segmentation algorithm can be applied to the BPPM, to save computation time, we simply threshold the BPPM by choosing a threshold: 
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/featureExtraction1.jpg"></p>
where given a T, the pixels of the BPPM are classified into classes C0 and C1, respectively. in each class, respectively, and is the squared difference between the mean probabilities of the classes. With the optimal threshold, we expect that those pixels in class C0 (i.e., those having probabilities below Topt) correspond to the tampered blocks in the image.
However, this is still insufficient for confident decision because any BPPM can be segmented in the above manner as long as its variance is nonzero. Based on the segmentation, we can extract four features: Topt and the connectivity K0 of C0. We need the connectivity of C0 as a feature because we expect that the tampered blocks cluster if they exist.<br>
First, the BPPM is denoised by using a medium filter. Then, for each pixel i in C0, find the number ei of pixels in class C1 in its four neighborhood. Finally, we compute K0=
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/featureExtraction2.jpg"></p>
This definition is inspired by the perimeter–area ratio for shape description. <br>
With the four-dimensional feature vector , we can proceed to decide whether the image is tampered, by feeding the feature vector into a trained SVM. If the output is positive, then the DCT blocks that correspond to C0 of the BPPM are decided as the tampered region of the image.<br>
Corresponding code for feature extraction
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/featureExtraction3.jpg"></p>
Corresponding code for SVM training
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/featureExtraction4.jpg"></p>

---
<h3>Proposed DCT coefficient analysis for the second paper</h3>
In the case of a tampered image, however, a histogram will actually be a mixture of p(x|H1) and p(x|H0). Hence, for large forgeries we expect the histogram of x to be a poor estimate of p(x|H1). In order to overcome this limitation, we should be able to separate the two conditional probabilities from the observed mixture. By assuming that the histogram h0(x) of the DCT coefficients before the first JPEG compression is available, a better estimate of p(x|H1) could be obtained as
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/proposedAnalysis1.jpg"></p>
Unfortunately, this equation is difficult to use in practice, since it would require a reliable estimate of both h0(x) and Q1. Hence, it was proposed to introduce the following approximation 
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/proposedAnalysis2.jpg"></p>
The above approximation holds whenever n(x) > 0 and the histogram of the original DCT coefficient is locally uniform. In practice,it was found that for moderate values of Q2 this is usually true, except for the center bin (x = 0) of the AC coefficients, which have a Laplacian-like distribution.h ̃(x) can be viewed as the histogram of the DCT coefficients after a single compression with quantization step Q2. A simple technique for estimating h ̃(x) is to consider the DCT coefficients obtained by recompressing with the second quantization matrix a slightly cropped version of the tampered image. <br>
The portion of code that does this is:
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/proposedAnalysis3.jpg"></p>

---
<h3>Determination of Q1</h3>
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/q1Determination1.jpg"></p>
It is interesting to note that for determination of n(x) we need Q1 which we can estimate by the following proposal made in paper. where 𝜶 is the mixture parameter and we have highlighted the dependence of both p(x) and n(x) from Q1. Based on the above model, the actual value of Q1 can be estimated as 
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/q1Determination2.jpg"></p>
This is just the least square and the relation between 𝜶 and Q1 can be made as-
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/q1Determination3.jpg"></p>
The portion of code that does this is-
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/q1Determination4.jpg"></p>

---
<h3>Results and discussion</h3>
<ol>
<li>For the paper 1
We have written the code for training an SVM model with images corresponding to QF1 From 50 to 95 at a step of 5 and QF2 From 50 to 95 at a step of 5 for 20 iterations generating a tempered and untempered image at each iteration thus generating a total of 4000 images for training SVM and then used this Model for detecting 20 further images as forged or unforged but this requires a lot of computation power so instead we wrote code demo1.m which trains SVM with a fixed QF1 and varying QF2 with a step size of 5 from 50 to 95 and took i as 1 to train SVM(Giving 1 tampered and 1 untampered image into SVM) . Then we tried detecting the 20 images as forged or unforged and plotted the percentage of correct detections with varying Q2 keeping Q1 fixed and these were the results obtained:
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/results1.jpg"></p>
For Q1=80 and varying Q2
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/results2.jpg"></p>
For Q1 =95 and varying Q2
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/results3.jpg"></p>
For Q1=50 and varying Q2
Even to perform these tasks an average of 30 mins for implementation for a i5 processor.
Our results almost match the output given by the paper and hence we have replicated their results.
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/results4.jpg"></p>
Drawbacks The result of untampered singly compressed is given as a 0.5 probability map and does not clearly segregate this untampered image. <br>
The result of the image given here was not detected properly and forgery of this type might go unnoticed. If a forgery is introduced at 8*8 multiple position then it might be detected but as discussed with bhaiya that has a probability of just(1/64). Also the forgery might be introduced from a doubly compressed image and then detection will be very difficult.
<p align = "center">
    <img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/drawbacks1.jpg">
    <img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/drawbacks2.jpg">
</p>
</li>
<li>For the paper 2
We have written the code for calculating AUC of ROC curve with images corresponding to QF1 From 50 to 100 at a step of 10 and QF2 From 50 to 100 at a step of 10 with varying the threshold form 0 to 1 at a step of 0.00001 for 20 iterations of tampered images. All images have been taken of size 1024*1024 and the central portion of size 256 × 256 is then replaced with the corresponding area from the original TIFF image.finally, the overall “manipulated” image is JPEG compressed (again with Matlab) with another given quality factor QF2. In this way, the image will result doubly compressed everywhere, except in the central region where it is supposed to be forged. Both the considered algorithms provide as output, for each analyzed image, a probability map that represents the probability of each 8 × 8 block to be forged (i.e. for each 1024 × 1024i image a 128 × 128 probability map is given). For a particular threshold we determine pfa(false alarm rate) and pd (missed detection probability) which form the basis of the ROC curve and the area under this curve is calculated. Then the mean auc is calculated for each of the 36 combinations . But this requires a lot of computation power so instead we also wrote a code as demo1.m which takes iterations for a particular Q1 and Q2 for 1 iteration of image and then AUC is calculated and ROC is plotted. We do this for 5 image and take their mean and we were able to match the results as dictated in the paper.<br>
<h4 align = "center">AUC characteristic for different Q1 and Q2 for 5 image set</h4>
||Q1=50,Q2=50|Q1=50,Q2=80|Q1=50,Q2=100|Q1=80,Q2=50|Q1=80,Q2=80|Q1=80,Q2=100|Q1=100,Q2=50|Q1=100,Q2=80|Q1=100,Q2=100|
||-----------|-----------|------------|-----------|-----------|------------|------------|------------|-------------|
|Image 1|0.6173|0.9974|0.9994|0.5508|0.6851|0.9986|0.6715|0.6963|0.5004|
|Image 2|0.63|0.9965|0.991|0.5671|0.65|0.9989|0.6814|0.7104|0.4981|
|Image 3|0.61|0.9953|0.996|0.531|0.6712|0.9981|0.6914|0.6894|0.501|
|Image 4|0.58|0.998|0.994|0.546|0.691|0.9991|0.6413|0.6931|0.5007|
|Image 5|0.6134|0.991|0.991|0.561|0.63|0.9986|0.6614|0.7034|0.5004|
|Mean Value obtained|0.61014|0.99564|0.99428|0.55118|0.66546|0.99866|0.6694|0.69852|0.50012|
<br>
The tampering map example is given in the following which the highlighted yellow portion indicates forgery. 
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/drawbacks3.jpg"></p>
<p align = "center">ROC curve example</p>
<p align = "center"><img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/drawbacks4.jpg"></p>
Advantages over Algorithm1: It even works well when QF1 > QF2 which is not in the case of algorithm 1. It does require to train a SVM but rather makes decision on the basis of the optimum threshold value which is kept near 0.52 which generates the best result.<br>
Drawback : Also the forgery might be introduced from a doubly compressed image and then detection will be very difficult. The result of the image given here was not detected properly and forgery of this type might go unnoticed.
<p align = "center">
    <img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/drawbacks5.jpg">
    <img src = "https://github.com/PratikPuri/Image-Forgery-Detection-And-Localization/blob/feature-readme/images/drawbacks6.jpg">
</p>
</li>
</ol>

---
<h3>Learnings:</h3>
<ol>
<li>Basis of Forgery detection.</li>
<li>SVM method being used as a classifier. </li>
<li>Learnt about ROC and significance of AUC curve. </li>
<li>DQ effect and its significance for forgery. </li>
<li>Bayesian classifiers. </li>
<li>A prominent method for feature extraction </li>
<li>Use of gaussian kernels for removing the R/T errors. </li>
<li>Proposed DCT coefficient analysis</li>
</ol>