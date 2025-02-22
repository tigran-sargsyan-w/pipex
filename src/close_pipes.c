/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   close_pipes.c                                      :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: tsargsya <tsargsya@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/02/22 13:47:14 by tsargsya          #+#    #+#             */
/*   Updated: 2025/02/22 13:47:15 by tsargsya         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "pipex.h"

// Первый процесс не закрывает `pipes[0].write`
// Последний процесс не закрывает `pipes[last-1].read`
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
