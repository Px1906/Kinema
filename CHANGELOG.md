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
- Perguntas do QTE com conteúdo (`content`) e estilo (`style`, cálculo ou teoria); cada barreira de QTE escolhe o conteúdo pelo Inspector e sorteia só entre as perguntas dele.
- Banco de 10 perguntas sobre os assuntos da fase tutorial.
- Aviso no painel de atributos quando a energia potencial fica negativa.

### Alterado
- Ao entrar num checkpoint, a bola é atraída para o centro como um ímã e fica suspensa ali, pronta para o próximo lançamento (antes ela freava e caía).
- Cenas de teste podem funcionar sem uma corda ou painel de controles.
- O painel de controles reutiliza a corda da fase quando disponível.
- A tecla `Espaço` lança a partícula quando ela está preparada e solta a partícula quando ela está presa à corda.
- O botão "Atualizar referência" do painel de atributos passa a se chamar "Centralizar referência".
- As perguntas de cálculo do QTE usam só os valores atuais da bola e números inteiros; a resposta certa sai dos valores mostrados no enunciado.
- Os atributos da bola são exibidos como números inteiros, arredondando para cima só quando a parte decimal passa de 0,5; a velocidade abaixo de 1 m/s mantém uma casa decimal.
- O painel de atributos do QTE fica escondido por padrão.
- A gravidade do jogo passa a ser 10 m/s² (o valor da Terra arredondado).

### Corrigido
- Acoplamento da partícula à corda adiado para evitar alterações durante o processamento de consultas físicas do Godot.
- Direção da velocidade tangencial corrigida ao soltar a partícula do movimento pendular.
- Conflito de merge removido do script dos controles de lançamento.
- A altura da energia potencial passa a ser medida pela base da bola, e não pelo centro.
- A energia mecânica da bola se conserva no ar: ela deixou de herdar o amortecimento linear padrão do projeto.
- Barreiras de QTE respondidas não voltam ao respawnar depois de alcançar um checkpoint.
