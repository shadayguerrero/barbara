#!/bin/bash

# Script para verificar y crear estructura de directorios
# Autor: Script generado para análisis metagenómico
# Fecha: $(date)

echo "=== Verificando estructura de directorios ==="

# Directorios base
BASE_DIR="/home_local/camda/shaday/barbara"
READS_DIR="/home_local/camda/shaday/barbara/reads"
SRC_DIR="/home_local/camda/shaday/barbara/src"
KRAKEN_DB="/home_local/compartida/camda2024/k2_pluspfp_20250402"

# Directorios de salida
TRIM_DIR="/home_local/camda/shaday/barbara/trim"
TAXONOMY_DIR="/home_local/camda/shaday/barbara/taxonomy"
ASSEMBLY_DIR="/home_local/camda/shaday/barbara/assembly"
MAPPING_DIR="/home_local/camda/shaday/barbara/mapping"
BINNING_DIR="/home_local/camda/shaday/barbara/binning"
ANNOTATION_DIR="/home_local/camda/shaday/barbara/annotation"

# Verificar directorios de entrada
echo "Verificando directorios de entrada..."
if [ ! -d "$READS_DIR" ]; then
    echo "ERROR: No se encuentra el directorio de reads: $READS_DIR"
    exit 1
fi

if [ ! -d "$KRAKEN_DB" ]; then
    echo "ERROR: No se encuentra la base de datos de Kraken: $KRAKEN_DB"
    exit 1
fi

# Verificar archivos de reads
echo "Verificando archivos de reads..."
SAMPLES=("CT_FKDN25H000391-1A_22NWHGLT4_L5" "ST_FKDN25H000392-1A_22NWHGLT4_L5")

for sample in "${SAMPLES[@]}"; do
    if [ ! -f "$READS_DIR/${sample}_1.fq.gz" ]; then
        echo "ERROR: No se encuentra ${sample}_1.fq.gz"
        exit 1
    fi
    if [ ! -f "$READS_DIR/${sample}_2.fq.gz" ]; then
        echo "ERROR: No se encuentra ${sample}_2.fq.gz"
        exit 1
    fi
    echo "✓ Archivos encontrados para muestra: $sample"
done

# Crear directorios de salida
echo "Creando directorios de salida..."
mkdir -p "$SRC_DIR"
mkdir -p "$TRIM_DIR"
mkdir -p "$TAXONOMY_DIR"
mkdir -p "$ASSEMBLY_DIR"
mkdir -p "$MAPPING_DIR"
mkdir -p "$BINNING_DIR"
mkdir -p "$ANNOTATION_DIR"

# Crear subdirectorios específicos
mkdir -p "$TRIM_DIR/fastqc_before"
mkdir -p "$TRIM_DIR/fastqc_after"
mkdir -p "$TRIM_DIR/trimmed_reads"
mkdir -p "$TAXONOMY_DIR/kraken_output"
mkdir -p "$TAXONOMY_DIR/biom_files"
mkdir -p "$ASSEMBLY_DIR/megahit_output"
mkdir -p "$MAPPING_DIR/bam_files"
mkdir -p "$BINNING_DIR/metabat2"
mkdir -p "$BINNING_DIR/maxbin2"
mkdir -p "$BINNING_DIR/concoct"
mkdir -p "$BINNING_DIR/dastool"
mkdir -p "$ANNOTATION_DIR/gtdbtk"

echo "✓ Estructura de directorios creada exitosamente"
echo "✓ Verificación completada"

# Mostrar resumen
echo ""
echo "=== RESUMEN ==="
echo "Directorio base: $BASE_DIR"
echo "Reads: $READS_DIR"
echo "Scripts: $SRC_DIR"
echo "Base de datos Kraken: $KRAKEN_DB"
echo ""
echo "Directorios de salida creados:"
echo "- Trimming: $TRIM_DIR"
echo "- Taxonomía: $TAXONOMY_DIR"
echo "- Ensamblaje: $ASSEMBLY_DIR"
echo "- Mapeo: $MAPPING_DIR"
echo "- Binning: $BINNING_DIR"
echo "- Anotación: $ANNOTATION_DIR"

