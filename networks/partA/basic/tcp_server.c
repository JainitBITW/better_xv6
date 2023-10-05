#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main()
{
	int server_socket, client_socket;
	struct sockaddr_in server_addr, client_addr;
	socklen_t client_addr_len = sizeof(client_addr);

	// Create a TCP socket
	server_socket = socket(AF_INET, SOCK_STREAM, 0);
	if(server_socket == -1)
	{
		perror("Socket creation error");
		exit(EXIT_FAILURE);
	}

	server_addr.sin_family = AF_INET;
	server_addr.sin_port = htons(12345);
	server_addr.sin_addr.s_addr = INADDR_ANY;

	// Bind the socket to the server address
	if(bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) == -1)
	{
		perror("Bind error");
		exit(EXIT_FAILURE);
	}

	// Listen for incoming connections
	if(listen(server_socket, 5) == -1)
	{
		perror("Listen error");
		exit(EXIT_FAILURE);
	}

	printf("Server is listening...\n");

	client_socket = accept(server_socket, (struct sockaddr*)&client_addr, &client_addr_len);
	if(client_socket == -1)
	{
		perror("Accept error");
		exit(EXIT_FAILURE);
	}
	while(1)
	{
		char buffer[1024];
		// Accept a connection from a client
		char send_buffer[1024];
		if(recv(client_socket, buffer, sizeof(buffer), 0) == -1)
		{
			perror("Receive error");
			exit(EXIT_FAILURE);
		}
		printf("Received from client: %s\n", buffer);
		printf("Enter a message to send to the server (or 'exit' to quit): ");
		fgets(send_buffer, sizeof(send_buffer), stdin);
		// Receive data from the client
		memset(buffer, 0, sizeof(buffer));


		// Send a response to the client
		
		if(send(client_socket, send_buffer, strlen(send_buffer), 0) == -1)
		{
			perror("Send error");
			exit(EXIT_FAILURE);
		}

		// Close the client socket
	}

	close(client_socket);
	// Close the server socket (never reached in this example)
	close(server_socket);

	return 0;
}
