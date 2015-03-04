# FT245_interface
This is a verilog module that can be used to communicate with the FT245 interface of an FTDI FT2232H.

The module utilises two FIFOs, of configurable length, which acts as a buffer between the FPGA and the FT2232H. With the module automatically carrying out the transactions to send and receive the data to and from the FT2232H (it should be noted the module places a preference on reading from the FT2232H over writing to it).

The interface to the FT2232H is designed to run from a 50 MHz. However, the interface to the module can use any frequency that is desired, as long as the *same_clocks* paramter is set to 0.
If a 50 MHz clock is being used to read and write into the FIFOs, it is better to set the *same_clocks* parameter to 1. By doing this, the module uses synchronous FIFOs instead of asynchronous, requiring less resources.
