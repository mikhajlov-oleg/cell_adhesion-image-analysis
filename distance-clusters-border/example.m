% Load cell contours from data file
Tcircular = readtable('circular-cell.csv');
Tirregular = readtable('irregular-shape-cell.csv');

% Pixel to µm conversion
pix2um = 0.11;

% Plot cell contours 
figure('Position',[475,312,897,403])
subplot(1,2,1)
patch(pix2um*Tcircular.x,pix2um*Tcircular.y,'r')
axis(pix2um*[-150 250 -175 350])
xlabel('x (µm)')
ylabel('y (µm)')
box on
axis equal

subplot(1,2,2)
patch(pix2um*Tirregular.x,pix2um*Tirregular.y,'b')
axis(pix2um*[0 400 -50 500])
xlabel('x (µm)')
ylabel('y (µm)')
box on
axis equal

% Calculate distance of *UNIFORMLY DISTRIBUTED* clusters to the cell edge
dcircular = pix2um*distance2edge(Tcircular.x,Tcircular.y);
dirregular = pix2um*distance2edge(Tirregular.x,Tirregular.y);

% Display average uniform distance on plot
subplot(1,2,1)
title(['d_{uniform} = ' num2str(dcircular) ' µm'])

subplot(1,2,2)
title(['d_{uniform} = ' num2str(dirregular) ' µm'])