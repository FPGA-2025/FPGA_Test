module i2c_control #(
    parameter CLK_FREQ = 25_000_000
) (
    input  logic clk,
    input  logic rst_n,

    // Eight i2c lines

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
    output logic scl7,

    output logic [7:0] data_to_uart,
    output logic data_valid_to_uart,
    input  logic uart_fifo_full
);
    parameter TWO_SECONDS = 2 * CLK_FREQ; // Two seconds in clock cycles

    // Eight instances of the BH1750 I2C sensor

    logic [15:0] bh1750_0_data;
    logic bh1750_0_tick_done;

    bh1750_i2c U0(
		.i_clk       (clk),
		.i_rst       (~rst_n),
		.io_sda      (sda0),
		.io_scl      (scl0),
		.o_data      (bh1750_0_data),
		.o_tick_done (bh1750_0_tick_done),
	);

    logic [15:0] bh1750_1_data;
    logic bh1750_1_tick_done;

    bh1750_i2c U1(
        .i_clk       (clk),
        .i_rst       (~rst_n),
        .io_sda      (sda1),
        .io_scl      (scl1),
        .o_data      (bh1750_1_data),
        .o_tick_done (bh1750_1_tick_done),
    );

    logic [15:0] bh1750_2_data;
    logic bh1750_2_tick_done;

    bh1750_i2c U2(
        .i_clk       (clk),
        .i_rst       (~rst_n),
        .io_sda      (sda2),
        .io_scl      (scl2),
        .o_data      (bh1750_2_data),
        .o_tick_done (bh1750_2_tick_done),
    );

    logic [15:0] bh1750_3_data;
    logic bh1750_3_tick_done;

    bh1750_i2c U3(
        .i_clk       (clk),
        .i_rst       (~rst_n),
        .io_sda      (sda3),
        .io_scl      (scl3),
        .o_data      (bh1750_3_data),
        .o_tick_done (bh1750_3_tick_done),
    );

    logic [15:0] bh1750_4_data;
    logic bh1750_4_tick_done;

    bh1750_i2c U4(
        .i_clk       (clk),
        .i_rst       (~rst_n),
        .io_sda      (sda4),
        .io_scl      (scl4),
        .o_data      (bh1750_4_data),
        .o_tick_done (bh1750_4_tick_done),
    );

    logic [15:0] bh1750_5_data;
    logic bh1750_5_tick_done;

    bh1750_i2c U5(
        .i_clk       (clk),
        .i_rst       (~rst_n),
        .io_sda      (sda5),
        .io_scl      (scl5),
        .o_data      (bh1750_5_data),
        .o_tick_done (bh1750_5_tick_done),
    );

    logic [15:0] bh1750_6_data;
    logic bh1750_6_tick_done;

    bh1750_i2c U6(
        .i_clk       (clk),
        .i_rst       (~rst_n),
        .io_sda      (sda6),
        .io_scl      (scl6),
        .o_data      (bh1750_6_data),
        .o_tick_done (bh1750_6_tick_done),
    );

    logic [15:0] bh1750_7_data;
    logic bh1750_7_tick_done;

    bh1750_i2c U7(
        .i_clk       (clk),
        .i_rst       (~rst_n),
        .io_sda      (sda7),
        .io_scl      (scl7),
        .o_data      (bh1750_7_data),
        .o_tick_done (bh1750_7_tick_done),
    );

    logic [127:0] data_buffer, data_buffer_reg;
    logic [31:0] time_counter;

    typedef enum logic [1:0] { 
        IDLE,
    } uart_send_state_t;

    uart_send_state_t uart_send_state;

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            time_counter    <= 32'h0;
            uart_send_state <= IDLE;
        end else begin
            case (uart_send_state)
                IDLE: begin

                end 
                default: begin
                    uart_send_state <= IDLE;
                end 
            endcase
        end
        
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            data_buffer_reg <= 128'h0;
        end else begin
            if (bh1750_0_tick_done) data_buffer_reg[15:0]   <= bh1750_0_data;
            if (bh1750_1_tick_done) data_buffer_reg[31:16]  <= bh1750_1_data;
            if (bh1750_2_tick_done) data_buffer_reg[47:32]  <= bh1750_2_data;
            if (bh1750_3_tick_done) data_buffer_reg[63:48]  <= bh1750_3_data;
            if (bh1750_4_tick_done) data_buffer_reg[79:64]  <= bh1750_4_data;
            if (bh1750_5_tick_done) data_buffer_reg[95:80]  <= bh1750_5_data;
            if (bh1750_6_tick_done) data_buffer_reg[111:96] <= bh1750_6_data;
            if (bh1750_7_tick_done) data_buffer_reg[127:112]<= bh1750_7_data;
        end
    end

    assign data_buffer = {
        bh1750_7_data, bh1750_6_data, bh1750_5_data, bh1750_4_data,
        bh1750_3_data, bh1750_2_data, bh1750_1_data, bh1750_0_data
    };

endmodule
