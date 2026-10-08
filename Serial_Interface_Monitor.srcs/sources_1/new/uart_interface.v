`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.09.2026 21:48:58
// Design Name: 
// Module Name: uart_interface
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


module uart_interface #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 9600
)(
    input  wire       clk,
    input  wire       reset,

    // UART pins
    input  wire       uart_rx,
    output wire       uart_tx,

    // 7-segment display
    output reg [6:0]  seg,
    output reg [5:0]  an,

    // Monitoring LEDs
    output reg [3:0]  status_led
);

    // =====================================================
    // BAUD RATE CALCULATION
    // =====================================================

    localparam BAUD_COUNT = CLK_FREQ / BAUD_RATE;

    // =====================================================
    // UART RECEIVER
    // =====================================================

    reg [15:0] baud_counter_rx;
    reg [3:0]  bit_counter_rx;

    reg [7:0]  rx_data;
    reg        rx_busy;
    reg        rx_valid;

    reg rx_sync1;
    reg rx_sync2;

    always @(posedge clk) begin

        if (reset) begin

            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;

        end
        else begin

            rx_sync1 <= uart_rx;
            rx_sync2 <= rx_sync1;

        end

    end


    // UART RX state machine

    always @(posedge clk) begin

        if (reset) begin

            baud_counter_rx <= 0;
            bit_counter_rx  <= 0;
            rx_data         <= 0;
            rx_busy         <= 0;
            rx_valid        <= 0;

        end
        else begin

            rx_valid <= 1'b0;

            // Detect start bit
            if (!rx_busy) begin

                if (rx_sync2 == 1'b0) begin

                    rx_busy <= 1'b1;

                    baud_counter_rx <= BAUD_COUNT / 2;

                    bit_counter_rx <= 0;

                end

            end

            else begin

                if (baud_counter_rx == BAUD_COUNT - 1) begin

                    baud_counter_rx <= 0;

                    // Data bits
                    if (bit_counter_rx < 8) begin

                        rx_data[bit_counter_rx] <= rx_sync2;

                        bit_counter_rx <= bit_counter_rx + 1'b1;

                    end

                    // Stop bit
                    else begin

                        rx_busy <= 1'b0;

                        rx_valid <= 1'b1;

                        bit_counter_rx <= 0;

                    end

                end

                else begin

                    baud_counter_rx <= baud_counter_rx + 1'b1;

                end

            end

        end

    end


    // =====================================================
    // UART TRANSMITTER
    // Echo received byte
    // =====================================================

    reg [9:0] tx_shift;
    reg [15:0] baud_counter_tx;

    reg [3:0] tx_bit_counter;
    reg tx_busy;

    assign uart_tx = tx_busy ? tx_shift[0] : 1'b1;


    always @(posedge clk) begin

        if (reset) begin

            tx_shift       <= 10'b1111111111;
            baud_counter_tx <= 0;
            tx_bit_counter <= 0;
            tx_busy        <= 0;

        end

        else begin

            // Start transmitting when data received
            if (rx_valid && !tx_busy) begin

                // UART frame:
                // Start + 8 data bits + Stop

                tx_shift <= {
                    1'b1,
                    rx_data,
                    1'b0
                };

                tx_busy <= 1'b1;

                baud_counter_tx <= 0;

                tx_bit_counter <= 0;

            end

            else if (tx_busy) begin

                if (baud_counter_tx == BAUD_COUNT - 1) begin

                    baud_counter_tx <= 0;

                    tx_shift <= {1'b1, tx_shift[9:1]};

                    if (tx_bit_counter == 9) begin

                        tx_busy <= 1'b0;

                        tx_bit_counter <= 0;

                    end

                    else begin

                        tx_bit_counter <= tx_bit_counter + 1'b1;

                    end

                end

                else begin

                    baud_counter_tx <= baud_counter_tx + 1'b1;

                end

            end

        end

    end


    // =====================================================
    // SIGNAL MONITORING LEDS
    // =====================================================

    always @(posedge clk) begin

        if (reset) begin

            status_led <= 4'b0000;

        end

        else begin

            status_led[0] <= rx_busy;   // RX busy
            status_led[1] <= tx_busy;   // TX busy
            status_led[2] <= rx_valid;  // Data received
            status_led[3] <= uart_rx;   // RX signal
        end

    end


    // =====================================================
    // 7-SEGMENT DISPLAY
    // Display received byte in HEX
    // =====================================================

    reg [19:0] refresh_counter;
    reg [2:0]  display_select;

    reg [3:0] digit;


    always @(posedge clk) begin

        if (reset)

            refresh_counter <= 0;

        else

            refresh_counter <= refresh_counter + 1'b1;

    end


    always @(*) begin

        display_select = refresh_counter[19:17];

        case(display_select)

            3'd0: begin
                an = 6'b111110;
                digit = rx_data[3:0];
            end

            3'd1: begin
                an = 6'b111101;
                digit = rx_data[7:4];
            end

            default: begin
                an = 6'b111111;
                digit = 4'd0;
            end

        endcase

    end


    // =====================================================
    // HEX TO 7-SEGMENT DECODER
    // =====================================================

    always @(*) begin

        case(digit)

            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;

            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;

            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;

            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;

            default:
                seg = 7'b1111111;

        endcase

    end

endmodule
