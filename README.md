# Welcome to the GitHub account for the KSEA App!

###You can find the source code and all dependent files here!

- **app.R**: the raw R script behind the KSEA App
- **PSP&NetworKIN_Kinase_Substrate_Dataset_July2016.csv**: the Kinase-Substrate (K-S) dataset that the algorithm uses for identifying the substrates for each kinase
- **Sample Experimental Dataset.csv**: the sample data file input
- **User Manual.pdf**: the user manual containing detailed guidelines for navigating through the interface, interpretation of results, troubleshooting, and local installation.
- **Welcome.Rmd**: the markdown file for the Welcome tab in the KSEA App interface
- **www**: the folder holding the site's logo and favicon 

# Instructions for Local Access via GitHub

1. Download and install the R programming software [here](https://www.r-project.org/). We recommend you have version 3.0.3 or newer installed. This app has not been tested on older versions.

2. Download and install the free R Studio software [here](https://www.rstudio.com/products/rstudio/download/). This provides a useful interface for R programming. 

  (This step is optional; if you choose to skip it, steps 3-6 can be done exactly as described within the R program's basic console.)

3. Open R Studio, and install the Shiny package by typing in the following command into your console, and then hit **Enter**. This may take up to a minute for completion. 
  ```
  install.packages("shiny")
  ```
4. Once the “>” symbol and cursor reappear, type in the following code, and then hit **Enter**.

  ```
  shiny::runGitHub('KSEA', 'casecpb')
  ```
5. The KSEA App should then automatically launch in a new window/browser tab. This step may take a few seconds.

6. When finished with the analysis, just exit the interface. Then, if needed, hit the escape (Esc) key within the R studio console to terminate the KSEA App. Ignore the warning messages that may appear, and exit from R Studio. 

*Note: steps 1-3 only need to be done once if you are using the same computer. If you wish to access the KSEA App again after the first time, just reopen R Studio, and go straight to step 4.*

Instructions can also be found in the User Manual.

-----
Please cite the following papers if using this tool:

1. Wiredja D.D., Koyutürk M., Chance M.R. (2017) The KSEA App: a web-based tool for kinase activity inference from quantitative phosphoproteomics. *Submitted for review*.
2. [Casado, P., et al. (2013) Kinase-substrate enrichment analysis provides insights into the heterogeneity of signaling pathway activation in leukemia cells. *Sci. Signal*. 6, rs6-rs6](http://stke.sciencemag.org/content/6/268/rs6.long)
3. [Hornbeck P.V., et al. (2015) PhosphoSitePlus, 2014: mutations, PTMs and recalibrations. *Nucleic Acids Res*. 43:D512-20](https://academic.oup.com/nar/article/43/D1/D512/2439467/PhosphoSitePlus-2014-mutations-PTMs-and)
4. [Horn H., et al. (2014) KinomeXplorer: an integrated platform for kinome biology studies. *Nat Methods*. 11(6):603-4](http://www.nature.com/nmeth/journal/v11/n6/full/nmeth.2968.html)
