# Import necessary libraries
library(dplyr)
library(factoextra)
library(ggplot2)
library(cluster)

# Import data
data <- read.csv('Electric_Vehicle_Population_Data.csv')

# count total number of rows
nrow(data)

# check column names
colnames(data)

# Data Pre-processing
# Clean Null Values
data <- na.omit(data)

# Remove rows where Base.MSRP is 0
data <- data %>% filter(Base.MSRP > 0)

# count total number of rows
nrow(data)

# display top 5 rows
head(data)


# remove unnecessary column names
data <- data %>%
  select(-X2020.Census.Tract,
         -Postal.Code,
         -Legislative.District,
         -DOL.Vehicle.ID,
         -Vehicle.Location)

# display top 5 rows
head(data)
  
# Exploratory Data Analysis
# Plot top 5 EV Car Manufacturer in the state of Washington

top_brands <- data %>%
  group_by(Make) %>%
  summarise(count = n()) %>%
  arrange(desc(count)) %>%
  head(10)

# Create horizontal bar plot
ggplot(top_brands, aes(x = count, y = reorder(Make, count))) +
  geom_bar(stat = "identity", fill = "steelblue") +
  geom_text(aes(label = count), hjust = -0.2) +  # Add count labels
  theme_minimal() +
  labs(
    title = "Top 10 EV Brands in the State of Washington",
    x = "Number of Vehicles",
    y = "Brand"
  ) +
  theme(
    plot.title = element_text(hjust = 0.5)
  ) +
  # Expand x-axis to prevent label cutoff
  scale_x_continuous(expand = expansion(mult = c(0, 0.1)))

# Calculate and sort city counts
top_10_cities <- data %>%
  group_by(City) %>%
  summarise(count = n()) %>%
  arrange(desc(count)) %>%
  head(10)

# Create horizontal bar plot
# Create horizontal bar plot with end labels
ggplot(top_10_cities, aes(x = count, y = reorder(City, count))) +
  geom_bar(stat = "identity", fill = "steelblue") +
  geom_text(aes(label = count), hjust = -0.2) +  # Add count labels
  theme_minimal() +
  labs(
    title = "Top 10 Cities with Most EVs in Washington",
    x = "Number of Vehicles",
    y = "City"
  ) +
  theme(
    plot.title = element_text(hjust = 0.5)
  ) +
  # Expand x-axis to prevent label cutoff
  scale_x_continuous(expand = expansion(mult = c(0, 0.1)))


# Get brand distribution for these cities
brand_distribution <- data %>%
  filter(City %in% top_10_cities$City) %>%
  group_by(City, Make) %>%
  summarise(count = n()) %>%
  group_by(City) %>%
  slice_max(order_by = count, n = 1)

# Create horizontal bar plot
ggplot(brand_distribution, aes(x = count, y = reorder(City, count))) +
  geom_bar(stat = "identity", fill = "steelblue") +
  geom_text(aes(label = paste0(Make, ": ", count)), hjust = -0.2) +
  theme_minimal() +
  labs(
    title = "Most Common EV Brand in Top 10 Cities",
    x = "Number of Vehicles",
    y = "City"
  ) +
  theme(
    plot.title = element_text(hjust = 0.5)
  ) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.3)))


## Top 10 EV Car Models in Top 10 Cities with most EVs

# Get top 10 cities
top_cities <- data %>%
  count(City) %>%
  arrange(desc(n)) %>%
  head(10) %>%
  pull(City)


# Filter data for top cities and get model counts
model_city_counts <- data %>%
  filter(City %in% top_cities) %>%
  group_by(City, Model) %>%
  summarise(Count = n()) %>%
  ungroup()

# Get top 10 models overall
top_models <- model_city_counts %>%
  group_by(Model) %>%
  summarise(Total = sum(Count)) %>%
  arrange(desc(Total)) %>%
  head(10) %>%
  pull(Model)

# Filter for top models
plot_data <- model_city_counts %>%
  filter(Model %in% top_models)

# Create the plot
ggplot(plot_data, aes(x = Count, y = reorder(Model, Count), fill = City)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme_minimal() +
  labs(
    title = "Top 10 Car Models in Top 10 Cities",
    x = "Number of Cars",
    y = "Model"
  ) +
  theme(
    legend.position = "right",
    plot.title = element_text(hjust = 0.5),
    axis.text.y = element_text(size = 8)
  )

# Calculate vehicles by year
# Calculate yearly totals
yearly_growth <- data %>%
  group_by(Model.Year) %>%
  summarise(total_vehicles = n()) %>%
  filter(Model.Year >= 2012 & Model.Year <= 2024)  # Remove any invalid years

# Create an area chart with gradient fill
ggplot(yearly_growth, aes(x = Model.Year, y = total_vehicles)) +
  geom_area(fill = "#4287f5", alpha = 0.6) +  # Light blue fill with transparency
  geom_line(color = "#1e3799", size = 1) +    # Darker blue line
  theme_minimal() +
  labs(
    title = "Growth of Electric Vehicles in Washington State",
    x = "Model Year",
    y = "Number of Vehicles",
    caption = "Data source: WA EV Population Data"
  )

# Calculate average range by year
avg_range <- data %>%
  filter(Electric.Range > 0) %>%  # Remove vehicles with 0 range
  group_by(Model.Year) %>%
  summarise(avg_range = mean(Electric.Range)) %>%
  filter(Model.Year >= 2012 & Model.Year <= 2024)  # Remove outlier years

# Create line plot with points
ggplot(avg_range, aes(x = Model.Year, y = avg_range)) +
  geom_line(color = "#2E86C1", size = 1) +
  geom_point(color = "#2E86C1", size = 3) +
  theme_minimal() +
  labs(
    title = "Average Electric Range by Model Year",
    x = "Model Year",
    y = "Average Range (miles)"
  ) +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    axis.text.x = element_text(angle = 0),
    panel.grid.minor = element_blank()
  ) +
  scale_x_continuous(breaks = min(data$Model.Year):max(data$Model.Year))


# Calculate market share percentages
market_share <- data %>%
  group_by(Make) %>%
  summarise(count = n()) %>%
  arrange(desc(count)) %>%
  mutate(
    percentage = (count/sum(count)) * 100,
    # Create label for sectors larger than 3%
    label = ifelse(percentage >= 3,
                   sprintf("%s\n%.1f%%", Make, percentage),
                   "")
  )

# Create enhanced pie chart
ggplot(market_share, aes(x = "", y = percentage, fill = Make)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar("y", start = 0) +
  geom_text(aes(label = label),
            position = position_stack(vjust = 0.5),
            size = 3) +
  theme_minimal() +
  labs(
    title = "EV Market Share by Brand in Washington",
    fill = "Brand (< 3%)"
  ) +
  theme(
    axis.text = element_blank(),
    axis.title = element_blank(),
    plot.title = element_text(hjust = 0.5),
    legend.position = "right",
    panel.grid = element_blank()
  )


## Part 2: Calculation of adoption rates

## Calculation of adoption rates
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

# Merge dataset with adoption_rate
merged_data <- data %>%
  left_join(adoption_data, by = "County")


# Calculate brand contribution by county
brand_county_contribution <- data %>%
  group_by(County, Make) %>%
  summarise(count = n()) %>%
  group_by(County) %>%
  mutate(
    contribution_pct = (count / sum(count)) * 100
  ) %>%
  arrange(County, desc(contribution_pct))

# Create visualization
ggplot(brand_county_contribution, 
       aes(x = County, y = contribution_pct, fill = Make)) +
  geom_bar(stat = "identity", position = "stack") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "right"
  ) +
  labs(
    title = "EV Brand Contribution to County Adoption Rates",
    x = "County",
    y = "Contribution Percentage",
    fill = "Brand"
  )

# K-Means Clustering

# vehicles are clustered based on average range and how many average battery electric vehicles

# Prepare data for market segmentation
segment_data <- merged_data %>%
  group_by(County, Make) %>%
  summarise(
    avg_range = mean(Electric.Range),
    bev_ratio = mean(Electric.Vehicle.Type == "Battery Electric Vehicle (BEV)"),
    avg_year = mean(Model.Year)
  ) %>%
  ungroup()

# Scale the features
scaled_features <- scale(segment_data[, c("avg_range", "bev_ratio", "avg_year")])

# Determine optimal number of clusters using elbow method
k <- 3  # Based on natural market segments
kmeans_result <- kmeans(scaled_features, centers = k)

# Plot 1: Elbow plot to validate k=3
fviz_nbclust(scaled_features, kmeans, method = "wss") +
  labs(title = "Elbow Method for Optimal k",
       x = "Number of Clusters (k)",
       y = "Total Within Sum of Squares")

# Plot 3: Feature relationships colored by cluster
segment_data$Cluster <- as.factor(kmeans_result$cluster)
ggplot(segment_data, aes(x = avg_range, y = avg_year, color = Cluster)) +
  geom_point(size = 3, alpha = 0.6) +
  theme_minimal() +
  labs(title = "EV Segments: Range vs Year",
       x = "Average Electric Range (miles)",
       y = "Average Model Year")

# Calculate silhouette scores for different k values
sil_scores <- numeric(8)  # Test k=2 to k=9

for(k in 2:9) {
  # Perform k-means
  km <- kmeans(scaled_features, centers = k, nstart = 25)
  
  # Calculate silhouette score
  sil <- silhouette(km$cluster, dist(scaled_features))
  sil_scores[k-1] <- mean(sil[,3])
}

# Plot silhouette scores
plot(2:9, sil_scores, type = "b", 
     xlab = "Number of clusters (k)", 
     ylab = "Average Silhouette Score",
     main = "Silhouette Score vs Number of Clusters")

# Print optimal k
cat("Optimal number of clusters:", which.max(sil_scores) + 1)


# Add manufacturer labels to points
ggplot(segment_data, aes(x = avg_range, y = avg_year, color = as.factor(kmeans_result$cluster))) +
  geom_point() +
  geom_text(aes(label = Make), vjust = -0.5, size = 3) +
  theme_minimal() +
  labs(title = "EV Segments by Range and Year",
       x = "Average Electric Range (miles)",
       y = "Average Model Year",
       color = "Cluster")

# Plot 2: Cluster visualization
fviz_cluster(kmeans_result, data = scaled_features,
             geom = "point",
             ellipse.type = "convex",
             palette = "Set2",
             ggtheme = theme_minimal()) +
  labs(title = "EV Market Segments Clustering",
       subtitle = "Based on Range, BEV Ratio, and Model Year")
