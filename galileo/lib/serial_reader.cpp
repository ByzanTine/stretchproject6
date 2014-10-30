#include <iostream>
#include <sstream>
#include <string>
#include <stdlib.h>

#include <fcntl.h> 
#include <termios.h> 
#include <unistd.h>


const std::string USB_SERIAL_PORT = "/dev/cu.usbmodem1421";

int init_serial_input (const char *);
int read_serial_int(int fd);

int main()
{
	int port_fd = init_serial_input(USB_SERIAL_PORT.c_str());
	if (port_fd == -1)
	{
		std::cerr << "Failed to initialize serial input." << std::endl;
		return 0;
	}

	while (true)
	{
        std::stringstream strstm;
		int pin = read_serial_int(port_fd);
		int reading = read_serial_int(port_fd);
		int output = 0;
		output += (pin << 8);
		output += reading;
        
        char cha1, cha2;
        cha1 = (char)(((int)'0')+pin);
        cha2 = (char)(((int)'0')+reading);
//		std::cout << std::hex << output << std::endl;
        
        strstm << "echo '";
        strstm << cha1;
        strstm << cha2;
        strstm <<  "' | nc -4u -w1 127.0.0.1 21368";
        //printf("%i,%i , %s", pin, reading, strstm.str().c_str());
        system(strstm.str().c_str());
	}

	return 0;
}
 
int read_serial_int(int fd)
{
	std::string str = "";
	char c = '\0';

	read(fd, &c, 1);
	while (isspace(c))
	{
		read(fd, &c, 1);
	}
	while (!isspace(c))
	{
		str.push_back(c);
		read(fd, &c, 1);
	}
	return std::stoi(str);
}

int init_serial_input (const char * port) {   
  int fd = 0;   
  struct termios options;   

  fd = open(port, O_RDWR | O_NOCTTY | O_NDELAY);   
  if (fd == -1)     
    return fd;   
  fcntl(fd, F_SETFL, 0);    // clear all flags on descriptor, enable direct I/O   
  tcgetattr(fd, &options);   // read serial port options   
  // enable receiver, set 8 bit data, ignore control lines   
  options.c_cflag |= (CLOCAL | CREAD | CS8);    
  // disable parity generation and 2 stop bits   
  options.c_cflag &= ~(PARENB | CSTOPB);  
  // set the new port options   
  tcsetattr(fd, TCSANOW, &options);      
  return fd; 
}
