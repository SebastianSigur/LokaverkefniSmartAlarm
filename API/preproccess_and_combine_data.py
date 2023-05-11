import os
import pandas as pd
import numpy as np
from tensorflow.keras.models import load_model
import pickle
import os
import matplotlib.pyplot as plt

class SleepStage:
    Wake = 0
    N1 = 1
    N2 = 2
    N3 = 3
    N4 = 4
    REM = 5
    unscored = -1

def transformdata(result_lines):
    data_dict = []
    for line in result_lines:
        seconds, heart_rate = line.strip().split(',')
        data_dict.append({'filename': 'test', 'seconds': float(seconds), 'heart_rate': float(heart_rate)})


    testing_dataframes = create_dataframe(data_dict)

    with open('preproccessedData/testing_dataframes.pkl', 'wb') as f:
        pickle.dump(testing_dataframes, f)
    pred = my_main()
    return pred

def custom_loss(y_true, y_pred):


    ce_loss = tf.keras.losses.sparse_categorical_crossentropy(y_true, y_pred)

    # Calculating weight for each sample based on true label
    weights = tf.where(y_true == 1, 3.0, 1.0)

    weighted_loss = ce_loss * weights

    # Calculating mean loss across all samples
    loss = tf.reduce_mean(weighted_loss)

    return loss





def create_dataframe(subject_data, feature_extraction=False):

    heart_rate_data = [x for x in subject_data if 'heart_rate' in x]
    heart_rate_df = pd.DataFrame(heart_rate_data).sort_values(by='seconds')
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

def combine_stages(stage, mapping):
    for key, stages in mapping.items():
        if stage in stages:
            return key
    return stage

def prepare_data_for_training(fetch = True, visualize=False, mapping={0:[SleepStage.Wake], 1:[SleepStage.N1,SleepStage.N2,SleepStage.N3,SleepStage.N4,SleepStage.REM]}):

    with open('preproccessedData/training_dataframes.pkl', 'rb') as f:
        training_dataframes = pickle.load(f)
    with open('preproccessedData/testing_dataframes.pkl', 'rb') as f:
        testing_dataframes = pickle.load(f)
        #print(testing_dataframes)

    combined_training_dataframes = {}
    for subject_id, dataframe in training_dataframes.items():
        dataframe['combined_stage'] = dataframe['stage'].apply(lambda stage: combine_stages(stage, mapping))
        combined_training_dataframes[subject_id] = dataframe




    X_train = []
    Y_train = []
    for subject_id, dataframe in combined_training_dataframes.items():

        # Drop rows with -1 in the 'combined_stage' column
        dataframe = dataframe[dataframe['combined_stage'] != -1]

        #shuffle
        dataframe = dataframe.sample(frac=1, random_state=42)
        features = dataframe.drop(['stage', 'combined_stage', 'filename', 'seconds'], axis=1)
        labels = dataframe['combined_stage']

        X_train.append(features)
        Y_train.append(labels.values)

    X_test= []
    Y_test = []
    features = testing_dataframes.drop(['filename', 'seconds'], axis=1)


    X_test.append(features)

    # Converting lists to numpy arrays
    X_train = np.concatenate(X_train, axis=0)
    Y_train = np.concatenate(Y_train, axis=0)

    
    X_train = np.array(X_train)

    X_test = np.concatenate(X_test, axis=0)
    #X_test = scaler.transform(X_test)  # Use transform instead of fit
    X_test = np.array(X_test)

    return X_train, Y_train, X_test

def combine_pred(y_pred_wake_sleep, model_light_deep, y_pred_s_sleep):
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
def my_main():

    model_wake_sleep = load_model('./sleep_weight_n60v13.h5')
    model_light_deep = load_model('./light_deep_n60v13.h5', custom_objects={'custom_loss': custom_loss})
    model_rem_sleep = load_model('./REM_n60v13.h5')
    #model_stage = load_model('./stages_n60tttt.h5')
    wake_deep={0:[SleepStage.Wake],1:[SleepStage.N1,SleepStage.N2,SleepStage.N3,SleepStage.N4,SleepStage.REM]}
    light_deep={0:[SleepStage.Wake],1:[SleepStage.N1,SleepStage.N2,SleepStage.REM], 2:[SleepStage.N3,SleepStage.N4]}
    sleep_rem={0:[SleepStage.Wake], 1:[SleepStage.REM], 2:[SleepStage.N1,SleepStage.N2,SleepStage.N3,SleepStage.N4]}

    X_train, Y_train, X_test = prepare_data_for_training(fetch=False, visualize=False, mapping=wake_deep)
    y_pred_wake_sleep = model_wake_sleep.predict(X_test, verbose=-1)
    y_sleep_wake_pred_int = [0 if pred[0] > pred[1] else 1 for pred in y_pred_wake_sleep]



    X_train, Y_train, X_test = prepare_data_for_training(fetch=False, visualize=False, mapping=light_deep)
    y_pred_l_sleep = model_light_deep.predict(X_test, verbose=-1)
    y_pred_l_int = [np.argmax([pred[0], pred[1]]) for pred in y_pred_l_sleep]
    
    
    y_pred_l_int = change_values_to_majority(y_pred_l_int, 10) 

    X_train, Y_train, X_test = prepare_data_for_training(fetch=False, visualize=False, mapping=sleep_rem)
    y_pred_r_sleep = model_rem_sleep.predict(X_test, verbose=-1)
    y_pred_r_int = [0 if pred[0] > 0.6 else 1.0 for pred in y_pred_r_sleep]

    y_pred_r_int = change_values_to_majority(y_pred_r_int, 50)
    
    pred = combine_pred(y_sleep_wake_pred_int, y_pred_l_int, y_pred_r_int)

    return pred

def main():
    data_directory = 'data/storage'

    files = os.listdir(data_directory)
    num_files = len(files)

    num_rows = (num_files + 1) // 2
    fig, axes = plt.subplots(num_rows, 2, figsize=(12, num_rows * 6), sharey=True)
    axes = axes.flatten()

    for i, file_name in enumerate(files):
        file_path = os.path.join(data_directory, file_name)

        time_list = []
        heart_list = []

        with open(file_path, 'r') as file:
            lines = file.readlines()
            for line in lines[1:]:  # Skip the first line (UUID)
                time, heart_rate = line.strip().split(',')
                time_list.append(float(time))
                heart_list.append(int(heart_rate))

        result_lines = []
        for heart_rate, heart_rate_date in zip(heart_list, time_list):
            result_lines.append(f"{heart_rate_date},{int(heart_rate)}")

        pred = transformdata(result_lines)

        x = time_list
        y = pred

        axes[i].plot(x, y)
        axes[i].set_xlabel('Time')
        axes[i].set_ylabel('Sleep Stage')
        axes[i].set_title(f'Sleep Stage Predictions ({file_name})')

     
        axes[i].set_yticks([0, 1, 2, 3])
        axes[i].set_yticklabels(['Awake', 'Light', 'REM', 'Deep'])

        ax2 = axes[i].twinx()
        ax2.plot(x, heart_list, color='red', alpha=0.3)
        ax2.set_ylabel('Heart Rate')
        ax2.yaxis.label.set_color('red')
        ax2.tick_params(axis='y', colors='red')
        ax2.set_ylim(min(heart_list) - 10, max(heart_list) + 10)
    plt.tight_layout()
    plt.show()



if __name__ == '__main__':
    main()

