# Import necessary libraries
library(dplyr)
library(DMwR)
library(caret)
library(e1071)

# Import data
data <- read.csv('Electric_Vehicle_Population_Data.csv')

# Data Pre-processing

# Clean Null Values
data <- na.omit(data)

# Remove rows where Base.MSRP is 0 (invalid data)
data <- data %>% filter(Base.MSRP > 0)

# Count the number of EV vehicles per county (BEV and PHEV)
ev_vehicles_count <- data %>%
  filter(Electric.Vehicle.Type %in% c("Battery Electric Vehicle (BEV)", "Plug-in Hybrid Electric Vehicle (PHEV)")) %>%
  group_by(County) %>%
  summarise(EV.Vehicles = n())

# Count the total number of vehicles across all counties
total_vehicles_all_counties <- data %>%
  summarise(Total.Vehicles = n()) %>%
  pull(Total.Vehicles)  # Extract the value from the data frame

# Calculate the adoption rate for each county (EVs in county / total vehicles across all counties)
adoption_data <- ev_vehicles_count %>%
  mutate(Adoption.Rate = (EV.Vehicles / total_vehicles_all_counties) * 100)

# Inspect the results
head(adoption_data)


########################################DO NOT REMOVE#######################################




