#!/bin/bash

# Script para binning metagenómico
# Autor: Script generado para análisis metagenómico
# Fecha: $(date)

echo "=== Iniciando binning metagenómico ==="

# Configuración
ASSEMBLY_DIR="/home_local/camda/shaday/barbara/assembly"
MAPPING_DIR="/home_local/camda/shaday/barbara/mapping"
OUTPUT_DIR="/home_local/camda/shaday/barbara/binning"
CONDA_ENV="binning_env"

# Activar ambiente micromamba
echo "Activando ambiente micromamba: $CONDA_ENV"
eval "$(micromamba shell hook --shell bash)"
micromamba activate /home_local/camda/micromamba/envs/$CONDA_ENV

# Crear directorios de salida
mkdir -p "$OUTPUT_DIR/metabat2"
mkdir -p "$OUTPUT_DIR/maxbin2"
mkdir -p "$OUTPUT_DIR/concoct"

# Verificar archivos necesarios
CONTIGS_FILE="$ASSEMBLY_DIR/final_contigs.fa"
if [ ! -f "$CONTIGS_FILE" ]; then
    CONTIGS_FILE="$ASSEMBLY_DIR/megahit_output/final.contigs.fa"
fi

if [ ! -f "$CONTIGS_FILE" ]; then
    echo "ERROR: No se encontró el archivo de contigs"
    exit 1
fi

DEPTH_FILE="$MAPPING_DIR/combined_depth.txt"
if [ ! -f "$DEPTH_FILE" ]; then
    echo "ERROR: No se encontró el archivo de profundidad combinado"
    echo "Asegúrate de haber ejecutado el script de mapeo primero"
    exit 1
fi

echo "Archivo de contigs: $CONTIGS_FILE"
echo "Archivo de profundidad: $DEPTH_FILE"

# Buscar archivos BAM
BAM_FILES=$(find "$MAPPING_DIR/bam_files" -name "*_sorted.bam" 2>/dev/null)
if [ -z "$BAM_FILES" ]; then
    echo "ERROR: No se encontraron archivos BAM ordenados"
    exit 1
fi

echo "Archivos BAM encontrados:"
echo "$BAM_FILES"

# 1. METABAT2
echo ""
echo "=== Ejecutando MetaBAT2 ==="

if command -v metabat2 &> /dev/null; then
    # Generar archivo de profundidad para MetaBAT2
    METABAT_DEPTH="$OUTPUT_DIR/metabat2/depth.txt"
    
    echo "Generando archivo de profundidad para MetaBAT2..."
    jgi_summarize_bam_contig_depths --outputDepth "$METABAT_DEPTH" $BAM_FILES
    
    if [ $? -eq 0 ]; then
        echo "✓ Archivo de profundidad generado para MetaBAT2"
        
        # Ejecutar MetaBAT2
        echo "Ejecutando MetaBAT2..."
        metabat2 -i "$CONTIGS_FILE" \
                 -a "$METABAT_DEPTH" \
                 -o "$OUTPUT_DIR/metabat2/bin" \
                 -t 8 \
                 -m 1500 \
                 --seed 1
        
        if [ $? -eq 0 ]; then
            echo "✓ MetaBAT2 completado"
            METABAT_BINS=$(ls "$OUTPUT_DIR/metabat2"/bin.*.fa 2>/dev/null | wc -l)
            echo "  Bins generados: $METABAT_BINS"
        else
            echo "✗ Error en MetaBAT2"
        fi
    else
        echo "✗ Error generando archivo de profundidad para MetaBAT2"
    fi
else
    echo "ADVERTENCIA: MetaBAT2 no disponible en el ambiente"
fi

# 2. MaxBin2
echo ""
echo "=== Ejecutando MaxBin2 ==="

if command -v run_MaxBin.pl &> /dev/null; then
    # Preparar archivos de abundancia para MaxBin2
    echo "Preparando archivos de abundancia para MaxBin2..."
    
    # Extraer abundancias por muestra
    SAMPLES=("CT_FKDN25H000391-1A_22NWHGLT4_L5" "ST_FKDN25H000392-1A_22NWHGLT4_L5")
    ABUND_FILES=""
    
    for i in "${!SAMPLES[@]}"; do
        sample="${SAMPLES[$i]}"
        col=$((i + 4))  # Columnas 4 y 5 en el archivo de profundidad combinado
        
        ABUND_FILE="$OUTPUT_DIR/maxbin2/${sample}_abundance.txt"
        awk -v col=$col 'NR>1 {print $1"\t"$col}' "$DEPTH_FILE" > "$ABUND_FILE"
        ABUND_FILES="$ABUND_FILES -abund $ABUND_FILE"
    done
    
    # Ejecutar MaxBin2
    echo "Ejecutando MaxBin2..."
    run_MaxBin.pl -contig "$CONTIGS_FILE" \
                  $ABUND_FILES \
                  -out "$OUTPUT_DIR/maxbin2/bin" \
                  -thread 8 \
                  -min_contig_length 1500
    
    if [ $? -eq 0 ]; then
        echo "✓ MaxBin2 completado"
        MAXBIN_BINS=$(ls "$OUTPUT_DIR/maxbin2"/bin.*.fasta 2>/dev/null | wc -l)
        echo "  Bins generados: $MAXBIN_BINS"
    else
        echo "✗ Error en MaxBin2"
    fi
else
    echo "ADVERTENCIA: MaxBin2 no disponible en el ambiente"
fi

# 3. CONCOCT
echo ""
echo "=== Ejecutando CONCOCT ==="

if command -v concoct &> /dev/null; then
    # Cortar contigs en fragmentos de 10kb para CONCOCT
    echo "Cortando contigs para CONCOCT..."
    CONCOCT_CONTIGS="$OUTPUT_DIR/concoct/contigs_10K.fa"
    cut_up_fasta.py "$CONTIGS_FILE" -c 10000 -o 0 --merge_last -b "$OUTPUT_DIR/concoct/contigs_10K.bed" > "$CONCOCT_CONTIGS"
    
    # Generar tabla de cobertura para CONCOCT
    echo "Generando tabla de cobertura para CONCOCT..."
    CONCOCT_COV="$OUTPUT_DIR/concoct/coverage_table.tsv"
    concoct_coverage_table.py "$OUTPUT_DIR/concoct/contigs_10K.bed" $BAM_FILES > "$CONCOCT_COV"
    
    # Ejecutar CONCOCT
    echo "Ejecutando CONCOCT..."
    concoct --composition_file "$CONCOCT_CONTIGS" \
            --coverage_file "$CONCOCT_COV" \
            -b "$OUTPUT_DIR/concoct/" \
            -t 8
    
    if [ $? -eq 0 ]; then
        # Extraer bins de CONCOCT
        echo "Extrayendo bins de CONCOCT..."
        merge_cutup_clustering.py "$OUTPUT_DIR/concoct/clustering_gt1000.csv" > "$OUTPUT_DIR/concoct/clustering_merged.csv"
        
        mkdir -p "$OUTPUT_DIR/concoct/fasta_bins"
        extract_fasta_bins.py "$CONTIGS_FILE" "$OUTPUT_DIR/concoct/clustering_merged.csv" --output_path "$OUTPUT_DIR/concoct/fasta_bins"
        
        echo "✓ CONCOCT completado"
        CONCOCT_BINS=$(ls "$OUTPUT_DIR/concoct/fasta_bins"/*.fa 2>/dev/null | wc -l)
        echo "  Bins generados: $CONCOCT_BINS"
    else
        echo "✗ Error en CONCOCT"
    fi
else
    echo "ADVERTENCIA: CONCOCT no disponible en el ambiente"
fi

# Generar resumen de binning
echo ""
echo "=== RESUMEN DE BINNING ==="

# Contar bins de cada método
METABAT_COUNT=$(ls "$OUTPUT_DIR/metabat2"/bin.*.fa 2>/dev/null | wc -l)
MAXBIN_COUNT=$(ls "$OUTPUT_DIR/maxbin2"/bin.*.fasta 2>/dev/null | wc -l)
CONCOCT_COUNT=$(ls "$OUTPUT_DIR/concoct/fasta_bins"/*.fa 2>/dev/null | wc -l)

echo "MetaBAT2: $METABAT_COUNT bins"
echo "MaxBin2: $MAXBIN_COUNT bins"
echo "CONCOCT: $CONCOCT_COUNT bins"

# Crear lista de bins para DasTool
echo ""
echo "Preparando archivos para DasTool..."

# MetaBAT2
if [ $METABAT_COUNT -gt 0 ]; then
    METABAT_SCAFFOLDS="$OUTPUT_DIR/metabat2_scaffolds2bin.tsv"
    echo "Generando $METABAT_SCAFFOLDS"
    for bin_file in "$OUTPUT_DIR/metabat2"/bin.*.fa; do
        if [ -f "$bin_file" ]; then
            bin_name=$(basename "$bin_file" .fa)
            grep "^>" "$bin_file" | sed "s/^>//" | sed "s/\s.*$//" | awk -v bin="$bin_name" '{print $1"\t"bin}' >> "$METABAT_SCAFFOLDS"
        fi
    done
fi

# MaxBin2
if [ $MAXBIN_COUNT -gt 0 ]; then
    MAXBIN_SCAFFOLDS="$OUTPUT_DIR/maxbin2_scaffolds2bin.tsv"
    echo "Generando $MAXBIN_SCAFFOLDS"
    for bin_file in "$OUTPUT_DIR/maxbin2"/bin.*.fasta; do
        if [ -f "$bin_file" ]; then
            bin_name=$(basename "$bin_file" .fasta)
            grep "^>" "$bin_file" | sed "s/^>//" | sed "s/\s.*$//" | awk -v bin="$bin_name" '{print $1"\t"bin}' >> "$MAXBIN_SCAFFOLDS"
        fi
    done
fi

# CONCOCT
if [ $CONCOCT_COUNT -gt 0 ]; then
    CONCOCT_SCAFFOLDS="$OUTPUT_DIR/concoct_scaffolds2bin.tsv"
    echo "Generando $CONCOCT_SCAFFOLDS"
    for bin_file in "$OUTPUT_DIR/concoct/fasta_bins"/*.fa; do
        if [ -f "$bin_file" ]; then
            bin_name=$(basename "$bin_file" .fa)
            grep "^>" "$bin_file" | sed "s/^>//" | sed "s/\s.*$//" | awk -v bin="$bin_name" '{print $1"\t"bin}' >> "$CONCOCT_SCAFFOLDS"
        fi
    done
fi

echo "✓ Binning completado"
echo "Resultados guardados en: $OUTPUT_DIR"

micromamba deactivate

