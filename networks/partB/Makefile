# Makefile for compiling tcp_r.c and tcp_s.c
CC = gcc


all: r s

r: tcp_r.c
	$(CC)  tcp_r.c -o r

s: tcp_s.c
	$(CC)  tcp_s.c -o s

clean:
	rm -f r s
