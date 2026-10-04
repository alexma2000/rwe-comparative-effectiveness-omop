# 01_data_load.R
library(CDMConnector)
library(dplyr)
library(dbplyr)
library(duckdb)

# Создаём локальную DuckDB базу с набором GiBleed (OMOP CDM)
# Первый вызов скачает данные в EUNOMIA_DATA_FOLDER, дальше будет использовать локальную копию
db_path <- eunomiaDir(
  datasetName = "GiBleed",
  cdmVersion = "5.3",
  databaseFile = tempfile(fileext = ".duckdb")
)

con <- DBI::dbConnect(duckdb::duckdb(dbdir = db_path))

# Создаём cdm-объект для удобной работы через dplyr
cdm <- cdmFromCon(
  con = con,
  cdmSchema = "main",
  writeSchema = "main",
  cdmName = "GiBleed"
)

# Проверка: какие таблицы доступны
cdm |> tables()

# Сохраняем соединение и cdm-объект для следующих скриптов
saveRDS(list(con = con, cdm = cdm), file = "output/connection.rds")
