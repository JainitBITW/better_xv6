#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

// Function to determine the game result
// 0 -> Rock (R) | 1 -> Paper (P) | 2 -> Scissors (S)
int getGameResult(int decisionA, int decisionB) {
    // for player A (clientA)
    if (decisionA == decisionB) {
        return 0;
    } else if ((decisionA == 0 && decisionB == 2) || (decisionA == 1 && decisionB == 0) || (decisionA == 2 && decisionB == 1)) {
        return 1;
    } else {
        return -1;
    }
}

int main() {
    int server_socket;
    struct sockaddr_in server_addr, client_addrA, client_addrB;
    socklen_t client_addr_lenA = sizeof(client_addrA);
    socklen_t client_addr_lenB = sizeof(client_addrB);
    char bufferA[1024], bufferB[1024];

    // Create UDP socket
    server_socket = socket(AF_INET, SOCK_DGRAM, 0);
    if (server_socket == -1) {
        perror("Socket creation error");
        exit(EXIT_FAILURE);
    }

    // Server address configuration
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(4546); // Server listens on port 4546
    server_addr.sin_addr.s_addr = INADDR_ANY;

    // Bind the socket to the server address
    if (bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1) {
        perror("Bind error");
        exit(EXIT_FAILURE);
    }

    printf("Server is listening for clients...\n");

    while (1) {
        // Receive decisions from clientA
        memset(bufferA, 0, sizeof(bufferA));
        int recvA = recvfrom(server_socket, bufferA, sizeof(bufferA), 0, (struct sockaddr *)&client_addrA, &client_addr_lenA);
        if (recvA == -1) {
            perror("Receive error for clientA");
            exit(EXIT_FAILURE);
        }

        // Receive decisions from clientB
        memset(bufferB, 0, sizeof(bufferB));
        int recvB = recvfrom(server_socket, bufferB, sizeof(bufferB), 0, (struct sockaddr *)&client_addrB, &client_addr_lenB);
        if (recvB == -1) {
            perror("Receive error for clientB");
            exit(EXIT_FAILURE);
        }

        // Compare decisions and determine the result
        int decisionA = atoi(bufferA);
        int decisionB = atoi(bufferB);

        char resultA[10], resultB[10];
        int gameResult = getGameResult(decisionA, decisionB);
        if (gameResult == 0) {
            strcpy(resultA, "Draw");
            strcpy(resultB, "Draw");
        } else if (gameResult == 1) {
            strcpy(resultA, "Win");
            strcpy(resultB, "Lost");
        } else {
            strcpy(resultA, "Lost");
            strcpy(resultB, "Win");
        }

        // Send results to clients
        sendto(server_socket, resultA, strlen(resultA), 0, (struct sockaddr *)&client_addrA, client_addr_lenA);
        sendto(server_socket, resultB, strlen(resultB), 0, (struct sockaddr *)&client_addrB, client_addr_lenB);

        // Receive "play again" response from clients
        memset(bufferA, 0, sizeof(bufferA));
        memset(bufferB, 0, sizeof(bufferB));
        int recvPlayAgainA = recvfrom(server_socket, bufferA, sizeof(bufferA), 0, (struct sockaddr *)&client_addrA, &client_addr_lenA);
        int recvPlayAgainB = recvfrom(server_socket, bufferB, sizeof(bufferB), 0, (struct sockaddr *)&client_addrB, &client_addr_lenB);

        if (recvPlayAgainA == -1 || recvPlayAgainB == -1) {
            perror("Receive error for play again response");
            exit(EXIT_FAILURE);
        }

        // Check if both players want to play again
        if (strcmp(bufferA, "no") == 0 || strcmp(bufferB, "no") == 0) {
            printf("At least one player doesn't want to play again. Exiting the game.\n");
            if (strcmp(bufferA, "no") == 0) {
                printf("ClientA disconnected.\n");
            }
            if (strcmp(bufferB, "no") == 0) {
                printf("ClientB disconnected.\n");
            }
            if(strcmp(bufferA,"yes") == 0){
                sendto(server_socket, "exit", strlen("exit"), 0, (struct sockaddr *)&client_addrA, client_addr_lenA);
            }
            if(strcmp(bufferB,"yes") == 0){
                sendto(server_socket, "exit", strlen("exit"), 0, (struct sockaddr *)&client_addrB, client_addr_lenB);
            }
            break;
        }
        else{
            sendto(server_socket, "continue", strlen("continue"), 0, (struct sockaddr *)&client_addrA, client_addr_lenA);
            sendto(server_socket, "continue", strlen("continue"), 0, (struct sockaddr *)&client_addrB, client_addr_lenB);
        }

    }

    // Close the socket
    close(server_socket);

    return 0;
}
