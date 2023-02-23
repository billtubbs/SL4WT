% Examples from Matlab documentation


%% Example 1

% Note: This example requires a data file to be downloaded

% tbl = readtable('abalone.data','Filetype','text',...
%      'ReadVariableNames',false);
% tbl.Properties.VariableNames = {'Sex','Length','Diameter','Height',...
%      'WWeight','SWeight','VWeight','ShWeight','NoShellRings'};
% 
% % Fit a GPR model using the subset of regressors method for parameter 
% % estimation, fully independent conditional method for prediction,
% % and standardize the predictors.
% gprMdl = fitrgp(tbl,'NoShellRings','KernelFunction','ardsquaredexponential',...
%       'FitMethod','sr','PredictMethod','fic','Standardize',1);
% 
% % Predict the responses using the trained model
% ypred = resubPredict(gprMdl);
% 
% figure(1);
% plot(tbl.NoShellRings,'r.');
% hold on
% plot(ypred,'b');
% xlabel('x');
% ylabel('y');
% legend({'data','predictions'},'Location','Best');
% axis([0 4300 0 30]);
% hold off;


%% Example 2

clear variables

rng(0,'twister'); % For reproducibility
n = 1000;
x = linspace(-10,10,n)';
y = 1 + x*5e-2 + sin(x)./x + 0.2*randn(n,1);

gprMdl = fitrgp(x,y,'Basis','linear',...
      'FitMethod','exact','PredictMethod','exact');

ypred = resubPredict(gprMdl);

% figure(2); clf
% plot(x,y,'b.');
% hold on;
% plot(x,ypred,'r','LineWidth',1.5);
% xlabel('x');
% ylabel('y');
% legend('Data','GPR predictions');
% hold off

% Check results match those from original code
assert(isequal(round(ypred(1:50:end), 6), [ ...
     0.547290  0.616969  0.701296  0.719353  0.639017  0.545164 ...
     0.595494  0.885246  1.348902  1.790963  2.007892  1.905910 ...
     1.559434  1.180125  0.983236  1.034072  1.224698  1.402893 ...
     1.497205  1.520400 ... 
]'))


%% Example 3

clear variables

load('gprdata2.mat')

% Fit default GP model
gprMdl1 = fitrgp(x, y, ...
    'KernelFunction', 'squaredexponential' ...
);

% Specify initial values for parameters
sigma0 = 0.2;
kparams0 = [3.5, 6.2];
gprMdl2 = fitrgp(x, y, ...
    'KernelFunction', 'squaredexponential', ...
    'KernelParameters', kparams0, ...
    'Sigma', sigma0 ...
);

ypred1 = resubPredict(gprMdl1);
ypred2 = resubPredict(gprMdl2);

% figure(3); clf
% plot(x,y,'r.');
% hold on
% plot(x,ypred1,'b');
% plot(x,ypred2,'g');
% xlabel('x');
% ylabel('y');
% legend({'data','default kernel parameters',...
% 'kparams0 = [3.5,6.2], sigma0 = 0.2'},...
% 'Location','Best');
% title('Impact of initial kernel parameter values');
% hold off

% Check results match those from original code
assert(isequal(round(ypred1(1:50:end), 6), [ ...
    3.532752  4.020919  4.914140  5.976234  7.020612  7.999264 ...
    8.978890 10.024299 11.082117 11.958451 12.411325
]'))
assert(isequal(round(ypred2(1:50:end), 6), [ ...
    3.009579  3.034660  4.423676  6.653578  7.892795  7.838956 ...
    8.028187  9.607758 11.825877 12.767466 12.791129 ...
]'))