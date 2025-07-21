# Libraries
library(tidyverse)
library(ggplot2)
library(lubridate)
library(plyr)
library(dplyr)
library(janitor)

# Import data
orders_raw <- read_csv('/Users/ben/Downloads/Copy of Candidate Copy - SR. DATA ANALYST - INTERVIEW ASSIGNMENT - Order Data Wide (2).csv')

# Clean data
orders <- orders_raw %>% clean_names() %>% filter(is_first_order == 1)

# Calculate reorder rate by product
reorder_rates <- orders %>%
  group_by(price) %>%
  dplyr::summarise(
    total_orders = n(),
    reorders = sum(within60, na.rm = TRUE),
    reorder_rate = reorders / total_orders,
    .groups = 'drop'
  ) %>%
  arrange(desc(reorder_rate))

############## LOOP CHARTS #######
# Function to create reorder rate chart for any grouping variable
create_reorder_chart <- function(data, group_var, chart_title = NULL, filename_prefix = "reorder_chart") {
  
  # Create dynamic title if not provided
  if(is.null(chart_title)) {
    chart_title <- paste("Reorder Rate by", str_to_title(gsub("_", " ", group_var)))
  }
  
  # Calculate reorder rates dynamically
  reorder_rates <- orders %>%
    group_by(!!sym(group_var)) %>%
    dplyr::summarise(
      total_orders = n(),
      reorders = sum(within60, na.rm = TRUE),
      reorder_rate = reorders / total_orders,
      .groups = 'drop'
    ) %>%
    arrange(desc(reorder_rate))
  
  # Create the chart
  p <- ggplot(reorder_rates, aes(x = reorder(!!sym(group_var), reorder_rate), y = reorder_rate)) +
    geom_col(aes(width = scales::rescale(total_orders, to = c(0.4, 1))), 
             fill = "#324A5F", alpha = 1.0) +
    geom_text(aes(label = paste0(round(reorder_rate * 100, 1), "% (", 
                                 scales::comma(total_orders), " orders)")), 
              hjust = -0.05, size = 3.2) +
    coord_flip() +
    scale_y_continuous(labels = scales::percent_format(), 
                       limits = c(0, 1),
                       breaks = seq(0, 1, 0.2)) +
    labs(
      title = chart_title,
      subtitle = "Bar width represents order volume, labels show exact counts",
      x = str_to_title(gsub("_", " ", group_var)),
      y = "Reorder Rate",
      caption = paste("Groups ordered by reorder rate (highest to lowest)")
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 12, color = "gray60"),
      axis.text = element_text(size = 10),
      panel.grid.major.y = element_blank(),
      panel.grid.minor = element_blank()
    )
  
  # Display the plot
  print(p)
  
  # Save the plot
  filename <- paste0(filename_prefix, "_", group_var, ".png")
  ggsave(filename, plot = p, 
         width = 10, height = 5.625, units = "in", 
         dpi = 300, bg = "white")
  
  cat("Chart saved as:", filename, "\n")
  
  return(p)
}

# Define grouping variables to loop through
grouping_vars <- c("product", "shipping_method", "price","payment_method",
                   "order_status","discount_used","has_support_ticket",
                   "acquisition_source","marketable","support_topic",
                   "support_csat","shipping_location")

# Loop through each grouping variable and create charts
charts <- list()
for(group_var in grouping_vars) {
  cat("\n=== Creating chart for", group_var, "===\n")
  charts[[group_var]] <- create_reorder_chart(orders, group_var)
}



# Pairwise prop test
# Product data
sold <- c(17607, 1304, 565, 524)
returned <- round(sold * c(0.727, 0.808, 0.724, 0.723))

# Run pairwise proportion test with Holm correction
pairwise_result <- pairwise.prop.test(
  x = returned,
  n = sold,
  p.adjust.method = "holm"
)

# View result
print(pairwise_result)








