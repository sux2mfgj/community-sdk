#pragma once

enum class ardrone_actions
{
	take_off,
	landing,
	hover,
	forward,
	right,
	left,
	continure,
};

auto init_drone(void) -> void;
auto closing_drone(void) -> void;
auto ardrone_command(ardrone_actions action) -> void;

/*
auto landing() -> void;
auto take_off() -> void;
auto hovver() -> void;
auto forward() -> void;
*/
