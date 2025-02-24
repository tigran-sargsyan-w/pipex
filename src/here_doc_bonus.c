/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   here_doc_bonus.c                                   :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: tsargsya <tsargsya@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/02/24 22:38:25 by tsargsya          #+#    #+#             */
/*   Updated: 2025/02/24 23:31:49 by tsargsya         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "pipex.h"

static void	handle_here_doc_input(char *filename, char *limiter);
static void	prepare_here_doc(char *temp_file, int *argc, char **argv);

/**
 * @brief Handles the input for the here_doc file
 * @param temp_file The name of the here_doc file
 * @param limiter The limiter string
 */
static void	handle_here_doc_input(char *temp_file, char *limiter)
{
	int		fd;
	char	*line;

	fd = open(temp_file, O_WRONLY | O_CREAT | O_TRUNC, 0644);
	if (fd == -1)
		error_exit("Error creating here_doc file");
	while (1)
	{
		ft_putstr_fd("> ", 1);
		line = get_next_line(0);
		if (!line || ft_strncmp(line, limiter, ft_strlen(limiter)) == 0)
		{
			free(line);
			break ;
		}
		write(fd, line, ft_strlen(line));
		free(line);
	}
	close(fd);
}

/**
 * @brief Prepares the here_doc file and the arguments for the pipeline
 * @param temp_file The name of the here_doc file
 * @param argc The number of arguments
 * @param argv The arguments
 */
static void	prepare_here_doc(char *temp_file, int *argc, char **argv)
{
	int	temp_fd;
	int	i;

	handle_here_doc_input(temp_file, argv[2]);
	temp_fd = open(temp_file, O_RDONLY);
	if (temp_fd == -1)
		error_exit("Error opening here_doc file");
	close(temp_fd);
	(*argc)--;
	argv[1] = temp_file;
	i = 2;
	while (i < *argc)
	{
		argv[i] = argv[i + 1];
		i++;
	}
}

/**
 * @brief Executes the here_doc pipeline
 * @param pipex The pipex structure
 * @param argc The number of arguments
 * @param argv The arguments
 * @param envp The environment variables
 * @return 0 on success, 1 on error
 */
int	pipex_here_doc(t_pipex *pipex, int argc, char **argv, char **envp)
{
	char	*temp_file;

	temp_file = ".here_doc_tmp";
	if (argc < 6)
	{
		ft_printf("Usage: ./pipex here_doc LIMITER cmd1 cmd2 ... file\n");
		return (1);
	}
	prepare_here_doc(temp_file, &argc, argv);
	init_pipex(pipex, argc, argv);
	execute_pipeline(pipex, argv, envp);
	if (pipex->outfile != -1)
		close(pipex->outfile);
	unlink(temp_file);
	return (0);
}
