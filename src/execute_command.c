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

void	execute_command(char *cmd, t_pipex *pipex, int cmd_index, char **envp)
{
	char	**args;
	char	*cmd_path;

	setup_redirections(pipex, cmd_index);
	close_pipes(pipex, cmd_index);
	args = ft_split(cmd, ' ');
	cmd_path = find_command(args[0], envp);
	if (!cmd_path)
	{
		ft_printf("Command not found: %s\n", args[0]);
		exit(127);
	}
	execve(cmd_path, args, envp);
	perror("Execve error");
	exit(1);
}
