/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   pipex.c                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: tsargsya <tsargsya@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/02/18 19:56:11 by tsargsya          #+#    #+#             */
/*   Updated: 2025/02/20 18:43:19 by tsargsya         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

int step1()
{
    int	pipe1[2], pipe2[2], pipe3[2];
	pid_t pid1, pid2, pid3, pid4;

	errno = EINVAL;
	perror("start");
	printf("%s\n", strerror(errno));
	// Создаем три пайпа:
	// pipe1: соединяет A и B
	// pipe2: соединяет B и C
	// pipe3: соединяет C и D
	if (pipe(pipe1) == -1)
	{
		perror("pipe1");
		exit(1);
	}
	if (pipe(pipe2) == -1)
	{
		perror("pipe2");
		exit(1);
	}
	if (pipe(pipe3) == -1)
	{
		perror("pipe3");
		exit(1);
	}
	// Дочерний процесс для команды A
	pid1 = fork();
	if (pid1 < 0)
	{
		perror("fork1");
		exit(1);
	}
	if (pid1 == 0)
	{
		// Команда A выводит данные в pipe1
		close(pipe1[0]); // закрываем конец на чтение в pipe1
		dup2(pipe1[1], STDOUT_FILENO);
		close(pipe1[1]);
        
		// Закрываем ненужные пайпы
		close(pipe2[0]);
		close(pipe2[1]);
		close(pipe3[0]);
		close(pipe3[1]);
        
		execlp("commandA", "commandA", (char *)NULL);
		perror("execlp commandA");
		exit(1);
	}
	// Дочерний процесс для команды B
	pid2 = fork();
	if (pid2 < 0)
	{
		perror("fork2");
		exit(1);
	}
	if (pid2 == 0)
	{
		// Команда B получает данные из pipe1 и отправляет их в pipe2
		close(pipe1[1]); // закрываем конец на запись в pipe1
		dup2(pipe1[0], STDIN_FILENO);
		close(pipe1[0]);
		close(pipe2[0]); // закрываем конец на чтение в pipe2
		dup2(pipe2[1], STDOUT_FILENO);
		close(pipe2[1]);
		// Закрываем неиспользуемый pipe3
		close(pipe3[0]);
		close(pipe3[1]);
		execlp("commandB", "commandB", (char *)NULL);
		perror("execlp commandB");
		exit(1);
	}
	// Дочерний процесс для команды C
	pid3 = fork();
	if (pid3 < 0)
	{
		perror("fork3");
		exit(1);
	}
	if (pid3 == 0)
	{
		// Команда C получает данные из pipe2 и отправляет их в pipe3
		close(pipe2[1]); // закрываем конец на запись в pipe2
		dup2(pipe2[0], STDIN_FILENO);
		close(pipe2[0]);
		close(pipe3[0]); // закрываем конец на чтение в pipe3
		dup2(pipe3[1], STDOUT_FILENO);
		close(pipe3[1]);
		// Закрываем неиспользуемый pipe1
		close(pipe1[0]);
		close(pipe1[1]);
		execlp("commandC", "commandC", (char *)NULL);
		perror("execlp commandC");
		exit(1);
	}
	// Дочерний процесс для команды D
	pid4 = fork();
	if (pid4 < 0)
	{
		perror("fork4");
		exit(1);
	}
	if (pid4 == 0)
	{
		// Команда D получает данные из pipe3
		close(pipe3[1]); // закрываем конец на запись в pipe3
		dup2(pipe3[0], STDIN_FILENO);
		close(pipe3[0]);
		// Закрываем неиспользуемые pipe1 и pipe2
		close(pipe1[0]);
		close(pipe1[1]);
		close(pipe2[0]);
		close(pipe2[1]);
		execlp("commandD", "commandD", (char *)NULL);
		perror("execlp commandD");
		exit(1);
	}
	// Родительский процесс закрывает все дескрипторы пайпов
	close(pipe1[0]);
	close(pipe1[1]);
	close(pipe2[0]);
	close(pipe2[1]);
	close(pipe3[0]);
	close(pipe3[1]);
	// Ожидаем завершения всех дочерних процессов
	wait(NULL);
	wait(NULL);
	wait(NULL);
	wait(NULL);
    return 0;
}

int step2()
{
    char *cmd = "/bin/ls"; // Полный путь к команде
    char *args[] = {"ls", "-l", NULL}; // Аргументы (включая имя команды)
    char *envp[] = {NULL}; // Окружение (пока пустое)

    execve(cmd, args, envp);
    perror("execve"); // Выведется только если execve провалится
    return 1;
}

int	main(void)
{
	printf("step1\n");
    // step1();

    printf("\nstep2\n");
    step2();
    
	return (0);
}
