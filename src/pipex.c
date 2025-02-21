#include "pipex.h"

int	main(int argc, char **argv, char **envp)
{
	t_pipex	pipex;

	if (argc < 5)
	{
		ft_printf("Usage: ./pipex file1 cmd1 cmd2 ... file2\n");
		return (1);
	}
	init_pipex(&pipex, argc, argv);
	execute_pipeline(&pipex, argv, envp);
	return (0);
}
