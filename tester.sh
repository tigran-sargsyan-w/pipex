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

# Function to run basic tests (Valgrind - optional)
run_test() {
    local infile="$1"
    local cmd1="$2"
    local cmd2="$3"
    local outfile="$4"
    local use_valgrind="$5"

    # 🛠 Гарантируем, что infile существует
    if [ ! -f "$infile" ]; then
        # echo "Creating default $infile..."
        printf "Hello\nWorld\nPipex\nTest\n" > "$infile"
    fi

    # 📝 Записываем ожидаемый результат (как это сделал бы Shell)
    rm -f expected_output.txt
    < "$infile" $cmd1 | $cmd2 > expected_output.txt 2>/dev/null

    rm -f "$outfile"

    # 📌 Формируем команду для Pipex: с Valgrind или без
    local exec_cmd="$PIPEX_BIN"
    [ "$use_valgrind" == "valgrind" ] && exec_cmd="valgrind --leak-check=full --show-leak-kinds=all --errors-for-leak-kinds=all --error-exitcode=42 $PIPEX_BIN"

    # 🚀 Запускаем Pipex
    $exec_cmd "$infile" "$cmd1" "$cmd2" "$outfile" 2>/dev/null
    local status=$?

    # 📌 Проверяем, создался ли `outfile`
    if [ ! -f "$outfile" ]; then
        echo "❌ FAIL: Pipex did NOT create $outfile for <$infile $cmd1 | $cmd2>"
        errors=$((errors + 1))
        return
    fi

    # 📌 Проверяем `Valgrind` или `diff`
    if [ "$use_valgrind" == "valgrind" ]; then
        if [ "$status" -eq 42 ]; then
            echo "❌ FAIL (Valgrind): <$infile $cmd1 | $cmd2>"
            errors=$((errors + 1))
        else
            echo "✅ OK (Valgrind): <$infile $cmd1 | $cmd2>"
        fi
    else
        # 🚀 Нормализуем `\n`, чтобы `diff` работал корректно
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

    # Если последний аргумент "valgrind", то включаем Valgrind
    if [ "$outfile" == "valgrind" ]; then
        use_valgrind="valgrind"
        outfile="$5"
        cmd3="$4"
        cmd2="$3"
        cmd1="$2"
        infile="$1"
    fi

    # 🛠 Гарантируем, что `infile` существует
    if [ ! -f "$infile" ]; then
        # echo "Creating default $infile..."
        printf "Hello\nWorld\nPipex\nTest\ntest1\ntest2\n" > "$infile"
    fi

    # 📝 Генерируем `expected_output.txt` через Shell
    rm -f expected_output.txt
    eval "< \"$infile\" $cmd1 | $cmd2 | $cmd3 > expected_output.txt 2>/dev/null"

    rm -f "$outfile"

    # 📌 Формируем команду для Pipex: с Valgrind или без
    local exec_cmd="$PIPEX_BIN"
    [ "$use_valgrind" == "valgrind" ] && exec_cmd="valgrind --leak-check=full --show-leak-kinds=all --errors-for-leak-kinds=all --error-exitcode=42 $PIPEX_BIN"

    # 🚀 Запускаем Pipex
    eval "$exec_cmd \"$infile\" \"$cmd1\" \"$cmd2\" \"$cmd3\" \"$outfile\"" 2>/dev/null
    local status=$?

    # 📌 Проверяем, создался ли `outfile`
    if [ ! -f "$outfile" ]; then
        echo "❌ FAIL: Pipex did NOT create $outfile for <$infile $cmd1 | $cmd2 | $cmd3>"
        errors=$((errors + 1))
        return
    fi

    # 📌 Проверяем `Valgrind` или `diff`
    if [ "$use_valgrind" == "valgrind" ]; then
        if [ "$status" -eq 42 ]; then
            echo "❌ FAIL (Valgrind - multi_cmd): <$infile $cmd1 | $cmd2 | $cmd3>"
            errors=$((errors + 1))
        else
            echo "✅ OK (Valgrind - multi_cmd): <$infile $cmd1 | $cmd2 | $cmd3>"
        fi
    else
        # 🚀 Нормализуем `\n`, чтобы `diff` работал корректно
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

    # 🛠 Гарантируем, что `expected_hd.txt` имеет точную структуру `here_doc`
    printf "hello\naaa\nbbb\n" > expected_hd.txt
    cat expected_hd.txt | $cmd1 | $cmd2 > expected_output.txt 2>/dev/null

    rm -f "$outfile"

    # 📌 Формируем команду с Valgrind или без
    local exec_cmd="$PIPEX_BIN"
    [ "$use_valgrind" == "valgrind" ] && exec_cmd="valgrind --leak-check=full --show-leak-kinds=all --errors-for-leak-kinds=all --error-exitcode=42 $PIPEX_BIN"

    # 🔥 Используем `printf`, чтобы точно передать `here_doc` в pipex
    printf "hello\naaa\nbbb\n%s\n" "$limiter" | $exec_cmd here_doc "$limiter" "$cmd1" "$cmd2" "$outfile" 2>/dev/null
    local status=$?

    # 📌 Проверяем, создался ли `outfile`
    if [ ! -f "$outfile" ]; then
        echo "❌ FAIL (here_doc): outfile was NOT created (limiter=\"$limiter\", cmds=\"$cmd1 $cmd2\")"
        errors=$((errors + 1))
        return
    fi

    # 📌 Проверяем `Valgrind` или `diff`
    if [ "$use_valgrind" == "valgrind" ]; then
        if [ "$status" -eq 42 ]; then
            echo "❌ FAIL (Valgrind - here_doc): LIMITER=\"$limiter\""
            errors=$((errors + 1))
        else
            echo "✅ OK (Valgrind - here_doc): LIMITER=\"$limiter\""
        fi
    else
        # 🚀 Дополнительно нормализуем `\n`, чтобы `diff` работал корректно
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

    # 🛠 Гарантируем, что infile существует
    if [ ! -f "$infile" ]; then
        # echo "Creating default $infile..."
        printf "Some input data\n" > "$infile"
    fi

    # 📝 Подготавливаем ожидаемый результат (Shell)
    rm -f expected_output.txt
    ( < "$infile" $badcmd | $cmd2 ) > expected_output.txt 2> bad_error.txt

    rm -f "$outfile"

    # 📌 Формируем команду для Pipex: с Valgrind или без
    local exec_cmd="$PIPEX_BIN"
    [ "$use_valgrind" == "valgrind" ] && exec_cmd="valgrind --leak-check=full --show-leak-kinds=all --errors-for-leak-kinds=all --error-exitcode=42 $PIPEX_BIN"

    # 🚀 Запускаем Pipex
    $exec_cmd "$infile" "$badcmd" "$cmd2" "$outfile" 2>/dev/null
    local status=$?

    # 📌 Проверяем, создался ли `outfile`
    if [ ! -f "$outfile" ]; then
        echo "✅ OK (badcmd): outfile NOT created for <$infile $badcmd | $cmd2>"
        return
    fi

    # 📌 Проверяем `Valgrind` или `diff`
    if [ "$use_valgrind" == "valgrind" ]; then
        if [ "$status" -eq 42 ]; then
            echo "❌ FAIL (Valgrind): <$infile $badcmd | $cmd2>"
            errors=$((errors + 1))
        else
            echo "✅ OK (Valgrind): <$infile $badcmd | $cmd2>"
        fi
    else
        # 🚀 Нормализуем `\n`, чтобы `diff` работал корректно
        sed -i -e '$a\' expected_output.txt
        sed -i -e '$a\' "$outfile"

        if diff expected_output.txt "$outfile" >/dev/null 2>&1; then
            echo "✅ OK (badcmd): matched shell behavior for <$infile $badcmd | $cmd2>"
        else
            echo "❌ FAIL (badcmd): differs from shell for <$infile $badcmd | $cmd2>"
            echo "--- Expected Output (hexdump) ---"
            hexdump -C expected_output.txt
            echo "--- Pipex Output (hexdump) ---"
            hexdump -C "$outfile"
            errors=$((errors + 1))
        fi
    fi
}

# All tests
echo "🚀 [Phase 1] Testing two-command ..."
echo ""
echo -e "Hello\nWorld\nPipex\nTest\ntest1\ntest2" > infile1.txt
run_test "infile1.txt" "cat" "wc -l" "outfile1.txt"
run_test "infile1.txt" "cat" "wc -l" "outfile1.txt" "valgrind"
echo -e "apple\nbanana\napple\ncherry\norange" > infile2.txt
run_test "infile2.txt" "grep apple" "wc -w" "outfile2.txt"
run_test "infile2.txt" "grep apple" "wc -w" "outfile2.txt" "valgrind"
echo -e "some content for ls\n" > infile3.txt
run_test "infile3.txt" "ls" "grep pipex" "outfile3.txt"
run_test "infile3.txt" "ls" "grep pipex" "outfile3.txt" "valgrind"

echo ""
echo "🚀 [Phase 2] Testing multiple-command..."
echo ""
run_multi_test "infile.txt" "cat" "grep test" "uniq" "wc -l" "multi_out.txt"
run_multi_test "infile.txt" "cat" "grep test" "uniq" "wc -l" "multi_out.txt" "valgrind"

echo ""
echo "🚀 [Phase 3] Testing empty infile..."
echo ""
touch empty_infile.txt
run_test "empty_infile.txt" "cat" "wc -l" "empty_out.txt"
run_test "empty_infile.txt" "cat" "wc -l" "empty_out.txt" "valgrind"

echo ""
echo "🚀 [Phase 4] Testing here_doc..."
echo ""
run_here_doc_test "END" "cat" "wc -l" "outfile_hd.txt"
run_here_doc_test "END" "cat" "wc -l" "outfile_hd.txt" "valgrind"

echo ""
echo "🚀 [Phase 5] Testing nonexistent command..."
echo ""
run_badcmd_test "infile_bad.txt" "blahblah_123" "wc -l" "out_bad.txt"
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
