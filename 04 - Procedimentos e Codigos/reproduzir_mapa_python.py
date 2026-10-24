"""Mapa exploratório de coocorrências de palavras-chave Scopus.
NÃO é a imagem nativa bibliometrix. Para reproduzir a imagem oficial, execute o .R.
"""
import json,re,unicodedata,math,os
from collections import Counter
from itertools import combinations
import networkx as nx
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib import patheffects
BASE=os.path.dirname(__file__)
J=os.path.join(BASE,'bib_parsed.json')
if not os.path.isfile(J): raise RuntimeError('Para replicar, edite J com caminho para bib_parsed.json')
data=json.load(open(J,encoding='utf-8'))
standard={
 'FISCAL DECENTRALISATION':'FISCAL DECENTRALIZATION',
 'LOCAL GOVERNMENTS':'LOCAL GOVERNMENT',
 'INTERGOVERNMENTAL TRANSFER':'INTERGOVERNMENTAL TRANSFERS',
 'INTERGOVERNMENTAL GRANT':'INTERGOVERNMENTAL GRANTS',
 'PUBLIC EXPENDITURES':'PUBLIC EXPENDITURE',
 'MUNICIPAL GOVERNMENTS':'MUNICIPALITIES',
 'FEDERALISM':'FISCAL FEDERALISM',
 'FLYPAPER EFFECTS':'FLYPAPER EFFECT',
 'FLY PAPER EFFECT':'FLYPAPER EFFECT',
 'PUBLIC SPENDING':'PUBLIC EXPENDITURE',
}
terms=[]
for entry in data:
  s=entry.get('author_keywords') or ''
  arr=re.split(r'\s*;\s*',s)
  clean=set()
  for t in arr:
   t=re.sub(r'\s+',' ',t.strip().upper())
   if not t or len(t)>65:continue
   t=standard.get(t,t)
   clean.add(t)
  if clean:terms.append(clean)
N=len(terms);freq=Counter(t for li in terms for t in li)
keep={t for t,n in freq.items() if n>=6 and n<N*.6}
g=nx.Graph()
for term in sorted(keep):g.add_node(term,freq=freq[term])
for st in terms:
 for a,b in combinations(sorted(st&keep),2):
  if g.has_edge(a,b):g[a][b]['weight']+=1
  else:g.add_edge(a,b,weight=1)
# pruning occasional weak edges for map interpretability
for u,v,w in list(g.edges(data=True)):
 if w['weight']<2:g.remove_edge(u,v)
g.remove_nodes_from(list(nx.isolates(g)))
coms=list(nx.algorithms.community.greedy_modularity_communities(g,weight='weight'))
coms=[c for c in coms if len(c)>=2]
raw=[]
for c in coms:
 nodes=sorted(c)
 inner=sum(g[u][v]['weight'] for u,v in combinations(nodes,2) if g.has_edge(u,v))
 outward=sum(g[u][v]['weight'] for u in c for v in g.neighbors(u) if v not in c)
 dens=2*inner/(len(c)*(len(c)-1)) if len(c)>1 else 0
 top=sorted(c,key=lambda x:freq[x],reverse=True)
 raw.append({'terms':nodes,'top':top[:3],'density':dens,'centrality':outward,'freq':sum(freq[t] for t in c),'size':len(c)})
raw=sorted(raw,key=lambda x:x['freq'],reverse=True)[:10]
if len(raw)<2:raise RuntimeError('Coocorrências insuficientes para mapa temático.')
xmax=max(v['centrality'] for v in raw); ymax=max(v['density'] for v in raw)
fig,ax=plt.subplots(figsize=(12,8))
colors=plt.cm.Set2(range(len(raw)))
for j,r in enumerate(raw):
 x=r['centrality']/xmax*100 if xmax else 0;y=r['density']/ymax*100 if ymax else 0
 ax.scatter(x,y,s=200+r['freq']*6,alpha=.55,color=colors[j],edgecolor='#44536B',linewidth=.9)
 label='\n'.join(r['top'][:2])
 ax.text(x,y,label,ha='center',va='center',fontsize=8.5,fontweight='semibold', color='#202C3B')
ax.axvline(50,ls='--',lw=1,color='#888888');ax.axhline(50,ls='--',lw=1,color='#888888')
ax.set_xlim(-10,110);ax.set_ylim(-10,110)
ax.set_xlabel('Centralidade externa normalizada (proxy exploratória)',fontsize=11)
ax.set_ylabel('Densidade interna normalizada (proxy exploratória)',fontsize=11)
ax.set_title('Mapa temático exploratório | rede de palavras-chave dos autores',fontsize=16,fontweight='bold',pad=16)
ax.text(5,104,'TEMAS ESPECIALIZADOS',fontsize=8,color='#526172')
ax.text(98,104,'TEMAS MOTORES',fontsize=8,color='#526172',ha='right')
ax.text(5,-6,'TEMAS PERIFÉRICOS',fontsize=8,color='#526172')
ax.text(98,-6,'TEMAS BÁSICOS/TRANSVERSAIS',fontsize=8,color='#526172',ha='right')
ax.grid(alpha=.1);fig.tight_layout()
name=os.path.join(BASE,'Mapa_Tematico_Exploratorio_RECONSTRUIDO.png')
fig.savefig(name,dpi=210,bbox_inches='tight',facecolor='white');plt.close(fig)
json.dump({'documentos_com_palavraschave':N,'limiar_termos':6,'normalizacao':standard,'comunidades':raw,'obs':'Mapeamento exploratório com NetworkX, NÃO saída nativa do bibliometrix.'},open(os.path.join(BASE,'metadados_mapa_tematico.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=2)
print('MAPA',name,'N',N,'CLUSTERS',len(raw))
