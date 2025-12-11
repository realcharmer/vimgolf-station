#!/usr/bin/env bash
set -euo pipefail
trap '' INT

VIMGOLF_IMAGE="ghcr.io/igrigorik/vimgolf:latest"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

network_configuration() {
	echo -n "+ Connecting to Wi-Fi "
	while ! ip a | grep -E "wlan0.*UP" >& /dev/null; do
		echo -n "."
		sleep 1
	done
	echo -e ". \e[32mDone\e[0m"
	echo -n "+ Testing DNS "
	while ! ping -c 1 vimgolf.com >& /dev/null ; do
		echo -n "."
		sleep 1
	done
	echo -e ". \e[32mDone\e[0m"
}

vimgolf() {
	clear
	cat "$SCRIPT_DIR/banner"
	for key in "${!CHALLENGES[@]}"; do
		local val="${CHALLENGES[$key]}"
		local desc="${val#*|}"
		printf " \e[32m[%s] \e[0m%s\n" "$key" "$desc"
	done
	echo
	read -rp " Select challenge: " choice
	# Handle empty input
	if [[ -z "$choice" ]]; then
		echo
		echo -e " \e[31mNo challenge entered!\e[0m"
		sleep 1
		return
	fi
	# Handle invalid input
	if [[ -z "${CHALLENGES[$choice]:-}" ]]; then
		echo
		echo -e " \e[31mInvalid challenge!\e[0m"
		sleep 1
		return
	fi
	local CHALLENGE_ID
	IFS='|' read -r CHALLENGE_ID _ <<< "${CHALLENGES[$choice]}"
	echo
	echo -e " Loading \e[32m[$CHALLENGE_ID]\e[0m"
	docker run --rm -it -e "key=$USER_KEY" "$VIMGOLF_IMAGE" "$CHALLENGE_ID"
}

if [[ ! -f "$SCRIPT_DIR/config" ]]; then
	echo "Configuration file missing!"
	exit 1
fi
# shellcheck disable=SC1091
source "$SCRIPT_DIR/config"
network_configuration
docker pull "$VIMGOLF_IMAGE"
while true; do
	vimgolf
done
