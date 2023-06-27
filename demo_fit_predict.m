% Compare various regression and prediction functions

clear variables

% Some data
X = [239.38 254.46 266.06 269.20 277.59]';
Y = [194.72 201.03 206.94 209.58 212.32]';

% Make predictions at
x = linspace(230, 290, 61)';

% Fit LR model
LR = struct();
LR.model = fitlm(X, Y);

% Fit polynomial model
POLY = struct('fit_type', "poly3");
[POLY.model, POLY.gof, POLY.output] = fit(X, Y, POLY.fit_type, 'Normalize', 'on');

% Fit GPR model
GPR = struct();
GPR.model = fitrgp(X, Y);

% Make predictions at new points
[LR.y_mean, LR.y_int] = predict(LR.model, x, 'Alpha', 0.1, 'Prediction', 'Observation');
[POLY.y_int, POLY.y_mean] = predint(POLY.model, x, 0.9, 'Observation', 'off');
[GPR.y_mean, GPR.y_sigma, GPR.y_int] = predict(GPR.model, x, 'Alpha', 0.1);

figure(1); clf
Y_pred = [LR.y_mean POLY.y_mean GPR.y_mean];
Y_lb = [LR.y_int(:,1) POLY.y_int(:,1) GPR.y_int(:,1)];
Y_ub = [LR.y_int(:,2) POLY.y_int(:,2) GPR.y_int(:,2)];
y_labels = ["LR", "POLY", "GPR"];
ax = make_statdplot(Y_pred, Y_lb, Y_ub, x, Y, X, "$x$", y_labels, "$\hat{y}(x)$", "90\% CI");
ylabel("$\hat{y}(x)$")
p = get(gcf, 'Position');
set(gcf, 'Position', [p(1:2) 420 315])
