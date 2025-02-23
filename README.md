# pipex
This project will let you discover in detail a UNIX mechanism that you already know by using it in your program.

./pipex infile "cat" "grep test" "wc -l" outfile

./pipex infile "cat" "grep test" "sort" "uniq" "wc -l" outfile

./pipex here_doc END "cat" "wc -l" outfile

./pipex here_doc END "cat" "grep a" "wc -l" outfile

valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --trace-children=yes -s -q ./pipex infile "cat" "grep test" "wc -l" outfile

valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --trace-children=yes -s -q ./pipex infile "cat" "grep test" "sort" "uniq" "wc -l" outfile

valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --trace-children=yes -s -q ./pipex here_doc END "cat" "wc -l" outfile

valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --trace-children=yes -s -q ./pipex here_doc END "cat" "grep a" "wc -l" outfile