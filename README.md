# Análisis Metagenómico de Muestras CT y ST

Este repositorio contiene los resultados de un análisis metagenómico realizado a dos muestras: **CT** y **ST**. A continuación se describen las carpetas y se proporcionan enlaces a visualizaciones interactivas.

---

## Estructura del repositorio

- `biom/` – Perfiles taxonómicos en formato BIOM.
- `krona/` – Visualizaciones interactivas de abundancias taxonómicas.
- `logs/` – Registros de ejecución de los scripts.
- `src/` – Scripts usados para el análisis.
- `trim/` – Resultados de control de calidad antes y después del trimming.

---

#### 1. Control de Calidad
```bash
# FastQC inicial
fastqc *.fastq.gz

# Trimming con TrimGalore
trim_galore --paired --quality 20 --length 50 *.fastq.gz

# FastQC post-trimming
fastqc *_val_*.fq.gz
```

#### 2. Clasificación Taxonómica
```bash
# Kraken2 para clasificación inicial
kraken2 --db k2_pluspfp --paired --output kraken.out --report kraken_report.txt

# Bracken para refinamiento de abundancias
bracken -d k2_pluspfp -i kraken_report.txt -o bracken.out -l S


## Control de calidad con FastQC

### Antes del trimming

- [CT - Read 1](trim/fastqc_before/CT_FKDN25H000391-1A_22NWHGLT4_L5_1_fastqc.html)
- [CT - Read 2](trim/fastqc_before/CT_FKDN25H000391-1A_22NWHGLT4_L5_2_fastqc.html)
- [ST - Read 1](trim/fastqc_before/ST_FKDN25H000392-1A_22NWHGLT4_L5_1_fastqc.html)
- [ST - Read 2](trim/fastqc_before/ST_FKDN25H000392-1A_22NWHGLT4_L5_2_fastqc.html)

### Después del trimming

- [CT - Read 1](trim/fastqc_after/CT_FKDN25H000391-1A_22NWHGLT4_L5_1_val_1_fastqc.html)
- [CT - Read 2](trim/fastqc_after/CT_FKDN25H000391-1A_22NWHGLT4_L5_2_val_2_fastqc.html)
- [ST - Read 1](trim/fastqc_after/ST_FKDN25H000392-1A_22NWHGLT4_L5_1_val_1_fastqc.html)
- [ST - Read 2](trim/fastqc_after/ST_FKDN25H000392-1A_22NWHGLT4_L5_2_val_2_fastqc.html)

---

## Visualización taxonómica con Krona

- [CT - Krona plot](krona/CT_FKDN25H000391-1A_22NWHGLT4_L5_krona.out.html)
- [ST - Krona plot](krona/ST_FKDN25H000392-1A_22NWHGLT4_L5_krona.out.html)

---

## Perfiles en formato BIOM

Los archivos `.biom` generados pueden encontrarse en la carpeta [biom/](https://github.com/shadayguerrero/barbara/tree/main/biom), listos para ser analizados con herramientas, **Phyloseq** o **Scikit-bio** u otras plataformas.

---




