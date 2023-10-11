#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>

int main() {
    int client_socket;
    struct sockaddr_in server_addr;
    char buffer[1024];

    // Create a TCP socket
    client_socket = socket(AF_INET, SOCK_STREAM, 0);

    if (client_socket == -1) {
        perror("Socket creation error");
        exit(EXIT_FAILURE);
    }

    server_addr.sin_family = AF_INET;

    // Set the appropriate port for clientA or clientB
    int server_port = 4547; // For clientA, use 12345; for clientB, use 12346
    server_addr.sin_port = htons(server_port);
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1"); // Replace with server IP

    // Connect to the server
    if (connect(client_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) == -1) {
        perror("Connection error");
        exit(EXIT_FAILURE);
    }

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
        send(client_socket, buffer, strlen(buffer), 0);

        // Receive the result from the server
        memset(buffer, 0, sizeof(buffer));
        int recv_result = recv(client_socket, buffer, sizeof(buffer), 0);
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

        send(client_socket, playAgain, strlen(playAgain), 0);

        if (strcmp(playAgain, "no") == 0) {
            break;
        }
         else {
            char pa[1024];
            printf("Waiting for other player to decide...\n");
           if(recv(client_socket, pa, sizeof(pa), 0) <= 0){
               perror("Receive error");
               break;
           }
                //   printf("Other player decided: %s\n", pa);
            if( pa[0]=='n' && pa[1]=='o' ){
                printf("Server closed the connection. BYE BYE\n");
                break;
            }
           
            

        }
    }

    // Close the socket
    close(client_socket);

    return 0;
}
