import CHIP_IO.GPIO as GPIO
import fb

GPIO.setup("U14_13", GPIO.IN)
GPIO.setup("U14_14", GPIO.IN)
GPIO.setup("U14_15", GPIO.IN)
GPIO.setup("U14_16", GPIO.IN)
GPIO.setup("U14_17", GPIO.IN)

value = 0

if GPIO.input("U14_13"):
	value = value + 1 
if GPIO.input("U14_14"):
	value = value + 2 
if GPIO.input("U14_15"):
	value = value + 4 
if GPIO.input("U14_16"):
	value = value + 8 

print(value)
