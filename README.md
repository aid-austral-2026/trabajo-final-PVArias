# Trabajo Final

Repo con el enunciado y los materiales para la entrega final en **Análisis Inteligente de Datos**.

# Películas de IMDb: puntajes y duración por década y género

Trabajo final de **Análisis Inteligente de Datos** (Maestría en Explotación de Datos y Gestión del Conocimiento, Universidad Austral).

**Autora:** Paula Arias

**Informe publicado:** <https://aid-austral-2026.github.io/trabajo-final-PVArias/>

## Descripción

El trabajo explora, con datos abiertos de IMDb, cómo evolucionaron el **puntaje** y la **duración** de las películas por década y por género.
Se entrega como un **reporte Quarto con salida HTML** (`index.qmd` / `index.html`) que recorre las cuatro etapas del análisis de datos:

| Etapa | Dónde se refleja |
|:--|:--|
| **Selección** | Sección *Materiales y métodos > Selección de los datos* del informe |
| **Limpieza** | Sección *Materiales y métodos > Limpieza* del informe y script `codigo/01_limpieza.R` |
| **Exploración** | Sección *Resultados*: medidas descriptivas, boxplots, mapas de calor y gráficos interactivos |
| **Comunicación** | El informe en sí, producido con Quarto |

## Estructura del repositorio

```
├── index.qmd              # Código fuente del informe (Quarto)
├── index.html             # Informe renderizado (se publica en GitHub Pages)
├── README.md              # Este archivo
├── .gitignore             # Excluye datos_crudos/ del repositorio
├── codigo/
│   └── 01_limpieza.R      # Lee los datos originales, los limpia y guarda los resultados
├── datos_salida/          # Datos ya limpios, que usa el informe
│   ├── peliculas.csv          # Una fila por película
│   ├── peliculas_genero.csv   # Una fila por película y por género
│   └── embudo_limpieza.csv    # Cantidad de películas que quedan en cada paso de la limpieza
└── datos_crudos/          # Datos originales de IMDb (NO incluidos en el repositorio)
```

## Fuente de los datos

Conjuntos de datos públicos de IMDb: <https://datasets.imdbws.com/>

- Se utilizaron las tablas `title.basics.tsv.gz` y `title.ratings.tsv.gz`.
- **Fecha de descarga: 7 de noviembre de 2026.** IMDb actualiza estos archivos a diario, por lo que una descarga posterior puede dar resultados levemente distintos.
- IMDb ofrece estos datos para uso personal y no comercial y sujetos a sus términos y condiciones. Este trabajo tiene fines exclusivamente académicos.

## Cómo reproducir el trabajo

Todas las rutas son relativas a la raíz del repositorio, por lo que el *working directory* debe ser esa carpeta (por ejemplo, abriendo el proyecto de RStudio o la carpeta del repo).

### Paquetes necesarios

```r
install.packages(c("tidyverse", "knitr", "plotly", "crosstalk"))
```

Además, para renderizar el informe se necesita [Quarto](https://quarto.org/) (viene incluido en las versiones recientes de RStudio).

### Opción A: ver el informe

Abrir `index.html` en un navegador, o ingresar al enlace de GitHub Pages indicado arriba. Los gráficos interactivos funcionan sin conexión a internet.

### Opción B: volver a generar el informe

El informe lee los datos ya limpios de `datos_salida/`, que están incluidos en el repositorio. Alcanza con renderizar `index.qmd` (botón *Render* en RStudio, o `quarto render index.qmd` en la terminal).

### Opción C: reproducir todo desde los datos originales

1. Descargar `title.basics.tsv.gz` y `title.ratings.tsv.gz` desde <https://datasets.imdbws.com/> y guardarlos, sin descomprimir, en una carpeta `datos_crudos/` en la raíz del repositorio. Pesan cientos de megabytes, por eso no se incluyen.
2. Ejecutar `codigo/01_limpieza.R`. Lee los archivos, limpia los datos y regenera los tres archivos de `datos_salida/`. La lectura puede tardar un minuto y consume bastante memoria, porque `title.basics` tiene casi 13 millones de filas.
3. Renderizar `index.qmd`, como en la opción B.

## Decisiones principales de la limpieza

El informe detalla cada paso con la cantidad de películas descartadas. En resumen:

- Se conservan solo los títulos de tipo película y se excluye el contenido marcado como para adultos.
- Se mantienen las películas con puntaje y con al menos **1.000 votos**, porque un puntaje basado en pocos votos es poco confiable.
- Se excluyen las películas sin año, duración o género, las estrenadas en 2026 y las de duración menor a 40 o mayor a 300 minutos.
- Como una película puede tener hasta tres géneros, se genera una segunda base con una fila por película y por género.
- Resultado: **48.482 películas**. Para el análisis se usan las estrenadas desde 1920, los géneros con al menos 500 películas y las combinaciones de década y género con al menos 30 películas.

## Limitaciones

- Los puntajes corresponden a usuarios de IMDb y no representan la opinión de toda la audiencia ni de la crítica.
- El filtro de 1.000 votos deja en las décadas antiguas sobre todo a los clásicos más conocidos, lo que puede inflar sus puntajes.
- La década de 2020 está incompleta (solo hasta 2025).
- El análisis es descriptivo: muestra patrones, no causas.