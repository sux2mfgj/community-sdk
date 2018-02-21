#include <iostream>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include <memory>
#include "drone.hpp"

const auto ardrone_port = 5556;
const auto ardrone_ip_addr = "192.168.1.1";

struct sockaddr_in addr;
int seq_num = 1;
int sock = -1;
bool is_flying = false;
void (* prev_function)();

template <typename... Args>
auto string_format(const std::string& format, Args... args) -> std::string
{
	auto size = snprintf(nullptr, 0, format.c_str(), args...) + 1;
	std::unique_ptr<char[]> buf(new char[size]);
	snprintf(buf.get(), size, format.c_str(), args...);
	return std::string(buf.get(), buf.get() + size - 1);
}

static auto send_to_ardrone(std::string str) 
	-> void
{
	sendto(sock, str.c_str(), str.size(), 0, (struct sockaddr*)&addr,
			sizeof(struct sockaddr));
	//std::cout << str << std::endl;
	usleep(100000);
}

static auto _take_off() -> void
{
	is_flying = true;
	std::string format = "AT*REF=%u,290718208\r";
	auto content = string_format(format, seq_num++);
	send_to_ardrone(content);
}

static auto _landing() -> void
{
	std::string format = "AT*REF=%u,290717696\r";
	auto content = string_format(format, seq_num++);
	send_to_ardrone(content);
}

static auto _hover() -> void
{
	auto format = "AT*PCMD=%u,0,%d,%d,%d,%d\r";
	auto content = string_format(format, seq_num++, 0, 0, 0, 0, 0);
	send_to_ardrone(content);
}

static auto _forward() -> void
{
	auto format = "AT*PCMD=%u,1,%d,%d,%d,%d\r";
	auto content = string_format(format, seq_num++, 0, -1102263091, 0, 0, 0);
	send_to_ardrone(content);
}

static auto _right() -> void
{
	auto format = "AT*PCMD=%u,1,%d,%d,%d,%d\r";
	auto content = string_format(format, seq_num++, 1102263091, 0, 0, 0, 0);
	send_to_ardrone(content);
}

static auto _left() -> void
{
	auto format = "AT*PCMD=%u,1,%d,%d,%d,%d\r";
	auto content = string_format(format, seq_num++, -1102263091, 0, 0, 0, 0);
	send_to_ardrone(content);
}
void init_drone(void)
{
	sock = socket(AF_INET, 
			SOCK_DGRAM, IPPROTO_UDP);
	addr.sin_family = AF_INET;
	addr.sin_port = htons(ardrone_port);
	addr.sin_addr.s_addr = 
		inet_addr(ardrone_ip_addr);
}

void closing_drone(void)
{
	_landing();
	close(sock);
}

auto ardrone_command(ardrone_actions action) -> void
{
	switch(action)
	{
		case ardrone_actions::take_off:
			prev_function = _take_off;
			break;
		case ardrone_actions::landing:
			prev_function = _landing;
			break;
		case ardrone_actions::hover:
			prev_function = _hover;
			break;
		case ardrone_actions::forward:
			if(!is_flying)
			{
				prev_function = _take_off;
				is_flying = true;
			}
			else 
			{
				prev_function = _forward;
			}
			break;
		case ardrone_actions::right:
			prev_function = _right;
			break;
		case ardrone_actions::left:
			prev_function = _left;
			break;
		case ardrone_actions::continure:
			if(!is_flying)
			{
				return;
			}
			break;
	}
	prev_function();
}
