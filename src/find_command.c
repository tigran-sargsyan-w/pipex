#include "pipex.h"
#include <string.h>

char	*get_from_env(char **envp, char *key)
{
	int	i;
	int	key_len;

	i = 0;
	key_len = ft_strlen(key);
	while (envp[i])
	{
		if (ft_strncmp(envp[i], key, key_len) == 0)
			return (envp[i] + key_len);
		i++;
	}
	return (NULL);
}

char	*find_command(char *cmd, char **envp)
{
	char	*path_env;
	char	**paths;
	char	*full_path;
	size_t	path_len;
	int i;

	if (!cmd || !envp)
		return (NULL);
	if (ft_strchr(cmd, '/'))
	{
		if (access(cmd, X_OK) == 0)
			return (ft_strdup(cmd));
		return (NULL);
	}
	path_env = get_from_env(envp, "PATH=");
	if (!path_env)
		return (NULL);
	paths = ft_split(path_env, ':');
	if (!paths)
		return (NULL);
	i = 0;
	while (paths[i])
	{
		path_len = ft_strlen(paths[i]) + ft_strlen(cmd) + 2;
		full_path = malloc(path_len);
		if (!full_path)
			return (NULL);
		ft_strlcpy(full_path, paths[i], path_len);
		ft_strlcat(full_path, "/", path_len);
		ft_strlcat(full_path, cmd, path_len);
		if (access(full_path, X_OK) == 0)
		{
			free(paths);
			return (full_path);
		}
		free(full_path);
		i++;
	}
	free(paths);
	return (NULL);
}
