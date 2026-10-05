# Contribuindo

## Fluxo de trabalho

1. Crie uma issue descrevendo o que será feito (ou comente numa existente).
2. Crie uma branch a partir de `main`: `feat/nome`, `fix/nome` ou `chore/nome`.
3. Faça commits pequenos e focados.
4. Abra um Pull Request preenchendo o template.
5. Aguarde o CI passar e uma revisão antes do merge.

`main` está sempre jogável. Não faça push direto nela.

## Mensagens de commit

Seguimos [Conventional Commits](https://www.conventionalcommits.org/pt-br/):

```
feat: adiciona pulo duplo ao jogador
fix: corrige colisão com paredes inclinadas
docs: atualiza instruções de build
refactor: separa lógica de input do jogador
chore: atualiza versão do Godot
```

## Convenções de código (GDScript)

Seguimos o [guia de estilo oficial](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html):

- Arquivos e pastas: `snake_case` (`player_controller.gd`)
- Classes e nodes: `PascalCase`
- Funções e variáveis: `snake_case`
- Constantes: `CONSTANT_CASE`
- Sinais no passado: `health_changed`, `enemy_died`
- Use tipagem estática sempre que possível (`var speed: float = 200.0`)
- Indentação com tabs
- Prefira sinais a referências diretas entre nodes distantes
- Sem números mágicos: use `const` ou `@export`

## Assets

- Binários pesados vão pelo Git LFS (já configurado em `.gitattributes`).
- Nomes em `snake_case`, organizados por tipo em `assets/`.
- Registre autoria e licença de todo asset de terceiros em `docs/CREDITS.md`.

## Cenas e merge

Arquivos `.tscn` podem gerar conflitos. Para reduzir:

- Evite mexer na mesma cena em branches diferentes.
- Prefira cenas pequenas e reutilizáveis.
- Em conflito, resolva abrindo a cena no editor e conferindo o resultado.

## Testes

Usamos [GUT](https://github.com/bitwes/Gut) em `tests/`. Rode antes de abrir o PR.
