#!/bin/bash

# Script para anotación taxonómica con GTDBtk
# Autor: Script generado para análisis metagenómico
# Fecha: $(date)

echo "=== Iniciando anotación taxonómica con GTDBtk ==="

# Configuración
BINNING_DIR="/home_local/camda/shaday/barbara/binning"
OUTPUT_DIR="/home_local/camda/shaday/barbara/annotation"
CONDA_ENV="gtdbtk-2.1.1"

# Activar ambiente micromamba
echo "Activando ambiente micromamba: $CONDA_ENV"
eval "$(micromamba shell hook --shell bash)"
micromamba activate /home_local/camda/micromamba/envs/$CONDA_ENV

# Verificar que GTDBtk esté disponible
if ! command -v gtdbtk &> /dev/null; then
    echo "ERROR: GTDBtk no está disponible en el ambiente $CONDA_ENV"
    exit 1
fi

# Crear directorios de salida
mkdir -p "$OUTPUT_DIR/gtdbtk"

# Buscar bins refinados de DasTool
DASTOOL_BINS_DIR="$BINNING_DIR/dastool/DasTool_DASTool_bins"
FINAL_BINS_DIR="$BINNING_DIR/final_bins"

# Determinar directorio de bins a usar
BINS_DIR=""
if [ -d "$FINAL_BINS_DIR" ] && [ "$(ls -A "$FINAL_BINS_DIR" 2>/dev/null)" ]; then
    BINS_DIR="$FINAL_BINS_DIR"
    echo "Usando bins refinados de: $BINS_DIR"
elif [ -d "$DASTOOL_BINS_DIR" ] && [ "$(ls -A "$DASTOOL_BINS_DIR" 2>/dev/null)" ]; then
    BINS_DIR="$DASTOOL_BINS_DIR"
    echo "Usando bins de DasTool: $BINS_DIR"
else
    # Buscar bins de métodos individuales
    echo "No se encontraron bins refinados, buscando bins individuales..."
    
    # Crear directorio temporal con todos los bins disponibles
    TEMP_BINS_DIR="$OUTPUT_DIR/temp_all_bins"
    mkdir -p "$TEMP_BINS_DIR"
    
    # Copiar bins de MetaBAT2
    if [ -d "$BINNING_DIR/metabat2" ]; then
        for bin in "$BINNING_DIR/metabat2"/bin.*.fa; do
            if [ -f "$bin" ]; then
                cp "$bin" "$TEMP_BINS_DIR/"
                echo "  Copiado: $(basename "$bin")"
            fi
        done
    fi
    
    # Copiar bins de MaxBin2
    if [ -d "$BINNING_DIR/maxbin2" ]; then
        for bin in "$BINNING_DIR/maxbin2"/bin.*.fasta; do
            if [ -f "$bin" ]; then
                # Renombrar extensión para consistencia
                new_name=$(basename "$bin" .fasta).fa
                cp "$bin" "$TEMP_BINS_DIR/$new_name"
                echo "  Copiado: $new_name"
            fi
        done
    fi
    
    # Copiar bins de CONCOCT
    if [ -d "$BINNING_DIR/concoct/fasta_bins" ]; then
        for bin in "$BINNING_DIR/concoct/fasta_bins"/*.fa; do
            if [ -f "$bin" ]; then
                cp "$bin" "$TEMP_BINS_DIR/"
                echo "  Copiado: $(basename "$bin")"
            fi
        done
    fi
    
    if [ "$(ls -A "$TEMP_BINS_DIR" 2>/dev/null)" ]; then
        BINS_DIR="$TEMP_BINS_DIR"
        echo "Usando bins combinados de: $BINS_DIR"
    else
        echo "ERROR: No se encontraron bins para anotar"
        exit 1
    fi
fi

# Contar bins disponibles
NUM_BINS=$(ls "$BINS_DIR"/*.fa 2>/dev/null | wc -l)
echo "Número de bins a anotar: $NUM_BINS"

if [ $NUM_BINS -eq 0 ]; then
    echo "ERROR: No se encontraron archivos .fa en $BINS_DIR"
    exit 1
fi

# Mostrar bins a procesar
echo "Bins a procesar:"
ls "$BINS_DIR"/*.fa | while read bin; do
    bin_name=$(basename "$bin")
    bin_size=$(grep -v "^>" "$bin" | tr -d '\n' | wc -c)
    num_contigs=$(grep -c "^>" "$bin")
    echo "  $bin_name: ${bin_size} bp, ${num_contigs} contigs"
done

# Verificar base de datos de GTDBtk
echo ""
echo "Verificando base de datos de GTDBtk..."
if [ -z "$GTDBTK_DATA_PATH" ]; then
    echo "ADVERTENCIA: Variable GTDBTK_DATA_PATH no está definida"
    echo "Intentando usar ubicación por defecto..."
    export GTDBTK_DATA_PATH="/home_local/compartida/gtdbtk_data"
fi

echo "GTDBTK_DATA_PATH: $GTDBTK_DATA_PATH"

if [ ! -d "$GTDBTK_DATA_PATH" ]; then
    echo "ERROR: Base de datos de GTDBtk no encontrada en $GTDBTK_DATA_PATH"
    echo "Por favor, configura la variable GTDBTK_DATA_PATH correctamente"
    exit 1
fi

# Ejecutar GTDBtk classify_wf
echo ""
echo "Ejecutando GTDBtk classify_wf..."
echo "Esto puede tomar varias horas dependiendo del número de bins..."

gtdbtk classify_wf --genome_dir "$BINS_DIR" \
                   --out_dir "$OUTPUT_DIR/gtdbtk" \
                   --cpus 8 \
                   --extension fa \
                   --skip_ani_screen

if [ $? -eq 0 ]; then
    echo "✓ GTDBtk completado exitosamente"
    
    # Mostrar archivos generados
    echo ""
    echo "=== ARCHIVOS GENERADOS ==="
    ls -la "$OUTPUT_DIR/gtdbtk"/ 2>/dev/null || echo "No se encontraron archivos de salida"
    
    # Mostrar resumen de clasificación
    SUMMARY_FILE="$OUTPUT_DIR/gtdbtk/gtdbtk.bac120.summary.tsv"
    if [ -f "$SUMMARY_FILE" ]; then
        echo ""
        echo "=== RESUMEN DE CLASIFICACIÓN BACTERIANA ==="
        echo "Bins clasificados:"
        awk -F'\t' 'NR>1 {print $1"\t"$2}' "$SUMMARY_FILE" | head -20
        
        CLASSIFIED_BACTERIA=$(awk -F'\t' 'NR>1' "$SUMMARY_FILE" | wc -l)
        echo "Total de bins bacterianos clasificados: $CLASSIFIED_BACTERIA"
    fi
    
    SUMMARY_FILE_AR="$OUTPUT_DIR/gtdbtk/gtdbtk.ar122.summary.tsv"
    if [ -f "$SUMMARY_FILE_AR" ]; then
        echo ""
        echo "=== RESUMEN DE CLASIFICACIÓN ARQUEANA ==="
        echo "Bins clasificados:"
        awk -F'\t' 'NR>1 {print $1"\t"$2}' "$SUMMARY_FILE_AR" | head -20
        
        CLASSIFIED_ARCHAEA=$(awk -F'\t' 'NR>1' "$SUMMARY_FILE_AR" | wc -l)
        echo "Total de bins arqueanos clasificados: $CLASSIFIED_ARCHAEA"
    fi
    
    # Generar reporte combinado
    echo ""
    echo "Generando reporte combinado..."
    COMBINED_REPORT="$OUTPUT_DIR/gtdbtk_combined_report.txt"
    
    echo "=== REPORTE COMBINADO GTDBtk ===" > "$COMBINED_REPORT"
    echo "Fecha: $(date)" >> "$COMBINED_REPORT"
    echo "Bins procesados: $NUM_BINS" >> "$COMBINED_REPORT"
    echo "" >> "$COMBINED_REPORT"
    
    if [ -f "$SUMMARY_FILE" ]; then
        echo "=== CLASIFICACIÓN BACTERIANA ===" >> "$COMBINED_REPORT"
        cat "$SUMMARY_FILE" >> "$COMBINED_REPORT"
        echo "" >> "$COMBINED_REPORT"
    fi
    
    if [ -f "$SUMMARY_FILE_AR" ]; then
        echo "=== CLASIFICACIÓN ARQUEANA ===" >> "$COMBINED_REPORT"
        cat "$SUMMARY_FILE_AR" >> "$COMBINED_REPORT"
        echo "" >> "$COMBINED_REPORT"
    fi
    
    echo "✓ Reporte combinado generado: $COMBINED_REPORT"
    
    # Limpiar directorio temporal si se creó
    if [ "$BINS_DIR" = "$TEMP_BINS_DIR" ]; then
        echo "Limpiando directorio temporal..."
        rm -rf "$TEMP_BINS_DIR"
    fi
    
else
    echo "✗ Error en GTDBtk"
    
    # Mostrar posibles errores
    echo ""
    echo "Verificando posibles problemas..."
    echo "1. Verificar que la base de datos de GTDBtk esté correctamente instalada"
    echo "2. Verificar que los bins tengan el formato correcto"
    echo "3. Verificar que haya suficiente espacio en disco"
    echo "4. Verificar logs de GTDBtk en $OUTPUT_DIR/gtdbtk/"
    
    # Mostrar logs si existen
    if [ -f "$OUTPUT_DIR/gtdbtk/gtdbtk.log" ]; then
        echo ""
        echo "Últimas líneas del log de GTDBtk:"
        tail -20 "$OUTPUT_DIR/gtdbtk/gtdbtk.log"
    fi
fi

echo ""
echo "✓ Proceso de anotación con GTDBtk completado"
echo "Resultados guardados en: $OUTPUT_DIR/gtdbtk"

micromamba deactivate

