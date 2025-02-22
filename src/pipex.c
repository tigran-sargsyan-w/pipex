/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   pipex.c                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: tsargsya <tsargsya@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/02/22 13:47:45 by tsargsya          #+#    #+#             */
/*   Updated: 2025/02/22 19:34:46 by tsargsya         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "pipex.h"

int	main(int argc, char **argv, char **envp)
{
	t_pipex	pipex;

	if (argc < 5)
	{
		ft_printf("Usage: ./pipex file1 cmd1 cmd2 ... file2\n");
		return (1);
	}
	if (ft_strcmp(argv[1], "here_doc") == 0)
		return (pipex_here_doc(&pipex, argc, argv, envp));
	init_pipex(&pipex, argc, argv);
	execute_pipeline(&pipex, argv, envp);
	return (0);
}
