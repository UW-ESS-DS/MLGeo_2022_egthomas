library(tidyverse)
library(readxl)

#load trophic mode predictions
trop <- read_csv("G2_surface_trophicModePredictions_updatedMarferret_marmicroDb")

#loads taxa and sample corresponding the trophic mode predictions for 
#each row
meta <- read_csv("G2_surface_tpm_updatedMarferret_marmicroDb_sampleTaxa.csv")

#bind 2 datasets
merged <- cbind(meta, trop)

#renames taxa vairable
colnames(merged)[3] <- "taxa"

#expand trophic mode labels
merged <- merged %>% mutate(xg_pred = str_c(xg_pred, "otrophic"))
merged <- merged %>% mutate(xg_pred = str_replace(xg_pred, "Hetotrophic", "Heterotrophic"))

#exclude taxa not identified at species level
merged <- merged %>% filter(str_detect(taxa, " "))
merged <- merged %>% filter(!(taxa %in% c("cellular organisms", "Micromonas <green algae>")))
merged <- merged %>% filter(!(taxa %in% c("unclassified Acanthoeca", "unclassified Micromonas", "unclassified Phaeocystis")))
merged <- merged %>% filter(taxa != "unclassified Chrysochromulina")

#exclude taxa too dissimilar from taxa in training data
merged <- merged %>% filter(!(taxa %in% c("Calanus finmarchicus", "Eucyclops serrulatus", 
                                          "Hydra vulgaris", "Oikopleura dioica", 
                                          "Paracyclopina nana")))

#expand size labels
merged <- merged %>% mutate(Size = ifelse(str_detect(sample, "2um"), "0.2um", NA))
merged <- merged %>% mutate(Size = ifelse(str_detect(sample, "3um"), "3um", Size))

#load sample metadata for gradients 2 cruise
sample <- read_excel("Gradients2_discrete_samples.xlsx", sheet = 2)

#fix column names
colnames(sample) <- sample[1,]
sample <- sample[-1,]

#get rid of unnecessary variables
sample <- sample %>% select(Date:Notes)

#make into dataframe
sample <- sample %>% as.data.frame()

#make station and cast variables numeric
merged <- merged %>% mutate(Station = parse_number(station))
sample <- sample %>% mutate(Station = parse_number(Station))
sample$Station <- as.numeric(sample$Station)
sample$Cast <- as.numeric(sample$Cast)

#fix cast info in prediction dataset
merged <- merged %>% mutate(Cast = 1)

#make time variable numeric
sample$`Time Start (HST)` <- as.numeric(sample$`Time Start (HST)`)

#get distinct metadata rows
sample <- sample %>% distinct(Station, Cast, `Depth (m)`, `Time Start (HST)`, Latitude, Size)

#add sample data to bootstrap predictions
merged <- merged %>% left_join(sample, by = c("Station", "Cast", "Size"))

#make latitude variable numeric
merged$Latitude <- as.numeric(merged$Latitude)

#exclude predictions in which there is both a phototrophy and heterotrophy prediction 
#for the same taxa in the same metatranscriptome because this is unreliable
exclude <- merged %>% filter(xg_pred %in% c("Phototrophic", "Heterotrophic")) %>% group_by(Station, `Depth (m)`, Size, taxa) %>% 
  distinct(xg_pred) %>% summarize(n = n()) %>% filter(n == 2)
exclude <- exclude %>% ungroup() 
merged <- merged %>% anti_join(exclude, by = c("Station", "Depth (m)", "taxa", "Size"))

#put trophic mode labels in particular order
merged$xg_pred <- factor(merged$xg_pred, levels = c("Phototrophic", "Heterotrophic", "Mixotrophic"))

#get number of predictions of each trophic mode by sample
mergedSummary <- merged %>% group_by(Latitude, Size, `Depth (m)`, xg_pred, sample) %>% summarize(n = n())

#make sure each trophic mode prediction is present in each sample 
#by giving 0 values when a trophic mode prediction is absent
mergedSummary <- mergedSummary %>% spread(key = xg_pred, value = n, fill = 0) %>% gather(Phototrophic:Mixotrophic, key = "xg_pred", value = "n")

#get number of predictions across trophic modes for each sample
totalPredictions_bySample <- merged %>% group_by(Latitude, Size, `Depth (m)`, sample) %>% 
  summarize(total = n())

#get number of species predictions can be made for each latitude
numSpecies <- merged %>% ungroup() %>% group_by(Latitude, Size, `Depth (m)`) %>% 
  mutate(Size = ifelse(Size == "0.2um", "0.2 - 3 um", Size)) %>%
  mutate(Size = ifelse(Size == "3um", "3 - 100 um", Size)) %>%
  distinct(taxa) %>%
  summarize(numSpecies = n())

#plot trophic mode predictions against latitude
mergedSummary %>% 
  ungroup() %>%
  left_join(totalPredictions_bySample, by = c("Latitude", "Size", "Depth (m)", "sample")) %>% 
  mutate(prop = n/total) %>%
  mutate(Size = ifelse(Size == "0.2um", "0.2 - 3 um", Size)) %>%
  mutate(Size = ifelse(Size == "3um", "3 - 100 um", Size)) %>%
  ggplot(aes(x = Latitude)) + geom_jitter(aes(y = prop, color = xg_pred), height = 0, width = .1) + 
  geom_smooth(aes(y = prop, color = xg_pred, group = xg_pred), span = 2) + 
  ylim(0, 1) +
  labs(y = "Proportion of predictions", color = "Trophic mode prediction") +
  facet_wrap(~`Size`) + 
  scale_color_manual(values = c("Phototrophic" = "blue", "Heterotrophic" = "red", "Mixotrophic" = "black")) + 
  geom_text(data = numSpecies, aes(label = numSpecies), y = .8, size = 5) + 
  theme_bw() +
  theme(strip.background =element_rect(fill="white")) +
  geom_vline(xintercept = 32.4, color = 'red', linetype="dashed") + 
  theme(axis.text.x = element_text(size = 18, color = 'black')) + 
  theme(axis.title.x = element_text(size = 26, color = 'black')) + 
  theme(axis.text.y = element_text(size = 18, color = 'black')) + 
  theme(axis.title.y = element_text(size = 26, color = 'black')) + 
  theme(strip.text = element_text(size = 18, color = 'black')) + 
  theme(legend.text = element_text(size = 14, color = 'black')) +
  theme(legend.title = element_text(size = 18, color = 'black')) + 
  theme(legend.key.size = unit(1, 'cm'),
        legend.key.height = unit(1, 'cm'),
        legend.key.width = unit(1, 'cm')) + 
  scale_x_continuous(breaks = scales::pretty_breaks(n = 10))

ggsave("g2_surface_allTrophicPredictions_bySample_updatedMarferret_marmicroDb.png", height = 6, width = 16)

