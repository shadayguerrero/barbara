#!/bin/bash

# Script maestro para ejecutar todo el pipeline metagenómico
# Autor: Script generado para análisis metagenómico
# Fecha: $(date)

echo "=========================================="
echo "    PIPELINE METAGENÓMICO COMPLETO"
echo "=========================================="
echo "Fecha de inicio: $(date)"
echo ""

# Configuración
SCRIPT_DIR="/home_local/camda/shaday/barbara/src"
LOG_DIR="/home_local/camda/shaday/barbara/logs"

# Crear directorio de logs
mkdir -p "$LOG_DIR"

# Inicializar micromamba
echo "Inicializando micromamba..."
eval "$(micromamba shell hook --shell bash)"

# Función para ejecutar script con logging
run_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/$script_name"
    local log_file="$LOG_DIR/${script_name%.sh}.log"
    
    echo "=========================================="
    echo "Ejecutando: $script_name"
    echo "Hora de inicio: $(date)"
    echo "Log: $log_file"
    echo "=========================================="
    
    if [ ! -f "$script_path" ]; then
        echo "ERROR: Script no encontrado: $script_path"
        return 1
    fi
    
    # Ejecutar script y guardar log
    bash "$script_path" 2>&1 | tee "$log_file"
    local exit_code=${PIPESTATUS[0]}
    
    if [ $exit_code -eq 0 ]; then
        echo "✓ $script_name completado exitosamente"
        echo "Hora de finalización: $(date)"
    else
        echo "✗ Error en $script_name (código de salida: $exit_code)"
        echo "Revisa el log: $log_file"
        return $exit_code
    fi
    
    echo ""
    return 0
}

# Función para mostrar tiempo transcurrido
show_elapsed_time() {
    local start_time="$1"
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    local hours=$((elapsed / 3600))
    local minutes=$(((elapsed % 3600) / 60))
    local seconds=$((elapsed % 60))
    
    printf "Tiempo transcurrido: %02d:%02d:%02d\n" $hours $minutes $seconds
}

# Tiempo de inicio
START_TIME=$(date +%s)

echo "Iniciando pipeline metagenómico completo..."
echo "Directorio de scripts: $SCRIPT_DIR"
echo "Directorio de logs: $LOG_DIR"
echo "Usando micromamba con ambientes en: /home_local/camda/micromamba/envs/"
echo ""

# Verificar que todos los scripts existan
SCRIPTS=(
    "00_setup_directories.sh"
    "01_fastqc_initial.sh"
    "02_trimgalore.sh"
    "03_fastqc_after.sh"
    "04_kraken2.sh"
    "05_kraken_biom.sh"
    "05b_bracken.sh"
    "06_megahit.sh"
    "07_mapping.sh"
    "08_binning.sh"
    "09_dastool.sh"
    "10_gtdbtk.sh"
    "11_diversity_analysis.sh"
)

echo "Verificando scripts..."
for script in "${SCRIPTS[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$script" ]; then
        echo "ERROR: Script no encontrado: $SCRIPT_DIR/$script"
        exit 1
    fi
    echo "✓ $script"
done
echo ""

# Verificar que micromamba esté disponible
if ! command -v micromamba &> /dev/null; then
    echo "ERROR: micromamba no está disponible en el sistema"
    echo "Por favor, instala micromamba o verifica que esté en el PATH"
    exit 1
fi

echo "✓ micromamba disponible: $(micromamba --version)"

# Verificar ambientes de micromamba
echo ""
echo "Verificando ambientes de micromamba..."
REQUIRED_ENVS=("metagenomics" "trimgalore" "megahit" "mapping_env" "binning_env" "gtdbtk-2.1.1")

for env in "${REQUIRED_ENVS[@]}"; do
    if [ -d "/home_local/camda/micromamba/envs/$env" ]; then
        echo "✓ Ambiente encontrado: $env"
    else
        echo "⚠ Ambiente no encontrado: $env"
        echo "  Ubicación esperada: /home_local/camda/micromamba/envs/$env"
    fi
done
echo ""

# Preguntar al usuario qué pasos ejecutar
echo "¿Qué pasos deseas ejecutar?"
echo "1) Pipeline completo (todos los pasos)"
echo "2) Solo control de calidad y trimming (pasos 0-3)"
echo "3) Solo taxonomía (pasos 4-5b)"
echo "4) Solo ensamblaje (paso 6)"
echo "5) Solo mapeo y binning (pasos 7-9)"
echo "6) Solo anotación (paso 10)"
echo "7) Solo análisis de diversidad (paso 11)"
echo "8) Personalizado (seleccionar pasos individuales)"
echo ""
read -p "Selecciona una opción (1-8): " option

case $option in
    1)
        echo "Ejecutando pipeline completo..."
        STEPS_TO_RUN=("${SCRIPTS[@]}")
        ;;
    2)
        echo "Ejecutando control de calidad y trimming..."
        STEPS_TO_RUN=("00_setup_directories.sh" "01_fastqc_initial.sh" "02_trimgalore.sh" "03_fastqc_after.sh")
        ;;
    3)
        echo "Ejecutando análisis taxonómico..."
        STEPS_TO_RUN=("04_kraken2.sh" "05_kraken_biom.sh" "05b_bracken.sh")
        ;;
    4)
        echo "Ejecutando ensamblaje..."
        STEPS_TO_RUN=("06_megahit.sh")
        ;;
    5)
        echo "Ejecutando mapeo y binning..."
        STEPS_TO_RUN=("07_mapping.sh" "08_binning.sh" "09_dastool.sh")
        ;;
    6)
        echo "Ejecutando anotación..."
        STEPS_TO_RUN=("10_gtdbtk.sh")
        ;;
    7)
        echo "Ejecutando análisis de diversidad..."
        STEPS_TO_RUN=("11_diversity_analysis.sh")
        ;;
    8)
        echo "Selección personalizada:"
        STEPS_TO_RUN=()
        for i in "${!SCRIPTS[@]}"; do
            script="${SCRIPTS[$i]}"
            read -p "¿Ejecutar $script? (y/n): " answer
            if [[ $answer =~ ^[Yy]$ ]]; then
                STEPS_TO_RUN+=("$script")
            fi
        done
        ;;
    *)
        echo "Opción inválida. Ejecutando pipeline completo..."
        STEPS_TO_RUN=("${SCRIPTS[@]}")
        ;;
esac

echo ""
echo "Pasos a ejecutar:"
for step in "${STEPS_TO_RUN[@]}"; do
    echo "  - $step"
done
echo ""

read -p "¿Continuar? (y/n): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Pipeline cancelado por el usuario."
    exit 0
fi

echo ""
echo "=========================================="
echo "INICIANDO EJECUCIÓN DEL PIPELINE"
echo "=========================================="

# Ejecutar pasos seleccionados
FAILED_STEPS=()
SUCCESSFUL_STEPS=()

for script in "${STEPS_TO_RUN[@]}"; do
    step_start_time=$(date +%s)
    
    if run_script "$script"; then
        SUCCESSFUL_STEPS+=("$script")
        step_end_time=$(date +%s)
        step_elapsed=$((step_end_time - step_start_time))
        echo "Tiempo del paso: ${step_elapsed}s"
    else
        FAILED_STEPS+=("$script")
        echo "FALLO en $script"
        
        # Preguntar si continuar
        read -p "¿Continuar con el siguiente paso? (y/n): " continue_answer
        if [[ ! $continue_answer =~ ^[Yy]$ ]]; then
            echo "Pipeline detenido por el usuario."
            break
        fi
    fi
    
    echo ""
done

# Resumen final
END_TIME=$(date +%s)
echo "=========================================="
echo "           RESUMEN FINAL"
echo "=========================================="
echo "Fecha de finalización: $(date)"
show_elapsed_time $START_TIME
echo ""

echo "Pasos exitosos (${#SUCCESSFUL_STEPS[@]}):"
for step in "${SUCCESSFUL_STEPS[@]}"; do
    echo "  ✓ $step"
done

if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
    echo ""
    echo "Pasos fallidos (${#FAILED_STEPS[@]}):"
    for step in "${FAILED_STEPS[@]}"; do
        echo "  ✗ $step"
    done
fi

echo ""
echo "Logs guardados en: $LOG_DIR"
echo ""

# Generar reporte final
FINAL_REPORT="/home_local/camda/shaday/barbara/pipeline_report.txt"
echo "=== REPORTE FINAL DEL PIPELINE METAGENÓMICO ===" > "$FINAL_REPORT"
echo "Fecha: $(date)" >> "$FINAL_REPORT"
show_elapsed_time $START_TIME >> "$FINAL_REPORT"
echo "Sistema: micromamba con ambientes en /home_local/camda/micromamba/envs/" >> "$FINAL_REPORT"
echo "" >> "$FINAL_REPORT"

echo "Pasos ejecutados exitosamente:" >> "$FINAL_REPORT"
for step in "${SUCCESSFUL_STEPS[@]}"; do
    echo "  ✓ $step" >> "$FINAL_REPORT"
done

if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
    echo "" >> "$FINAL_REPORT"
    echo "Pasos fallidos:" >> "$FINAL_REPORT"
    for step in "${FAILED_STEPS[@]}"; do
        echo "  ✗ $step" >> "$FINAL_REPORT"
    done
fi

echo "" >> "$FINAL_REPORT"
echo "Directorios de resultados:" >> "$FINAL_REPORT"
echo "  - Trimming: /home_local/camda/shaday/barbara/trim" >> "$FINAL_REPORT"
echo "  - Taxonomía: /home_local/camda/shaday/barbara/taxonomy" >> "$FINAL_REPORT"
echo "  - Ensamblaje: /home_local/camda/shaday/barbara/assembly" >> "$FINAL_REPORT"
echo "  - Mapeo: /home_local/camda/shaday/barbara/mapping" >> "$FINAL_REPORT"
echo "  - Binning: /home_local/camda/shaday/barbara/binning" >> "$FINAL_REPORT"
echo "  - Anotación: /home_local/camda/shaday/barbara/annotation" >> "$FINAL_REPORT"
echo "  - Análisis de diversidad: /home_local/camda/shaday/barbara/analysis/diversity" >> "$FINAL_REPORT"
echo "  - Logs: $LOG_DIR" >> "$FINAL_REPORT"

echo "Reporte final guardado en: $FINAL_REPORT"

if [ ${#FAILED_STEPS[@]} -eq 0 ]; then
    echo ""
    echo "🎉 ¡Pipeline completado exitosamente!"
    exit 0
else
    echo ""
    echo "⚠️  Pipeline completado con errores. Revisa los logs para más detalles."
    exit 1
fi

