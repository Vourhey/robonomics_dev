#!/usr/bin/env bash

ROBONOMICS_COMM_VERSION="1.1.0"

# Install all the packages and dependencies
function init() {
    sudo apt update && sudo apt install -y curl python3-pip

	curl https://nixos.org/nix/install | sh
	echo "https://aira.life/channels/aira-unstable nixos" > ~/.nix-channels
	. ~/.nix-profile/etc/profile.d/nix.sh
	nix-channel --update
	nix-env -iA cachix -f https://cachix.org/api/v1/install
	cachix use aira
	nix-env -iA nixos.robonomics_comm
}

function generate_keyfile() {
	ROBONOMICS_COMM="$(find /nix/store -type d | grep robonomics_comm-$ROBONOMICS_COMM_VERSION | head -n 1)"
	echo "source $ROBONOMICS_COMM/setup.bash" > env.bash
    echo "source $ROBONOMICS_COMM/setup.zsh" > env.zsh
	. $ROBONOMICS_COMM/setup.bash

	# Generate keyfile
	if [ ! -e keyfile ]; then
		PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c32)
		echo $PASSWORD > keyfile_password_file
		python3 -c "import os,eth_keyfile,json; print(json.dumps(eth_keyfile.create_keyfile_json(os.urandom(32), '$PASSWORD'.encode())))" > keyfile
	fi
}

# Run IPFS
function start_ipfs() {
    [ ! -x ~/.ipfs ] && ipfs init
	ipfs daemon --enable-pubsub-experiment &
	sleep 5
	ipfs swarm connect /dnsaddr/bootstrap.aira.life &
}

function mainnet() {
	generate_keyfile
	start_ipfs

	WORKSPACE=`pwd`

	roslaunch robonomics_liability liability.launch \
		lighthouse_contract:="airalab.lighthouse.5.robonomics.eth" \
		keyfile:="$WORKSPACE/keyfile" \
		keyfile_password_file:="$WORKSPACE/keyfile_password_file" \
		web3_http_provider:="https://mainnet.infura.io/v3/cd7368514cbd4135b06e2c5581a4fff7" \
		web3_ws_provider:="wss://mainnet.infura.io/ws" &

	sleep 5

	roslaunch ethereum_common erc20.launch \
		keyfile:="$WORKSPACE/keyfile" \
		keyfile_password_file:="$WORKSPACE/keyfile_password_file" \
		web3_http_provider:="https://mainnet.infura.io/v3/cd7368514cbd4135b06e2c5581a4fff7" \
		web3_ws_provider:="wss://mainnet.infura.io/ws" &
}

function sidechain() {
	generate_keyfile
	start_ipfs

	WORKSPACE=`pwd`
	roslaunch robonomics_liability liability.launch \
		lighthouse_contract:="airalab.lighthouse.5.robonomics.sid" \
	    factory_contract:="factory.5.robonomics.sid" \
        graph_topic:="graph.5.robonomics.sid" \
        ens_contract:="0xaC4Ac4801b50b74aa3222B5Ba282FF54407B3941" \
        keyfile:="$WORKSPACE/keyfile" \
        keyfile_password_file:="$WORKSPACE/keyfile_password_file" \
        web3_http_provider:="https://sidechain.aira.life/rpc" \
        web3_ws_provider:="wss://sidechain.aira.life/ws" &

	sleep 5

	roslaunch ethereum_common erc20.launch \
		factory_contract:="factory.5.robonomics.sid" \
		erc20_token:="xrt.5.robonomics.sid" \
		ens_contract:="0xaC4Ac4801b50b74aa3222B5Ba282FF54407B3941" \
		keyfile:="$WORKSPACE/keyfile" \
		keyfile_password_file:="$WORKSPACE/keyfile_password_file" \
		web3_http_provider:="https://sidechain.aira.life/rpc" \
		web3_ws_provider:="wss://sidechain.aira.life/ws" &
}

function help() {
    __usage="
    Usage: ./robonomics.sh init|mainnet|sidechain

    Options:
        init        install all the necessary packages and dependencies
        mainnet     launch the Robonomics stack in Mainnet (airalab.lighthouse.5.robonomics.eth)
        sidechain   launch the Robonomics stack in Sidechain (airalab.lighthouse.5.robonomics.sid)
    "
    echo "$__usage"
}

case "$1" in
    "init")
        echo "Installing dependencies and robonomics_comm"
        init
        ;;
    "mainnet")
        echo "Starting Robonomics Mainnet"
        mainnet
        ;;
    "sidechain")
        echo "Starting Robonomics Sidechain"
        sidechain
        ;;
    *)
        help
        ;;
esac

