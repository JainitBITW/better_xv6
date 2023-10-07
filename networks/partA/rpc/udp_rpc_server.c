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
    int server_socketA, server_socketB;
    struct sockaddr_in server_addrA, server_addrB, client_addrA, client_addrB;
    socklen_t client_addr_lenA = sizeof(struct sockaddr_in);
    socklen_t client_addr_lenB = sizeof(struct sockaddr_in);
    char bufferA[1024], bufferB[1024];

    // Create UDP sockets for clients A and B
    server_socketA = socket(AF_INET, SOCK_DGRAM, 0);
    if (server_socketA == -1) {
        perror("Socket creation error for clientA");
        exit(EXIT_FAILURE);
    }

    server_socketB = socket(AF_INET, SOCK_DGRAM, 0);
    if (server_socketB == -1) {
        perror("Socket creation error for clientB");
        exit(EXIT_FAILURE);
    }

    // Server addresses configuration for clients A and B
    server_addrA.sin_family = AF_INET;
    server_addrA.sin_port = htons(4546); // Server for client A listens on port 4546
    server_addrA.sin_addr.s_addr = INADDR_ANY;

    server_addrB.sin_family = AF_INET;
    server_addrB.sin_port = htons(4547); // Server for client B listens on port 4547
    server_addrB.sin_addr.s_addr = INADDR_ANY;

    // Bind the sockets to the respective server addresses
    if (bind(server_socketA, (struct sockaddr *)&server_addrA, sizeof(server_addrA)) == -1) {
        perror("Bind error for clientA");
        exit(EXIT_FAILURE);
    }

    if (bind(server_socketB, (struct sockaddr *)&server_addrB, sizeof(server_addrB)) == -1) {
        perror("Bind error for clientB");
        exit(EXIT_FAILURE);
    }

    printf("Server is listening for clients...\n");

    while (1) {
        // Receive decisions from client A
        memset(bufferA, 0, sizeof(bufferA));
        int recvA = recvfrom(server_socketA, bufferA, sizeof(bufferA), 0, (struct sockaddr *)&client_addrA, &client_addr_lenA);
        if (recvA == -1) {
            perror("Receive error for clientA");
            exit(EXIT_FAILURE);
        }

        // Receive decisions from client B
        memset(bufferB, 0, sizeof(bufferB));
        int recvB = recvfrom(server_socketB, bufferB, sizeof(bufferB), 0, (struct sockaddr *)&client_addrB, &client_addr_lenB);
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
        sendto(server_socketA, resultA, strlen(resultA), 0, (struct sockaddr *)&client_addrA, client_addr_lenA);
        sendto(server_socketB, resultB, strlen(resultB), 0, (struct sockaddr *)&client_addrB, client_addr_lenB);

        // Receive play again decision from client A
        memset(bufferA, 0, sizeof(bufferA));
        recvA = recvfrom(server_socketA, bufferA, sizeof(bufferA), 0, (struct sockaddr *)&client_addrA, &client_addr_lenA);
        if (recvA == -1) {
            perror("Receive error for clientA");
            exit(EXIT_FAILURE);
        }
        recvB = recvfrom(server_socketB, bufferB, sizeof(bufferB), 0, (struct sockaddr *)&client_addrB, &client_addr_lenB);
        if (recvB == -1) {
            perror("Receive error for clientB");
            exit(EXIT_FAILURE);
        }
        if(strcmp(bufferA, "yes")==0)
          {
            sendto(server_socketB, "yes", strlen("yes"), 0, (struct sockaddr *)&client_addrB, client_addr_lenB);

        }
        else
        {
            sendto(server_socketB, "no", strlen("no"), 0, (struct sockaddr *)&client_addrB, client_addr_lenB);
        }
        if(strcmp(bufferB, "yes")==0)
         {
            sendto(server_socketA, "yes", strlen("yes"), 0, (struct sockaddr *)&client_addrA, client_addr_lenA);

        }
        else
        {
            sendto(server_socketA, "no", strlen("no"), 0, (struct sockaddr *)&client_addrA, client_addr_lenA);
        }
      
        if( (strcmp(bufferA, "no")==0) || (strcmp(bufferB, "no")==0) )
        {
            printf("Server closed the connection. BYE BYE\n");
            break;
        }

    }

    // Close the sockets
    close(server_socketA);
    close(server_socketB);

    return 0;
}
