/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   execute_utils.c                                    :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: tsargsya <tsargsya@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/02/22 13:47:28 by tsargsya          #+#    #+#             */
/*   Updated: 2025/02/24 22:59:47 by tsargsya         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "pipex.h"

static void	setup_redirections(t_pipex *pipex, int cmd_index);
static void	execute_command(char *cmd, t_pipex *pipex, int cmd_index,
				char **envp);

/**
 * @brief Set up redirections for the command at the given index.
 * @param pipex The pipex struct.
 * @param cmd_index The index of the command.
 */
static void	setup_redirections(t_pipex *pipex, int cmd_index)
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

/**
 * @brief Execute the command at the given index.
 * @param cmd The command to execute.
 * @param pipex The pipex struct.
 * @param cmd_index The index of the command.
 * @param envp The environment variables.
 */
static void	execute_command(char *cmd, t_pipex *pipex, int cmd_index,
		char **envp)
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
		exit(CMD_NOT_FOUND);
	}
	execve(cmd_path, args, envp);
	perror("Execve error");
	exit(EXIT_FAILURE);
}

/**
 * @brief Free the given array.
 * @param array The array to free.
 */
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

/**
 * @brief Execute the pipeline.
 * @param pipex The pipex struct.
 * @param argv The arguments.
 * @param envp The environment variables.
 */
void	execute_pipeline(t_pipex *pipex, char **argv, char **envp)
{
	int		i;
	pid_t	pid;

	i = 0;
	while (i < pipex->cmd_count)
	{
		pid = fork();
		if (pid == -1)
			error_exit("Fork error");
		if (pid == 0)
			execute_command(argv[i + 2], pipex, i, envp);
		i++;
	}
	close_pipes(pipex, -1);
	if (pipex->infile != -1)
		close(pipex->infile);
	if (pipex->outfile != -1)
		close(pipex->outfile);
	i = 0;
	while (i < pipex->cmd_count)
	{
		wait(NULL);
		i++;
	}
	free(pipex->pipes);
}
