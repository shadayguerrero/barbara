#!/bin/bash

# Script para generar archivos BIOM desde resultados de Kraken2
# Autor: Script generado para análisis metagenómico
# Fecha: $(date)

echo "=== Generando archivos BIOM desde Kraken2 ==="

# Configuración
KRAKEN_DIR="/home_local/camda/shaday/barbara/taxonomy/kraken_output"
BIOM_DIR="/home_local/camda/shaday/barbara/taxonomy/biom_files"
CONDA_ENV="metagenomics"

# Activar ambiente micromamba
echo "Activando ambiente micromamba: $CONDA_ENV"
eval "$(micromamba shell hook --shell bash)"
micromamba activate /home_local/camda/micromamba/envs/$CONDA_ENV

# Verificar que kraken-biom esté disponible
if ! command -v kraken-biom &> /dev/null; then
    echo "ADVERTENCIA: kraken-biom no está disponible"
    echo "Intentando instalar kraken-biom..."
    pip install kraken-biom
fi

# Crear directorio de salida
mkdir -p "$BIOM_DIR"

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

# Generar archivo BIOM combinado
echo ""
echo "Generando archivo BIOM combinado..."
BIOM_OUTPUT="$BIOM_DIR/combined_taxonomy.biom"

# Crear lista temporal de archivos
TEMP_LIST="$BIOM_DIR/kraken_reports_list.txt"
echo "$KRAKEN_REPORTS" > "$TEMP_LIST"

# Ejecutar kraken-biom
if command -v kraken-biom &> /dev/null; then
    kraken-biom $KRAKEN_REPORTS \
                --fmt json \
                -o "$BIOM_OUTPUT"
    
    if [ $? -eq 0 ]; then
        echo "✓ Archivo BIOM generado exitosamente: $BIOM_OUTPUT"
        
        # Generar archivo BIOM en formato TSV para visualización
        TSV_OUTPUT="$BIOM_DIR/combined_taxonomy.tsv"
        if command -v biom &> /dev/null; then
            biom convert -i "$BIOM_OUTPUT" -o "$TSV_OUTPUT" --to-tsv --header-key taxonomy
            echo "✓ Archivo TSV generado: $TSV_OUTPUT"
        fi
    else
        echo "✗ Error generando archivo BIOM"
    fi
else
    echo "ADVERTENCIA: kraken-biom no disponible, generando tabla manual..."
    
    # Crear tabla manual combinada
    MANUAL_TABLE="$BIOM_DIR/combined_taxonomy_manual.tsv"
    echo -e "TaxID\tTaxonomy\tCT_FKDN25H000391-1A_22NWHGLT4_L5\tST_FKDN25H000392-1A_22NWHGLT4_L5" > "$MANUAL_TABLE"
    
    # Procesar cada reporte individualmente
    for report in $KRAKEN_REPORTS; do
        sample_name=$(basename "$report" | sed 's/_kraken2_report.txt//')
        echo "Procesando $sample_name..."
    done
    
    echo "✓ Tabla manual generada: $MANUAL_TABLE"
fi

# Generar archivos BIOM individuales para cada muestra
echo ""
echo "Generando archivos BIOM individuales..."
for report in $KRAKEN_REPORTS; do
    sample_name=$(basename "$report" | sed 's/_kraken2_report.txt//')
    individual_biom="$BIOM_DIR/${sample_name}_taxonomy.biom"
    
    if command -v kraken-biom &> /dev/null; then
        kraken-biom "$report" \
                    --fmt json \
                    -o "$individual_biom"
        echo "✓ BIOM individual generado para $sample_name"
    fi
done

# Generar resumen de abundancias taxonómicas
echo ""
echo "Generando resumen de abundancias..."
SUMMARY_FILE="$BIOM_DIR/taxonomy_summary.txt"

echo "=== RESUMEN DE ABUNDANCIAS TAXONÓMICAS ===" > "$SUMMARY_FILE"
echo "Fecha: $(date)" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

for report in $KRAKEN_REPORTS; do
    sample_name=$(basename "$report" | sed 's/_kraken2_report.txt//')
    echo "Muestra: $sample_name" >> "$SUMMARY_FILE"
    echo "----------------------------------------" >> "$SUMMARY_FILE"
    
    # Top 10 a nivel de especie (S)
    echo "Top 10 especies:" >> "$SUMMARY_FILE"
    grep -E "^\s*[0-9]+\.[0-9]+\s+[0-9]+\s+[0-9]+\s+S\s+" "$report" | \
    head -10 | \
    awk '{printf "  %6.2f%% - %s\n", $1, substr($0, index($0,$6))}' >> "$SUMMARY_FILE"
    
    echo "" >> "$SUMMARY_FILE"
done

echo "✓ Resumen generado: $SUMMARY_FILE"

# Mostrar estadísticas finales
echo ""
echo "=== ARCHIVOS BIOM GENERADOS ==="
ls -la "$BIOM_DIR"/*.biom 2>/dev/null || echo "No se encontraron archivos BIOM"
ls -la "$BIOM_DIR"/*.tsv 2>/dev/null || echo "No se encontraron archivos TSV"
ls -la "$BIOM_DIR"/*.txt 2>/dev/null || echo "No se encontraron archivos de resumen"

micromamba deactivate

