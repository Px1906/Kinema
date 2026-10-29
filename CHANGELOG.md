# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
versionamento seguindo [SemVer](https://semver.org/lang/pt-BR/).

## [Não lançado]

### Adicionado
- Estrutura inicial do projeto.
- Partícula controlável com física de `RigidBody2D`, gravidade, colisões e reset ao ponto de origem.
- Configuração de velocidade e ângulo de lançamento por sliders, seta de pré-visualização e botão de lançamento.
- Controle do vetor de lançamento por arraste do mouse.
- Superfícies sólidas de chão, plataforma e parede, com tamanho, atrito e quique configuráveis.
- Entidade de corda reutilizável com comprimento fixo e visualização sob demanda.
- Área de detecção configurável para identificar a aproximação da partícula à corda.
- Acoplamento da partícula à extremidade da corda.
- Movimento pendular com gravidade configurável e liberação com velocidade tangencial.
- Botão `Soltar` e atalho de teclado pela tecla `Espaço`.
- Referência de altura zero (`HeightReference`) arrastável pela origem ou pelos eixos, em passos de 1 m e dentro dos limites da fase.
- Arquivos de skill de GDScript para apoiar o desenvolvimento Godot.
- Altura da área de gatilho da barreira de QTE configurável pelo Inspector (`trigger_height`).
- Layout da fase tutorial.
- Cinco tamanhos prontos de plataforma: muito curta (64×32), curta (128×32), média (256×32), longa (512×64) e muito longa (1024×64).
- Cinco tamanhos prontos de parede: muito curta (32×64), curta (32×128), média (32×256), longa (64×512) e muito longa (64×1024).
- Espinhos (`SpikeZone`, 128×32): a bola que entra finca, freando até parar um pouco além do contato, fica presa um instante e a tentativa falha. Podem ser repetidos e girados para plataformas, paredes e tetos.
- Perguntas do QTE com conteúdo (`content`) e estilo (`style`, cálculo ou teoria); cada barreira de QTE escolhe o conteúdo pelo Inspector e sorteia só entre as perguntas dele.
- Banco de 10 perguntas sobre os assuntos da fase tutorial.
- Aviso no painel de atributos quando a energia potencial fica negativa.
- Texto, imagem e animação dos popups de tutorial em `resources/tutorial_popups.json`; cada `TutorialPopupZone` escolhe o seu pelo `popup_id`.
- Popups de tutorial na fase tutorial: controles, atributos, referência, energias potencial, cinética e mecânica, e perda de energia nas colisões.
- Ângulo de lançamento desenhado na bola: arco do eixo horizontal até a seta, com o valor em graus (cor configurável em `angle_color`).
- Prévia de trajetória enquanto a bola está na corda, mostrando o caminho se ela for solta naquele instante, com limite e espaçamento próprios (`attached_point_count`, `attached_time_step`).
- Módulo da velocidade (`|v| = N m/s`) desenhado sobre o meio da seta de lançamento, afastado do arco e do texto do ângulo quando a seta é curta.
- Som de knob nos sliders de velocidade e ângulo do painel de lançamento.
- Fase tutorial estendida para a esquerda, com novas plataformas, checkpoints e espinhos.

### Alterado
- A tabela de atributos chama a energia total de "Energia mecânica".
- Ao entrar num checkpoint, a bola é atraída para o centro como um ímã e fica suspensa ali, pronta para o próximo lançamento (antes ela freava e caía).
- Cenas de teste podem funcionar sem uma corda ou painel de controles.
- O painel de controles reutiliza a corda da fase quando disponível.
- A tecla `Espaço` lança a partícula quando ela está preparada e solta a partícula quando ela está presa à corda.
- O botão "Atualizar referência" do painel de atributos passa a se chamar "Centralizar referência".
- As perguntas de cálculo do QTE usam só os valores atuais da bola e números inteiros; a resposta certa sai dos valores mostrados no enunciado.
- Os atributos da bola são exibidos como números inteiros, arredondando para cima só quando a parte decimal passa de 0,5; a velocidade abaixo de 1 m/s mantém uma casa decimal.
- O painel de atributos do QTE fica escondido por padrão.
- A gravidade do jogo passa a ser 10 m/s² (o valor da Terra arredondado).
- A fase tutorial passa a usar só os tamanhos prontos de plataforma e parede, com o layout e os checkpoints ajustados a eles.
- A bola gira mais livre (`angular_damp` de 2,5 para 0,5 na fase tutorial).
- A referência de altura só pode ser arrastada com a bola pronta para lançar, controlada pelo `LevelController` (antes a própria referência consultava o Player).
- Duração e curva do ímã do checkpoint configuráveis por checkpoint no Inspector (`pull_duration`, `pull_velocity_influence`).
- A altura automática do gatilho da barreira de QTE passa a ser indicada por `trigger_height` negativo (-1), em vez de 0.
- A fase tutorial não tem mais piso que mata; o perigo passa a ser os espinhos.
- A seta de lançamento e as bolinhas da prévia de trajetória passam a ser pretas; a seta fica com o dobro do comprimento e mais grossa.
- O arraste do mouse para mirar não desenha mais o traço vermelho.
- A velocidade no painel de lançamento é exibida em m/s e já considera o fator de lançamento; os rótulos dos sliders mostram nome e valor em duas linhas para não cortar o texto.
- A seta de lançamento tem o comprimento da velocidade de saída na escala do mundo: saindo a N m/s, ela mede N metros.
- O som de knob toca a cada 1 m/s da velocidade de saída e a cada 10° de ângulo, com histerese para não repetir com o valor parado na borda (`KnobNotch`).
- Os popups da fase tutorial foram reescritos em 17 textos, do lançamento às considerações finais; os que mostram fórmulas pedem para acompanhar os valores em "Atributos", e o texto da caixa fica justificado.

### Corrigido
- Acoplamento da partícula à corda adiado para evitar alterações durante o processamento de consultas físicas do Godot.
- Direção da velocidade tangencial corrigida ao soltar a partícula do movimento pendular.
- Conflito de merge removido do script dos controles de lançamento.
- A altura da energia potencial passa a ser medida pela base da bola, e não pelo centro.
- A energia mecânica da bola se conserva no ar: ela deixou de herdar o amortecimento linear padrão do projeto.
- Barreiras de QTE respondidas não voltam ao respawnar depois de alcançar um checkpoint.
- O checkpoint só é marcado como alcançado quando o ímã de fato puxa a bola.
- O fim do puxão do ímã não emite `stopped` se a bola já tiver mudado de estado (corda ou reinício).
- A energia mecânica da bola não cai mais em pleno voo (a velocidade usada no cálculo passa a ser a do meio do passo de física).
- A energia potencial não fica mais negativa por um instante quando a bola quica no nível da referência.
- O cursor volta ao normal assim que a referência de altura deixa de ser arrastável e ao trocar de fase.
- A caixa de texto dos popups de tutorial não bloqueia mais o arraste do vetor de lançamento nem da referência de altura.
- O som de knob toca ao chegar em 180° e na velocidade máxima, e o ângulo negativo também clica nos sliders.
