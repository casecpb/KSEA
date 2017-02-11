

library(shiny)

#@@@@@@@@@@@@@@@@@@@@@@@@@#
# User Interface
#@@@@@@@@@@@@@@@@@@@@@@@@@#

ui = fluidPage(
  
  headerPanel(windowTitle = "The KSEA App",
              img(src = 'Logo2.png')),
    
  headerPanel(#"The KSEA App",
             tags$head(tags$link(rel = "icon", type = "image/png", href = "Favicon.png")),
             tags$title("The KSEA App")
  ),

  sidebarLayout(
    
    sidebarPanel(
      p("Documents for Getting Started:"),
      downloadLink("Manual", label= "Download the User Manual PDF"),
      br(),
      downloadLink("SampleData", label = "Download a Sample Dataset"),
      p(""),
      fileInput(inputId = "PX.Dataset", label = "Input experimental dataset (.csv)"),
      radioButtons(inputId = "file", label = "Select kinase-substrate dataset",
                   c("PhosphoSitePlus" = "no",
                     "PhosphoSitePlus + NetworKIN" = "yes")),
      conditionalPanel(
        condition = "input.file == 'yes'",
        numericInput("NetworKIN.cutoff", "Set NetworKIN score cutoff", value = 2, min = 0, max = 228, step = 0.5)),
      numericInput(inputId = "p.cutoff", label = "[for plot] Set p-value cutoff", value = 0.05, min = 0, max = 1, step = 0.01),
      numericInput(inputId = "m.cutoff", label = "[for plot] Set substrate count cutoff", value = 5, min = 0, step = 1),
      actionButton("go","GO!")   
    ),
    
    mainPanel(
      tabsetPanel(type = "tabs",
                  tabPanel("Welcome", includeMarkdown("Welcome.Rmd")),
                  tabPanel("Plot", plotOutput(outputId = "plot")), 
                  tabPanel("KSEA Kinase Scores", dataTableOutput(outputId = "Mean.FC")),
                  tabPanel("Kinase-Substrate Links", dataTableOutput(outputId = "KS.dataset.abbrev")),
                  tabPanel("Downloads", downloadButton("downloadPlot", "Download Plot"),
                           br(),
                           downloadButton("downloadKSEA", "Download KSEA Kinase Scores"),
                           br(),
                           downloadButton("downloadKS.abbrev", "Download Kinase-Substrate Links"))
      )
    )
  ),
  hr(),
  p("KSEA App, version 1.0 (2017)", align="center", width=2) 
)

#@@@@@@@@@@@@@@@@@@@@@@@@@#
# Server
#@@@@@@@@@@@@@@@@@@@@@@@@@#

server <- function(input, output){
  
  KS.all = read.csv("PSP&NetworKIN_Kinase_Substrate_Dataset_July2016.csv")
  
  PX = eventReactive(
    input$go,
    {inFile = input$PX.Dataset
    raw = read.csv(inFile$datapath)
    raw[raw$FC == 0,6] = NA
    return(raw)
})
  
 KS = eventReactive(
    input$go,
    {choice = switch(input$file,
                 no = "PhosphoSitePlus",
                 yes = "[a-z]")
 
 KS.filtered = KS.all[grep(choice, KS.all$Source),]
 KS.filtered = KS.filtered[(KS.filtered$networkin_score >= input$NetworKIN.cutoff),]
 return(KS.filtered)
})  
  
  new = reactive({
    PX = PX()
    # deal with peptides with multiple phosphorylated residues
    if (length(grep(";", PX$Residue.Both))==0){
      new = PX
      colnames(new)[c(2,4)] = c("SUB_GENE", "SUB_MOD_RSD")
      new$log2FC = log2(abs(as.numeric(as.character(new$FC)))) # the as.numeric(as.character()) fixes an issue with the FC values as factors
      new = new[complete.cases(new$log2FC),]
    }
    
    else{
      double = PX[grep(";",PX$Residue.Both),]
      residues = as.character(double$Residue.Both)
      residues = as.matrix(residues, ncol = 1)
      split = strsplit(residues, split = ";")
      x = sapply(split, length)
      
      single = data.frame(Protein = rep(double$Protein, x), 
                          Gene = rep(double$Gene, x),
                          Peptide = rep(double$Peptide, x),
                          Residue.Both = unlist(split),
                          p = rep(double$p, x),
                          FC = rep(double$FC, x))
      
      # create new object of PX that has all residues in separate rows
      new = PX[-grep(";", PX$Residue.Both),]
      new = rbind(new, single)
      colnames(new)[c(2,4)] = c("SUB_GENE", "SUB_MOD_RSD")
      new$log2FC = log2(abs(as.numeric(as.character(new$FC)))) # the as.numeric(as.character()) fixes an issue with the FC values as factors
      new = new[complete.cases(new$log2FC),]
    }
    return(new)
  })
  
  KS.dataset.abbrev = reactive({
    KS = KS()
    new = new()
    # Filter KS by residues that are only found in new
    
    KS.dataset = merge(KS, new)
    KS.dataset = KS.dataset[order(KS.dataset$GENE),]
    KS.dataset$Uniprot.noIsoform = sapply(KS.dataset$KIN_ACC_ID, function(x) unlist(strsplit(as.character(x), split="-"))[1])
    # last expression collapses isoforms of the same protein for easy processing
    # don't get scared...there are some identical peptides that were detected multiple times from MS
    
    KS.dataset.abbrev = KS.dataset[,c(5,1,2,16:19,14)]
    colnames(KS.dataset.abbrev) = c("Kinase.Gene", "Substrate.Gene", "Substrate.Mod", "Peptide", "p", "FC", "log2FC", "Source")
    KS.dataset.abbrev = KS.dataset.abbrev[order(KS.dataset.abbrev$Kinase.Gene, KS.dataset.abbrev$Substrate.Gene, KS.dataset.abbrev$Substrate.Mod, KS.dataset.abbrev$p),]
    
    # take the mean of the log2FC amongst duplicates
    KS.dataset.abbrev = aggregate(log2FC ~ Kinase.Gene+Substrate.Gene+Substrate.Mod+Source, data=KS.dataset.abbrev, FUN=mean)
    
    KS.dataset.abbrev = KS.dataset.abbrev[order(KS.dataset.abbrev$Kinase.Gene),]
    return(KS.dataset.abbrev)
  })
  
  Mean.FC = reactive({
    KS.dataset.abbrev = KS.dataset.abbrev()
    new = new()
    
    # create table to do analysis for KSEA and z-score
    
    kinase.list = as.vector(KS.dataset.abbrev$Kinase.Gene)
    kinase.list = as.matrix(table(kinase.list))
    
    Mean.FC = aggregate(log2FC ~ Kinase.Gene, data=KS.dataset.abbrev, FUN=mean)
    Mean.FC = Mean.FC[order(Mean.FC[,1]),]
    Mean.FC$mS = Mean.FC[,2]
    Mean.FC$Enrichment = Mean.FC$mS/abs(mean(new$log2FC, na.rm=T))
    Mean.FC$m = kinase.list
    Mean.FC$z.score = ((Mean.FC$mS- mean(new$log2FC, na.rm=T))*sqrt(Mean.FC$m))/sd(new$log2FC, na.rm=T)
    Mean.FC$p.value = pnorm(-abs(Mean.FC$z.score)) # 1-tailed p-value
    Mean.FC$FDR = p.adjust(Mean.FC$p.value, method="fdr")
    
    return(Mean.FC[,-2])
  })
  
  #::::::::::::#
  
  data = eventReactive(
    input$go,
{raw = Mean.FC()
 raw = raw[raw$m >= input$m.cutoff,]
 raw = raw[order(raw$z.score),]
})
  
  color = reactive({
    color = data()
    #color = color[order(color$z.score),]
    color$color = "black"
    color[(color$p.value < input$p.cutoff)&(color$z.score < 0),ncol(color)] = "blue"
    color[(color$p.value < input$p.cutoff)&(color$z.score > 0),ncol(color)] = "red"
    color = as.character(color$color)
  })
  
  kinase = reactive({
    kinase = data()
    kinase = as.character(kinase$Kinase.Gene)
  })
  
  z.score = reactive({
    data2 = data()
    data2 = as.numeric(data2$z.score)
  })
  
  bar.plot = eventReactive(
    input$go,
{barplot(z.score(), col = color(),
         border = NA,
         xpd=F, cex.names= .6,
         xlab = "Kinase z-score",
         names.arg=kinase(), horiz=T, las=1)
})
  
  plot.height = reactive({
    length = length(z.score())
    height = length^0.55
    return(height)
  })
  
  #------------------------#
  
  output$Manual = downloadHandler(
    filename = "KSEA User Manual.pdf",
    content = function(file){
      file.copy("User Manual.pdf", file)
    })
  
  output$SampleData = downloadHandler(
    filename = "Sample Dataset.csv",
    content = function(file){
      file.copy("Sample Experimental Dataset.csv", file)
    })
  
  output$plot = renderPlot({
    bar.plot()
  })
  
  output$Mean.FC = renderDataTable({
    Mean.FC()
  })
  
  output$KS.dataset.abbrev = renderDataTable({
    KS.dataset.abbrev()
  })
  
  output$downloadPlot = downloadHandler(
    filename = "KSEA Bar Plot.tif",
    content = function(file) {
      tiff(file,    
           width = 6*300,        
           height = 300*plot.height(),
           res = 300, # 300 pixels per inch
           pointsize = 13)
      par(mai=c(1,1,.4,.4))
      barplot(z.score(), col = color(),
              border = NA,
              xpd=F, cex.names= .6, cex.axis = 0.8,
              xlab = "Kinase z-score",
              names.arg=kinase(), horiz=T, las=1)
      dev.off()
    })
  
  output$downloadKSEA = downloadHandler(
    filename = "KSEA Kinase Scores.csv",
    content = function(x){
      write.csv(Mean.FC(), quote=F, row.names=F, x)
    })
  
  output$downloadKS.abbrev = downloadHandler(
    filename = "Kinase-Substrate Links.csv",
    content = function(y){
      write.csv(KS.dataset.abbrev(), quote=F, row.names=F, y)
    })
}


#@@@@@@@@@@@@@@@@@@@@@@@@@#
# Final line of code
#@@@@@@@@@@@@@@@@@@@@@@@@@#

shinyApp(ui = ui, server = server)