# Reconstroi indicadores a partir do arquivo compilado, sem sobrescrever as planilhas.
# Requer R e o pacote readxl; usar Source no RStudio e escolher Base_Consolidada_Real_Data_RJ_Niteroi_Franca.xlsx.
if (!requireNamespace('readxl', quietly=TRUE)) install.packages('readxl', repos='https://cloud.r-project.org')
cat('Selecione a planilha consolidada da pasta 02_Dados_Brutos_Atualizados.\n')
arquivo <- file.choose()
br <- as.data.frame(readxl::read_excel(arquivo, sheet='Base_Bruta'))
tr <- as.data.frame(readxl::read_excel(arquivo, sheet='Base_Tratada'))
campos <- c('unidade','ano','despesa_total','receita_tributaria','transf_correntes','royalties_compens_total','populacao_ibge','pib_reais')
stopifnot(all(campos %in% names(br)), all(c('Unidade','Ano','Fator_Deflator (Base 2023)') %in% names(tr)))
br <- br[!is.na(br$ano) & br$ano >= 2015 & br$ano <= 2024,]
chave <- paste(as.character(br$unidade), as.integer(br$ano),sep='::')
pos <- match(chave, paste(as.character(tr$Unidade),as.integer(tr$Ano),sep='::'))
stopifnot(!anyNA(pos), length(unique(chave))==30, nrow(br)==30)
fator <- as.numeric(tr[['Fator_Deflator (Base 2023)']][pos])
fator[br$unidade=='França' & br$ano==2024] <- 1/1.02
stopifnot(all(is.finite(fator)),all(fator>0))
nom_desp <- as.numeric(br$despesa_total)
nom_trib <- as.numeric(br$receita_tributaria)
nom_transf <- as.numeric(br$transf_correntes)
nom_pet <- as.numeric(br$royalties_compens_total)
nom_pet[br$unidade=='França'] <- NA_real_ # conceito não aplicável, zero na planilha de entrada não representa dado comparável.
pop <- as.numeric(br$populacao_ibge)
pop[br$unidade=='Rio de Janeiro' & br$ano==2022] <- 6211223
pop[br$unidade=='Niterói' & br$ano==2022] <- 481749
pop[br$ano==2023] <- NA_real_  # ausente na versão auditada
pib <- as.numeric(br$pib_reais)
seguro <- function(num, den) ifelse(is.na(num)|is.na(den)|den==0,NA_real_,num/den)
fonte_pop <- ifelse(br$ano==2022 & br$unidade!='França','Censo IBGE 2022; quebra metodológica',
                   ifelse(is.na(pop),'AUSENTE: não imputado',
                          ifelse(br$unidade=='França','INSEE alegado na base; verificar série','Estimativa recebida; método não identificado')))
moeda <- ifelse(br$unidade=='França','EUR','BRL')
resultado <- data.frame(
 'Unidade'=br$unidade, 'Ano'=as.integer(br$ano), 'Moeda'=moeda,
 'Despesa nominal'=nom_desp,'Tributos próprios nominal'=nom_trib,
 'Transferências correntes nominal'=nom_transf,'Compensações petróleo nominal'=nom_pet,
 'Fator usado (base 2023)'=fator,'Despesa real'=nom_desp*fator,
 'Tributos reais'=nom_trib*fator,'Transferências correntes reais'=nom_transf*fator,
 'Petróleo real'=nom_pet*fator,'População usada'=pop,
 'Fonte população / ressalva'=fonte_pop,'PIB nominal'=pib,
 'Despesa/PIB'=seguro(nom_desp,pib),'Petróleo/Despesa'=seguro(nom_pet,nom_desp),
 'Tributos/Despesa'=seguro(nom_trib,nom_desp),'Transferências correntes/Despesa'=seguro(nom_transf,nom_desp),
 'Soma transf.+petróleo autorizada?'='NÃO; rubricas não conciliadas',
 'Escopo da comparação'=ifelse(br$unidade=='França','APUL nacional; não commune','Município; contabilidade orçamentária'),check.names=FALSE)
stopifnot(nrow(resultado)==30,all(resultado[['Ano']]>=2015 & resultado[['Ano']]<=2024))
saida <- file.path(dirname(arquivo),'Base_Tratada_REPRODUZIDA_2015_2024.csv')
write.csv2(resultado,file=saida,row.names=FALSE,na='',fileEncoding='UTF-8')
message('Base reproduzida: ',saida)
message('Este script NÃO concilia rubricas Siconfi/ANP nem substitui arquivos primários das fontes.')
