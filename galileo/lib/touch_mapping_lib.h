class Touch_map {
	public:
		// constructs Touch_map using base_reading = 0; max_reading = 1023
		Touch_map(int _pin, void (*_notify_vol)(double vol), 
			int (*_get_val)(int pin));
		// constructs Touch_map using max_reading = 1023
		Touch_map(int _pin, void (*_notify_vol)(double vol),
			int (*_get_val)(int pin), int _base_reading);
		// full constructor
		Touch_map(int _pin, void (*_notify_vol)(double vol),
			int (*_get_val)(int pin), int _base_reading, int _max_reading);
		// updates the internal state of Touch_map object; calls notify_vol
		void update();
	private:
		// the pin from which we get reading 
		int pin;
		// base and max reading values
		int base_reading;
		int max_reading;
		// callback used by update; vol < 0 is proportion of max_vol
		void (*notify_vol)(double vol);
		// function used to read pin value
		int (*get_val)(int pin);	
};