/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   find_cmd_utils.c                                   :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: tsargsya <tsargsya@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/02/22 13:47:37 by tsargsya          #+#    #+#             */
/*   Updated: 2025/02/24 23:22:29 by tsargsya         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "pipex.h"

static char	*get_from_env(char **envp, char *key);
static char	*build_command_path(char *dir, char *cmd);
static char	*search_in_paths(char **paths, char *cmd);

/**
 * @brief Retrieve the value associated with 
 * a specified key from the environment variables.
 * @envp: An array of strings representing the environment variables.
 * @key: The name of the environment variable to search for.
 * @return Value associated with the key
 */
static char	*get_from_env(char **envp, char *key)
{
	int	i;
	int	key_len;

	i = 0;
	key_len = ft_strlen(key);
	while (envp[i])
	{
		if (ft_strncmp(envp[i], key, key_len) == 0 && envp[i][key_len] == '=')
			return (envp[i] + key_len + 1);
		i++;
	}
	return (NULL);
}

/**
 * @brief Constructs a full command path string.
 * @param dir Directory in which the command is located.
 * @param cmd Command name.
 * @return A newly allocated string containing the full command path.
 */
static char	*build_command_path(char *dir, char *cmd)
{
	char	*full_path;
	size_t	path_len;

	path_len = ft_strlen(dir) + ft_strlen(cmd) + 2;
	full_path = malloc(path_len);
	if (!full_path)
		return (NULL);
	ft_strlcpy(full_path, dir, path_len);
	ft_strlcat(full_path, "/", path_len);
	ft_strlcat(full_path, cmd, path_len);
	return (full_path);
}

/**
 * @brief Searches for the command in the specified directories.
 * @param paths An array of strings representing the directories to search in.
 * @param cmd Command name.
 * @return A newly allocated string containing the full command path.
 */
static char	*search_in_paths(char **paths, char *cmd)
{
	char	*full_path;
	int		i;

	i = 0;
	while (paths[i])
	{
		full_path = build_command_path(paths[i], cmd);
		if (!full_path)
		{
			free_array(paths);
			return (NULL);
		}
		if (access(full_path, X_OK) == 0)
		{
			free_array(paths);
			return (full_path);
		}
		free(full_path);
		i++;
	}
	free_array(paths);
	return (NULL);
}

/**
 * @brief Searches for the command in the specified directories.
 * @param cmd Command name.
 * @param envp An array of strings representing the environment variables.
 * @return A newly allocated string containing the full command path.
 */
char	*find_command(char *cmd, char **envp)
{
	char	*path_env;
	char	**paths;

	if (!cmd || !envp)
		return (NULL);
	if (ft_strchr(cmd, '/'))
	{
		if (access(cmd, X_OK) == 0)
			return (ft_strdup(cmd));
		return (NULL);
	}
	path_env = get_from_env(envp, "PATH");
	if (!path_env)
		return (NULL);
	paths = ft_split(path_env, ':');
	if (!paths)
		return (NULL);
	return (search_in_paths(paths, cmd));
}
