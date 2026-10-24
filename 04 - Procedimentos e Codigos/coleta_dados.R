# Coleta de dados: Rio de Janeiro (3304557) e Niterói (3303302), 2015-2025
# Rode no RStudio. Dados ausentes ficam como NA (nunca zero).
# install.packages(c("rsiconfi", "sidrar", "dplyr", "purrr", "writexl"))

library(jsonlite); library(sidrar); library(dplyr); library(purrr); library(writexl)

munis <- c(RJ = 3304557, Niteroi = 3303302)
anos  <- 2015:2025  # últimos dez anos (2015 a 2025)
dir.create("dados_brutos", showWarnings = FALSE)

# 1) SICONFI - DCA (receitas e despesas). Anexos: I-C (receitas), I-D (despesas por função), I-E (despesas por categoria)
# Confira os nomes dos anexos no portal; podem variar por ano.
anexos <- c("DCA-Anexo I-C", "DCA-Anexo I-D", "DCA-Anexo I-E")
baixa_dca <- function(ano, anexo, ente) {
  res <- list(); offset <- 0
  repeat {
    url <- paste0("https://apidatalake.tesouro.gov.br/ords/siconfi/tt/dca?an_exercicio=", ano,
                  "&no_anexo=", URLencode(anexo, reserved = TRUE),
                  "&id_ente=", ente, "&offset=", offset)
    r <- fromJSON(url)
    if (length(r$items) == 0) break
    res[[length(res) + 1]] <- r$items
    if (!isTRUE(r$hasMore)) break
    offset <- offset + r$limit
    Sys.sleep(0.5)
  }
  bind_rows(res)
}

combos <- expand.grid(ano = anos, anexo = anexos, ente = as.character(munis),
                      stringsAsFactors = FALSE)
dca <- pmap_dfr(combos, function(ano, anexo, ente) {
  tryCatch(
    baixa_dca(ano, anexo, ente),
    error = function(e) { message("Falhou: ", ano, " | ", anexo, " | ", ente); NULL }
  )
})
write.csv(dca, "dados_brutos/siconfi_dca.csv", row.names = FALSE)

# 2) IBGE SIDRA - População (tabela 6579; estimativas) e PIB municipal (tabela 5938)
# period = "all" traz tudo o que a tabela tem; depois filtramos 2015-2025.
# Anos que a tabela ainda não publicou simplesmente não aparecem (ficam NA no painel, nunca zero).
pop <- get_sidra(6579, variable = 9324, period = "all",
                 geo = "City", geo.filter = list(City = as.numeric(munis)))
pib <- get_sidra(5938, variable = 37, period = "all",
                 geo = "City", geo.filter = list(City = as.numeric(munis)))
pop <- pop[pop$Ano %in% anos, ]
pib <- pib[pib$Ano %in% anos, ]
# Se a população de anos recentes não estiver na 6579, procure a tabela de estimativas mais nova no SIDRA.
write.csv(pop, "dados_brutos/ibge_populacao.csv", row.names = FALSE)
write.csv(pib, "dados_brutos/ibge_pib.csv", row.names = FALSE)

# 3) IPCA (tabela 1737, variável 2266 = número-índice)
ipca <- get_sidra(1737, variable = 2266, period = "201501-202512")
write.csv(ipca, "dados_brutos/ibge_ipca.csv", row.names = FALSE)

# 4) Royalties e participações especiais: baixar manualmente na ANP (planilhas por beneficiário)
#    https://www.gov.br/anp/pt-br/assuntos/royalties-e-outras-participacoes
# 5) França: baixar manualmente (OCDE, collectivites-locales.gouv.fr, INSEE, Banco Mundial WDI)

# Deflacionamento (exemplo): valor_real = valor_nominal * (indice_base / indice_ano)
