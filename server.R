
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(RMariaDB)
library(DBI)

# Define database options
options(mysql = list(
  "host" = "localhost",
  "port" = 3306,
  "user" = "root",
  "password" = "symptomhub1234"
))
databaseName <- "readme_info"
table <- "readme"

# Define fields that we want to save from form
fieldsAll <- c("title","num_part","corr_type","description","sample_type","authors","date_range", "citation","email")

responsesDir <- file.path("responses")
# save timestamp for each response as well
epochTime <- function() {
  as.integer(Sys.time())
}

shinyServer(function(input, output) {

# For Downloading Data tab  
  
  # Reactive value for selected dataset ----
  datasetInput <- reactive({
    switch(input$dataset,
           "rock" = rock,
           "pressure" = pressure,
           "cars" = cars)
  })
  
  # Generate a summary of the data ----
  output$summary <- renderPrint({
    summary(datasetInput())
  })
  
  # Table of selected dataset ----
  output$table <- renderTable({
    datasetInput()
  })
  
  # Downloadable csv of selected dataset ----
  output$downloadData <- downloadHandler(
    filename = function() {
      paste(input$dataset, ".csv", sep = "")
    },
    content = function(file) {
      write.csv(datasetInput(), file, row.names = FALSE)
    })
  
  # For Uploading Dataset tab
  
  # Whenever a field is filled, aggregate all form data
  formData <- reactive({
    data <- sapply(fieldsAll, function(x) input[[x]])
    data <- c(data, timestamp = epochTime())
    data <- t(data)
    data
  })
  
  # Save each instance of "responses" as a csv
  #saveData <- function(data) {
  #  fileName <- sprintf("%s_%s.csv",
  #                      humanTime(),
  #                      digest::digest(data))
    
  #  write.csv(x = data, file = file.path(responsesDir, fileName),
  #            row.names = FALSE, quote = TRUE)
  #}
  
  # Temporary saveData on local session
  #saveData <- function(data) {
  #  data <- as.data.frame(t(data),stringsAsFactors=FALSE)
  #  if (exists("responses")) {
  #    responses <<- rbind(responses, data)
  #  } else {
  #    responses <<- data
  #  }
  #}
  
  #loadData <- function() {
  #  if (exists("responses")) {
  #    responses
  #  }
  #}
  
  # saveData for remote SQL database
  saveData <- function(data) {
    # Connect to the database
    db <- dbConnect(RMariaDB::MariaDB(), dbname = databaseName, host = options()$mysql$host, 
                    port = options()$mysql$port, user = options()$mysql$user, 
                    password = options()$mysql$password)
    # Construct the update query by looping over the data fields
    query <- sprintf(
      "INSERT INTO %s (%s) VALUES ('%s')",
      table, 
      paste(names(data), collapse = ", "),
      paste(data, collapse = "', '")
    )
    # Submit the update query and disconnect
    dbSendQuery(db, query)
    dbDisconnect(db)
  }
  
  #loadData for remote SQL database
  loadData <- function() {
    # Connect to the database
    db <- dbConnect(RMariaDB::MariaDB(), dbname = databaseName, host = options()$mysql$host, 
                    port = options()$mysql$port, user = options()$mysql$user, 
                    password = options()$mysql$password)
    # Construct the fetching query
    query <- sprintf("SELECT * FROM %s", table)
    # Submit the fetch query and disconnect
    data <- dbSendQuery(db, query)
    dbDisconnect(db)
    data
  }
  
  # Use humanTime instead of epochTime for more readable timestamp
  humanTime <- function() format(Sys.time(), "%Y%m%d-%H%M%OS")
  
  # When the Submit button is clicked, save the form data
  observeEvent(input$submit, {
    saveData(formData())
  })
  
  # Show the previous responses
  # (update with current response when Submit is clicked)
  output$responses <- renderTable({
    input$submit
    loadData()
  })
  
  output$contents <- renderTable({
    
    # input$file1 will be NULL initially. After the user selects
    # and uploads a file, head of that data file by default,
    # or all rows if selected, will be shown.
    
    req(input$file1)
    
    df <- read.csv(input$file1$datapath,
                   header = TRUE,
                   sep = ",",
                   quote = '"')
    
    #if(input$disp == "head") {
    #  return(head(df))
    #}
    #else {
      return(df)
    #}
    
  })
  
})


