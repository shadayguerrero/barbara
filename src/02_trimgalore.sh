#!/bin/bash

# Script para TrimGalore
# Autor: Script generado para análisis metagenómico
# Fecha: $(date)

echo "=== Iniciando TrimGalore ==="

# Configuración
READS_DIR="/home_local/camda/shaday/barbara/reads"
OUTPUT_DIR="/home_local/camda/shaday/barbara/trim/trimmed_reads"
CONDA_ENV="trimgalore"

# Activar ambiente micromamba
echo "Activando ambiente micromamba: $CONDA_ENV"
eval "$(micromamba shell hook --shell bash)"
micromamba activate /home_local/camda/micromamba/envs/$CONDA_ENV

# Verificar que TrimGalore esté disponible
if ! command -v trim_galore &> /dev/null; then
    echo "ERROR: TrimGalore no está disponible en el ambiente $CONDA_ENV"
    exit 1
fi

# Crear directorio de salida
mkdir -p "$OUTPUT_DIR"

# Muestras a procesar
SAMPLES=("CT_FKDN25H000391-1A_22NWHGLT4_L5" "ST_FKDN25H000392-1A_22NWHGLT4_L5")

echo "Procesando TrimGalore para todas las muestras..."

# Procesar cada muestra
for sample in "${SAMPLES[@]}"; do
    echo "Procesando muestra: $sample"
    
    # Verificar que existan los archivos
    if [ ! -f "$READS_DIR/${sample}_1.fq.gz" ] || [ ! -f "$READS_DIR/${sample}_2.fq.gz" ]; then
        echo "ERROR: No se encuentran los archivos para $sample"
        continue
    fi
    
    # Ejecutar TrimGalore
    trim_galore --paired \
                --quality 20 \
                --length 50 \
                --stringency 3 \
                --fastqc \
                --cores 4 \
                --output_dir "$OUTPUT_DIR" \
                "$READS_DIR/${sample}_1.fq.gz" \
                "$READS_DIR/${sample}_2.fq.gz"
    
    echo "✓ TrimGalore completado para $sample"
done

echo "✓ TrimGalore completado para todas las muestras"
echo "Archivos trimmed guardados en: $OUTPUT_DIR"

# Mostrar archivos generados
echo ""
echo "=== ARCHIVOS GENERADOS ==="
ls -la "$OUTPUT_DIR"/*.fq.gz 2>/dev/null || echo "No se encontraron archivos trimmed"
ls -la "$OUTPUT_DIR"/*.html 2>/dev/null || echo "No se encontraron reportes FastQC"

# Generar reporte de estadísticas
echo ""
echo "=== ESTADÍSTICAS DE TRIMMING ==="
for sample in "${SAMPLES[@]}"; do
    echo "Muestra: $sample"
    
    # Buscar archivos trimmed
    R1_TRIMMED=$(find "$OUTPUT_DIR" -name "*${sample}*1*val_1.fq.gz" 2>/dev/null | head -1)
    R2_TRIMMED=$(find "$OUTPUT_DIR" -name "*${sample}*2*val_2.fq.gz" 2>/dev/null | head -1)
    
    if [ -f "$R1_TRIMMED" ] && [ -f "$R2_TRIMMED" ]; then
        echo "  ✓ R1 trimmed: $(basename "$R1_TRIMMED")"
        echo "  ✓ R2 trimmed: $(basename "$R2_TRIMMED")"
    else
        echo "  ✗ Archivos trimmed no encontrados"
    fi
    echo ""
done

micromamba deactivate

