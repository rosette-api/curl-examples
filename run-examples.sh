#!/bin/bash

service_url="https://api.rosette.com/rest/v1"
retcode=0
errors=( "Exception" "processingFailure" "badRequest" )

#------------ Start Functions --------------------------

#Gets called when the user doesn't provide any args
function usage {
  echo -e "\n${0} -a API_KEY -f [FILENAME] -u [ALT_URL]"
  echo "  API_KEY      - Rosette API key (required)"
  echo "  FILENAME     - Shell script file (optional)"
  echo "  ALT_URL      - Alternate URL (optional)"
  exit 1
}

# strip the trailing slash off of the alt_url if necessary
function cleanURL() {
  if [ ! -z "${ALT_URL}" ]; then
    case ${ALT_URL} in
      */) ALT_URL=${ALT_URL::-1}
        echo "Slash detected"
        ;;
    esac
    service_url=${ALT_URL}
  fi
}

function checkAPIKey() {
  output_file=check_key_out.log
  http_status_code=$(curl -s -o "${output_file}" -w "%{http_code}" -H "X-RosetteAPI-Key: ${API_KEY}" "${service_url}/ping")
  if [ "${http_status_code}" = "403" ]; then
    echo -e "\nInvalid Rosette API key.  Output is:\n"
    cat "${output_file}"
    rm "${output_file}"
    exit 1
  else
    rm "${output_file}"
  fi
}

function validateURL() {
  output_file=validate_url_out.log
  http_status_code=$(curl -s -o "${output_file}" -w "%{http_code}" -H "X-RosetteAPI-Key: ${API_KEY}" "${service_url}/ping")
  if [ "${http_status_code}" != "200" ]; then
    echo -e "\n${service_url} server not responding.  Output is:\n"
    cat "${output_file}"
    rm "${output_file}"
    exit 1
  else
    rm "${output_file}"
  fi
}

function runExample() {
  echo -e "\n---------- ${1} start -------------"
  result=""
  script="$(sed s/your_api_key/${API_KEY}/ < ./${1})" #replacing your_api_key with actual key
  if [ ! -z ${ALT_URL} ]; then
    script=$(echo "${script}" | sed "s#https://api.rosette.com/rest/v1#${service_url}#") #replacing api url with alt URL if provided
  fi
  script=$(echo "${script}" | sed 's~\\$~~g' )
  echo $script #curl -x etc etc
  result="$(echo ${script} | bash 2>&1)" #run api operation
  echo "${result}"
  echo -e "\n---------- ${1} end -------------"
  for err in "${errors[@]}"; do
    if [[ ${result} == *"${err}"* ]]; then
      retcode=1
    fi
  done
}

#------------ End Functions ----------------------------

#Gets API_KEY, FILENAME
while getopts ":a:f:u:" arg; do
  case "${arg}" in
    a)
      API_KEY=${OPTARG}
      ;;
    f)
      FILENAME=${OPTARG}
      ;;
    u)
      ALT_URL=${OPTARG}
      echo "Using alternate URL: ${ALT_URL}"
      ;;
    :)
      echo "Option -${OPTARG} requires an argument"
      usage
      ;;
  esac
done

if [ -z ${API_KEY} ]; then
  echo "-a API_KEY required"
  usage
fi

cleanURL

validateURL

#Run the examples
if [ ! -z ${API_KEY} ]; then
  checkAPIKey
  pushd examples
  if [ ! -z ${FILENAME} ]; then
    runExample ${FILENAME}
  else
    for file in *.curl; do
      runExample ${file}
    done
  fi
else 
  HELP
fi

exit ${retcode}
