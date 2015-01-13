#!/usr/bin/env zsh

setopt ERR_EXIT
setopt NO_UNSET

# ==============================================================================
# = Configuration                                                              =
# ==============================================================================

# Paths

root=$0:A:h:h


# Packages

aur_packages=(
)

pacman_packages=(
  git
  zsh
)


# ==============================================================================
# = Tasks                                                                      =
# ==============================================================================

function install_pacman_packages()
{
    sudo pacman --noconfirm --sync --needed --refresh $pacman_packages
}

function install_meteor()
{
    if (( ! $+commands[meteor] )); then
        curl https://install.meteor.com | /usr/bin/bash
    fi
}


# ==============================================================================
# = Command line interface                                                     =
# ==============================================================================

tasks=(
    install_pacman_packages
    install_meteor
)

function usage()
{
    cat <<-'EOF'
		Set up a development environment

		Usage:

		    setup.zsh [TASK...]

		Tasks:

		    install_pacman_packages
		    install_meteor
	EOF
    exit 1
}

for task in $@; do
    if [[ ${tasks[(i)$task]} -gt ${#tasks} ]]; then
        usage
    fi
done

for task in ${@:-$tasks}; do
    print -P -- "%F{green}Task: $task%f"
    $task
done

