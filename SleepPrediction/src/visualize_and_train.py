
import pandas as pd
import matplotlib.pyplot as plt
from src.model import prepare_data_for_training, defineModel, trainModel, SleepStage
import numpy as np
from sklearn.metrics import confusion_matrix
from sklearn.metrics import cohen_kappa_score
from joblib import dump, load


if __name__ == '__main__':
        
    cm = []

    X_train, Y_train, X_test, Y_test = prepare_data_for_training(fetch=False, visualize=False, mapping = {0:[SleepStage.Wake], 1:[SleepStage.N1,SleepStage.N2,SleepStage.N3,SleepStage.N4,SleepStage.REM]})

    history, model = trainModel(X_train, Y_train, X_test, Y_test)
    model.save('/models/sleep_weight_n60v13.h5')

    y_test_int = [SleepStage.Wake if label == 0 else 1 for label in Y_test]

    y_pred = model.predict(X_test)
    y_pred_int = [SleepStage.Wake if pred[0] > pred[1] else 1 for pred in y_pred]

    #Generate confusion matrix
    cm.append(confusion_matrix(y_test_int, y_pred_int))




    X_train, Y_train, X_test, Y_test = prepare_data_for_training(fetch=False, visualize=True, mapping = {0:[SleepStage.Wake],1:[SleepStage.N1,SleepStage.N2,SleepStage.REM], 2:[SleepStage.N3,SleepStage.N4]})
    valid_indices = [i for i, y in enumerate(Y_train) if y != 0]
    X_train = np.array([X_train[i] for i in valid_indices])
    Y_train = np.array([Y_train[i]-1 for i in valid_indices])
    valid_indices = [i for i, y in enumerate(Y_test) if y != 0]
    X_test = np.array([X_test[i] for i in valid_indices])
    Y_test = np.array([Y_test[i]-1 for i in valid_indices])

    history, model = trainModel(X_train, Y_train, X_test, Y_test, weighted = True)

    model.save('/models/light_deep_n60v13.h5')

    y_test_int = [SleepStage.Wake if label == 0 else 1 for label in Y_test]

    y_pred = model.predict(X_test)
    y_pred_int = np.array([SleepStage.Wake if pred[0] > pred[1] else 1.0 for pred in y_pred]).astype(int)



    # Generate confusion matrix
    cm.append(confusion_matrix(y_test_int, y_pred_int))


    X_train, Y_train, X_test, Y_test = prepare_data_for_training(fetch=True, visualize=True, mapping = {0:[SleepStage.Wake],1:[SleepStage.REM], 2:[SleepStage.N1,SleepStage.N2,SleepStage.N3,SleepStage.N4]})
    valid_indices = [i for i, y in enumerate(Y_train) if y != 0]
    X_train = np.array([X_train[i] for i in valid_indices])
    Y_train = np.array([Y_train[i]-1 for i in valid_indices])
    valid_indices = [i for i, y in enumerate(Y_test) if y != 0]
    X_test = np.array([X_test[i] for i in valid_indices])
    Y_test = np.array([Y_test[i]-1 for i in valid_indices])

    history, model = trainModel(X_train, Y_train, X_test, Y_test)
    model.save('/models/REM_n60v13.h5')

    y_test_int = [SleepStage.Wake if label == 0 else 1 for label in Y_test]

    y_pred = model.predict(X_test)
    y_pred_int = [SleepStage.Wake if pred[0] > pred[1] else 1 for pred in y_pred]

    # Generate confusion matrix
    cm.append(confusion_matrix(y_test_int, y_pred_int))


    print(cm)