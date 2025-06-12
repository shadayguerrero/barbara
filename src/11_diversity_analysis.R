# Script de Análisis de Diversidad Metagenómica
# Basado en archivos BIOM generados por Kraken2/Bracken
# Autor: Script generado para análisis metagenómico
# Fecha: Sys.Date()

# Cargar librerías necesarias
suppressPackageStartupMessages({
  library(phyloseq)
  library(ggplot2)
  library(RColorBrewer)
  library(vegan)
  library(patchwork)
  library(dplyr)
  library(tidyr)
  library(gridExtra)
  library(scales)
})

# Función principal de análisis metagenómico
analiza_metagenoma_biom <- function(biom_path, 
                                   metadata_path = NULL,
                                   niveles_tax = c("Phylum", "Class", "Order", "Family", "Genus", "Species"), 
                                   min_abundancia = 1, 
                                   output_dir = "./figuras",
                                   prefijo = "metagenoma") {
  
  cat("=== INICIANDO ANÁLISIS DE DIVERSIDAD METAGENÓMICA ===\n")
  cat("Archivo BIOM:", biom_path, "\n")
  cat("Directorio de salida:", output_dir, "\n")
  
  # Crear directorio de salida
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Verificar que el archivo BIOM existe
  if (!file.exists(biom_path)) {
    stop("ERROR: Archivo BIOM no encontrado: ", biom_path)
  }
  
  # Importar archivo BIOM
  cat("\n1. Importando archivo BIOM...\n")
  tryCatch({
    physeq <- import_biom(biom_path)
    cat("   ✓ Archivo BIOM importado exitosamente\n")
  }, error = function(e) {
    stop("ERROR importando archivo BIOM: ", e$message)
  })
  
  # Limpiar nombres de taxonomía (remover prefijos de Kraken)
  if (!is.null(tax_table(physeq))) {
    # Remover prefijos como "k__", "p__", etc.
    physeq@tax_table@.Data <- gsub("^[a-z]__", "", physeq@tax_table@.Data)
    
    # Asignar nombres de columnas estándar
    if (ncol(tax_table(physeq)) >= 7) {
      colnames(physeq@tax_table@.Data) <- c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species")
    } else {
      # Asignar nombres disponibles
      possible_names <- c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species")
      colnames(physeq@tax_table@.Data) <- possible_names[1:ncol(tax_table(physeq))]
    }
    cat("   ✓ Taxonomía limpiada y estandarizada\n")
  }
  
  # Agregar metadatos si se proporcionan
  if (!is.null(metadata_path) && file.exists(metadata_path)) {
    cat("2. Cargando metadatos...\n")
    metadata <- read.table(metadata_path, header = TRUE, sep = "\t", row.names = 1)
    sample_data(physeq) <- sample_data(metadata)
    cat("   ✓ Metadatos agregados\n")
  } else {
    # Crear metadatos básicos basados en nombres de muestras
    cat("2. Creando metadatos básicos...\n")
    sample_names <- sample_names(physeq)
    metadata <- data.frame(
      SampleID = sample_names,
      Group = ifelse(grepl("^CT", sample_names), "Control", "Treatment"),
      row.names = sample_names
    )
    sample_data(physeq) <- sample_data(metadata)
    cat("   ✓ Metadatos básicos creados (CT=Control, ST=Treatment)\n")
  }
  
  # Estadísticas básicas
  cat("\n3. Estadísticas básicas del dataset:\n")
  cat("   - Número de muestras:", nsamples(physeq), "\n")
  cat("   - Número de taxa:", ntaxa(physeq), "\n")
  cat("   - Total de reads:", sum(sample_sums(physeq)), "\n")
  cat("   - Reads por muestra:\n")
  for (i in 1:nsamples(physeq)) {
    cat("     ", sample_names(physeq)[i], ":", sample_sums(physeq)[i], "\n")
  }
  
  # Guardar estadísticas en archivo
  stats_file <- file.path(output_dir, paste0(prefijo, "_estadisticas.txt"))
  sink(stats_file)
  cat("=== ESTADÍSTICAS DEL DATASET METAGENÓMICO ===\n")
  cat("Fecha:", as.character(Sys.Date()), "\n")
  cat("Archivo BIOM:", biom_path, "\n\n")
  cat("Número de muestras:", nsamples(physeq), "\n")
  cat("Número de taxa:", ntaxa(physeq), "\n")
  cat("Total de reads:", sum(sample_sums(physeq)), "\n\n")
  cat("Reads por muestra:\n")
  for (i in 1:nsamples(physeq)) {
    cat(sample_names(physeq)[i], ":", sample_sums(physeq)[i], "\n")
  }
  sink()
  
  # ANÁLISIS DE DIVERSIDAD ALFA
  cat("\n4. Calculando diversidad alfa...\n")
  
  # Calcular índices de diversidad
  alpha_div <- estimate_richness(physeq, measures = c("Observed", "Chao1", "Shannon", "Simpson"))
  alpha_div$Sample <- rownames(alpha_div)
  alpha_div$Group <- sample_data(physeq)$Group
  
  # Gráfica de diversidad alfa
  alpha_plot <- plot_richness(physeq, x = "Group", measures = c("Observed", "Chao1", "Shannon", "Simpson")) +
    geom_boxplot(alpha = 0.7) +
    geom_point(size = 3, alpha = 0.8) +
    theme_bw() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    labs(title = "Diversidad Alfa", 
         subtitle = "Comparación entre grupos",
         x = "Grupo", y = "Valor del índice") +
    scale_color_brewer(type = "qual", palette = "Set1")
  
  ggsave(file.path(output_dir, paste0(prefijo, "_diversidad_alpha.png")), 
         alpha_plot, width = 12, height = 8, dpi = 300)
  cat("   ✓ Gráfica de diversidad alfa guardada\n")
  
  # Guardar tabla de diversidad alfa
  write.table(alpha_div, file.path(output_dir, paste0(prefijo, "_diversidad_alpha.txt")), 
              sep = "\t", quote = FALSE, row.names = FALSE)
  
  # ANÁLISIS DE DIVERSIDAD BETA
  cat("\n5. Calculando diversidad beta...\n")
  
  # Transformar a abundancias relativas
  physeq_rel <- transform_sample_counts(physeq, function(x) x / sum(x) * 100)
  
  # Ordenación NMDS con distancia Bray-Curtis
  set.seed(123)  # Para reproducibilidad
  ord_nmds <- ordinate(physeq_rel, method = "NMDS", distance = "bray")
  
  # Gráfica NMDS
  beta_plot_nmds <- plot_ordination(physeq_rel, ord_nmds, color = "Group") +
    geom_point(size = 4, alpha = 0.8) +
    stat_ellipse(type = "norm", linetype = 2) +
    theme_bw() +
    labs(title = "Diversidad Beta - NMDS (Bray-Curtis)",
         subtitle = paste("Stress:", round(ord_nmds$stress, 3))) +
    scale_color_brewer(type = "qual", palette = "Set1")
  
  ggsave(file.path(output_dir, paste0(prefijo, "_diversidad_beta_nmds.png")), 
         beta_plot_nmds, width = 10, height = 8, dpi = 300)
  
  # PCoA con distancia Bray-Curtis
  ord_pcoa <- ordinate(physeq_rel, method = "PCoA", distance = "bray")
  
  # Gráfica PCoA
  beta_plot_pcoa <- plot_ordination(physeq_rel, ord_pcoa, color = "Group") +
    geom_point(size = 4, alpha = 0.8) +
    stat_ellipse(type = "norm", linetype = 2) +
    theme_bw() +
    labs(title = "Diversidad Beta - PCoA (Bray-Curtis)",
         subtitle = paste("Varianza explicada: PC1 =", 
                         round(ord_pcoa$values$Relative_eig[1] * 100, 1), "%, PC2 =",
                         round(ord_pcoa$values$Relative_eig[2] * 100, 1), "%")) +
    scale_color_brewer(type = "qual", palette = "Set1")
  
  ggsave(file.path(output_dir, paste0(prefijo, "_diversidad_beta_pcoa.png")), 
         beta_plot_pcoa, width = 10, height = 8, dpi = 300)
  
  cat("   ✓ Gráficas de diversidad beta guardadas (NMDS y PCoA)\n")
  
  # ANÁLISIS DE ABUNDANCIA POR NIVELES TAXONÓMICOS
  cat("\n6. Generando gráficas de abundancia por niveles taxonómicos...\n")
  
  for (nivel_tax in niveles_tax) {
    if (nivel_tax %in% colnames(tax_table(physeq))) {
      cat("   Procesando nivel:", nivel_tax, "\n")
      
      # Filtrar taxa sin asignación
      physeq_filt <- subset_taxa(physeq, !is.na(tax_table(physeq)[, nivel_tax]) & 
                                tax_table(physeq)[, nivel_tax] != "" &
                                tax_table(physeq)[, nivel_tax] != "unclassified")
      
      if (ntaxa(physeq_filt) == 0) {
        cat("     ⚠ No hay taxa válidos para el nivel", nivel_tax, "\n")
        next
      }
      
      # Aglomerar por nivel taxonómico
      glom_abs <- tax_glom(physeq_filt, taxrank = nivel_tax)
      glom_rel <- tax_glom(physeq_rel, taxrank = nivel_tax)
      
      # Convertir a dataframe
      df_abs <- psmelt(glom_abs)
      df_rel <- psmelt(glom_rel)
      
      # Agrupar abundancias menores
      df_rel[[nivel_tax]] <- as.character(df_rel[[nivel_tax]])
      df_abs[[nivel_tax]] <- as.character(df_abs[[nivel_tax]])
      
      # Calcular abundancia media y agrupar taxa raros
      media_taxa <- df_rel %>%
        group_by(!!sym(nivel_tax)) %>%
        summarise(media = mean(Abundance), .groups = 'drop')
      
      taxones_bajos <- media_taxa[[nivel_tax]][media_taxa$media < min_abundancia]
      
      df_rel[[nivel_tax]] <- ifelse(df_rel[[nivel_tax]] %in% taxones_bajos, "Others", df_rel[[nivel_tax]])
      df_abs[[nivel_tax]] <- ifelse(df_abs[[nivel_tax]] %in% taxones_bajos, "Others", df_abs[[nivel_tax]])
      
      # Colores
      n_taxa <- length(unique(df_rel[[nivel_tax]]))
      if (n_taxa <= 8) {
        colores <- brewer.pal(max(3, n_taxa), "Dark2")
      } else {
        colores <- colorRampPalette(brewer.pal(8, "Dark2"))(n_taxa)
      }
      
      # Gráfica de abundancia absoluta
      abs_plot <- ggplot(df_abs, aes(x = Sample, y = Abundance, fill = !!sym(nivel_tax))) +
        geom_bar(stat = "identity") +
        theme_bw() +
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5),
              legend.position = "bottom") +
        scale_fill_manual(values = colores) +
        scale_y_continuous(labels = comma) +
        labs(title = paste("Abundancia absoluta por", nivel_tax),
             x = "Muestra", y = "Número de reads", fill = nivel_tax) +
        guides(fill = guide_legend(ncol = 3))
      
      # Gráfica de abundancia relativa
      rel_plot <- ggplot(df_rel, aes(x = Sample, y = Abundance, fill = !!sym(nivel_tax))) +
        geom_bar(stat = "identity") +
        theme_bw() +
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5),
              legend.position = "bottom") +
        scale_fill_manual(values = colores) +
        labs(title = paste("Abundancia relativa por", nivel_tax, "(%)"),
             x = "Muestra", y = "Abundancia relativa (%)", fill = nivel_tax) +
        guides(fill = guide_legend(ncol = 3))
      
      # Combinar gráficas
      combined_plot <- abs_plot / rel_plot
      
      # Guardar gráfica
      ggsave(file.path(output_dir, paste0(prefijo, "_abundancia_", tolower(nivel_tax), ".png")),
             combined_plot, width = 14, height = 12, dpi = 300)
      
      # Guardar tabla de abundancias
      write.table(df_rel, file.path(output_dir, paste0(prefijo, "_abundancia_", tolower(nivel_tax), ".txt")), 
                  sep = "\t", quote = FALSE, row.names = FALSE)
      
      cat("     ✓ Gráfica y tabla guardadas para", nivel_tax, "\n")
    } else {
      cat("     ⚠ Nivel taxonómico", nivel_tax, "no encontrado en los datos\n")
    }
  }
  
  # RESUMEN FINAL
  cat("\n7. Generando resumen final...\n")
  
  # Crear gráfica resumen con diversidad alfa y beta
  summary_plot <- (alpha_plot | beta_plot_nmds) / beta_plot_pcoa
  
  ggsave(file.path(output_dir, paste0(prefijo, "_resumen_diversidad.png")),
         summary_plot, width = 16, height = 12, dpi = 300)
  
  cat("   ✓ Gráfica resumen de diversidad guardada\n")
  
  cat("\n=== ANÁLISIS COMPLETADO ===\n")
  cat("Todos los archivos guardados en:", output_dir, "\n")
  
  # Retornar objeto phyloseq para análisis adicionales
  return(physeq)
}

# Función para ejecutar análisis con archivos específicos del pipeline
ejecutar_analisis_pipeline <- function(base_dir = "/home_local/camda/shaday/barbara") {
  
  cat("=== EJECUTANDO ANÁLISIS DE DIVERSIDAD DEL PIPELINE ===\n")
  
  # Directorios
  biom_dir <- file.path(base_dir, "taxonomy", "biom_files")
  output_dir <- file.path(base_dir, "analysis", "diversity")
  
  # Crear directorio de salida
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Buscar archivo BIOM combinado
  biom_files <- list.files(biom_dir, pattern = "combined.*\\.biom$", full.names = TRUE)
  
  if (length(biom_files) == 0) {
    cat("ERROR: No se encontraron archivos BIOM en", biom_dir, "\n")
    cat("Archivos disponibles:\n")
    print(list.files(biom_dir))
    return(NULL)
  }
  
  # Usar el primer archivo BIOM encontrado
  biom_file <- biom_files[1]
  cat("Usando archivo BIOM:", biom_file, "\n")
  
  # Ejecutar análisis
  physeq <- analiza_metagenoma_biom(
    biom_path = biom_file,
    niveles_tax = c("Phylum", "Class", "Order", "Family", "Genus", "Species"),
    min_abundancia = 1,
    output_dir = output_dir,
    prefijo = "metagenoma_CT_ST"
  )
  
  return(physeq)
}

# Función principal para llamar desde línea de comandos
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) == 0) {
    # Ejecutar con configuración por defecto del pipeline
    physeq <- ejecutar_analisis_pipeline()
  } else if (length(args) >= 1) {
    # Ejecutar con archivo BIOM específico
    biom_path <- args[1]
    output_dir <- ifelse(length(args) >= 2, args[2], "./figuras")
    min_abundancia <- ifelse(length(args) >= 3, as.numeric(args[3]), 1)
    
    physeq <- analiza_metagenoma_biom(
      biom_path = biom_path,
      output_dir = output_dir,
      min_abundancia = min_abundancia
    )
  }
  
  cat("\n¡Análisis completado exitosamente!\n")
}

# Ejecutar función principal si el script se ejecuta directamente
if (!interactive()) {
  main()
}

