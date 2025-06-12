#!/bin/bash

# Script wrapper para análisis de diversidad con R
# Autor: Script generado para análisis metagenómico
# Fecha: $(date)

echo "=== Iniciando análisis de diversidad y abundancia ==="

# Configuración
BASE_DIR="/home_local/camda/shaday/barbara"
BIOM_DIR="$BASE_DIR/taxonomy/biom_files"
OUTPUT_DIR="$BASE_DIR/analysis/diversity"
SCRIPT_DIR="/home_local/camda/shaday/barbara/src"
R_SCRIPT="$SCRIPT_DIR/11_diversity_analysis.R"
CONDA_ENV="r_env"

# Activar ambiente micromamba
echo "Activando ambiente micromamba: $CONDA_ENV"
eval "$(micromamba shell hook --shell bash)"
micromamba activate /home_local/camda/micromamba/envs/$CONDA_ENV

# Verificar que R esté disponible
if ! command -v R &> /dev/null; then
    echo "ERROR: R no está disponible en el ambiente $CONDA_ENV"
    exit 1
fi

# Verificar que el script R existe
if [ ! -f "$R_SCRIPT" ]; then
    echo "ERROR: Script R no encontrado: $R_SCRIPT"
    exit 1
fi

# Crear directorio de salida
mkdir -p "$OUTPUT_DIR"

echo "Configuración:"
echo "  - Directorio base: $BASE_DIR"
echo "  - Directorio BIOM: $BIOM_DIR"
echo "  - Directorio de salida: $OUTPUT_DIR"
echo "  - Script R: $R_SCRIPT"

# Verificar archivos BIOM disponibles
echo ""
echo "Verificando archivos BIOM disponibles..."
if [ ! -d "$BIOM_DIR" ]; then
    echo "ERROR: Directorio BIOM no encontrado: $BIOM_DIR"
    echo "Asegúrate de haber ejecutado los scripts de Kraken2 y BIOM primero"
    exit 1
fi

BIOM_FILES=$(find "$BIOM_DIR" -name "*.biom" 2>/dev/null)
if [ -z "$BIOM_FILES" ]; then
    echo "ERROR: No se encontraron archivos BIOM en $BIOM_DIR"
    echo "Archivos disponibles en el directorio:"
    ls -la "$BIOM_DIR" 2>/dev/null || echo "Directorio vacío o no accesible"
    exit 1
fi

echo "Archivos BIOM encontrados:"
echo "$BIOM_FILES"

# Verificar e instalar paquetes R necesarios
echo ""
echo "Verificando paquetes R necesarios..."

R --slave << 'EOF'
# Lista de paquetes necesarios
required_packages <- c(
    "phyloseq", "ggplot2", "RColorBrewer", "vegan", 
    "patchwork", "dplyr", "tidyr", "gridExtra", "scales"
)

# Función para instalar paquetes faltantes
install_if_missing <- function(packages) {
    # Verificar BiocManager
    if (!requireNamespace("BiocManager", quietly = TRUE)) {
        install.packages("BiocManager", repos = "https://cran.r-project.org")
    }
    
    for (pkg in packages) {
        if (!requireNamespace(pkg, quietly = TRUE)) {
            cat("Instalando paquete:", pkg, "\n")
            
            # Intentar instalar desde Bioconductor primero (para phyloseq)
            if (pkg == "phyloseq") {
                BiocManager::install(pkg, ask = FALSE, update = FALSE)
            } else {
                # Intentar CRAN primero
                tryCatch({
                    install.packages(pkg, repos = "https://cran.r-project.org")
                }, error = function(e) {
                    # Si falla, intentar Bioconductor
                    BiocManager::install(pkg, ask = FALSE, update = FALSE)
                })
            }
        } else {
            cat("Paquete ya instalado:", pkg, "\n")
        }
    }
}

# Instalar paquetes faltantes
install_if_missing(required_packages)

# Verificar que todos los paquetes se pueden cargar
cat("\nVerificando carga de paquetes...\n")
for (pkg in required_packages) {
    tryCatch({
        library(pkg, character.only = TRUE)
        cat("✓", pkg, "\n")
    }, error = function(e) {
        cat("✗", pkg, "- ERROR:", e$message, "\n")
    })
}

cat("\nVerificación de paquetes completada.\n")
EOF

if [ $? -ne 0 ]; then
    echo "ERROR: Problemas con la instalación/verificación de paquetes R"
    echo "Intenta instalar manualmente los paquetes faltantes"
    exit 1
fi

# Ejecutar análisis R
echo ""
echo "Ejecutando análisis de diversidad en R..."
echo "Esto puede tomar varios minutos..."

# Ejecutar script R
Rscript "$R_SCRIPT"

if [ $? -eq 0 ]; then
    echo "✓ Análisis de diversidad completado exitosamente"
    
    # Mostrar archivos generados
    echo ""
    echo "=== ARCHIVOS GENERADOS ==="
    if [ -d "$OUTPUT_DIR" ]; then
        echo "Directorio de salida: $OUTPUT_DIR"
        echo ""
        echo "Gráficas generadas:"
        find "$OUTPUT_DIR" -name "*.png" | while read file; do
            echo "  - $(basename "$file")"
        done
        
        echo ""
        echo "Tablas generadas:"
        find "$OUTPUT_DIR" -name "*.txt" | while read file; do
            echo "  - $(basename "$file")"
        done
        
        echo ""
        echo "Resumen de archivos:"
        ls -la "$OUTPUT_DIR"
    else
        echo "⚠ Directorio de salida no encontrado"
    fi
    
    # Generar reporte HTML simple
    echo ""
    echo "Generando reporte HTML..."
    
    HTML_REPORT="$OUTPUT_DIR/reporte_diversidad.html"
    
    cat > "$HTML_REPORT" << 'HTML_EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Reporte de Análisis de Diversidad Metagenómica</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #2c3e50; }
        h2 { color: #34495e; border-bottom: 2px solid #ecf0f1; padding-bottom: 10px; }
        .image-container { margin: 20px 0; text-align: center; }
        img { max-width: 100%; height: auto; border: 1px solid #ddd; margin: 10px; }
        .stats { background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 15px 0; }
    </style>
</head>
<body>
    <h1>Análisis de Diversidad Metagenómica</h1>
    <p><strong>Fecha:</strong> $(date)</p>
    <p><strong>Muestras analizadas:</strong> CT (Control) y ST (Treatment)</p>
    
    <h2>Diversidad Alfa</h2>
    <div class="image-container">
        <img src="metagenoma_CT_ST_diversidad_alpha.png" alt="Diversidad Alfa">
    </div>
    <p>La diversidad alfa mide la riqueza y diversidad dentro de cada muestra individual.</p>
    
    <h2>Diversidad Beta</h2>
    <div class="image-container">
        <img src="metagenoma_CT_ST_diversidad_beta_nmds.png" alt="NMDS">
        <img src="metagenoma_CT_ST_diversidad_beta_pcoa.png" alt="PCoA">
    </div>
    <p>La diversidad beta compara la composición microbiana entre muestras.</p>
    
    <h2>Abundancia por Niveles Taxonómicos</h2>
HTML_EOF

    # Agregar imágenes de abundancia al HTML
    for level in phylum class order family genus species; do
        if [ -f "$OUTPUT_DIR/metagenoma_CT_ST_abundancia_${level}.png" ]; then
            cat >> "$HTML_REPORT" << HTML_EOF2
    <h3>$(echo ${level^})</h3>
    <div class="image-container">
        <img src="metagenoma_CT_ST_abundancia_${level}.png" alt="Abundancia ${level^}">
    </div>
HTML_EOF2
        fi
    done
    
    cat >> "$HTML_REPORT" << 'HTML_EOF3'
    
    <h2>Resumen de Diversidad</h2>
    <div class="image-container">
        <img src="metagenoma_CT_ST_resumen_diversidad.png" alt="Resumen Diversidad">
    </div>
    
    <div class="stats">
        <h3>Archivos Generados</h3>
        <ul>
HTML_EOF3

    # Listar archivos generados en el HTML
    find "$OUTPUT_DIR" -name "*.png" -o -name "*.txt" | sort | while read file; do
        echo "            <li>$(basename "$file")</li>" >> "$HTML_REPORT"
    done
    
    cat >> "$HTML_REPORT" << 'HTML_EOF4'
        </ul>
    </div>
    
    <p><em>Reporte generado automáticamente por el pipeline metagenómico</em></p>
</body>
</html>
HTML_EOF4

    echo "✓ Reporte HTML generado: $HTML_REPORT"
    
else
    echo "✗ Error en el análisis de diversidad"
    echo "Revisa los logs para más detalles"
    exit 1
fi

echo ""
echo "✓ Análisis de diversidad completado"
echo "Resultados guardados en: $OUTPUT_DIR"

micromamba deactivate

