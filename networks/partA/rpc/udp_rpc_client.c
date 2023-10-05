#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

int main() {
    int client_socket;
    struct sockaddr_in server_addr;
    char buffer[1024];

    // Create a UDP socket
    client_socket = socket(AF_INET, SOCK_DGRAM, 0);

    if (client_socket == -1) {
        perror("Socket creation error");
        exit(EXIT_FAILURE);
    }

    server_addr.sin_family = AF_INET;

    // Set the appropriate port for clientA or clientB
    int server_port = 4546; // For clientA, use 12345; for clientB, use 12346
    server_addr.sin_port = htons(server_port);
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1"); // Replace with server IP

    while (1) {
        // User input for rock (0), paper (1), or scissors (2)
        int decision;
        
        printf("Enter your choice (0 for Rock, 1 for Paper, 2 for Scissors): ");
        scanf("%d", &decision);

        // Check if the input is valid
        if (decision < 0 || decision > 2) {
            printf("Invalid choice. Please enter 0, 1, or 2.\n");
            continue; // Skip sending invalid input to the server
        }

        // Send the decision to the server
        sprintf(buffer, "%d", decision);
        if (sendto(client_socket, buffer, strlen(buffer), 0, (struct sockaddr*)&server_addr, sizeof(server_addr)) == -1) {
            perror("Sendto error");
            exit(EXIT_FAILURE);
        }

        // Receive the result from the server
        memset(buffer, 0, sizeof(buffer));
        socklen_t server_addr_len = sizeof(server_addr);
        int recv_result = recvfrom(client_socket, buffer, sizeof(buffer), 0, (struct sockaddr*)&server_addr, &server_addr_len);
        if (recv_result <= 0) {
            if (recv_result == 0) {
                printf("Server closed the connection.\n");
            } else {
                perror("Receive error");
            }
            break; // Exit the loop when the server closes the connection or an error occurs.
        }

        // Display the result
        printf("Result: %s\n", buffer);

        // Prompt for another game
        char playAgain[10];
        printf("Do you want to play again? (yes/no): ");
        scanf("%s", playAgain);

        sendto(client_socket, playAgain, strlen(playAgain), 0, (struct sockaddr*)&server_addr, sizeof(server_addr));

        if (strcmp(playAgain, "no") == 0) {
            break;
        }
        if( recvfrom(client_socket, buffer, sizeof(buffer), 0, (struct sockaddr*)&server_addr, &server_addr_len) == -1) {
            perror("Receive error");
            exit(EXIT_FAILURE);
        }
        if(strcmp(buffer, "exit") == 0) {
            printf("Server closed the connection.\n");
            break;
        }
    }

    // Close the socket
    close(client_socket);

    return 0;
}
