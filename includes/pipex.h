#ifndef PIPEX_H
# define PIPEX_H

# include "ft_printf.h"
# include "libft.h"
# include <fcntl.h>
# include <stdio.h>
# include <stdlib.h>
# include <sys/wait.h>
# include <unistd.h>

typedef struct s_pipe
{
	int read;  // Чтение
	int write; // Запись
}		t_pipe;

typedef struct s_pipex
{
	int cmd_count; // Количество команд
	t_pipe *pipes; // Массив структур пайпов
	int infile;    // Входной файл
	int outfile;   // Выходной файл
}		t_pipex;

// Основные функции
void	init_pipex(t_pipex *pipex, int argc, char **argv);
void	close_pipes(t_pipex *pipex, int cmd_index);
void	execute_pipeline(t_pipex *pipex, char **argv, char **envp);
void	execute_command(char *cmd, t_pipex *pipex, int cmd_index, char **envp);
void	error_exit(char *msg);
char	*find_command(char *cmd, char **envp);

#endif
