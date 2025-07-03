module top (
    input  logic clk,
    input  logic rst,
    
    output logic [7:0] led,
    output logic builtin_led,

    output logic tx,
    input  logic rx
);

    localparam SECOND    = 25_000_000;
    localparam CLK_FREQ  = 25_000_000;
    localparam BAUD_RATE = 115_200;

    logic [31:0] counter;
    logic rst_n;
    logic [1:0] state;

    initial begin
        state = 0;
        rst_n = 0;
    end

    always @(posedge clk) begin
        case(state)
            0: begin
                state <= 1;
                rst_n <= 0;
            end
            1: begin
                state <= 2;
                rst_n <= 0;
            end
            2: begin
                state <= 2;
                rst_n <= 1;
            end
        endcase
    end

    initial begin
        counter     = 0;
        builtin_led = 0;
    end

    always_ff @(posedge clk) begin
        if(counter < SECOND) begin
            counter <= counter + 1;
        end else begin
            builtin_led <= ~builtin_led;
            counter     <= 0;
        end
    end

    logic uart_rx_valid;
    logic [7:0] uart_rx_data;

    UART_TX #(
        .BAUD_RATE       (BAUD_RATE),
        .CLK_FREQ        (CLK_FREQ)
    ) uart_tx (
        .clk             (clk),
        .rst_n           (rst_n),

        .wr_bit_period_i (0),
        .bit_period_i    (CLK_FREQ / BAUD_RATE),

        .parity_type_i   (1),
        .uart_tx_en      (uart_rx_valid),
        .uart_tx_data    (uart_rx_data),
        .uart_txd        (tx),
        .uart_tx_busy    ()
    );

    UART_RX #(
        .BAUD_RATE              (BAUD_RATE),
        .CLK_FREQ               (CLK_FREQ)
    ) uart_rx (
        .clk                    (clk),
        .rst_n                  (rst_n),

        .wr_bit_period_i        (0),
        .bit_period_i           (CLK_FREQ / BAUD_RATE),

        .parity_type_i          (1),
        .uart_rxd               (rx),
        .uart_rx_en             (1),
        .uart_rx_valid_o        (uart_rx_valid),
        .uart_rx_data           (uart_rx_data),
        .uart_rx_parity_error_o ()
    );

endmodule

