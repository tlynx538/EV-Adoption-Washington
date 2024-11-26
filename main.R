# Import necessary libraries
library(dplyr)
library(caret)
library(factoextra)
library(ggplot2)
library(cluster)

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

# Plot 2: Cluster visualization
fviz_cluster(kmeans_result, data = scaled_features,
             geom = "point",
             ellipse.type = "convex",
             palette = "Set2",
             ggtheme = theme_minimal()) +
  labs(title = "EV Market Segments Clustering",
       subtitle = "Based on Range, BEV Ratio, and Model Year")

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

