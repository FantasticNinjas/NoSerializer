
CC := clang++
ARCHIVE := llvm-ar

# ANSI colors for command line text
ANSI_GREEN := \033[1;92m
ANSI_DEFAULT_COLOR:= \033[m

SRC_DIR := src
LIB_DIR := lib
BIN_DIR := bin
TEST_DIR := test

BUILD_DIR := .$(CC)

LIB_INTERNAL_NAME := libNoSerialInternal

LIB_INTERNAL_SRC_DIR := $(SRC_DIR)/$(LIB_INTERNAL_NAME)
LIB_INTERNAL_SRC := $(wildcard $(LIB_INTERNAL_SRC_DIR)/*.cxx)
LIB_INTERNAL_OBJ := $(patsubst $(SRC_DIR)/%.cxx, $(BUILD_DIR)/%.o, $(LIB_INTERNAL_SRC))
LIB_INTERNAL := $(LIB_DIR)/$(LIB_INTERNAL_NAME).a

FRONTEND_SRC_DIR := $(SRC_DIR)/frontend
FRONTEND_BIN_DIR := $(BIN_DIR)

.DEFAULT_GOAL := all

################################################################
# Build internal library
################################################################

$(LIB_INTERNAL): $(LIB_INTERNAL_OBJ)
	@printf "%b" "$(ANSI_GREEN)Packing static library $@...$(ANSI_DEFAULT_COLOR)\n"
	$(ARCHIVE) rcs $@ $^

################################################################
# Build C++ frontend executable
################################################################

CXX_FRONTEND_NAME := noserial-cxx

CXX_FRONTEND_SRC_DIR := $(FRONTEND_SRC_DIR)/$(CXX_FRONTEND_NAME)
CXX_FRONTEND_SRC := $(wildcard $(CXX_FRONTEND_SRC_DIR)/*.cxx)
CXX_FRONTEND_EXE := $(FRONTEND_BIN_DIR)/$(CXX_FRONTEND_NAME)
CXX_FRONTEND_OBJ := $(patsubst $(SRC_DIR)/%.cxx, $(BUILD_DIR)/%.o, $(CXX_FRONTEND_SRC))

$(CXX_FRONTEND_EXE): $(CXX_FRONTEND_OBJ) $(LIB_INTERNAL)
	@printf "%b" "$(ANSI_GREEN)Linking executable $@...$(ANSI_DEFAULT_COLOR)\n"
	$(CC) $^ -o $@

################################################################
# Build C frontend executable
################################################################

C_FRONTEND_NAME := noserial-c

C_FRONTEND_SRC_DIR := $(FRONTEND_SRC_DIR)/$(C_FRONTEND_NAME)
C_FRONTEND_SRC := $(wildcard $(C_FRONTEND_SRC_DIR)/*.cxx)
C_FRONTEND_EXE := $(FRONTEND_BIN_DIR)/$(C_FRONTEND_NAME)
C_FRONTEND_OBJ := $(patsubst $(SRC_DIR)/%.cxx, $(BUILD_DIR)/%.o, $(C_FRONTEND_SRC))

$(C_FRONTEND_EXE): $(C_FRONTEND_OBJ) $(LIB_INTERNAL)
	@printf "%b" "$(ANSI_GREEN)Linking executable $@...$(ANSI_DEFAULT_COLOR)\n"
	$(CC) $^ -o $@


################################################################
# Compiler flags
################################################################

# Adjust optomization flags based on whether debugging is enabled
DEBUG := 1

ifeq ($(DEBUG), 1)
OPT_FLAGS := -O0 -g
else
OPT_FLAGS := -03 -Werror
endif

# Include files from all source directories
INCLUDE_FLAGS := -I$(CXX_FRONTEND_SRC_DIR) -I$(LIB_INTERNAL_SRC_DIR)

# Enable all warnings and warnings as errors
WARNING_FLAGS := -Wall -Wextra

COMP_FLAGS := -std=c++20 -c $(OPT_FLAGS) $(WARNING_FLAGS) $(INCLUDE_FLAGS)


EXE := $(CXX_FRONTEND_EXE) $(C_FRONTEND_EXE)

.PHONY: all clean

all: $(EXE)
	@printf "%b" "$(ANSI_GREEN)*** Build Successful ***$(ANSI_DEFAULT_COLOR)\n"

clean:
	rm -rf $(BUILD_DIR) $(LIB_INTERNAL) $(EXE)

################################################################
# Compile source files
################################################################

%.o: %.cxx
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cxx $(BUILD_DIR)/%.d
	@printf "%b" "$(ANSI_GREEN)Compiling source file $<...$(ANSI_DEFAULT_COLOR)\n"
	@mkdir -p $(dir $@)
	$(CC) $< -MT $@ -MMD -MP -MF $(BUILD_DIR)/$*.d $(COMP_FLAGS) -o $@

# Dependancy files are built at the same time as object files. Empty target for
# dependancy files used to trigger object files to be rebuilt if dependancy file is
# missing
$(BUILD_DIR)/%.d: ;

# Ensure dependancy files are not deleted as intermediate files
.PRECIOUS: $(BUILD_DIR)/%.d

# Include auto-generated dependancy files
DEPENDANCY_FILES := $(shell find $(BUILD_DIR) -name "*.d" 2> /dev/null)

include $(DEPENDANCY_FILES)