# gloss bench figure exts-009
# source: nflplotR (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(nflplotR)
# ---- chunk 1 ----
### Name: nfl_team_factor
### Title: Create Ordered NFL Team Name Factor
### Aliases: nfl_team_factor

### ** Examples

## No test: 
# unsorted vector including NFL team abbreviations
teams <- c("LAC", "LV", "CLE", "BAL", "DEN", "PIT", "CIN", "KC")

# defaults to sort by division and nick name in ascending order
nfl_team_factor(teams)

# can sort by every column in nflreadr::load_teams()
nfl_team_factor(teams, team_abbr)

# descending order by using base::rev()
nfl_team_factor(teams, rev(team_abbr))

######### HOW TO USE IN PRACTICE #########

library(ggplot2)
# load some sample data from the ggplot2 package
plot_data <- mpg
# add a new column by randomly sampling the above defined teams vector
plot_data$team <- sample(teams, nrow(mpg), replace = TRUE)

# Now we plot the data and facet by team abbreviation. ggplot automatically
# converts the team names to a factor and sorts it alphabetically
ggplot(plot_data, aes(displ, hwy)) +
  geom_point() +
  facet_wrap(~team, ncol = 4) +
  theme_minimal()

# We'll change the order of facets by making another team name column and
# converting it to an ordered factor. Again, this defaults to sort by division
# and nick name in ascending order.
plot_data$ordered_team <- nfl_team_factor(sample(teams, nrow(mpg), replace = TRUE))

# Let's check how the facets are ordered now.
ggplot(plot_data, aes(displ, hwy)) +
  geom_point() +
  facet_wrap(~ordered_team, ncol = 4) +
  theme_minimal()

# The facet order looks weird because the defaults is meant to be used with
# NFL team wordmarks. So let's use the actual wordmarks and look at the result.
ggplot(plot_data, aes(displ, hwy)) +
  geom_point() +
  facet_wrap(~ordered_team, ncol = 4) +
  theme_minimal() +
  theme(strip.text = element_nfl_wordmark())
