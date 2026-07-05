require-module powerline
powerline-start

set-option global powerline_ignore_warnings true
set-option global powerline_format 'git lsp bufname line_column filetype mode_info position'
set-option global powerline_separator ''
set-option global powerline_separator_thin ''

# Colours reference flexoki-palette.kak (generated from lib/flexoki.nix), which
# kakrc sources before this file. Only the slots used by our powerline_format
# modules are set; the plugin pre-declares the rest.
declare-option -hidden str powerline_color00 %opt{flx_bg}      # fg: bufname
declare-option -hidden str powerline_color01 %opt{flx_tx3}     # bg: position
declare-option -hidden str powerline_color02 %opt{flx_yellow}  # fg: git
declare-option -hidden str powerline_color03 %opt{flx_tx}      # bg: bufname
declare-option -hidden str powerline_color04 %opt{flx_bg}      # bg: git
declare-option -hidden str powerline_color05 %opt{flx_tx}      # fg: position
declare-option -hidden str powerline_color06 %opt{flx_tx}      # fg: line-column, lsp
declare-option -hidden str powerline_color07 %opt{flx_bg}      # fg: mode-info
declare-option -hidden str powerline_color08 %opt{flx_ui2}     # base background
declare-option -hidden str powerline_color09 %opt{flx_tx3}     # bg: line-column, lsp
declare-option -hidden str powerline_color10 %opt{flx_tx2}     # fg: filetype
declare-option -hidden str powerline_color11 %opt{flx_ui}      # bg: filetype
declare-option -hidden str powerline_color12 %opt{flx_ui2}     # bg: client
declare-option -hidden str powerline_color13 %opt{flx_tx}      # fg: client
declare-option -hidden str powerline_color14 %opt{flx_tx}      # fg: session
declare-option -hidden str powerline_color15 %opt{flx_ui3}     # bg: session

declare-option -hidden str powerline_next_bg %opt{powerline_color08}
declare-option -hidden str powerline_base_bg %opt{powerline_color08}
