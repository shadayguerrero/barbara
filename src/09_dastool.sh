#!/bin/bash

# Script para DasTool - refinamiento de bins
# Autor: Script generado para análisis metagenómico
# Fecha: $(date)

echo "=== Iniciando DasTool para refinamiento de bins ==="

# Configuración
ASSEMBLY_DIR="/home_local/camda/shaday/barbara/assembly"
BINNING_DIR="/home_local/camda/shaday/barbara/binning"
OUTPUT_DIR="/home_local/camda/shaday/barbara/binning/dastool"
CONDA_ENV="binning_env"

# Activar ambiente micromamba
echo "Activando ambiente micromamba: $CONDA_ENV"
eval "$(micromamba shell hook --shell bash)"
micromamba activate /home_local/camda/micromamba/envs/$CONDA_ENV

# Verificar que DasTool esté disponible
if ! command -v DAS_Tool &> /dev/null; then
    echo "ERROR: DasTool no está disponible en el ambiente $CONDA_ENV"
    exit 1
fi

# Crear directorio de salida
mkdir -p "$OUTPUT_DIR"

# Verificar archivo de contigs
CONTIGS_FILE="$ASSEMBLY_DIR/final_contigs.fa"
if [ ! -f "$CONTIGS_FILE" ]; then
    CONTIGS_FILE="$ASSEMBLY_DIR/megahit_output/final.contigs.fa"
fi

if [ ! -f "$CONTIGS_FILE" ]; then
    echo "ERROR: No se encontró el archivo de contigs"
    exit 1
fi

echo "Archivo de contigs: $CONTIGS_FILE"

# Verificar archivos de scaffolds2bin
METABAT_SCAFFOLDS="$BINNING_DIR/metabat2_scaffolds2bin.tsv"
MAXBIN_SCAFFOLDS="$BINNING_DIR/maxbin2_scaffolds2bin.tsv"
CONCOCT_SCAFFOLDS="$BINNING_DIR/concoct_scaffolds2bin.tsv"

# Construir lista de archivos de entrada para DasTool
SCAFFOLDS_FILES=""
LABELS=""

if [ -f "$METABAT_SCAFFOLDS" ] && [ -s "$METABAT_SCAFFOLDS" ]; then
    SCAFFOLDS_FILES="$SCAFFOLDS_FILES,$METABAT_SCAFFOLDS"
    LABELS="$LABELS,metabat2"
    echo "✓ MetaBAT2 scaffolds2bin encontrado"
else
    echo "⚠ MetaBAT2 scaffolds2bin no encontrado o vacío"
fi

if [ -f "$MAXBIN_SCAFFOLDS" ] && [ -s "$MAXBIN_SCAFFOLDS" ]; then
    SCAFFOLDS_FILES="$SCAFFOLDS_FILES,$MAXBIN_SCAFFOLDS"
    LABELS="$LABELS,maxbin2"
    echo "✓ MaxBin2 scaffolds2bin encontrado"
else
    echo "⚠ MaxBin2 scaffolds2bin no encontrado o vacío"
fi

if [ -f "$CONCOCT_SCAFFOLDS" ] && [ -s "$CONCOCT_SCAFFOLDS" ]; then
    SCAFFOLDS_FILES="$SCAFFOLDS_FILES,$CONCOCT_SCAFFOLDS"
    LABELS="$LABELS,concoct"
    echo "✓ CONCOCT scaffolds2bin encontrado"
else
    echo "⚠ CONCOCT scaffolds2bin no encontrado o vacío"
fi

# Remover comas iniciales
SCAFFOLDS_FILES=$(echo "$SCAFFOLDS_FILES" | sed 's/^,//')
LABELS=$(echo "$LABELS" | sed 's/^,//')

if [ -z "$SCAFFOLDS_FILES" ]; then
    echo "ERROR: No se encontraron archivos scaffolds2bin válidos"
    echo "Asegúrate de haber ejecutado el script de binning primero"
    exit 1
fi

echo "Archivos de entrada: $SCAFFOLDS_FILES"
echo "Etiquetas: $LABELS"

# Ejecutar DasTool
echo ""
echo "Ejecutando DasTool..."
echo "Esto puede tomar tiempo dependiendo del número de bins..."

DAS_Tool -i "$SCAFFOLDS_FILES" \
         -l "$LABELS" \
         -c "$CONTIGS_FILE" \
         -o "$OUTPUT_DIR/DasTool" \
         --search_engine diamond \
         --threads 8 \
         --score_threshold 0.5 \
         --duplicate_penalty 0.6 \
         --megabin_penalty 0.5 \
         --write_bins 1 \
         --write_bin_evals 1

if [ $? -eq 0 ]; then
    echo "✓ DasTool completado exitosamente"
    
    # Contar bins refinados
    DASTOOL_BINS_DIR="$OUTPUT_DIR/DasTool_DASTool_bins"
    if [ -d "$DASTOOL_BINS_DIR" ]; then
        REFINED_BINS=$(ls "$DASTOOL_BINS_DIR"/*.fa 2>/dev/null | wc -l)
        echo "  Bins refinados generados: $REFINED_BINS"
        
        if [ $REFINED_BINS -gt 0 ]; then
            echo "  Bins refinados:"
            ls "$DASTOOL_BINS_DIR"/*.fa | while read bin; do
                bin_name=$(basename "$bin")
                bin_size=$(grep -v "^>" "$bin" | tr -d '\n' | wc -c)
                echo "    $bin_name: ${bin_size} bp"
            done
        fi
    else
        echo "  No se encontró directorio de bins refinados"
    fi
    
    # Mostrar archivos generados
    echo ""
    echo "=== ARCHIVOS GENERADOS POR DASTOOL ==="
    ls -la "$OUTPUT_DIR"/DasTool* 2>/dev/null || echo "No se encontraron archivos de DasTool"
    
    # Mostrar resumen de evaluación si existe
    EVAL_FILE="$OUTPUT_DIR/DasTool_DASTool_summary.txt"
    if [ -f "$EVAL_FILE" ]; then
        echo ""
        echo "=== RESUMEN DE EVALUACIÓN ==="
        cat "$EVAL_FILE"
    fi
    
    # Crear enlaces simbólicos para fácil acceso
    if [ -d "$DASTOOL_BINS_DIR" ] && [ $REFINED_BINS -gt 0 ]; then
        FINAL_BINS_DIR="$BINNING_DIR/final_bins"
        mkdir -p "$FINAL_BINS_DIR"
        
        echo ""
        echo "Creando enlaces simbólicos en $FINAL_BINS_DIR..."
        for bin in "$DASTOOL_BINS_DIR"/*.fa; do
            if [ -f "$bin" ]; then
                ln -sf "$bin" "$FINAL_BINS_DIR/"
                echo "  ✓ $(basename "$bin")"
            fi
        done
    fi
    
else
    echo "✗ Error en DasTool"
    
    # Mostrar posibles errores
    echo ""
    echo "Verificando posibles problemas..."
    
    # Verificar si los archivos de entrada tienen el formato correcto
    echo "Verificando formato de archivos scaffolds2bin..."
    for file in $(echo "$SCAFFOLDS_FILES" | tr ',' ' '); do
        if [ -f "$file" ]; then
            echo "Archivo: $file"
            echo "Primeras 5 líneas:"
            head -5 "$file"
            echo "Número de líneas: $(wc -l < "$file")"
            echo ""
        fi
    done
fi

echo ""
echo "✓ Proceso de refinamiento con DasTool completado"
echo "Resultados guardados en: $OUTPUT_DIR"

micromamba deactivate

