#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>

#include "discord.h"
#include "log.h"

static struct discord* client_g;
static int fd;
static const char term_char[1] = {1};
static char resp_buff[2048];

void on_ready(struct discord *client, const struct discord_ready *event) {
	log_info("Bot online as %s#%s", event->user->username, event->user->discriminator);
}

void on_message_create(struct discord *client, const struct discord_message *msg) {
	if(msg->author->bot) return;
	//if(msg->guild_id) return;
	if(strncmp("!s ", msg->content, 3) == 0) {
		printf("bot command received\n");
		char* cmd = msg->content + 3;
		int len = strlen(cmd);
		if(len > 254) {
			struct discord_create_message params = { .content = "" };
			discord_create_message(client, msg->channel_id, &params, NULL);
		}
		write(fd, cmd, len);
		write(fd, term_char, 1);
		int idx = 0;
		while(true) {
			int n = read(fd, resp_buff + idx, 1);
			if(n == 0) continue;
			if(resp_buff[idx] == 0 || idx == 2047) break;
			idx++;
		}
		resp_buff[idx] = 0;
		struct discord_create_message params = { .content = resp_buff };
		discord_create_message(client, msg->channel_id, &params, NULL);
		if(strcmp(cmd, "halt") == 0) {
			discord_shutdown(client);
			return;
		}
	}
}

int main(int argc, char *argv[]) {
	char *config_file;
	if(argc > 1) config_file = argv[1];
	else config_file = "./config.json";
	char *portname = "/dev/ttyS0";
	
	fd = open(portname, O_RDWR | O_NOCTTY | O_SYNC);
	if(fd < 0) {
		printf("Error opening serial port: %s\n", strerror(errno));
		return 1;
	}
	struct termios tty;
	if(tcgetattr(fd, &tty) != 0) {
		printf("Error from tcgetattr: %s\n", strerror(errno));
		return 1;
	}
	cfsetospeed(&tty, 38400);
	cfsetispeed(&tty, 38400);
	
	tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;
	
	tty.c_iflag &= ~IGNBRK;
	tty.c_lflag = 0;
	
	tty.c_oflag = 0;
	tty.c_cc[VMIN] = 0;
	tty.c_cc[VTIME] = 5;
	
	tty.c_iflag &= ~(IXON | IXOFF | IXANY);
	
	tty.c_cflag |= (CLOCAL | CREAD);
	
	tty.c_cflag &= ~(PARENB | PARODD);
	tty.c_cflag &= ~CSTOPB;
	tty.c_cflag &= ~CRTSCTS;
	
	if(tcsetattr(fd, TCSANOW, &tty) != 0) {
		printf("Error from tcsetattr: %s\n", strerror(errno));
		return 1;
	}
	ccord_global_init();
	client_g = discord_config_init(config_file);
	assert(NULL != client_g && "Couldn’t initialize client");
	discord_set_on_ready(client_g, &on_ready);
	discord_set_on_message_create(client_g, &on_message_create);
	discord_run(client_g);

	discord_cleanup(client_g);
	ccord_global_cleanup();
	return 0;
}
