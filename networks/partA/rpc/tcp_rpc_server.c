#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
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
    int server_socket, client_socketA, client_socketB;
    struct sockaddr_in server_addr, client_addrA, client_addrB;
    socklen_t client_addr_lenA = sizeof(client_addrA);
    socklen_t client_addr_lenB = sizeof(client_addrB);
    char bufferA[1024], bufferB[1024];

    // Create TCP socket
    server_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket == -1) {
        perror("Socket creation error");
        exit(EXIT_FAILURE);
    }

    // Server address configuration
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(4546); // Server listens on port 4545
    server_addr.sin_addr.s_addr = INADDR_ANY;

    // Bind the socket to the server address
    if (bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1) {
        perror("Bind error");
        exit(EXIT_FAILURE);
    }

    // Listen for incoming connections (maximum of 2 clients)
    if (listen(server_socket, 2) == -1) {
        perror("Listen error");
        exit(EXIT_FAILURE);
    }

    printf("Server is listening for clients...\n");

    // Accept a connection from clientA
    client_socketA = accept(server_socket, (struct sockaddr *)&client_addrA, &client_addr_lenA);
    if (client_socketA == -1) {
        perror("Accept error for clientA");
        exit(EXIT_FAILURE);
    }

    printf("ClientA connected...\n");

    // Accept a connection from clientB
    client_socketB = accept(server_socket, (struct sockaddr *)&client_addrB, &client_addr_lenB);
    if (client_socketB == -1) {
        perror("Accept error for clientB");
        exit(EXIT_FAILURE);
    }

    printf("ClientB connected...\n");

    while (1) {
        // Receive decisions from clientA
        memset(bufferA, 0, sizeof(bufferA));
        int recvA = recv(client_socketA, bufferA, sizeof(bufferA), 0);
        if (recvA == -1) {
            perror("Receive error for clientA");
            exit(EXIT_FAILURE);
        } else if (recvA == 0) {
            printf("ClientA disconnected.\n");
            break; // Exit the loop if clientA disconnects
        }

        // Receive decisions from clientB
        memset(bufferB, 0, sizeof(bufferB));
        int recvB = recv(client_socketB, bufferB, sizeof(bufferB), 0);
        if (recvB == -1) {
            perror("Receive error for clientB");
            exit(EXIT_FAILURE);
        } else if (recvB == 0) {
            printf("ClientB disconnected.\n");
            break; // Exit the loop if clientB disconnects
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

        send(client_socketA, resultA, strlen(resultA), 0);
        send(client_socketB, resultB, strlen(resultB), 0);

        // Prompt for another game
        char playAgainA[10], playAgainB[10];
        memset(playAgainA, 0, sizeof(playAgainA));
        memset(playAgainB, 0, sizeof(playAgainB));

        int recvPlayAgainA = recv(client_socketA, playAgainA, sizeof(playAgainA), 0);
        if (recvPlayAgainA == -1) {
            perror("Receive error for clientA");
            exit(EXIT_FAILURE);
        }
        int recvPlayAgainB = recv(client_socketB, playAgainB, sizeof(playAgainB), 0);
        if (recvPlayAgainB == -1) {
            perror("Receive error for clientB");
            exit(EXIT_FAILURE);
        }

        if (strcmp(playAgainA, "no\n") == 0 && strcmp(playAgainB, "no\n") == 0) {
            break;
        }
    }

    // Close the sockets
    close(client_socketA);
    close(client_socketB);
    close(server_socket);

    return 0;
}
