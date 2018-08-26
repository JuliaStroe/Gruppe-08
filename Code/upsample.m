function [img_up] = upsample(img,steps,odd_even_xy)
%UPSAMPLE Summary of this function goes here
%   Detailed explanation goes here
for i=1:steps
    [row,col]=size(img);
%     if(mod(col,2) == 1 & i<=steps)
    if(odd_even_xy(steps+1-i,2) == 0)

        col_new = col+0.5;
    else
        col_new = col;
    end
    
%     if(mod(row,2) == 1 & i<=steps)
    if(odd_even_xy(steps+1-i,1) == 0)
        row_new = row+0.5;
    else
        row_new = row;
    end

    
    img = interp2((1:col)',1:row_new,img,(1:0.5:col_new)',1:0.5:row_new);
    size(img) %for debugging purpose
end
img_up = img;
end

