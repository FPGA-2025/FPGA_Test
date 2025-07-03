module top (
    input  logic clk,
    input  logic rst_n,
    
    output logic [7:0] leds,
    output logic builtin_led,

    input  logic tx,
    output logic rx
);

    localparam SECOND = 25_000_000;

    logic [31:0] counter;

    initial begin
        counter     = 0;
        builtin_led = 0;
    end

    always_ff @(posedge clk) begin
        if(counter < SECOND) begin
            counter <= counter + 1;
        end else begin
            led     <= ~led;
            counter <= 0;
        end
    end

    logic uart_rx_valid;
    logic [7:0] uart_rx_data;

    UART_TX #(
        .BAUD_RATE  (115_200),
        .CLK_FREQ   (25_000_000)
    ) uart_tx (
        .clk             (clk),
        .rst_n           (1),

        .wr_bit_period_i (0),
        .bit_period_i    (115_200),

        .parity_type_i   (1),
        .uart_tx_en      (uart_rx_valid),
        .uart_tx_data    (uart_rx_data),
        .uart_txd        (tx),
        .uart_tx_busy    ()
    );

    UART_RX #(
        .BAUD_RATE              (115_200),
        .CLK_FREQ               (25_000_000)
    ) uart_rx (
        .clk                    (clk),
        .rst_n                  (1),

        .wr_bit_period_i        (0),
        .bit_period_i           (115200),

        .parity_type_i          (1),
        .uart_rxd               (rx),
        .uart_rx_en             (1),
        .uart_rx_valid_o        (uart_rx_valid),
        .uart_rx_data           (uart_rx_data),
        .uart_rx_parity_error_o ()
    );

endmodule

