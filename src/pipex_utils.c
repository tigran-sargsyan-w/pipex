/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   pipex_utils.c                                      :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: tsargsya <tsargsya@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/02/22 13:47:24 by tsargsya          #+#    #+#             */
/*   Updated: 2025/02/24 23:36:27 by tsargsya         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "pipex.h"

/**
 * @brief Initialize the pipex structure
 * @param pipex The pipex structure
 * @param argc The number of arguments
 * @param argv The arguments
 */
void	init_pipex(t_pipex *pipex, int argc, char **argv)
{
	int	i;

	pipex->cmd_count = argc - 3;
	pipex->infile = open(argv[1], O_RDONLY);
	if (pipex->infile == -1)
		error_exit("Error opening infile");
	pipex->outfile = open(argv[argc - 1], O_WRONLY | O_CREAT | O_TRUNC, 0644);
	if (pipex->outfile == -1)
		error_exit("Error opening outfile");
	pipex->pipes = malloc(sizeof(t_pipe) * (pipex->cmd_count - 1));
	if (!pipex->pipes)
		error_exit("Memory allocation error");
	i = 0;
	while (i < pipex->cmd_count - 1)
	{
		if (pipe((int *)&pipex->pipes[i]) == -1)
			error_exit("Pipe error");
		i++;
	}
}

/**
 * @brief Close the pipes
 * @param pipex The pipex structure
 * @param cmd_index The command index to skip
 */
void	close_pipes(t_pipex *pipex, int cmd_index)
{
	int	i;

	i = 0;
	while (i < pipex->cmd_count - 1)
	{
		if (!(cmd_index == 0 && i == 0))
			close(pipex->pipes[i].write);
		if (!(cmd_index == pipex->cmd_count - 1 && i == cmd_index - 1))
			close(pipex->pipes[i].read);
		i++;
	}
}

/**
 * @brief Exit the program with an error message
 * @param msg The error message
 */
void	error_exit(char *msg)
{
	perror(msg);
	exit(EXIT_FAILURE);
}
