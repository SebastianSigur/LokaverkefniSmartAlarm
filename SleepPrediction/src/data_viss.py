import pandas as pd
import matplotlib.pyplot as plt
from src.model import getData, defineModel, trainModel, SleepStage
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import confusion_matrix
from sklearn.metrics import cohen_kappa_score

import matplotlib.pyplot as plt

def plot_last_value_with_labels(X, y, labels=None):
    print(X)
    last_values = X[:, -1] # Extract the last value (mean_hr) from each sequence
    unique_labels = np.unique(y)

    if labels is None:
        labels = unique_labels

    for label in unique_labels:
        label_indices = np.where(y == label)
        plt.scatter(last_values[label_indices], y[label_indices], label=labels[label], alpha=0.5)

    plt.xlabel('Last Mean Heart Rate')
    plt.ylabel('Sleep Stage')
    plt.legend(loc='upper right')
    plt.title('Last Mean Heart Rate vs Sleep Stage')
    plt.show()
X_train, X_test, y_train, y_test, n_steps = getData(visualize=False, test_size=0.2, mapping={0:[SleepStage.Wake], 1:[SleepStage.N1],2:[SleepStage.N2],3:[SleepStage.N3],4:[SleepStage.N4],5:[SleepStage.REM]})

stage_labels = {0: 'Wake', 1: 'N1', 2: 'N2', 3: 'N3', 4: 'N4', 5: 'REM'}
plot_last_value_with_labels(X_train[:, -1, 0], y_train, stage_labels)



