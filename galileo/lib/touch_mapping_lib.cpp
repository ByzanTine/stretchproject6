#include "touch_mapping_lib.h"

Touch_map::Touch_map (int _pin, 
	void (*_notify_vol)(int pin, double vol), int (*_get_val)(int pin))
	: pin(_pin), notify_vol(_notify_vol), get_val(_get_val),
	  base_reading(0), max_reading(1023)
	{}

Touch_map::Touch_map (int _pin, 
	void (*_notify_vol)(int pin, double vol), int (*_get_val)(int pin),
	int _base_reading)
	: pin(_pin), notify_vol(_notify_vol), get_val(_get_val),
	  base_reading(_base_reading), max_reading(1023)
	{}

Touch_map::Touch_map (int _pin, 
	void (*_notify_vol)(int pin, double vol), int (*_get_val)(int pin),
	int _base_reading, int _max_reading)
	: pin(_pin), notify_vol(_notify_vol), get_val(_get_val),
	  base_reading(_base_reading), max_reading(_max_reading)
	{}

void Touch_map::update()
{
	int reading = get_val(pin);
	// make sure reading is in specified range
	reading = reading < base_reading ? base_reading : reading;
	reading = reading > max_reading ? max_reading : reading;
	double vol = double (reading - base_reading)
		/ double (max_reading - base_reading);
	notify_vol(pin, vol);
}