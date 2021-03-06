library("data.table")
library("ggplot2")
#download the data 
fileUrl<-"https://d396qusza40orc.cloudfront.net/repdata%2Fdata%2FStormData.csv.bz2"
if(!file.exists("data"))
        dir.create("data")
download.file(fileUrl, destfile = "data/stormData.csv.bz2")

#read the file
stormData<-read.csv(bzfile("data/stormData.csv.bz2"))
stormData<-as.data.table(stormData)

#View header
head(stromData)

# Only use data where fatalities or injuries occurred and keep only reqired column.  
stormData <- stormData[(EVTYPE != "?" & 
                                (INJURIES > 0 | FATALITIES > 0 | PROPDMG > 0 | CROPDMG > 0)), c("EVTYPE"
                                                                                                , "FATALITIES"
                                                                                                , "INJURIES"
                                                                                                , "PROPDMG"
                                                                                                , "PROPDMGEXP"
                                                                                                , "CROPDMG"
                                                                                                , "CROPDMGEXP") ]
head(stormData)

# Change all damage exponents to uppercase.
cols <- c("PROPDMGEXP", "CROPDMGEXP")
stormData[,  (cols) := c(lapply(.SD, toupper)), .SDcols = cols]

# Map property damage alphanumeric exponents to numeric values.
propDmgKey <-  c("\"\"" = 10^0,
                 "-" = 10^0, 
                 "+" = 10^0,
                 "0" = 10^0,
                 "1" = 10^1,
                 "2" = 10^2,
                 "3" = 10^3,
                 "4" = 10^4,
                 "5" = 10^5,
                 "6" = 10^6,
                 "7" = 10^7,
                 "8" = 10^8,
                 "9" = 10^9,
                 "H" = 10^2,
                 "K" = 10^3,
                 "M" = 10^6,
                 "B" = 10^9)

# Map crop damage alphanumeric exponents to numeric values
cropDmgKey <-  c("\"\"" = 10^0,
                 "?" = 10^0, 
                 "0" = 10^0,
                 "K" = 10^3,
                 "M" = 10^6,
                 "B" = 10^9)


stormData[, PROPDMGEXP := propDmgKey[as.character(stormData[,PROPDMGEXP])]]
stormData[is.na(PROPDMGEXP), PROPDMGEXP := 10^0 ]

stormData[, CROPDMGEXP := cropDmgKey[as.character(stormData[,CROPDMGEXP])] ]
stormData[is.na(CROPDMGEXP), CROPDMGEXP := 10^0 ]


stormData <- stormData[, .(EVTYPE, FATALITIES, INJURIES, PROPDMG, PROPDMGEXP, propCost = PROPDMG * PROPDMGEXP, CROPDMG, CROPDMGEXP, cropCost = CROPDMG * CROPDMGEXP)]

totalCostDT <- stormData[, .(propCost = sum(propCost), cropCost = sum(cropCost), Total_Cost = sum(propCost) + sum(cropCost)), by = .(EVTYPE)]

totalCostDT <- totalCostDT[order(-Total_Cost), ]

totalCostDT <- totalCostDT[1:10, ]

head(totalCostDT, 5)


totalInjuriesDT <- stormData[, .(FATALITIES = sum(FATALITIES), INJURIES = sum(INJURIES), totals = sum(FATALITIES) + sum(INJURIES)), by = .(EVTYPE)]

totalInjuriesDT <- totalInjuriesDT[order(-FATALITIES), ]

totalInjuriesDT <- totalInjuriesDT[1:10, ]

head(totalInjuriesDT, 5)

fatalInjury <- melt(totalInjuriesDT, id.vars="EVTYPE", variable.name = "fatalInjury")
head(fatalInjury, 5)

#create graph
ggplot(fatalInjury, aes(fill = fatalInjury, x = reorder(EVTYPE,-value), y = value))+
        geom_bar(position = "dodge", stat = "identity")+
        ylab("Frequency Count")+
        xlab("Event Type")+
        theme(axis.text.x = element_text(angle=90, hjust=1))+
        ggtitle("Top 10 US Killers")+ theme(plot.title = element_text(hjust = 0.5))

econ_consequences <- melt(totalCostDT, id.vars="EVTYPE", variable.name = "Damage_Type")
head(econ_consequences, 5)

#create graph
ggplot(econ_consequences, aes(fill = Damage_Type, x = reorder(EVTYPE,-value), y = value))+
        geom_bar(position = "dodge", stat = "identity")+
        ylab("Cost (dollars)")+
        xlab("Event Type")+
        theme(axis.text.x = element_text(angle=90, hjust=1))+
        ggtitle("Top 10 US Storm Events causing Economic Consequences") + theme(plot.title = element_text(hjust = 0.5))



        
        






