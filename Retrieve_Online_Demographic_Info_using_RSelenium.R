#########################################################################
### Project Description: Demographic Information Online Retrieva ########
### Online Resource: https://zipwho.com/ 

### Project Details: For a given set of zip codes, the goal is to retrieve
### demographic information for modeling purpose. Below codes uses the
### Rselenium pageage to scrape the source view of zipwho.com and cleanse
### it into table format in R, then output to csv

### Disclaimer: This is for self-study purpose only. No violation intended

#########################################################################


######################## Library Imports ################################

library(RSelenium)
library(stringr)
library(readr)
library(dplyr)

######################## Constant Variables #############################
# set working directory, change this line for your own folder location

folder_path = "C:/Users/Lukianna/Desktop/"

################## DATA IMPORT ###########################################

ZIP_CODES <- read_delim( file.path(folder_path,"ZIP_CODES.txt") , "\t")

# Check for the file heading, please note that 5 digit zip is required
# for example, 07480 gives results, 7480 would not.
head(ZIP_CODES)

all_zip = as.vector(as.matrix(ZIP_CODES$zip_5))


################## INITIATE THE BROWSER DRIVER ##########################
## I had issues initializing using below code, as that returns the default
## rD <- rsDriver()

## Instead, use below function overwrite the default value from above, 
## This would avoid the compatibility issue with Chrome version and Chrome drive.
## *This code is inherited online*

rD <- RSelenium::rsDriver(
  browser = "chrome",
  chromever =
    system2(command = "wmic",
            args = 'datafile where name="C:\\\\Program Files (x86)\\\\Google\\\\Chrome\\\\Application\\\\chrome.exe" get Version /value',
            stdout = TRUE,
            stderr = TRUE) %>%
    stringr::str_extract(pattern = "(?<=Version=)\\d+\\.\\d+\\.\\d+\\.") %>%
    magrittr::extract(!is.na(.)) %>%
    stringr::str_replace_all(pattern = "\\.", replacement = "\\\\.") %>%
    paste0("^",  .) %>%
    stringr::str_subset(string = binman::list_versions(appname = "chromedriver") %>%
                          dplyr::last()) %>%
    as.numeric_version() %>%
    max() %>%
    as.character()
)

remDr <- rD$client

######################## PAGE NAVIGATION ################################
## Test run below to see if it works.
remDr$open()
## Note: this page is easy to traverse through, zip code is embedded in the url.
remDr$navigate("https://zipwho.com/?zip=07480&city=&filters=--_--_--_--&state=&mode=zip")

## break the link into two sections, to prepare for the loop
URL_front = "view-source:https://zipwho.com/?zip="
URL_end = "&city=&filters=--_--_--_--&state=&mode=zip"


####################### RUN FROM BELOW ##################################

## all the retrievable columns on that website

OUTPUT = c("zip,zip_5,city,state,MedianIncome,MedianIncomeRank,CostOfLivingIndex,
           CostOfLivingRank,MedianMortgageToIncomeRatio,MedianMortgageToIncomeRank,
           OwnerOccupiedHomesPercent,OwnerOccupiedHomesRank,MedianRoomsInHome,
           MedianRoomsInHomeRank,CollegeDegreePercent,CollegeDegreeRank,
           ProfessionalPercent,ProfessionalRank,Population,PopulationRank,
           AverageHouseholdSize,AverageHouseholdSizeRank,MedianAge,MedianAgeRank,
           MaleToFemaleRatio,MaleToFemaleRank,MarriedPercent,MarriedRank,
           DivorcedPercent,DivorcedRank,WhitePercent,WhiteRank,BlackPercent,
           BlackRank,AsianPercent,AsianRank,HispanicEthnicityPercent,
           HispanicEthnicityRank")


for(n in 1:length(all_zip)){
  zip_temp = all_zip[n]
  URL = paste0(URL_front,zip_temp, URL_end)
  
  remDr$navigate(URL)
  framesource = remDr$getPageSource()[[1]]
  
  pointA = regexpr("HispanicEthnicityRank",framesource)
  pointB = regexpr("\";\r</td>",framesource)
  
  data_row= substr (framesource, pointA+23, pointB)
  data_row = gsub ("\"", "", data_row )
  #print(data_row)
  
  if(data_row == ""){
    #invalid page
  } else {
    data_row = paste0(ZIP_CODES[n,1],",",data_row)
    print(data_row)
    OUTPUT = rbind(OUTPUT, data_row)
  }
}

# OUTPUT the search result into csv
write.table(OUTPUT , file.path(folder_path,"ZIP_INFO.txt") ,append = TRUE, 
            quote = FALSE, row.names = FALSE, col.names = FALSE, sep=",")


