#!/bin/bash

# Script para FastQC después del trimming
# Autor: Script generado para análisis metagenómico
# Fecha: $(date)

echo "=== Iniciando FastQC después del trimming ==="

# Configuración
TRIMMED_DIR="/home_local/camda/shaday/barbara/trim/trimmed_reads"
OUTPUT_DIR="/home_local/camda/shaday/barbara/trim/fastqc_after"
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

# Buscar todos los archivos trimmed
echo "Buscando archivos trimmed..."
TRIMMED_FILES=$(find "$TRIMMED_DIR" -name "*val_*.fq.gz" 2>/dev/null)

if [ -z "$TRIMMED_FILES" ]; then
    echo "ERROR: No se encontraron archivos trimmed en $TRIMMED_DIR"
    echo "Asegúrate de haber ejecutado TrimGalore primero"
    exit 1
fi

echo "Archivos trimmed encontrados:"
echo "$TRIMMED_FILES"

# Ejecutar FastQC en todos los archivos trimmed
echo ""
echo "Ejecutando FastQC en archivos trimmed..."
fastqc $TRIMMED_FILES \
       --outdir "$OUTPUT_DIR" \
       --threads 4 \
       --quiet

echo "✓ FastQC post-trimming completado"
echo "Resultados guardados en: $OUTPUT_DIR"

# Generar reporte resumen
echo ""
echo "=== RESUMEN FastQC POST-TRIMMING ==="
echo "Archivos HTML generados:"
ls -la "$OUTPUT_DIR"/*.html 2>/dev/null || echo "No se encontraron archivos HTML"

echo ""
echo "=== COMPARACIÓN ANTES/DESPUÉS ==="
BEFORE_DIR="/home_local/camda/shaday/barbara/trim/fastqc_before"
echo "FastQC antes del trimming: $BEFORE_DIR"
echo "FastQC después del trimming: $OUTPUT_DIR"

micromamba deactivate

