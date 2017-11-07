
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(DT)

# Define UI for data download app ----
ui <- navbarPage("Welcome!",
             
  # Download tab ----
  tabPanel("Downloading Data",
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      
      # Input: Choose dataset ----
      selectInput("dataset", "Choose a dataset:",
                  choices = c("rock", "pressure", "cars")),
      
      # Button
      downloadButton("downloadData", "Download")
      
    ),
    
    # Main panel for displaying outputs ----
    mainPanel(
      
      # Output: Tabset w/ plot, summary, and table ----
      tabsetPanel(type = "tabs",
                  tabPanel("Summary", DT::dataTableOutput("summary")),
                  tabPanel("Table", tableOutput("table"))
      
      )
   )
  )
),
  # Upload tab ----
  tabPanel("Uploading Datasets",
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
             
    # Sidebar panel for inputs ----
    sidebarPanel(
               
      # Input: Select a file ----
      fileInput("file1", "Choose CSV File",
               multiple = TRUE,
               accept = c("text/csv",
                "text/comma-separated-values,text/plain",
                ".csv")),
               
      # Horizontal line ----
      tags$hr(),
               
      # Input: Checkbox if file has header ----
      #checkboxInput("header", "Header", TRUE),
               
      # Input: Select separator ----
      #radioButtons("sep", "Separator",
      #            choices = c(Comma = ",",
      #                        Semicolon = ";",
      #                        Tab = "\t"),
      #            selected = ","),
               
      # Input: Select quotes ----
      #radioButtons("quote", "Quote",
      #            choices = c(None = "",
      #                        "Double Quote" = '"',
      #                        "Single Quote" = "'"),
      #            selected = '"'),
               
      # Horizontal line ----
      #tags$hr(),
               
      # Input: Select number of rows to display ----
      #radioButtons("disp", "Display",
      #            choices = c(Head = "head",
      #                        All = "all"),
      #            selected = "head"),
     
      # Input: Name of Dataset
      textInput("title", h5("Unique Name for Your Dataset"), 
                value = "Enter text..."), 
    
      # Input: Number of Participants
      numericInput("num_part", 
                  h5("Number of Participants"), 
                  value = 100),
    
      # Input: Column Contents
    
      # Input: Correlation Type
      selectInput("corr_type", h5("Type of correlation used"), 
                  choices = list("polychoric" = 1, "polyserial" = 2,
                                "Pearson" = 3), selected = 1),
      
      # Input: Description
      textInput("description", h5("Brief Description of your Dataset"), 
                value = "Enter text..."),
      
      # Input: Sample Type
      selectInput("sample_type", h5("Sample type"), 
                  choices = list("clinical" = 1, "nonclinical" = 2,
                                 "mixed" = 3), selected = 1),
      
      # Input: Authors
      textInput("authors", h5("Dataset Authors"), 
                value = "Enter text..."),
      
      # Input: Years of Data Collection
      dateRangeInput("date_range", h5("Years of Data Collection"), start = NULL, end = NULL, min = NULL,
                     max = NULL, format = "yyyy-mm-dd", startview = "year", 
                     language = "en", separator = " to ", width = NULL),
      
      # Input: Citation
      textInput("citation", h5("Citation for this Dataset"), 
                value = "Enter text..."),
      
      # Input: Email address
      textInput("email", h5("Email Address"), 
                value = "Enter text..."),
    
      # Submit
      actionButton("submit", "Submit", class = "btn-primary")
      
    ),
    
     # Main panel for displaying outputs ----
    mainPanel(
    
    # Output: Tabset w/ README and contents ----
    tabsetPanel(type = "tabs",
                tabPanel("README", DT::dataTableOutput("responses")),
                tabPanel("Contents", tableOutput("contents"))
                
    )
             
  )          
)
)
)

