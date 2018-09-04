#!/bin/bash
# Copyright (C) 2018  Mikkel Oscar Lyderik Larsen
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

init() {
  # Assign default value if unset or null (ensures it is never null)
  : "${CC:=gcc}"
}

# read arch-travis config from env
read_config() {
  local old_ifs=$IFS
  local sep='::::'
  CONFIG_BUILD_SCRIPTS=${CONFIG_BUILD_SCRIPTS//$sep/\$'\n'}
  CONFIG_PACKAGES=${CONFIG_PACKAGES//$sep/\$'\n'}
  CONFIG_REPOS=${CONFIG_REPOS//$sep/\$'\n'}
  IFS=$'\n'
  CONFIG_BUILD_SCRIPTS=(${CONFIG_BUILD_SCRIPTS[@]})
  CONFIG_PACKAGES=(${CONFIG_PACKAGES[@]})
  CONFIG_REPOS=(${CONFIG_REPOS[@]})
  IFS=$old_ifs
}

# add custom repositories to pacman.conf
add_repositories() {
  # /etc/pacman.conf repository line
  local repo_line='70'
  
  if [ ${#CONFIG_REPOS[@]} -gt 0 ]; then
    for r in "${CONFIG_REPOS[@]}"; do
      local splitarr=(${r//=/ })
      ((repo_line+=1))
      sudo sed -i "${repo_line}i[${splitarr[0]}]" /etc/pacman.conf
      ((repo_line+=1))
      sudo sed -i "${repo_line}iServer = ${splitarr[1]}\n" /etc/pacman.conf
      ((repo_line+=1))
    done

    # update repos
    sudo pacman -Syy
  fi
}

# upgrade system to avoid partial upgrade states
upgrade_system() {
  sudo pacman -Syu --noconfirm
}

# install packages defined in .travis.yml
install_packages() {
  for package in "${CONFIG_PACKAGES[@]}"; do
    sudo pacman -S $package --noconfirm --needed
  done
}

# run build scripts defined in .travis.yml
build_scripts() {
  if [ ${#CONFIG_BUILD_SCRIPTS[@]} -gt 0 ]; then
    for script in "${CONFIG_BUILD_SCRIPTS[@]}"; do
      echo "\$ $script"
      eval $script
    done
  else
    echo "No build scripts defined"
    exit 1
  fi
}

arch_msg() {
  lightblue='\033[1;34m'
  reset='\e[0m'
  echo -e "${lightblue}$@${reset}"
}

main() {
  cd /build

  init

  read_config

  # If custom compiler is defined, add it to packages to install
  if [[ "${CC}" != 'gcc' ]]; then
    CONFIG_PACKAGES+="${CC}"
  fi

  echo "travis_fold:start:arch_travis"
  arch_msg "Setting up Arch environment"
  add_repositories

  upgrade_system
  install_packages

  echo "travis_fold:end:arch_travis"
  echo ""

  arch_msg "Running travis build"
  build_scripts
}

main
