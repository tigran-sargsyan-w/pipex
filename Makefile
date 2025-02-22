NAME = pipex

# Пути к файлам
LIBFT_DIR = libft
LIBFT = $(LIBFT_DIR)/libft.a

SRCS = src/pipex.c \
	src/init_pipex.c \
	src/execute_pipeline.c \
	src/execute_command.c \
	src/close_pipes.c \
	src/errors.c \
	src/find_command.c \
	src/pipex_here_doc.c
OBJS = $(SRCS:.c=.o)

CC = cc
CFLAGS = -Wall -Wextra -Werror -Iincludes -I$(LIBFT_DIR)
LDFLAGS = -Wl,--allow-multiple-definition

# Флаги линковки (добавляем libft)
LFLAGS = -L$(LIBFT_DIR) -lft

all: $(LIBFT) $(NAME)

$(LIBFT):
	@make -C $(LIBFT_DIR)

$(NAME): $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) $(LFLAGS) -o $(NAME) $(LDFLAGS)

%.o: %.c
	@$(CC) $(CFLAGS) -c $< -o $@

clean:
	@make clean -C $(LIBFT_DIR)
	rm -f $(OBJS)

fclean: clean
	@make fclean -C $(LIBFT_DIR)
	rm -f $(NAME)

re: fclean all