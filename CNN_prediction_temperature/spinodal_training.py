import tensorflow as tf
gpu = tf.config.experimental.list_physical_devices('GPU')
tf.config.experimental.set_memory_growth(gpu[0], True)

# import the necessary packages
from spinodalfunc import spinodal_datasets
from spinodalfunc import spinodal_models
from sklearn.model_selection import train_test_split
from tensorflow.keras.layers import Dense
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.layers import concatenate
import numpy as np
import argparse
import locale
import os
# construct the argument parser and parse the arguments
ap = argparse.ArgumentParser()
ap.add_argument("-d", "--dataset", type=str, required=True,
	help="path to input dataset of spinodal images")
args = vars(ap.parse_args())

# construct the path to the input .csv file that contains information
# on each sample in the dataset and then load the dataset
print("[INFO] loading images min-max...")
inputPath = os.path.sep.join([args["dataset"], "SpinodalInfo.csv"])
df = spinodal_datasets.load_image_minmax(inputPath)
# load the images and then scale the pixel intensities to the
# range [0, 1]
print("[INFO] loading spinodal images...")
images = spinodal_datasets.load_spinodal_images(df, args["dataset"])
images = images / 255.0
# partition the data into training and testing splits using 75% of
# the data for training and the remaining 25% for testing
print("[INFO] processing data...")
split = train_test_split(df, images, test_size=0.25, random_state=42)
(trainAttrX, testAttrX, trainImagesX, testImagesX) = split
# find the largest temperature in the training set and use it to
# scale our temperatures to the range [0, 1] (will lead to better
# training and convergence)
maxTemp = trainAttrX["temperature"].max()
trainY = trainAttrX["temperature"] / maxTemp
testY = testAttrX["temperature"] / maxTemp
# process the image minmax data by performing min-max scaling
(trainAttrX, testAttrX) = spinodal_datasets.process_image_minmax(df,trainAttrX, testAttrX)
# create the MLP and CNN models
mlp = spinodal_models.create_mlp(trainAttrX.shape[1], regress=False)
cnn = spinodal_models.create_cnn(64, 64, 3, regress=False)
# create the input to our final set of layers as the *output* of both
# the MLP and CNN
combinedInput = concatenate([mlp.output, cnn.output])
# our final FC layer head will have two dense layers, the final one
# being our regression head
x = Dense(4, activation="relu")(combinedInput)
x = Dense(1, activation="linear")(x)
# our final model will accept categorical/numerical data on the MLP
# input and images on the CNN input, outputting a single value (the
# predicted temperature of the spinodal)
model = Model(inputs=[mlp.input, cnn.input], outputs=x)
# compile the model using mean absolute percentage error as our loss,
# implying that we seek to minimize the absolute percentage difference
# between our temperature *predictions* and the *actual temperatures*
opt = Adam(lr=1e-3, decay=1e-3 / 200)
model.compile(loss="mean_absolute_percentage_error", optimizer=opt)
# train the model
print("[INFO] training model...")
model.fit(
	x=[trainAttrX, trainImagesX], y=trainY,
	validation_data=([testAttrX, testImagesX], testY),
	epochs=1000, batch_size=8)
# make predictions on the testing data
print("[INFO] predicting temperatures...")
preds = model.predict([testAttrX, testImagesX])
print("Actual Temperature...")
print(testY)
print("Predicted Temperature...")
print(preds)
# compute the difference between the *predicted* temperatures and the
# *actual* temperatures, then compute the percentage difference and
# the absolute percentage difference
diff = preds.flatten() - testY
percentDiff = (diff / testY) * 100
absPercentDiff = np.abs(percentDiff)
# compute the mean and standard deviation of the absolute percentage
# difference
mean = np.mean(absPercentDiff)
std = np.std(absPercentDiff)
# finally, show some statistics on our model
locale.setlocale(locale.LC_ALL, "en_US.UTF-8")
print("[INFO] avg. temperature: {}, std temperature: {}".format(
	(df["temperature"].mean(), grouping=True),
	(df["temperature"].std(), grouping=True)))
print("[INFO] mean: {:.2f}%, std: {:.2f}%".format(mean, std))
