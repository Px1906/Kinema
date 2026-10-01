# Meu Jogo

> Descrição curta do jogo em uma ou duas frases.

![Status](https://img.shields.io/badge/status-em%20desenvolvimento-yellow)
![Godot](https://img.shields.io/badge/Godot-4.x-478cbf)
![Licença](https://img.shields.io/badge/licen%C3%A7a-MIT-green)

## Sobre

Gênero, plataforma-alvo, ideia central e o que torna o jogo diferente.

## Requisitos

- [Godot 4.x](https://godotengine.org/download) (versão exata em `.godot-version`)
- [Git LFS](https://git-lfs.com/) para os assets binários

## Como rodar

```bash
git clone https://github.com/SEU_USUARIO/meu-jogo.git
cd meu-jogo
git lfs install
git lfs pull
```

Abra o Godot, clique em **Importar** e selecione o arquivo `project.godot`. Depois pressione **F5**.

## Estrutura do projeto

```
.
├── assets/        # Arte, áudio, fontes (organizados por tipo)
├── scenes/        # Cenas (.tscn)
├── scripts/       # Scripts (.gd)
├── autoload/      # Singletons globais
├── addons/        # Plugins de terceiros
├── tests/         # Testes automatizados (GUT)
├── docs/          # Documentação e GDD
└── .github/       # CI, templates de issue e PR
```

## Controles

| Ação | Teclado | Controle |
|------|---------|----------|
| Mover | WASD / Setas | Analógico esquerdo |
| Pular | Espaço | A |

## Contribuindo

Leia o [CONTRIBUTING.md](CONTRIBUTING.md) antes de abrir um PR.

## Roadmap

Veja as [issues](../../issues) e o [CHANGELOG](CHANGELOG.md).

## Licença

Código sob licença [MIT](LICENSE). Assets podem ter licenças próprias, veja [docs/CREDITS.md](docs/CREDITS.md).
