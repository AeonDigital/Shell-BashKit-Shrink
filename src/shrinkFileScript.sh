#!/usr/bin/env bash

#
# Remove all comments and empty lines.
# 
# @param string $1
# Original file.
#
# @param string $2
# New shrink file.
# If not defined will subscribe the original file.
#
# @param string $3
# Optional. Data to be set in package file header (before shebang).
#
# @return status
shrinkFileScript() {
  local strOriginalFile="${1}"
  local strShrinkFile="${2}"
  local strShrinkHeader="${3}"

  if [ ! -f "${strOriginalFile}" ]; then
    echo "[ x ] Error: Original file '${strOriginalFile}' does not exists." >&2
    return "1"
  fi

  if [ "${strShrinkFile}" == "" ]; then
    strShrinkFile="${strOriginalFile}"
  fi


  local codeNL=$'\n'
  local strRawLine=""
  local strCleanLine=""
  local strOpenQuoteType=""
  local strOpenQuoteFullLine=""
  local hereDocToken=""
  local strPackageFileContent="#!/usr/bin/env bash${codeNL}${codeNL}"


  if [ "${strShrinkHeader}" != "" ]; then
    strPackageFileContent+="${strShrinkHeader}${codeNL}"
  fi
 

  while IFS=$'\n' read -r strRawLine || [ -n "${strRawLine}" ]; do
    if [ "${strOpenQuoteType}" != "" ]; then
      strOpenQuoteFullLine+="${strRawLine}"
      strPackageFileContent+="${strRawLine}${codeNL}"

      strOpenQuoteType=$(shrinkDetectMultilineStringType "${strOpenQuoteFullLine}")
      continue
    fi


    if [ "${hereDocToken}" != "" ]; then
      strPackageFileContent+="${strRawLine}${codeNL}"

      if [ "${strRawLine}" == "${hereDocToken}" ]; then
        hereDocToken=""
      fi
      continue
    fi



    hereDocToken=$(shrinkCheckOpenHeredoc "${strRawLine}")
    if [ "${hereDocToken}" != "" ]; then
      strPackageFileContent+="${strRawLine}${codeNL}"
      continue
    fi



    strCleanLine="${strRawLine}"
    strCleanLine="${strCleanLine#"${strCleanLine%%[![:space:]]*}"}" # trim L
    strCleanLine="${strCleanLine%"${strCleanLine##*[![:space:]]}"}" # trim R

    if [ "${strCleanLine:0:1}" == "#" ]; then
      continue
    fi

    strOpenQuoteType=$(shrinkDetectMultilineStringType "${strRawLine}")
    if [ "${strOpenQuoteType}" != "" ]; then
      strOpenQuoteFullLine="${strRawLine}"
      strPackageFileContent+="${strRawLine}${codeNL}"
      continue
    fi

    if [ "${strCleanLine}" == "" ]; then
      continue
    fi

    strPackageFileContent+="${strRawLine}${codeNL}"

  done < "${strOriginalFile}"


  strPackageFileContent="${strPackageFileContent#"${strPackageFileContent%%[![:space:]]*}"}" # trim L
  strPackageFileContent="${strPackageFileContent%"${strPackageFileContent##*[![:space:]]}"}" # trim R

  echo -n "${strPackageFileContent}" > "${strShrinkFile}"
}