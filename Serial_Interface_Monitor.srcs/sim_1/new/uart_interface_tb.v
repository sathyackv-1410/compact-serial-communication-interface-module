`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.09.2026 21:50:17
// Design Name: 
// Module Name: uart_interface_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module uart_interface_tb;

    reg clk;
    reg reset;
    reg uart_rx;

    wire uart_tx;

    wire [6:0] seg;
    wire [5:0] an;

    wire [3:0] status_led;


    uart_interface #(
        .CLK_FREQ(100_000_000),
        .BAUD_RATE(9600)
    ) uut (

        .clk(clk),
        .reset(reset),

        .uart_rx(uart_rx),
        .uart_tx(uart_tx),

        .seg(seg),
        .an(an),

        .status_led(status_led)

    );


    // =====================================================
    // 100 MHz CLOCK
    // =====================================================

    initial begin

        clk = 0;

        forever #5 clk = ~clk;

    end


    // =====================================================
    // UART BYTE TRANSMISSION TASK
    // =====================================================

    task send_byte;

        input [7:0] data;

        integer i;

        begin

            // Start bit
            uart_rx = 1'b0;

            #(104167);

            // 8 data bits
            for (i = 0; i < 8; i = i + 1) begin

                uart_rx = data[i];

                #(104167);

            end

            // Stop bit
            uart_rx = 1'b1;

            #(104167);

        end

    endtask


    // =====================================================
    // TEST
    // =====================================================

    initial begin

        reset = 1;

        uart_rx = 1;

        #100;

        reset = 0;

        #1000;


        // Send ASCII A
        send_byte(8'h41);


        #500000;


        // Send ASCII 5
        send_byte(8'h35);


        #500000;

        $finish;

    end

endmodule
