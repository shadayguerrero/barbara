#!/bin/bash

# Script para FastQC inicial (antes del trimming)
# Autor: Script generado para análisis metagenómico
# Fecha: $(date)

echo "=== Iniciando FastQC antes del trimming ==="

# Configuración
READS_DIR="/home_local/camda/shaday/barbara/reads"
OUTPUT_DIR="/home_local/camda/shaday/barbara/trim/fastqc_before"
CONDA_ENV="metagenomics"

# Activar ambiente micromamba
echo "Activando ambiente micromamba: $CONDA_ENV"
eval "$(micromamba shell hook --shell bash)"
micromamba activate /home_local/camda/micromamba/envs/$CONDA_ENV

# Verificar que FastQC esté disponible
if ! command -v fastqc &> /dev/null; then
    echo "ERROR: FastQC no está disponible en el ambiente $CONDA_ENV"
    exit 1
fi

# Crear directorio de salida
mkdir -p "$OUTPUT_DIR"

# Muestras a procesar
SAMPLES=("CT_FKDN25H000391-1A_22NWHGLT4_L5" "ST_FKDN25H000392-1A_22NWHGLT4_L5")

echo "Procesando FastQC para todas las muestras..."

# Procesar todas las muestras en paralelo
for sample in "${SAMPLES[@]}"; do
    echo "Procesando muestra: $sample"
    
    # Verificar que existan los archivos
    if [ ! -f "$READS_DIR/${sample}_1.fq.gz" ] || [ ! -f "$READS_DIR/${sample}_2.fq.gz" ]; then
        echo "ERROR: No se encuentran los archivos para $sample"
        continue
    fi
    
    # Ejecutar FastQC para forward y reverse
    fastqc "$READS_DIR/${sample}_1.fq.gz" "$READS_DIR/${sample}_2.fq.gz" \
           --outdir "$OUTPUT_DIR" \
           --threads 2 \
           --quiet
    
    echo "✓ FastQC completado para $sample"
done

echo "✓ FastQC inicial completado para todas las muestras"
echo "Resultados guardados en: $OUTPUT_DIR"

# Generar reporte resumen
echo ""
echo "=== RESUMEN FastQC INICIAL ==="
echo "Archivos generados:"
ls -la "$OUTPUT_DIR"/*.html 2>/dev/null || echo "No se encontraron archivos HTML"

micromamba deactivate

