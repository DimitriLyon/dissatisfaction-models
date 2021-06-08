# Models for detecting dissatisfaction in spoken dialog

## Set up

1. Clone this repo or download it as a ZIP and extract.
1. Download [The UTEP Corpus of Dissatisfaction in Spoken Dialog](https://github.com/joneavila/utep-dissatisfaction-corpus). Place the `calls`
   folder, `annotations` folder, and `call-log.xlsx` in the root of this project.
1. Download [Midlevel Prosodic Features Toolkit](https://github.com/nigelgward/midlevel). Place the `midlevel-master` folder
   in the root of this project.
1. Open this project
(the `dissatisfaction-models` folder) in MATLAB.
1. Install MATLAB's [Signal Processing Toolbox](https://www.mathworks.com/products/signal.html).
1. **Add the project folder and its subfolders to
   Path.** Right-click the folder in the Current Folder window or use the
   [addpath](https://www.mathworks.com/help/matlab/ref/addpath.html) function.

## Annotations

Customer utterances were annotated for dissatisfaction (see [The UTEP Corpus of Dissatisfaction in Spoken Dialog](https://github.com/joneavila/utep-dissatisfaction-corpus)). For the frame-level and utterance-level models below, the labels `n` and `nn` are read as 0 (negative class, neutral), `d` and `dd` are read as 1 (positive class, dissatisfied), and all other labels are ignored.

## linearRegressionDialog.m

A dialog-level linear regression model.

The first regressor is trained using the feature set specified in [mono.fss](mono.fss). The second regressor is trained using features based on the frame predictions of the first regressor. For each dialog, the summary features are: (1) the fraction of frames above a *dissatisfaction threshold* (see [linearRegressionFrame.m](#linearRegressionFrame.m)); (2) its minimum dissatisfaction value; (3) its maximum dissatisfaction value; (4) its mean dissatisfaction value;
(5) the range of its dissatisfaction values; and (6) the standard deviation of its dissatisfaction values.

The summary features are computed for each dialog from (including) the first non-`o` (out of character) utterance to (including) the last non-`o` utterance.

For training, validation, and test sets, see [source/tracklists-dialog](source/tracklists-dialog). The baseline always predicts a value of 1 for perfectly dissatisfied. Results on the test set:

```none
beta=0.25, min(yPred)=-20.39, max(yPred)=5.22, mean(yPred)=0.21
dissThreshold=0.755
regressorFscore=0.68, regressorPrecision=0.86, regressorRecall=0.16, regressorMSE=6.75
baselineFscore=0.52, baselinePrecision=0.51, baselineRecall=1.00, baselineMSE=0.49
```

## linearRegressionFrame.m

A frame-level linear regression model.

For training, validation, and test sets, see [source/tracklists-frame](source/tracklists-frame). Each set comprises 6
dialogs, half labeled as neutral and half labeled as dissatisfied. The dissatisfied dialogs typically have more neutral frames compared to dissatisfied frames, so the training data is balanced in code.

The learned coefficients are printed in descending order:

```none
Coefficients in descending order with format:
coefficient number, value, feature abbreviation
 16 | 0.160004 | se vo  +1600  +3200
 78 | 0.151007 | se wp  +800  +1600
 59 | 0.115827 | se np -1600 -800
  1 | 0.110473 | se vo -3200 -1600
 14 | 0.107677 | se vo  +400  +800
...
 57 | -0.071638 | se th  +400  +800
 44 | -0.078300 | se tl  +800  +1600
 30 | -0.082371 | se cr  +800  +1600
108 | -0.095654 | se pd  +800  +1600
  2 | -0.227057 | se vo -1600 -800
```

With time feature included:
```none
Coefficients in descending order with format:
coefficient number, value, feature abbreviation
119 | 0.180460 | time into dialog
78 | 0.156935 | se wp  +800  +1600
59 | 0.148045 | se np -1600 -800
45 | 0.136897 | se th -1600 -800
16 | 0.126064 | se vo  +1600  +3200
...
76 | -0.065106 | se wp  +300  +400
71 | -0.068658 | se wp -400 -300
108 | -0.089846 | se pd  +800  +1600
30 | -0.104341 | se cr  +800  +1600
 2 | -0.285015 | se vo -1600 -800
 ```

The baseline always predicts a value of 1 for perfectly dissatisfied. Results on the test set:

```none
beta=0.25, min(yPred)=-1.13, max(yPred)=7.16, mean(yPred)=0.55
regressorRsquared=0.28
dissThreshold=0.370
regressorFscore=0.49, regressorPrecision=0.48, regressorRecall=0.71, regressorMSE=0.46
baselineFscore=0.45, baselinePrecision=0.43, baselineRecall=1.00, baselineMSE=0.57
```

With time feature included:

```none
beta=0.25, min(yPred)=-3.16, max(yPred)=5.53, mean(yPred)=0.53
regressorRsquared=0.35
dissThreshold=0.411
regressorFscore=0.58, regressorPrecision=0.57, regressorRecall=0.81, regressorMSE=0.35
baselineFscore=0.45, baselinePrecision=0.43, baselineRecall=1.00, baselineMSE=0.57
```

## linearRegressionUtterance.m

An utterance-level linear regression model. For each utterance, this model predicts the mean, predicted dissatisfaction values for the frames in the utterance. This model shares the frame-level's
training, validation, and test set. 

The baseline always predicts a value of 1 for perfectly dissatisfied. Results on the test set:

```none
beta=0.25, min(yPred)=-0.02, max(yPred)=1.25, mean(yPred)=0.52
dissThreshold=0.922
regressorFscore=0.79, regressorPrecision=1.00, regressorRecall=0.18, regressorMSE=0.27
baselineFscore=0.39, baselinePrecision=0.38, baselineRecall=1.00, baselineMSE=0.62
```

With time feature included:

```none
beta=0.25, min(yPred)=-0.03, max(yPred)=1.30, mean(yPred)=0.50
dissThreshold=0.571
regressorFscore=0.62, regressorPrecision=0.62, regressorRecall=0.73, regressorMSE=0.25
baselineFscore=0.39, baselinePrecision=0.38, baselineRecall=1.00, baselineMSE=0.62
```

## calculateCorpusStats.m

Print the number of neutral and dissatisfied frames in the dialog-level sets and print the number of neutral and dissatisfied utterances in the dialog-level sets. Output:

```none
train frames
	neutral=8335, dissatisfied=7899
dev frames
	neutral=14084, dissatisfied=7581
test frames
	neutral=54543, dissatisfied=20893
train utterances
	neutral=46 (n=33, nn=13), dissatisfied=24 (d=16, dd=8)
dev utterances
	neutral=52 (n=43, nn=9), dissatisfied=23 (d=14, dd=9)
test utterances
	neutral=256 (n=200, nn=56), dissatisfied=82 (d=63, dd=19)
```
