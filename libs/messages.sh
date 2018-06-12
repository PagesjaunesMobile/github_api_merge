RESTORE='\033[0m'
RED='\033[00;31m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
GREEN='\033[00;32m'

function color_echo {
	echo -e "$1$2${RESTORE}"
}

function msg_error {
	echo "$(color_echo ${RED} [Error]) $1"
  echo
}

function msg_warn {
	echo "$(color_echo ${YELLOW} [Warn]) $1"
}

function msg_info {
	echo "$(color_echo ${BLUE} [Info]) $1"
}

function msg_success {
	echo "$(color_echo ${GREEN} [OK]) $1"
}