# Flexoki (light) — https://stephango.com/flexoki
# Colours come from flexoki-palette.kak (generated from lib/flexoki.nix), read
# here via %opt{flx_*}. Structure mirrors kakoune's built-in gruvbox-light.

# Code highlighting
face global value         "%opt{flx_purple}"
face global type          "%opt{flx_yellow}"
face global variable      "%opt{flx_blue}"
face global module        "%opt{flx_green}"
face global function      "%opt{flx_tx}"
face global string        "%opt{flx_green}"
face global keyword       "%opt{flx_red}"
face global operator      "%opt{flx_tx}"
face global attribute     "%opt{flx_orange}"
face global comment       "%opt{flx_tx2}+i"
face global documentation comment
face global meta          "%opt{flx_cyan}"
face global builtin       "%opt{flx_tx}+b"

# Markdown highlighting
face global title  "%opt{flx_green}+b"
face global header "%opt{flx_orange}"
face global mono   "%opt{flx_tx2}"
face global block  "%opt{flx_cyan}"
face global link   "%opt{flx_blue}+u"
face global bullet "%opt{flx_yellow}"
face global list   "%opt{flx_tx}"

# UI
face global Default            "%opt{flx_tx},%opt{flx_bg}"
face global PrimarySelection   "default,%opt{flx_ui3}"
face global SecondarySelection "default,%opt{flx_ui}"
face global PrimaryCursor      "%opt{flx_bg},%opt{flx_tx}+fg"
face global SecondaryCursor    "%opt{flx_bg},%opt{flx_tx2}+fg"
face global PrimaryCursorEol   "%opt{flx_bg},%opt{flx_tx3}+fg"
face global SecondaryCursorEol "%opt{flx_bg},%opt{flx_ui3}+fg"
face global LineNumbers        "%opt{flx_tx3}"
face global LineNumberCursor   "%opt{flx_yellow},%opt{flx_ui}"
face global LineNumbersWrapped "%opt{flx_ui2}"
face global MenuForeground     "%opt{flx_bg},%opt{flx_blue}"
face global MenuBackground     "%opt{flx_tx},%opt{flx_ui}"
face global MenuInfo           "%opt{flx_tx2}"
face global Information        "%opt{flx_bg},%opt{flx_tx}"
face global Error              "%opt{flx_bg},%opt{flx_red}"
face global StatusLine         "%opt{flx_tx},%opt{flx_bg}"
face global StatusLineMode     "%opt{flx_yellow}+b"
face global StatusLineInfo     "%opt{flx_purple}"
face global StatusLineValue    "%opt{flx_red}"
face global StatusCursor       "%opt{flx_bg},%opt{flx_tx}"
face global Prompt             "%opt{flx_yellow}"
face global MatchingChar       "%opt{flx_tx},%opt{flx_ui2}+b"
face global BufferPadding      "%opt{flx_ui3},%opt{flx_bg}"
face global Whitespace         "%opt{flx_ui2}+f"
