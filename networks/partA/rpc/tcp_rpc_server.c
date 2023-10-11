#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

int getGameResult(int decisionA, int decisionB) {
    if (decisionA == decisionB) {
        return 0; // Draw
    } else if ((decisionA == 0 && decisionB == 2) || (decisionA == 1 && decisionB == 0) || (decisionA == 2 && decisionB == 1)) {
        return 1; // Client A wins
    } else {
        return -1; // Client B wins
    }
}

int main() {
    int server_socketA, server_socketB;
    int client_socketA, client_socketB;
    struct sockaddr_in server_addrA, server_addrB;
    struct sockaddr_in client_addrA, client_addrB;
    socklen_t client_addr_lenA = sizeof(struct sockaddr_in);
    socklen_t client_addr_lenB = sizeof(struct sockaddr_in);

    char bufferA[1024], bufferB[1024];

    // Create two TCP sockets, one for each client
    server_socketA = socket(AF_INET, SOCK_STREAM, 0);
    server_socketB = socket(AF_INET, SOCK_STREAM, 0);
    
    if (server_socketA == -1 || server_socketB == -1) {
        perror("Socket creation error");
        exit(EXIT_FAILURE);
    }

    // Server address configuration for client A
    server_addrA.sin_family = AF_INET;
    server_addrA.sin_port = htons(4546); // Server for client A listens on port 4546
    server_addrA.sin_addr.s_addr = INADDR_ANY;

    // Server address configuration for client B
    server_addrB.sin_family = AF_INET;
    server_addrB.sin_port = htons(4547); // Server for client B listens on port 4547
    server_addrB.sin_addr.s_addr = INADDR_ANY;

    // Bind the sockets to their respective server addresses
    if (bind(server_socketA, (struct sockaddr *)&server_addrA, sizeof(server_addrA)) == -1) {
        perror("Bind error for client A");
        exit(EXIT_FAILURE);
    }

    if (bind(server_socketB, (struct sockaddr *)&server_addrB, sizeof(server_addrB)) == -1) {
        perror("Bind error for client B");
        exit(EXIT_FAILURE);
    }

    // Listen for incoming connections from clients A and B
    if (listen(server_socketA, 1) == -1 || listen(server_socketB, 1) == -1) {
        perror("Listen error");
        exit(EXIT_FAILURE);
    }

    printf("Server is listening for clients...\n");

    // Accept connections from clients A and B
    client_socketA = accept(server_socketA, (struct sockaddr *)&client_addrA, &client_addr_lenA);
    client_socketB = accept(server_socketB, (struct sockaddr *)&client_addrB, &client_addr_lenB);


    while (1) {
        // Receive decisions from client A
        memset(bufferA, 0, sizeof(bufferA));
        int recvA = recv(client_socketA, bufferA, sizeof(bufferA), 0);
        if (recvA == -1) {
            perror("Receive error for clientA");
            exit(EXIT_FAILURE);
        }

        // Receive decisions from client B
        memset(bufferB, 0, sizeof(bufferB));
        int recvB = recv(client_socketB, bufferB, sizeof(bufferB), 0);
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

        // Send results to client A and client B
        send(client_socketA, resultA, strlen(resultA), 0);
        send(client_socketB, resultB, strlen(resultB), 0);

        // Receive play again decision from client A
        memset(bufferA, 0, sizeof(bufferA));
        recvA = recv(client_socketA, bufferA, sizeof(bufferA), 0);
        if (recvA == -1) {
            perror("Receive error for clientA");
            exit(EXIT_FAILURE);
        }

        memset(bufferB, 0, sizeof(bufferB));
        recvB = recv(client_socketB, bufferB, sizeof(bufferB), 0);
        if (recvB == -1) {
            perror("Receive error for clientB");
            exit(EXIT_FAILURE);
        }

       //send them to the other player
        send(client_socketA, bufferB, strlen(bufferB), 0);
        send(client_socketB, bufferA, strlen(bufferA), 0);


        if ((strcmp(bufferA, "no") == 0) || (strcmp(bufferB, "no") == 0)) {
            printf("Server closed the connection. BYE BYE\n");
            break;
        }
    }

    // Close the sockets
    close(client_socketA);
    close(client_socketB);
    close(server_socketA);
    close(server_socketB);
    

    return 0;
}
