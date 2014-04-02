close all;
clear all;

ResourcePath = 'H:\Matlab\Resource';
Helper = 'H:\Matlab\LVTN\helper';
addpath(ResourcePath);
addpath(Helper);

vid = vision.VideoFileReader('street.avi');

oldframe = grayScale(step(vid));
newframe = grayScale(step(vid));

[u,v] = HornSchunk(oldframe, newframe);
bwIm = (u.*u + v.*v) > 0.00005;


B = blobBoundaries(bwIm,300);

subplot(1,2,1),imshow(oldframe);
subplot(1,2,2),imshow(bwIm);

disp(B);
