# README - Scripts de Análisis Metagenómico (Actualizado para Micromamba)

## Descripción General

Este conjunto de scripts está diseñado para realizar un análisis metagenómico completo de 2 muestras (CT y ST) con reads paired-end. El pipeline incluye control de calidad, trimming, clasificación taxonómica, ensamblaje, mapeo, binning y anotación taxonómica.

**ACTUALIZACIÓN**: Los scripts han sido configurados para usar **micromamba** en lugar de conda, con ambientes ubicados en `/home_local/camda/micromamba/envs/`.

## Estructura de Archivos

### Datos de Entrada
- **Directorio de reads**: `/home_local/camda/shaday/barbara/reads`
  - `CT_FKDN25H000391-1A_22NWHGLT4_L5_1.fq.gz` (forward)
  - `CT_FKDN25H000391-1A_22NWHGLT4_L5_2.fq.gz` (reverse)
  - `ST_FKDN25H000392-1A_22NWHGLT4_L5_1.fq.gz` (forward)
  - `ST_FKDN25H000392-1A_22NWHGLT4_L5_2.fq.gz` (reverse)

- **Base de datos Kraken2**: `/home_local/compartida/camda2024/k2_pluspfp_20250402/`

### Directorios de Salida
- **Scripts**: `/home_local/camda/shaday/barbara/src`
- **Trimming**: `/home_local/camda/shaday/barbara/trim`
- **Taxonomía**: `/home_local/camda/shaday/barbara/taxonomy`
- **Ensamblaje**: `/home_local/camda/shaday/barbara/assembly`
- **Mapeo**: `/home_local/camda/shaday/barbara/mapping`
- **Binning**: `/home_local/camda/shaday/barbara/binning`
- **Anotación**: `/home_local/camda/shaday/barbara/annotation`

## Scripts Incluidos

### 1. Setup y Verificación
- **00_setup_directories.sh**: Verifica estructura de directorios y crea directorios de salida

### 2. Control de Calidad y Trimming
- **01_fastqc_initial.sh**: FastQC antes del trimming (ambiente: metagenomics)
- **02_trimgalore.sh**: Trimming con TrimGalore (ambiente: trimgalore)
- **03_fastqc_after.sh**: FastQC después del trimming (ambiente: metagenomics)

### 3. Clasificación Taxonómica
- **04_kraken2.sh**: Clasificación taxonómica con Kraken2 (ambiente: metagenomics)
- **05_kraken_biom.sh**: Generación de archivos BIOM (ambiente: metagenomics)
- **05b_bracken.sh**: Refinamiento de abundancias con Bracken (ambiente: metagenomics)

### 4. Ensamblaje
- **06_megahit.sh**: Ensamblaje con MEGAHIT (ambiente: megahit)

### 5. Mapeo y Binning
- **07_mapping.sh**: Mapeo de reads a contigs (ambiente: mapping_env)
- **08_binning.sh**: Binning con MetaBAT2, MaxBin2 y CONCOCT (ambiente: binning_env)
- **09_dastool.sh**: Refinamiento de bins con DasTool (ambiente: binning_env)

### 6. Anotación
- **10_gtdbtk.sh**: Anotación taxonómica con GTDBtk (ambiente: gtdbtk-2.1.1)

### 7. Análisis de Diversidad
- **11_diversity_analysis.sh**: Análisis de diversidad alfa, beta y abundancias (ambiente: metagenomics)
- **11_diversity_analysis.R**: Script R para análisis estadístico y gráficas

### 8. Script Maestro
- **run_pipeline.sh**: Ejecuta todo el pipeline o pasos seleccionados

## Ambientes Micromamba Requeridos

Los scripts están configurados para usar micromamba con ambientes ubicados en:
`/home_local/camda/micromamba/envs/`

### Ambientes necesarios:
1. **metagenomics**: FastQC, Kraken2, Bracken, R, phyloseq, herramientas generales
2. **trimgalore**: TrimGalore
3. **megahit**: MEGAHIT
4. **mapping_env**: BWA, samtools
5. **binning_env**: MetaBAT2, MaxBin2, CONCOCT, DasTool
6. **gtdbtk-2.1.1**: GTDBtk

### Verificación de ambientes:
```bash
# Verificar que micromamba esté disponible
micromamba --version

# Listar ambientes disponibles
micromamba env list

# Verificar ambientes específicos
ls -la /home_local/camda/micromamba/envs/
```

## Uso

### Opción 1: Pipeline Completo
```bash
cd /home_local/camda/shaday/barbara/src
./run_pipeline.sh
```

### Opción 2: Scripts Individuales
```bash
cd /home_local/camda/shaday/barbara/src

# 1. Setup
./00_setup_directories.sh

# 2. Control de calidad
./01_fastqc_initial.sh
./02_trimgalore.sh
./03_fastqc_after.sh

# 3. Taxonomía
./04_kraken2.sh
./05_kraken_biom.sh
./05b_bracken.sh

# 4. Ensamblaje
./06_megahit.sh

# 5. Mapeo y binning
./07_mapping.sh
./08_binning.sh
./09_dastool.sh

# 6. Anotación
./10_gtdbtk.sh

# 7. Análisis de diversidad
./11_diversity_analysis.sh
```

## Características de Micromamba

### Ventajas sobre Conda:
- **Más rápido**: Resolución de dependencias más eficiente
- **Menor uso de memoria**: Footprint más pequeño
- **Compatible**: Usa el mismo formato de paquetes que conda
- **Standalone**: No requiere instalación base de Anaconda/Miniconda

### Activación de ambientes:
Los scripts usan la siguiente sintaxis para activar ambientes:
```bash
eval "$(micromamba shell hook --shell bash)"
micromamba activate /home_local/camda/micromamba/envs/AMBIENTE
```

## Instalación de Micromamba (si es necesario)

Si micromamba no está instalado:
```bash
# Descargar e instalar micromamba
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
sudo mv bin/micromamba /usr/local/bin/

# Inicializar
micromamba shell init -s bash
source ~/.bashrc
```

## Resultados Esperados

### Control de Calidad
- Reportes FastQC antes y después del trimming
- Reads trimmed de alta calidad

### Taxonomía
- Clasificación taxonómica de reads
- Archivos BIOM para análisis downstream
- Reportes de abundancia taxonómica
- Estimaciones refinadas de abundancia a nivel de especie con Bracken

### Ensamblaje
- Contigs ensamblados (mínimo 500 bp)
- Estadísticas de ensamblaje (N50, longitud total, etc.)

### Binning
- Bins de genomas individuales
- Bins refinados con DasTool
- Evaluación de calidad de bins

### Anotación
- Clasificación taxonómica de MAGs con GTDBtk
- Identificación de especies bacterianas y arqueanas

### Análisis de Diversidad
- Diversidad alfa (Shannon, Simpson, Chao1, Observed)
- Diversidad beta (NMDS, PCoA con distancia Bray-Curtis)
- Gráficas de abundancia relativa por nivel taxonómico
- Análisis estadístico y visualizaciones en R
- Reporte HTML interactivo

## Tiempo Estimado de Ejecución

- **FastQC**: 5-10 minutos por paso
- **TrimGalore**: 30-60 minutos
- **Kraken2**: 1-2 horas
- **Bracken**: 30-60 minutos
- **MEGAHIT**: 2-6 horas
- **Mapeo**: 1-2 horas
- **Binning**: 2-4 horas
- **GTDBtk**: 4-8 horas
- **Análisis de diversidad**: 30-60 minutos

**Total estimado**: 13-25 horas

## Requisitos del Sistema

- **CPU**: Mínimo 8 cores (recomendado 16+)
- **RAM**: Mínimo 32 GB (recomendado 64+ GB)
- **Almacenamiento**: Mínimo 100 GB libres
- **Micromamba**: Instalado y configurado
- **Base de datos GTDBtk**: Configurar variable `GTDBTK_DATA_PATH`

## Solución de Problemas

### Errores Comunes

1. **Micromamba no encontrado**
   ```bash
   # Verificar instalación
   which micromamba
   micromamba --version
   
   # Reinicializar si es necesario
   micromamba shell init -s bash
   source ~/.bashrc
   ```

2. **Ambiente no encontrado**
   ```bash
   # Verificar ubicación de ambientes
   ls -la /home_local/camda/micromamba/envs/
   
   # Activar manualmente para probar
   micromamba activate /home_local/camda/micromamba/envs/metagenomics
   ```

3. **Archivos no encontrados**
   - Verificar rutas de archivos de entrada
   - Ejecutar `00_setup_directories.sh` primero

4. **Memoria insuficiente**
   - Reducir número de threads en scripts
   - Usar parámetro `--memory` en MEGAHIT

5. **Base de datos GTDBtk**
   ```bash
   # Configurar variable de entorno
   export GTDBTK_DATA_PATH=/home_local/compartida/gtdbtk_data
   
   # Verificar que la base de datos esté completa
   ls -la $GTDBTK_DATA_PATH
   ```

### Logs y Debugging

- Los logs se guardan en `/home_local/camda/shaday/barbara/logs/`
- Cada script genera su propio archivo de log
- Revisar logs para errores específicos

### Verificación de Ambientes

El script maestro incluye verificación automática de:
- Disponibilidad de micromamba
- Existencia de ambientes requeridos
- Rutas de directorios

## Migración desde Conda

Si previamente usabas conda, los cambios principales son:
- `conda activate` → `micromamba activate /ruta/completa/al/ambiente`
- `conda deactivate` → `micromamba deactivate`
- Inicialización con `eval "$(micromamba shell hook --shell bash)"`

## Contacto y Soporte

Para problemas o preguntas sobre los scripts, revisar:
1. Logs de ejecución
2. Documentación de micromamba
3. Verificar requisitos del sistema
4. Estado de ambientes micromamba

## Notas Adicionales

- Los scripts están optimizados para 2 muestras específicas
- Modificar nombres de muestras en scripts si es necesario
- Micromamba es más eficiente que conda para este tipo de workflows
- Mantener suficiente espacio en disco durante todo el proceso
- Los ambientes deben estar preinstalados en `/home_local/camda/micromamba/envs/`

