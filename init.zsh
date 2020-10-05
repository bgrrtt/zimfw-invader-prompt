# vim:et sts=2 sw=2 ft=zsh
# =============================================================================

# Invader Prompt
# ========================
# Requires zimfw's git-info module

# =============================================================================
# Prompt Character

invader_char () {
  success_char_str="%F{green}❯%F{green}❯%F{white}"
  failure_char_str="%F{red}❯%F{red}❯%F{white}"
  prompt_char_str="%(0?.$success_char_str.$failure_char_str) "
  echo $prompt_char_str
}


# =============================================================================
# Current Working Directory

invader_cwd () {
  inside_git_repo="$(git rev-parse --is-inside-work-tree 2>/dev/null)"
  if [ "$inside_git_repo" ]; then
    git_root_path="$(git rev-parse --show-toplevel)"
    git_root_dir="$git_root_path:t${${PWD:A}#$~git_root_path}"
    git_root_parent_dir="$(basename $(dirname $git_root_path))"
    cwd_str="%F{blue}$git_root_parent_dir/$git_root_dir "
  else
    cwd_str="%F{blue}%4(~:../:)%3~ "
  fi
  echo $cwd_str
}


# =============================================================================
# Time

invader_time () {
  time_str="%F{yellow}%D{%T}"
  echo $time_str
}


# =============================================================================
# Git

invader_git_active_branch () {
    git_branch_str="%F{white}${(e)git_info[active_branch]}%F{white} "
    echo $git_branch_str
}

invader_git_active_status () {
    git_status_str="%F{white}${(e)git_info[active_status]} "
    echo $git_status_str
}

invader_git_active_remote () {
    git_status_str="%F{red}${(e)git_info[active_remote]}%F{white} "
    echo $git_status_str
}


# =============================================================================
# Docker

invader_docker_status() {
    if [[ -e docker-compose.yml ]]; then
        if [[ $DOCKER_MACHINE_NAME != "" && $DOCKER_MACHINE_NAME != "default" ]]; then
          DOCKER_MACHINE_NAME_LOCAL="%{$fg_bold[red]%}"$DOCKER_MACHINE_NAME"%{$fg_bold[blue]%}:"
        fi
        echo -n " ("$DOCKER_MACHINE_NAME_LOCAL
        docker-compose ps 2>/dev/null | tail -n+3 | while read line
        do
            CONTAINER_LETTER_POSITION=$(echo $line | awk 'match($0,"_"){print RSTART}')
            CONTAINER_LETTER=$(echo ${line:$CONTAINER_LETTER_POSITION:1} | tr '[:lower:]' '[:upper:]')
            if [[ $line == *"Up"* ]]; then
                echo -n "%{$fg_bold[green]%}"$CONTAINER_LETTER"%{$fg_bold[blue]%}"
            else
                echo -n "%{$fg_bold[red]%}"$CONTAINER_LETTER"%{$fg_bold[blue]%}"
            fi
        done
        echo -n ")"
    fi
}


# =============================================================================
# Kubernetes Control Context

invader_kube_context () {
    local kube_context=$(kubectl config current-context 2>/dev/null)
    [[ -z $kube_context ]] && return
    local kube_namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
    [[ -n $kube_namespace && "$kube_namespace" != "default" ]] && kube_context="$kube_context ($kube_namespace)"
    echo $kube_context
}


# =============================================================================
# GCloud (Account and Project)

invader_gcloud_prompt () {
    local gcloud_account=$(gcloud config get-value account 2>/dev/null)
    [[ -z $gcloud_account ]] && return
    local gcloud_project=$(gcloud config get-value project 2>/dev/null)
    [[ -z $gcloud_project ]] && return
    local gcloud_prompt="${gcloud_account}:${gcloud_project}"
    echo $gcloud_prompt
}


# =============================================================================
# Prompt

prompt_invader_precmd() {
    (( ${+functions[git-info]} )) && git-info
}

prompt_invader_setup() {
    autoload -Uz add-zsh-hook && add-zsh-hook precmd prompt_invader_precmd

    setopt no_prompt_bang prompt_cr prompt_percent prompt_sp prompt_subst

    zstyle ':zim:git-info' verbose yes
    zstyle ':zim:git-info' ignore-submodules 'none'

    zstyle ':zim:git-info:action:apply' format 'apply'
    zstyle ':zim:git-info:action:bisect' format 'bisect: <B>'
    zstyle ':zim:git-info:action:cherry-pick' format 'cherry-pick'
    zstyle ':zim:git-info:action:cherry-pick-sequence' format 'cherry-pick-sequence'
    zstyle ':zim:git-info:action:merge' format 'merge: >M<'
    zstyle ':zim:git-info:action:rebase' format ' >R>'
    zstyle ':zim:git-info:action:rebase-interactive' format 'rebase-interactive'
    zstyle ':zim:git-info:action:rebase-merge' format 'rebase-merge'
    zstyle ':zim:git-info:action' format '%s'              # %s
    zstyle ':zim:git-info:ahead' format '%F{green} ⬆︎'      # %A
    zstyle ':zim:git-info:behind' format '%F{red} ⬇'       # %B
    zstyle ':zim:git-info:diverged' format '%F{magenta} ✖' # %V
    zstyle ':zim:git-info:branch' format '%b'              # %b
    zstyle ':zim:git-info:commit' format '%F{yellow}%c'    # %c
    zstyle ':zim:git-info:clean' format '%F{green}'        # %C
    zstyle ':zim:git-info:dirty' format '%F{yellow}'       # %D
    zstyle ':zim:git-info:indexed' format '%F{green} ✚'    # %i
    zstyle ':zim:git-info:unindexed' format '%F{blue} ✱'   # %I
    zstyle ':zim:git-info:position' format '%F{white} %p'  # %p
    zstyle ':zim:git-info:remote' format '%F{green}'       # %R
    zstyle ':zim:git-info:stashed' format '%F{magenta} ✦'  # %S
    zstyle ':zim:git-info:untracked' format '%F{red} ??'   # %u

    zstyle ':zim:git-info:keys' format \
            'active_branch' '%C%D%b%c%p' \
            'active_status' '%s%A%B%V%D%i%I%S%u' \
            'active_remote' '%R'

    new_line=$'\n'
    new_prompt_lines=${new_line}${new_line}${new_line}${new_line}

    PROMPT=''
    PROMPT+='${new_prompt_lines}'
    PROMPT+='$(invader_cwd)$(invader_git_active_remote)$(invader_git_active_branch)$(invader_kube_context)$(invader_docker_status)'
    PROMPT+='${new_line}'
    PROMPT+='$(invader_char)'

    RPROMPT=''
    RPROMPT+='$(invader_git_active_status)'

}

prompt_invader_setup "${@}"
