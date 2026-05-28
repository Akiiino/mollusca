require-module powerline
powerline-start

set-option global powerline_ignore_warnings true
set-option global powerline_format 'git lsp bufname line_column filetype mode_info position'
set-option global powerline_separator ''
set-option global powerline_separator_thin ''

evaluate-commands %sh{
    gray="rgb:928374"
    red="rgb:9d0006"
    green="rgb:79740e"
    yellow="rgb:b57614"
    blue="rgb:076678"
    purple="rgb:8f3f71"
    aqua="rgb:427b58"
    orange="rgb:af3a03"

    bg="rgb:fbf1c7"
    bg_alpha="rgba:fbf1c7a0"
    bg1="rgb:ebdbb2"
    bg2="rgb:d5c4a1"
    bg3="rgb:bdae93"
    bg4="rgb:a89984"

    fg="rgb:3c3836"
    fg_alpha="rgba:3c3836a0"
    fg0="rgb:282828"
    fg2="rgb:504945"
    fg3="rgb:665c54"
    fg4="rgb:7c6f64"

    printf "%s\n" "
        declare-option -hidden str powerline_color00 ${bg}     # fg: bufname
        declare-option -hidden str powerline_color01 ${bg4}    # bg: position
        declare-option -hidden str powerline_color02 ${yellow} # fg: git
        declare-option -hidden str powerline_color03 ${fg}     # bg: bufname
        declare-option -hidden str powerline_color04 ${bg}     # bg: git
        declare-option -hidden str powerline_color05 ${fg0}    # fg: position
        declare-option -hidden str powerline_color06 ${fg0}    # fg: line-column
        declare-option -hidden str powerline_color07 ${bg}     # fg: mode-info
        declare-option -hidden str powerline_color08 ${bg2}     # base background
        declare-option -hidden str powerline_color09 ${bg4}    # bg: line-column
        declare-option -hidden str powerline_color10 ${fg3}    # fg: filetype
        declare-option -hidden str powerline_color11 ${bg1}    # bg: filetype
        declare-option -hidden str powerline_color12 ${bg2}    # bg: client
        declare-option -hidden str powerline_color13 ${fg2}    # fg: client
        declare-option -hidden str powerline_color14 ${fg}     # fg: session
        declare-option -hidden str powerline_color15 ${bg3}    # bg: session
        declare-option -hidden str powerline_color16 ${bg}     # unused
        declare-option -hidden str powerline_color17 ${bg4}    # unused
        declare-option -hidden str powerline_color18 ${yellow} # unused
        declare-option -hidden str powerline_color19 ${fg}     # unused
        declare-option -hidden str powerline_color20 ${bg}     # unused
        declare-option -hidden str powerline_color21 ${fg0}    # unused
        declare-option -hidden str powerline_color22 ${fg0}    # unused
        declare-option -hidden str powerline_color23 ${bg}     # unused
        declare-option -hidden str powerline_color24 ${bg}     # unused
        declare-option -hidden str powerline_color25 ${bg4}    # unused
        declare-option -hidden str powerline_color26 ${fg3}    # unused
        declare-option -hidden str powerline_color27 ${bg1}    # unused
        declare-option -hidden str powerline_color28 ${bg2}    # unused
        declare-option -hidden str powerline_color29 ${fg2}    # unused
        declare-option -hidden str powerline_color30 ${fg}     # unused
        declare-option -hidden str powerline_color31 ${bg3}    # unused

        declare-option -hidden str powerline_next_bg %opt{powerline_color08}
        declare-option -hidden str powerline_base_bg %opt{powerline_color08}
    "
}
