#include "pipex.h"

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
