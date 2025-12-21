#!/usr/bin/env bash

#
# mounted by Shell-BashKit-Shrink in 2025-12-20 23:30:32


shrinkCheckOpenHeredoc() {
  local strLine="${1}"
  strLine="${strLine#"${strLine%%[![:space:]]*}"}" # trim L
  strLine="${strLine//<<</}" # Remove herestring ini
  if [[ "${strLine}" =~ (^|[^\"\'])(\<\<-?)([[:space:]]*)([A-Za-z0-9_]+|\'[^\']*\'|\"[^\"]*\") ]]; then
    local delimiter="${BASH_REMATCH[4]}"
    delimiter="${delimiter%'}"
    delimiter="${delimiter#'}"
    delimiter="${delimiter%\"}"
    delimiter="${delimiter#\"}"
    echo -ne "${delimiter}"
  fi
}
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
shrinkPackage() {
  local tgtDir="${1}"
  if [ ! -d "${tgtDir}" ]; then
    echo "[ x ] Error: target directory does not exists!" >&2
    return "1"
  fi
  local tgtPackage="${2}"
  if [ "${tgtPackage}" == "" ]; then
    echo "[ x ] Error: package filename cannot be empty!" >&2
    return "1"
  fi
  local strShrinkHeader="${3}"
  local codeNL=$'\n'
  local strPackageFileContent=""
  local pathToTargetFile=""
  for pathToTargetFile in $(find "${tgtDir}" -type f -name "*.sh" | sort); do
    strPackageFileContent+="$(< "${pathToTargetFile}")${codeNL}"
  done
  if [ "${strPackageFileContent}" == "" ]; then
    echo "[ x ] Error: target content is empty!" >&2
    return "1"
  fi
  echo -n "${strPackageFileContent}" > "${tgtPackage}"
  if [ "$?" != "0" ]; then
    echo "[ x ] Error: on create 'package.sh' file!" >&2
    return "1"
  fi
  if ! bash -n "${tgtPackage}"; then
    echo "[ x ] Error: Selected code has sintax error; Created a '${tgtPackage}.error' for debug proposes." >&2
    mv "${tgtPackage}" "${tgtPackage}.error"
    return "1"
  fi
  shrinkFileScript "${tgtPackage}" "" "${strShrinkHeader}"
  if [ "$?" != "0" ]; then
    echo "[ x ] Error: Fail on shrink '${tgtPackage}'; Created a '${tgtPackage}.error' for debug proposes." >&2
    mv "${tgtPackage}" "${tgtPackage}.error"
    return "1"
  else
    if ! bash -n "${tgtPackage}"; then
      echo "[ x ] Error: Selected code has sintax error after shrink proccess; Created a '${tgtPackage}.error' for debug proposes." >&2
      mv "${tgtPackage}" "${tgtPackage}.error"
      return "1"
    fi
    echo "[ v ] Success: File '${tgtPackage}' created!"
    return "0"
  fi
}