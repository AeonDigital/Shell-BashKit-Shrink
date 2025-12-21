#!/usr/bin/env bash

#
# Execute action
#
# @param string $1
# Action to be executed.
#
# Choose one of:
# - load
execBashKit() {
  local action="${1:-load}"
  local currentDirectoryPath="$(tmpPath=$(dirname "${BASH_SOURCE[0]}"); realpath "${tmpPath}")"
  local projectName="${currentDirectoryPath##*/}"

  case "${action,,}" in 
    load)
      local it=""
      for it in $(find "${currentDirectoryPath}/src" -type f -name "*.sh" | sort); do
        . "${it}"
      done
      ;;

    shrink|pkg)
      local it=""
      for it in $(find "${currentDirectoryPath}/src" -type f -name "*.sh" | sort); do
        . "${it}"
      done

      local codeNL=$'\n'
      local strShrinkHeader+="#${codeNL}"
      strShrinkHeader+="# mounted by Shell-BashKit-Shrink in "
      strShrinkHeader+=$(date +"%Y-%m-%d %H:%M:%S")
      strShrinkHeader+="${codeNL}${codeNL}"


      shrinkPackage "${currentDirectoryPath}/src" "${currentDirectoryPath}/package-${projectName,,}.sh" "${strShrinkHeader}"

      unset shrinkPackage
      unset shrinkFileScript
      unset shrinkCheckOpenHeredoc
      unset shrinkDetectMultilineStringType
      ;;
  esac
}
execBashKit "${1}"
unset execBashKit