RCS_DIR=~/.dotfiles/vimrcs

git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

echo "source $RCS_DIR/config.vim" > ~/.vimrc

vim +PluginInstall +qall

ln -s  $RCS_DIR/ctags ~/.ctags