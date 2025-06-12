#!/bin/bash

# Script para ensamblaje con MEGAHIT
# Autor: Script generado para análisis metagenómico
# Fecha: $(date)

echo "=== Iniciando ensamblaje con MEGAHIT ==="

# Configuración
TRIMMED_DIR="/home_local/camda/shaday/barbara/trim/trimmed_reads"
OUTPUT_DIR="/home_local/camda/shaday/barbara/assembly"
CONDA_ENV="megahit"

# Activar ambiente micromamba
echo "Activando ambiente micromamba: $CONDA_ENV"
eval "$(micromamba shell hook --shell bash)"
micromamba activate /home_local/camda/micromamba/envs/$CONDA_ENV

# Verificar que MEGAHIT esté disponible
if ! command -v megahit &> /dev/null; then
    echo "ERROR: MEGAHIT no está disponible en el ambiente $CONDA_ENV"
    exit 1
fi

# Crear directorio de salida
mkdir -p "$OUTPUT_DIR"

# Buscar todos los archivos trimmed
echo "Buscando archivos trimmed..."
R1_FILES=$(find "$TRIMMED_DIR" -name "*val_1.fq.gz" | sort)
R2_FILES=$(find "$TRIMMED_DIR" -name "*val_2.fq.gz" | sort)

if [ -z "$R1_FILES" ] || [ -z "$R2_FILES" ]; then
    echo "ERROR: No se encontraron archivos trimmed en $TRIMMED_DIR"
    echo "Asegúrate de haber ejecutado TrimGalore primero"
    exit 1
fi

echo "Archivos R1 encontrados:"
echo "$R1_FILES"
echo ""
echo "Archivos R2 encontrados:"
echo "$R2_FILES"

# Convertir a listas separadas por comas
R1_LIST=$(echo "$R1_FILES" | tr '\n' ',' | sed 's/,$//')
R2_LIST=$(echo "$R2_FILES" | tr '\n' ',' | sed 's/,$//')

echo ""
echo "Lista R1: $R1_LIST"
echo "Lista R2: $R2_LIST"

# Definir directorio de salida de MEGAHIT
MEGAHIT_OUTPUT="$OUTPUT_DIR/megahit_output"

# Eliminar directorio de salida si existe (MEGAHIT requiere directorio vacío)
if [ -d "$MEGAHIT_OUTPUT" ]; then
    echo "Eliminando directorio de salida existente..."
    rm -rf "$MEGAHIT_OUTPUT"
fi

# Ejecutar MEGAHIT
echo ""
echo "Ejecutando MEGAHIT..."
echo "Esto puede tomar varias horas dependiendo del tamaño de los datos..."

megahit -1 "$R1_LIST" \
        -2 "$R2_LIST" \
        -o "$MEGAHIT_OUTPUT" \
        --num-cpu-threads 8 \
        --memory 0.8 \
        --min-contig-len 500 \
        --k-min 21 \
        --k-max 141 \
        --k-step 20

if [ $? -eq 0 ]; then
    echo "✓ MEGAHIT completado exitosamente"
    
    # Verificar archivo de contigs
    CONTIGS_FILE="$MEGAHIT_OUTPUT/final.contigs.fa"
    if [ -f "$CONTIGS_FILE" ]; then
        echo "✓ Archivo de contigs generado: $CONTIGS_FILE"
        
        # Generar estadísticas del ensamblaje
        echo ""
        echo "=== ESTADÍSTICAS DEL ENSAMBLAJE ==="
        
        # Contar contigs
        NUM_CONTIGS=$(grep -c "^>" "$CONTIGS_FILE")
        echo "Número total de contigs: $NUM_CONTIGS"
        
        # Calcular estadísticas de longitud
        echo "Calculando estadísticas de longitud..."
        python3 << EOF
import sys
from Bio import SeqIO

contigs_file = "$CONTIGS_FILE"
lengths = []

try:
    for record in SeqIO.parse(contigs_file, "fasta"):
        lengths.append(len(record.seq))
    
    if lengths:
        lengths.sort(reverse=True)
        total_length = sum(lengths)
        num_contigs = len(lengths)
        min_length = min(lengths)
        max_length = max(lengths)
        mean_length = total_length / num_contigs
        
        # Calcular N50
        cumulative = 0
        n50 = 0
        for length in lengths:
            cumulative += length
            if cumulative >= total_length * 0.5:
                n50 = length
                break
        
        print(f"Longitud total: {total_length:,} bp")
        print(f"Longitud promedio: {mean_length:.1f} bp")
        print(f"Longitud mínima: {min_length:,} bp")
        print(f"Longitud máxima: {max_length:,} bp")
        print(f"N50: {n50:,} bp")
        
        # Contigs por rangos de tamaño
        ranges = [(500, 1000), (1000, 5000), (5000, 10000), (10000, float('inf'))]
        for min_len, max_len in ranges:
            count = sum(1 for l in lengths if min_len <= l < max_len)
            if max_len == float('inf'):
                print(f"Contigs >= {min_len:,} bp: {count}")
            else:
                print(f"Contigs {min_len:,}-{max_len:,} bp: {count}")
    else:
        print("No se encontraron contigs en el archivo")
        
except ImportError:
    print("BioPython no disponible, usando métodos alternativos...")
    # Método alternativo sin BioPython
    import re
    
    with open(contigs_file, 'r') as f:
        content = f.read()
    
    sequences = re.findall(r'>.*?\n((?:[^>]*\n?)*)', content)
    lengths = [len(seq.replace('\n', '')) for seq in sequences]
    
    if lengths:
        lengths.sort(reverse=True)
        total_length = sum(lengths)
        print(f"Longitud total: {total_length:,} bp")
        print(f"Longitud promedio: {sum(lengths)/len(lengths):.1f} bp")
        print(f"Longitud mínima: {min(lengths):,} bp")
        print(f"Longitud máxima: {max(lengths):,} bp")

except Exception as e:
    print(f"Error calculando estadísticas: {e}")
    print("Usando métodos básicos...")
    
    # Método más básico
    with open(contigs_file, 'r') as f:
        lines = f.readlines()
    
    header_count = sum(1 for line in lines if line.startswith('>'))
    total_bases = sum(len(line.strip()) for line in lines if not line.startswith('>'))
    
    print(f"Número de contigs: {header_count}")
    print(f"Total de bases: {total_bases:,} bp")
    if header_count > 0:
        print(f"Longitud promedio: {total_bases/header_count:.1f} bp")
EOF
        
        # Crear enlace simbólico para fácil acceso
        FINAL_CONTIGS="$OUTPUT_DIR/final_contigs.fa"
        ln -sf "$CONTIGS_FILE" "$FINAL_CONTIGS"
        echo "✓ Enlace simbólico creado: $FINAL_CONTIGS"
        
    else
        echo "✗ No se encontró el archivo de contigs final"
    fi
    
    # Mostrar archivos generados
    echo ""
    echo "=== ARCHIVOS GENERADOS ==="
    ls -la "$MEGAHIT_OUTPUT"/ 2>/dev/null || echo "No se encontraron archivos en el directorio de salida"
    
else
    echo "✗ Error en MEGAHIT"
    exit 1
fi

echo ""
echo "✓ Ensamblaje completado"
echo "Directorio de salida: $MEGAHIT_OUTPUT"
echo "Archivo de contigs: $CONTIGS_FILE"

micromamba deactivate

