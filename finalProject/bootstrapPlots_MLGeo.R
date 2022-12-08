library(tidyverse)
library(readxl)

###bootstrap runs at 90% of PFAMs

#load pfams used for each bootstrap run
pfam <- read_csv("bootstrapPfams.csv")

#load predictions for each bootstrap run
res <- read_csv("bootstrapPredictions.csv")

#loads taxa and sample corresponding the trophic mode predictions for 
#each row
meta <- read_csv("G2_surface_tpm_updatedMarferret_marmicroDb_sampleTaxa.csv")

#bind 2 datasets
merged <- cbind(meta, res)

#get rid of unnecessary variable
merged <- merged %>% select(-`...1`)

#exclude taxa not identified at species level
merged <- merged %>% filter(str_detect(tax_name, " "))
merged <- merged %>% filter(!(tax_name %in% c("cellular organisms", "Micromonas <green algae>")))
merged <- merged %>% filter(!(tax_name %in% c("unclassified Acanthoeca", "unclassified Micromonas", "unclassified Phaeocystis")))
merged <- merged %>% filter(tax_name != "unclassified Chrysochromulina")

#exclude taxa too dissimilar from taxa in training data
merged <- merged%>% filter(!(tax_name %in% c("Calanus finmarchicus", "Eucyclops serrulatus", 
                                          "Hydra vulgaris", "Oikopleura dioica", "Paracyclopina nana")))

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

#gather data into long form
merged_g <- merged %>% gather(col0:col29, key = "boot", value = "xg_pred")

#exclude predictions in which there is both a phototrophy and heterotrophy prediction 
#for the same taxa in the same metatranscriptome because this is unreliable
exclude <- merged_g %>% filter(xg_pred %in% c("Phot", "Het")) %>% group_by(Station, `Depth (m)`, Size, tax_name, boot) %>% 
  distinct(xg_pred) %>% summarize(n = n()) %>% filter(n == 2)
exclude <- exclude %>% ungroup() 
merged_g <- merged_g %>% anti_join(exclude, by = c("Station", "Depth (m)", "tax_name", "Size", "boot"))

#expand trophic mode labels
merged_g <- merged_g %>% mutate(xg_pred = str_c(xg_pred, "otrophic"))
merged_g <- merged_g %>% mutate(xg_pred = str_replace(xg_pred, "Hetotrophic", "Heterotrophic"))

#make latitude variable numeric
merged_g$Latitude <- as.numeric(merged_g$Latitude)

#expand size
merged_g <- merged_g %>% 
  mutate(Size = ifelse(Size == "0.2um", "0.2 - 3 um", Size)) %>%
  mutate(Size = ifelse(Size == "3um", "3 - 100 um", Size))

#get number of species predictions can be made for each latitude
numSpecies <- merged_g %>% ungroup() %>% group_by(Latitude, Size, `Depth (m)`) %>% 
  distinct(tax_name) %>% summarize(numSpecies = n())

#get number of predictions across trophic modes for each sample and bootstrap run
totalPredictions_byBoot <- merged_g %>% group_by(Latitude, Size, `Depth (m)`, sample, boot) %>% 
  summarize(total = n())

#get number of predictions of each trophic mode by sample and bootstrap run
mergedSummary_boot <- merged_g %>% group_by(Latitude, Size, `Depth (m)`, xg_pred, sample, boot) %>% summarize(n = n())

mergedSummary_boot %>% 
  ungroup() %>%
  left_join(totalPredictions_byBoot, by = c("Latitude", "Size", "Depth (m)", "sample", "boot")) %>% 
  mutate(prop = n/total) %>%
  ggplot(aes(x = Latitude)) + geom_jitter(aes(y = prop, color = xg_pred), height = .04, width = .2, alpha = .3) + 
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

ggsave("g2_surface_allTrophicPredictions_byBootstrap_updatedMarferret_marmicroDb_bootstrap.png", height = 6, width = 16)


###bootstrap runs for which a random proportion of the training features 
###were selected

#load proportion of PFAMs used
numPfam <- read_csv("bootstrapNumPfams.csv")

#load trophic mode predictions
pred <- read_csv("bootstrapPredictionsChangeNumPfams.csv")

#combine trophic mode predictions and taxa and sample corresponding 
#the trophic mode predictions for each row
pred <- cbind(meta, pred)

#gather number of PFAMs used for each bootstrap run 
#into long form
numPfam <- numPfam %>% gather(col0:col999, key = boot, value = "propPfams")

#get rid of unnecessary variable
numPfam <- numPfam %>% select(-`...1`)

#gather trophic mode predictions into long form
pred <- pred %>% gather(col0:col999, key = boot, value = "xg_pred")
pred <- pred %>% select(-`...1`)

#exclude taxa not identified at species level
pred <- pred %>% filter(str_detect(tax_name, " "))
pred <- pred %>% filter(!(tax_name %in% c("cellular organisms", "Micromonas <green algae>")))
pred <- pred %>% filter(!(tax_name %in% c("unclassified Acanthoeca", "unclassified Micromonas", "unclassified Phaeocystis")))
pred <- pred %>% filter(tax_name != "unclassified Chrysochromulina")

#exclude taxa too dissimilar from taxa in training data
pred <- pred %>% filter(!(tax_name %in% c("Calanus finmarchicus", "Eucyclops serrulatus", 
          "Hydra vulgaris", "Oikopleura dioica", "Paracyclopina nana")))

#add proportion of PFAMs used in run to trophic mode predictions
pred <- pred %>% left_join(numPfam, by = c("boot"))

#gets the dominant trophic mode prediction for each taxa at each cruise station 
#across metatranscriptome replicates
top <- pred %>% filter(propPfams > .99) %>% group_by(station, tax_name, xg_pred) %>% summarize(n = n()) %>% 
  ungroup() %>% group_by(station, tax_name) %>% arrange(desc(n)) %>% slice(1)
top <- top %>% ungroup()

#add dominant trophic mode prediction for each taxa at each cruise station to 
#predictions across bootstrap runs
pred <- pred %>% left_join(top %>% select(-n), by = c("station", "tax_name"))

#calculate total number of predictions in that bootstrap run (always 955)
total <- pred %>% group_by(propPfams) %>% summarize(n = n())
total %>% distinct(n)

#calculate number of predictions across bootstrap runs that match 
#the dominant prediction for the respective taxa and divide 
#by the total number of predictions in that bootstrap run (always 955)
#plot predictions matching dominant prediction per taxa against proportion 
#of PFAMs used
pred %>% filter(xg_pred.x == xg_pred.y) %>% group_by(propPfams) %>% summarize(n = n()) %>% mutate(prop = n/955) %>% 
  ggplot(aes(x = propPfams, y = prop)) + geom_point(height = .02, width = .02)  + 
  geom_smooth() +
  labs(x = "Proportion of features (PFAMs) used", y = "Proportion of predictions matching trophic\nmode predicted from all of the features available") +
  theme_bw() +
  theme(strip.background =element_rect(fill="white")) +
  theme(axis.text.x = element_text(size = 18, color = 'black')) + 
  theme(axis.title.x = element_text(size = 21, color = 'black')) + 
  theme(axis.text.y = element_text(size = 18, color = 'black')) + 
  theme(axis.title.y = element_text(size = 21, color = 'black')) + 
  theme(strip.text = element_text(size = 18, color = 'black')) + 
  theme(legend.text = element_text(size = 14, color = 'black')) +
  theme(legend.title = element_text(size = 18, color = 'black')) + 
  ylim(0,1)

ggsave("g2_surface_bootstrapPredictionAccuraciesVsPropPfams.png", height = 7, width = 8)


