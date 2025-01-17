# 
# Creates a linear model to predict n anglers/year and predicts those anglers
# through 2040.
#


library(dplyr)
library(ggplot2)
library(mgcv)
library(scales)
library(tidyr)


# angler days on the upper madison river from Horton paper, 2018
actual <- data_frame(
  year = c(2011, 2013, 2015, 2016), 
  angler_days = c(90000, 135000, 155000, 180000)) %>%
  mutate(type = 'actual')

actual

# Generate lm from these data
mod <- lm(angler_days~year, data = actual)
summary(mod)

# add predcited values to df
actual <- cbind(actual, predict(mod, interval = 'confidence'))
actual

# Create a df to extrapolate
future <- data.frame(
  year = seq(2016, 2040, by = 1), 
  angler_days = NA, 
  type = 'predicted')
future

# Generate predictions
predicted = cbind(future, predict(mod, newdata = future, interval = 'prediction', level = 0.95))

from_2020_pressure <- # from League and Caball 2022
  data.frame(year = 2020, 
             angler_days = 310762, #pg 27, table 6
             type = 'actual', 
             fit = NA, 
             lwr = NA, 
             upr = NA)

# Create df of all years from 2011 through 2040
all <- 
  actual %>%
  rbind(predicted) %>%
  mutate(angler_days = ifelse(year == 2020, 310762*.67, 
                              ifelse(year == 2019, 263735*.67, 
                                     ifelse(year == 2017, 306448*.67, angler_days))), 
         )

all %>%
  saveRDS("./data/07_predicted_angler_pressure.rds")


#Plot the observed/expected angler data
p <- 
  all %>%
  filter(year <= 2030) %>%
  ggplot() +
  aes(x = year, y = fit) +
  geom_point((aes(x = year, y = angler_days)), size = 4) +
  geom_line(aes(linetype = type), linewidth = 1) +
  geom_ribbon(aes(ymin = lwr, ymax = upr), alpha = 0.3) +
  xlab("Year") +
  ylab('N anglers/year\n(upper Madison River)') +
  scale_linetype_discrete(name = "",
                          labels = c('Observed and 95% confidence interval',
                                     'Prediction and 95% prediction interval')
  ) + 
  # scale_shape_manual(name = "test",
  #                    values = c(16, NA),
  #                    labels = c('Observed',
  #                               NA)
  # ) +
  labs(shape = "", linetype = '', point = "") +
  scale_y_continuous(labels = label_comma()) +
  theme_minimal(base_size = 30) +
  theme(legend.position = 'bottom',
        legend.title=element_blank(),
        panel.grid.minor = element_blank(),
        # panel.border = element_rect(colour = "black", fill=NA, size=1)
        # panel.border = element_blank(), 
        axis.line.x = element_line(size = 0.5, linetype = "solid", colour = "black"),
        axis.line.y = element_line(size = 0.5, linetype = "solid", colour = "black"),
  )
p

ggsave(paste0("output/images/07_predicted_yearly_n_anglers.png"), plot = p, 
       width = 16, height = 9, bg = "white")

# all %>%
#   filter(year >= 2023 & year <= 2030) %>%
#   select(year, fit, lwr, upr) %>%
#   pivot_longer(!year, names_to = 'type', values_to = 'n_anglers') %>%
#   mutate(n_upper_anglers = n_anglers * .67)
# 

