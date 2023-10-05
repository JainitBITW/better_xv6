#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main() {
    int client_socket;
    struct sockaddr_in server_addr;
    socklen_t server_addr_len = sizeof(server_addr);
    char buffer[1024];

    // Create a UDP socket
    client_socket = socket(AF_INET, SOCK_DGRAM, 0);
    if (client_socket == -1) {
        perror("Socket creation error");
        exit(EXIT_FAILURE);
    }

    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(12345);
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1"); // Replace with server IP

    while (1) {
        // User input
        printf("Enter a message to send to the server (or 'exit' to quit): ");
        fgets(buffer, sizeof(buffer), stdin);

        // Send data to the server
        if (sendto(client_socket, buffer, strlen(buffer), 0, (struct sockaddr*)&server_addr, server_addr_len) == -1) {
            perror("Sendto error");
            exit(EXIT_FAILURE);
        }

        if (strcmp(buffer, "exit\n") == 0) {
            printf("Exiting...\n");
            break;
        }

        // Receive a response from the server
        memset(buffer, 0, sizeof(buffer));
        if (recvfrom(client_socket, buffer, sizeof(buffer), 0, NULL, NULL) == -1) {
            perror("Receivefrom error");
            exit(EXIT_FAILURE);
        }

        printf("Received from server: %s\n", buffer);
    }

    // Close the socket
    close(client_socket);

    return 0;
}
