# SGDD - Kinema

## 1. Objetivo

O Kinema é um jogo educacional em duas dimensões, voltado a alunos do ensino médio e dos períodos iniciais de cursos de engenharia, com o objetivo de apoiar o ensino de física, com foco em cinemática. Inspirado em simuladores e calculadoras gráficas, sua mecânica principal consiste em arremessar uma bola a partir de um ponto inicial, definindo velocidade e ângulo de lançamento, até alcançar o fim da fase. O elemento de quebra-cabeça está em prever a trajetória da bola e sua interação em cadeia com molas, cordas e portais, que respondem com forças elásticas, movimento pendular e mudanças de massa e volume, sempre respeitando a conservação de energia do sistema. Ao tornar essas equações visuais e interativas, o jogo busca aproximar o aluno da prática e facilitar a compreensão de conceitos que costumam ser abstratos quando vistos apenas em livros.

## 2. Jogo

O jogo é centrado na trajetória de uma bola, que o jogador deve guiar de um ponto inicial até um ponto final da fase. Cada fase representa a visualização mental de um menino enquanto resolve uma questão de física em uma prova, seguindo o ciclo abaixo.

- **tutorial:** dividido em mecânica, introdução interativa que ensina o jogador a usar o novo elemento da fase, como mola, corda ou portal, e teoria, apresentação da fórmula física associada, acompanhada de uma aplicação teórica ou real do conceito, quando aplicável.
- **questão:** exibição do enunciado da questão de física que a fase representa.
- **cenário:** apresentação do ambiente da fase, permitindo ao jogador identificar os elementos presentes, como molas, cordas e portais, e os conceitos físicos envolvidos.
- **configuração do lançamento:** definição da velocidade inicial e do ângulo de arremesso da bola.
- **execução e intervenção:** lançamento da bola, com o jogador podendo agir em momentos específicos da trajetória, como soltar a bola de uma corda no ponto certo de um movimento pendular, para guiar seu percurso.
- **resultado:** caso a bola alcance o ponto final, a fase é concluída; caso caia ou fique parada, o jogador perde e repete a fase.

## 3. Tabela de Elementos

| Categorias | Itens principais |
| --- | --- |
| Ambiente | Cenário 2D homogêneo, ponto de lançamento e ponto final da fase, plataformas e obstáculos, menino fazendo a prova, enunciado da questão de física |
| Elementos físicos | Bola (partícula controlada pelo jogador), mola (força elástica), corda (movimento pendular), portal de massa e volume |
| Ferramentas do jogador | Ajuste de velocidade inicial e ângulo, pré-visualização da trajetória, soltar a bola da corda no ponto certo, reinício da fase |
| UI/Interação | Interface estilo GeoGebra, plano cartesiano, painel de valores (x, y, v, a, m, V), painel de parâmetros (sliders e campos numéricos), gráficos em tempo real, câmera com zoom e pan, tutorial em estilo caderno |
| Dados | Resources do Godot (fases com posições inicial e final, objetos e parâmetros físicos; tipos de mola, corda e portal) e progresso salvo em ConfigFile ou JSON |
| EXTRA | EXTRA |

## 4. Assets

- Elementos narrativos.
  - Representação do menino que está fazendo a prova.
  - Tela ou elemento visual com o enunciado da questão de física de cada fase.
- Elementos físicos da fase.
  - Bola, o objeto controlado pelo jogador.
  - Mola, que aplica força elástica.
  - Corda, que gera movimento pendular.
  - Portal, que altera massa e volume da bola.
  - Cenário 2D homogêneo, mantendo o mesmo estilo visual do início ao fim.
- Tutorial.
  - Estética de caderno, com desenhos e anotações em estilo lápis ou grafite, remetendo a um rascunho feito à mão.
- UI & Text.
  - Interface estilo GeoGebra.
  - Plano cartesiano com grade, eixos e marcações numéricas.
  - Painel de valores da partícula (x, y, v, a, m, V).
  - Painel de parâmetros ajustáveis (sliders e campos numéricos).
  - Gráficos em tempo real de posição, velocidade e aceleração.
  - Câmera com zoom e pan.

## 5. Áudio

- Música
  - Trilha ambiente suave e minimalista, tipo lo-fi, piano ou sintetizador leve, em loop, sem melodia marcante para não cansar nem distrair durante o jogo.
  - Menu principal com uma faixa um pouco mais "de abertura" e a tela de fases com a mesma trilha em volume mais baixo.
  - Uma vinheta curta (2 a 3 segundos) ao concluir uma fase, em vez de uma música longa.
- Efeitos sonoros por mecânica
  - **Lançamento:** som curto de "impulso" (whoosh leve??).
  - **Partícula em movimento:** nada contínuo, ou um zumbido bem sutil.
  - **Mola:** um "boing" curto, dando para variar o tom conforme a constante k ou a compressão (mola curta = som agudo). Isso reforçaria o contexto do jogo sem precisar de texto.
  - **Corda:** som de tensão ao esticar e um leve estalo ao prender, tipo um "whip" das teias do Homem-Aranha, por exemplo.
  - **Portais:** um som diferente para cada tipo. Por exemplo, tom que sobe quando a massa ou o volume aumentam e desce quando diminuem.
  - **Colisões:** batida suave contra plataformas e obstáculos.
  - **Tentativa falha:** som neutro e baixo, nada punitivo, já que o foco é aprender.
- Interface
  - Cliques de botão e sliders com um "tick" discreto (tipo o do Minecraft, por exemplo).
  - Som ao abrir e fechar o painel de tutorial.
  - Um "ping" ao atualizar valores importantes, se achar que ajuda.

## 6. Programação

- Configuração Inicial
  - Criar projeto Godot 4 e repositório no GitHub (.gitignore do Godot).
  - Definir a estrutura de pastas (cenas, scripts, resources, assets, ui, etc).
  - Ajustar Physics Ticks per Second para uma simulação estável.
  - Criar autoloads: GameManager (estado e progressão) e SaveManager.
- Mecânicas de Fase
  - Partícula
    - Corpo físico com massa, volume, velocidade e posição.
    - Cálculo de densidade e aceleração (a = F / m).
    - Reset da partícula ao ponto de lançamento.
  - Lançamento
    - Controle de ângulo e velocidade inicial.
    - Pré-visualização da trajetória calculada pelas equações de movimento.
  - Molas
    - Força elástica (Lei de Hooke), com constante k configurável (por fase ou cenário).
    - Detecção da partícula com Area2D e aplicação de impulso.
  - Cordas (Fase 1)
    - Ponto de ancoragem e comprimento fixo.
    - Movimento pendular na partícula.
  - Portais de massa e volume
    - Area2D que altera massa e volume ao detectar a partícula.
    - Atualização do visual da partícula (escala e cor??) com Tween.
- Objetivo e vitória
  - Area2D no ponto final emitindo o sinal `level_completed`.
  - Detecção de tentativa falha (saída dos limites) e reinício da fase.
- Progressão e Salvamento
  - Lançamento e movimento uniformemente variado -> molas -> cordas -> portais.
  - Controle de fases desbloqueadas.
  - Salvamento local em arquivo (ConfigFile ou JSON).
- Comunicação entre Sistemas
  - Sinais para desacoplar os sistemas (`particle_launched`, `particle_mass_changed`, `level_completed`).
- Banco de Dados
  - Resources de fases (posição inicial e final, objetos, parâmetros físicos).
  - Resources de objetos físicos (tipos de mola, corda, portal).
- Integração e Build
  - Configurar o preset de exportação do Godot para Windows.
  - Gerar executável e testar em outra máquina, sem Godot instalado.
  - Testes de física (consistência da simulação) e de usabilidade com alunos.

## Referências

- Crayon Physics Deluxe: o jogador deve guiar uma bola desenhando objetos no cenário, com forte ênfase em simulação de gravidade e transferência de momento.
  - <https://store.steampowered.com/app/26900/Crayon_Physics_Deluxe/>
- Newton's Fourth Law
  - <https://store.steampowered.com/app/3023490/Newtons_Fourth_Law/>
- Frame - Portals on Steroids
  - <https://store.steampowered.com/app/1916610/Frame__Portals_on_Steroids/>
- Graphwar
  - <https://graphwar.com/>
