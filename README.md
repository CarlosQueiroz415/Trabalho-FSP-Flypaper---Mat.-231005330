# O Efeito Flypaper e a Ilusão Fiscal sob a Ótica dos Royalties do Petróleo

**Universidade de Brasília (UnB)**  
**Disciplina:** Finanças do Setor Público — CCA0169, turma 01, 2026.2  
**Trabalho:** P2 — artigo científico e base de dados  
**Recorte empírico:** Rio de Janeiro e Niterói (municípios) e França (agregado das administrações públicas locais — *APUL*)  
**Período principal da análise:** 2015–2024

## Apresentação

Este repositório reúne o artigo científico, as planilhas usadas na construção e no tratamento da base de dados, os códigos e os resultados da análise bibliométrica, além das figuras utilizadas na pesquisa.

**Informo que não tive acesso à base de dados editável do trabalho anterior indicado para a atividade.** Por isso, construí minha própria base desde o início, reunindo e organizando informações disponíveis nas fontes consultadas.

A análise distingue os dois municípios brasileiros do agregado francês *APUL*. Por serem unidades com abrangências e sistemas contábeis diferentes, a comparação é **descritiva e institucional**, e não uma estimativa causal do efeito flypaper ou da ilusão fiscal.

## Organização atual do repositório

```text
Repositorio Flypaper/
├── .gitignore
├── 01 - Artigo/
│   ├── Artigo Flypaper.docx
│   └── Artigo Flypaper.pdf
├── 02 - Dados Brutos/
│   ├── 01 - Base Consolidada Real Data RJ Niteroi Franca.xlsx
│   ├── base_flypaper_RJ_Niteroi_2015_2025.xlsx
│   ├── IPCA.xlsx / PIB.xlsx
│   └── [demais planilhas de origem e séries auxiliares]
├── 03 - Dados Tratados/
│   └── Base Consolidada.xlsx
├── 04 - Procedimentos e Codigos/
│   ├── coleta_dados.R
│   ├── Construir_Base_Tratada_Desde_Consolidada.R
│   ├── Reproduzir_Resultados_Financeiros.R
│   ├── Script_Bibliometria_Scopus.R
│   ├── Reproduzir_Mapa_Bibliometrix.R
│   ├── reproduzir_mapa_python.py
│   └── metadados_mapa_tematico.json
├── 05 - Bibliometria/
│   ├── Scopus_Flypaper_IllusaoFiscal.bib
│   ├── Resultados_Bibliometria.xlsx
│   ├── Base_Bibliometrica_Limpa.csv
│   ├── Matriz_84_Artigos_Citados.csv
│   ├── Mapa Tematico Exploratorio.png
│   └── [gráficos e resumo bibliométrico]
├── 05 - Figuras/
│   ├── fig_01_despesa_real.png
│   ├── fig_02_exposicao_petroleo.png
│   └── fig_03_keywords.png
└── README.md
```

## Conteúdo das pastas

| Pasta | Finalidade |
|---|---|
| `01 - Artigo` | Contém as versões Word e PDF do artigo final utilizado nesta organização. |
| `02 - Dados Brutos` | Reúne as planilhas de coleta e apoio, inclusive séries financeiras francesas, transferências/dotações, população, PIB, inflação e bases compiladas utilizadas na montagem do estudo. Algumas planilhas já são consolidações, não extrações primárias por rubrica. |
| `03 - Dados Tratados` | Contém `Base Consolidada.xlsx`, com as abas `Base_Original`, `Base_Auditada`, `Reconciliacao_Externa`, `Dicionario` e `Fontes`. |
| `04 - Procedimentos e Codigos` | Guarda os scripts R/Python de coleta, reconstrução de indicadores, gráficos financeiros e análise bibliométrica. |
| `05 - Bibliometria` | Contém o BibTeX do Scopus, a base bibliográfica tratada, relatórios, gráficos, matriz de artigos e o mapa temático exploratório. |
| `05 - Figuras` | Reúne os gráficos destacados para a apresentação dos resultados econômicos. |

## Dados, variáveis e transformações

A análise econômica principal cobre **2015 a 2024**, com observações adicionais preservadas em arquivos de entrada. As variáveis trabalhadas incluem despesa, arrecadação própria, transferências correntes, compensações petrolíferas, população, PIB e fatores de atualização monetária.

- **Valores reais:** valores nominais multiplicados pela razão entre o índice de preços do ano-base (2023) e o índice do ano observado, mantendo BRL e EUR em suas respectivas moedas.
- **Indicadores de comparação:** índices de evolução da despesa real, razões nominais entre receitas petrolíferas e despesas, tributos próprios e despesas, transferências correntes e despesas, e indicadores relativos ao PIB quando os dados permitem.
- **Dados ausentes:** lacunas são mantidas como ausências, sem substituir valores indisponíveis por zero.
- **Classificações:** compensações petrolíferas e transferências correntes são apresentadas separadamente. Não se deve somá-las automaticamente, pois a inexistência de sobreposição contábil não foi demonstrada por códigos de receita.
- **França:** a série utilizada representa as *administrations publiques locales* (APUL), e não somente as *communes*. A série e os conceitos não são integralmente equivalentes às contas orçamentárias dos dois municípios brasileiros.

As definições, fontes, unidades e notas de conciliação estão disponíveis principalmente nas abas `Dicionario`, `Fontes` e `Reconciliacao_Externa` da planilha `03 - Dados Tratados/Base Consolidada.xlsx`.

## Registro das atualizações e alterações

Como não recebi uma base anterior editável, não foi possível elaborar uma comparação célula a célula com aquele trabalho. Registro, em vez disso, as operações realizadas **a partir dos arquivos de coleta e das bases compiladas que reuni**:

1. Organização de séries brasileiras e francesas e construção de uma base comparativa para a janela 2015–2024.
2. Preservação dos arquivos de entrada e separação da base consolidada tratada.
3. Aplicação de fatores de deflacionamento para o ano-base de 2023 e construção de indicadores de comparação.
4. Registro dos dados ausentes e identificação das diferenças de escopo institucional.
5. Separação preventiva de compensações petrolíferas e transferências correntes nos indicadores utilizados.
6. Registro de confrontações externas e ressalvas, inclusive sobre a série histórica francesa; a conciliação é **parcial**, não uma auditoria contábil completa.
7. Processamento da exportação Scopus no `bibliometrix`, seleção dos estudos citados e produção de tabelas e figuras bibliométricas.

## Como reproduzir os procedimentos

### 1. Preparar o ambiente

Use o **RStudio** com R instalado. Alguns scripts instalam seus pacotes automaticamente; o arquivo `coleta_dados.R` também contém indicações de pacotes e depende do acesso às APIs externas. Execute os códigos de maneira individual, lendo as mensagens do Console e selecionando o arquivo solicitado.

### 2. Reconstruir os indicadores econômicos

1. Abra `04 - Procedimentos e Codigos/Construir_Base_Tratada_Desde_Consolidada.R` no RStudio.
2. Execute o script e, quando a janela de seleção abrir, escolha **`02 - Dados Brutos/01 - Base Consolidada Real Data RJ Niteroi Franca.xlsx`**. O script lê as abas `Base_Bruta` e `Base_Tratada`.
3. O CSV `Base_Tratada_REPRODUZIDA_2015_2024.csv` será salvo ao lado da planilha selecionada. Esse procedimento reconstrói indicadores a partir da base compilada; não refaz, por si só, a conciliação de todas as rubricas de origem.
4. Para reproduzir os gráficos financeiros, execute `04 - Procedimentos e Codigos/Reproduzir_Resultados_Financeiros.R` e selecione **`03 - Dados Tratados/Base Consolidada.xlsx`**. Embora a mensagem do script cite um nome antigo de arquivo, a aba usada é `Base_Auditada`, existente na planilha atual. As imagens e o CSV gerados serão salvos na mesma pasta da planilha selecionada.

O arquivo `coleta_dados.R` é um roteiro complementar de coleta via fontes externas. Ele pode exigir ajuste ou conferência de APIs, códigos de séries e permissões de acesso; seus resultados não substituem as planilhas preservadas no repositório.

### 3. Reproduzir a bibliometria

1. No RStudio, abra `04 - Procedimentos e Codigos/Script_Bibliometria_Scopus.R` e selecione **`05 - Bibliometria/Scopus_Flypaper_IllusaoFiscal.bib`** quando solicitado. O script cria uma pasta de resultados ao lado do arquivo BibTeX.
2. As tabelas e figuras já existentes no repositório estão em `05 - Bibliometria/`, incluindo `Resultados_Bibliometria.xlsx`, gráficos de produção científica, periódicos e palavras-chave, e `Matriz_84_Artigos_Citados.csv`.
3. O arquivo **`05 - Bibliometria/Mapa Tematico Exploratorio.png`** é uma representação exploratória; **não corresponde à saída nativa** de `bibliometrix::thematicMap()`. Para gerar a versão nativa, execute `04 - Procedimentos e Codigos/Reproduzir_Mapa_Bibliometrix.R` e escolha o mesmo `.bib`. O script salvará uma nova imagem na pasta do BibTeX.

## Observações sobre o alcance da pesquisa

A tese de Ferreira (2021) e a literatura sobre efeito flypaper e ilusão fiscal constituem a referência teórica, e o artigo discute a relação entre financiamento público, receitas petrolíferas e despesas municipais. **As estatísticas descritivas, isoladamente, não comprovam causalidade nem demonstram percepção equivocada dos contribuintes.** A comparação com a França funciona como contraponto institucional, dadas as diferenças de abrangência e contabilidade.

Os resultados apresentados devem ser interpretados juntamente com as notas metodológicas do artigo e com a planilha tratada.

