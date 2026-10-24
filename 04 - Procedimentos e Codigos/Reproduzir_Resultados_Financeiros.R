# Instale o pacote readxl e ggplot2 uma vez se necessário; clique Source.
for (pacote in c('readxl','ggplot2')) if (!requireNamespace(pacote,quietly=TRUE)) install.packages(pacote,repos='https://cloud.r-project.org')
library(readxl)
library(ggplot2)
cat('Selecione o arquivo Base_Auditada_Conciliação_Parcial.xlsx\n')
arquivo <- file.choose()
x <- read_excel(arquivo, sheet='Base_Auditada', col_names=TRUE)
# Leia por posição conforme dicionário: unidade, ano, moeda, desp, própria, transf, royalties, fator
colunas <- c('unidade','ano','moeda','desp_nom','trib_nom','transf_nom','petroleo_nom','fator','desp_real','trib_real','transf_real','petroleo_real','pop','pop_fonte','pib','desp_pib','petroleo_desp','tributos_desp','transferencias_desp','nao_somar','escopo')
stopifnot(ncol(x)==length(colunas))
names(x) <- colunas
x$ano <- as.integer(x$ano)
stopifnot(all(x$ano>=2015 & x$ano<=2024))
stopifnot(all(is.na(x$desp_real) | abs(x$desp_real - x$desp_nom*x$fator)<1))
# Não somar transferências e petróleo, pois sobreposição não foi afastada.
x$desp_index <- ave(x$desp_real, x$unidade, FUN=function(z) 100*z/z[1])
p <- ggplot(x, aes(ano,desp_index,color=unidade,group=unidade)) +
  geom_line(linewidth=1.1) + geom_point(size=2) +
  labs(title='Despesa real 2015 = 100', x='Ano', y='Índice de gasto real (moeda de 2023)', color='Unidade') +
  theme_minimal(base_size=11)
saida <- dirname(arquivo)
ggsave(file.path(saida,'R_Indice_despesa_real.png'),plot=p,width=11,height=6,dpi=170)
y <- subset(x,unidade %in% c('Rio de Janeiro','Niterói'))
p2 <- ggplot(y,aes(ano,100*petroleo_nom/desp_nom,color=unidade,group=unidade)) +
  geom_line(linewidth=1.1)+geom_point(size=2)+
  labs(title='Compensações petrolíferas / despesa nominal',x='Ano',y='% da despesa',color='Município')+
  theme_minimal(base_size=11)
ggsave(file.path(saida,'R_Razao_petroleo_despesa.png'),plot=p2,width=11,height=6,dpi=170)
write.csv2(x,file.path(saida,'Dados_Analise_2015_2024.csv'),row.names=FALSE,na='')
print(aggregate(desp_index ~ unidade,x,FUN=function(z)tail(z,1)))
cat('Resultados salvos ao lado da planilha auditada. Este script é descritivo, NÃO testa causalidade.\n')
