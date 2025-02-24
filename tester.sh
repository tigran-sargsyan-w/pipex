#!/bin/bash

errors=0  # Error counter
PIPEX_BIN="$(pwd)/pipex"  # Path to the pipex binary

# Check if the pipex binary exists
if [ ! -f "$PIPEX_BIN" ]; then
    echo "❌ Error: pipex binary not found! Please compile your project first."
    exit 1
fi

# Check if pipex is an executable file
if [ ! -x "$PIPEX_BIN" ]; then
    echo "❌ Error: pipex binary is not executable! Attempting to set executable permission..."
    chmod +x "$PIPEX_BIN"
fi

# Create a temporary directory for tests and navigate into it
TEST_DIR="pipex_test_dir"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Function to check Valgrind memory leaks
check_valgrind_leaks() {
    local log_file="$1"

    local still def ind pos
    still=$(grep "still reachable:"   "$log_file" | sed -E 's/.* ([0-9]+) bytes in.*/\1/')
    def=$(grep "definitely lost:"     "$log_file" | sed -E 's/.* ([0-9]+) bytes in.*/\1/')
    ind=$(grep "indirectly lost:"     "$log_file" | sed -E 's/.* ([0-9]+) bytes in.*/\1/')
    pos=$(grep "possibly lost:"       "$log_file" | sed -E 's/.* ([0-9]+) bytes in.*/\1/')

    still=${still:-0}
    def=${def:-0}
    ind=${ind:-0}
    pos=${pos:-0}

    echo "$still $def $ind $pos"
}

# Function to run basic tests (Valgrind - optional)
run_test() {
    local infile="$1"
    local cmd1="$2"
    local cmd2="$3"
    local outfile="$4"
    local use_valgrind="$5"

    # 🛠 Generate default infile if it doesn't exist
    if [ ! -f "$infile" ]; then
        printf "Hello\nWorld\nPipex\nTest\n" > "$infile"
    fi

    # Form expected_output.txt through Shell
    rm -f expected_output.txt
    < "$infile" $cmd1 | $cmd2 > expected_output.txt 2>/dev/null

    rm -f "$outfile"

    # Form the command to run (with or without Valgrind)
    local exec_cmd="$PIPEX_BIN"
    if [ "$use_valgrind" = "valgrind" ]; then
        exec_cmd="valgrind --leak-check=full --show-leak-kinds=all \
                  --errors-for-leak-kinds=all --error-exitcode=42 \
                  $PIPEX_BIN"
    fi

    # Run pipex (with Valgrind or without), write stderr to valgrind_log.txt
    $exec_cmd "$infile" "$cmd1" "$cmd2" "$outfile" 2> valgrind_log.txt
    local cmd_status=$?

    # Check if the outfile was created
    if [ ! -f "$outfile" ]; then
        echo "❌ FAIL: Pipex did NOT create $outfile for <$infile $cmd1 | $cmd2>"
        errors=$((errors + 1))
        return
    fi

    # If Valgrind is used, analyze logs and check the return code
    if [ "$use_valgrind" = "valgrind" ]; then
        local still=0 def=0 ind=0 pos=0
        read still def ind pos < <(check_valgrind_leaks valgrind_log.txt)

        if [ "$cmd_status" -eq 42 ]; then
            echo "❌ FAIL (Valgrind exit code): <$infile $cmd1 | $cmd2>"
            errors=$((errors + 1))
        else
            echo "✅ OK (Valgrind exit code): <$infile $cmd1 | $cmd2>"
        fi

        if (( def > 0 || ind > 0 || pos > 0 || still > 0 )); then
            echo "❌ FAIL (Valgrind memory check): <$infile $cmd1 | $cmd2>"
            echo "Valgrind summary:"
            echo "  definitely lost: $def bytes"
            echo "  indirectly lost: $ind bytes"
            echo "  possibly lost:   $pos bytes"
            echo "  still reachable: $still bytes"
            errors=$((errors + 1))
        else
            echo "✅ OK (Valgrind memory check): no memory issues"
        fi

    else
        # If Valgrind is not used, just do a regular diff
        sed -i -e '$a\' expected_output.txt
        sed -i -e '$a\' "$outfile"

        if diff expected_output.txt "$outfile" >/dev/null 2>&1; then
            echo "✅ OK: <$infile $cmd1 | $cmd2> -> $outfile"
        else
            echo "❌ FAIL: <$infile $cmd1 | $cmd2> -> $outfile"
            echo "--- Expected Output (hexdump) ---"
            hexdump -C expected_output.txt
            echo "--- Pipex Output (hexdump) ---"
            hexdump -C "$outfile"
            errors=$((errors + 1))
        fi
    fi
}

# Function to run multiple-command tests (Valgrind - optional)
run_multi_test() {
    local infile="$1"
    local cmd1="$2"
    local cmd2="$3"
    local cmd3="$4"
    local outfile="$5"
    local use_valgrind="$6"

    # If the last argument is "valgrind", switch to it
    if [ "$outfile" == "valgrind" ]; then
        use_valgrind="valgrind"
        outfile="$5"
        cmd3="$4"
        cmd2="$3"
        cmd1="$2"
        infile="$1"
    fi

    # Generate default infile if it doesn't exist
    if [ ! -f "$infile" ]; then
        printf "Hello\nWorld\nPipex\nTest\ntest1\ntest2\n" > "$infile"
    fi

    # Create expected_output.txt through Shell
    rm -f expected_output.txt
    eval "< \"$infile\" $cmd1 | $cmd2 | $cmd3 > expected_output.txt 2>/dev/null"

    rm -f "$outfile"

    # Form the command to run (with or without Valgrind)
    local exec_cmd="$PIPEX_BIN"
    if [ "$use_valgrind" == "valgrind" ]; then
        exec_cmd="valgrind --leak-check=full --show-leak-kinds=all \
                  --errors-for-leak-kinds=all --error-exitcode=42 \
                  $PIPEX_BIN"
    fi

    # Run pipex (with Valgrind or without), write stderr to valgrind_log.txt
    eval "$exec_cmd \"$infile\" \"$cmd1\" \"$cmd2\" \"$cmd3\" \"$outfile\"" 2> valgrind_log.txt
    local cmd_status=$?

    # Check if the outfile was created
    if [ ! -f "$outfile" ]; then
        echo "❌ FAIL: Pipex did NOT create $outfile for <$infile $cmd1 | $cmd2 | $cmd3>"
        errors=$((errors + 1))
        return
    fi

    # If Valgrind is used, analyze logs and check the return code
    if [ "$use_valgrind" == "valgrind" ]; then
        local still def ind pos
        read still def ind pos < <(check_valgrind_leaks valgrind_log.txt)

        if [ "$cmd_status" -eq 42 ]; then
            echo "❌ FAIL (Valgrind - multi_cmd): <$infile $cmd1 | $cmd2 | $cmd3>"
            errors=$((errors + 1))
        else
            echo "✅ OK (Valgrind - multi_cmd): <$infile $cmd1 | $cmd2 | $cmd3>"
        fi

        if (( def > 0 || ind > 0 || pos > 0 || still > 0 )); then
            echo "❌ FAIL (Valgrind memory check - multi_cmd): <$infile $cmd1 | $cmd2 | $cmd3>"
            echo "Valgrind summary:"
            echo "  definitely lost: $def bytes"
            echo "  indirectly lost: $ind bytes"
            echo "  possibly lost:   $pos bytes"
            echo "  still reachable: $still bytes"
            errors=$((errors + 1))
        fi
    else
        sed -i -e '$a\' expected_output.txt
        sed -i -e '$a\' "$outfile"

        if diff expected_output.txt "$outfile" >/dev/null 2>&1; then
            echo "✅ OK: <$infile $cmd1 | $cmd2 | $cmd3> -> $outfile"
        else
            echo "❌ FAIL: <$infile $cmd1 | $cmd2 | $cmd3> -> $outfile"
            echo "--- Expected Output (hexdump) ---"
            hexdump -C expected_output.txt
            echo "--- Pipex Output (hexdump) ---"
            hexdump -C "$outfile"
            errors=$((errors + 1))
        fi
    fi
}

# Function to run here_doc tests (Valgrind - optional)
run_here_doc_test() {
    local limiter="$1"
    local cmd1="$2"
    local cmd2="$3"
    local outfile="$4"
    local use_valgrind="$5"

    # Generate expected_output.txt through Shell
    printf "hello\naaa\nbbb\n" > expected_hd.txt
    cat expected_hd.txt | $cmd1 | $cmd2 > expected_output.txt 2>/dev/null

    rm -f "$outfile"

    # Run pipex (with Valgrind or without), write stderr to valgrind_log.txt
    local cmd_status=0
    if [ "$use_valgrind" == "valgrind" ]; then
        printf "hello\naaa\nbbb\n%s\n" "$limiter" \
        | valgrind --leak-check=full --show-leak-kinds=all \
                   --errors-for-leak-kinds=all --error-exitcode=42 -s \
                   "$PIPEX_BIN" here_doc "$limiter" "$cmd1" "$cmd2" "$outfile" \
                   2> valgrind_log.txt
        cmd_status=$?

        read still def ind pos < <(check_valgrind_leaks valgrind_log.txt)
    else
        printf "hello\naaa\nbbb\n%s\n" "$limiter" \
        | "$PIPEX_BIN" here_doc "$limiter" "$cmd1" "$cmd2" "$outfile" 2>/dev/null
        cmd_status=$?
    fi

    # Check if the outfile was created
    if [ ! -f "$outfile" ]; then
        echo "❌ FAIL (here_doc): outfile was NOT created (limiter=\"$limiter\", cmds=\"$cmd1 $cmd2\")"
        errors=$((errors + 1))
        return
    fi

    # If Valgrind is used, analyze logs and check the return code
    if [ "$use_valgrind" == "valgrind" ]; then
        if [ "$cmd_status" -eq 42 ]; then
            echo "❌ FAIL (Valgrind - here_doc): LIMITER=\"$limiter\" (error-exitcode=42)"
            errors=$((errors + 1))
        else
            if (( def > 0 || ind > 0 || pos > 0 || still > 0 )); then
                echo "❌ FAIL (Valgrind - memory issues): LIMITER=\"$limiter\""
                echo "Valgrind summary:"
                echo "  definitely lost: $def bytes"
                echo "  indirectly lost: $ind bytes"
                echo "  possibly lost:   $pos bytes"
                echo "  still reachable: $still bytes"
                errors=$((errors + 1))
            else
                echo "✅ OK (Valgrind - here_doc): LIMITER=\"$limiter\""
            fi
        fi

    else
        # If Valgrind is not used, just do a regular diff
        sed -i -e '$a\' expected_output.txt
        sed -i -e '$a\' "$outfile"

        if diff expected_output.txt "$outfile" >/dev/null 2>&1; then
            echo "✅ OK (here_doc): LIMITER=\"$limiter\""
        else
            echo "❌ FAIL (here_doc): LIMITER=\"$limiter\""
            echo "--- Expected Output (hexdump) ---"
            hexdump -C expected_output.txt
            echo "--- Pipex Output (hexdump) ---"
            hexdump -C "$outfile"
            errors=$((errors + 1))
        fi
    fi
}

# Function to run nonexistent tests (Valgrind - optional)
run_badcmd_test() {
    local infile="$1"
    local badcmd="$2"
    local cmd2="$3"
    local outfile="$4"
    local use_valgrind="$5"

    # Generate default infile if it doesn't exist
    if [ ! -f "$infile" ]; then
        printf "Some input data\n" > "$infile"
    fi

    # Create expected_output.txt through Shell
    rm -f expected_output.txt
    ( < "$infile" $badcmd | $cmd2 ) > expected_output.txt 2> bad_error.txt

    rm -f "$outfile"

    # If Valgrind is needed, form the command
    local exec_cmd="$PIPEX_BIN"
    if [ "$use_valgrind" = "valgrind" ]; then
        exec_cmd="valgrind --leak-check=full --show-leak-kinds=all \
                  --errors-for-leak-kinds=all --error-exitcode=42 \
                  $PIPEX_BIN"
    fi

    # Run pipex (with Valgrind or without), write stderr to valgrind_log.txt
    $exec_cmd "$infile" "$badcmd" "$cmd2" "$outfile" 2> valgrind_log.txt
    local cmd_status=$?

    local still=0 def=0 ind=0 pos=0
    if [ "$use_valgrind" = "valgrind" ]; then
        read still def ind pos < <(check_valgrind_leaks valgrind_log.txt)
    fi

    # Check if the outfile was created
    if [ ! -f "$outfile" ]; then
        echo "✅ OK (badcmd): outfile NOT created for <$infile $badcmd | $cmd2>"
    else
        sed -i -e '$a\' expected_output.txt
        sed -i -e '$a\' "$outfile"
        if diff expected_output.txt "$outfile" >/dev/null 2>&1; then
            echo "✅ OK (badcmd): matched shell behavior for <$infile $badcmd | $cmd2>"
        else
            echo "❌ FAIL (badcmd): differs from shell for <$infile $badcmd | $cmd2>"
            errors=$((errors + 1))
        fi
    fi

    # If Valgrind is used, check the return code and memory leaks
    if [ "$use_valgrind" = "valgrind" ]; then
        if [ "$cmd_status" -eq 42 ]; then
            echo "❌ FAIL (Valgrind exit code): <$infile $badcmd | $cmd2>"
            errors=$((errors + 1))
        else
            echo "✅ OK (Valgrind exit code): <$infile $badcmd | $cmd2>"
        fi

        if (( def > 0 || ind > 0 || pos > 0 || still > 0 )); then
            echo "❌ FAIL (Valgrind memory check): <$infile $badcmd | $cmd2>"
            echo "Valgrind summary:"
            echo "  definitely lost: $def bytes"
            echo "  indirectly lost: $ind bytes"
            echo "  possibly lost:   $pos bytes"
            echo "  still reachable: $still bytes"
            errors=$((errors + 1))
        else
            echo "✅ OK (Valgrind memory check): no memory issues"
        fi
    fi
}

# Function to check file descriptors
run_check_fds_test() {
    valgrind --track-fds=yes --trace-children=yes -s \
        "$PIPEX_BIN" "$@" > /dev/null 2> valgrind_log.txt

    local leak_lines
    leak_lines=$(grep -A 10 "Open file descriptor" valgrind_log.txt | \
        grep -v "<inherited from parent>" | \
        grep -v "vscode" | \
        grep -v -E "(HEAP SUMMARY|LEAK SUMMARY|ERROR SUMMARY|All heap|suppressed:|in use at exit|total heap usage:|^--$|lost:|bytes in )" | \
        sed '/^==[0-9]\+== *$/d' | \
        sed '/^==[0-9]\+== Open file descriptor [0-9]\+:$/d')

    if [ -n "$leak_lines" ]; then
        echo "❌ FAIL: Find unclosed file descriptors!"
        echo "$leak_lines"
        errors=$((errors + 1))
    else
        echo "✅ OK: All file descriptors are closed or inherited from parent"
    fi
}

# All tests
echo ""
echo "🚀 [Phase 1] Testing two-command ..."
echo ""
echo -e "Hello\nWorld\nPipex\nTest\ntest1\ntest2" > infile1.txt
run_test "infile1.txt" "cat" "wc -l" "outfile1.txt"
run_check_fds_test "infile1.txt" "cat" "wc -l" "outfile1.txt"
run_test "infile1.txt" "cat" "wc -l" "outfile1.txt" "valgrind"
echo -e "apple\nbanana\napple\ncherry\norange" > infile2.txt
run_test "infile2.txt" "grep apple" "wc -w" "outfile2.txt"
run_check_fds_test "infile2.txt" "grep apple" "wc -w" "outfile2.txt"
run_test "infile2.txt" "grep apple" "wc -w" "outfile2.txt" "valgrind"
echo -e "some content for ls\n" > infile3.txt
run_test "infile3.txt" "ls" "grep pipex" "outfile3.txt"
run_check_fds_test "infile3.txt" "ls" "grep pipex" "outfile3.txt"
run_test "infile3.txt" "ls" "grep pipex" "outfile3.txt" "valgrind"

echo ""
echo "🚀 [Phase 2] Testing multiple-command..."
echo ""
run_multi_test "infile.txt" "cat" "uniq" "wc -l" "multi_out.txt"
run_check_fds_test "infile.txt" "cat" "uniq" "wc -l" "multi_out.txt"
run_multi_test "infile.txt" "cat" "uniq" "wc -l" "multi_out.txt" "valgrind"

echo ""
echo "🚀 [Phase 3] Testing empty infile..."
echo ""
touch empty_infile.txt
run_test "empty_infile.txt" "cat" "wc -l" "empty_out.txt"
run_check_fds_test "empty_infile.txt" "cat" "wc -l" "empty_out.txt"
run_test "empty_infile.txt" "cat" "wc -l" "empty_out.txt" "valgrind"

echo ""
echo "🚀 [Phase 4] Testing here_doc..."
echo ""
run_here_doc_test "END" "cat" "wc -l" "outfile_hd.txt"
# run_check_fds_test "here_doc" "END" "cat" "wc -l" "outfile_hd.txt"
run_here_doc_test "END" "cat" "wc -l" "outfile_hd.txt" "valgrind"

echo ""
echo "🚀 [Phase 5] Testing nonexistent command..."
echo ""
run_badcmd_test "infile_bad.txt" "blahblah_123" "wc -l" "out_bad.txt"
run_check_fds_test "infile_bad.txt" "blahblah_123" "wc -l" "out_bad.txt"
run_badcmd_test "infile_bad.txt" "blahblah_123" "wc -l" "out_bad.txt" "valgrind"

echo ""
if [ "$errors" -gt 0 ]; then
    echo "⚠️  Completed with $errors errors."
else
    echo "🎉 All tests passed successfully!"
fi

# Delete all temporary files
cd ..
rm -rf "$TEST_DIR"
