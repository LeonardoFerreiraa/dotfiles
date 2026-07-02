# Dot Files

## Neovim

Configuração do Neovim vive em [`nvim/`](./nvim). Para instalar, crie um link
simbólico apontando para o diretório que o Neovim lê de fato:

```sh
git clone git@github.com:LeonardoFerreiraa/dotfiles.git ~/workspace/dotfiles
ln -s ~/workspace/dotfiles/nvim ~/.config/nvim
```

Na primeira vez que abrir o `nvim`, o [lazy.nvim](https://github.com/folke/lazy.nvim)
é baixado e instala os plugins automaticamente.

### Mapeamentos

| Atalho             | Ação                                             |
| ------------------ | ------------------------------------------------ |
| `<leader>ff`        | Find file (Telescope `find_files`)                |
| `<leader>fg`        | Live grep (Telescope `live_grep`)                 |
| `<leader>fb`        | Buffers abertos (Telescope `buffers`)             |
| `<leader>fw`        | Warnings/erros (Telescope `diagnostics`)          |
| `<leader>fu`        | Find usage / referências (Telescope `lsp_references`) |
| `<leader>fd`        | Definitions & declarations juntas no Telescope (dedup) |
| `<leader>ca`        | Code actions / sugestões de correção (Telescope, substitui `gra`) |
| `<leader>sd`        | Show diagnostic — mostra o warning/erro completo do cursor (substitui `<C-w>d`) |
| `gd`                | Go to definition                                  |
| `gD`                | Go to declaration                                 |
| `K`                 | Hover (documentação)                              |
| `<leader>l`         | Limpa o highlight de busca (`:nohls`)             |
| `<leader>gb`        | Volta no jumplist (equivalente a `<C-o>`)         |
| `<leader>gf`        | Avança no jumplist (equivalente a `<C-i>`)        |
| `<leader>t`         | Abre/fecha um terminal flutuante (toggleterm)     |
| `-`                 | Abre o `netrw` (explorador de arquivos)           |

`<leader>` é a barra de espaço (`<Space>`).

### Comandos Java (jdtls)

| Comando        | Ação                                                              |
| -------------- | ------------------------------------------------------------------ |
| `:JavaSetJdk`  | Escolhe uma JDK instalada via `cli-assistant` e (re)inicia o jdtls |
| `:JavaReindex` | Apaga o cache do workspace do jdtls e reinicia (reindex completo)  |
