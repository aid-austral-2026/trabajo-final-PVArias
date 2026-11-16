# =============================================================================
# 01_limpieza.R
# Limpieza de los datos de películas de IMDb
#
# Qué hace este script:
#   1. Lee los archivos originales de IMDb (title.basics y title.ratings).
#   2. Se queda con las películas y las une con sus puntajes.
#   3. Limpia los datos y construye las variables para el análisis.
#   4. Guarda los datos limpios y la tabla del "embudo" de limpieza
#      en la carpeta datos_salida/.
#
# Entradas (carpeta datos_crudos/, no incluida en el repositorio por su tamaño):
#   - title.basics.tsv.gz
#   - title.ratings.tsv.gz
#   Se descargan de https://datasets.imdbws.com/ (descarga: 7/11/2026).
#
# Salidas (carpeta datos_salida/):
#   - peliculas.csv: una fila por película.
#   - peliculas_genero.csv: una fila por película y por género.
#   - embudo_limpieza.csv: cantidad de películas que quedan en cada paso.
#
# Cómo ejecutarlo: abrir el proyecto de RStudio, de modo que el directorio de
# trabajo sea la raíz del repositorio (las rutas son relativas a esa carpeta).
# Nota: el informe (index.qmd) solo necesita los archivos de datos_salida/,
# por lo que este script solo hay que correrlo si se vuelven a descargar
# los datos originales.
# =============================================================================


# 1. Paquetes ----------------------------------------------------------------

# Si no está instalado, instalarlo una sola vez (quitar el # de la línea):
# install.packages("tidyverse")

# tidyverse incluye los paquetes usados acá: readr (lectura de archivos),
# dplyr (filtros y transformaciones), tidyr (reorganizar tablas) y
# stringr (trabajo con texto)
library(tidyverse)


# 2. Lectura de los datos ----------------------------------------------------

# En estos archivos los valores faltantes están escritos como "\N";
# na = "\\N" hace que R los lea como NA.
# quote = "" evita problemas con títulos que contienen comillas.
basics <- read_tsv("datos_crudos/title.basics.tsv.gz",
                   na = "\\N", quote = "", show_col_types = FALSE)

ratings <- read_tsv("datos_crudos/title.ratings.tsv.gz",
                    na = "\\N", quote = "", show_col_types = FALSE)

# Control de lectura: glimpse() muestra en forma compacta la cantidad de filas
# y columnas, el nombre y el tipo de cada variable y sus primeros valores.
# Sirve para verificar que los archivos se leyeron bien (por ejemplo, que
# los números se reconocieron como numéricos y no como texto).
glimpse(basics)
glimpse(ratings)


# 3. Selección de películas y unión de las tablas ----------------------------

# Se conservan solo las películas (se descartan series, cortos y otros
# formatos) sin marca de contenido para adultos, y se unen con sus puntajes
# mediante la clave tconst. inner_join() deja únicamente los títulos que
# aparecen en ambas tablas, es decir, las películas que tienen puntaje.
peliculas <- basics %>%
  filter(titleType == "movie", isAdult == 0) %>%
  inner_join(ratings, by = "tconst")

# Diagnóstico de la base unida (no modifica los datos):
dim(peliculas)          # cantidad de filas y columnas
colSums(is.na(peliculas))     # cantidad de valores faltantes por columna
summary(peliculas$startYear)  # resumen del año de estreno
summary(peliculas$runtimeMinutes) # resumen de la duración (detecta atípicos)
summary(peliculas$numVotes)   # resumen de la cantidad de votos


# 4. Limpieza y construcción de variables ------------------------------------

peliculas_limpias <- peliculas %>%
  filter(
    numVotes >= 1000,              # puntajes con al menos 1000 votos
    !is.na(startYear), !is.na(runtimeMinutes), !is.na(genres), # datos completos
    !str_detect(genres, "Adult"),   # excluye el género "Adult"
    startYear <= 2025,             # menos o igual a 2025 ya que 2026 todavía no terminó
    runtimeMinutes >= 40,          # largometraje: 40 minutos o más
    runtimeMinutes <= 300          # descarta duraciones imposibles
  ) %>%
  # Década de estreno: por ejemplo, 1994 / 10 = 199,4; floor() lo redondea
  # hacia abajo (199) y al multiplicar por 10 se obtiene 1990
  mutate(decada = floor(startYear / 10) * 10) %>%
  # Se eligen las columnas que se usan y se les dan nombres más claros
  select(id = tconst, titulo = primaryTitle, anio = startYear, decada,
         duracion = runtimeMinutes, generos = genres,
         puntaje = averageRating, votos = numVotes)


# 5. Formato largo por género ------------------------------------------------

# Cada película tiene hasta tres géneros en una sola celda (por ejemplo,
# "Drama,Romance"). Para comparar géneros se necesita una fila por película
# y por género:
# 1) separate() divide la celda en hasta 3 columnas (si hay menos de 3
#    géneros, las columnas sobrantes quedan en NA);
# 2) pivot_longer() apila las 3 columnas en una sola y descarta los NA.
peliculas_genero <- peliculas_limpias %>%
  separate(col = generos, into = c("genero1", "genero2", "genero3"),
           sep = ",", fill = "right", remove = FALSE) %>%
  pivot_longer(cols = c(genero1, genero2, genero3),
               names_to = "posicion", values_to = "genero",
               values_drop_na = TRUE) %>%
  select(-posicion, -generos)

# Diagnóstico final de la base limpia:
dim(peliculas_limpias)  # cantidad de películas que quedaron
count(peliculas_limpias, decada)  # películas por década
count(peliculas_genero, genero, sort = TRUE) %>% print(n = Inf)  # por género


# 6. Guardado de los datos limpios -------------------------------------------

# dir.create() crea la carpeta de salida si no existe
dir.create("datos_salida", showWarnings = FALSE)
write_csv(peliculas_limpias, "datos_salida/peliculas.csv")
write_csv(peliculas_genero, "datos_salida/peliculas_genero.csv")


# 7. Embudo de limpieza ------------------------------------------------------

# Para documentar en el informe cuántas películas se pierden en cada paso, se
# repiten los filtros de la limpieza de a uno, en el mismo orden, contando
# las películas que quedan después de cada uno.

p1 <- peliculas %>% filter(numVotes >= 1000)
p2 <- p1 %>% filter(!is.na(startYear), !is.na(runtimeMinutes), !is.na(genres))
p3 <- p2 %>% filter(startYear <= 2025)
p4 <- p3 %>% filter(runtimeMinutes >= 40, runtimeMinutes <= 300)
p5 <- p4 %>% filter(!str_detect(genres, "Adult"))

embudo <- tibble(
  paso = c("Títulos de tipo película en IMDb",
           "Sin marca de contenido para adultos",
           "Con puntaje (unión con ratings)",
           "Con al menos 1000 votos",
           "Con año, duración y géneros completos",
           "Estrenadas hasta 2025",
           "Duración entre 40 y 300 minutos",
           "Sin el género Adult"),
  n = c(sum(basics$titleType == "movie"),
        nrow(filter(basics, titleType == "movie", isAdult == 0)),
        nrow(peliculas), nrow(p1), nrow(p2), nrow(p3), nrow(p4), nrow(p5))
) %>%
  mutate(perdidas = lag(n) - n)   # películas descartadas en ese paso (NA en el primero)

# Control: el último paso del embudo debe coincidir con la base limpia;
# si no, el script se detiene con un error
stopifnot(nrow(p5) == nrow(peliculas_limpias))


write_csv(embudo, "datos_salida/embudo_limpieza.csv")
embudo