# Detect OS and architecture
# For any native builds
ifeq ($(OS),Windows_NT)
    OS_NAME?=windows
    ARCH_NAME?= $(shell uname -m)
    BIN_EXT?=.exe
else
    OS_NAME?=$(shell uname -s)
    ARCH_NAME?=$(shell uname -m)
    BIN_EXE?=
endif

ifeq ($(OS_NAME),Linux)
    OS_NAME:=linux
endif

ifeq ($(OS_NAME),Darwin)
    OS_NAME:=mac
endif

# MingW and Cygwin has opposite handling when it sees a *. Detect and set it correctly.
MSYS_VERSION := $(if $(findstring Msys, $(shell uname -o)),$(word 1, $(subst ., ,$(shell uname -r))),0)

ifeq ($(MSYS_VERSION),0)
  WILD_STAR=*
else
  WILD_STAR=\*
endif

