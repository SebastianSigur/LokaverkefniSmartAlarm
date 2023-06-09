import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from tensorflow.keras.models import load_model
from sklearn.metrics import confusion_matrix
from sklearn.metrics import cohen_kappa_score
from src.model import prepare_data_for_training, SleepStage, custom_loss
from sklearn.metrics import accuracy_score
from sklearn.metrics import accuracy_score, cohen_kappa_score

class SleepStage:
    Wake = 0
    N1 = 1
    N2 = 2
    N3 = 3
    N4 = 4
    REM = 5
    unscored = -1

def plot(y_pred, y_true):
    data = np.array(y_pred)
    real_stages = np.array(y_true).ravel()

    # Determine the most likely state for each time point
    predicted_stages = y_pred

    # Create an array for the x-axis (time)
    time_points = np.arange(len(data))

    # Create subplots
    fig, (ax1, ax2) = plt.subplots(2, 1, sharex=True)

    # Plot the lines for real sleep stages
    ax1.plot(time_points, real_stages, label='Real')
    ax1.set_ylabel('Sleep Stage')
    ax1.set_title('Real Sleep Cycle')

    sleep_m={0:[SleepStage.Wake],1:[SleepStage.N1,SleepStage.N2], 2:[SleepStage.REM],3:[SleepStage.N3,SleepStage.N4]}
    ax1.set_yticks([0, 1, 2, 3])
    ax1.set_yticklabels(['Awake', 'light sleep','REM', 'Deep Sleep'])

    
    ax1.legend()

    # Plot the lines for predicted sleep stages
    ax2.plot(time_points, predicted_stages, label='Predicted')
    ax2.set_xlabel('Time')

    ax2.set_ylabel('Sleep Stage')
    ax2.set_title('Predicted Sleep Cycle')
    ax2.set_yticks([0, 1, 2, 3])
    ax2.set_yticklabels(['Awake', 'light sleep','REM', 'Deep Sleep'])


    ax2.legend()

    # Adjust layout and show the plots
    plt.tight_layout()
    plt.show()

def create_dataframe(subject_data, feature_extraction=False):
    heart_rate_data = [x for x in subject_data if 'heart_rate' in x]
    sleep_stage_data = [x for x in subject_data if 'stage' in x]
    heart_rate_df = pd.DataFrame(heart_rate_data).sort_values(by='seconds')
    sleep_stage_df = pd.DataFrame(sleep_stage_data).sort_values(by='seconds')

    heart_rate_df['stage'] = None
    last_sleep_stage_time = sleep_stage_df['seconds'].max()
    for index, row in heart_rate_df.iterrows():

        if row['seconds'] < 0:
            heart_rate_df.at[index, 'stage'] = 0
        elif row['seconds'] > last_sleep_stage_time:
            heart_rate_df.at[index, 'stage'] = None
        else:
            closest_index = sleep_stage_df['seconds'].sub(row['seconds']).abs().idxmin()
            heart_rate_df.at[index, 'stage'] = sleep_stage_df.at[closest_index, 'stage']

    # Remove rows with 'stage' set to None
    heart_rate_df.dropna(subset=['stage'], inplace=True)

    heart_rate_df.index = pd.to_timedelta(heart_rate_df['seconds'], unit='s')
    time_windows = ['5T', '10T', '30T']  # 'T' stands for minutes

    for window in time_windows:
        heart_rate_df[f'heartRateDeviation_last_{window[:-1]}_min'] = heart_rate_df['heart_rate'].rolling(window=window, min_periods=1, center=False).apply(lambda x: np.std(x) / np.mean(x), raw=True)
        #heart_rate_df[f'heartRateMean_last_{window//60}_min'] = heart_rate_df['heart_rate'].rolling(window=window, min_periods=1, center=False).mean()
    

    for window in time_windows:
        heart_rate_df[f'heartVariability_last_{window[:-1]}_min'] = heart_rate_df['heart_rate'].rolling(window=window, min_periods=1, center=False).apply(lambda x: np.std(x), raw=True)
        heart_rate_df[f'RMSSD_last_{window[:-1]}_min'] = heart_rate_df['heart_rate'].rolling(window=window, min_periods=1, center=False).apply(rmssd, raw=True)

    for window in time_windows:
        mean_heart_rate = heart_rate_df['heart_rate'].rolling(window=window, min_periods=1).mean()
        heart_rate_df[f'heart_rate_last_{window[:-1]}_min'] = heart_rate_df['heart_rate'] / mean_heart_rate
        
    heart_rate_df.dropna(subset=['heart_rate'], inplace=True)
    return heart_rate_df

def rmssd(heart_rates):
    if len(heart_rates) <= 1:
        return 0
    differences = np.diff(heart_rates)
    squared_diff = np.square(differences)
    mean_squared_diff = np.mean(squared_diff)
    return np.sqrt(mean_squared_diff)

def getTestData():

    data_dict = {}

    # loop through the heart_rate directory and read the files
    for filename in os.listdir('data/test2'):
        x = 0
        if filename.endswith('.txt') and 'heart' in filename:
            
            with open(os.path.join('data/test2', filename), 'r') as f:
                x = 0
                for line in f:
                    if x == 0:
                        x+=1
                        subject_id = line.strip()
                        continue
                    # split the line into seconds and heart rate values
                    seconds, heart_rate = line.strip().split(',')
                    # add the data to the dictionary
                    if subject_id in data_dict:
                        data_dict[subject_id].append({'filename': filename, 'seconds': float(seconds), 'heart_rate': float(heart_rate)})
                    else:
                        data_dict[subject_id] = [{'filename': filename, 'seconds': float(seconds), 'heart_rate': float(heart_rate)}]

    # loop through the labels directory and read the files
    for filename in os.listdir('data/test2') :
        if filename.endswith('_labeled_sleep.txt'):
            subject_id = filename.split('_')[0]
            with open(os.path.join('data/test2', filename), 'r') as f:
                for line in f:
                    # split the line into date and stage values
                    date, stage = line.strip().split()
                    # add the data to the dictionary
                    if subject_id in data_dict:
                        data_dict[subject_id].append({'filename': filename, 'seconds': float(date), 'stage': float(stage)})
                    else:
                        data_dict[subject_id] = [{'filename': filename, 'seconds': float(date), 'stage': float(stage)}]

    
    dataframes = {}
    for subject_id, subject_data in data_dict.items():
        dataframes[subject_id] = create_dataframe(subject_data)
    return dataframes

def combine_stages(stage, mapping):
    for key, stages in mapping.items():
        if stage in stages:
            return key
    return stage


def combine_pred(y_pred_wake_sleep, model_light_deep, y_pred_s_sleep):
    sleep_m={0:[SleepStage.Wake],1:[SleepStage.N1,SleepStage.N2], 2:[SleepStage.REM],3:[SleepStage.N3,SleepStage.N4]}
    pred = []
    for wake_sleep,light_deep, s_sleep in zip(y_pred_wake_sleep, model_light_deep, y_pred_s_sleep):
        if wake_sleep == 0:
            #Awake 
            pred.append(0)
        else:
            if light_deep == 0:
                if s_sleep == 0:
                    #REM
                    pred.append(2)
                else:
                    #LIGHT
                    pred.append(1)
            else:
                #DEEP
                pred.append(3)
    return pred

def combine_pred_s_l(y_pred_wake_sleep, model_light_deep):
    sleep_m={0:[SleepStage.Wake],1:[SleepStage.N1,SleepStage.N2], 2:[SleepStage.REM],3:[SleepStage.N3,SleepStage.N4]}
    pred = []
    for wake_sleep,light_deep in zip(y_pred_wake_sleep, model_light_deep):
        if wake_sleep == 0:
            #Awake 
            pred.append(0)
        else:
            if light_deep == 0:
                #LIGHT
                pred.append(1)
            else:
                #DEEP
                pred.append(3)
    return pred


def write_to_file(pred, data, file_to_write_to = './predicted_sleep_stage.txt'):

 

    df = pd.DataFrame(data)
    # Check if the length of the lines is the same as the length of pred
    
    assert len(df) == len(pred), "The length of the lines and pred are not the same"
    df['predicted_sleep_stage'] = pred
    with open(file_to_write_to, 'w') as f:
        for index, row in df.iterrows():
            f.write(f"{row['seconds']} {row['predicted_sleep_stage']}\n")

def change_values_to_majority(arr, n):
    length = len(arr)
    new_arr = [0] * length

    for i in range(length):
        left = max(0, i - n)
        right = min(length, i + n + 1)
        neighbors = arr[left:right]

        ones = neighbors.count(1)
        zeros = neighbors.count(0)
        new_arr[i] = 1 if ones > zeros else 0

    return new_arr

from sklearn.metrics import accuracy_score, cohen_kappa_score, confusion_matrix, roc_auc_score

def calculate_performance_metrics(y_true, y_pred, wake_threshold=0.6):
    # Convert probabilities to class labels
    y_pred_labels = (y_pred[:, 1] > wake_threshold).astype(int)

    accuracy = accuracy_score(y_true, y_pred_labels)

    kappa = cohen_kappa_score(y_true, y_pred_labels)

    # Calculate confusion matrix
    cm = confusion_matrix(y_true, y_pred_labels)

    # Calculate Wake correct (specificity) and Sleep correct (sensitivity)
    wake_correct = cm[0, 0] / (cm[0, 0] + cm[0, 1])
    sleep_correct = cm[1, 1] / (cm[1, 0] + cm[1, 1])


    auc = roc_auc_score(y_true, y_pred[:, 1])

    return {
        "Accuracy": accuracy,
        "Wake Correct (Specificity)": wake_correct,
        "Sleep Correct (Sensitivity)": sleep_correct,
        "Cohen's Kappa": kappa,
        "AUC": auc
    }
def test():
    
    models = ['./models/sleep_weight_n60v13.h5', './models/light_deep_n60v13.h5', './models/REM_n60v13.h5']
    mappings = [
        {0: [SleepStage.Wake], 1: [SleepStage.N1, SleepStage.N2, SleepStage.N3, SleepStage.N4, SleepStage.REM]},
        {0: [SleepStage.Wake], 1: [SleepStage.N1, SleepStage.N2, SleepStage.REM], 2: [SleepStage.N3, SleepStage.N4]},
        {0: [SleepStage.Wake], 1: [SleepStage.REM], 2: [SleepStage.N1, SleepStage.N2, SleepStage.N3, SleepStage.N4]}
    ]
    predictions_mapping = {j:i for i ,j in zip(models, ['SW', 'LD', 'REM'])}
    predicitons = {}
    cm_train = []
    cm_test = []
    accuracies_train = []
    accuracies_test = []
    kappa_scores_train = []
    kappa_scores_test = []

    for i, model_path in enumerate(models):
        model = load_model(model_path, custom_objects={'custom_loss': custom_loss})
        X_train, Y_train, X_test, Y_test = prepare_data_for_training(fetch=False, visualize=False, mapping=mappings[i])

        if i > 0:
            # Remove instances where the y label is 0
            valid_indices_train = [j for j, y in enumerate(Y_train) if y != 0]
            X_train = np.array([X_train[j] for j in valid_indices_train])
            Y_train = np.array([Y_train[j] - 1 for j in valid_indices_train])

            valid_indices_test = [j for j, y in enumerate(Y_test) if y != 0]
            X_test = np.array([X_test[j] for j in valid_indices_test])
            Y_test = np.array([Y_test[j] - 1 for j in valid_indices_test])

        # Training set
        y_pred_train = model.predict(X_train)
        y_pred_train_int = np.argmax(y_pred_train, axis=1)
        y_train_int = [label for label in Y_train]

        # Test set
        y_pred_test = model.predict(X_test)
        y_pred_test_int = np.argmax(y_pred_test, axis=1)
        y_test_int = [label for label in Y_test]

        #save predicitons
        predicitons[models[i]+'test'] = y_test_int
        predicitons[models[i]+'train'] = y_train_int
        predicitons[models[i]+'test_pred'] = y_pred_test_int
        predicitons[models[i]+'train_pred'] = y_pred_train_int


        accuracy_train = accuracy_score(y_train_int, y_pred_train_int)
        kappa_train = cohen_kappa_score(y_train_int, y_pred_train_int)

        accuracy_test = accuracy_score(y_test_int, y_pred_test_int)
        kappa_test = cohen_kappa_score(y_test_int, y_pred_test_int)

        # Generate confusion matrices
        cm_train.append(confusion_matrix(y_train_int, y_pred_train_int))
        cm_test.append(confusion_matrix(y_test_int, y_pred_test_int))

        accuracies_train.append(accuracy_train)
        accuracies_test.append(accuracy_test)
        kappa_scores_train.append(kappa_train)
        kappa_scores_test.append(kappa_test)


    
    
    info = ['Sleep vs. Wake', 'Light vs. Deep', 'REM vs. nonREM']
    x = 0
    print(f"Accuracies for Training Set:")
    for accuracy in accuracies_train:
        print(info[x] + f' {accuracy}')
        x+=1
    x = 0
    print(f"\nAccuracies for Test Set:")
    for accuracy in accuracies_test:
        print(info[x] + f' {accuracy}')
    x = 0
    print(f"\nKappa Scores for Training Set:")
    for kappa in kappa_scores_train:
        print(info[x] + f' {kappa}')
    x = 0
    print(f"\nKappa Scores for Test Set")
    for kappa in kappa_scores_test:
        print(info[x] + f' {kappa}')

    pred = combine_pred(predicitons[predictions_mapping['SW']+ 'test_pred'], predicitons[predictions_mapping['LD']+ 'test_pred'], predicitons[predictions_mapping['REM']+ 'test_pred'])
    true = combine_pred(predicitons[predictions_mapping['SW']+ 'test'], predicitons[predictions_mapping['LD']+ 'test'], predicitons[predictions_mapping['REM']+ 'test'])
    pred_train = combine_pred(predicitons[predictions_mapping['SW']+ 'train_pred'], predicitons[predictions_mapping['LD']+ 'train_pred'], predicitons[predictions_mapping['REM']+ 'train_pred'])
    true_train = combine_pred(predicitons[predictions_mapping['SW']+ 'train'], predicitons[predictions_mapping['LD']+ 'train'], predicitons[predictions_mapping['REM']+ 'train'])
    

    print(f"\nAccuracies for predicting all classes Training Set:{accuracy_score(true_train, pred_train)}")
    print(f"Accuracies for predicting all classes Test Set:{accuracy_score(true, pred)}")
    print(f"Kappa Scores for predicting all classes  Training Set: {cohen_kappa_score(true_train, pred_train)}")
    print(f"Kappa Scores for predicting all classes  Test Set: {cohen_kappa_score(true, pred)}")
    




if __name__ == '__main__':
    test()
    

