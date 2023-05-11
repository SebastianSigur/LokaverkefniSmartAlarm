
from src.preproccesing import getData, getTestData
import numpy as np

import tensorflow as tf
from tensorflow.keras.layers import Input, Dense, Dropout
from tensorflow.keras.models import Model
import pickle
from keras.regularizers import l1
import matplotlib.pyplot as plt
from sklearn.metrics import cohen_kappa_score
from itertools import product

def p(y_true):
    real_stages = np.array(y_true).ravel()



    time_points = np.arange(len(y_true))
    fig, (ax1, ax2) = plt.subplots(2, 1, sharex=True)

    # Plot the lines for real sleep stages
    ax1.plot(time_points, real_stages, label='Real')
    ax1.set_ylabel('Sleep Stage')
    ax1.set_title('Real Sleep Cycle')
    ax1.set_yticks([0, 1,2,3,4,5])
    ax1.set_yticklabels(['Awake', 'N1','N2','N3','N4','REM'])
    ax1.legend()


    # Adjust layout and show the plots
    plt.tight_layout()
    plt.show()

class SleepStage:
    Wake = 0
    N1 = 1
    N2 = 2
    N3 = 3
    N4 = 4
    REM = 5
    unscored = -1

def combine_stages(stage, mapping):
    for key, stages in mapping.items():
        if stage in stages:
            return key
    return stage

# read the data into a pandas dataframe
def prepare_data_for_training(fetch = True, visualize=False, mapping={0:[SleepStage.Wake], 1:[SleepStage.N1,SleepStage.N2,SleepStage.N3,SleepStage.N4,SleepStage.REM]}):
    if fetch:
        print("Getting training data")
        training_dataframes = getData()
        print("Getting testing data")
        testing_dataframes = getTestData()
        print("Fetching data done. Pipeline process beginning")

        with open('data/preproccessedData/training_dataframes.pkl', 'wb') as f:
            pickle.dump(training_dataframes, f)
        with open('data/preproccessedData/testing_dataframes.pkl', 'wb') as f:
            pickle.dump(testing_dataframes, f)
    else:
        with open('data/preproccessedData/training_dataframes.pkl', 'rb') as f:
            training_dataframes = pickle.load(f)
        with open('data/preproccessedData/testing_dataframes.pkl', 'rb') as f:
            testing_dataframes = pickle.load(f)


    combined_training_dataframes = {}
    for subject_id, dataframe in training_dataframes.items():
        dataframe['combined_stage'] = dataframe['stage'].apply(lambda stage: combine_stages(stage, mapping))
        combined_training_dataframes[subject_id] = dataframe

    combined_testing_dataframes = {}
    for subject_id, dataframe in testing_dataframes.items():
        
        dataframe['combined_stage'] = dataframe['stage'].apply(lambda stage: combine_stages(stage, mapping))
        combined_testing_dataframes[subject_id] = dataframe

  


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
    for subject_id, dataframe in combined_testing_dataframes.items():
        # Drop rows with -1 in the 'combined_stage' column
        dataframe = dataframe[dataframe['combined_stage'] != -1]
        features = dataframe.drop(['stage', 'combined_stage', 'filename', 'seconds'], axis=1)
        labels = dataframe['combined_stage']

       
        # Normalize the data
        #scaler = MinMaxScaler()
        #X_test_subject_normalized = scaler.fit_transform(features)
      

        X_test.append(features)
        Y_test.append(labels.values)
    
    # Converting lists to numpy arrays
    X_train = np.concatenate(X_train, axis=0)
    Y_train = np.concatenate(Y_train, axis=0)

    # Normalize the data
    #scaler = MinMaxScaler()
    #X_train = scaler.fit_transform(X_train)
    X_train = np.array(X_train)

    X_test = np.concatenate(X_test, axis=0)
    #X_test = scaler.transform(X_test)  # Use transform instead of fit
    X_test = np.array(X_test)
    Y_test = np.concatenate(Y_test, axis=0)

    return X_train, Y_train, X_test, Y_test


def custom_loss(y_true, y_pred):

    # Calculate cross-entropy loss
    ce_loss = tf.keras.losses.sparse_categorical_crossentropy(y_true, y_pred)

    # Calculate weight for each sample based on true label
    weights = tf.where(y_true == 1, 3.0, 1.0)

    # Apply weights to the cross-entropy loss
    weighted_loss = ce_loss * weights

    # Calculate mean loss across all samples
    loss = tf.reduce_mean(weighted_loss)

    return loss

def defineModel(input_shape, nr_of_layers, dropout, dense_units, regularize, out, mid, weighted):
    
    # Input layer
    inputs = Input(shape=input_shape)

    # Hidden layers
    if regularize is not None:
        x = Dense(dense_units, activation='relu',kernel_regularizer=l1(0.001))(inputs)
    else:
        x = Dense(dense_units, activation='relu')(inputs)
    if dropout is not None:
        x = Dropout(dropout)(x)

    for _ in range(nr_of_layers//2):
        if regularize is not None:
            x = Dense(dense_units, activation='relu',kernel_regularizer=l1(0.001))(x)
        else:
            x = Dense(dense_units, activation='relu')(x)
        if dropout is not None:
            x = Dropout(dropout)(x)
    x = Dense(mid, activation='relu')(x)
    for _ in range(nr_of_layers//2):
        x = Dense(dense_units, activation='relu')(x)
    x = Dense(dense_units, activation='relu')(x)

    # Output layer
    outputs = Dense(out, activation='softmax')(x)


    model = Model(inputs=inputs, outputs=outputs)
    #sparse = 'sparse_categorical_crossentropy'
    if weighted:

        model.compile(optimizer='adam', loss=custom_loss, metrics=['accuracy'])
    else:
        model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])
    return model


 


def trainModel(X_train, y_train, X_test, y_test, out = 2, weighted = False):
    from imblearn.over_sampling import SMOTE

    smote = SMOTE()

    # apply SMOTE
    X_train_oversampled, y_train_oversampled = smote.fit_resample(X_train, y_train)

    epochs_list = [50]
    batch_size_list = [32]
    nr_of_layers_list = [4]
    dropout_list = [0.5]
    regularize_list = [None]
    dense_units_list = [32, 64, 128]
    mids = [8,16,32]
    input_shape = X_train.shape[1:]

    best_model = None
    best_history = None
    best_val_accuracy = 0
    best_kappa_score = 0

    total_combinations = len(mids)*len(regularize_list)*len(epochs_list) * len(batch_size_list) * len(nr_of_layers_list) * len(dropout_list) * len(dense_units_list)
    current_iteration = 0
    import time
    t = []
    b = []
    for epochs, batch_size, nr_of_layers, dropout, dense_units, regularize,mid in product(epochs_list, batch_size_list, nr_of_layers_list, dropout_list, dense_units_list, regularize_list, mids):
        print(epochs, batch_size, nr_of_layers, dropout, dense_units, regularize)
        stopwatch = time.time()
        current_iteration += 1
        print(f'Current iteration: {current_iteration} / {total_combinations}')
        model = defineModel(input_shape, nr_of_layers, dropout, dense_units, regularize, out,mid, weighted = weighted)
        history = model.fit(
            X_train_oversampled,
            y_train_oversampled,
            epochs=25,
            batch_size=batch_size,
            validation_data=(X_test, y_test),
        )
        
        
        # Calculate Kappa score for the validation set
        y_pred = model.predict(X_test)
        y_pred_classes = np.argmax(y_pred, axis=1)
        kappa_score = cohen_kappa_score(y_test, y_pred_classes)

        print(f'Score for kappa score: {kappa_score}')
        val_accuracy = history.history['val_accuracy'][-1]
        USEKAPPASCORE = True
        if USEKAPPASCORE:
            
            if kappa_score > best_kappa_score:
                best_kappa_score = kappa_score
                best_history = history
                best_model = model
                b = [epochs, batch_size, nr_of_layers, dropout, dense_units, regularize]
        else:
            if val_accuracy > best_val_accuracy:
                val_accuracy = best_val_accuracy
                best_history = history
                best_model = model
                b = [epochs, batch_size, nr_of_layers, dropout, dense_units, regularize]
        model.fit(
            X_train_oversampled,
            y_train_oversampled,
            epochs=50,
            batch_size=batch_size,
            validation_data=(X_test, y_test),
            initial_epoch=25,
        )
        # Calculate Kappa score for the validation set
        y_pred = model.predict(X_test)
        y_pred_classes = np.argmax(y_pred, axis=1)
        kappa_score = cohen_kappa_score(y_test, y_pred_classes)

        print(f'Score for kappa score: {kappa_score}')
        val_accuracy = history.history['val_accuracy'][-1]
        if True:
            
            if kappa_score > best_kappa_score:
                best_kappa_score = kappa_score
                best_history = history
                best_model = model
                b = [epochs, batch_size, nr_of_layers, dropout, dense_units, regularize]
        else:
            if val_accuracy > best_val_accuracy:
                val_accuracy = best_val_accuracy
                best_history = history
                best_model = model
                b = [epochs, batch_size, nr_of_layers, dropout, dense_units, regularize]

        t.append(time.time()-stopwatch)
        m = np.mean(t)/len(t)
        print("estimated time left is:",m*total_combinations-m*current_iteration)
    print(b)
    return best_history, best_model

