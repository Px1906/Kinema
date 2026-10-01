# Kinema

Jogo de puzzle que ensina cinemática a estudantes do ensino médio e universitário. Resolva as fases aplicando velocidade, aceleração e movimento. Feito com Godot 4.

![Status](https://img.shields.io/badge/status-em%20desenvolvimento-yellow)
![Godot](https://img.shields.io/badge/Godot-4.x-478cbf)
![Licença](https://img.shields.io/badge/licen%C3%A7a-MIT-green)

## Requisitos

- [Godot 4.x](https://godotengine.org/download) (versão exata em `.godot-version`)
- [Git LFS](https://git-lfs.com/) para os assets binários

## Como rodar

```bash
git clone https://github.com/Px1906/Kinema.git)
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
├── tools/         # Scripts de apoio ao desenvolvimento e ao CI
└── .github/       # CI, templates de issue e PR
```

## Controles

| Ação | Teclado | Controle |
|------|---------|----------|

Em desenvolvimento

## Contribuindo

Leia o [CONTRIBUTING.md](CONTRIBUTING.md) antes de abrir um PR.

## Roadmap

Veja as [issues](../../issues) e o [CHANGELOG](CHANGELOG.md).

## Licença

Código sob licença [MIT](LICENSE). Assets podem ter licenças próprias, veja [docs/CREDITS.md](docs/CREDITS.md).
