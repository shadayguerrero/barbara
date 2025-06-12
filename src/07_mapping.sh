#!/bin/bash

# Script para mapeo de reads a contigs
# Autor: Script generado para análisis metagenómico
# Fecha: $(date)

echo "=== Iniciando mapeo de reads a contigs ==="

# Configuración
TRIMMED_DIR="/home_local/camda/shaday/barbara/trim/trimmed_reads"
ASSEMBLY_DIR="/home_local/camda/shaday/barbara/assembly"
OUTPUT_DIR="/home_local/camda/shaday/barbara/mapping"
CONDA_ENV="mapping_env"

# Activar ambiente micromamba
echo "Activando ambiente micromamba: $CONDA_ENV"
eval "$(micromamba shell hook --shell bash)"
micromamba activate /home_local/camda/micromamba/envs/$CONDA_ENV

# Verificar herramientas necesarias
if ! command -v bwa &> /dev/null; then
    echo "ERROR: BWA no está disponible en el ambiente $CONDA_ENV"
    exit 1
fi

if ! command -v samtools &> /dev/null; then
    echo "ERROR: samtools no está disponible en el ambiente $CONDA_ENV"
    exit 1
fi

# Crear directorios de salida
mkdir -p "$OUTPUT_DIR/bam_files"
mkdir -p "$OUTPUT_DIR/depth_files"

# Verificar archivo de contigs
CONTIGS_FILE="$ASSEMBLY_DIR/final_contigs.fa"
if [ ! -f "$CONTIGS_FILE" ]; then
    CONTIGS_FILE="$ASSEMBLY_DIR/megahit_output/final.contigs.fa"
fi

if [ ! -f "$CONTIGS_FILE" ]; then
    echo "ERROR: No se encontró el archivo de contigs"
    echo "Buscado en: $ASSEMBLY_DIR/final_contigs.fa"
    echo "Buscado en: $ASSEMBLY_DIR/megahit_output/final.contigs.fa"
    exit 1
fi

echo "Archivo de contigs: $CONTIGS_FILE"

# Indexar contigs con BWA
echo "Indexando contigs con BWA..."
BWA_INDEX="$OUTPUT_DIR/contigs_index"
cp "$CONTIGS_FILE" "$BWA_INDEX.fa"
bwa index "$BWA_INDEX.fa"

if [ $? -ne 0 ]; then
    echo "ERROR: Fallo al indexar contigs con BWA"
    exit 1
fi

echo "✓ Indexación completada"

# Muestras a procesar
SAMPLES=("CT_FKDN25H000391-1A_22NWHGLT4_L5" "ST_FKDN25H000392-1A_22NWHGLT4_L5")

# Procesar cada muestra
for sample in "${SAMPLES[@]}"; do
    echo ""
    echo "Procesando muestra: $sample"
    
    # Buscar archivos trimmed para esta muestra
    R1_TRIMMED=$(find "$TRIMMED_DIR" -name "*${sample}*1*val_1.fq.gz" 2>/dev/null | head -1)
    R2_TRIMMED=$(find "$TRIMMED_DIR" -name "*${sample}*2*val_2.fq.gz" 2>/dev/null | head -1)
    
    if [ ! -f "$R1_TRIMMED" ] || [ ! -f "$R2_TRIMMED" ]; then
        echo "ERROR: No se encuentran los archivos trimmed para $sample"
        continue
    fi
    
    echo "  R1: $(basename "$R1_TRIMMED")"
    echo "  R2: $(basename "$R2_TRIMMED")"
    
    # Definir archivos de salida
    SAM_FILE="$OUTPUT_DIR/bam_files/${sample}.sam"
    BAM_FILE="$OUTPUT_DIR/bam_files/${sample}.bam"
    SORTED_BAM="$OUTPUT_DIR/bam_files/${sample}_sorted.bam"
    DEPTH_FILE="$OUTPUT_DIR/depth_files/${sample}_depth.txt"
    
    # Mapeo con BWA
    echo "  Ejecutando BWA mem..."
    bwa mem -t 8 "$BWA_INDEX.fa" "$R1_TRIMMED" "$R2_TRIMMED" > "$SAM_FILE"
    
    if [ $? -ne 0 ]; then
        echo "  ✗ Error en BWA mem para $sample"
        continue
    fi
    
    # Convertir SAM a BAM
    echo "  Convirtiendo SAM a BAM..."
    samtools view -bS "$SAM_FILE" > "$BAM_FILE"
    
    # Ordenar BAM
    echo "  Ordenando archivo BAM..."
    samtools sort "$BAM_FILE" -o "$SORTED_BAM"
    
    # Indexar BAM ordenado
    echo "  Indexando BAM ordenado..."
    samtools index "$SORTED_BAM"
    
    # Calcular profundidad de cobertura
    echo "  Calculando profundidad de cobertura..."
    samtools depth "$SORTED_BAM" > "$DEPTH_FILE"
    
    # Generar estadísticas de mapeo
    echo "  Generando estadísticas de mapeo..."
    STATS_FILE="$OUTPUT_DIR/bam_files/${sample}_stats.txt"
    samtools flagstat "$SORTED_BAM" > "$STATS_FILE"
    
    # Mostrar estadísticas básicas
    TOTAL_READS=$(samtools view -c "$SORTED_BAM")
    MAPPED_READS=$(samtools view -c -F 4 "$SORTED_BAM")
    
    if [ $TOTAL_READS -gt 0 ]; then
        MAPPING_RATE=$(echo "scale=2; $MAPPED_READS * 100 / $TOTAL_READS" | bc)
        echo "    Total reads: $TOTAL_READS"
        echo "    Reads mapeados: $MAPPED_READS"
        echo "    Tasa de mapeo: ${MAPPING_RATE}%"
    fi
    
    # Limpiar archivo SAM (opcional, para ahorrar espacio)
    rm "$SAM_FILE"
    rm "$BAM_FILE"  # Mantener solo el BAM ordenado
    
    echo "  ✓ Mapeo completado para $sample"
done

# Generar archivo de profundidad combinado para binning
echo ""
echo "Generando archivo de profundidad combinado para binning..."
COMBINED_DEPTH="$OUTPUT_DIR/combined_depth.txt"

# Crear header
echo -e "contigName\tcontigLen\ttotalAvgDepth\t$(echo "${SAMPLES[@]}" | tr ' ' '\t')" > "$COMBINED_DEPTH"

# Usar script de Python para combinar profundidades
python3 << EOF
import os
import sys
from collections import defaultdict

# Directorios
depth_dir = "$OUTPUT_DIR/depth_files"
contigs_file = "$CONTIGS_FILE"
output_file = "$COMBINED_DEPTH"

# Leer longitudes de contigs
contig_lengths = {}
try:
    with open(contigs_file, 'r') as f:
        current_contig = None
        current_length = 0
        for line in f:
            if line.startswith('>'):
                if current_contig:
                    contig_lengths[current_contig] = current_length
                current_contig = line.strip()[1:].split()[0]
                current_length = 0
            else:
                current_length += len(line.strip())
        if current_contig:
            contig_lengths[current_contig] = current_length
except Exception as e:
    print(f"Error leyendo contigs: {e}")
    sys.exit(1)

# Leer profundidades para cada muestra
samples = ["CT_FKDN25H000391-1A_22NWHGLT4_L5", "ST_FKDN25H000392-1A_22NWHGLT4_L5"]
contig_depths = defaultdict(lambda: defaultdict(float))

for sample in samples:
    depth_file = os.path.join(depth_dir, f"{sample}_depth.txt")
    if os.path.exists(depth_file):
        print(f"Procesando {depth_file}")
        with open(depth_file, 'r') as f:
            for line in f:
                parts = line.strip().split('\t')
                if len(parts) >= 3:
                    contig = parts[0]
                    depth = float(parts[2])
                    contig_depths[contig][sample] += depth
    else:
        print(f"Archivo no encontrado: {depth_file}")

# Calcular profundidades promedio por contig
contig_avg_depths = {}
for contig in contig_depths:
    if contig in contig_lengths:
        total_depth = sum(contig_depths[contig].values())
        avg_depth = total_depth / len(samples) if len(samples) > 0 else 0
        contig_avg_depths[contig] = avg_depth

# Escribir archivo combinado
try:
    with open(output_file, 'w') as f:
        # Header
        f.write("contigName\tcontigLen\ttotalAvgDepth\t" + "\t".join(samples) + "\n")
        
        # Datos
        for contig in sorted(contig_lengths.keys()):
            length = contig_lengths[contig]
            avg_depth = contig_avg_depths.get(contig, 0)
            
            line = f"{contig}\t{length}\t{avg_depth:.2f}"
            for sample in samples:
                sample_depth = contig_depths[contig].get(sample, 0)
                if length > 0:
                    sample_avg = sample_depth / length
                else:
                    sample_avg = 0
                line += f"\t{sample_avg:.2f}"
            f.write(line + "\n")
    
    print(f"Archivo combinado generado: {output_file}")
    
except Exception as e:
    print(f"Error escribiendo archivo combinado: {e}")
    sys.exit(1)
EOF

echo "✓ Mapeo completado para todas las muestras"
echo "Archivos BAM guardados en: $OUTPUT_DIR/bam_files"
echo "Archivos de profundidad en: $OUTPUT_DIR/depth_files"
echo "Archivo de profundidad combinado: $COMBINED_DEPTH"

# Mostrar resumen
echo ""
echo "=== RESUMEN DE MAPEO ==="
ls -la "$OUTPUT_DIR/bam_files"/*.bam 2>/dev/null || echo "No se encontraron archivos BAM"
ls -la "$OUTPUT_DIR/depth_files"/*.txt 2>/dev/null || echo "No se encontraron archivos de profundidad"

micromamba deactivate

