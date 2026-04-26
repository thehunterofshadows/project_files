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
# ─────────────────────────────────────────────────────────────────────────────

# ── ANSI ──────────────────────────────────────────────────────────────────────
_R='\e[31m' _G='\e[32m' _C='\e[36m'
_B='\e[1m'  _D='\e[2m'  _NC='\e[0m'

# Cursor control codes
_CUP='\e[H'     # move cursor to top-left (row 1, col 1)
_EL='\e[2K'     # erase entire current line
_SC='\e[s'      # save cursor position
_RC='\e[u'      # restore cursor position
_HIDE='\e[?25l' # hide cursor
_SHOW='\e[?25h' # show cursor

# ── State ─────────────────────────────────────────────────────────────────────
_VR_NAMES=()
_VR_ICONS=()
_VR_STATUS=()
_VR_ERRORS=()
_VR_CUR=0
_VR_W=80
_VR_HEADER_LINES=7  # lines consumed by the header block

# ── vr_init "emoji:Name" ... ──────────────────────────────────────────────────
# Call once before any vr_step. Reserves header space at the top of the screen.
vr_init() {
    _VR_NAMES=(); _VR_ICONS=(); _VR_STATUS=(); _VR_ERRORS=(); _VR_CUR=0
    _VR_W=$(tput cols 2>/dev/null || echo 80)
    for entry in "$@"; do
        _VR_ICONS+=("${entry%%:*}")
        _VR_NAMES+=("${entry#*:}")
        _VR_STATUS+=(pending)
    done

    # Print blank lines to push the terminal scroll region down,
    # giving the header room to live without overlapping output.
    printf "${_HIDE}"
    printf '\n%.0s' $(seq 1 $(( _VR_HEADER_LINES + 1 )))
    _vr_draw_header
}

# ── _vr_draw_header ───────────────────────────────────────────────────────────
# Jumps to row 1, redraws the entire header, then restores the cursor
# back to wherever it was so output continues scrolling below.
_vr_draw_header() {
    local total=${#_VR_NAMES[@]}
    local done_n=0
    for s in "${_VR_STATUS[@]}"; do [[ "$s" == ok ]] && ((done_n++)) || true; done

    printf "${_SC}"   # save current (output) cursor
    printf "${_CUP}"  # jump to top-left

    # Title
    printf "${_EL}  ${_B}${_C}⬡  DEPLOY RUNNER${_NC}\n"
    printf "${_EL}\n"

    # Step dots:  ● done  ◉ running  ○ pending  ✗ failed
    printf "${_EL}  "
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
    printf "\n"
    printf "${_EL}\n"

    # Progress bar
    local bar_w=28
    local filled=$(( done_n * bar_w / total ))
    local empty=$(( bar_w - filled ))
    printf "${_EL}  ${_D}[${_NC}"
    [[ $filled -gt 0 ]] && printf "${_G}%0.s█${_NC}" $(seq 1 $filled)
    [[ $empty  -gt 0 ]] && printf "${_D}%0.s░${_NC}" $(seq 1 $empty)
    printf "${_D}]${_NC}  ${_D}step ${_VR_CUR} of ${total}${_NC}\n"

    # Divider
    printf "${_EL}${_D}"
    printf '%*s' "$_VR_W" '' | tr ' ' '─'
    printf "${_NC}\n"

    printf "${_RC}"   # restore cursor back to output area
}

# ── vr_step "Name" cmd [args...] ──────────────────────────────────────────────
# Runs a command, streams its output indented below the sticky header.
vr_step() {
    local name="$1"; shift
    local total=${#_VR_NAMES[@]}
    _VR_STATUS[$_VR_CUR]="running"
    _vr_draw_header

    printf "\n  ${_C}${_B}▶ $((_VR_CUR+1))/${total}  —  ${name}${_NC}\n\n"

    local rc=0
    set +e
    "$@" 2>&1 | while IFS= read -r line; do
        printf "  ${_D}│${_NC}  %s\n" "$line"
        _vr_draw_header   # re-pin header after every output line
    done
    rc=${PIPESTATUS[0]}
    set -e

    printf "\n"
    if [[ $rc -eq 0 ]]; then
        _VR_STATUS[$_VR_CUR]="ok"
        printf "  ${_G}✓${_NC}  ${_B}${name}${_NC} ${_G}— done${_NC}\n\n"
    else
        _VR_STATUS[$_VR_CUR]="fail"
        _VR_ERRORS+=("  $((_VR_CUR+1)). ${name}  (exit ${rc})")
        printf "  ${_R}✗${_NC}  ${_B}${name}${_NC} ${_R}— failed  (exit ${rc})${_NC}\n\n"
    fi

    _vr_draw_header
    ((_VR_CUR++)) || true
    return $rc
}

# ── vr_summary ────────────────────────────────────────────────────────────────
# Print the final pass/fail board. Attach via: trap 'vr_summary' EXIT
vr_summary() {
    printf "${_SHOW}"  # always restore cursor visibility on exit
    _vr_draw_header
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
