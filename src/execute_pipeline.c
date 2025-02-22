/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   execute_pipeline.c                                 :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: tsargsya <tsargsya@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/02/22 13:47:34 by tsargsya          #+#    #+#             */
/*   Updated: 2025/02/22 13:47:35 by tsargsya         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "pipex.h"

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
	i = 0;
	while (i < pipex->cmd_count)
	{
		wait(NULL);
		i++;
	}
	free(pipex->pipes);
}
