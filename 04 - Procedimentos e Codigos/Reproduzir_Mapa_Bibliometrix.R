# MAPA TEMÁTICO OFICIAL DO BIBLIOMETRIX — código para executar no RStudio.
# Abrir RStudio > File > Open File > este .R > Source > selecionar .bib do Scopus.
# Não é necessário biblioshiny(). A imagem é criada diretamente pelo bibliometrix.
for (pk in c('bibliometrix','ggplot2')) {
  if (!requireNamespace(pk, quietly=TRUE)) install.packages(pk, repos='https://cloud.r-project.org')
}
library(bibliometrix)
library(ggplot2)
message('Selecione o arquivo .bib ORIGINAL do Scopus (não o Excel).')
input <- file.choose()
M <- convert2df(file=input, dbsource='scopus', format='bibtex')
if (!'DE' %in% colnames(M)) stop('Campo DE (Author Keywords) ausente: reexporte do Scopus incluindo palavras-chave.')
M$DE <- toupper(trimws(as.character(M$DE)))
M$DE <- gsub('FISCAL DECENTRALISATION', 'FISCAL DECENTRALIZATION', M$DE, fixed=TRUE)
M$DE <- gsub('LOCAL GOVERNMENTS', 'LOCAL GOVERNMENT', M$DE, fixed=TRUE)
M$DE <- gsub('INTERGOVERNMENTAL TRANSFER;', 'INTERGOVERNMENTAL TRANSFERS;', M$DE, fixed=TRUE)
M$DE <- gsub('INTERGOVERNMENTAL GRANT;', 'INTERGOVERNMENTAL GRANTS;', M$DE, fixed=TRUE)
M$DE <- gsub('FLY PAPER EFFECT', 'FLYPAPER EFFECT', M$DE, fixed=TRUE)
if (sum(!is.na(M$DE) & nzchar(M$DE))<30) stop('Poucos registros com DE para mapa temático.')
set.seed(2026)
map <- tryCatch(
  thematicMap(M, field='DE', n=100, minfreq=5, stemming=FALSE, n.labels=2,
             size=0.55, cluster='walktrap', repel=TRUE),
  error=function(e){message('Tentativa padrão falhou: ',conditionMessage(e));
    thematicMap(M, field='DE', n=70, minfreq=3, stemming=FALSE, n.labels=1,
               size=0.5, cluster='louvain', repel=TRUE)}
)
if (is.null(map$map)) stop('bibliometrix não gerou objeto map (ggplot).')
saida <- file.path(dirname(input),'05_mapa_tematico_BIBLIOMETRIX_CORRIGIDO.png')
ggsave(saida, plot=map$map, width=12, height=8, dpi=200, bg='white')
print(map$map)
write.csv(map$clusters, file=file.path(dirname(input),'clusters_mapa_bibliometrix.csv'), row.names=TRUE)
message('IMAGEM CRIADA: ',saida)
