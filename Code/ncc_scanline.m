function [disparity_map] = ncc_scanline(img1,img2,window_length,offset_pix,min_corr)
%NCC_SCANLINE Summary of this function goes here
%   Detailed explanation goes here

% �berpr�fen ob beide Bilder gleiche Anzahl an Zeilen haben
size_img1 = size(img1);
size_img2 = size(img2);

img1 = double(img1);
img2 = double(img2);

if(size_img1(1) ~=size_img2(1))
    error('Bilder haben nicht die gleiche Anzahl an Zeilen')
end

if(mod(window_length,2)==0)
    error('window_length must be odd')
end

if(size_img1(2)<size_img2(2))
    img2 = img2(1:size_img1(1),1:size_img1(2));
elseif(size_img1(2)>size_img2(2))
    img1 = img1(1:size_img2(1),1:size_img2(2));
end

size_x = size(img1,2);
size_y = size(img1,1);

% Rand f�r Bildsegmentauswahl zur Verf�gung stellen
border_dist = floor(window_length/2);

% Mpt1-Vektor (Merkmalspunkte im Bild 1 entlang x-Achse)
Mpt1 = (border_dist+1):(size_x-border_dist-1);

% Mpt2-Vektor (Merkmalspunkte im Bild 2 entlang x-Achse)
Mpt2 = (border_dist+1):(size_x-border_dist-1);

% F�r Schleife ben�tigte Parameter
window_length_squared = window_length^2;
disparity_map = zeros(size_y,size_x);
disparity_map_L = zeros(size_y,size_x);
disparity_map_R = zeros(size_y,size_x);

% Zeilenweise wird SAD berechnet
for zeile = (border_dist+1):1:(size_y-border_dist-1)
    % Berechnen der oberen und unteren Fenster indizes
    low_y = zeile-border_dist;
    up_y = zeile+border_dist;
    low_x = Mpt1-border_dist;
    up_x = Mpt1+border_dist;
    
    low2_y = zeile-border_dist;
    up2_y = zeile+border_dist;
    low2_x = Mpt1-border_dist;
    up2_x = Mpt1+border_dist;
    
    % Bestimme Disparity-Band
%     max_disparity =  -100; %abs(max(max(rough_disparity(low_y:up_y,:)))+offset_pix);
%     min_disparity = 100; %abs(min(min(rough_disparity(low_y:up_y,:)))+offset_pix);
    
    % �ber jedes Pixel der Zeile von Bild1 wird Box extrahiert
    for i = 1:length(Mpt1)
        % Bildausschnitt extrahieren
        boxes_img1(:,i) = reshape(img1(low_y:up_y,low_x(i):up_x(i)),[window_length_squared,1])...
            -mean(mean(img1(low_y:up_y,low_x(i):up_x(i))));
        sigma_box = sqrt(1/(numel(boxes_img1(:,i))-1)*trace((boxes_img1(:,i))'*(boxes_img1(:,i))));
        norm_box_img1(:,i) = 1/sigma_box*(boxes_img1(:,i));
    end
    % �ber jedes Pixel der Zeile von Bild1 wird Box extrahiert
    for i = 1:length(Mpt2)
        % Bildausschnitt extrahieren
        boxes_img2(:,i) = reshape(img2(low_y:up_y,low_x(i):up_x(i)),[window_length_squared,1])...
            -mean(mean(img2(low_y:up_y,low_x(i):up_x(i))));
        sigma_box = sqrt(1/(numel(boxes_img2(:,i))-1)*trace((boxes_img2(:,i))'*(boxes_img2(:,i))));
        norm_box_img2(:,i) = 1/sigma_box*(boxes_img2(:,i));
    end
    
    for i = 1:1:length(Mpt1)
        NCC = 1/(window_length_squared-1)*norm_box_img1(:,i)'*norm_box_img2;
        [val, idx] = sort(NCC,'descend','MissingPlacement','last');
        idx_max = ceil(mean(idx(val == max(val))));
        if(~isempty(idx) & ~isnan(idx_max) & val(1)>min_corr)
            new_disparity = Mpt1(i)- Mpt2(idx_max)+offset_pix;%max(min(Mpt1(i)- Mpt2(idx_max)+offset_pix,500),50);
            disparity_map_L(zeile,i)= new_disparity;
        end
    end
    
   disp(zeile);
end
disparity_map = disparity_map_L;%0.5*(disparity_map_R+disparity_map_L);
end

