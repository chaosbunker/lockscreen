#!/usr/bin/env bash
# shellcheck disable=1090

cd "$(dirname "$0")" || exit 1

LOCKSCREEN_BINARY="lockscreen"
LOCKSCREEN_SOURCE="lockscreen.c"
CONFIG_FILE="cfg.json"
PLIST_FILE="com.felixhammerl.lockscreen.plist"
AGENT_NAME="com.felixhammerl.lockscreen"
AGENTS_FOLDER="$HOME/Library/LaunchAgents"

echo "Configuring the lockscreen agent..."

if [ ! -f "$LOCKSCREEN_BINARY" ]; then
	echo "Compiling binary..."
	clang -framework login -F /System/Library/PrivateFrameworks --output="$LOCKSCREEN_BINARY" "$LOCKSCREEN_SOURCE"
	echo "Done."
fi

if [ ! -f "$CONFIG_FILE" ]; then
	echo "Configuring yubikey USB data..."
	system_profiler SPUSBDataType
	read -p "Please enter Vendor ID (without \"0x\"): " -r VID
	read -p "Please enter Product ID (without \"0x\"): " -r PID
  echo "{ \"vid\": $(( 16#$VID )), \"pid\": $(( 16#$PID ))}" > "$CONFIG_FILE"
	echo "Done."
fi

PROCESS_RUNNING=$(launchctl list | grep -c "$AGENT_NAME")
if [ $PROCESS_RUNNING != 0 ]; then
  echo "Terminating other agents ..."
	launchctl stop "$AGENT_NAME"
	launchctl unload "$AGENTS_FOLDER/$PLIST_FILE"
	echo "Done."
fi

echo "Starting the agent..."
cp "$PLIST_FILE" "$AGENTS_FOLDER/$PLIST_FILE"
launchctl load "$AGENTS_FOLDER/$PLIST_FILE"
launchctl start "$AGENT_NAME"

echo "Done."