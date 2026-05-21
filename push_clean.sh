#!/usr/bin/env bash
# push_clean.sh
# Runs git push and clean.sh in parallel, showing all output until both complete

set -euo pipefail

PROJECT_ROOT="$(pwd)"
CLEAN_SCRIPT="${PROJECT_ROOT}/project_files/clean.sh"

echo "==================================================================="
echo "Starting parallel execution: git push & project_files/clean.sh"
echo "==================================================================="

# Function to run git push with labeled output
run_git_push() {
    echo ""
    echo "--- GIT PUSH STARTING ---"
    if git push; then
        echo "--- GIT PUSH COMPLETED SUCCESSFULLY ---"
        return 0
    else
        echo "--- GIT PUSH FAILED ---"
        return 1
    fi
}

# Function to run clean.sh with labeled output
run_clean() {
    echo ""
    echo "--- PROJECT_FILES/CLEAN.SH STARTING ---"
    if bash "${CLEAN_SCRIPT}"; then
        echo "--- PROJECT_FILES/CLEAN.SH COMPLETED SUCCESSFULLY ---"
        return 0
    else
        echo "--- PROJECT_FILES/CLEAN.SH FAILED ---"
        return 1
    fi
}

# Export functions so they can be run in subshells
export -f run_git_push
export -f run_clean
export CLEAN_SCRIPT

# Run both commands in parallel and capture their PIDs
run_git_push &
PID_PUSH=$!

run_clean &
PID_CLEAN=$!

# Wait for both processes and capture their exit codes
wait $PID_PUSH
EXIT_PUSH=$?

wait $PID_CLEAN
EXIT_CLEAN=$?

echo ""
echo "==================================================================="
echo "Execution Summary:"
echo "  git push: $([ $EXIT_PUSH -eq 0 ] && echo "SUCCESS" || echo "FAILED (exit code: $EXIT_PUSH)")"
echo "  clean.sh: $([ $EXIT_CLEAN -eq 0 ] && echo "SUCCESS" || echo "FAILED (exit code: $EXIT_CLEAN)")"
echo "==================================================================="

# Exit with error if either command failed
if [ $EXIT_PUSH -ne 0 ] || [ $EXIT_CLEAN -ne 0 ]; then
    exit 1
fi

echo "All tasks completed successfully!"
exit 0
