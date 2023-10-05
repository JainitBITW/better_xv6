#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main() {
    int client_socket;
    struct sockaddr_in server_addr;
    

    // Create a TCP socket
    client_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (client_socket == -1) {
        perror("Socket creation error");
        exit(EXIT_FAILURE);
    }

    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(12345);
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1"); // Replace with server IP

    // Connect to the server
    if (connect(client_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) == -1) {
        perror("Connection error");
        exit(EXIT_FAILURE);
    }

    while (1) {
        // User input
        char buffer[1024];
        printf("Enter a message to send to the server (or 'exit' to quit): ");
        fgets(buffer, sizeof(buffer), stdin);

        // Send data to the server
        if (send(client_socket, buffer, strlen(buffer), 0) == -1) {
            perror("Send error");
            exit(EXIT_FAILURE);
        }

        if (strcmp(buffer, "exit\n") == 0) {
            printf("Exiting...\n");
            break;
        }

        // Receive a response from the server
        memset(buffer, 0, sizeof(buffer));
        if (recv(client_socket, buffer, sizeof(buffer), 0) == -1) {
            perror("Receive error");
            exit(EXIT_FAILURE);
        }

        printf("Received from server: %s\n", buffer);
    }

    // Close the socket
    close(client_socket);

    return 0;
}
