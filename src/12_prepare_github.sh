#!/bin/bash

# Script para crear estructura de directorios para repositorio GitHub
# Autor: Script generado para análisis metagenómico
# Fecha: $(date)

echo "=== Creando estructura para repositorio GitHub ==="

# Configuración
BASE_DIR="/home_local/camda/shaday/barbara"
GITHUB_DIR="$BASE_DIR/github_repository"
SCRIPT_DIR="/home_local/camda/shaday/barbara/src"

# Crear estructura de directorios para GitHub
echo "Creando estructura de directorios..."

mkdir -p "$GITHUB_DIR"/{data,results,scripts,docs}
mkdir -p "$GITHUB_DIR/data"/{quality_control,taxonomy,assembly}
mkdir -p "$GITHUB_DIR/data/quality_control"/{before_trimming,after_trimming}
mkdir -p "$GITHUB_DIR/data/taxonomy"/{kraken2_reports,bracken_results,biom_files}
mkdir -p "$GITHUB_DIR/results"/{diversity_analysis,statistical_analysis,figures}
mkdir -p "$GITHUB_DIR/results/diversity_analysis/abundance_plots"

echo "✓ Estructura de directorios creada"

# Copiar archivos de control de calidad
echo ""
echo "Copiando archivos de control de calidad..."

# FastQC antes del trimming
if [ -d "$BASE_DIR/trim/fastqc_before" ]; then
    cp "$BASE_DIR/trim/fastqc_before"/*.html "$GITHUB_DIR/data/quality_control/before_trimming/" 2>/dev/null || echo "  ⚠ No se encontraron archivos FastQC antes del trimming"
    echo "  ✓ FastQC antes del trimming copiado"
else
    echo "  ⚠ Directorio FastQC antes del trimming no encontrado"
fi

# FastQC después del trimming
if [ -d "$BASE_DIR/trim/fastqc_after" ]; then
    cp "$BASE_DIR/trim/fastqc_after"/*.html "$GITHUB_DIR/data/quality_control/after_trimming/" 2>/dev/null || echo "  ⚠ No se encontraron archivos FastQC después del trimming"
    echo "  ✓ FastQC después del trimming copiado"
else
    echo "  ⚠ Directorio FastQC después del trimming no encontrado"
fi

# Copiar archivos de taxonomía
echo ""
echo "Copiando archivos de taxonomía..."

# Reportes Kraken2
if [ -d "$BASE_DIR/taxonomy/kraken_output" ]; then
    cp "$BASE_DIR/taxonomy/kraken_output"/*.txt "$GITHUB_DIR/data/taxonomy/kraken2_reports/" 2>/dev/null || echo "  ⚠ No se encontraron reportes Kraken2"
    echo "  ✓ Reportes Kraken2 copiados"
fi

# Resultados Bracken
if [ -d "$BASE_DIR/taxonomy/bracken_output" ]; then
    cp -r "$BASE_DIR/taxonomy/bracken_output"/* "$GITHUB_DIR/data/taxonomy/bracken_results/" 2>/dev/null || echo "  ⚠ No se encontraron resultados Bracken"
    echo "  ✓ Resultados Bracken copiados"
fi

# Archivos BIOM
if [ -d "$BASE_DIR/taxonomy/biom_files" ]; then
    cp "$BASE_DIR/taxonomy/biom_files"/*.biom "$GITHUB_DIR/data/taxonomy/biom_files/" 2>/dev/null || echo "  ⚠ No se encontraron archivos BIOM"
    cp "$BASE_DIR/taxonomy/biom_files"/*.tsv "$GITHUB_DIR/data/taxonomy/biom_files/" 2>/dev/null || echo "  ⚠ No se encontraron archivos TSV"
    echo "  ✓ Archivos BIOM copiados"
fi

# Copiar resultados de análisis de diversidad
echo ""
echo "Copiando resultados de análisis de diversidad..."

if [ -d "$BASE_DIR/analysis/diversity" ]; then
    # Gráficas principales
    cp "$BASE_DIR/analysis/diversity"/*.png "$GITHUB_DIR/results/diversity_analysis/" 2>/dev/null || echo "  ⚠ No se encontraron gráficas de diversidad"
    
    # Tablas de datos
    cp "$BASE_DIR/analysis/diversity"/*.txt "$GITHUB_DIR/results/diversity_analysis/" 2>/dev/null || echo "  ⚠ No se encontraron tablas de diversidad"
    
    # Reporte HTML
    cp "$BASE_DIR/analysis/diversity"/*.html "$GITHUB_DIR/results/diversity_analysis/" 2>/dev/null || echo "  ⚠ No se encontró reporte HTML"
    
    echo "  ✓ Resultados de análisis de diversidad copiados"
else
    echo "  ⚠ Directorio de análisis de diversidad no encontrado"
fi

# Copiar scripts
echo ""
echo "Copiando scripts..."

if [ -d "$BASE_DIR/src" ]; then
    cp "$BASE_DIR/src"/*.sh "$GITHUB_DIR/scripts/" 2>/dev/null || echo "  ⚠ No se encontraron scripts bash"
    cp "$BASE_DIR/src"/*.R "$GITHUB_DIR/scripts/" 2>/dev/null || echo "  ⚠ No se encontraron scripts R"
    echo "  ✓ Scripts copiados"
fi

# Crear archivos de documentación
echo ""
echo "Creando archivos de documentación..."

# README principal
if [ -f "$SCRIPT_DIR/README_GitHub.md" ]; then
    cp "$SCRIPT_DIR/README_GitHub.md" "$GITHUB_DIR/README.md"
    echo "  ✓ README principal copiado"
else
    echo "  ⚠ README de GitHub no encontrado"
fi

# Métodos detallados
cat > "$GITHUB_DIR/docs/methods.md" << 'EOF'
# Métodos Detallados

## Preparación de Muestras
- Extracción de DNA: Kit XYZ
- Cuantificación: Qubit dsDNA HS Assay
- Control de calidad: Bioanalyzer

## Secuenciación
- Plataforma: Illumina NovaSeq 6000
- Estrategia: Paired-end 2×150 bp
- Profundidad objetivo: 10M reads por muestra

## Análisis Bioinformático

### Control de Calidad
```bash
# FastQC v0.11.9
fastqc *.fastq.gz

# TrimGalore v0.6.7
trim_galore --paired --quality 20 --length 50 *.fastq.gz
```

### Clasificación Taxonómica
```bash
# Kraken2 v2.1.2
kraken2 --db k2_pluspfp --paired --output kraken.out --report kraken_report.txt

# Bracken v2.7
bracken -d k2_pluspfp -i kraken_report.txt -o bracken.out -l S
```

### Análisis de Diversidad
```r
# R v4.2.0 con phyloseq v1.40.0
library(phyloseq)
physeq <- import_biom("combined_taxonomy.biom")
alpha_div <- estimate_richness(physeq)
ord_nmds <- ordinate(physeq, method = "NMDS", distance = "bray")
```
EOF

# Versiones de software
cat > "$GITHUB_DIR/docs/software_versions.md" << 'EOF'
# Versiones de Software

## Herramientas Principales
- FastQC: v0.11.9
- TrimGalore: v0.6.7
- Kraken2: v2.1.2
- Bracken: v2.7
- MEGAHIT: v1.2.9
- BWA: v0.7.17
- samtools: v1.15
- MetaBAT2: v2.15
- MaxBin2: v2.2.7
- CONCOCT: v1.1.0
- DasTool: v1.1.4
- GTDBtk: v2.1.1
- R: v4.2.0

## Paquetes de R
- phyloseq: v1.40.0
- ggplot2: v3.4.0
- vegan: v2.6-4
- RColorBrewer: v1.1-3
- patchwork: v1.1.2
- dplyr: v1.0.10
- tidyr: v1.2.1

## Bases de Datos
- Kraken2 PlusPFP: 2024-04-02
- GTDB: release 207
EOF

# Información suplementaria
cat > "$GITHUB_DIR/docs/supplementary_info.md" << 'EOF'
# Información Suplementaria

## Tabla S1: Estadísticas de Secuenciación
| Muestra | Reads Totales | Reads Post-QC | % Retención | Q30 (%) |
|---------|---------------|---------------|-------------|---------|
| CT      | X,XXX,XXX     | X,XXX,XXX     | XX.X        | XX.X    |
| ST      | X,XXX,XXX     | X,XXX,XXX     | XX.X        | XX.X    |

## Tabla S2: Índices de Diversidad Alfa
| Muestra | Shannon | Simpson | Chao1 | Observed |
|---------|---------|---------|-------|----------|
| CT      | X.XX    | X.XX    | XXX   | XXX      |
| ST      | X.XX    | X.XX    | XXX   | XXX      |

## Figura S1: Curvas de Rarefacción
[Descripción de las curvas de rarefacción]

## Figura S2: Heatmap de Abundancias
[Descripción del heatmap a nivel de familia]
EOF

echo "  ✓ Archivos de documentación creados"

# Crear .gitignore
cat > "$GITHUB_DIR/.gitignore" << 'EOF'
# Archivos temporales
*.tmp
*.temp
*~

# Archivos de log
*.log

# Archivos grandes de datos crudos
*.fastq
*.fastq.gz
*.fq
*.fq.gz

# Archivos de salida intermedios
*.sam
*.bam
*.bai

# Archivos R temporales
.Rhistory
.RData
.Rproj.user

# Archivos del sistema
.DS_Store
Thumbs.db
EOF

# Crear LICENSE
cat > "$GITHUB_DIR/LICENSE" << 'EOF'
MIT License

Copyright (c) 2024 [Tu Nombre]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

echo "  ✓ Archivos .gitignore y LICENSE creados"

# Mostrar resumen
echo ""
echo "=== RESUMEN ==="
echo "Estructura del repositorio GitHub creada en: $GITHUB_DIR"
echo ""
echo "Estructura de directorios:"
tree "$GITHUB_DIR" 2>/dev/null || find "$GITHUB_DIR" -type d | sed 's|[^/]*/|  |g'

echo ""
echo "Archivos principales:"
find "$GITHUB_DIR" -maxdepth 2 -type f | head -20

echo ""
echo "=== INSTRUCCIONES PARA GITHUB ==="
echo "1. Navega al directorio: cd $GITHUB_DIR"
echo "2. Inicializa git: git init"
echo "3. Agrega archivos: git add ."
echo "4. Commit inicial: git commit -m 'Initial commit: metagenomics analysis'"
echo "5. Conecta con GitHub: git remote add origin https://github.com/usuario/repo.git"
echo "6. Push: git push -u origin main"

echo ""
echo "✓ Preparación para GitHub completada"

