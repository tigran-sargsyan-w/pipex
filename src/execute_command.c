/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   execute_command.c                                  :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: tsargsya <tsargsya@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/02/22 13:47:28 by tsargsya          #+#    #+#             */
/*   Updated: 2025/02/23 19:08:21 by tsargsya         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "pipex.h"

void	setup_redirections(t_pipex *pipex, int cmd_index)
{
	if (cmd_index == 0)
	{
		dup2(pipex->infile, STDIN_FILENO);
		dup2(pipex->pipes[cmd_index].write, STDOUT_FILENO);
	}
	else if (cmd_index == pipex->cmd_count - 1)
	{
		dup2(pipex->pipes[cmd_index - 1].read, STDIN_FILENO);
		dup2(pipex->outfile, STDOUT_FILENO);
	}
	else
	{
		dup2(pipex->pipes[cmd_index - 1].read, STDIN_FILENO);
		dup2(pipex->pipes[cmd_index].write, STDOUT_FILENO);
	}
}

void	free_array(char **array)
{
	int	i;

	i = 0;
	if (!array)
		return ;
	while (array[i])
	{
		free(array[i]);
		i++;
	}
	free(array);
}

void	execute_command(char *cmd, t_pipex *pipex, int cmd_index, char **envp)
{
	char	**args;
	char	*cmd_path;

	setup_redirections(pipex, cmd_index);
	close_pipes(pipex, cmd_index);
	if (pipex->infile != -1)
		close(pipex->infile);
	if (pipex->outfile != -1)
		close(pipex->outfile);
	args = ft_split(cmd, ' ');
	cmd_path = find_command(args[0], envp);
	if (!cmd_path)
	{
		write(STDERR_FILENO, "Command not found: ", 19);
		write(STDERR_FILENO, args[0], ft_strlen(args[0]));
		write(STDERR_FILENO, "\n", 1);
		close_pipes(pipex, -1);
		free_array(args);
		if (pipex->pipes)
			free(pipex->pipes);
		exit(127);
	}
	execve(cmd_path, args, envp);
	perror("Execve error");
	exit(1);
}
