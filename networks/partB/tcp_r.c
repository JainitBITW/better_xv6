#include "headers.h"
int* acks;
struct timeval* times_sent;
void* send_message(void* args)
{
	struct Thread_Args* thread_args = (struct Thread_Args*)args;
	int socket = thread_args->socket;
	struct sockaddr_in server_addr = thread_args->server_addr;
	struct Message* message = thread_args->message;
	int i;
	times_sent = malloc(sizeof(struct timeval) * message->num_chunks);
	// Send the number of chunks

	for(i = 0; i < message->num_chunks; i++)
	{
		struct Chunk* chunk = malloc(sizeof(struct Chunk));
		printf("Here %d %d  \n", message->num_chunks , message->chunks[i]->times_sended);
		
		strcpy(chunk->data, message->chunks[i]->data);
		chunk->seq_num = message->chunks[i]->seq_num;
		message->chunks[i]->times_sended =1;
		chunk->times_sended = message->chunks[i]->times_sended;
		printf("Here2\n");
		printf("Sending chunk in send_message %d: %s\n", chunk->seq_num, chunk->data);

		if(sendto(socket,
				  &chunk,
				  sizeof(chunk),
				  0,
				  (struct sockaddr*)&server_addr,
				  sizeof(server_addr)) < 0)
		{
			perror("sendto failed");
			exit(1);
		}
		printf("Sent chunk in send_message %d: %s\n", chunk->seq_num, chunk->data);
		gettimeofday(&times_sent[chunk->seq_num], NULL);
	}

	return NULL;
}

void* receive_ack(void* args)
{
	struct Thread_Args* thread_args = (struct Thread_Args*)args;
	int socket = thread_args->socket;
	struct sockaddr_in server_addr = thread_args->server_addr;
	struct Message* message = thread_args->message;

	int i;
	for(i = 0; i < message->num_chunks; i++)
	{
		struct Chunk* chunk;
		socklen_t addr_len = sizeof(server_addr);
		if(recvfrom(socket, &chunk, sizeof(chunk), 0, (struct sockaddr*)&server_addr, &addr_len) <
		   0)
		{
			perror("recvfrom failed");
			exit(1);
		}
		printf("Received ack %d\n", chunk->seq_num);
		acks[chunk->seq_num] = 1;
	}
	return NULL;
}

void* resend_message_in_chunks(void* args)
{

	struct Thread_Args* thread_args = (struct Thread_Args*)args;
	int socket = thread_args->socket;
	struct sockaddr_in server_addr = thread_args->server_addr;
	struct Message* message = thread_args->message;

	int i;
	struct timeval now;
	for(i = 0; i < message->num_chunks; i++)
	{
		struct Chunk* chunk;

		memcpy(chunk, message->chunks[i], sizeof(struct Chunk));
		while(message->chunks[i]->times_sended < MAX_RETRIES && acks[chunk->seq_num] == 0)
		{
			gettimeofday(&now, NULL);
			timersub(&now, &times_sent[chunk->seq_num], &now);
			if(now.tv_sec >= TIMEOUT)
			{
				if(sendto(socket,
						  &chunk,
						  sizeof(chunk),
						  0,
						  (struct sockaddr*)&server_addr,
						  sizeof(server_addr)) < 0)
				{
					perror("sendto failed");
					exit(1);
				}
				printf("Resent chunk %d: %s\n", chunk->seq_num, chunk->data);
				gettimeofday(&times_sent[chunk->seq_num], NULL);
				message->chunks[i]->times_sended++;
			}
		}
	}

	return NULL;
}

struct Message* create_message(char* msg)
{
	struct Message* message = malloc(sizeof(struct Message));
	int msg_len = strlen(msg);
	int num_chunks = msg_len / CHUNK_SIZE;
	if(msg_len % CHUNK_SIZE != 0)
	{
		num_chunks++;
	}
	message->num_chunks = num_chunks;
	int i;
	for(i = 0; i < num_chunks; i++)
	{
		struct Chunk* chunk = malloc(sizeof(struct Chunk));

		chunk->seq_num = i;
		memcpy(chunk->data, msg + i * CHUNK_SIZE, CHUNK_SIZE);
		message->chunks[i] = chunk;
		// printf("Chunk %d: %s\n", chunk->seq_num, chunk->data);
	}
	if(msg_len % CHUNK_SIZE != 0)
	{
		
		message->chunks[num_chunks-1]->data[msg_len % CHUNK_SIZE] = '\0';
		// printf("Chunk %d: %s\n", chunk->seq_num, chunk->data);
	}

	return message;
}

void print_message(struct Message* message)
{
	int i;
	for(i = 0; i < message->num_chunks; i++)
	{
		printf("Chunk %d: %s\n", message->chunks[i]->seq_num, message->chunks[i]->data);
	}
}

void free_message(struct Message* message)
{
	int i;
	for(i = 0; i < message->num_chunks; i++)
	{
		free(message->chunks[i]);
	}
	free(message);
}

void send_message_final()
{
	char msg[MAX_MSG_LEN];
	printf("Enter message to send: ");
	fgets(msg, MAX_MSG_LEN, stdin);
	msg[strlen(msg) - 1] = '\0';
	struct Message* message = create_message(msg);
	print_message(message);
	int c_socket = socket(AF_INET, SOCK_DGRAM, 0);
	if(c_socket < 0)
	{
		perror("socket failed");
		exit(1);
	}
	struct sockaddr_in server_addr;
	server_addr.sin_family = AF_INET;
	server_addr.sin_port = htons(4545);
	if(inet_pton(AF_INET, "127.0.0.1", &server_addr.sin_addr) < 0)
	{
		perror("inet_pton failed");
		close(c_socket);
		exit(1);
	}

	struct Thread_Args* thread_args = malloc(sizeof(struct Thread_Args));
	thread_args->socket = c_socket;
	thread_args->server_addr = server_addr;
	thread_args->message = message;
	acks = malloc(sizeof(int) * message->num_chunks);

	int i;
	for(i = 0; i < message->num_chunks; i++)
	{
		acks[i] = 0;
	}
	// Send the number of chunks
	printf("Sending number of chunks %d \n", message->num_chunks);
	if(sendto(c_socket,
			  &message->num_chunks,
			  sizeof(message->num_chunks),
			  0,
			  (struct sockaddr*)&server_addr,
			  sizeof(server_addr)) < 0)
	{
		perror("sendto failed");
		exit(1);
	}
	pthread_t send_thread, receive_thread, resend_thread;
	pthread_create(&send_thread, NULL, send_message, (void*)thread_args);
	pthread_create(&receive_thread, NULL, receive_ack, (void*)thread_args);
	pthread_join(send_thread, NULL);
	pthread_join(receive_thread, NULL);
	int all_acks_received = 1;
	for(i = 0; i < message->num_chunks; i++)
	{
		if(acks[i] == 0)
		{
			all_acks_received = 0;
			break;
		}
	}
	if(all_acks_received)
	{
		printf("All acks received\n");
	}
	else
	{
		printf("Resending chunks\n");
		pthread_create(&resend_thread, NULL, resend_message_in_chunks, (void*)thread_args);
		pthread_join(resend_thread, NULL);
	}
	// free_message(message);
	// free(thread_args);
	// free(acks);
	close(c_socket);
}

void receive_message()
{
	int c_socket = socket(AF_INET, SOCK_DGRAM, 0);
	if(c_socket < 0)
	{
		perror("socket failed");
		exit(1);
	}
	struct sockaddr_in server_addr;
	server_addr.sin_family = AF_INET;
	server_addr.sin_port = htons(4545);
	socklen_t len = sizeof(server_addr);

	if(bind(c_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0)
	{
		perror("bind failed");
		close(c_socket);
		exit(1);
	}

	int num_chunks;
	printf("Waiting for number of chunks\n");
	if(recvfrom(
		   c_socket, &num_chunks, sizeof(num_chunks), 0, (struct sockaddr*)&server_addr, &len) < 0)
	{
		perror("recvfrom failed");
		close(c_socket);
		exit(1);
	}
	printf("Number of chunks: %d\n", num_chunks);
	int i;

	struct Message* message = malloc(sizeof(struct Message));

	message->num_chunks = num_chunks;

	int recv_chunks[num_chunks];
	for(i = 0; i < num_chunks; i++)
	{
		recv_chunks[i] = 0;
	}
	for(i = 0; i < num_chunks; i++)
	{
		struct Chunk* chunk = malloc(sizeof(struct Chunk));
		
		if(recvfrom(c_socket, &chunk, sizeof(chunk), 0, (struct sockaddr*)&server_addr, &len) < 0)
		{
			perror("recvfrom failed");
			close(c_socket);
			exit(1);
		}

		else if(recv_chunks[chunk->seq_num] == 0)
		{
			printf("Waiting for chunks\n");
			printf("Received chunk %d: %s\n", chunk->seq_num, chunk->data);
			message->chunks[i] = chunk;
			recv_chunks[chunk->seq_num] = 1;
			recv_chunks[i] = 1;
			if(sendto(c_socket, &chunk, sizeof(chunk), 0, (struct sockaddr*)&server_addr, len) < 0)
			{
				perror("sendto failed");
				exit(1);
			}
			else
			{
				printf("Sent chunk %d: %s\n", chunk->seq_num, chunk->data);
			}
		}
		else
		{
			// printf("%d SEQ NUM\n", chunk->seq_num);
			i--;
		}
	}
	print_message(message);
	// free(message);
	close(c_socket);
}

int main()
{
	for(;;)
	{
		receive_message();
		send_message_final();
	}
}
