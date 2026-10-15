# SGDD - Kinema

## 1. Objetivo

O Kinema é um jogo educacional em duas dimensões (2D), voltado a alunos do ensino médio e dos períodos iniciais de cursos de engenharia, com o objetivo de apoiar o ensino de física, com foco em cinemática. Inspirado em simuladores e calculadoras gráficas, sua mecânica principal consiste em arremessar uma bola a partir de um ponto inicial, definindo velocidade e ângulo de lançamento, até alcançar o fim da fase. O lançamento percorre o jogo inteiro: está presente em todas as fases, e as demais mecânicas são introduzidas sobre ele. O elemento de quebra-cabeça está em prever a trajetória da bola e sua interação em cadeia com molas, cordas e portais, que respondem com forças elásticas, movimento pendular e mudanças de massa e de área, sempre respeitando a conservação de energia do sistema. Ao tornar essas equações visuais e interativas, o jogo busca aproximar o aluno da prática e facilitar a compreensão de conceitos que costumam ser abstratos quando vistos apenas em livros.

Este SGDD descreve o jogo completo. A prova de conceito (POC), entregue até o fim de outubro de 2026, é a fase tutorial desse jogo: a primeira fase, que ensina o lançamento e a interação com cordas, organizada em checkpoints e com barreiras de Quick Time Event (QTE). Os requisitos do documento de requisitos correspondem à POC. Mola, portais, barreiras de impacto físico, as demais fases, a seleção de fases, o desbloqueio e o salvamento da progressão são a extensão do projeto depois da entrega, e em cada tópico deste documento aparecem listados depois dos itens da POC.

## 2. Jogo

**Progressão das mecânicas**

- O jogo terá fases tutoriais, que apresentam as mecânicas e ensinam a física por trás delas, seguidas de fases que exploram as mecânicas ensinadas.
- O lançamento está presente em todas as fases. As mecânicas já apresentadas continuam aparecendo, combinadas, nas fases seguintes.

**Estrutura da fase**

- A fase se organiza em checkpoints sequenciais. O jogador avança de um checkpoint ao seguinte fazendo arremessos.
- A progressão espacial é ascendente: o jogador avança da esquerda para a direita, mas precisa também subir para progredir.
- Ao alcançar um checkpoint, ele fica registrado. Se a tentativa falhar, o jogo volta ao último checkpoint alcançado, e não ao início da fase. A bola parada sobre um checkpoint não conta como falha.
- Em cada checkpoint, o jogador configura e executa o próximo lançamento.

**Final da fase**

- A fase termina quando a bola alcança o ponto final, que fica depois do último checkpoint.
- Ao chegar ao ponto final, o jogo informa visualmente que a fase foi concluída e toca a vinheta de conclusão.
- As fórmulas aprendidas ficam disponíveis para consulta nos menus.

**Lançamento**

O lançamento é a mecânica principal do jogo e está presente em todas as fases.

- Configuração
  - O jogador define a velocidade inicial e o ângulo de lançamento de duas formas, que ficam sincronizadas: pelos sliders do pop-up de lançamento, aberto por um botão no canto superior esquerdo, ou arrastando o mouse a partir da bola, desenhando o vetor de lançamento na tela.
  - No arraste, a direção do vetor é a direção do lançamento, que dá o ângulo, e o comprimento do vetor dá a velocidade inicial.
  - Antes de lançar, o jogo apresenta a pré-visualização da trajetória prevista.
- Execução
  - Com os parâmetros definidos, o jogador lança a bola. A bola se move segundo a simulação física e colide com chão, plataformas e paredes.
  - Durante o movimento, o jogador acompanha os atributos da bola no pop-up de atributos.
- Resultado
  - Se a bola cair, sair dos limites ou ficar parada fora de um checkpoint, a tentativa falha e o jogo volta ao último checkpoint alcançado.

**Corda**

A corda faz a bola descrever um movimento pendular, com conservação de energia mecânica.

- Captura
  - Cada corda tem um ponto de ancoragem e uma área de ação circular, com linhas segmentadas girando.
  - Quando a bola entra na área de ação e sua direção fica perpendicular à linha entre a bola e a âncora, a corda é criada. O comprimento da corda é a distância entre a bola e a âncora nesse instante, e a bola mantém o sentido do movimento.
- Movimento pendular
  - A bola oscila em torno do ponto de ancoragem. A velocidade muda ao longo da oscilação: a energia potencial e a energia cinética se trocam, e a energia mecânica total se mantém constante.
  - Se a bola não tiver velocidade suficiente para manter a corda esticada, a corda afrouxa e a bola segue em lançamento oblíquo.
- Soltura
  - O jogador solta a bola da corda com um clique, no ponto certo do movimento pendular. A bola segue em lançamento oblíquo, com a velocidade e a direção do instante da soltura.
  - A corda é removida ao soltar a bola ou ao reiniciar a tentativa.

**Barreiras**

As barreiras são uma mecânica central da gameplay. Existem dois tipos.

- Barreira de QTE
  - Ao chegar à barreira, o jogo dispara um Quick Time Event (QTE) de cerca de 10 segundos, com o tempo da fase em câmera lenta.
  - O QTE é uma pergunta rápida de três alternativas sobre as mecânicas ensinadas. Os números são simples: o objetivo é o jogador associar as equações ao que está fazendo e a valores numéricos reais, ganhando noção do tamanho das grandezas, e não calcular o valor exato.
  - A pergunta se refere ao estado da bola naquele instante. O jogador consulta os atributos (massa, área, velocidade, energia cinética, energia potencial e energia total), associa-os às fórmulas e calcula a resposta.
  - Das três alternativas, uma é correta e é calculada a partir dos valores reais da bola. As outras duas são aleatórias, dentro de uma faixa definida para cada pergunta.
  - Acerto: a alternativa escolhida fica verde, toca um GIF engraçado como recompensa, a tela volta ao normal, a barreira some, o jogador passa pelo obstáculo e o tempo volta ao normal.
  - Erro: a alternativa escolhida fica vermelha e toca um efeito sonoro engraçado, para o jogador identificar que errou. Depois a tela volta ao normal, a bola bate na barreira com o som de uma bola contra a parede, sem conseguir atravessá-la, e cai. O jogo volta ao último checkpoint.
  - Se os 10 segundos acabarem sem resposta, o QTE conta como erro.
  - Justificativa pedagógica: sem o QTE, o jogador só veria os atributos da bola passando durante a fase. Com ele, precisa exercitar cálculos simples, e os atributos e as energias potencial e cinética ganham um propósito dentro do jogo.
- Barreira de impacto físico
  - Barreira sem pergunta, que só se rompe se a bola chegar com energia cinética igual ou maior que um valor mínimo (Ec = ½ · m · v²), que depende da massa e da velocidade no impacto.
  - Os portais de massa e área trabalham em conjunto com essas barreiras, ajustando a bola antes do choque.

**Interface da fase**

- No canto superior esquerdo da tela ficam dois botões. O primeiro abre um pop-up com dois sliders: ângulo de lançamento e velocidade inicial. O segundo abre um pop-up com os atributos da bola naquele momento: massa, área, velocidade, energia cinética, energia potencial e energia total.
- Durante um QTE, as bordas da tela dão um zoom in. A pergunta desce pela parte de cima da tela e as opções de resposta sobem a partir de baixo, para o jogador clicar. À esquerda aparecem fixos os atributos da bola, que antes ficavam no pop-up e agora são exibidos obrigatoriamente, para o jogador olhar os valores.
- Acertos e erros têm efeitos sonoros e visuais dedicados.

**Ciclo da fase**

- **tutorial:** presente nas fases tutoriais, dividido em mecânica, introdução interativa que ensina o jogador a usar o novo elemento da fase, como mola, corda ou portal, e teoria, apresentação da fórmula física associada, acompanhada de uma aplicação teórica ou real do conceito, quando aplicável.
- **cenário:** apresentação do ambiente da fase, permitindo ao jogador identificar as mecânicas presentes.
- **configuração do lançamento:** definição da velocidade inicial e do ângulo de arremesso da bola, com pré-visualização da trajetória, pelos sliders do pop-up ou arrastando o mouse na tela.
- **execução e intervenção:** lançamento da bola, com o jogador podendo agir em momentos específicos da trajetória, como soltar a bola de uma corda, com um clique, no ponto certo do movimento pendular, para guiar seu percurso, e responder às perguntas dos QTEs das barreiras que surgirem no caminho.
- **resultado:** caso a bola alcance o ponto final, a fase é concluída; caso caia, saia dos limites ou fique parada, o jogador perde e volta ao último checkpoint alcançado.

**Estados da tentativa**

O jogo separa visualmente três estados: preparando o lançamento, bola em movimento e tentativa encerrada. Dentro de "bola em movimento" existe o sub-estado QTE, com câmera lenta e interface própria.

**Fluxo de telas**

Menu principal (jogar, opções, créditos e sair), cutscene de introdução, fase e seleção de fases. Durante a fase, o jogador pode pausar, reiniciar, ajustar o áudio ou voltar ao menu principal. Nos menus, o jogador pode consultar as fórmulas já aprendidas. Todos os controles e menus são operados apenas com o mouse.

## 3. Tabela de Elementos

| Categorias | Itens principais |
| --- | --- |
| Ambiente | Cenário 2D homogêneo em papel quadriculado, com progressão ascendente da esquerda para a direita, ponto de lançamento e ponto final da fase, checkpoints, plataformas e obstáculos, menino fazendo a prova |
| Elementos físicos | Bola (disco 2D controlado pelo jogador, com massa e área), corda (movimento pendular com conservação de energia), barreira de QTE, mola (força elástica), portal de massa e área, barreira de impacto físico |
| Ferramentas do jogador | Ajuste de velocidade inicial e ângulo (pop-up com dois sliders ou arraste do mouse desenhando o vetor), pré-visualização da trajetória, soltar a bola da corda no ponto certo, resposta ao QTE entre três alternativas, reinício a partir do último checkpoint, pausa |
| UI/Interação | Interface em estilo caderno de geometria (papel quadriculado, traços de lápis, régua), plano cartesiano, dois botões no canto superior esquerdo que abrem o pop-up de lançamento (sliders de ângulo e velocidade inicial) e o pop-up de atributos da bola (massa, área, velocidade, energia cinética, energia potencial e energia total), tela de QTE (zoom nas bordas, pergunta no topo, opções embaixo, atributos fixos à esquerda), câmera com zoom e pan, menu principal, pausa, opções de áudio, créditos, cutscene de introdução, consulta das fórmulas aprendidas, tutorial em estilo caderno, seleção de fases |
| Dados | Resources do Godot (fases com posições inicial e final, objetos e parâmetros físicos; tipos de mola, corda e portal) e progresso salvo em ConfigFile ou JSON |

## 4. Assets

- Elementos narrativos.
  - Representação do menino que está fazendo a prova.
  - Tela ou elemento visual com a pergunta de cada QTE, apresentada como uma questão da prova.
  - Cutscene de introdução, com a premissa do jogo: o menino resolvendo uma prova de física.
- Elementos físicos da fase.
  - Bola, o objeto controlado pelo jogador, desenhada como um disco a lápis. O tamanho acompanha a área e a intensidade do traço acompanha a massa.
  - Corda, que gera movimento pendular.
  - Área de ação da corda (círculo com linhas segmentadas girando, traçado como se fosse feito com compasso) e ponto de ancoragem.
  - Barreira de QTE, que bloqueia o caminho até o jogador responder à pergunta, no mesmo estilo de traço de régua. Precisa de uma animação de desaparecimento para o acerto.
  - Marcador de checkpoint, com estado de alcançado e não alcançado.
  - Plataformas, paredes e chão, em traços retos, como se feitos com régua.
  - Cenário 2D homogêneo em papel quadriculado, mantendo o mesmo estilo visual do início ao fim.
  - Mola, que aplica força elástica, desenhada em zigue-zague de traços retos.
  - Portal, que altera massa e área da bola.
  - Barreira de impacto físico, visualmente distinta da barreira de QTE para o jogador saber qual é qual.
- Estilo visual.
  - Traços de lápis ou grafite que remetam ao campo de estudo da geometria, como se alguém usasse réguas e papel quadriculado. O estilo vale para todo o jogo: fases, interface, menus e tutorial.
- Tutorial.
  - Mesma estética do jogo, com desenhos e anotações em estilo lápis ou grafite, remetendo a um rascunho feito à mão sobre papel quadriculado.
- UI & Text.
  - Interface em estilo caderno de geometria.
  - Plano cartesiano com grade, eixos e marcações numéricas sobre o papel quadriculado.
  - Pop-up de atributos da bola (massa, área, velocidade, energia cinética, energia potencial e energia total). No QTE, o mesmo conteúdo aparece fixo à esquerda.
  - Pop-up de lançamento com dois sliders (ângulo e velocidade inicial), com um transferidor desenhado junto à bola para indicar o ângulo de lançamento.
  - Vetor de lançamento desenhado na tela ao arrastar o mouse a partir da bola.
  - Ícones dos dois botões do canto superior esquerdo (lançamento e atributos).
  - Efeito visual de zoom nas bordas da tela durante o QTE.
  - Botões de resposta do QTE, com estado normal, verde para a resposta correta e vermelho para a errada.
  - GIF engraçado de recompensa, exibido quando o jogador acerta o QTE.
  - Câmera com zoom e pan.
  - Menu principal, pausa, opções, créditos, consulta das fórmulas aprendidas e seleção de fases, no mesmo estilo.

## 5. Áudio

- Música
  - Trilha ambiente suave e minimalista, tipo lo-fi, piano ou sintetizador leve, em loop, sem melodia marcante para não cansar nem distrair durante o jogo.
  - Menu principal com uma faixa um pouco mais “de abertura” e a tela de fases com a mesma trilha em volume mais baixo.
  - Uma vinheta curta (2 a 3 secs) ao concluir uma fase, em vez de uma música longa.
- Efeitos sonoros por mecânica
  - **Lançamento:** som curto de “impulso” (um “whoosh” leve).
  - **Bola em movimento:** nada contínuo, ou um zumbido bem sutil.
  - **Corda:** som de tensão ao esticar e um leve estalo ao prender, tipo o “whip” das teias do Homem-Aranha, por exemplo.
  - **Acerto no QTE:** efeito sonoro dedicado de recompensa, junto com o GIF e o botão verde.
  - **Erro no QTE:** efeito sonoro engraçado, para o jogador identificar que errou a pergunta, junto com o botão vermelho. Mantém o tom leve, sem punição pesada.
  - **Colisão com a barreira após o erro:** som de bola batendo na parede sem conseguir atravessá-la.
  - **Colisões:** batida suave contra plataformas e obstáculos.
  - **Tentativa falha:** som neutro e baixo, nada punitivo, já que o foco é aprender.
  - **Mola:** um “boing” curto, dando para variar o tom conforme a constante k ou a compressão (mola curta = som agudo). Isso reforçaria o contexto do jogo sem precisar de texto.
  - **Portais:** um som diferente para cada tipo. Por exemplo, tom que sobe quando a massa ou a área aumentam e desce quando diminuem.
- Interface
  - Cliques de botão e sliders com um “tick” discreto (tipo o do Minecraft, por exemplo).
  - Som ao abrir e fechar o painel de tutorial.
  - Um “ping” ao atualizar valores importantes, se achar que ajuda.
- Ajustes
  - Nas opções, o jogador regula separadamente o volume geral, o da música e o dos efeitos sonoros, ou silencia cada um.

## 6. Programação

- Configuração Inicial
  - Criar Projeto Godot 4 e repositório no GitHub (.gitignore do Godot)
  - Definir a estrutura de pastas (cenas, scripts, resources, assets, ui, etc)
  - Ajustar Physics Ticks per Second para uma simulação estável
  - Definir a escala de unidades (pixels por metro) e a aceleração da gravidade g (padrão 9,8 m/s²), usadas em todos os cálculos de física e de energia
  - Criar autoloads: GameManager (estado e progressão), SaveManager e AudioManager
  - Configurar a exportação para Windows (executável sem exigir o Godot instalado) e a resolução base, com suporte a 720p e 1080p, em tela cheia ou janela
- Mecânicas de Fase
  - Bola
    - Corpo físico com massa, área, velocidade e posição
    - Cálculo da aceleração (a = F / m)
    - Raio da bola derivado da área (A = π · r²), usado no colisor e no visual
    - Reset da bola ao ponto de lançamento
  - Lançamento
    - Controle de ângulo e velocidade inicial por dois sliders em um pop-up, aberto por um botão no canto superior esquerdo
    - Definição do vetor de lançamento arrastando o mouse a partir da bola: a direção do vetor dá o ângulo e o comprimento dá a velocidade inicial, com um limite máximo. O arraste e os sliders se atualizam mutuamente em tempo real
    - Pré-visualização da trajetória calculada pelas equações de movimento
    - Estados da tentativa (preparando o lançamento, bola em movimento, tentativa encerrada), com mudança visual a cada estado. O QTE é um sub-estado de "bola em movimento"
  - Cordas
    - Area2D circular de ação ao redor do ponto de ancoragem, com representação visual (círculo e linhas segmentadas girando)
    - Detecção da entrada da bola na área e cálculo contínuo do produto escalar entre a velocidade e o vetor bola–âncora (v · r)
    - Criação da corda no instante em que a direção da bola fica perpendicular à linha bola–âncora (v · r = 0, detectado pela mudança de sinal)
    - Cálculo do comprimento da corda L (distância no instante da captura) e da velocidade angular inicial ω0 = v / L, mantendo o sentido do movimento
    - Movimento pendular da bola em torno do ponto de ancoragem: a cada passo de física, o ângulo θ (medido a partir da vertical que passa pela âncora) e a velocidade angular ω são atualizados por integração numérica de θ'' = −(g / L) · sen θ, de modo que a velocidade muda ao longo da oscilação
    - Conservação de energia no pêndulo: a energia mecânica total (Ep + Ec) se mantém constante durante a oscilação. Usar um integrador estável (semi-implícito ou Verlet) e uma checagem de erro de energia por passo para evitar deriva
    - Soltura da bola por clique do mouse, que segue em lançamento oblíquo com a velocidade tangencial do instante da soltura
    - Remoção da corda e reinício do estado ao soltar a bola ou reiniciar a fase
    - Corda frouxa: quando a tensão fica nula ou negativa (bola acima da âncora com velocidade insuficiente), remover a corda e seguir em lançamento oblíquo com a velocidade do instante
  - Checkpoints
    - Area2D de checkpoint que registra no GameManager o último checkpoint alcançado
    - Em qualquer falha (queda, saída dos limites, bola parada fora de um checkpoint ou erro no QTE), a bola volta ao último checkpoint alcançado, com reinício limpo do estado
    - Bola parada sobre um checkpoint não conta como falha
  - Barreira de QTE
    - Gatilho: Area2D antes da barreira, que detecta a bola e inicia o QTE (distância de ativação configurável)
    - Câmera lenta: reduzir o `Engine.time_scale` durante o QTE. O contador de cerca de 10 segundos deve ignorar o `time_scale` (`create_timer` com `ignore_time_scale = true`), para durar 10 segundos reais
    - Gerador de pergunta: a partir de modelos de pergunta (Resource) e dos valores reais da bola (massa, área, velocidade, Ep, Ec e E), calcular a resposta correta, com números simples e foco em ordem de grandeza
    - Alternativas erradas: duas, sorteadas dentro de uma faixa configurável por modelo de pergunta, diferentes entre si e da correta. A posição da alternativa correta também é sorteada
    - Acerto: marcar o botão clicado em verde, exibir o GIF de recompensa, desfazer o zoom, remover a barreira e restaurar o `time_scale` para 1
    - Erro (inclui o tempo esgotado sem resposta): marcar o botão clicado em vermelho, tocar o efeito sonoro engraçado, desfazer o zoom e restaurar o `time_scale`. A barreira continua sólida, a bola colide (com som) e cai, e a falha leva ao último checkpoint
    - O Godot não reproduz GIF diretamente: converter o GIF em sequência de frames (AnimatedSprite2D) ou em vídeo
  - Molas
    - Força elástica (Lei de Hooke), com constante k configurável (por fase ou cenário)
    - Detecção da bola com Area2D e aplicação de impulso
    - Energia potencial elástica (½ · k · x²) somada à energia potencial, para que a energia total se conserve durante a compressão
  - Portais de massa e área
    - Area2D que altera massa e área ao detectar a bola
    - Atualização do visual da bola (escala conforme a área e intensidade do traço conforme a massa) com Tween
    - Regra para a velocidade na passagem pelo portal (conservar momento linear ou energia cinética): a definir pela equipe
  - Barreira de impacto físico
    - Contato da bola com a barreira: calcular Ec = ½ · m · v² no instante do choque. Se Ec for maior ou igual à energia cinética mínima da barreira (configurável na Resource), a barreira se rompe. Caso contrário, a bola colide normalmente
    - A massa da bola, ajustada pelos portais, entra no cálculo
- Energia e Grandezas
  - Cálculo a cada passo de física da energia potencial (Ep = m · g · h, mais a elástica quando houver mola), da energia cinética (Ec = ½ · m · v²) e da energia total (E = Ep + Ec), com a altura h medida a partir de uma referência definida em cada fase
  - Pop-up de atributos atualizado em tempo real com massa (m), área (A), velocidade (v), energia cinética (Ec), energia potencial (Ep) e energia total (E)
- Interface de jogo
  - Dois botões no canto superior esquerdo: o primeiro abre o pop-up de lançamento (sliders de ângulo e velocidade inicial) e o segundo abre o pop-up de atributos da bola
  - Overlay do QTE: zoom in nas bordas da tela (Tween no zoom da câmera ou vinheta por shader), pergunta descendo pela parte de cima, opções de resposta subindo pela parte de baixo e atributos fixos à esquerda, reaproveitando a cena do pop-up de atributos em modo fixo e obrigatório
  - Feedback com efeitos sonoros e visuais dedicados tanto para acertos quanto para erros: botão verde, GIF e som de recompensa no acerto; botão vermelho e som engraçado no erro
- Objetivo e vitória
  - Area2D no ponto final emitindo o sinal `level_completed`
  - Ao concluir a fase, informar visualmente a conclusão e tocar a vinheta
  - Detecção de tentativa falha (saída dos limites ou bola parada fora de um checkpoint, com velocidade abaixo de um limite por um tempo mínimo) e reinício a partir do último checkpoint
  - Reinício limpo: corda, massa, área e velocidade voltam aos valores iniciais, sem estados residuais
- Tutorial e Câmera
  - Tutorial em duas partes (mecânica e teoria), carregado a partir do Resource da fase
  - Câmera que acompanha a bola entre os checkpoints ao longo da fase ascendente, com zoom e pan pelo mouse
  - Theme único do Godot aplicado a toda a interface, com o estilo de caderno de geometria (traços de lápis, papel quadriculado, régua)
- Menus e Telas
  - Menu principal (jogar, opções, créditos e sair)
  - Cutscene de introdução, exibida antes da primeira fase
  - Pausa que congela a simulação, com continuar, reiniciar, opções e voltar ao menu principal
  - Opções de áudio e de tela (resolução, tela cheia ou janela) e tela de créditos
  - Consulta das fórmulas já aprendidas, disponível nos menus principal e de pausa, com o registro das fórmulas liberadas conforme o jogador conclui os tutoriais
  - Todos os controles e menus operados apenas com o mouse
  - Seleção de fases, com fases bloqueadas e desbloqueadas
- Áudio
  - AudioManager com barramentos Master, Música e Efeitos, controle de volume e silenciar por barramento
  - Reprodução de música, vinheta e efeitos sonoros disparados pelos sinais dos outros sistemas, incluindo o efeito de acerto, o efeito engraçado do erro no QTE e o som da colisão na barreira
- Progressão e Salvamento
  - Fases tutoriais que apresentam cada mecânica, seguidas de fases que a exploram, com o lançamento presente em todas
  - Controle de fases desbloqueadas
  - Salvamento local em arquivo (ConfigFile ou JSON), incluindo o progresso e as opções de áudio e de tela
- Comunicação entre Sistemas
  - Sinais para desacoplar os sistemas (`ball_launched`, `ball_mass_changed`, `ball_area_changed`, `rope_attached`, `rope_released`, `checkpoint_reached`, `qte_started`, `qte_answered`, `qte_timeout`, `barrier_removed`, `barrier_broken`, `attempt_failed`, `level_completed`)

## Referências

- Crayon Physics Deluxe: o jogador deve guiar uma bola desenhando objetos no cenário, com forte ênfase em simulação de gravidade e transferência de momento.
  - <https://store.steampowered.com/app/26900/Crayon_Physics_Deluxe/>
- Newton's Fourth Law
  - <https://store.steampowered.com/app/3023490/Newtons_Fourth_Law/>
- Frame - Portals on Steroids
  - <https://store.steampowered.com/app/1916610/Frame__Portals_on_Steroids/>
- Graphwar
  - <https://graphwar.com/>
