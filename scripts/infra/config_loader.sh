#!/usr/bin/env bash

# INI config loader for bash workflow scripts.
# Source this file and call load_config/get_config helpers.

declare -gA CONFIG_VALUES=()
declare -g CONFIG_SOURCE_FILE=""

_config_trim() {
    local value="${1-}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

_config_store_key() {
    local section="$1"
    local key="$2"
    local normalized_section normalized_key

    normalized_section="$(_config_trim "$section")"
    normalized_key="$(_config_trim "$key")"

    normalized_section="${normalized_section,,}"
    normalized_key="${normalized_key,,}"

    printf '%s.%s' "$normalized_section" "$normalized_key"
}

_config_env_key() {
    local section="$1"
    local key="$2"
    local env_key

    env_key="${section}_${key}"
    env_key="${env_key^^}"
    env_key="${env_key//[^A-Z0-9_]/_}"
    printf '%s' "$env_key"
}

load_config() {
    local file="$1"
    local line trimmed current_section key value store_key

    if [[ -z "$file" ]]; then
        printf 'Error: load_config requires <file>\n' >&2
        return 1
    fi

    if [[ ! -f "$file" ]]; then
        printf 'Error: Config file not found: %s\n' "$file" >&2
        return 1
    fi

    CONFIG_VALUES=()
    CONFIG_SOURCE_FILE="$file"
    current_section=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        trimmed="$(_config_trim "$line")"

        if [[ -z "$trimmed" ]]; then
            continue
        fi

        if [[ "$trimmed" == \#* || "$trimmed" == \;* ]]; then
            continue
        fi

        if [[ "$trimmed" =~ ^\[(.+)\]$ ]]; then
            current_section="$(_config_trim "${BASH_REMATCH[1]}")"
            continue
        fi

        if [[ "$trimmed" == *"="* ]]; then
            key="$(_config_trim "${trimmed%%=*}")"
            value="$(_config_trim "${trimmed#*=}")"

            if [[ -z "$current_section" || -z "$key" ]]; then
                continue
            fi

            store_key="$(_config_store_key "$current_section" "$key")"
            CONFIG_VALUES["$store_key"]="$value"
        fi
    done < "$file"

    return 0
}

get_config() {
    local section="$1"
    local key="$2"
    local default_value="${3-}"
    local env_key store_key

    if [[ -z "$section" || -z "$key" ]]; then
        printf 'Error: get_config requires <section> <key> [default]\n' >&2
        return 1
    fi

    env_key="$(_config_env_key "$section" "$key")"
    if [[ -n "${!env_key+x}" ]]; then
        printf '%s\n' "${!env_key}"
        return 0
    fi

    store_key="$(_config_store_key "$section" "$key")"
    if [[ -n "${CONFIG_VALUES[$store_key]+x}" ]]; then
        printf '%s\n' "${CONFIG_VALUES[$store_key]}"
        return 0
    fi

    if [[ $# -ge 3 ]]; then
        printf '%s\n' "$default_value"
        return 0
    fi

    return 1
}

require_config() {
    local section="$1"
    local key="$2"
    local value

    value="$(get_config "$section" "$key")" || {
        printf 'Error: Required config missing: [%s] %s\n' "$section" "$key" >&2
        exit 1
    }

    printf '%s\n' "$value"
}

config_has() {
    local section="$1"
    local key="$2"
    local env_key store_key

    if [[ -z "$section" || -z "$key" ]]; then
        return 1
    fi

    env_key="$(_config_env_key "$section" "$key")"
    if [[ -n "${!env_key+x}" ]]; then
        return 0
    fi

    store_key="$(_config_store_key "$section" "$key")"
    [[ -n "${CONFIG_VALUES[$store_key]+x}" ]]
}
