# plotting figures stroop task

import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

# path of resultfiles
filepath = "/Users/Lucy/Documents/Berlin/FU/MCNB/1Semester/Programming/Project/StroopTask/results"

# read in resultfiles as numpy arrays
boxplot_data = np.genfromtxt(filepath + "/stroop_results_boxplot.txt", delimiter = '\t')
corrplot_data = np.genfromtxt(filepath + "/stroop_results_corrplot.txt", delimiter = '\t')

# remove first row with headers
boxplot_data = boxplot_data[1:,:]
corrplot_data = corrplot_data[1:,:]

# save data as panda structure (dictionary)
boxplot_data = pd.DataFrame(data = {'Congruent Trials': boxplot_data[:,0], 'Incongruent Trials': boxplot_data[:,1]})
corrplot_data = pd.DataFrame(data = {'Trials': corrplot_data[:,0], 'Average Reaction Time in Seconds': corrplot_data[:,1]})

# create figures
plt.figure()
# create boxplot of average reaction time in congruent vs. incongruent trials (stroop effect)
sns.set_palette('Set2')
sns.boxplot(data=boxplot_data)
plt.title("Stroop Effect")
plt.ylabel("Average Reaction Time in Seconds")

# show plot
# plt.show()

# save figure
plt.savefig('boxplot.jpg', dpi=300) 

# create scatterplot of trials (x-axis) against reaction time (y-axis)
plt.figure()
corrplot = sns.scatterplot(data = corrplot_data,
    x = 'Trials', y = 'Average Reaction Time in Seconds') # x- and y- axis
plt.title("Correlation between Trials and Reaction Time")
plt.xlabel("Trials")
plt.ylabel("Average Reaction Time in Seconds")

# show plot
# plt.show()

# save figure
plt.savefig('scatterplot.jpg', dpi=300) 