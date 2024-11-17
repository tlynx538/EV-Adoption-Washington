# import libraries
library(dplyr)
library(ggplot2)

# importing data 
data <- read.csv('Electric_Vehicle_Population_Data.csv')

# Data Pre-Processing

# Initial Summary
# number of rows
nrow(data)


# check for null values
is.null(data)

# Clean Null Values
data = na.omit(data)
nrow(data)

# Remove redundant columns 
# check for column names
colnames(data)

# dropping columns
# State','2020 Census Tract', 'DOL Vehicle ID','Postal Code','Legislative District
data <- data %>% select(-State, -X2020.Census.Tract, -Postal.Code, -Legislative.District)

# check for column names
colnames(data)

# remove base msrp values containing zeroes
data <- data %>% filter(Base.MSRP > 0)

# check dataset length 
nrow(data)

# dataset summary
summary(data)

# simple linear regression 
model <- lm(Base.MSRP ~ Electric.Range + Model.Year + Electric.Vehicle.Type + Make, data = data)

summary(model)