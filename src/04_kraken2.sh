#!/bin/bash

# Script para clasificación taxonómica con Kraken2
# Autor: Script generado para análisis metagenómico
# Fecha: $(date)

echo "=== Iniciando clasificación taxonómica con Kraken2 ==="

# Configuración
TRIMMED_DIR="/home_local/camda/shaday/barbara/trim/trimmed_reads"
OUTPUT_DIR="/home_local/camda/shaday/barbara/taxonomy/kraken_output"
KRAKEN_DB="/home_local/compartida/camda2024/k2_pluspfp_20250402"
CONDA_ENV="metagenomics"

# Activar ambiente micromamba
echo "Activando ambiente micromamba: $CONDA_ENV"
eval "$(micromamba shell hook --shell bash)"
micromamba activate /home_local/camda/micromamba/envs/$CONDA_ENV

# Verificar que Kraken2 esté disponible
if ! command -v kraken2 &> /dev/null; then
    echo "ERROR: Kraken2 no está disponible en el ambiente $CONDA_ENV"
    exit 1
fi

# Verificar base de datos
if [ ! -d "$KRAKEN_DB" ]; then
    echo "ERROR: Base de datos de Kraken2 no encontrada: $KRAKEN_DB"
    exit 1
fi

# Crear directorio de salida
mkdir -p "$OUTPUT_DIR"

# Muestras a procesar
SAMPLES=("CT_FKDN25H000391-1A_22NWHGLT4_L5" "ST_FKDN25H000392-1A_22NWHGLT4_L5")

echo "Procesando clasificación taxonómica para todas las muestras..."

# Procesar cada muestra
for sample in "${SAMPLES[@]}"; do
    echo "Procesando muestra: $sample"
    
    # Buscar archivos trimmed para esta muestra
    R1_TRIMMED=$(find "$TRIMMED_DIR" -name "*${sample}*1*val_1.fq.gz" 2>/dev/null | head -1)
    R2_TRIMMED=$(find "$TRIMMED_DIR" -name "*${sample}*2*val_2.fq.gz" 2>/dev/null | head -1)
    
    if [ ! -f "$R1_TRIMMED" ] || [ ! -f "$R2_TRIMMED" ]; then
        echo "ERROR: No se encuentran los archivos trimmed para $sample"
        echo "R1: $R1_TRIMMED"
        echo "R2: $R2_TRIMMED"
        continue
    fi
    
    echo "  R1: $(basename "$R1_TRIMMED")"
    echo "  R2: $(basename "$R2_TRIMMED")"
    
    # Definir archivos de salida
    KRAKEN_OUTPUT="$OUTPUT_DIR/${sample}_kraken2.out"
    KRAKEN_REPORT="$OUTPUT_DIR/${sample}_kraken2_report.txt"
    
    # Ejecutar Kraken2
    echo "  Ejecutando Kraken2..."
    kraken2 --db "$KRAKEN_DB" \
            --paired \
            --threads 8 \
            --output "$KRAKEN_OUTPUT" \
            --report "$KRAKEN_REPORT" \
            --gzip-compressed \
            "$R1_TRIMMED" "$R2_TRIMMED"
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Kraken2 completado para $sample"
        
        # Generar estadísticas básicas
        TOTAL_READS=$(wc -l < "$KRAKEN_OUTPUT")
        CLASSIFIED_READS=$(grep -c "^C" "$KRAKEN_OUTPUT")
        UNCLASSIFIED_READS=$(grep -c "^U" "$KRAKEN_OUTPUT")
        
        echo "    Total reads: $TOTAL_READS"
        echo "    Clasificados: $CLASSIFIED_READS"
        echo "    No clasificados: $UNCLASSIFIED_READS"
        
        # Calcular porcentaje de clasificación
        if [ $TOTAL_READS -gt 0 ]; then
            CLASSIFICATION_RATE=$(echo "scale=2; $CLASSIFIED_READS * 100 / $TOTAL_READS" | bc)
            echo "    Tasa de clasificación: ${CLASSIFICATION_RATE}%"
        fi
    else
        echo "  ✗ Error en Kraken2 para $sample"
    fi
    
    echo ""
done

echo "✓ Clasificación taxonómica completada para todas las muestras"
echo "Resultados guardados en: $OUTPUT_DIR"

# Generar reporte resumen
echo ""
echo "=== RESUMEN KRAKEN2 ==="
echo "Archivos generados:"
ls -la "$OUTPUT_DIR"/*.out 2>/dev/null || echo "No se encontraron archivos .out"
ls -la "$OUTPUT_DIR"/*.txt 2>/dev/null || echo "No se encontraron archivos de reporte"

# Mostrar top 10 taxones más abundantes para cada muestra
echo ""
echo "=== TOP 10 TAXONES MÁS ABUNDANTES ==="
for sample in "${SAMPLES[@]}"; do
    REPORT_FILE="$OUTPUT_DIR/${sample}_kraken2_report.txt"
    if [ -f "$REPORT_FILE" ]; then
        echo "Muestra: $sample"
        echo "Rank | %Reads | Reads | Taxon"
        head -11 "$REPORT_FILE" | tail -10 | awk '{printf "%-4s | %6.2f | %8s | %s\n", $4, $1, $2, $6}'
        echo ""
    fi
done

micromamba deactivate

