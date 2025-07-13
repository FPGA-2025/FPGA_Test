module top (
    input  logic clk,
    input  logic rst,
    
    output logic [7:0] led,
    output logic builtin_led,

    output logic tx,
    input  logic rx,

    inout  logic sda0,
    output logic scl0,

    inout  logic sda1,
    output logic scl1,

    inout  logic sda2,
    output logic scl2,

    inout  logic sda3,
    output logic scl3,

    inout  logic sda4,
    output logic scl4,

    inout  logic sda5,
    output logic scl5,

    inout  logic sda6,
    output logic scl6,

    inout  logic sda7,
    output logic scl7
);

    localparam SECOND       = 25_000_000;
    localparam CLK_FREQ     = 25_000_000;
    localparam BAUD_RATE    = 115_200;
    localparam BUFFER_SIZE  = 32;
    localparam PAYLOAD_BITS = 8;

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

    logic uart_rx_fifo_read;
    logic uart_rx_fifo_write;
    logic uart_tx_fifo_read;
    logic uart_tx_fifo_write;


    logic [7:0] uart_rx_fifo_data_in;
    logic [7:0] uart_tx_fifo_data_in;
    logic [7:0] uart_rx_fifo_data_out;
    logic [7:0] uart_tx_fifo_data_out;

    logic uart_rx_fifo_empty;
    logic uart_tx_fifo_empty;
    logic uart_rx_fifo_full;
    logic uart_tx_fifo_full;


    logic uart_rx_valid;
    logic [7:0] uart_rx_data;


    always_ff @(posedge clk) begin : UART_RX_READ_TO_FIFO
        uart_rx_fifo_write <= 1'b0;

        if(!uart_rx_fifo_full && uart_rx_valid) begin
            uart_rx_fifo_data_in <= uart_rx_data;
            uart_rx_fifo_write   <= 1'b1;
        end
    end

    logic uart_tx_en, uart_tx_busy;
    logic [7:0] uart_tx_data;

    typedef enum logic [1:0] { 
        TX_FIFO_IDLE,
        TX_FIFO_READ_FIFO,
        TX_FIFO_WRITE_TX,
        TX_FIFO_WAIT
    } tx_read_fifo_state_t;

    tx_read_fifo_state_t tx_read_fifo_state;

    always_ff @(posedge clk) begin : UART_TX_READ_FROM_FIFO
        uart_tx_en        <= 1'b0;
        uart_tx_fifo_read <= 1'b0;

        unique case (tx_read_fifo_state)
            TX_FIFO_IDLE: begin
                if(!uart_tx_fifo_empty && !uart_tx_busy) begin
                    tx_read_fifo_state <= TX_FIFO_READ_FIFO;
                    uart_tx_fifo_read  <= 1'b1;
                end
            end
            TX_FIFO_READ_FIFO: begin
                tx_read_fifo_state <= TX_FIFO_WRITE_TX;
            end
            TX_FIFO_WRITE_TX: begin
                uart_tx_data       <= uart_tx_fifo_data_out;
                uart_tx_en         <= 1'b1;
                tx_read_fifo_state <= TX_FIFO_WAIT;
            end
            TX_FIFO_WAIT: begin
                tx_read_fifo_state <= TX_FIFO_IDLE;
            end
            default: tx_read_fifo_state <= TX_FIFO_IDLE;
        endcase
    end

    UART_TX #(
        .BAUD_RATE       (BAUD_RATE),
        .CLK_FREQ        (CLK_FREQ)
    ) uart_tx (
        .clk             (clk),
        .rst_n           (rst_n),

        .wr_bit_period_i (0),
        .bit_period_i    (CLK_FREQ / BAUD_RATE),

        .parity_type_i   (1),
        .uart_tx_en      (uart_tx_en),
        .uart_tx_data    (uart_tx_data),
        .uart_txd        (txd),
        .uart_tx_busy    (uart_tx_busy)
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

    FIFO #(
        .DEPTH        (BUFFER_SIZE),
        .WIDTH        (PAYLOAD_BITS)
    ) tx_fifo (
        .clk          (clk),
        .rst_n        (rst_n),

        .wr_en_i      (uart_tx_fifo_write),
        .rd_en_i      (uart_tx_fifo_read),

        .write_data_i (uart_tx_fifo_data_in),
        .full_o       (uart_tx_fifo_full),
        .empty_o      (uart_tx_fifo_empty),
        .read_data_o  (uart_tx_fifo_data_out)
    );

    FIFO #(
        .DEPTH        (BUFFER_SIZE),
        .WIDTH        (PAYLOAD_BITS)
    ) rx_fifo (
        .clk          (clk),
        .rst_n        (rst_n),

        .wr_en_i      (uart_rx_fifo_write),
        .rd_en_i      (uart_rx_fifo_read),

        .write_data_i (uart_rx_fifo_data_in),
        .full_o       (uart_rx_fifo_full),
        .empty_o      (uart_rx_fifo_empty),
        .read_data_o  (uart_rx_fifo_data_out)
    );

    i2c_control #(
        .CLK_FREQ             (25_000_000)
    ) u_i2c_control (
        .clk                  (clk),                           // 1 bit
        .rst_n                (rst_n),                         // 1 bit
        .scl0                 (scl0),                          // 1 bit
        .scl1                 (scl1),                          // 1 bit
        .scl2                 (scl2),                          // 1 bit
        .scl3                 (scl3),                          // 1 bit
        .scl4                 (scl4),                          // 1 bit
        .scl5                 (scl5),                          // 1 bit
        .scl6                 (scl6),                          // 1 bit
        .scl7                 (scl7),                          // 1 bit
        .data_to_uart         (uart_tx_fifo_data_in),          // 8 bits
        .data_valid_to_uart   (uart_tx_fifo_write),            // 1 bit
        .uart_fifo_full       (uart_tx_fifo_full)              // 1 bit
    );

endmodule

