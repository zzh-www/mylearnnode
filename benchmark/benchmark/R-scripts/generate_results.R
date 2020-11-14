# Script for the result evaluation and generation of plots.

#########################
# Definition of Globals #
#########################

# You may change these global variables for different purposes.
# You should at least check the MySQL configuration below

# MySQL Configuration -   数据库配置
MYSQL_HOST <- "localhost"
MYSQL_PORT <- 3306
MYSQL_DBNAME <- "crosspare"
MYSQL_USER <- "crosspare"
MYSQL_PASSWORT <- "crosspare"

# Path for all generates plots         所有图的储存路径
PLOT_PATH <- "D:\\RSOURECE\\figures\\"

# Path for all generated tables         生成的所有图的储存路径
TABLES_PATH <- "D:\\RSOURECE\\tables\\"

# If true the plots included in the article are generated    如果为真则生成文章中的所有图
CREATEPLOTS <- FALSE

# Defines wether Friedman-Nemenyi or ANOVA with Scott-Knott clustering is used for ranking    定义 是使用 Friedman-Nemenyi 还是 ANOVA with Scott-Knott clustering 方法进行排序
# TRUE = Friedman-Nemenyi, FALSE = Scott-Knott
NONPARAMETRIC <- TRUE

# 1 for fine-grained Nemenyi ranking from the correction            NONPARAMETRICRANKINGMODE 参数设置为 1 将以改良后的细粒度后续检验排序
# Any other number for the three-ranks approach from the original paper     其他参数则以原始文章的三种方法排序
NONPARAMETRICRANKINGMODE <- 1

# If true CD charts for Friedman-Nemenyi tests are created  CD charts 为 Critical Distance Diagram 临界距离图 即意思为设置为TRUE则会创建CD charts
PRINTCDCHARTS <- TRUE
CD_EXPORT_WIDTH <- 10

#################################
# Install and load dependencies #    下载相应依赖
#################################
if (!require("RMySQL")) install.packages("RMySQL")
# https://iowiki.com/r/r_database.html  RMySQL教程
if (!require("ScottKnott")) install.packages("ScottKnott")
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("gridExtra")) install.packages("gridExtra")
if (!require("xtable")) install.packages("xtable")
if (!require("reshape")) install.packages("reshape")
if (!require("gdata")) install.packages("gdata")
if (!require("stringr")) install.packages("stringr")

library(RMySQL)
library(ScottKnott)
library(ggplot2)
library(gridExtra)
library(xtable)
library(reshape)
library(gdata)
library(stringr)

# We have to increase the number of nested expressions, because the CD diagrams cannot be plotted otherwise         设置堆栈数，不然不够
options(expressions = 10000)

########################################################
# Definition of functions with result evaluation logic #
########################################################

evaluateCPDPBenchmark <- function(metricNames, datasets) {

  # rq1results = evaluateCPDPBenchmark(metricNamesRQ1, datasetsRQ1)    datasetsRQ1 = c("JURECZKO", "MDP", "AEEEM_LDHHWCHU", "RELINK", "NETGENE")
  mydb <- dbConnect(MySQL(), user = MYSQL_USER, password = MYSQL_PASSWORT, host = MYSQL_HOST, port = MYSQL_PORT, dbname = MYSQL_DBNAME)

  dbListTables(mydb)
  dbListFields(mydb, "crosspare.results")

  sqlStatement <- "SELECT DISTINCT concat(substring(configurationName, 8), '-', classifier) as config FROM resultsView WHERE configurationName LIKE 'RELINK-%';"
  rs <- dbSendQuery(mydb, sqlStatement)
  configurations <- fetch(rs, n = -1)

  for (i in 1:length(datasets)) {
    dataset <- datasets[i]
    sqlStatement <- paste("SELECT concat(substring(configurationName, ",
      nchar(dataset) + 2,
      "), '-', classifier) as config, ",
      paste(metricNames, collapse = ", "),
      " FROM resultsView WHERE configurationName LIKE '",
      dataset, "-%';",
      sep = ""
    )
    print(sqlStatement)
    print("+++++++++++++++++++++++++++++++++++++++++++++++++++")
    # evaluateCPDPBenchmark(metricNamesRQ1, datasetsRQ1)
    ###############################################################################################################################################################################
    # [1] "SELECT concat(substring(configurationName, 10), '-', classifier) as config, auc, fscore, gscore, mcc FROM resultsView WHERE configurationName LIKE 'JURECZKO-%';"      #
    # [1] "+++++++++++++++++++++++++++++++++++++++++++++++++++"                                                                                                                   #
    # [1] "SELECT concat(substring(configurationName, 5), '-', classifier) as config, auc, fscore, gscore, mcc FROM resultsView WHERE configurationName LIKE 'MDP-%';"            #
    # [1] "+++++++++++++++++++++++++++++++++++++++++++++++++++"                                                                                                                   #
    # [1] "SELECT concat(substring(configurationName, 16), '-', classifier) as config, auc, fscore, gscore, mcc FROM resultsView WHERE configurationName LIKE 'AEEEM_LDHHWCHU-%';"#
    # [1] "+++++++++++++++++++++++++++++++++++++++++++++++++++"                                                                                                                   #
    # [1] "SELECT concat(substring(configurationName, 8), '-', classifier) as config, auc, fscore, gscore, mcc FROM resultsView WHERE configurationName LIKE 'RELINK-%';"         #
    # [1] "+++++++++++++++++++++++++++++++++++++++++++++++++++"                                                                                                                   #
    # [1] "SELECT concat(substring(configurationName, 9), '-', classifier) as config, auc, fscore, gscore, mcc FROM resultsView WHERE configurationName LIKE 'NETGENE-%';"        #
    # [1] "+++++++++++++++++++++++++++++++++++++++++++++++++++"                                                                                                                   #
    ###############################################################################################################################################################################
    rs <- dbSendQuery(mydb, sqlStatement)
    results <- fetch(rs, n = -1)
    # -1代表所有,或剩余
    results[is.na(results)] <- 0
    # results里的所有缺失值都置为0

    cnts <- data.frame(config = unique(results$config), count = 0)
    # 取出config一列去重,并增加一个列,列名为count,值为0

    #                    config    auc           fscore        gscore            mcc
    # 1                  ALL-DT     ...             ...         ...               ...
    # 2                  ALL-LR     ...             ...         ...               ...

    # print(results)




    #                    config     count
    # 1                  ALL-DT     0
    # 2                  ALL-LR     0
    # 3                  ALL-NB     0
    # 4                 ALL-NET     0
    # 5                  ALL-RF     0
    # 6                 ALL-SVM     0
    # 7            Amasaki15-DT     0
    # 8            Amasaki15-LR     0
    # 9            Amasaki15-NB     0
    # 10          Amasaki15-NET     0
    # 11           Amasaki15-RF     0
    # 12          Amasaki15-SVM     0
    # 13       CamargoCruz09-DT     0
    # 14       CamargoCruz09-LR     0
    # 15       CamargoCruz09-NB     0
    # 16      CamargoCruz09-NET     0
    # 17       CamargoCruz09-RF     0
    # 18      CamargoCruz09-SVM     0
    # 19        Canfora13-MODEP     0
    # 20                  CV-DT     0
    # 21                  CV-LR     0
    # 22                  CV-NB     0
    # 23                 CV-NET     0
    # 24                  CV-RF     0
    # 25                 CV-SVM     0
    # 26           Herbold13-DT     0
    # 27           Herbold13-LR     0
    # 28           Herbold13-NB     0
    # 29          Herbold13-NET     0
    # 30           Herbold13-RF     0
    # 31          Herbold13-SVM     0
    # 32            Kawata15-DT     0
    # 33            Kawata15-LR     0
    # 34            Kawata15-NB     0
    # print(cnts)

    # R语言中

    # $表示从一个dataframe中取出某一列数据

    # @是从R的类实例里面读取数据，bg=x@colors$bg.col就是从对象实例x中取出colors，而这个colors本身又是个dataframe，所以需要进一步用$读取bg.col列。


    print(nrow(results))
    cat("????????????????????????????????????????????????????????????????")
    for (j in 1:nrow(results)) {
      # nrow(results)获取results表行数 j便是从1到nrow(results)
      cnts[cnts$config == results$config[j], ]$count <- cnts[cnts$config == results$config[j], ]$count + 1
      # 计数作用，记录config出现过多少次显示在count中
      # SELECT concat(substring(configurationName, 10), '-', classifier) as config, auc, fscore, gscore, mcc FROM resultsView WHERE configurationName LIKE 'JURECZKO-%'轮，本循环结束后的cnts

      #                    config     count
      # 1                  ALL-DT     29

      # 2                  ALL-LR     29
      # 3                  ALL-NB     29
      # 4                 ALL-NET     29
      # 5                  ALL-RF     29
      # 6                 ALL-SVM     28
      # 7            Amasaki15-DT     0
      # 8            Amasaki15-LR     0
      # 9            Amasaki15-NB     0
      results$index[j] <- cnts[cnts$config == results$config[j], ]$count
      # 表示是同config中第几次出现的
    }
    #RQ1 metricNames "auc"    "fscore" "gscore" "mcc"
    if ("auc" %in% metricNames) {
      if (NONPARAMETRIC) {
        # Friedman-Nemenyi Test  前后校验方法   default 默认模式
        meanRanks <- createMeanRankMat(results, "auc")
        #对结果依据auc进行Friedman-Nemenyi Test排名，一个顺位排名（即无平均序值）rank 1 1 2 3 另一个排名即使平均序值排名 normRank
        if (PRINTCDCHARTS) {
          # 创建临界距离图
          printMetricName <- "AUC"
          plotObj <- plotCDNemenyiFriedman(meanRanks, max(results$index), title = paste("Critical Distance Diagram for ", printMetricName, " and the ", dataset, " data", sep = ""))
          ggsave(filename = paste(PLOT_PATH, printMetricName, "_", dataset, ".png", sep = ""), plot = plotObj, device = "png", width = CD_EXPORT_WIDTH, height = CD_EXPORT_WIDTH)
        }

        colnumber <- ncol(configurations) + 1
        if (NONPARAMETRICRANKINGMODE == 1) {
          for (j in 1:nrow(configurations)) {
            if (configurations$config[j] %in% meanRanks$config) {
              configurations[j, colnumber] <- meanRanks[meanRanks$config == configurations$config[j], ]$normRank
              #将平均序值增添到configurations即加一列以平均序值为值
            }
          }
        } 
        else {
          cdNemenyi <- getNemenyiCD(0.05, length(unique(results$config)), max(results$index))
          maxMeanRank <- max(meanRanks$meanRank)
          minMeanRank <- min(meanRanks$meanRank)

          # with CD within first results
          if (maxMeanRank - minMeanRank <= cdNemenyi) {
            # all on first rank
            configurations[, colnumber] <- 1
          }
          else if (maxMeanRank - minMeanRank <= 2 * cdNemenyi) {
            # only two ranks
            firstRank <- meanRanks$config[meanRanks$meanRank >= maxMeanRank - cdNemenyi]
            secondRank <- meanRanks$config[meanRanks$meanRank < maxMeanRank - cdNemenyi]
            configurations[configurations$config %in% firstRank, colnumber] <- 1
            configurations[configurations$config %in% secondRank, colnumber] <- 1 - length(firstRank) / (nrow(meanRanks) - 1)
          } else {
            # three ranks
            firstRank <<- meanRanks$config[meanRanks$meanRank >= maxMeanRank - cdNemenyi]
            secondRank <<- meanRanks$config[meanRanks$meanRank > minMeanRank + cdNemenyi & meanRanks$meanRank < maxMeanRank - cdNemenyi]
            thirdRank <<- meanRanks$config[meanRanks$meanRank <= minMeanRank + cdNemenyi]
            configurations[configurations$config %in% firstRank, colnumber] <- 1
            configurations[configurations$config %in% secondRank, colnumber] <- 1 - length(firstRank) / (nrow(meanRanks) - 1)
            configurations[configurations$config %in% thirdRank, colnumber] <- 1 - (length(firstRank) + length(secondRank)) / (nrow(meanRanks) - 1)
          }
        }
        colnames(configurations)[colnumber] <- paste("AUC", dataset, sep = "_")
        # 给平均序值取名为AUC-dataset
      } else {
        # AOV and Scott-Knott test
        skresult <- SK(aov(auc ~ config, results), sig.level = 0.05)
        colnumber <- ncol(configurations) + 1
        higherRanked <- 0
        for (j in 1:length(unique(skresult$groups))) {
          orderedNms <- skresult$nms[skresult$ord]
          configurations[configurations$config %in% orderedNms[skresult$groups == j], colnumber] <- 1 - (higherRanked / (nrow(configurations) - 1))
          higherRanked <- higherRanked + length(orderedNms[skresult$groups == j])
        }
        colnames(configurations)[colnumber] <- paste("AUC", dataset, sep = "_")
      }
      colnumber <- ncol(configurations) + 1
      for (j in 1:nrow(configurations)) {
        configurations[j, colnumber] <- mean(results[results$config == configurations$config[j], ]$auc, na.rm = TRUE)
        # 将result中config与configurations中的config相同的所有行的auc相加取均值，添加到configus中作为meanAUC_dataset
      }
      colnames(configurations)[colnumber] <- paste("meanAUC", dataset, sep = "_")
    }

    if ("fscore" %in% metricNames) {
      if (NONPARAMETRIC) {
        # Friedman-Nemenyi Test
        meanRanks <- createMeanRankMat(results, "fscore")
        if (PRINTCDCHARTS) {
          printMetricName <- "F-Measure"
          plotObj <- plotCDNemenyiFriedman(meanRanks, max(results$index), title = paste("Critical Distance Diagram for ", printMetricName, " and the ", dataset, " data", sep = ""))
          ggsave(filename = paste(PLOT_PATH, printMetricName, "_", dataset, ".png", sep = ""), plot = plotObj, device = "png", width = CD_EXPORT_WIDTH, height = CD_EXPORT_WIDTH)
        }

        colnumber <- ncol(configurations) + 1
        if (NONPARAMETRICRANKINGMODE == 1) {
          for (j in 1:nrow(configurations)) {
            if (configurations$config[j] %in% meanRanks$config) {
              configurations[j, colnumber] <- meanRanks[meanRanks$config == configurations$config[j], ]$normRank
            }
          }
        } else {
          cdNemenyi <- getNemenyiCD(0.05, length(unique(results$config)), max(results$index))
          maxMeanRank <- max(meanRanks$meanRank)
          minMeanRank <- min(meanRanks$meanRank)

          # with CD within first results
          if (maxMeanRank - minMeanRank <= cdNemenyi) {
            # all on first rank
            configurations[, colnumber] <- 1
          }
          else if (maxMeanRank - minMeanRank <= 2 * cdNemenyi) {
            # only two ranks
            firstRank <- meanRanks$config[meanRanks$meanRank >= maxMeanRank - cdNemenyi]
            secondRank <- meanRanks$config[meanRanks$meanRank < maxMeanRank - cdNemenyi]
            configurations[configurations$config %in% firstRank, colnumber] <- 1
            configurations[configurations$config %in% secondRank, colnumber] <- 1 - length(firstRank) / (nrow(meanRanks) - 1)
          } else {
            # three ranks
            firstRank <<- meanRanks$config[meanRanks$meanRank >= maxMeanRank - cdNemenyi]
            secondRank <<- meanRanks$config[meanRanks$meanRank > minMeanRank + cdNemenyi & meanRanks$meanRank < maxMeanRank - cdNemenyi]
            thirdRank <<- meanRanks$config[meanRanks$meanRank <= minMeanRank + cdNemenyi]
            configurations[configurations$config %in% firstRank, colnumber] <- 1
            configurations[configurations$config %in% secondRank, colnumber] <- 1 - length(firstRank) / (nrow(meanRanks) - 1)
            configurations[configurations$config %in% thirdRank, colnumber] <- 1 - (length(firstRank) + length(secondRank)) / (nrow(meanRanks) - 1)
          }
        }
        colnames(configurations)[colnumber] <- paste("FMEAS", dataset, sep = "_")
      }
      else {
        skresult <- SK(aov(fscore ~ config, results), sig.level = 0.05)
        colnumber <- ncol(configurations) + 1
        higherRanked <- 0
        for (j in 1:length(unique(skresult$groups))) {
          orderedNms <- skresult$nms[skresult$ord]
          configurations[configurations$config %in% orderedNms[skresult$groups == j], colnumber] <- 1 - (higherRanked / (nrow(configurations) - 1))
          higherRanked <- higherRanked + length(orderedNms[skresult$groups == j])
        }
        colnames(configurations)[colnumber] <- paste("FMEAS", dataset, sep = "_")
      }
      colnumber <- ncol(configurations) + 1
      for (j in 1:nrow(configurations)) {
        configurations[j, colnumber] <- mean(results[results$config == configurations$config[j], ]$fscore, na.rm = TRUE)
      }
      colnames(configurations)[colnumber] <- paste("meanFMEAS", dataset, sep = "_")
    }

    if ("gscore" %in% metricNames) {
      if (NONPARAMETRIC) {
        # Friedman-Nemenyi Test
        meanRanks <- createMeanRankMat(results, "gscore")
        if (PRINTCDCHARTS) {
          printMetricName <- "G-measure"
          plotObj <- plotCDNemenyiFriedman(meanRanks, max(results$index), title = paste("Critical Distance Diagram for ", printMetricName, " and the ", dataset, " data", sep = ""))
          ggsave(filename = paste(PLOT_PATH, printMetricName, "_", dataset, ".png", sep = ""), plot = plotObj, device = "png", width = CD_EXPORT_WIDTH, height = CD_EXPORT_WIDTH)
        }

        colnumber <- ncol(configurations) + 1
        if (NONPARAMETRICRANKINGMODE == 1) {
          for (j in 1:nrow(configurations)) {
            if (configurations$config[j] %in% meanRanks$config) {
              configurations[j, colnumber] <- meanRanks[meanRanks$config == configurations$config[j], ]$normRank
            }
          }
        } else {
          cdNemenyi <- getNemenyiCD(0.05, length(unique(results$config)), max(results$index))
          maxMeanRank <- max(meanRanks$meanRank)
          minMeanRank <- min(meanRanks$meanRank)

          # with CD within first results
          if (maxMeanRank - minMeanRank <= cdNemenyi) {
            # all on first rank
            configurations[, colnumber] <- 1
          }
          else if (maxMeanRank - minMeanRank <= 2 * cdNemenyi) {
            # only two ranks
            firstRank <- meanRanks$config[meanRanks$meanRank >= maxMeanRank - cdNemenyi]
            secondRank <- meanRanks$config[meanRanks$meanRank < maxMeanRank - cdNemenyi]
            configurations[configurations$config %in% firstRank, colnumber] <- 1
            configurations[configurations$config %in% secondRank, colnumber] <- 1 - length(firstRank) / (nrow(meanRanks) - 1)
          } else {
            # three ranks
            firstRank <<- meanRanks$config[meanRanks$meanRank >= maxMeanRank - cdNemenyi]
            secondRank <<- meanRanks$config[meanRanks$meanRank > minMeanRank + cdNemenyi & meanRanks$meanRank < maxMeanRank - cdNemenyi]
            thirdRank <<- meanRanks$config[meanRanks$meanRank <= minMeanRank + cdNemenyi]
            configurations[configurations$config %in% firstRank, colnumber] <- 1
            configurations[configurations$config %in% secondRank, colnumber] <- 1 - length(firstRank) / (nrow(meanRanks) - 1)
            configurations[configurations$config %in% thirdRank, colnumber] <- 1 - (length(firstRank) + length(secondRank)) / (nrow(meanRanks) - 1)
          }
        }
        colnames(configurations)[colnumber] <- paste("GMEAS", dataset, sep = "_")
      }
      else {
        skresult <- SK(aov(gscore ~ config, results), sig.level = 0.05)
        colnumber <- ncol(configurations) + 1
        higherRanked <- 0
        for (j in 1:length(unique(skresult$groups))) {
          orderedNms <- skresult$nms[skresult$ord]
          configurations[configurations$config %in% orderedNms[skresult$groups == j], colnumber] <- 1 - (higherRanked / (nrow(configurations) - 1))
          higherRanked <- higherRanked + length(orderedNms[skresult$groups == j])
        }
        colnames(configurations)[colnumber] <- paste("GMEAS", dataset, sep = "_")
      }
      colnumber <- ncol(configurations) + 1
      for (j in 1:nrow(configurations)) {
        configurations[j, colnumber] <- mean(results[results$config == configurations$config[j], ]$gscore, na.rm = TRUE)
      }
      colnames(configurations)[colnumber] <- paste("meanGMEAS", dataset, sep = "_")
    }

    if ("mcc" %in% metricNames) {
      if (NONPARAMETRIC) {
        # Friedman-Nemenyi Test
        meanRanks <- createMeanRankMat(results, "mcc")
        if (PRINTCDCHARTS) {
          printMetricName <- "MCC"
          plotObj <- plotCDNemenyiFriedman(meanRanks, max(results$index), title = paste("Critical Distance Diagram for ", printMetricName, " and the ", dataset, " data", sep = ""))
          ggsave(filename = paste(PLOT_PATH, printMetricName, "_", dataset, ".png", sep = ""), plot = plotObj, device = "png", width = CD_EXPORT_WIDTH, height = CD_EXPORT_WIDTH)
        }

        colnumber <- ncol(configurations) + 1
        if (NONPARAMETRICRANKINGMODE == 1) {
          for (j in 1:nrow(configurations)) {
            if (configurations$config[j] %in% meanRanks$config) {
              configurations[j, colnumber] <- meanRanks[meanRanks$config == configurations$config[j], ]$normRank
            }
          }
        } else {
          cdNemenyi <- getNemenyiCD(0.05, length(unique(results$config)), max(results$index))
          maxMeanRank <- max(meanRanks$meanRank)
          minMeanRank <- min(meanRanks$meanRank)

          # with CD within first results
          if (maxMeanRank - minMeanRank <= cdNemenyi) {
            # all on first rank
            configurations[, colnumber] <- 1
          }
          else if (maxMeanRank - minMeanRank <= 2 * cdNemenyi) {
            # only two ranks
            firstRank <- meanRanks$config[meanRanks$meanRank >= maxMeanRank - cdNemenyi]
            secondRank <- meanRanks$config[meanRanks$meanRank < maxMeanRank - cdNemenyi]
            configurations[configurations$config %in% firstRank, colnumber] <- 1
            configurations[configurations$config %in% secondRank, colnumber] <- 1 - length(firstRank) / (nrow(meanRanks) - 1)
          } else {
            # three ranks
            firstRank <<- meanRanks$config[meanRanks$meanRank >= maxMeanRank - cdNemenyi]
            secondRank <<- meanRanks$config[meanRanks$meanRank > minMeanRank + cdNemenyi & meanRanks$meanRank < maxMeanRank - cdNemenyi]
            thirdRank <<- meanRanks$config[meanRanks$meanRank <= minMeanRank + cdNemenyi]
            configurations[configurations$config %in% firstRank, colnumber] <- 1
            configurations[configurations$config %in% secondRank, colnumber] <- 1 - length(firstRank) / (nrow(meanRanks) - 1)
            configurations[configurations$config %in% thirdRank, colnumber] <- 1 - (length(firstRank) + length(secondRank)) / (nrow(meanRanks) - 1)
          }
        }
        colnames(configurations)[colnumber] <- paste("MCC", dataset, sep = "_")
      }
      else {
        skresult <- SK(aov(mcc ~ config, results), sig.level = 0.05)
        colnumber <- ncol(configurations) + 1
        higherRanked <- 0
        for (j in 1:length(unique(skresult$groups))) {
          orderedNms <- skresult$nms[skresult$ord]
          configurations[configurations$config %in% orderedNms[skresult$groups == j], colnumber] <- 1 - (higherRanked / (nrow(configurations) - 1))
          higherRanked <- higherRanked + length(orderedNms[skresult$groups == j])
        }
        colnames(configurations)[colnumber] <- paste("MCC", dataset, sep = "_")
      }
      colnumber <- ncol(configurations) + 1
      for (j in 1:nrow(configurations)) {
        configurations[j, colnumber] <- mean(results[results$config == configurations$config[j], ]$mcc, na.rm = TRUE)
      }
      colnames(configurations)[colnumber] <- paste("meanMCC", dataset, sep = "_")
    }

    if (CREATEPLOTS) {
      if ("auc" %in% metricNames) {
        plotauc <- ggplot(data = results, aes(reorder(config, auc, FUN = mean), auc)) +
          ggtitle(paste("AUC ordered by the mean value for", dataset, "data")) +
          geom_boxplot() +
          stat_summary(fun.y = mean, geom = "point", size = 3, shape = 9) +
          scale_y_continuous(limits = c(0, 1.0)) +
          coord_flip() +
          theme(axis.text = element_text(size = 8), axis.title = element_text(size = 8), title = element_text(size = 8), axis.text.x = element_text(angle = 90, hjust = 1))
        ggsave(filename = paste(PLOT_PATH, "AUC_", dataset, ".pdf", sep = ""), plot = plotauc)
      }

      if ("fscore" %in% metricNames) {
        plotfscore <- ggplot(data = results, aes(reorder(config, fscore, FUN = mean), fscore)) +
          ggtitle(paste("F-measure ordered by the mean value for", dataset, "data")) +
          geom_boxplot() +
          stat_summary(fun.y = mean, geom = "point", size = 3, shape = 9) +
          scale_y_continuous(limits = c(0, 1.0)) +
          coord_flip() +
          theme(axis.text = element_text(size = 8), axis.title = element_text(size = 8), title = element_text(size = 8), axis.text.x = element_text(angle = 90, hjust = 1))
        ggsave(filename = paste(PLOT_PATH, "FMEASURE_", dataset, ".pdf", sep = ""), plot = plotfscore)
      }

      if ("gscore" %in% metricNames) {
        plotgscore <- ggplot(data = results, aes(reorder(config, gscore, FUN = mean), gscore)) +
          ggtitle(paste("G-measure ordered by the mean value for", dataset, "data")) +
          geom_boxplot() +
          stat_summary(fun.y = mean, geom = "point", size = 3, shape = 9) +
          scale_y_continuous(limits = c(0, 1.0)) +
          coord_flip() +
          theme(axis.text = element_text(size = 8), axis.title = element_text(size = 8), title = element_text(size = 8), axis.text.x = element_text(angle = 90, hjust = 1))
        ggsave(filename = paste(PLOT_PATH, "GMEASURE_", dataset, ".pdf", sep = ""), plot = plotgscore)
      }

      if ("mcc" %in% metricNames) {
        plotmcc <- ggplot(data = results, aes(reorder(config, mcc, FUN = mean), mcc)) +
          ggtitle(paste("MCC ordered by the mean value for", dataset, "data")) +
          geom_boxplot() +
          stat_summary(fun.y = mean, geom = "point", size = 3, shape = 9) +
          scale_y_continuous(limits = c(0, 1.0)) +
          coord_flip() +
          theme(axis.text = element_text(size = 8), axis.title = element_text(size = 8), title = element_text(size = 8), axis.text.x = element_text(angle = 90, hjust = 1))
        ggsave(filename = paste(PLOT_PATH, "MCC_", dataset, ".pdf", sep = ""), plot = plotmcc)
      }
    }
  }
  dbDisconnect(mydb)
  
print("RQ1")
browser()
# configurations最终获得属性
#  [1] config                   AUC_JURECZKO             meanAUC_JURECZKO      

#  [4] FMEAS_JURECZKO           meanFMEAS_JURECZKO       GMEAS_JURECZKO        

#  [7] meanGMEAS_JURECZKO       MCC_JURECZKO             meanMCC_JURECZKO      

# [10] AUC_MDP                  meanAUC_MDP              FMEAS_MDP

# [13] meanFMEAS_MDP            GMEAS_MDP                meanGMEAS_MDP

# [16] MCC_MDP                  meanMCC_MDP              AUC_AEEEM_LDHHWCHU    

# [19] meanAUC_AEEEM_LDHHWCHU   FMEAS_AEEEM_LDHHWCHU     meanFMEAS_AEEEM_LDHHWCHU
# [22] GMEAS_AEEEM_LDHHWCHU     meanGMEAS_AEEEM_LDHHWCHU MCC_AEEEM_LDHHWCHU    

# [25] meanMCC_AEEEM_LDHHWCHU   AUC_RELINK               meanAUC_RELINK        

# [28] FMEAS_RELINK             meanFMEAS_RELINK         GMEAS_RELINK

# [31] meanGMEAS_RELINK         MCC_RELINK               meanMCC_RELINK        

# [34] AUC_NETGENE              meanAUC_NETGENE          FMEAS_NETGENE

# [37] meanFMEAS_NETGENE        GMEAS_NETGENE            meanGMEAS_NETGENE     

# [40] MCC_NETGENE              meanMCC_NETGENE
  skresults <- configurations
  #返回结果configuration
  rownames(skresults) <- skresults$config
  # 设置skresults矩阵行名为config  skresults["ALL-DT","meanMCC_NETGENE"]可以这样访问元素 根据数据集和算法评价指标得到序值
  skresults$config <- NULL
  print("RQ1")
  #startsWith(colnames(skresults), "mean") 判断列名是否以mean开头，是则返回列名，在前面加 ！ 则不是返回列名
  #rowMeans求该行行值的平均值,na.rm=true则忽略NA
  skresults$MEANRANK <- rowMeans(skresults[!startsWith(colnames(skresults), "mean")], na.rm = TRUE)
  skresults$config <- as.factor(rownames(skresults))
  #行名作为config列值
  for (i in 1:nrow(skresults)) {
    #1 ALL-DT
    skresults$approach[i] <- strsplit(rownames(skresults)[[i]], "-")[[1]][1]
    #ALL
    splitLength <- nchar(strsplit(rownames(skresults)[[i]], "-")[[1]][1])
    # 3
    skresults$classifier[i] <- substring(rownames(skresults)[[i]], splitLength + 2)
    #DT
  }

#                       meanMCC_NETGENE    MEANRANK                config       approach          classifier
# ALL-DT                    0.166473576 0.561061507                ALL-DT           ALL             DT
# ALL-LR                    0.084986836 0.572949975                ALL-LR           ALL             LR
# ALL-NB                    0.162096635 0.787150363                ALL-NB           ALL             NB
# ALL-NET                  -0.003251102 0.497842733               ALL-NET           ALL             NET
# ALL-RF                    0.275845294 0.619355276                ALL-RF
# ALL-SVM                  -0.004323501 0.053342751               ALL-SVM
# Amasaki15-DT              0.127708758 0.557246609          Amasaki15-DT         Amasaki15
# Amasaki15-LR              0.112841160 0.604483532          Amasaki15-LR
# Amasaki15-NB              0.187563671 0.860456351          Amasaki15-NB
# Amasaki15-NET             0.230733589 0.587698149         Amasaki15-NET
# Amasaki15-RF              0.286106481 0.662508528          Amasaki15-RF
# Amasaki15-SVM             0.132425771 0.123019831         Amasaki15-SVM
# CamargoCruz09-DT          0.153541748 0.528304446      CamargoCruz09-DT
# CamargoCruz09-LR         -0.026855038 0.545987030      CamargoCruz09-LR
# CamargoCruz09-NB          0.257268693 0.917362545      CamargoCruz09-NB
  return(skresults)
}

plotBestResults <- function(results, rq, metricsString) {
  best <- results
  approaches <- unique(best$approach)
  for (j in 1:length(approaches)) {
    maxval <- max(best[best$approach == approaches[j], ]$MEANRANK)
    for (i in nrow(best):1) {
      if (best$approach[i] == approaches[j] && best$MEANRANK[i] < maxval) {
        best <- best[-i, ]
      }
    }
  }

  best$MEANRANK <- round(best$MEANRANK, digits = 3)
  textsize <- 12
  plotBest <- ggplot(data = best, aes(reorder(config, MEANRANK, FUN = mean), MEANRANK)) +
    ggtitle(paste("Ranking of approaches using", metricsString)) +
    ylab("Mean rankscore") +
    xlab("Approach") +
    geom_bar(stat = "identity") +
    geom_label(aes(label = MEANRANK), hjust = 0, nudge_y = 0.002) +
    scale_y_continuous(limits = c(0, 1.02), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
    coord_flip() +
    theme(axis.text = element_text(size = textsize), axis.title = element_text(size = textsize), title = element_text(size = textsize))
  print(plotBest)
  ggsave(filename = paste(PLOT_PATH, "BEST_", rq, ".pdf", sep = ""), plot = plotBest)
  return(best)
}

writeResultsTableRQ1 <- function(rq1best, rq4results, rq5results) {
  resultsTableFrame <- round(rq1best[, 1:41], digits = 2)

  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanAUC_JURECZKO, " (", resultsTableFrame$AUC_JURECZKO, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "auc"
  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanFMEAS_JURECZKO, " (", resultsTableFrame$FMEAS_JURECZKO, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "F-measure"
  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanGMEAS_JURECZKO, " (", resultsTableFrame$GMEAS_JURECZKO, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "G-measure"
  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanMCC_JURECZKO, " (", resultsTableFrame$MCC_JURECZKO, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "MCC"
  colnumber <- ncol(resultsTableFrame) + 1

  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(round(rq4results[rq4results$config %in% rownames(resultsTableFrame), ]$meanAUC_FILTERJURECZKO - rq1best$meanAUC_JURECZKO, digits = 2), " / ", round(rq5results[rq5results$config %in% rownames(resultsTableFrame), ]$meanAUC_SELECTEDJURECZKO - rq1best$meanAUC_JURECZKO, digits = 2), sep = "")
  colnames(resultsTableFrame)[colnumber] <- "auc"
  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(round(rq4results[rq4results$config %in% rownames(resultsTableFrame), ]$meanFMEAS_FILTERJURECZKO - rq1best$meanFMEAS_JURECZKO, digits = 2), " / ", round(rq5results[rq5results$config %in% rownames(resultsTableFrame), ]$meanFMEAS_SELECTEDJURECZKO - rq1best$meanFMEAS_JURECZKO, digits = 2), sep = "")
  colnames(resultsTableFrame)[colnumber] <- "F-measure"
  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(round(rq4results[rq4results$config %in% rownames(resultsTableFrame), ]$meanGMEAS_FILTERJURECZKO - rq1best$meanGMEAS_JURECZKO, digits = 2), " / ", round(rq5results[rq5results$config %in% rownames(resultsTableFrame), ]$meanGMEAS_SELECTEDJURECZKO - rq1best$meanGMEAS_JURECZKO, digits = 2), sep = "")
  colnames(resultsTableFrame)[colnumber] <- "G-measure"
  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(round(rq4results[rq4results$config %in% rownames(resultsTableFrame), ]$meanMCC_FILTERJURECZKO - rq1best$meanMCC_JURECZKO, digits = 2), " / ", round(rq5results[rq5results$config %in% rownames(resultsTableFrame), ]$meanMCC_SELECTEDJURECZKO - rq1best$meanMCC_JURECZKO, digits = 2), sep = "")
  colnames(resultsTableFrame)[colnumber] <- "MCC"
  colnumber <- ncol(resultsTableFrame) + 1

  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanAUC_MDP, " (", resultsTableFrame$AUC_MDP, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "auc"
  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanFMEAS_MDP, " (", resultsTableFrame$FMEAS_MDP, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "F-measure"
  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanGMEAS_MDP, " (", resultsTableFrame$GMEAS_MDP, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "G-measure"
  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanMCC_MDP, " (", resultsTableFrame$MCC_MDP, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "MCC"
  colnumber <- ncol(resultsTableFrame) + 1

  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanAUC_AEEEM_LDHHWCHU, " (", resultsTableFrame$AUC_AEEEM_LDHHWCHU, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "auc"
  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanFMEAS_AEEEM_LDHHWCHU, " (", resultsTableFrame$FMEAS_AEEEM_LDHHWCHU, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "F-measure"
  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanGMEAS_AEEEM_LDHHWCHU, " (", resultsTableFrame$GMEAS_AEEEM_LDHHWCHU, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "G-measure"
  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanMCC_AEEEM_LDHHWCHU, " (", resultsTableFrame$MCC_AEEEM_LDHHWCHU, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "MCC"
  colnumber <- ncol(resultsTableFrame) + 1

  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanAUC_NETGENE, " (", resultsTableFrame$AUC_NETGENE, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "auc"
  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanFMEAS_NETGENE, " (", resultsTableFrame$FMEAS_NETGENE, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "F-measure"
  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanGMEAS_NETGENE, " (", resultsTableFrame$GMEAS_NETGENE, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "G-measure"
  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanMCC_NETGENE, " (", resultsTableFrame$MCC_NETGENE, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "MCC"
  colnumber <- ncol(resultsTableFrame) + 1

  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanAUC_RELINK, " (", resultsTableFrame$AUC_RELINK, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "auc"
  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanFMEAS_RELINK, " (", resultsTableFrame$FMEAS_RELINK, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "F-measure"
  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanGMEAS_RELINK, " (", resultsTableFrame$GMEAS_RELINK, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "G-measure"
  colnumber <- ncol(resultsTableFrame) + 1
  resultsTableFrame[, colnumber] <- paste(resultsTableFrame$meanMCC_RELINK, " (", resultsTableFrame$MCC_RELINK, ")", sep = "")
  colnames(resultsTableFrame)[colnumber] <- "MCC"
  colnumber <- ncol(resultsTableFrame) + 1

  tableCaption <- "Mean results over all products with rankscores in brackets. Bold-faced values are top-ranking for the metric on the data set. For FILTERJURECZKO and SELECTEDJURECKO, we show the difference in the mean values to JURECZKO."
  tablePart1 <- print.xtable(xtable(resultsTableFrame[, 42:53]))
  tablePart2 <- print.xtable(xtable(resultsTableFrame[, 54:65]))

  tablePart1 <- sub("\\centering", "", tablePart1, fixed = TRUE)
  tablePart1 <- sub("\\begin{table}[ht]", "\\begin{table*}\n\\scriptsize\\centering\\begin{sideways}", tablePart1, fixed = TRUE)
  tablePart1 <- sub("rllllrrrrllll", "|r|llll|llll|llll|", tablePart1, fixed = TRUE)
  tablePart1 <- sub("\\hline", "\\hline\n & \\multicolumn{4}{c|}{JURECZKO} & \\multicolumn{4}{c|}{FILTERJURECZKO / SELECTEDJURECZKO} & \\multicolumn{4}{c|}{MDP} \\\\\n\\hline", tablePart1, fixed = TRUE)
  tablePart1 <- sub("\\end{tabular}\n\\end{table}\n", "", tablePart1, fixed = TRUE)
  tablePart2 <- sub("\\begin{table}[ht]\n\\centering\n\\begin{tabular}{rllllllllllll}\n  \\hline\n", "\\hline\n & \\multicolumn{4}{c|}{AEEEM} & \\multicolumn{4}{c|}{NETGENE} & \\multicolumn{4}{c|}{RELINK} \\\\\n\\hline", tablePart2, fixed = TRUE)
  tablePart2 <- sub(".*\\\\hline\\\n & \\\\\\multicolumn", "\\\\hline\n & \\\\multicolumn", tablePart2, fixed = FALSE)
  tablePart2 <- sub("\\end{table}", paste("\\end{sideways}\n\\caption{", tableCaption, "}\n\\label{tbl:results}\n\\end{table*}", sep = ""), tablePart2, fixed = TRUE)
  tableStr <- paste(tablePart1, tablePart2, sep = "")
  tableStr <- gsub("NaN (NA)", "-", tableStr, fixed = TRUE)
  tableStr <- gsub("NaN / NaN", "-", tableStr, fixed = TRUE)
  tableStr <- gsub("&  &", "& - &", tableStr, fixed = TRUE)
  tableStr <- gsub("0 ", "0.00 ", tableStr, fixed = TRUE)
  tableStr <- gsub("auc.1", "\\emph{AUC}", tableStr, fixed = TRUE)
  tableStr <- gsub("auc.2", "\\emph{AUC}", tableStr, fixed = TRUE)
  tableStr <- gsub("auc.3", "\\emph{AUC}", tableStr, fixed = TRUE)
  tableStr <- gsub("auc.4", "\\emph{AUC}", tableStr, fixed = TRUE)
  tableStr <- gsub("auc.5", "\\emph{AUC}", tableStr, fixed = TRUE)
  tableStr <- gsub("auc ", "\\emph{AUC} ", tableStr, fixed = TRUE)
  tableStr <- gsub("F-measure.1", "\\emph{F-measure}", tableStr, fixed = TRUE)
  tableStr <- gsub("F-measure.2", "\\emph{F-measure}", tableStr, fixed = TRUE)
  tableStr <- gsub("F-measure.3", "\\emph{F-measure}", tableStr, fixed = TRUE)
  tableStr <- gsub("F-measure.4", "\\emph{F-measure}", tableStr, fixed = TRUE)
  tableStr <- gsub("F-measure.5", "\\emph{F-measure}", tableStr, fixed = TRUE)
  tableStr <- gsub("F-measure ", "\\emph{F-measure} ", tableStr, fixed = TRUE)
  tableStr <- gsub("G-measure.1", "\\emph{G-measure}", tableStr, fixed = TRUE)
  tableStr <- gsub("G-measure.2", "\\emph{G-measure}", tableStr, fixed = TRUE)
  tableStr <- gsub("G-measure.3", "\\emph{G-measure}", tableStr, fixed = TRUE)
  tableStr <- gsub("G-measure.4", "\\emph{G-measure}", tableStr, fixed = TRUE)
  tableStr <- gsub("G-measure.5", "\\emph{G-measure}", tableStr, fixed = TRUE)
  tableStr <- gsub("G-measure ", "\\emph{G-measure} ", tableStr, fixed = TRUE)
  tableStr <- gsub("MCC.1", "\\emph{MCC}", tableStr, fixed = TRUE)
  tableStr <- gsub("MCC.2", "\\emph{MCC}", tableStr, fixed = TRUE)
  tableStr <- gsub("MCC.3", "\\emph{MCC}", tableStr, fixed = TRUE)
  tableStr <- gsub("MCC.4", "\\emph{MCC}", tableStr, fixed = TRUE)
  tableStr <- gsub("MCC.5", "\\emph{MCC}", tableStr, fixed = TRUE)
  tableStr <- gsub("MCC ", "\\emph{MCC} ", tableStr, fixed = TRUE)
  tableStr <- gsub("([0-9]\\.[0-9][0-9]? \\(1\\))", "\\\\textbf\\{\\1\\}", tableStr, perl = TRUE)
  write(tableStr, file = paste(TABLES_PATH, "resultsTable.tex", sep = ""))
}

compareDatasets <- function(set1, set2, metric) {
  mydb <- dbConnect(MySQL(), user = MYSQL_USER, password = MYSQL_PASSWORT, host = MYSQL_HOST, port = MYSQL_PORT, dbname = MYSQL_DBNAME)

  sqlStatement <- paste("SELECT q1.config, q1.mean1, q2.mean2 FROM ",
    "(SELECT concat(substring(configurationName, ", nchar(set1) + 2, "), '-', classifier) as config, avg(", metric,
    ") as mean1 FROM resultsView WHERE configurationName LIKE '", set1, "-%' GROUP BY configurationName, classifier) q1, ",
    "(SELECT concat(substring(configurationName, ", nchar(set2) + 2, "), '-', classifier) as config, avg(", metric,
    ") as mean2 FROM resultsView WHERE configurationName LIKE '", set2, "-%' GROUP BY configurationName, classifier) q2 ",
    "WHERE q1.config=q2.config",
    sep = ""
  )
  rs <- dbSendQuery(mydb, sqlStatement)
  results <- fetch(rs, n = -1)

  cat(paste("metric:", metric, "\n"))
  cat(paste("mean", set1, ":", mean(results$mean1), "\n"))
  cat(paste("mean", set2, ":", mean(results$mean2)), "\n")
  cat(paste("mean(abs(mean1-mean2)):", mean(abs(results$mean1 - results$mean2)), "\n"))
  cat(paste("sd(abs(mean1-mean2)):", sd(abs(results$mean1 - results$mean2)), "\n"))
  print(wilcox.test(results$mean1, results$mean2))
  dbDisconnect(mydb)
}

evalRQ2 <- function() {
  mydb <- dbConnect(MySQL(), user = MYSQL_USER, password = MYSQL_PASSWORT, host = MYSQL_HOST, port = MYSQL_PORT, dbname = MYSQL_DBNAME)

  sqlStatement <- "SELECT count1, count2, count1/count2 FROM (SELECT count(*) as count1 FROM results WHERE configurationName NOT LIKE 'F%' AND configurationName NOT LIKE 'S%' AND recall>=0.75 AND results.precision>=0.75 AND error<=0.25) q1, (SELECT count(*) as count2 FROM results WHERE configurationName NOT LIKE 'F%' AND configurationName NOT LIKE 'S%') q2;"
  rs <- dbSendQuery(mydb, sqlStatement)
  results <- fetch(rs, n = -1)
  cat(paste("results with baselines for Zimmermann\n"))
  cat(paste("number of single results that fulfill the criterion:       ", results[1, 1], "\n"))
  cat(paste("number of single results that do not fulfill the criterion:", results[1, 2], "\n"))
  cat(paste("rate of fulfilling the criterion:                          ", results[1, 3], "\n"))
  cat("\n")

  sqlStatement <- "SELECT count1, count2, count1/count2 FROM (SELECT count(*) as count1 FROM results WHERE configurationName NOT LIKE 'F%' AND configurationName NOT LIKE 'S%' and configurationName NOT LIKE '%CV' AND classifier!='FIX' AND classifier!='RANDOM' AND recall>=0.75 AND results.precision>=0.75 AND error<=0.25) q1, (SELECT count(*) as count2 FROM results WHERE configurationName NOT LIKE 'F%' AND configurationName NOT LIKE 'S%' and configurationName NOT LIKE '%CV' AND classifier!='FIX' AND classifier!='RANDOM') q2;"
  rs <- dbSendQuery(mydb, sqlStatement)
  results <- fetch(rs, n = -1)
  cat(paste("results without baselines for Zimmermann\n"))
  cat(paste("number of single results that fulfill the criterion:       ", results[1, 1], "\n"))
  cat(paste("number of single results that do not fulfill the criterion:", results[1, 2], "\n"))
  cat(paste("rate of fulfilling the criterion:                          ", results[1, 3], "\n"))
  cat("\n")

  sqlStatement <- "SELECT count1, count2, count1/count2 FROM (SELECT count(*) as count1 FROM results WHERE configurationName NOT LIKE 'F%' AND configurationName NOT LIKE 'S%' AND recall>=0.70 AND results.precision>=0.5) q1, (SELECT count(*) as count2 FROM results WHERE configurationName NOT LIKE 'F%' AND configurationName NOT LIKE 'S%') q2;"
  rs <- dbSendQuery(mydb, sqlStatement)
  results <- fetch(rs, n = -1)
  cat(paste("results with baselines for He\n"))
  cat(paste("number of single results that fulfill the criterion:       ", results[1, 1], "\n"))
  cat(paste("number of single results that do not fulfill the criterion:", results[1, 2], "\n"))
  cat(paste("rate of fulfilling the criterion:                          ", results[1, 3], "\n"))
  cat("\n")

  sqlStatement <- "SELECT count1, count2, count1/count2 FROM (SELECT count(*) as count1 FROM results WHERE configurationName NOT LIKE 'F%' AND configurationName NOT LIKE 'S%' and configurationName NOT LIKE '%CV' AND classifier!='FIX' AND classifier!='RANDOM' AND recall>=0.7 AND results.precision>=0.5) q1, (SELECT count(*) as count2 FROM results WHERE configurationName NOT LIKE 'F%' AND configurationName NOT LIKE 'S%' and configurationName NOT LIKE '%CV' AND classifier!='FIX' AND classifier!='RANDOM') q2;"
  rs <- dbSendQuery(mydb, sqlStatement)
  results <- fetch(rs, n = -1)
  cat(paste("results without baselines for He\n"))
  cat(paste("number of single results that fulfill the criterion:       ", results[1, 1], "\n"))
  cat(paste("number of single results that do not fulfill the criterion:", results[1, 2], "\n"))
  cat(paste("rate of fulfilling the criterion:                          ", results[1, 3], "\n"))
  cat("\n")

  sqlStatement <- "SELECT res1.configurationName, res1.classifier, cnt1 as cnt, cnt1/cnt2 as rate FROM (SELECT configurationName, classifier, count(*) as cnt1 FROM results WHERE configurationName  NOT LIKE 'F%' AND recall>=0.75 AND results.precision>=0.75 AND error<=0.25 GROUP BY configurationName, classifier) as res1, (SELECT configurationName, classifier, count(*) as cnt2 FROM results WHERE configurationName  NOT LIKE 'F%' GROUP BY configurationName, classifier) as res2 WHERE res1.configurationName=res2.configurationName AND res1.classifier=res2.classifier ORDER BY rate DESC;"
  rs <- dbSendQuery(mydb, sqlStatement)
  results <- fetch(rs, n = -1)
  cat("distinct products with at least 100 classes that fulfill the criterion:\n")
  cat("configuration\t\t\tclassifier\t\tcount\trate\n")
  for (i in 1:nrow(results)) {
    cat(paste(str_pad(results[i, 1], width = 25, side = "right"), str_pad(results[i, 2], width = 20, side = "right"), results[i, 3], results[i, 4], "\n", sep = "\t"))
  }
  cat("\n")

  sqlStatement <- "SELECT distinct productName FROM results WHERE configurationName  NOT LIKE 'F%' AND configurationName NOT LIKE 'S%' AND recall>=0.75 AND results.precision>=0.75 AND error<=0.25 AND testsize>=100 GROUP BY configurationName, classifier"
  rs <- dbSendQuery(mydb, sqlStatement)
  results <- fetch(rs, n = -1)
  cat("distinct products with at least 100 classes that fulfill the criterion:\n")
  cat(paste(results[, 1], collapse = "\n"))
  cat("\n\n")

  sqlStatement <- "SELECT distinct productName FROM results WHERE configurationName NOT LIKE 'F%' AND configurationName NOT LIKE 'S%' AND recall>=0.75 AND results.precision>=0.75 AND error<=0.25 AND testsize<100 GROUP BY configurationName, classifier"
  rs <- dbSendQuery(mydb, sqlStatement)
  results <- fetch(rs, n = -1)
  cat("distinct products with less than 100 classes that fulfill the criterion:\n")
  cat(paste(results[, 1], collapse = "\n"))
  cat("\n\n")

  sqlStatement <- "SELECT productName as Product, testsize, sum(cnt1) as cnt, prec FROM (SELECT productName, testsize, if(count(*)=1, 1, count(*)/10) as cnt1, 1.0 as recall, (tp+fn)/testsize as 'prec' FROM results WHERE configurationName NOT LIKE 'F%' AND configurationName NOT LIKE 'S%' AND configurationName NOT LIKE '%CV' AND classifier!='FIX' AND classifier!='RANDOM' AND recall>=0.75 AND results.precision>=0.75 AND error<=0.25 GROUP BY configurationName, classifier, productName) as res  GROUP BY productName, testsize UNION SELECT DISTINCT productName as Product, testsize, 0 as cnt, (tp+fn)/testsize as prec FROM results WHERE classifier='FIX' and (tp+fn)/testsize>=0.75 and productName!='pbeans1.csv' ORDER BY Product"
  rs <- dbSendQuery(mydb, sqlStatement)
  results <- fetch(rs, n = -1)
  cat("distinct products with less than 100 classes that fulfill the criterion:\n")
  cat(paste(results[, 1], collapse = "\n"))
  cat("\n\n")

  rownames(results) <- results$Product
  results$Product <- NULL
  results$Data <- "JURECZKO"
  results <- results[, c(4, 1, 2, 3)]

  captionStr <- "Products where any \\ac{CPDP} approach fulfills the criterion by Zimmermann\\etal~\\cite{Zimmermann2009} and the \\emph{precision} of the trivial prediction FIX."
  tableStr <- print.xtable(xtable(results, caption = captionStr))
  # tableStr = sub("\\begin{table}", "\\begin{table*}", tableStr, fixed=TRUE)
  tableStr <- sub("rlrrr", "|r|l|l|l|l|", tableStr, fixed = TRUE)
  tableStr <- sub("\\hline\n", "\\hline\n \\textbf{Product}", tableStr, fixed = TRUE)
  tableStr <- sub("Data", "\\textbf{Data Set}", tableStr, fixed = TRUE)
  tableStr <- sub("testsize", "\\textbf{\\#Inst.}", tableStr, fixed = TRUE)
  tableStr <- sub("cnt", "\\textbf{\\#Appr.}", tableStr, fixed = TRUE)
  tableStr <- sub("prec \\\\ \n", "\\emph{precision} \\\\ &&&& FIX \\\\ \\hline\n", tableStr, fixed = TRUE)
  tableStr <- gsub(".csv", "", tableStr, fixed = TRUE)
  tableStr <- sub("openintents & JURECZKO", "openintents & RELINK", tableStr, fixed = TRUE)
  tableStr <- sub("\\end{table}", "\\label{tbl:productsSuccess}\n\\end{table}", tableStr, fixed = TRUE)
  write(tableStr, paste(TABLES_PATH, "productsSuccess.tex", sep = ""))

  dbDisconnect(mydb)
}

getNemenyiCD <- function(pval, nConfigs, nData) {
  return(qtukey(1 - pval, nConfigs, Inf) / sqrt((nConfigs * (nConfigs + 1)) / (12 * nData)))
}

plotCDNemenyiFriedman <- function(meanRanks, nData, pval = 0.05, title = "") {
  nConfigs <- nrow(meanRanks)
  cdNemenyi <- getNemenyiCD(pval, nConfigs, nData)

  roundedMaxMeanRank <- ceiling(max(meanRanks$meanRank))
  roundedMinMeanRank <- floor(min(meanRanks$meanRank))
  maxMeanRank <- max(meanRanks$meanRank)
  minMeanRank <- min(meanRanks$meanRank)
  halfEntries <- ceiling(nrow(meanRanks) / 2)

  red <- 0.8
  green <- 0
  stepsize <- 1.6 / max(meanRanks$rank)
  colors <- list()
  for (j in 1:max(meanRanks$rank)) {
    colors[j] <- rgb(green, red, 0)
    if (green + stepsize > 0.8) {
      green <- 0.8
      red <- red - stepsize
      if (red < 0) {
        red <- 0
      }
    } else {
      green <- green + stepsize
      if (green > 0.8) {
        green <- 0.8
      }
    }
  }
  meanRanks <- meanRanks[order(meanRanks$meanRank, decreasing = FALSE), ]
  g <- ggplot(data = meanRanks)
  # create lines for configurations
  for (j in 1:nrow(meanRanks)) {
    xval <- meanRanks$meanRank[j]
    if (j <= halfEntries) {
      yend <- j
      xlinestart <- roundedMinMeanRank
      xtext <- roundedMinMeanRank - 0.2 / roundedMaxMeanRank
      hjust <- "right"
    } else {
      yend <- j - 2 * (j - halfEntries)
      xlinestart <- roundedMaxMeanRank
      xtext <- roundedMaxMeanRank + 0.2 / roundedMaxMeanRank
      hjust <- "left"
    }
    if (meanRanks$meanRank[j] <= minMeanRank + cdNemenyi) {
      color <- "#00cc00"
    }
    else if (meanRanks$meanRank[j] >= maxMeanRank - cdNemenyi) {
      color <- "#cc0000"
    }
    else {
      color <- "#0000cc"
    }
    color <- colors[[meanRanks$rank[j]]]
    g <- g + geom_segment(x = xval, y = 0, xend = xval, yend = -yend, color = color)
    g <- g + geom_segment(x = xlinestart, y = -yend, xend = xval, yend = -yend, color = color)
    g <- g + geom_text(label = meanRanks$config[j], x = xtext, y = -yend, hjust = hjust, color = color)
  }
  # create axis
  if (roundedMaxMeanRank > 100) {
    breaks <- 1:(roundedMaxMeanRank / 5) * 5
  } else if (roundedMaxMeanRank > 80) {
    breaks <- 1:(roundedMaxMeanRank / 4) * 4
  } else if (roundedMaxMeanRank > 60) {
    breaks <- 1:(roundedMaxMeanRank / 3) * 3
  } else if (roundedMaxMeanRank > 40) {
    breaks <- 1:(roundedMaxMeanRank / 2) * 2
  } else {
    breaks <- 1:roundedMaxMeanRank
  }
  breaks <<- breaks
  g <- g + geom_segment(x = 0, y = 0, xend = roundedMaxMeanRank, yend = 0)
  g <- g + geom_text(label = "Mean Rank", x = roundedMinMeanRank - 0.2 / roundedMaxMeanRank, y = 0.01 * halfEntries, hjust = "right", vjust = "bottom")
  for (j in roundedMinMeanRank:roundedMaxMeanRank) {
    if (j %in% breaks) {
      g <- g + geom_segment(x = j, y = 0, xend = j, yend = 0.01 * halfEntries)
      g <- g + geom_text(label = j, x = j, y = 0.015 * halfEntries, vjust = "bottom")
    }
  }
  # add critical distance
  critDistY <- 3
  g <- g + geom_segment(x = minMeanRank, y = critDistY, xend = minMeanRank + cdNemenyi, yend = critDistY)
  g <- g + geom_segment(x = minMeanRank + cdNemenyi, y = critDistY - 0.005 * halfEntries, xend = minMeanRank + cdNemenyi, yend = critDistY + 0.005 * halfEntries)
  g <- g + geom_segment(x = minMeanRank, y = critDistY - 0.005 * halfEntries, xend = minMeanRank, yend = critDistY + 0.005 * halfEntries)
  g <- g + geom_text(label = paste("Critical Distance =", round(cdNemenyi, digits = 3)), x = minMeanRank - 0.2 / roundedMaxMeanRank, y = critDistY, hjust = "right")
  # set scales
  g <- g + scale_y_continuous(limits = c(-halfEntries, 1), breaks = NULL, labels = NULL)
  g <- g + scale_x_continuous(limits = c(roundedMinMeanRank - 1, roundedMaxMeanRank + 1), breaks = breaks, labels = NULL)
  g <- g + theme(axis.ticks.x = element_blank())
  # set title
  g <- g + ggtitle(title)
  g <- g + coord_cartesian(xlim = c(roundedMinMeanRank - 0.2 * roundedMaxMeanRank, roundedMaxMeanRank + 0.2 * roundedMaxMeanRank))
  return(g)
}

createMeanRankMat <- function(results, column) {
  nemenyi.groups <- factor(as.character(results$config))
  nemenyi.blocks <- factor(results$index)
  nemenyi.y <- results[[column]]
  nemenyi.n <- length(levels(nemenyi.blocks))
  nemenyi.k <- length(levels(nemenyi.groups))
  nemenyi.y <- nemenyi.y[order(nemenyi.groups, nemenyi.blocks)]
  nemenyi.mat <- matrix(nemenyi.y, nrow = nemenyi.n, ncol = nemenyi.k, byrow = FALSE)
  for (nemenyi.i in 1:length(nemenyi.mat[, 1])) {
    nemenyi.mat[nemenyi.i, ] <- rank(nemenyi.mat[nemenyi.i, ])
  }
  nemenyi.mnsum <- data.frame(meanRank = colMeans(nemenyi.mat))
  nemenyi.mnsum$config <- levels(nemenyi.groups)
  # create ranks
  # break if difference > cd
  nemenyi.cd <- getNemenyiCD(0.05, length(unique(results$config)), max(results$index))
  nemenyi.mnsum <- nemenyi.mnsum[order(-nemenyi.mnsum$meanRank), ]
  currentRank <- 1
  nemenyi.mnsum$rank[1] <- 1
  for (i in 2:nrow(nemenyi.mnsum)) {
    if (nemenyi.mnsum$meanRank[i - 1] - nemenyi.mnsum$meanRank[i] > nemenyi.cd) {
      currentRank <- currentRank + 1
    }
    nemenyi.mnsum$rank[i] <- currentRank
  }
  nemenyi.mnsum$normRank <- 1 - (nemenyi.mnsum$rank - 1) / (max(nemenyi.mnsum$rank) - 1)
  return(nemenyi.mnsum)
}

#####################
# Result evaluation #
#####################

# Performance metrics used
# Script can only handle auc, fscore, gscore, and mcc
# To use other metrics available in the MySQL database,
# the functions above must be modified, because we do
# some string matching with the metric names.
metricNamesRQ1 <- c("auc", "fscore", "gscore", "mcc")

# Datasets that are used for different research questions.
datasetsRQ1 <- c("JURECZKO", "MDP", "AEEEM_LDHHWCHU", "RELINK", "NETGENE")
datasetsRQ3 <- c("FILTERJURECZKO")
datasetsRQ4 <- c("SELECTEDJURECZKO")
# debug(evaluateCPDPBenchmark)
rq1results <- evaluateCPDPBenchmark(metricNamesRQ1, datasetsRQ1)
# undebug(evaluateCPDPBenchmark)
#                       meanMCC_NETGENE    MEANRANK                config
# ALL-DT                    0.166473576 0.561061507                ALL-DT
# ALL-LR                    0.084986836 0.572949975                ALL-LR
# ALL-NB                    0.162096635 0.787150363                ALL-NB
# ALL-NET                  -0.003251102 0.497842733               ALL-NET
# ALL-RF                    0.275845294 0.619355276                ALL-RF
# ALL-SVM                  -0.004323501 0.053342751               ALL-SVM
# Amasaki15-DT              0.127708758 0.557246609          Amasaki15-DT
# Amasaki15-LR              0.112841160 0.604483532          Amasaki15-LR
# Amasaki15-NB              0.187563671 0.860456351          Amasaki15-NB
# Amasaki15-NET             0.230733589 0.587698149         Amasaki15-NET
# Amasaki15-RF              0.286106481 0.662508528          Amasaki15-RF
# Amasaki15-SVM             0.132425771 0.123019831         Amasaki15-SVM
# CamargoCruz09-DT          0.153541748 0.528304446      CamargoCruz09-DT
# CamargoCruz09-LR         -0.026855038 0.545987030      CamargoCruz09-LR
# CamargoCruz09-NB          0.257268693 0.917362545      CamargoCruz09-NB
# CamargoCruz09-NET         0.201932481 0.587135969     CamargoCruz09-NET
# CamargoCruz09-RF          0.278157721 0.486796297      CamargoCruz09-RF
# CamargoCruz09-SVM         0.220962218 0.184957885     CamargoCruz09-SVM
# Canfora13-MODEP           0.000000000 0.170125294       Canfora13-MODEP
# CV-DT                     0.450498247 0.791657536                 CV-DT
# CV-LR                     0.396841766 0.823654374                 CV-LR
# CV-NB                     0.341568163 0.870623962                 CV-NB
# CV-NET                    0.272865490 0.694790138                CV-NET
# CV-RF                     0.513754864 0.903475226                 CV-RF
# CV-SVM                    0.356822745 0.228610645                CV-SVM
# Herbold13-DT              0.158405275 0.489077401          Herbold13-DT
# Herbold13-LR              0.050328534 0.654502903          Herbold13-LR
# Herbold13-NB              0.143461633 0.762321140          Herbold13-NB
# Herbold13-NET             0.221273534 0.802084481         Herbold13-NET
# Herbold13-RF              0.335727679 0.621527285          Herbold13-RF
# Herbold13-SVM             0.297224137 0.668257473         Herbold13-SVM
# Kawata15-DT               0.198769321 0.496253837           Kawata15-DT
# Kawata15-LR               0.089330969 0.564688423           Kawata15-LR
# Kawata15-NB               0.143336917 0.736781083           Kawata15-NB
# Kawata15-NET              0.033619151 0.514187900          Kawata15-NET
# Kawata15-RF               0.270484293 0.520017168           Kawata15-RF
# Kawata15-SVM             -0.004323501 0.053910932          Kawata15-SVM
# Koshgoftaar08-DT          0.188974821 0.590964630      Koshgoftaar08-DT
# Koshgoftaar08-LR          0.023375888 0.454967017      Koshgoftaar08-LR
# Koshgoftaar08-NB          0.239210069 0.742397272      Koshgoftaar08-NB
# Koshgoftaar08-NET         0.055855543 0.492597901     Koshgoftaar08-NET
# Koshgoftaar08-RF          0.255133813 0.422080174      Koshgoftaar08-RF
# Koshgoftaar08-SVM         0.000000000 0.075137418     Koshgoftaar08-SVM
# Liu10-GP                  0.064929484 0.521111832              Liu10-GP
# Ma12-DT                   0.189790356 0.582173421               Ma12-DT
# Ma12-LR                   0.081137170 0.557549124               Ma12-LR
# Ma12-NB                   0.177564725 0.820496865               Ma12-NB
# Ma12-NET                 -0.043914006 0.531988769              Ma12-NET
# Ma12-RF                   0.286605688 0.546675177               Ma12-RF
# Ma12-SVM                  0.000000000 0.024046914              Ma12-SVM
# Menzies11-DT              0.115167087 0.406897997          Menzies11-DT
# Menzies11-LR              0.048249400 0.376913277          Menzies11-LR
# Menzies11-NB              0.124766360 0.551427326          Menzies11-NB
# Menzies11-NET             0.065595551 0.438375283         Menzies11-NET
# Menzies11-RF              0.162893123 0.493422499          Menzies11-RF
# Menzies11-SVM             0.003558840 0.167013891         Menzies11-SVM
# Menzies11-WHICH           0.068550800 0.321622504       Menzies11-WHICH
# Nam13-DT                          NaN 0.199529605              Nam13-DT
# Nam13-LR                          NaN 0.305192459              Nam13-LR
# Nam13-NB                          NaN 0.347078987              Nam13-NB
# Nam13-NET                         NaN 0.042967541             Nam13-NET
# Nam13-RF                          NaN 0.315514193              Nam13-RF
# Nam13-SVM                         NaN 0.004975248             Nam13-SVM
# Nam15-DT                  0.116737890 0.649315490              Nam15-DT
# Nam15-LR                  0.116752846 0.681817443              Nam15-LR
# Nam15-NB                  0.118784007 0.673049487              Nam15-NB
# Nam15-NET                 0.116737890 0.643129400             Nam15-NET
# Nam15-RF                  0.116737890 0.648815490              Nam15-RF
# Nam15-SVM                 0.066609954 0.195435952             Nam15-SVM
# Panichella14-CODEP-BN     0.175558548 0.688623274 Panichella14-CODEP-BN
# Panichella14-CODEP-LR     0.071935700 0.494086660 Panichella14-CODEP-LR
# Peters12-DT              -0.047639532 0.284497379           Peters12-DT
# Peters12-LR               0.069274558 0.411672437           Peters12-LR
# Peters12-NB               0.116618593 0.682477536           Peters12-NB
# Peters12-NET             -0.032073876 0.429919139          Peters12-NET
# Peters12-RF               0.029798867 0.340045095           Peters12-RF
# Peters12-SVM             -0.001534569 0.043267818          Peters12-SVM
# Peters13-DT              -0.070372111 0.277938753           Peters13-DT
# Peters13-LR               0.075751370 0.445711631           Peters13-LR
# Peters13-NB               0.116474603 0.680456861           Peters13-NB
# Peters13-NET             -0.032082039 0.431629862          Peters13-NET
# Peters13-RF               0.027913425 0.339062224           Peters13-RF
# Peters13-SVM             -0.018999648 0.042988396          Peters13-SVM
# Peters15-DT               0.168831394 0.485630348           Peters15-DT
# Peters15-LR               0.059953834 0.431836983           Peters15-LR
# Peters15-NB               0.182853387 0.833227013           Peters15-NB
# Peters15-NET              0.287847242 0.569830811          Peters15-NET
# Peters15-RF               0.213935142 0.587285759           Peters15-RF
# Peters15-SVM              0.067581182 0.045839836          Peters15-SVM
# PHe15-DT                  0.125960270 0.405852121              PHe15-DT
# PHe15-LR                  0.043106291 0.499433508              PHe15-LR
# PHe15-NB                  0.156979735 0.761703663              PHe15-NB
# PHe15-NET                 0.027084273 0.495054588             PHe15-NET
# PHe15-RF                  0.076319980 0.439898369              PHe15-RF
# PHe15-SVM                 0.000000000 0.015664561             PHe15-SVM
# Random-RANDOM            -0.002164970 0.308663884         Random-RANDOM
# Ryu14-VCBSVM              0.000000000 0.315303321          Ryu14-VCBSVM
# Ryu15-DT                  0.166447352 0.338966414              Ryu15-DT
# Ryu15-LR                  0.063993819 0.317415399              Ryu15-LR
# Ryu15-NB                  0.150620724 0.589703138              Ryu15-NB
# Ryu15-NET                 0.054522687 0.278034125             Ryu15-NET
# Ryu15-RF                  0.164084379 0.278914893              Ryu15-RF
# Ryu15-SVM                 0.037185296 0.058231744             Ryu15-SVM
# Trivial-FIX               0.000000000 0.157621248           Trivial-FIX
# Turhan09-DT               0.123019931 0.525067153           Turhan09-DT
# Turhan09-LR              -0.065774835 0.437067273           Turhan09-LR
# Turhan09-NB               0.131381755 0.800597364           Turhan09-NB
# Turhan09-NET              0.259978895 0.582864543          Turhan09-NET
# Turhan09-RF               0.222888472 0.603867326           Turhan09-RF
# Turhan09-SVM              0.064208562 0.059338169          Turhan09-SVM
# Uchigaki12-LE             0.000000000 0.425908735         Uchigaki12-LE
# Watanabe08-DT             0.139457527 0.525885980         Watanabe08-DT
# Watanabe08-LR             0.047965643 0.523658687         Watanabe08-LR
# Watanabe08-NB             0.203579670 0.730951679         Watanabe08-NB
# Watanabe08-NET            0.053938990 0.477640150        Watanabe08-NET
# Watanabe08-RF             0.276967557 0.583738798         Watanabe08-RF
# Watanabe08-SVM            0.011909973 0.069167819        Watanabe08-SVM
# YZhang15-AVGVOTE          0.196457244 0.773916879      YZhang15-AVGVOTE
# YZhang15-BAG-DT           0.235806083 0.621871656       YZhang15-BAG-DT
# YZhang15-BOOST-DT         0.218347026 0.649567302     YZhang15-BOOST-DT
# YZhang15-BOOST-NB         0.162096635 0.732307359     YZhang15-BOOST-NB
# YZhang15-MAXVOTE          0.158718926 0.814684608      YZhang15-MAXVOTE
# YZhang15-NB               0.166068453 0.807783820           YZhang15-NB
# ZHe13-DT                          NaN 0.641364051              ZHe13-DT
# ZHe13-LR                          NaN 0.515883876              ZHe13-LR
# ZHe13-NB                          NaN 0.629244417              ZHe13-NB
# ZHe13-NET                         NaN 0.700951220             ZHe13-NET
# ZHe13-RF                          NaN 0.715325894              ZHe13-RF
# ZHe13-SVM                         NaN 0.524044548             ZHe13-SVM
# Zimmermann09-DT           0.176848971 0.431925570       Zimmermann09-DT
# Zimmermann09-LR          -0.029721633 0.355660277       Zimmermann09-LR
# Zimmermann09-NB           0.230005564 0.665541323       Zimmermann09-NB
# Zimmermann09-NET          0.021910491 0.453076461      Zimmermann09-NET
# Zimmermann09-RF           0.241580870 0.485465016       Zimmermann09-RF
# Zimmermann09-SVM          0.000000000 0.105531328      Zimmermann09-SVM
rq1best <- plotBestResults(rq1results, "RQ1", "AUC, F-measure, G-Measure, and MCC")
#依据skresults的MEANRANK排名并做图，每种算法只取表现最好的分类的值，ALL只取ALL-NB（NB,LR,DT,NET,RF,SVM是不同分类）
rq3results <- evaluateCPDPBenchmark(metricNamesRQ1, datasetsRQ3)
rq4results <- evaluateCPDPBenchmark(metricNamesRQ1, datasetsRQ4)
writeResultsTableRQ1(rq1best, rq3results, rq4results)
evalRQ2()

cat("comparing JURECZKO and FILTERJURECZKO\n")
compareDatasets("JURECZKO", "FILTERJURECZKO", "auc")
compareDatasets("JURECZKO", "FILTERJURECZKO", "fscore")
compareDatasets("JURECZKO", "FILTERJURECZKO", "gscore")
compareDatasets("JURECZKO", "FILTERJURECZKO", "mcc")

cat("comparing JURECZKO and SELECTEDJURECZKO\n")
compareDatasets("JURECZKO", "SELECTEDJURECZKO", "auc")
compareDatasets("JURECZKO", "SELECTEDJURECZKO", "fscore")
compareDatasets("JURECZKO", "SELECTEDJURECZKO", "gscore")
compareDatasets("JURECZKO", "SELECTEDJURECZKO", "mcc")

cat("comparing AEEEM and AEEEM_LDHH")
compareDatasets("AEEEM", "AEEEM_LDHH", "auc")
compareDatasets("AEEEM", "AEEEM_LDHH", "fscore")
compareDatasets("AEEEM", "AEEEM_LDHH", "gscore")
compareDatasets("AEEEM", "AEEEM_LDHH", "mcc")

cat("comparing AEEEM and AEEEM_WCHU")
compareDatasets("AEEEM", "AEEEM_WCHU", "auc")
compareDatasets("AEEEM", "AEEEM_WCHU", "fscore")
compareDatasets("AEEEM", "AEEEM_WCHU", "gscore")
compareDatasets("AEEEM", "AEEEM_WCHU", "mcc")

cat("comparing AEEEM and AEEEM_LDHHWCHU")
compareDatasets("AEEEM", "AEEEM_LDHHWCHU", "auc")
compareDatasets("AEEEM", "AEEEM_LDHHWCHU", "fscore")
compareDatasets("AEEEM", "AEEEM_LDHHWCHU", "gscore")
compareDatasets("AEEEM", "AEEEM_LDHHWCHU", "mcc")