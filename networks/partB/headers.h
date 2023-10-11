
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <pthread.h>
#include <sys/time.h>

#define MAX_MSG_LEN 1024
#define CHUNK_SIZE 4
#define MAX_CHUNKS 256
#define MAX_RETRIES 5
#define TIMEOUT 5
struct Message {
    struct Chunk* chunks[MAX_CHUNKS];
    int num_chunks;
};

struct Thread_Args {
    int socket;
    struct sockaddr_in server_addr;
    struct Message* message;
   
};

struct Chunk {
    char data[CHUNK_SIZE];
    int seq_num;
    int times_sended;
};

void* send_message(void* args);
void* receive_ack(void* args);
void* resend_message_in_chunks(void* args);
struct Message* create_message(char* msg);
void print_message(struct Message* message);
void free_message(struct Message* message);
