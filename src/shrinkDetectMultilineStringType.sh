#!/usr/bin/env bash

#
# Checks if the given line ends with an open string.
#
# @param string $1
# String.
#
# @return string
# Possible return values
# -      '' : Line ends normaly
# -  single : single quote open
# -  double : double quote open
shrinkDetectMultilineStringType() {
  local strLine="${1}"
  local strOpenType=""

  local prevChar=""
  local currentChar=""
  local i="0"
  for (( i=0; i<${#strLine}; i++ )); do
    currentChar="${strLine:$i:1}"

    case "${strOpenType}" in
      "")
        if [ "${currentChar}" == "'" ]; then
          strOpenType="single"
        elif [[ "${prevChar}" != "\\" && "${currentChar}" == '"' ]]; then
          strOpenType="double"
        fi
        ;;

      "single")
        if [ "${currentChar}" == "'" ]; then
          strOpenType=""
        fi
        ;;

      "double")
        if [[ "${prevChar}" != "\\" && "${currentChar}" == '"' ]]; then
          strOpenType=""
        fi
        ;;
    esac

    prevChar="${currentChar}"
  done

  echo -ne "${strOpenType}"
}