# **************************************************************************** #
#                                  Makefile                                    #
# **************************************************************************** #

NAME        = pipex

# -------------------------------
#   Directories
# -------------------------------
SRC_DIR     = src
LIBFT_DIR   = libft

# -------------------------------
#   Library Dependency
# -------------------------------
LIBFT       = $(LIBFT_DIR)/libft.a

# -------------------------------
#   Source Files for Mandatory Part
# -------------------------------
SRCS        = $(SRC_DIR)/pipex.c \
              $(SRC_DIR)/pipex_utils.c \
              $(SRC_DIR)/execute_utils.c \
              $(SRC_DIR)/find_cmd_utils.c

# -------------------------------
#   Bonus Source Files (Additional)
# -------------------------------
BONUS_SRCS  = $(SRC_DIR)/here_doc_bonus.c

# -------------------------------
#   All Source Files (Mandatory + Bonus)
# -------------------------------
ALL_SRCS    = $(SRCS) $(BONUS_SRCS)

# -------------------------------
#   Object Files for pipex (All)
# -------------------------------
OBJS        = $(ALL_SRCS:.c=.o)

# -------------------------------
#   Compiler and Flags
# -------------------------------
CC          = cc
CFLAGS      = -Wall -Wextra -Werror -Iincludes -I$(LIBFT_DIR)
LDFLAGS     = -Wl,--allow-multiple-definition
LFLAGS      = -L$(LIBFT_DIR) -lft

# **************************************************************************** #
#                                 Build Rules                                  #
# **************************************************************************** #

all: $(LIBFT) $(NAME)
	@echo "🚀 Executable $(NAME) created successfully!"

$(LIBFT):
	@$(MAKE) -s -C $(LIBFT_DIR)

$(NAME): $(OBJS)
	@$(CC) $(CFLAGS) $(OBJS) $(LFLAGS) -o $(NAME) $(LDFLAGS)

bonus: all

%.o: %.c
	@$(CC) $(CFLAGS) -c $< -o $@

clean:
	@$(MAKE) -s clean -C $(LIBFT_DIR)
	@rm -f $(OBJS)
	@echo "🗑️ $(NAME) object files removed."

fclean: clean
	@$(MAKE) -s fclean -C $(LIBFT_DIR)
	@rm -f $(NAME)
	@echo "😒 $(NAME) removed."

re: fclean all

.PHONY: all bonus clean fclean re
