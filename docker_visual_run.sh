#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# docker_visual_run.sh — Reusable visual step runner  (source this file)
#
# Usage:
#   source ./docker_visual_run.sh
#   vr_init "🔄:Step One" "🏗️:Step Two" "🧪:Step Three"
#   trap 'vr_summary' EXIT
#   vr_step "Step One"  your_command --args
#   vr_step "Step Two"  another_command
#   vr_summary
# ─────────────────────────────────────────────────────────────────────────────

# ── ANSI ──────────────────────────────────────────────────────────────────────
_R='\e[31m' _G='\e[32m' _Y='\e[33m' _C='\e[36m'
_B='\e[1m'  _D='\e[2m'  _NC='\e[0m'

# ── State ─────────────────────────────────────────────────────────────────────
_VR_NAMES=()    # display names
_VR_ICONS=()    # emoji icons
_VR_STATUS=()   # pending | running | ok | fail
_VR_ERRORS=()   # collected error messages
_VR_CUR=0       # 0-indexed current step index
_VR_W=80        # terminal width

# ── vr_init "emoji:Name" "emoji:Name" ... ────────────────────────────────────
# Register all steps at the start so the progress bar knows the total.
vr_init() {
    _VR_NAMES=(); _VR_ICONS=(); _VR_STATUS=(); _VR_ERRORS=(); _VR_CUR=0
    _VR_W=$(tput cols 2>/dev/null || echo 80)
    for entry in "$@"; do
        _VR_ICONS+=("${entry%%:*}")
        _VR_NAMES+=("${entry#*:}")
        _VR_STATUS+=(pending)
    done
}

# ── Internal: render the header ───────────────────────────────────────────────
_vr_header() {
    local total=${#_VR_NAMES[@]}
    local done_n=0
    for s in "${_VR_STATUS[@]}"; do [[ "$s" == ok ]] && ((done_n++)) || true; done

    echo ""
    printf "  ${_B}${_C}⬡  DEPLOY RUNNER${_NC}\n\n"

    # Step status dots  ●  ◉  ○  ✗
    printf "  "
    for ((i=0; i<total; i++)); do
        local name="${_VR_NAMES[$i]}"
        case "${_VR_STATUS[$i]}" in
            ok)      printf "${_G}● ${name}${_NC}" ;;
            running) printf "${_C}${_B}◉ ${name}${_NC}" ;;
            fail)    printf "${_R}✗ ${name}${_NC}" ;;
            pending) printf "${_D}○ ${name}${_NC}" ;;
        esac
        [[ $((i+1)) -lt $total ]] && printf "${_D}  ──  ${_NC}"
    done
    printf "\n\n"

    # Progress bar
    local bar_w=28
    local filled=$(( done_n * bar_w / total ))
    local empty=$(( bar_w - filled ))
    printf "  ${_D}[${_NC}"
    [[ $filled -gt 0 ]] && printf "${_G}%0.s█${_NC}" $(seq 1 $filled)
    [[ $empty  -gt 0 ]] && printf "${_D}%0.s░${_NC}" $(seq 1 $empty)
    printf "${_D}]${_NC}  ${_D}step ${_VR_CUR} of ${total}${_NC}\n"

    # Divider
    printf "${_D}"
    printf '%*s' "$_VR_W" '' | tr ' ' '─'
    printf "${_NC}\n"
}

# ── vr_step "Display Name" cmd [args...] ─────────────────────────────────────
# Runs the command, streams output with indentation, marks pass/fail.
vr_step() {
    local name="$1"; shift
    local total=${#_VR_NAMES[@]}
    _VR_STATUS[$_VR_CUR]="running"

    _vr_header
    printf "\n  ${_C}${_B}▶ $((_VR_CUR+1))/${total}  —  ${name}${_NC}\n\n"

    local rc=0
    set +e
    "$@" 2>&1 | while IFS= read -r line; do
        printf "  ${_D}│${_NC}  %s\n" "$line"
    done
    rc=${PIPESTATUS[0]}
    set -e

    printf "\n"
    if [[ $rc -eq 0 ]]; then
        _VR_STATUS[$_VR_CUR]="ok"
        printf "  ${_G}✓${_NC}  ${_B}${name}${_NC} ${_G}— done${_NC}\n"
    else
        _VR_STATUS[$_VR_CUR]="fail"
        _VR_ERRORS+=("  $((_VR_CUR+1)). ${name}  (exit ${rc})")
        printf "  ${_R}✗${_NC}  ${_B}${name}${_NC} ${_R}— failed  (exit ${rc})${_NC}\n"
    fi

    printf "\n${_D}"
    printf '%*s' "$_VR_W" '' | tr ' ' '─'
    printf "${_NC}\n\n"

    ((_VR_CUR++)) || true
    return $rc
}

# ── vr_summary ────────────────────────────────────────────────────────────────
# Print the final status board.  Call via `trap 'vr_summary' EXIT` for safety.
vr_summary() {
    _vr_header
    printf "\n"
    if [[ ${#_VR_ERRORS[@]} -eq 0 ]]; then
        printf "  ${_G}${_B}✓  All steps completed successfully.${_NC}\n\n"
    else
        printf "  ${_R}${_B}✗  Completed with ${#_VR_ERRORS[@]} error(s):${_NC}\n\n"
        for e in "${_VR_ERRORS[@]}"; do
            printf "    ${_R}•${_NC}  %s\n" "$e"
        done
        printf "\n"
        exit 1
    fi
}
