# Análisis Metagenómico: Diversidad Microbiana en Muestras CT vs ST

[![DOI](https://img.shields.io/badge/DOI-10.xxxx%2Fxxxxxx-blue)](https://doi.org/10.xxxx/xxxxxx)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R](https://img.shields.io/badge/R-%3E%3D4.0-blue)](https://www.r-project.org/)
[![Python](https://img.shields.io/badge/Python-%3E%3D3.8-blue)](https://www.python.org/)

## Descripción del Proyecto

Este repositorio contiene el análisis metagenómico completo de dos muestras microbianas: **CT (Control)** y **ST (Treatment)**. El estudio incluye análisis de diversidad alfa, diversidad beta, y caracterización taxonómica de las comunidades microbianas.

## 📊 Resultados Principales

### Control de Calidad
- **Reads totales procesados**: ~X millones
- **Calidad promedio**: Q30+ > 95%
- **Reads después del trimming**: ~X millones (XX% retención)

### Diversidad Microbiana
- **Diversidad Alfa**: Diferencias significativas entre CT y ST
- **Diversidad Beta**: Separación clara entre grupos (NMDS stress < 0.15)
- **Taxa identificados**: XXX especies, XXX géneros, XXX familias

### Composición Taxonómica
- **Phyla dominantes**: Bacteroidetes (XX%), Firmicutes (XX%), Proteobacteria (XX%)
- **Géneros más abundantes**: *Bacteroides*, *Prevotella*, *Faecalibacterium*
- **Especies diferenciales**: XX especies significativamente diferentes entre grupos

## 📁 Estructura del Repositorio

```
├── data/                          # Datos procesados
│   ├── quality_control/           # Reportes FastQC
│   │   ├── before_trimming/       # QC antes del trimming
│   │   └── after_trimming/        # QC después del trimming
│   ├── taxonomy/                  # Clasificación taxonómica
│   │   ├── kraken2_reports/       # Reportes Kraken2
│   │   ├── bracken_results/       # Estimaciones Bracken
│   │   └── biom_files/           # Archivos BIOM
│   └── assembly/                  # Ensamblajes
├── results/                       # Resultados del análisis
│   ├── diversity_analysis/        # Análisis de diversidad
│   │   ├── alpha_diversity.png    # Gráficas diversidad alfa
│   │   ├── beta_diversity_nmds.png # NMDS
│   │   ├── beta_diversity_pcoa.png # PCoA
│   │   └── abundance_plots/       # Gráficas de abundancia
│   ├── statistical_analysis/      # Análisis estadísticos
│   └── figures/                   # Figuras principales
├── scripts/                       # Scripts de análisis
│   ├── 01_quality_control.sh      # Control de calidad
│   ├── 02_taxonomic_analysis.sh   # Análisis taxonómico
│   ├── 03_diversity_analysis.R    # Análisis de diversidad
│   └── pipeline_master.sh         # Pipeline completo
├── docs/                          # Documentación
│   ├── methods.md                 # Métodos detallados
│   ├── software_versions.md       # Versiones de software
│   └── supplementary_info.md      # Información suplementaria
└── README.md                      # Este archivo
```

## 🔬 Metodología

### Secuenciación y Datos
- **Plataforma**: Illumina NovaSeq 6000
- **Estrategia**: Paired-end 2×150 bp
- **Profundidad**: ~X millones de reads por muestra
- **Región objetivo**: Shotgun metagenomics

### Pipeline de Análisis

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
```

#### 3. Análisis de Diversidad
```r
# Cargar datos BIOM
physeq <- import_biom("combined_taxonomy.biom")

# Diversidad alfa
alpha_div <- estimate_richness(physeq, measures = c("Shannon", "Simpson", "Chao1"))

# Diversidad beta (NMDS y PCoA)
ord_nmds <- ordinate(physeq, method = "NMDS", distance = "bray")
ord_pcoa <- ordinate(physeq, method = "PCoA", distance = "bray")
```

## 📈 Resultados Principales

### Diversidad Alfa
![Diversidad Alfa](results/diversity_analysis/alpha_diversity.png)

**Hallazgos clave:**
- Índice de Shannon: CT = X.XX ± X.XX, ST = X.XX ± X.XX
- Índice de Simpson: CT = X.XX ± X.XX, ST = X.XX ± X.XX
- Riqueza observada: CT = XXX ± XX, ST = XXX ± XX

### Diversidad Beta
<div align="center">
  <img src="results/diversity_analysis/beta_diversity_nmds.png" width="45%" />
  <img src="results/diversity_analysis/beta_diversity_pcoa.png" width="45%" />
</div>

**Hallazgos clave:**
- NMDS stress: X.XXX (excelente representación)
- PERMANOVA: R² = X.XXX, p < 0.001
- Separación clara entre grupos CT y ST

### Composición Taxonómica

#### A Nivel de Phylum
![Abundancia Phylum](results/diversity_analysis/abundance_phylum.png)

#### A Nivel de Género
![Abundancia Género](results/diversity_analysis/abundance_genus.png)

#### A Nivel de Especie
![Abundancia Especie](results/diversity_analysis/abundance_species.png)

## 🛠️ Requisitos de Software

### Herramientas Principales
- **FastQC** v0.11.9 - Control de calidad
- **TrimGalore** v0.6.7 - Trimming de reads
- **Kraken2** v2.1.2 - Clasificación taxonómica
- **Bracken** v2.7 - Estimación de abundancias
- **MEGAHIT** v1.2.9 - Ensamblaje
- **R** v4.2.0 - Análisis estadístico

### Paquetes de R
```r
# Instalar paquetes necesarios
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install(c("phyloseq"))
install.packages(c("ggplot2", "vegan", "RColorBrewer", "patchwork", 
                   "dplyr", "tidyr", "gridExtra", "scales"))
```

### Bases de Datos
- **Kraken2 PlusPFP**: Base de datos estándar + protozoos, hongos y plantas
- **GTDBtk**: GTDB release 207

## 🚀 Reproducibilidad

### Ejecutar el Pipeline Completo
```bash
# Clonar repositorio
git clone https://github.com/usuario/metagenomics-ct-st.git
cd metagenomics-ct-st

# Ejecutar pipeline completo
bash scripts/pipeline_master.sh

# O ejecutar pasos individuales
bash scripts/01_quality_control.sh
bash scripts/02_taxonomic_analysis.sh
Rscript scripts/03_diversity_analysis.R
```

### Configuración del Ambiente
```bash
# Crear ambiente conda
conda create -n metagenomics -c bioconda -c conda-forge \
    fastqc trimgalore kraken2 bracken megahit r-base

# Activar ambiente
conda activate metagenomics
```

## 📊 Datos Suplementarios

### Archivos Disponibles
- **Tabla S1**: Estadísticas de secuenciación y control de calidad
- **Tabla S2**: Abundancias taxonómicas completas por muestra
- **Tabla S3**: Índices de diversidad alfa por muestra
- **Tabla S4**: Resultados de análisis estadísticos
- **Figura S1**: Curvas de rarefacción
- **Figura S2**: Heatmap de abundancias a nivel de familia

### Acceso a Datos Crudos
Los datos de secuenciación están disponibles en:
- **SRA**: PRJNA123456
- **ENA**: ERP123456

## 📝 Citación

Si utilizas este código o datos, por favor cita:

```bibtex
@article{autor2024metagenomics,
  title={Análisis metagenómico comparativo de comunidades microbianas CT vs ST},
  author={Autor, A. and Colaborador, B.},
  journal={Journal of Metagenomics},
  year={2024},
  volume={X},
  pages={XXX-XXX},
  doi={10.xxxx/xxxxxx}
}
```

## 👥 Contribuidores

- **Investigador Principal**: [Nombre] - Diseño experimental y análisis
- **Bioinformático**: [Nombre] - Pipeline de análisis y scripts
- **Técnico de Laboratorio**: [Nombre] - Preparación de muestras y secuenciación

## 📞 Contacto

- **Email**: investigador@universidad.edu
- **ORCID**: [0000-0000-0000-0000](https://orcid.org/0000-0000-0000-0000)
- **Twitter**: [@usuario](https://twitter.com/usuario)

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 🙏 Agradecimientos

- Laboratorio de Microbiología, Universidad XYZ
- Centro de Secuenciación ABC
- Financiamiento: Grant #123456 de la Agencia Nacional de Ciencia

## 📚 Referencias

1. Wood, D.E., et al. (2019). Improved metagenomic analysis with Kraken 2. *Genome Biology*, 20, 257.
2. Lu, J., et al. (2017). Bracken: estimating species abundance in metagenomics data. *PeerJ Computer Science*, 3, e104.
3. McMurdie, P.J. & Holmes, S. (2013). phyloseq: an R package for reproducible interactive analysis and graphics of microbiome census data. *PLoS ONE*, 8(4), e61217.

---

**Última actualización**: $(date +"%B %Y")
**Versión del pipeline**: 1.0.0

