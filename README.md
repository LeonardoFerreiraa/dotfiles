# Dot Files

```
apt install i3 i3blocks i3lock i3status lxappearance dmenu compton feh arc-theme ranger pulseaudio-utils pavucontrol notify-osd maim dunst numlockx xautolock
```

- https://github.com/snwh/moka-icon-theme
- https://github.com/horst3180/arc-theme

# Install

## Xresources

```
cat <<EOF > ~/.Xresources
font-size: 16
touchpad: ETPS/2 Elantech Touchad
bg-color: #2f343f
inactive-bg-color: #2f343f
text-color: #f3f4f5
inactive-text-color: #676E7D
urgent-bg-color: #E53935
separator-color: #757575
indicator-color: #000000
EOF
```

## Clone

```
git clone https://github.com/LeonardoFerreiraa/dotfiles.git ~/.dotfiles
```

## Fonts

```
ln -s ~/.dotfiles/fonts ~/.fonts
```

## I3

```
ln -s ~/.dotfiles/i3 ~/.config
```

## VIM

```
ln -s ~/.dotfiles/vimrc ~/.vimrc
```

## Dunst

```
ln -s ~/.dotfiles/dunst ~/.config/
```