library("shiny")
library("data.table")
library("magick")
library("shinyWidgets")

# Define global variables and load data
patternsFull <- c("kwart",
                  "8e noot - 8e noot",
                  "16e noot - 8e noot punt",
                  "8e noot punt - 16e noot",
                  "8e rust - 16e noot - 16e noot",
                  "16e rust - 16e noot - 16e rust - 16e noot",
                  "16e rust - 16e noot - 16e noot - 16e rust")

patternsNotation <- c("4",
                      "8 - 8",
                      "16 - 8p",
                      "8p - 16",
                      "r8 - 16 - 16",
                      "r16 - 16 - r16 - 16",
                      "r16 - 16 - 16 - r16")

difficulty_scores <- c("kwart" = 1,
                       "8e noot - 8e noot" = 2,
                       "16e noot - 8e noot punt" = 3,
                       "8e noot punt - 16e noot" = 3,
                       "8e rust - 16e noot - 16e noot" = 4,
                       "16e rust - 16e noot - 16e rust - 16e noot" = 5,
                       "16e rust - 16e noot - 16e noot - 16e rust" = 5)


notation_lookup <- setNames(patternsNotation, patternsFull)

combinations <- as.data.table(
  expand.grid(count_1 = patternsFull,
              count_2 = patternsFull,
              count_3 = patternsFull,
              count_4 = patternsFull,
              stringsAsFactors = FALSE))

combinations[, combo := paste(notation_lookup[count_1],
                              notation_lookup[count_2],
                              notation_lookup[count_3],
                              notation_lookup[count_4],
                              sep = "  |  ")]

combinations[, difficulty := difficulty_scores[count_1] + difficulty_scores[count_2] + 
               difficulty_scores[count_3] + difficulty_scores[count_4]]

combinations[, variability := apply(.SD, 1, function(x) uniqueN(x)), .SDcols = c("count_1", "count_2", "count_3", "count_4")]

combinations[variability == 4, difficulty := difficulty + 2]
combinations[variability <= 2, difficulty := difficulty - 2]
combinations[, variability := NULL]

combinations[, difficulty_category := fcase(
  difficulty <= 10, "easy",
  difficulty > 10 & difficulty <= 14, "medium",
  difficulty > 14, "hard",
  default = "unknown"
)]

combinations[, idx := .I]

defaultMeasureDifficulty <- "easy"

ui <- fluidPage(
  tags$head(
    tags$link(
      rel = "shortcut icon",
      href = "favicon.ico",
      rel = "stylesheet",
      href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.1/css/all.min.css"
    ),
    
    tags$link(
      rel = "stylesheet",
      href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.1/css/all.min.css"
    ),
    
    tags$script(
      src = "rhythm-player.js"
    ),
    
    tags$style(HTML("
      body, html {
        margin: 0;
        padding: 0;
        overflow-x: hidden;
      }
      
      .main-header {
        text-align: center;
        width: 100%;
      }
      
      .main-header img {
        display: block;
        margin: 0 auto;
        height: 100px;
        max-width: 100%;
        margin-top: 15px;
        margin-bottom: 10px;
      }
      
      .center-content {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        width: 100%;
        margin-top: 20px;
      }
      
      .footer {
        padding: 30px 0;
        text-align: center;
        background-color: #F8F9FA;
        border-top: 1px solid #E9ECEF;
        font-size: 16px;
        width: 100%
      }
      
      .image-container {
        max-width: 100%;
        max-height: 200px;
        margin-top: 50px;
        margin-left: auto;
        margin-right: auto;
        object-fit: contain;
        justify-content: center;
        align-items: center;
      }
      
      .image-container img {
        max-width: 100%;
        max-height: 100%;
      }
      
      .js-irs-0 .irs-single, .js-irs-0 .irs-bar-edge, .js-irs-0 .irs-bar {
        background: #FF7500;
        border-color: #FF7500 !important;
        color: black;
        font-weight: bold;
      }
      
      #startMetronome {
        background-color: #FF7500;
        border-color: #FF7500;
        color: black;
        margin-bottom: 5px;
      }
      
      #startRhythm {
        background-color: #FF7500;
        border-color: #FF7500;
        color: black;
        margin-bottom: 25px;
      }
      
      #stop {
        background-color: #801100;
        border-color: #801100;
        color: white;
        margin-bottom: 25px;
      }
      
      .pretty.p-default input:checked ~ .state label:before {
          border-color: #FF7500 !important;
      }
      
      .pretty.p-default input:checked ~ .state label:after {
        background-color: #FF7500 !important;
        box-shadow: inset 0 0 0 15px #FF7500 !important; /* Coloured shadow to mimic filling */
      }
      
      .pretty.p-default input:checked ~ .state.p-primary-o label:after {
        background-color: #FF7500 !important;
        border-width: 0px !important;
      }
      
      #randomBtn {
        background-color: #FF7500;
        border-color: #FF7500;
        color: black;
        font-size: 18px;
        font-weight: bold;
      }
      ")
    )
  ),
  
  div(class = "main-header",
      img(
        src = "title-card.png",
        alt = "Random Measure Generator"
      )
  ),
  
  div(class = "center-content",
      
      sliderInput("bpm", "Set BPM:", min = 40, max = 120, value = 80, step = 1, ticks = FALSE),
      
      actionButton("startMetronome", "Metronome Only", class = "btn btn-success", icon = icon("play")),
      
      actionButton("startRhythm", "Metronome with Rhythm", class = "btn btn-success", icon = icon("play")),
      
      actionButton("stop", "Stop", class = "btn btn-danger", icon = icon("stop")),
      
      prettyRadioButtons(
        inputId = "radioDifficultySelect",
        label = "Select difficulty:",
        choices = c("Easy" = "easy", "Medium" = "medium", "Hard" = "hard"),
        outline = TRUE,
        plain = FALSE,
        status = "primary",
        animation = "smooth",
        inline = TRUE
      ),
      
      actionButton("randomBtn", "Generate random measure!", class = "btn btn-success", icon = icon("magic")),
      
      div(class = "image-container", imageOutput("measureImage")),
      
      verbatimTextOutput("measureInfo"),
      
      # Footer section
      tags$hr(),
      div(class = "footer",
          "Designed by Jasper Naberman © 2024"
      )
  )
)

server <- function(input, output, session) {
  # sample default index value for initial loading
  initial_indices <- combinations[difficulty_category == defaultMeasureDifficulty, idx]
  initial_index <- sample(initial_indices, 1)
  selected_index <- reactiveVal(initial_index)
  
  # Define a reactive value to track the playing state
  playingState <- reactiveValues(rhythm = FALSE, metronome = FALSE)
  
  # adjust metronome bpm
  observe({
    req(input$bpm)
    if (playingState$metronome) {
      session$sendCustomMessage(type = "adjustMetronome", message = list(bpm = input$bpm))
    }
  })
  
  # start metronome
  observeEvent(input$startMetronome, {
    bpm <- isolate(input$bpm)
    
    session$sendCustomMessage(type = 'stopRhythm', message = list())
    session$sendCustomMessage(type = "startMetronome", message = list(bpm = bpm))
    
    playingState$metronome <- TRUE
    playingState$rhythm <- FALSE
  }, ignoreNULL = FALSE)
  
  # start rhythm (+ metronome)
  observeEvent(input$startRhythm, {
    index <- selected_index()
    
    pattern_data <- combinations[index, .(count_1, count_2, count_3, count_4)]
    rhythm_parts_list <- list(pattern_data$count_1,
                              pattern_data$count_2,
                              pattern_data$count_3,
                              pattern_data$count_4)
    
    session$sendCustomMessage(type = "stopMetronome", message = list())
    session$sendCustomMessage(type = 'startRhythm', message = rhythm_parts_list)
    
    playingState$rhythm <- TRUE
    playingState$metronome <- TRUE
  })
  
  # stop metronome only & metronome + rhythm
  observeEvent(input$stop, {
    session$sendCustomMessage(type = "stopMetronome", message = list())
    session$sendCustomMessage(type = 'stopRhythm', message = list())
    
    playingState$metronome <- FALSE
    playingState$rhythm <- FALSE
  }, ignoreNULL = FALSE)
  
  # generate random measure button
  observeEvent(input$randomBtn, {
    req(input$radioDifficultySelect)
    
    filtered_indices <- combinations[difficulty_category == input$radioDifficultySelect, idx]
    
    if (length(filtered_indices) > 0) {
      sampled_index <- sample(filtered_indices, 1)
      selected_index(sampled_index)
    } else {
      selected_index(NULL)
      showNotification("No measures available for selected difficulty.", type = "warning")
    }
    
    if (playingState$rhythm) {
      session$sendCustomMessage(type = 'stopRhythm', message = list())
      playingState$rhythm <- FALSE
      
      # If the metronome was playing with the rhythm, restart it
      if (playingState$metronome) {
        session$sendCustomMessage(type = "startMetronome", message = list(bpm = input$bpm))
      }
    }
  })
  
  # generate corresponding measure image
  output$measureImage <- renderImage({
    index <- selected_index()
    
    if (!is.null(index)) {
      selected_row_DT <- combinations[index]
      
      # Retrieve the notation to find corresponding images
      image_files <- c(notation_lookup[selected_row_DT[, count_1]],
                       notation_lookup[selected_row_DT[, count_2]],
                       notation_lookup[selected_row_DT[, count_3]],
                       notation_lookup[selected_row_DT[, count_4]])
      
      # Load images and add borders to each image for spacing
      image_paths <- paste0("www/images/", image_files, ".png")
      images <- lapply(image_paths, image_read)
      images <- lapply(images, function(img) { image_border(img, "white", "50x50") })
      
      # Load images and combine them into a composite measure image
      measure_image <- image_montage(do.call(c, images),
                                     tile = "x1",
                                     gravity = "Center",
                                     geometry = "+50+0")
      
      imagePixelHeight <- 200
      measure_image <- image_resize(measure_image, paste0("x", imagePixelHeight))
      
      measure_image <- image_convert(measure_image, format = "png")
      
      # Save the image temporarily
      temp <- tempfile(fileext = ".png")
      tryCatch({
        image_write(measure_image, temp)
      }, error = function(e) {
        error_message <- paste("Error in image_write:", e$message)
        print(error_message)
        temp <- error_message
      })
      
      list(src = temp, contentType = 'image/png', height = imagePixelHeight, alt = "No successful run. Try again.")
    } else {
      list(src = NULL, alt = "No measure selected.")
    }
  },
  deleteFile = TRUE
  )
  
  # genearate measure info text block
  output$measureInfo <- renderText({
    index <- selected_index()
    
    if (!is.null(index)) {
      paste0("Measure: |  ", combinations[index, combo], "  |\n",
             "Difficulty counts: ",
             paste(combinations[index,
                                c(difficulty_scores[count_1],
                                  difficulty_scores[count_2],
                                  difficulty_scores[count_3],
                                  difficulty_scores[count_4])],
                   collapse = " + "), "\n",
             "Difficulty score: ", combinations[index, difficulty], " / 19 (",
             round(combinations[index, difficulty] / 19 * 100), "%)")
    } else {
      "No measure selected"
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)
