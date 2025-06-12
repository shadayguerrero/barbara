#!/bin/bash

# Script para refinamiento de abundancias con Bracken
# Autor: Script generado para análisis metagenómico
# Fecha: $(date)

echo "=== Iniciando refinamiento de abundancias con Bracken ==="

# Configuración
KRAKEN_DIR="/home_local/camda/shaday/barbara/taxonomy/kraken_output"
OUTPUT_DIR="/home_local/camda/shaday/barbara/taxonomy/bracken_output"
KRAKEN_DB="/home_local/compartida/camda2024/k2_pluspfp_20250402"
CONDA_ENV="metagenomics"

# Activar ambiente micromamba
echo "Activando ambiente micromamba: $CONDA_ENV"
eval "$(micromamba shell hook --shell bash)"
micromamba activate /home_local/camda/micromamba/envs/$CONDA_ENV

# Verificar que Bracken esté disponible
if ! command -v bracken &> /dev/null; then
    echo "ERROR: Bracken no está disponible en el ambiente $CONDA_ENV"
    exit 1
fi

# Verificar base de datos
if [ ! -d "$KRAKEN_DB" ]; then
    echo "ERROR: Base de datos de Kraken2 no encontrada: $KRAKEN_DB"
    exit 1
fi

# Crear directorio de salida
mkdir -p "$OUTPUT_DIR"

# Verificar archivos de Kraken2
echo "Verificando archivos de Kraken2..."
KRAKEN_REPORTS=$(find "$KRAKEN_DIR" -name "*_kraken2_report.txt" 2>/dev/null)

if [ -z "$KRAKEN_REPORTS" ]; then
    echo "ERROR: No se encontraron reportes de Kraken2 en $KRAKEN_DIR"
    echo "Asegúrate de haber ejecutado Kraken2 primero"
    exit 1
fi

echo "Reportes de Kraken2 encontrados:"
echo "$KRAKEN_REPORTS"

# Muestras a procesar
SAMPLES=("CT_FKDN25H000391-1A_22NWHGLT4_L5" "ST_FKDN25H000392-1A_22NWHGLT4_L5")

echo ""
echo "Procesando Bracken para todas las muestras..."

# Niveles taxonómicos a procesar
LEVELS=("S" "G" "F" "O" "C" "P")
LEVEL_NAMES=("Species" "Genus" "Family" "Order" "Class" "Phylum")

# Procesar cada muestra
for sample in "${SAMPLES[@]}"; do
    echo ""
    echo "Procesando muestra: $sample"
    
    # Buscar reporte de Kraken2 para esta muestra
    KRAKEN_REPORT=$(find "$KRAKEN_DIR" -name "${sample}_kraken2_report.txt" 2>/dev/null | head -1)
    
    if [ ! -f "$KRAKEN_REPORT" ]; then
        echo "ERROR: No se encontró el reporte de Kraken2 para $sample"
        echo "Buscado: ${sample}_kraken2_report.txt"
        continue
    fi
    
    echo "  Reporte Kraken2: $(basename "$KRAKEN_REPORT")"
    
    # Crear directorio para esta muestra
    SAMPLE_OUTPUT_DIR="$OUTPUT_DIR/$sample"
    mkdir -p "$SAMPLE_OUTPUT_DIR"
    
    # Procesar cada nivel taxonómico
    for i in "${!LEVELS[@]}"; do
        level="${LEVELS[$i]}"
        level_name="${LEVEL_NAMES[$i]}"
        
        echo "    Procesando nivel: $level_name ($level)"
        
        # Definir archivos de salida
        BRACKEN_OUTPUT="$SAMPLE_OUTPUT_DIR/${sample}_bracken_${level}.txt"
        BRACKEN_REPORT="$SAMPLE_OUTPUT_DIR/${sample}_bracken_${level}_report.txt"
        
        # Ejecutar Bracken
        bracken -d "$KRAKEN_DB" \
                -i "$KRAKEN_REPORT" \
                -o "$BRACKEN_OUTPUT" \
                -w "$BRACKEN_REPORT" \
                -r 150 \
                -l "$level" \
                -t 10
        
        if [ $? -eq 0 ]; then
            echo "      ✓ Bracken completado para nivel $level_name"
            
            # Generar estadísticas básicas
            if [ -f "$BRACKEN_OUTPUT" ]; then
                TOTAL_READS=$(awk 'NR>1 {sum+=$5} END {print sum}' "$BRACKEN_OUTPUT")
                NUM_TAXA=$(awk 'NR>1' "$BRACKEN_OUTPUT" | wc -l)
                echo "        Total reads asignados: $TOTAL_READS"
                echo "        Número de taxa: $NUM_TAXA"
            fi
        else
            echo "      ✗ Error en Bracken para nivel $level_name"
        fi
    done
    
    echo "  ✓ Bracken completado para $sample"
done

echo ""
echo "✓ Bracken completado para todas las muestras"
echo "Resultados guardados en: $OUTPUT_DIR"

# Generar resumen combinado
echo ""
echo "Generando resumen combinado..."
SUMMARY_FILE="$OUTPUT_DIR/bracken_summary.txt"

echo "=== RESUMEN DE ABUNDANCIAS BRACKEN ===" > "$SUMMARY_FILE"
echo "Fecha: $(date)" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

for sample in "${SAMPLES[@]}"; do
    SAMPLE_OUTPUT_DIR="$OUTPUT_DIR/$sample"
    
    if [ -d "$SAMPLE_OUTPUT_DIR" ]; then
        echo "Muestra: $sample" >> "$SUMMARY_FILE"
        echo "----------------------------------------" >> "$SUMMARY_FILE"
        
        for i in "${!LEVELS[@]}"; do
            level="${LEVELS[$i]}"
            level_name="${LEVEL_NAMES[$i]}"
            
            BRACKEN_OUTPUT="$SAMPLE_OUTPUT_DIR/${sample}_bracken_${level}.txt"
            
            if [ -f "$BRACKEN_OUTPUT" ]; then
                echo "" >> "$SUMMARY_FILE"
                echo "Nivel $level_name ($level) - Top 10:" >> "$SUMMARY_FILE"
                echo "Nombre | %Abundancia | Reads" >> "$SUMMARY_FILE"
                
                # Top 10 más abundantes
                awk 'NR>1 {printf "%-30s | %8.4f | %8s\n", $1, $6, $5}' "$BRACKEN_OUTPUT" | \
                sort -k3 -nr | head -10 >> "$SUMMARY_FILE"
            fi
        done
        
        echo "" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
    fi
done

echo "✓ Resumen generado: $SUMMARY_FILE"

# Generar archivos combinados para análisis comparativo
echo ""
echo "Generando archivos combinados para análisis comparativo..."

for i in "${!LEVELS[@]}"; do
    level="${LEVELS[$i]}"
    level_name="${LEVEL_NAMES[$i]}"
    
    COMBINED_FILE="$OUTPUT_DIR/combined_bracken_${level}.txt"
    
    echo "Generando archivo combinado para nivel $level_name..."
    
    # Crear header
    echo -e "name\ttaxonomy_id\ttaxonomy_lvl\tkraken_assigned_reads\tadded_reads\tnew_est_reads\tfraction_total_reads\tCT_abundance\tST_abundance" > "$COMBINED_FILE"
    
    # Usar Python para combinar archivos
    python3 << EOF
import os
import pandas as pd
from collections import defaultdict

level = "$level"
output_dir = "$OUTPUT_DIR"
samples = ["CT_FKDN25H000391-1A_22NWHGLT4_L5", "ST_FKDN25H000392-1A_22NWHGLT4_L5"]
combined_file = "$COMBINED_FILE"

# Diccionario para almacenar datos
all_taxa = {}
sample_data = {}

# Leer datos de cada muestra
for sample in samples:
    bracken_file = os.path.join(output_dir, sample, f"{sample}_bracken_{level}.txt")
    
    if os.path.exists(bracken_file):
        print(f"Procesando {bracken_file}")
        
        with open(bracken_file, 'r') as f:
            lines = f.readlines()
            
        # Saltar header
        for line in lines[1:]:
            parts = line.strip().split('\t')
            if len(parts) >= 7:
                name = parts[0]
                taxonomy_id = parts[1]
                taxonomy_lvl = parts[2]
                kraken_reads = parts[3]
                added_reads = parts[4]
                new_est_reads = parts[5]
                fraction = parts[6]
                
                # Almacenar información del taxón
                if name not in all_taxa:
                    all_taxa[name] = {
                        'taxonomy_id': taxonomy_id,
                        'taxonomy_lvl': taxonomy_lvl,
                        'kraken_assigned_reads': kraken_reads,
                        'added_reads': added_reads,
                        'new_est_reads': new_est_reads,
                        'fraction_total_reads': fraction
                    }
                
                # Almacenar abundancia por muestra
                if name not in sample_data:
                    sample_data[name] = {}
                sample_data[name][sample] = float(fraction)

# Escribir archivo combinado
with open(combined_file, 'w') as f:
    f.write("name\ttaxonomy_id\ttaxonomy_lvl\tkraken_assigned_reads\tadded_reads\tnew_est_reads\tfraction_total_reads\tCT_abundance\tST_abundance\n")
    
    for name in sorted(all_taxa.keys()):
        taxa_info = all_taxa[name]
        ct_abundance = sample_data.get(name, {}).get("CT_FKDN25H000391-1A_22NWHGLT4_L5", 0.0)
        st_abundance = sample_data.get(name, {}).get("ST_FKDN25H000392-1A_22NWHGLT4_L5", 0.0)
        
        f.write(f"{name}\t{taxa_info['taxonomy_id']}\t{taxa_info['taxonomy_lvl']}\t{taxa_info['kraken_assigned_reads']}\t{taxa_info['added_reads']}\t{taxa_info['new_est_reads']}\t{taxa_info['fraction_total_reads']}\t{ct_abundance:.6f}\t{st_abundance:.6f}\n")

print(f"Archivo combinado generado: {combined_file}")
EOF
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Archivo combinado generado: $(basename "$COMBINED_FILE")"
    else
        echo "  ✗ Error generando archivo combinado para nivel $level_name"
    fi
done

# Mostrar estadísticas finales
echo ""
echo "=== ARCHIVOS BRACKEN GENERADOS ==="
echo "Archivos individuales por muestra:"
for sample in "${SAMPLES[@]}"; do
    SAMPLE_DIR="$OUTPUT_DIR/$sample"
    if [ -d "$SAMPLE_DIR" ]; then
        echo "  $sample:"
        ls "$SAMPLE_DIR"/*.txt 2>/dev/null | while read file; do
            echo "    - $(basename "$file")"
        done
    fi
done

echo ""
echo "Archivos combinados:"
ls "$OUTPUT_DIR"/combined_bracken_*.txt 2>/dev/null | while read file; do
    echo "  - $(basename "$file")"
done

echo ""
echo "Archivos de resumen:"
ls "$OUTPUT_DIR"/*.txt 2>/dev/null | grep -v combined | while read file; do
    echo "  - $(basename "$file")"
done

# Mostrar top 5 especies más abundantes por muestra
echo ""
echo "=== TOP 5 ESPECIES MÁS ABUNDANTES ==="
for sample in "${SAMPLES[@]}"; do
    SPECIES_FILE="$OUTPUT_DIR/$sample/${sample}_bracken_S.txt"
    if [ -f "$SPECIES_FILE" ]; then
        echo ""
        echo "Muestra: $sample"
        echo "Especie | %Abundancia | Reads"
        awk 'NR>1 {printf "%-40s | %8.4f | %8s\n", $1, $6, $5}' "$SPECIES_FILE" | \
        sort -k3 -nr | head -5
    fi
done

micromamba deactivate

