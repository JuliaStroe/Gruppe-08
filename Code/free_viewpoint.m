function [output_image]  = free_viewpoint(image1, image2, p)
% This function generates an image from a virtual viewpoint between two
% real images. The output image has the same size as the input images.
devMode =true;
%% Algorithmus
%% Umwandlung der Bilder in Graubilder
disp('-------------conversion to gray pictures--------------')
IGray1 = rgb_to_gray(image1);
IGray2 = rgb_to_gray(image2);

%% Intensitäts und Beleuchtungskorrektur
disp('-------------bias gain correction of images-----------')
IGray1 = gain_offset_correction_cdf(IGray1);
IGray2 = gain_offset_correction_cdf(IGray2);

%% Bilateralte Filterung
% Kanten sollen sich gut von homogenen Flächen abheben können
IGray1 = uint8(bfltGray(double(IGray1),12,100,15));
IGray2 = uint8(bfltGray(double(IGray2),12,100,15));

%% Harris-Merkmale berechnen
disp('-------------getting feature points--------------')
% Robuste Einstellungen 'segment_length',15,'k',0.12,'min_dist',10,'N',20
Merkmale1 = harris_detektor(IGray1,'segment_length',15,'k',0.15,'min_dist',20,'N',40,'do_plot',devMode);
Merkmale2 = harris_detektor(IGray2,'segment_length',15,'k',0.15,'min_dist',20,'N',40,'do_plot',devMode);

%% Korrespondenzschaetzung
disp('-------------estimation correspondence points--------------')
% Robuste Einstellungen 'window_length',55,'min_corr',0.9
Korrespondenzen = punkt_korrespondenzen(IGray1,IGray2,Merkmale1,Merkmale2,'window_length',45,'min_corr',0.95,'do_plot',devMode);

%% Finde robuste Korrespondenzpunktpaare mit Hilfe des RANSAC-Algorithmus
disp('-------------finding robust correspondence points--------------')
Korrespondenzen_robust = F_ransac(Korrespondenzen,'epsilon',0.7, 'tolerance', 0.01);

% Zeige die robusten Korrespondenzpunktpaare
if(devMode)
    disp('-------------plot robust correspondence points--------------')
    figure
    im1 = imshow(IGray1);
    hold all;
    im2 = imshow(IGray2);
    im1.AlphaData = 0.5;
    im2.AlphaData = 0.5;
    plot(Korrespondenzen_robust(1,:),Korrespondenzen_robust(2,:),'*r');
    plot(Korrespondenzen_robust(3,:),Korrespondenzen_robust(4,:),'*g');
    for i = 1:length(Korrespondenzen_robust(1,:))
        plot([Korrespondenzen_robust(1,i) Korrespondenzen_robust(3,i)],[Korrespondenzen_robust(2,i) Korrespondenzen_robust(4,i)],'b');
    end
end

%% Berechne die Essentielle Matrix
% Kamerakalibrierungsmatrix ist in KK.mat enthalten und wurde mit in der
% Video-Vorlesung angegebenen Toolbox bestimmt.
disp('-------------essential matrix calculation--------------')

load('calib_K.mat');
K = K;

E = achtpunktalgorithmus(Korrespondenzen_robust,K);
% F = achtpunktalgorithmus(Korrespondenzen_robust);
% disp(E);
% disp(F);
[T1, R1, T2, R2, U, V] = TR_aus_E(E);

[T_cell, R_cell,T,R, d_cell, x1, x2] = ...
    rekonstruktion(T1, T2, R1, R2, Korrespondenzen_robust, K);


%% Bildrektifizierungsalgorithmus
disp('-------------rectification--------------')
[img1_rectified, img2_rectified, Tr1, Tr2, offset_x_pixel] = ...
    rectification(IGray1,IGray2,K,T,R,'do_plot',devMode,'size_frame','valid_offset');
save('zwspeicher.nat')

%% Disparitätsermittling
disp('---------disparity estimation-----------')

% [depth_map] = ...
%     depth_estimation(img1_rectified,img2_rectified,'do_plot',devMode);


%% Ausgabe des Free-Viewpoint Bildes
output_image = uint8(p*image1+(1-p)*image2);
end

