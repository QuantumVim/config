#!/usr/bin/env bash
set -eo pipefail

function validate_plugin_name() {
    # check the plugin name against patterns
    local plugin="$1"
    if [[ "$plugin" =~ ^[[:alnum:]_-]+/([[:alnum:]_-]+)\.nvim$ ]]; then
        plugin_name=${BASH_REMATCH[1]}
    elif [[ "$plugin" =~ ^[[:alnum:]_-]+/([[:alnum:]_-]+)\.lua$ ]]; then
        plugin_name=${BASH_REMATCH[1]}
    elif [[ "$plugin" =~ ^[[:alnum:]_-]+/([[:alnum:]_-]+)$ ]]; then
        plugin_name=${BASH_REMATCH[1]}
    else
        echo "Invalid plugin name: $plugin" >&2
        exit 1
    fi

    # special pattern
    if [[ "$plugin_name" == "nvim" ]]; then
        if [[ "$plugin" =~ ^([[:alnum:]_-]+)/nvim$ ]]; then
            plugin_name=${BASH_REMATCH[1]}
            plugin_name=${plugin_name//nvim/}
        fi
    fi

    # normalize plugin name
    if [ -n "$plugin_name" ]; then
        plugin_name=${plugin_name//--/-}
        hr_name=$plugin_name
        plugin_name=${plugin_name//-/_}
        plugin_name=${plugin_name,,}
    else
        echo "Invalid plugin name: $plugin" >&2
        exit 1
    fi

    echo "$plugin_name $hr_name"
}

PLUGIN_NAME=""
HR_NAME=""

while getopts "p:" opt; do
    case $opt in
        p)
            echo "Plugin name: $OPTARG" >&2
            read -r PLUGIN_NAME HR_NAME < <(validate_plugin_name "$OPTARG")
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

echo "Plugin name: $PLUGIN_NAME"
qvim_state_name="quantumvim"
NVIM_APPNAME="${NVIM_APPNAME:-"qvim"}"

XDG_CACHE_HOME="${XDG_CACHE_HOME:-"$HOME/.cache"}"
XDG_STATE_HOME="${XDG_STATE_HOME:-"$HOME/.local/state"}"
XDC_CONFIG_HOME="${XDC_CONFIG_HOME:-"$HOME/.config"}"

QUANTUMVIM_STATE_DIR="${QUANTUMVIM_STATE_DIR:-"$XDG_STATE_HOME/$qvim_state_name"}"
QUANTUMVIM_RTP_DIR="${QUANTUMVIM_RTP_DIR:-"$QUANTUMVIM_STATE_DIR/$NVIM_APPNAME"}"
QUANTUMVIM_CACHE_DIR="${QUANTUMVIM_CACHE_DIR:-"$XDG_CACHE_HOME/$NVIM_APPNAME"}"

QV_USER_CONFIG_DIR="${QV_USER_CONFIG_DIR:-"$XDC_CONFIG_HOME"/"$NVIM_APPNAME"}"
QV_USER_CONFIG_PLUGIN_DIR="${QV_USER_CONFIG_PLUGIN_DIR:-"$QV_USER_CONFIG_DIR"/"plugins"}"

function generate_plugin_config() {
    [ ! -d "$QV_USER_CONFIG_PLUGIN_DIR" ] && mkdir -p "$QV_USER_CONFIG_PLUGIN_DIR"
    local src_plugin="$QV_USER_CONFIG_DIR/scripts/templates/plugin.template"
    local dst_plugin="$QV_USER_CONFIG_PLUGIN_DIR/$HR_NAME.lua"

    # backup old files
    if [ -f "$dst_plugin" ]; then
        mv -v "$dst_plugin" "$dst_plugin.old"
    fi

    cp -v "$src_plugin" "$dst_plugin"

    sed -e s"#QV_STRING_PLUGIN_NAME_VAR#${HR_NAME}#"g \
        -e s"#QV_PLUGIN_NAME_VAR#${PLUGIN_NAME}#"g "${src_plugin}" \
        tee "${dst_plugin}" > /dev/null
}

if [ ! -d "$QUANTUMVIM_RTP_DIR" ]; then
    echo "Warn: QuantumVim is not installed. Please install it first." >&2
fi

if ! command -v qvim &> /dev/null; then
    echo "Warn: qvim is not a command. Please install it first." >&2
fi

generate_plugin_config

echo "Plugin config generated at: $QV_USER_CONFIG_PLUGIN_DIR/$HR_NAME.lua" >&2

exit 0
