module uart_echo (
    input  wire clk,
    input  wire clk_en,
    input  wire rx,
    output wire tx
);

    wire [7:0] rx_data;
    wire       rx_valid;
    wire       tx_busy;

    // UART Receiver
    uart_rx uart_rx_inst (
        .clk(clk),
        .clk_en(clk_en),
        .rx(rx),
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );

    // UART Transmitter
    uart_tx uart_tx_inst (
        .clk(clk),
        .clk_en(clk_en),
        .tx_start(rx_valid),
        .tx_data(rx_data),
        .tx(tx),
        .busy(tx_busy)
    );

endmodule
