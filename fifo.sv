module FIFO #(
    parameter DEPTH = 8,
    parameter WIDTH = 8
) (
    input  logic clk,
    input  logic rst_n,

    input  logic wr_en_i,
    input  logic rd_en_i,
    
    input  logic [WIDTH - 1'b1:0] write_data_i,
    output logic full_o,
    output logic empty_o,
    output logic [WIDTH - 1'b1:0] read_data_o
);

// Cálculo da largura do ponteiro
localparam PTR_WIDTH = $clog2(DEPTH); // apenas multiplos de 2

// Memória FIFO
logic [WIDTH - 1:0] memory[DEPTH - 1:0];

// Ponteiros de leitura e escrita
logic unsigned [PTR_WIDTH - 1:0] read_ptr;
logic unsigned [PTR_WIDTH - 1:0] write_ptr;

// Leitura
always_ff @(posedge clk) begin
    if (!rst_n) begin
        read_ptr    <= 'd0;
        read_data_o <= 'd0;
    end else if (rd_en_i && !empty_o) begin
        read_data_o <= memory[read_ptr];
        read_ptr    <= read_ptr + 1;
    end
end

// Escrita
always_ff @(posedge clk) begin
    if (!rst_n) begin
        write_ptr <= 'd0;
    end else if (wr_en_i && !full_o) begin
        memory[write_ptr] <= write_data_i;
        write_ptr         <= write_ptr + 1;
    end
end

// FIFO cheia: ocorre quando o próximo `write_ptr` encontra `read_ptr`
assign full_o = ((write_ptr + 1) == read_ptr) || 
    ((write_ptr == PTR_WIDTH'(DEPTH - 1)) && (read_ptr == 0));

// FIFO vazia: ocorre quando os ponteiros são iguais
assign empty_o = (write_ptr == read_ptr);

endmodule
