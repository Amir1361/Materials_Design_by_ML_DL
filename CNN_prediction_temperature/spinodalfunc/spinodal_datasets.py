from sklearn.preprocessing import MinMaxScaler
import pandas as pd
import numpy as np
import glob
import cv2
import os

def load_image_minmax(inputPath):
	# initialize the list of column names in the CSV file and then
	# load it using Pandas
	cols = ["min", "max", "image_name","temperature"]
	df = pd.read_csv(inputPath,header=None, names=cols)
	# return the data frame
	return df

def process_image_minmax(df, train, test):
	# initialize the column names of the continuous data
	continuous = ["min", "max"]
	# performin min-max scaling each continuous feature column to
	# the range [0, 1]
	cs = MinMaxScaler()
	trainContinuous = cs.fit_transform(train[continuous])
	testContinuous = cs.transform(test[continuous])
	# construct our training and testing data points by concatenating
	# the categorical features with the continuous features
	# trainX = np.hstack([trainContinuous])
	# testX = np.hstack([testContinuous])
	# return the concatenated training and testing data
	trainX = np.array(trainContinuous)
	testX = np.array(testContinuous)
	return (trainX, testX)

def load_spinodal_images(df, inputPath):
	# initialize our images array (i.e., the house images themselves)
	images = []
	# loop over the indexes of the houses
	for i in df['image_name']:
		# find the the images for the spinodal
		#imagePath = inputPath + i
		imagePath = os.path.join(inputPath,i)
        #imagePath = os.path.join(inputPath,i)
		image = cv2.imread(imagePath)
		image = cv2.resize(image,(64,64))
		images.append(image)
        #image = cv2.resize(image, (32, 32))
        #images.append(image)
    # return our set of images
	return np.array(images)
