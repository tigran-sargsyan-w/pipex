#!/bin/bash

errors=0  # Счётчик ошибок
PIPEX_BIN="$(pwd)/pipex"  # Полный путь к pipex

# 1) Проверяем, существует ли pipex
if [ ! -f "$PIPEX_BIN" ]; then
    echo "❌ Error: pipex binary not found! Please compile your project first."
    exit 1
fi

# 2) Проверяем, что pipex исполняемый
if [ ! -x "$PIPEX_BIN" ]; then
    chmod +x "$PIPEX_BIN"
fi

# Создадим директорию для временных файлов
TEST_DIR="pipex_test_dir"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "======================================"
echo "🚀 PIPEX ADVANCED TESTER + BAD COMMAND"
echo "======================================"

########################
# ФУНКЦИЯ: run_test (две команды)
########################
# Сравнивает < infile cmd1 | cmd2 > expected.txt с тем, что даёт ./pipex infile cmd1 cmd2 outfile
run_test() {
    local infile="$1"
    local cmd1="$2"
    local cmd2="$3"
    local outfile="$4"

    # Если infile не существует, создаём
    if [ ! -f "$infile" ]; then
        echo "Creating default $infile..."
        echo -e "Hello\nWorld\nPipex\nTest" > "$infile"
    fi

    # Ожидаемый результат
    rm -f expected.txt
    < "$infile" $cmd1 | $cmd2 > expected.txt 2>/dev/null

    # Запускаем pipex
    rm -f "$outfile"
    "$PIPEX_BIN" "$infile" "$cmd1" "$cmd2" "$outfile" 2>/dev/null

    # Проверяем существование outfile
    if [ ! -f "$outfile" ]; then
        echo "❌ FAIL: Pipex did not create $outfile for <$infile $cmd1 | $cmd2>"
        errors=$((errors + 1))
        return
    fi

    # Сравниваем
    if diff expected.txt "$outfile" >/dev/null 2>&1; then
        echo "✅ OK: <$infile $cmd1 | $cmd2> -> $outfile"
    else
        echo "❌ FAIL: <$infile $cmd1 | $cmd2> -> $outfile"
        echo "--- Expected ---"
        cat expected.txt
        echo "--- Got ---"
        cat "$outfile"
        errors=$((errors + 1))
    fi
}

########################
# ФУНКЦИЯ: run_here_doc_test
########################
# Автоматическая проверка here_doc (не требует ввода вручную)
run_here_doc_test() {
    local limiter="$1"
    local cmd1="$2"
    local cmd2="$3"
    local outfile="$4"

    # Подготавливаем ожидаемый результат (имитируем shell)
    cat <<EOF | $cmd1 | $cmd2 > expected_hd.txt
hello
aaa
bbb
EOF

    rm -f "$outfile"
    # Передаём строки в pipex
    printf "hello\naaa\nbbb\n%s\n" "$limiter" | "$PIPEX_BIN" here_doc "$limiter" "$cmd1" "$cmd2" "$outfile" 2>/dev/null

    if [ ! -f "$outfile" ]; then
        echo "❌ FAIL (here_doc): Did not create $outfile (limiter=\"$limiter\", cmds=\"$cmd1 $cmd2\")"
        errors=$((errors + 1))
        return
    fi

    if diff expected_hd.txt "$outfile" >/dev/null 2>&1; then
        echo "✅ OK (here_doc): LIMITER=\"$limiter\""
    else
        echo "❌ FAIL (here_doc): LIMITER=\"$limiter\""
        errors=$((errors + 1))
    fi
}

########################
# ФУНКЦИЯ: run_valgrind_test
########################
run_valgrind_test() {
    local args=("$@")
    local val_cmd="valgrind --leak-check=full --show-leak-kinds=all \
        --errors-for-leak-kinds=all --error-exitcode=42 $PIPEX_BIN ${args[*]}"

    local vg_out
    vg_out=$(eval "$val_cmd" 2>&1)
    local status=$?

    if [ "$status" -eq 42 ]; then
        echo "❌ FAIL (Valgrind): ${args[*]}"
        echo "$vg_out" | grep "ERROR SUMMARY:"
        errors=$((errors + 1))
    else
        echo "✅ OK (Valgrind): ${args[*]}"
    fi
}

########################
# ФУНКЦИЯ: run_badcmd_test (несуществующая команда)
########################
# Проверяем, что outfile всё-таки создаётся или не создаётся, смотрим diff. 
# Обычно shell выдаёт ошибку: "bash: blahblah: command not found". 
# Pipex тоже должен обрабатывать ошибку (Command not found).
run_badcmd_test() {
    local infile="$1"
    local badcmd="$2"
    local cmd2="$3"
    local outfile="$4"

    # Генерируем infile, если нет
    if [ ! -f "$infile" ]; then
        echo -e "Some input data\n" > "$infile"
    fi

    # Ожидаемый shell-результат
    # shell way: < infile badcmd | cmd2
    # Но т.к. badcmd не существует, shell выдаст ошибку, outfile будет пустым/не созданным.
    # Чтобы получить "expected", можно сделать так:
    rm -f expected_bad.txt
    ( < "$infile" $badcmd | $cmd2 ) > expected_bad.txt 2> bad_error.txt

    rm -f "$outfile"
    "$PIPEX_BIN" "$infile" "$badcmd" "$cmd2" "$outfile" 2>/dev/null

    if [ ! -f "$outfile" ]; then
        echo "✅ OK (badcmd): outfile not created for <$infile $badcmd | $cmd2>" 
        # Предположим, что pipex не создаёт outfile, либо создаёт пустым — зависит от реализации.
        return
    fi

    # Если outfile существует, мы можем сравнить diff (чаще всего оно пустое).
    if diff expected_bad.txt "$outfile" >/dev/null 2>&1; then
        echo "✅ OK (badcmd): matched shell's empty output for <$infile $badcmd | $cmd2>"
    else
        echo "❌ FAIL (badcmd): differ from shell for <$infile $badcmd | $cmd2>"
        errors=$((errors + 1))
    fi
}

########################
#  НАЧИНАЕМ ТЕСТЫ
########################

echo "1) Simple two-command tests..."
# Тест 1: cat | wc -l
echo -e "Hello\nWorld\nPipex\nTest" > infile1.txt
run_test "infile1.txt" "cat" "wc -l" "outfile1.txt"

# Тест 2: grep apple | wc -w
echo -e "apple\nbanana\napple\ncherry\norange" > infile2.txt
run_test "infile2.txt" "grep apple" "wc -w" "outfile2.txt"

# Тест 3: ls | grep pipex
echo -e "some content for ls\n" > infile3.txt
run_test "infile3.txt" "ls" "grep pipex" "outfile3.txt"

echo ""
echo "2) here_doc test..."
run_here_doc_test "END" "cat" "wc -l" "outfile_hd.txt"

echo ""
echo "3) Valgrind tests on these scenarios..."
run_valgrind_test "infile1.txt" "cat" "wc -l" "val_out1.txt"
run_valgrind_test "infile2.txt" "grep apple" "wc -w" "val_out2.txt"
# run_valgrind_test "here_doc" "END" "cat" "wc -l" "val_hd.txt"

echo ""
echo "4) Nonexistent command test..."
run_badcmd_test "infile_bad.txt" "blahblah_123" "wc -l" "out_bad.txt"

echo ""
echo "5) Valgrind test on bad command..."
run_valgrind_test "infile_bad.txt" "nonexistCMD999" "wc -l" "val_bad.txt"

echo ""
if [ "$errors" -gt 0 ]; then
    echo "⚠️  Completed with $errors errors."
else
    echo "🎉 All tests passed successfully!"
fi

# Удаляем временные файлы
rm -f expected.txt expected_hd.txt bad_error.txt expected_bad.txt 
rm -f infile1.txt infile2.txt infile3.txt infile_bad.txt 
rm -f outfile1.txt outfile2.txt outfile3.txt outfile_hd.txt
rm -f out_bad.txt val_out1.txt val_out2.txt val_hd.txt val_bad.txt
cd ..
rm -rf "$TEST_DIR"
