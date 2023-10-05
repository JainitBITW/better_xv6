#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main() {
    int server_socket;
    struct sockaddr_in server_addr, client_addr;
    socklen_t client_addr_len = sizeof(client_addr);

    // Create a UDP socket
    server_socket = socket(AF_INET, SOCK_DGRAM, 0);
    if (server_socket == -1) {
        perror("Socket creation error");
        exit(EXIT_FAILURE);
    }

    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(12345);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    // Bind the socket to the server address
    if (bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) == -1) {
        perror("Bind error");
        exit(EXIT_FAILURE);
    }

    printf("Server is listening...\n");

    while (1) {
        char buffer[1024];
        char send_buffer[1024];

        // Receive a datagram from a client
        ssize_t recv_len = recvfrom(server_socket, buffer, sizeof(buffer), 0, (struct sockaddr*)&client_addr, &client_addr_len);
        if (recv_len == -1) {
            perror("Receivefrom error");
            exit(EXIT_FAILURE);
        }

        buffer[recv_len] = '\0'; // Null-terminate the received data
        printf("Received from client: %s\n", buffer);

        printf("Enter a message to send to the client (or 'exit' to quit): ");
        fgets(send_buffer, sizeof(send_buffer), stdin);

        // Send a response datagram to the client
        ssize_t send_len = sendto(server_socket, send_buffer, strlen(send_buffer), 0, (struct sockaddr*)&client_addr, client_addr_len);
        if (send_len == -1) {
            perror("Sendto error");
            exit(EXIT_FAILURE);
        }

        if (strcmp(send_buffer, "exit\n") == 0) {
            printf("Exiting...\n");
            break;
        }
    }

    // Close the server socket
    close(server_socket);

    return 0;
}
