__author__ = 'Vescent Photonics'
__version__ = '1.1'
# Modifcations made for Python 3.4 compatibility

import threading
import queue
import serial
from serial.tools import list_ports
import time
import logging


class SerialPortThread(threading.Thread):
    """ A thread for monitoring a COM port. The COM port is
        opened when the thread is started.

        :param send_q:
            Queue for data to transmit.

        :param receive_q:
            Queue for received data.

        :param error_q:
            Queue for error messages. In particular, if the
            serial port fails to open for some reason, an error
            is placed into this queue.

        :param port_num:
            The COM port to open. Must be recognized by the
            system.

        :param port_baud/stopbits/parity:
            Serial communication parameters

        :param port_timeout:
            The timeout used for reading the COM port. If this
            value is low, the thread will return data in finer
            grained chunks, with more accurate timestamps, but
            it will also consume more CPU.

        :param debug:
            Set to True to enable timestamps to be added to each transaction
            on the error queue.
    """

    def __init__(self,
                 send_q,
                 receive_q,
                 error_q,
                 port_num,
                 port_baud,
                 port_stopbits=serial.STOPBITS_ONE,
                 port_parity=serial.PARITY_NONE,
                 port_timeout=0.1,
                 debug=False):
        threading.Thread.__init__(self)

        self.serial_port = None
        self.serial_arg = dict(port=port_num,
                               baudrate=port_baud,
                               stopbits=port_stopbits,
                               parity=port_parity,
                               timeout=port_timeout)
        self.debug = debug
        self.send_q = send_q
        self.receive_q = receive_q
        self.error_q = error_q

        self.alive = threading.Event()
        self.alive.set()

    def run(self):
        try:
            if self.serial_port:
                self.serial_port.close()
            self.serial_port = serial.Serial(**self.serial_arg)
        except serial.SerialException as e:
            self.error_q.put(str(e))
            return

        # Restart the clock
        if self.debug is True:
            time.clock()

        while self.alive.isSet():
            try:
                data = self.send_q.get(True, 0.05)

                # This is for debugging only
                if self.debug is True:
                    timestamp = time.clock()
                    self.error_q.put((data, timestamp))

                # Write serial data
                if 'command' in data:
                    self.serial_port.write(bytes(data['command'], 'ascii'))  # PySerial >2.5
                    # self.serial_port.write(data['command'])
                else:
                    continue

                # Wait up to timeout period for response
                response = self.serial_port.read(1)
                response += self.serial_port.readline()

                if len(data) > 0:
                    # This is for debugging only
                    if self.debug is True:
                        timestamp = time.clock()
                        self.error_q.put((data, timestamp))

                    data['result'] = response.decode('ascii')  # PySerial >2.5
                    # data['result'] = response
                    self.receive_q.put(data)

                    # The following allows blocking on the main thread to implemented
                    # by using Queue.join() - Ex. self.send_q.join()
                    self.send_q.task_done()
            except queue.Empty:
                continue

        # clean up
        if self.serial_port:
            self.serial_port.close()

    def join(self, timeout=None):
        self.alive.clear()
        threading.Thread.join(self, timeout)


class Connection(object):
    """Creates a connection object to send commands to an ICE box.
    :param log: Set to True to print log information to the standard out.
    :param size: Maximum number of items queue can hold. Insertions
    will block when queue is full.
    """

    def __init__(self, log=False, size=20):
        self.__send_q = queue.Queue(size)
        self.__receive_q = queue.Queue(size)
        self.async_q = queue.Queue(size)
        self.__error_q = queue.Queue(size)
        self.__serial_connected = False
        self.__com_monitor = None
        self.logging = log

    def connect(self, port, baud=115200, timeout=0.1):
        """
        Opens a serial connection to an ICE box.
        :param port: Name of COM port for ICE virtual serial port.
        :param baud: Baud rate of serial connection. Default is 115200.
        :param timeout: Timeout in seconds to wait if serial port doesn't respond.
        :return: Returns an error string if problem connecting, otherwise None.
        """
        if self.__com_monitor is not None:
            return

        # Initialize worker thread
        self.__com_monitor = SerialPortThread(
            self.__send_q,
            self.__receive_q,
            self.__error_q,
            port,
            baud,
            port_timeout=timeout,
            debug=False)
        self.__com_monitor.start()

        # Check for connection error from thread
        com_error = self.get_item_from_queue(self.__error_q)
        if com_error is not None:
            self.disconnect()  # clean up worker thread
            return com_error
        else:
            self.__serial_connected = True
            return None

    def is_connected(self):
        """
        Returns True if the serial port is connected to the ICE box.
        :return: True if connected.
        """
        return self.__serial_connected

    def send(self, command, blocking=True, callback=None):
        """
        Sends a serial string to the ICE box. Can either be a blocking (default)
        command or be non-blocking and accept a callback function to call.
        :param command: String of command to send to ICE. No line returns necessary.
        :param blocking: True to return only after response is received. Otherwise
        is non-blocking and will put command and callback on the send queue.
        :param callback: Reference to function to call after a non-blocking command
        call returns. Callback function must accept a single data parameter which will
        contain the response string from the ICE box.
        :return: If blocking is True, it will return the string response from the ICE
        box. Otherwise, it will return None if non-blocking mode is used.
        """
        if self.__serial_connected is False:
            return None

        if blocking is True:
            # Wait for any prior non-blocking queue items to finish
            self.__send_q.join()

        if self.logging:
            logging.debug('TX: ' + command)

        # Add line return to all commands
        command += '\r\n'
        data = {
            'command': command,
            'callback': callback,
            'result': None
        }
        self.__send_q.put(data, True, 2.0)

        if blocking is True:
            result = None
            self.__send_q.join()

            responses = list(self.get_all_from_queue(self.__receive_q))

            # Sort through and pick off any unprocessed async responses
            # and set them aside in a separate queue for get_all_responses()
            # to process. We match first non-async result that matches our
            # command and throw away any non-matching non-async responses
            # to keep the receive queue clean in case a response was dropped.
            for response in responses:
                if self.logging:
                    logging.debug('RX: ' + response['result'].rstrip())

                if response['callback'] is not None:
                    self.async_q.put(response)
                elif response['command'] is command:
                    result = response['result'].rstrip()

            return result
        else:
            return None

    def get_response(self):
        """
        Gets a command response off of the receive queue.
        :return: Returns either response object or None if queue was empty.
        """
        return self.get_item_from_queue(self.__receive_q)

    def get_all_responses(self):
        """
        Gets all command responses off of the receive queue.
        :return: Returns a list of all responses in queue.
        """
        data = list(self.get_all_from_queue(self.__receive_q))
        data.extend(list(self.get_all_from_queue(self.async_q)))
        return data

    def get_error(self):
        """
        Gets a command response off of the error queue.
        :return: Returns either error object or None if queue was empty.
        """
        return self.get_item_from_queue(self.__error_q)

    def process_responses(self):
        """
        This function can be called periodically by the application thread to
        get and process all of the callbacks of non-blocking commands off of the
        receive queue. The callback functions of non-blocking commands don't execute
        until this function is called. It should typically be called on a GUI thread
        timer every 100 milliseconds or so.
        :return: None
        """
        data = self.get_all_responses()

        for result in data:
            if self.logging:
                logging.debug('RX: ' + result['result'].rstrip())
                logging.debug(result)
            if result['callback'] is not None:
                response = result.get('result', None).rstrip()
                result['callback'](response)

    def disconnect(self):
        """
        Cleans up and kills serial connection thread and releases serial port.
        Should be called before exiting the program or destroying this object.
        :return: None
        """
        self.__serial_connected = False
        self.__send_q.queue.clear()
        self.__receive_q.queue.clear()
        self.__error_q.queue.clear()

        if self.__com_monitor is not None:
            self.__com_monitor.join(0.01)
            self.__com_monitor = None

    def __del__(self):
        # Cleanup and kill thread
        if self.__com_monitor is not None:
            self.__com_monitor.join(0.01)
            self.__com_monitor = None

    def list_serial_ports(self):
        """
        Helper function to get a list of available serial ports. Uses
        PySerial (version 2.7 or greater) serial tools to get ports on
        Windows, Linux, and Mac OSX.
        :return: A list containing tuples of three strings corresponding to
        the port name, human description, and hardware ID.
        """
        return list(list_ports.comports())

    def get_all_from_queue(self, Q):
        """ Generator to yield one after the others all items
            currently in the queue Q, without any waiting.
        """
        try:
            while True:
                yield Q.get_nowait()
        except queue.Empty:
            raise StopIteration

    def get_item_from_queue(self, Q, timeout=0.01):
        """ Attempts to retrieve an item from the queue Q. If Q is
            empty, None is returned.

            Blocks for 'timeout' seconds in case the queue is empty,
            so don't use this method for speedy retrieval of multiple
            items (use get_all_from_queue for that).
        """
        try:
            item = Q.get(True, timeout)
        except queue.Empty:
            return None

        return item


def _main():
    """
    Main function only to be called for testing this library. Also provides
    a usage example to how to integrate class into main program. The "port"
    variable needs to be changed to the correct COM port before this is run.
    :return: None
    """
    print('Starting tests of ' + __file__)

    # Instantiate a connection object to communicate with ICE. Logging
    # is set to True only for testing purposes.
    ice = Connection(log=True)
    port = 'COM3'  # Change to correct COM port

    # Print list of system COM ports
    print(ice.list_serial_ports())

    # Connect to ICE box
    result = ice.connect(port)

    # If result is not None, then an error occurred while trying
    # to open the serial port.
    if result is not None:
        print(result)
    else:
        print('Serial connected to ' + port)

    print('Sending blocking #version command...')
    # This is a blocking command and will block execution until either
    # the ICE box responds of the serial port times out.
    data = ice.send('#version')

    if data is not None:
        print(data)
    else:
        print('Error: Data was none')

    print('Sending non-blocking #status and #version commands...')
    # These are non-blocking commands and return immediately. The result
    # won't be available until process_responses() is called and the response
    # strings are passed into the specified callback function.
    ice.send('#status', blocking=False, callback=_callbackFn)
    ice.send('#version', blocking=False, callback=_callbackFn)

    print('Waiting 1 second...')
    time.sleep(1)

    # Process the callback functions of all non-blocking commands
    # that have returned.
    ice.process_responses()

    # Disconnect and release serial port so other programs can access it.
    ice.disconnect()
    print('All tests done.')


def _callbackFn(data):
    """
    Example of a callback function.
    :param data: Response string from ICE will be passed into this variable.
    :return: None.
    """
    print("callback response: " + str(data))


# Only executes if this module is run directly instead of imported.
if __name__ == "__main__":
    _main()
