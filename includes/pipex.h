/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   pipex.h                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: tsargsya <tsargsya@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/02/22 13:46:58 by tsargsya          #+#    #+#             */
/*   Updated: 2025/02/24 22:56:50 by tsargsya         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#ifndef PIPEX_H
# define PIPEX_H

# define CMD_NOT_FOUND 127

# include "ft_printf.h"
# include "libft.h"
# include "get_next_line.h"
# include <fcntl.h>
# include <stdio.h>
# include <stdlib.h>
# include <sys/wait.h>
# include <unistd.h>

typedef struct s_pipe
{
	int		read;
	int		write;
}			t_pipe;

typedef struct s_pipex
{
	int		cmd_count;
	t_pipe	*pipes;
	int		infile;
	int		outfile;
}			t_pipex;

void		init_pipex(t_pipex *pipex, int argc, char **argv);
void		close_pipes(t_pipex *pipex, int cmd_index);
void		execute_pipeline(t_pipex *pipex, char **argv, char **envp);
void		error_exit(char *msg);
char		*find_command(char *cmd, char **envp);
int			pipex_here_doc(t_pipex *pipex, int argc, char **argv, char **envp);
void		free_array(char **array);

#endif
