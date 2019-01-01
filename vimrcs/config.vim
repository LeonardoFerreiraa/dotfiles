set nocompatible 
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'scrooloose/nerdtree'
Plugin 'jistr/vim-nerdtree-tabs'
Plugin 'kien/ctrlp.vim'
Plugin 'tpope/vim-endwise'
Plugin 'jiangmiao/auto-pairs'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'alvan/vim-closetag'
Plugin 'gcmt/taboo.vim'
Plugin 'vim-airline/vim-airline'
Plugin 'morhetz/gruvbox'
Plugin 'tomtom/tcomment_vim'
Plugin 'tpope/vim-fugitive'
Plugin 'vim-scripts/vimspell'

call vundle#end() 
filetype plugin indent on

" ==========[ FUNCTIONS ]========== "

" TODO: fix multiline usage
function! Surround(open, close)
  let save = @"
  silent normal gvy
  let @" = a:open . @" . a:close
  silent normal gvp
  let @" = save
endfunction

" ==========[ SHORTCUTS ]========== "
let mapleader=","

set pastetoggle=<F3>

map <C-left>  :wincmd h<CR>
map <C-down>  :wincmd j<CR>
map <C-up>    :wincmd k<CR>
map <C-right> :wincmd l<CR>

map <C-h> :wincmd h<CR>
map <C-j> :wincmd j<CR>
map <C-k> :wincmd k<CR>
map <C-l> :wincmd l<CR>

nmap <silent> <F2> :NERDTreeTabsToggle<CR>
nmap <silent><leader>l :nohls<cr>

vmap <silent> ' :call Surround("'", "'")<CR>
vmap <silent> <leader>" :call Surround('"', '"')<CR>
vmap <silent> ( :call Surround('(', ')')<CR>
vmap <silent> [ :call Surround('[', ']')<CR>
vmap <silent> { :call Surround('{', '}')<CR>
vmap <silent> ` :call Surround('`', '`')<CR>

map srn :set number nonu rnu<CR>
map snn :set number nu nornu<CR>

nnoremap <C-F12> :CtrlPTag<cr>

nnoremap <F5> :buffers<CR>:buffer<Space>

" ==========[ CONFIGS ]========== "
set number

set autoindent
set shiftwidth=2
set tabstop=2
set expandtab
set smarttab
set so=7

set ignorecase
set incsearch
set hlsearch
set smartcase

set laststatus=2

syntax on
set background=dark

set nowrap

set mouse=a
set mousehide

set wildignore=*.class,*.pyc,node_modules,*.o

let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']

let g:NERDTreeMouseMode=3
let g:NERDTreeRespectWildIgnore=1

let g:ctrlp_use_caching=0

let g:closetag_filenames="*.html,*.erb"

set noswapfile
set autoread

let g:taboo_tab_format=' %N - %f |'

try
  colorscheme gruvbox
catch
endtry

set diffopt+=vertical

set list
set listchars=tab:▶\ ,trail:·

set hidden

au! BufNewFile,BufRead * let b:spell_language="brasileiro"

