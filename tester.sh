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

    # 📝 Write expected output (as Shell would do)
    rm -f expected_output.txt
    < "$infile" $cmd1 | $cmd2 > expected_output.txt 2>/dev/null

    rm -f "$outfile"

    # 📌 Form the command for Pipex: with Valgrind or without
    local exec_cmd="$PIPEX_BIN"
    [ "$use_valgrind" == "valgrind" ] && exec_cmd="valgrind --leak-check=full --show-leak-kinds=all --errors-for-leak-kinds=all --error-exitcode=42 $PIPEX_BIN"

    # 🚀 Run pipex with or without Valgrind
    $exec_cmd "$infile" "$cmd1" "$cmd2" "$outfile" 2>/dev/null
    local status=$?

    # 📌 Check if `outfile` was created
    if [ ! -f "$outfile" ]; then
        echo "❌ FAIL: Pipex did NOT create $outfile for <$infile $cmd1 | $cmd2>"
        errors=$((errors + 1))
        return
    fi

    # 📌 Check `Valgrind` or `diff`
    if [ "$use_valgrind" == "valgrind" ]; then
        if [ "$status" -eq 42 ]; then
            echo "❌ FAIL (Valgrind): <$infile $cmd1 | $cmd2>"
            errors=$((errors + 1))
        else
            echo "✅ OK (Valgrind): <$infile $cmd1 | $cmd2>"
        fi
    else
        # 🚀 Normalize `\n` to make `diff` work correctly
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
    local use_valgrind=""

    # Check if the last argument is "valgrind", then enable Valgrind
    if [ "$outfile" == "valgrind" ]; then
        use_valgrind="valgrind"
        outfile="$5"
        cmd3="$4"
        cmd2="$3"
        cmd1="$2"
        infile="$1"
    fi

    # 🛠 Generate default infile if it doesn't exist
    if [ ! -f "$infile" ]; then
        printf "Hello\nWorld\nPipex\nTest\ntest1\ntest2\n" > "$infile"
    fi

    # 📝 Generate `expected_output.txt` via Shell
    rm -f expected_output.txt
    eval "< \"$infile\" $cmd1 | $cmd2 | $cmd3 > expected_output.txt 2>/dev/null"

    rm -f "$outfile"

    # 📌 Form the command for Pipex: with Valgrind or without
    local exec_cmd="$PIPEX_BIN"
    [ "$use_valgrind" == "valgrind" ] && exec_cmd="valgrind --leak-check=full --show-leak-kinds=all --errors-for-leak-kinds=all --error-exitcode=42 $PIPEX_BIN"

    # 🚀 Run pipex with or without Valgrind
    eval "$exec_cmd \"$infile\" \"$cmd1\" \"$cmd2\" \"$cmd3\" \"$outfile\"" 2>/dev/null
    local status=$?

    # 📌 Check if `outfile` was created
    if [ ! -f "$outfile" ]; then
        echo "❌ FAIL: Pipex did NOT create $outfile for <$infile $cmd1 | $cmd2 | $cmd3>"
        errors=$((errors + 1))
        return
    fi

    # 📌 Check `Valgrind` or `diff`
    if [ "$use_valgrind" == "valgrind" ]; then
        if [ "$status" -eq 42 ]; then
            echo "❌ FAIL (Valgrind - multi_cmd): <$infile $cmd1 | $cmd2 | $cmd3>"
            errors=$((errors + 1))
        else
            echo "✅ OK (Valgrind - multi_cmd): <$infile $cmd1 | $cmd2 | $cmd3>"
        fi
    else
        # 🚀 Normalize `\n` to make `diff` work correctly
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

    # 🛠 Generate expected_hd.txt with here_doc structure
    printf "hello\naaa\nbbb\n" > expected_hd.txt
    cat expected_hd.txt | $cmd1 | $cmd2 > expected_output.txt 2>/dev/null

    rm -f "$outfile"

    # 📌 Form the command for Pipex: with Valgrind or without
    local exec_cmd="$PIPEX_BIN"
    [ "$use_valgrind" == "valgrind" ] && exec_cmd="valgrind --leak-check=full --show-leak-kinds=all --errors-for-leak-kinds=all --error-exitcode=42 $PIPEX_BIN"

    # 🔥 Use `printf` to pass `here_doc` to pipex
    printf "hello\naaa\nbbb\n%s\n" "$limiter" | $exec_cmd here_doc "$limiter" "$cmd1" "$cmd2" "$outfile" 2>/dev/null
    local status=$?

    # 📌 Check if `outfile` was created
    if [ ! -f "$outfile" ]; then
        echo "❌ FAIL (here_doc): outfile was NOT created (limiter=\"$limiter\", cmds=\"$cmd1 $cmd2\")"
        errors=$((errors + 1))
        return
    fi

    # 📌 Check `Valgrind` or `diff`
    if [ "$use_valgrind" == "valgrind" ]; then
        if [ "$status" -eq 42 ]; then
            echo "❌ FAIL (Valgrind - here_doc): LIMITER=\"$limiter\""
            errors=$((errors + 1))
        else
            echo "✅ OK (Valgrind - here_doc): LIMITER=\"$limiter\""
        fi
    else
        # 🚀 Normalize `\n` to make `diff` work correctly
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

    # 🛠 Если infile не существует — создаём
    if [ ! -f "$infile" ]; then
        printf "Some input data\n" > "$infile"
    fi

    # 📝 Готовим ожидаемый вывод через Shell
    rm -f expected_output.txt
    ( < "$infile" $badcmd | $cmd2 ) > expected_output.txt 2> bad_error.txt

    rm -f "$outfile"

    # 📌 Если нужно Valgrind, составляем команду
    local exec_cmd="$PIPEX_BIN"
    if [ "$use_valgrind" = "valgrind" ]; then
        exec_cmd="valgrind --leak-check=full --show-leak-kinds=all \
                  --errors-for-leak-kinds=all --error-exitcode=42 \
                  $PIPEX_BIN"
    fi

    # 🚀 Запускаем pipex (под valgrind или нет), stderr => valgrind_log.txt
    $exec_cmd "$infile" "$badcmd" "$cmd2" "$outfile" 2> valgrind_log.txt
    local cmd_status=$?

    # Если мы в режиме Valgrind, парсим лог и получаем 4 числа:
    local still=0 def=0 ind=0 pos=0
    if [ "$use_valgrind" = "valgrind" ]; then
        read still def ind pos < <(check_valgrind_leaks valgrind_log.txt)
    fi

    # 📌 Проверяем, создался ли outfile
    if [ ! -f "$outfile" ]; then
        echo "✅ OK (badcmd): outfile NOT created for <$infile $badcmd | $cmd2>"
    else
        # Сравниваем с ожидаемым выводом
        sed -i -e '$a\' expected_output.txt
        sed -i -e '$a\' "$outfile"
        if diff expected_output.txt "$outfile" >/dev/null 2>&1; then
            echo "✅ OK (badcmd): matched shell behavior for <$infile $badcmd | $cmd2>"
        else
            echo "❌ FAIL (badcmd): differs from shell for <$infile $badcmd | $cmd2>"
            errors=$((errors + 1))
        fi
    fi

    # Если запущено под Valgrind — проверяем код возврата + утечки
    if [ "$use_valgrind" = "valgrind" ]; then
        # Проверка кода возврата (42 при ошибках Valgrind)
        if [ "$cmd_status" -eq 42 ]; then
            echo "❌ FAIL (Valgrind exit code): <$infile $badcmd | $cmd2>"
            errors=$((errors + 1))
        else
            echo "✅ OK (Valgrind exit code): <$infile $badcmd | $cmd2>"
        fi

        # Проверка утечек (если хоть один вид > 0 — считаем ошибкой)
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

check_fds() {
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
check_fds "infile1.txt" "cat" "wc -l" "outfile1.txt"
run_test "infile1.txt" "cat" "wc -l" "outfile1.txt" "valgrind"
echo -e "apple\nbanana\napple\ncherry\norange" > infile2.txt
run_test "infile2.txt" "grep apple" "wc -w" "outfile2.txt"
check_fds "infile2.txt" "grep apple" "wc -w" "outfile2.txt"
run_test "infile2.txt" "grep apple" "wc -w" "outfile2.txt" "valgrind"
echo -e "some content for ls\n" > infile3.txt
run_test "infile3.txt" "ls" "grep pipex" "outfile3.txt"
check_fds "infile3.txt" "ls" "grep pipex" "outfile3.txt"
run_test "infile3.txt" "ls" "grep pipex" "outfile3.txt" "valgrind"

echo ""
echo "🚀 [Phase 2] Testing multiple-command..."
echo ""
run_multi_test "infile.txt" "cat" "grep test" "uniq" "wc -l" "multi_out.txt"
check_fds "infile.txt" "cat" "grep test" "uniq" "wc -l" "multi_out.txt"
run_multi_test "infile.txt" "cat" "grep test" "uniq" "wc -l" "multi_out.txt" "valgrind"

echo ""
echo "🚀 [Phase 3] Testing empty infile..."
echo ""
touch empty_infile.txt
run_test "empty_infile.txt" "cat" "wc -l" "empty_out.txt"
check_fds "empty_infile.txt" "cat" "wc -l" "empty_out.txt"
run_test "empty_infile.txt" "cat" "wc -l" "empty_out.txt" "valgrind"

echo ""
echo "🚀 [Phase 4] Testing here_doc..."
echo ""
run_here_doc_test "END" "cat" "wc -l" "outfile_hd.txt"
# check_fds "here_doc" "END" "cat" "wc -l" "outfile_hd.txt"
run_here_doc_test "END" "cat" "wc -l" "outfile_hd.txt" "valgrind"

echo ""
echo "🚀 [Phase 5] Testing nonexistent command..."
echo ""
run_badcmd_test "infile_bad.txt" "blahblah_123" "wc -l" "out_bad.txt"
check_fds "infile_bad.txt" "blahblah_123" "wc -l" "out_bad.txt"
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
