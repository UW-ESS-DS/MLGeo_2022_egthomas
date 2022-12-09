
## MLGEO Final Project: Leveraging machine learning to predict the trophic mode of protists across the North Pacific surface ocean
Elaina Thomas egthomas@uw.edu <github: elainathomas>

PhD student, University of Washington Oceanography

Last updated: 12/8/22

To determine whether mixotrophic protists shift in trophic mode in response to nutrient availability, light, and temperature, I apply a machine learning model to metatranscriptomes collected from the surface ocean across the North Pacific. Metatranscriptomes were collected in 2017 during the Gradients 2 expedition. Read about the expedition in [Juranek et al. 2020 (DOI: 10.1029/2020GB006702)](https://doi.org/10.1029/2020GB006702).

To read about the development of the machine learning model and application of the model to the Gradients 1 cruise, see [Lambert et al. 2022, (DOI: 10.1073/pnas.2100916119)](https://www.pnas.org/doi/full/10.1073/pnas.2100916119)
## Data availability
For running ML jupyter notebook:

[environment.mkl.yml](https://uwnetid-my.sharepoint.com/:u:/r/personal/egthomas_uw_edu/Documents/environment.mkl.yml?csf=1&web=1&e=ygSmcD)

[Field_training_data.csv](https://uwnetid-my.sharepoint.com/:x:/r/personal/egthomas_uw_edu/Documents/Field_training_data.csv?d=w566dbd02791c44fcb8df2d445fc3f1c9&csf=1&web=1&e=VWVDbi)

[Field_training_labels.csv](https://uwnetid-my.sharepoint.com/:x:/r/personal/egthomas_uw_edu/Documents/Field_training_labels.csv?d=w94802441a0954b5bb4a8a4253dd8b1ba&csf=1&web=1&e=LcS95U)

[G2_surface_tpm_updatedMarferret_marmicroDb.csv](https://uwnetid-my.sharepoint.com/:x:/r/personal/egthomas_uw_edu/Documents/G2_surface_tpm_updatedMarferret_marmicroDb.csv?d=w44f2c45c457f458993bd074e0a0caa5a&csf=1&web=1&e=xrjKlk)

[Extracted_Pfams.csv](https://uwnetid-my.sharepoint.com/:x:/r/personal/egthomas_uw_edu/Documents/Extracted_Pfams.csv?d=wc047b7a23cf24e059053978644977afa&csf=1&web=1&e=YAhz6s)

For plotting in R:
[G2_surface_tpm_updatedMarferret_marmicroDb_sampleTaxa.csv](https://uwnetid-my.sharepoint.com/:x:/r/personal/egthomas_uw_edu/Documents/G2_surface_tpm_updatedMarferret_marmicroDb_sampleTaxa.csv?d=w3c0e5b82b50d4d1d8252ba4fbf9ae406&csf=1&web=1&e=DiMMno)

[Gradients2_discrete_samples.xlsx](https://uwnetid-my.sharepoint.com/:x:/r/personal/egthomas_uw_edu/Documents/Gradients2_discrete_samples.xlsx?d=w120b83308ba44c5ba5eef83c7004929d&csf=1&web=1&e=IED8ot)


## Instructions

Clone this repository: git clone "https://github.com/UW-ESS-DS/MLGeo_2022_egthomas/tree/master/finalProject"

Download data from links in data availability.

Create conda environment: run conda env create -f environment.mkl.yml

Run Jupyter notebook gradients2Cruise_trophicPredictions_MLGeo.ipynb to generate trophic mode predictions for species across the Gradients 2 transect. This notebook will also produce trophic mode prediction results from 30 bootstrap runs in which 10% of feature PFAMs are excluded, and for 1000 bootstrap runs for which each run uses a random proportion of feature PFAMS.

Run code in plots_MLGeo.R to generate a plot of the proportion of each predicted trophic mode (photo-, mixo-, or heterotrophic) per sample across the Gradients 2 transect of the North Pacific. 

Run code in bootstrapPlots_MLGeo.R to generate two plots. One plot shows the proportion of each predicted trophic mode per sample across the N. Pacific Gradients 2 transect for each of the 30 bootstrap runs in which 10% of feature PFAMs are excluded. The other plot visualizes the accuracy of trophic mode predictions against the proportion of feature PFAMs the predictions are based upon.