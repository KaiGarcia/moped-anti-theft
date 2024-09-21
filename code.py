import time
import board
import busio
import adafruit_mma8451
from adafruit_ble import BLERadio
from adafruit_ble.advertising.standard import ProvideServicesAdvertisement
from adafruit_ble.services.nordic import UARTService

# Initialize I2C bus and MMA8451 accelerometer
i2c = busio.I2C(board.SCL, board.SDA)
mma = adafruit_mma8451.MMA8451(i2c)

# Initialize BLE
ble = BLERadio()
uart = UARTService()  # Using UART service to send data
advertisement = ProvideServicesAdvertisement(uart)

print("BLE UART Server is starting up...")

while True:
    # Start advertising the BLE service
    ble.start_advertising(advertisement)

    print("Waiting for a connection...")
    while not ble.connected:
        time.sleep(0.1)  # Wait for a connection

    print("Connected!")
    ble.stop_advertising()

    while ble.connected:
        # Read acceleration data from MMA8451
        accel_x, accel_y, accel_z = mma.acceleration

        # Create a string with the accelerometer data
        accel_data = f"X: {accel_x:.2f}, Y: {accel_y:.2f}, Z: {accel_z:.2f}"

        # Send the accelerometer data over BLE
        print(f"Sent: {accel_data}")

        if ( ( abs(accel_x) > 3 ) or ( abs(accel_y) > 3 ) or ( abs(accel_z) > 10 ) ):
          uart.write(f'Movement Detected!\n')
          print(f'Movement Detected sent')

        # Add a delay to avoid flooding the connection
        time.sleep(1)
