# ============================================================
# ANALISE BIBLIOMETRICA - EFEITO FLYPAPER E ILUSAO FISCAL
# Fonte: exportacao Scopus em BibTeX
# Projeto: Royalties do petroleo, financas municipais e comparacao Brasil-Franca
# ============================================================
# COMO USAR:
# 1. Abra este arquivo no RStudio.
# 2. Clique em Source (ou execute o script inteiro).
# 3. Selecione Scopus_Flypaper_IllusaoFiscal.bib quando a janela abrir.
# 4. Os resultados serao salvos em uma pasta "Resultados_Bibliometria"
#    ao lado do arquivo BibTeX.
#
# O script nao altera o arquivo BibTeX original.
# ============================================================

# ---- 0. Pacotes ----
pacotes <- c("bibliometrix", "dplyr", "stringr", "ggplot2", "openxlsx",
             "tidyr", "purrr", "tibble")

instalar <- pacotes[!vapply(pacotes, requireNamespace, logical(1), quietly = TRUE)]
if (length(instalar) > 0) {
  install.packages(instalar, dependencies = TRUE)
}

suppressPackageStartupMessages({
  library(bibliometrix)
  library(dplyr)
  library(stringr)
  library(ggplot2)
  library(openxlsx)
  library(tidyr)
  library(purrr)
  library(tibble)
})

# ---- 1. Selecionar arquivo BibTeX ----
message("Selecione o arquivo exportado do Scopus (.bib).")
bib_file <- file.choose()

if (!file.exists(bib_file)) stop("Arquivo BibTeX nao encontrado.")
pasta_base <- dirname(normalizePath(bib_file))
pasta_saida <- file.path(pasta_base, "Resultados_Bibliometria")
dir.create(pasta_saida, showWarnings = FALSE, recursive = TRUE)

# ---- 2. Importar dados ----
message("Importando registros do Scopus...")
M_original <- bibliometrix::convert2df(
  file = bib_file,
  dbsource = "scopus",
  format = "bibtex"
)

if (is.null(M_original) || nrow(M_original) == 0) {
  stop("Nenhum registro foi importado. Confira se o arquivo foi exportado em BibTeX pelo Scopus.")
}

# Padronizar nomes de campos importantes quando presentes
campos_essenciais <- c("AU", "TI", "SO", "PY", "DI", "AB", "DE", "ID", "C1", "TC")
for (campo in campos_essenciais) {
  if (!campo %in% names(M_original)) M_original[[campo]] <- NA_character_
}

# Conversao de ano para numerico
M_original$PY <- suppressWarnings(as.integer(as.character(M_original$PY)))

# ---- 3. Diagnostico inicial ----
normalizar_texto <- function(x) {
  x <- ifelse(is.na(x), "", as.character(x))
  x <- tolower(x)
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT", sub = "")
  x <- stringr::str_replace_all(x, "[^a-z0-9]", "")
  x
}

M <- M_original %>%
  mutate(
    DOI_LIMPO = str_to_lower(str_trim(ifelse(is.na(DI), "", as.character(DI)))),
    TITULO_LIMPO = vapply(TI, normalizar_texto, character(1)),
    ANO = PY,
    FONTE = SO,
    TITULO = TI,
    DOI = DI
  )

# Identificar duplicatas por DOI; quando DOI ausente, usar titulo normalizado
M <- M %>%
  mutate(
    CHAVE_DUP = ifelse(!is.na(DOI_LIMPO) & DOI_LIMPO != "",
                       paste0("doi:", DOI_LIMPO),
                       ifelse(TITULO_LIMPO != "", paste0("titulo:", TITULO_LIMPO),
                              paste0("registro:", row_number())))
  )

duplicatas <- M %>%
  group_by(CHAVE_DUP) %>%
  filter(n() > 1) %>%
  ungroup() %>%
  select(any_of(c("AU", "TI", "SO", "PY", "DI", "TC", "CHAVE_DUP")))

# Mantem a primeira ocorrencia de cada DOI/titulo para analises sem duplicacao
M_limpo <- M %>%
  distinct(CHAVE_DUP, .keep_all = TRUE) %>%
  select(-DOI_LIMPO, -TITULO_LIMPO, -CHAVE_DUP)

# ---- 4. Tabelas de frequencia ----
ano_producao <- M_limpo %>%
  filter(!is.na(PY), PY > 0) %>%
  count(PY, name = "Quantidade_artigos") %>%
  arrange(PY)

fontes <- M_limpo %>%
  filter(!is.na(SO), str_trim(SO) != "") %>%
  count(SO, name = "Quantidade_artigos") %>%
  arrange(desc(Quantidade_artigos), SO) %>%
  rename(Revista = SO)

autores <- M_limpo %>%
  filter(!is.na(AU), str_trim(AU) != "") %>%
  select(AU) %>%
  separate_rows(AU, sep = ";") %>%
  mutate(Autor = str_trim(AU)) %>%
  filter(Autor != "") %>%
  count(Autor, name = "Documentos") %>%
  arrange(desc(Documentos), Autor)

# Keywords DE (Author Keywords) e ID (Keywords Plus/Indexadas)
contar_palavras <- function(dados, campo, nome_saida) {
  if (!campo %in% names(dados)) return(tibble())
  dados %>%
    transmute(palavras = as.character(.data[[campo]])) %>%
    filter(!is.na(palavras), str_trim(palavras) != "") %>%
    separate_rows(palavras, sep = ";") %>%
    mutate(palavra = str_squish(palavras)) %>%
    filter(palavra != "") %>%
    count(palavra, name = "Frequencia") %>%
    arrange(desc(Frequencia), palavra) %>%
    rename(!!nome_saida := palavra)
}

palavras_autores <- contar_palavras(M_limpo, "DE", "Palavra_chave")
palavras_indexadas <- contar_palavras(M_limpo, "ID", "Termo_indexado")

# Documentos por ano e revista
ano_revista <- M_limpo %>%
  filter(!is.na(PY), !is.na(SO), str_trim(SO) != "") %>%
  count(PY, SO, name = "Artigos") %>%
  arrange(PY, desc(Artigos))

# Resumo de cobertura dos dados
resumo <- tibble(
  Indicador = c(
    "Registros importados do Scopus",
    "Registros apos remocao de duplicatas",
    "Duplicatas identificadas (linhas)",
    "Registros com resumo (abstract)",
    "Registros com DOI",
    "Registros com palavras-chave dos autores",
    "Ano inicial",
    "Ano final"
  ),
  Valor = c(
    nrow(M_original),
    nrow(M_limpo),
    nrow(duplicatas),
    sum(!is.na(M_limpo$AB) & str_trim(as.character(M_limpo$AB)) != ""),
    sum(!is.na(M_limpo$DI) & str_trim(as.character(M_limpo$DI)) != ""),
    sum(!is.na(M_limpo$DE) & str_trim(as.character(M_limpo$DE)) != ""),
    ifelse(all(is.na(M_limpo$PY)), NA, min(M_limpo$PY, na.rm = TRUE)),
    ifelse(all(is.na(M_limpo$PY)), NA, max(M_limpo$PY, na.rm = TRUE))
  )
)

# ---- 5. Graficos PNG ----
tema <- theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1))

if (nrow(ano_producao) > 0) {
  p_ano <- ggplot(ano_producao, aes(x = PY, y = Quantidade_artigos)) +
    geom_col() +
    labs(title = "Producao cientifica anual", x = "Ano", y = "Numero de artigos") +
    tema
  ggsave(file.path(pasta_saida, "01_producao_cientifica_anual.png"),
         p_ano, width = 10, height = 6, dpi = 300)
}

if (nrow(fontes) > 0) {
  top_fontes <- fontes %>% slice_max(Quantidade_artigos, n = 20, with_ties = FALSE)
  p_fontes <- ggplot(top_fontes,
                     aes(x = reorder(Revista, Quantidade_artigos), y = Quantidade_artigos)) +
    geom_col() + coord_flip() +
    labs(title = "20 fontes mais relevantes", x = "Revista", y = "Numero de artigos") +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(face = "bold"))
  ggsave(file.path(pasta_saida, "02_fontes_mais_relevantes.png"),
         p_fontes, width = 10, height = 8, dpi = 300)
}

if (nrow(palavras_autores) > 0) {
  top_kw <- palavras_autores %>% slice_max(Frequencia, n = 25, with_ties = FALSE)
  p_kw <- ggplot(top_kw, aes(x = reorder(Palavra_chave, Frequencia), y = Frequencia)) +
    geom_col() + coord_flip() +
    labs(title = "25 palavras-chave mais frequentes", x = "Palavra-chave", y = "Frequencia") +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(face = "bold"))
  ggsave(file.path(pasta_saida, "03_palavras_chave.png"),
         p_kw, width = 10, height = 8, dpi = 300)
}

# ---- 6. Analise bibliometrica com bibliometrix ----
# Exporta sumario textual da analise. Se a versao instalada tiver alguma
# incompatibilidade, o restante do script continua.
tryCatch({
  resultados_biblio <- bibliometrix::biblioAnalysis(M_limpo, sep = ";")
  captura <- capture.output(
    print(summary(resultados_biblio, k = 20, pause = FALSE))
  )
  writeLines(captura, file.path(pasta_saida, "04_sumario_bibliometrix.txt"))
}, error = function(e) {
  writeLines(paste("Nao foi possivel gerar o sumario bibliometrix:", e$message),
             file.path(pasta_saida, "04_sumario_bibliometrix.txt"))
})

# Mapa tematico (usa palavras-chave dos autores). Pode falhar se houver
# poucas palavras-chave ou incompatibilidade com a versao do pacote.
if ("DE" %in% names(M_limpo) &&
    sum(!is.na(M_limpo$DE) & str_trim(as.character(M_limpo$DE)) != "") >= 10) {
  tryCatch({
    png(file.path(pasta_saida, "05_mapa_tematico.png"),
        width = 1800, height = 1200, res = 180)
    bibliometrix::thematicMap(
      M_limpo,
      field = "DE",
      n = 250,
      minfreq = 3,
      stemming = FALSE,
      size = 0.5,
      n.labels = 3,
      repel = TRUE
    )
    dev.off()
  }, error = function(e) {
    if (grDevices::dev.cur() > 1) dev.off()
    writeLines(paste("Mapa tematico nao gerado:", e$message),
               file.path(pasta_saida, "05_erro_mapa_tematico.txt"))
  })
}

# ---- 7. Exportar tabelas para Excel e CSV ----
# Remover colunas internas que nao interessam ao usuario
M_export <- M_limpo %>%
  select(-any_of(c("DOI_LIMPO", "TITULO_LIMPO", "CHAVE_DUP")))

abas <- list(
  "Resumo" = resumo,
  "Base_limpa" = M_export,
  "Producao_anual" = ano_producao,
  "Revistas" = fontes,
  "Autores" = autores,
  "Palavras_autores" = palavras_autores,
  "Termos_indexados" = palavras_indexadas,
  "Ano_revista" = ano_revista,
  "Duplicatas" = duplicatas
)

openxlsx::write.xlsx(abas,
                     file = file.path(pasta_saida, "Resultados_Bibliometria.xlsx"),
                     overwrite = TRUE)

write.csv(M_export, file.path(pasta_saida, "Base_Bibliometrica_Limpa.csv"),
          row.names = FALSE, fileEncoding = "UTF-8", na = "")
write.csv(resumo, file.path(pasta_saida, "Resumo_da_Base.csv"),
          row.names = FALSE, fileEncoding = "UTF-8", na = "")

# ---- 8. Mensagem final ----
cat("\n============================================\n")
cat("ANALISE CONCLUIDA\n")
cat("Registros importados:", nrow(M_original), "\n")
cat("Registros apos deduplicacao:", nrow(M_limpo), "\n")
cat("Pasta de resultados:", pasta_saida, "\n")
cat("Arquivo Excel: Resultados_Bibliometria.xlsx\n")
cat("Graficos PNG e sumario bibliometrix tambem foram salvos.\n")
cat("============================================\n")
