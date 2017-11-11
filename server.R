
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(RMySQL)
library(DBI)
library(DT)

# Define database options
options(mysql = list(
  "host" = "localhost",
  "port" = 3306,
  "user" = "root"
))
databaseName <- "readme_info"
table <- "readme_basic"

# Define fields that we want to save from form
fieldsAll <- c("title","num_part","corr_type","description","sample_type","authors","date_range", "citation","email")

# for local testing
# responsesDir <- file.path("~/Desktop")
# on server
 responsesDir <- file.path("/tmp")

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
  output$summary <- DT::renderDataTable({
    loadData()
  }
  ,callback = JS(
    "table.on('click.dt', 'tr', function() {
    $(this).toggleClass('rowselected');
    Shiny.onInputChange('rows',
    table.rows('.rowselected').data().toArray());
});")
  )

  output$selected <- renderPrint(input$summary_rows_selected)
  output$info <- renderPrint({
    cat('Rows Selected File Ids: ')
    # TODO: don't hardcode column numbers
    if (length(input$rows) > 3)
      cat(input$rows[seq(3,length(input$rows),12)])
    
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
  
  # Downloadable csvs of selected rows ----
  output$downloadDataZip <- downloadHandler(
    filename = 'data.zip',
    content = function(fname) {
      #tmpdir <- tempdir()
      #setwd(tempdir())
      #print(tempdir())
      setwd("~/Desktop")
      fs <- input$rows[seq(3,length(input$rows),12)]
      print(fs)
      for (f in fs) {
        write.csv(datasetInput()$rock, file = paste(f,".csv",sep=""), sep =",")
      }
      zip(zipfile=fname, files=fs)
    },
    contentType = "application/zip"
  )

  
  # For Uploading Dataset tab
  
  # Whenever a field is filled, aggregate all form data
  formData <- reactive({
    data <- sapply(fieldsAll, function(x) input[[x]])
    # data <- c(data, timestamp = epochTime())
    data <- t(data)
    data
  })

  saveCSVData <- function(datapath) {
    data <- read.csv(datapath,
                   header = TRUE,
                   sep = ",",
                   quote = '"')
    fileName <- sprintf("%s_%s.csv",
                        humanTime(),
                        digest::digest(data))

    write.csv(x = data, file = file.path(responsesDir, fileName),
              row.names = FALSE, quote = TRUE)
  }
  
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
    db <- dbConnect(RMySQL::MySQL(), dbname = databaseName, host = options()$mysql$host, 
                    port = options()$mysql$port, user = options()$mysql$user, 
                    password = options()$mysql$password)
    # Construct the update query by looping over the data fields
    query <- sprintf(
      "INSERT INTO %s (%s) VALUES ('%s')",
      table, 
      #paste(names(data), collapse = ", "),
      paste(fieldsAll, collapse=", "),
      paste(data, collapse = "', '")
    )
    # Submit the update query and disconnect
    dbSendQuery(db, query)
    dbDisconnect(db)
  }
  
  #loadData for remote SQL database
  loadData <- function() {
    # Connect to the database
    db <- dbConnect(RMySQL::MySQL(), dbname = databaseName, host = options()$mysql$host, 
                    port = options()$mysql$port, user = options()$mysql$user, 
                    password = options()$mysql$password)
    # Construct the fetching query
    query <- sprintf("SELECT * FROM %s", table)
    # Submit the fetch query and disconnect
    data <- dbGetQuery(db, query)
    dbDisconnect(db)
    data
  }
  
  # Use humanTime instead of epochTime for more readable timestamp
  humanTime <- function() format(Sys.time(), "%Y%m%d-%H%M%OS")
  
  # When the Submit button is clicked, save the form data
  observeEvent(input$submit, {
    saveCSVData(input$file1$datapath)
    saveData(formData())
  })
  
  # Show the previous responses
  # (update with current response when Submit is clicked)
  output$responses <- DT::renderDataTable({
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


