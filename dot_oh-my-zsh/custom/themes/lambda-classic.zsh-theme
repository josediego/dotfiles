# lambda-classic — variante duotono del tema lambda
# λ + path en el color base, branch de git en el acento (amarillo/ámbar).
# Toma los colores de la paleta ANSI de la terminal (Gruvbox), así prompt y
# terminal quedan unidos sin hardcodear nada.

PROMPT='%{$fg_bold[green]%}λ%{$reset_color%} %~/ $(git_prompt_info)%{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[yellow]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg_bold[yellow]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""
