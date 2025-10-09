# AXI4-Lite UART Slave
## AXI4-Lite UART Slave - Overview
This project implements a UART, using FIFO buffering, with CSRs and AXI4-Lite interface.
## Features

● AXI4-Lite interface

● Configurable Data Width: supports 5 to 8 data bits.

● Programmable Baud Rates

● FIFO RX/TX: Seperate 8-byte FIFOs for transmit and recieve data buffering

● Parity Support

● Status Monitoring

## File Structure

● async_fifo_tb.vhd - Top-level entity for the asynchronous fifo

● AXI4-Lite_UART_Slave.vhd - AXI4-Lite UART wrapper

● AXI4-Lite_Slave.vhd - Implements the interface protocol

● UART_Reciever.vhd - Implements the UART reciever

● UART_Transmitter.vhd - Implements the UART transmitter 

● baud_rate_generator.vhd - Implements the baud rate generator

● Mux_4_1.vhd - Implements a multiplexer.

● fifo.vhd

● fifo_memory.vhd

● fifo_rptr.vhd

● fifo_wptr.vhd

● signal_generator.vhd

