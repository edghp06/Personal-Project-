module top (
    input  wire clk,        // 27 MHz system clock
    output wire uart_tx      // UART TX output
);

    // -------------------------------------------------
    // Clock enable for UART baud rate
    // 27 MHz / 115200 ≈ 234
    // -------------------------------------------------
    localparam integer BAUD_DIV = 234;

    reg [7:0] baud_cnt = 0;
    reg clk_en = 0;

    always @(posedge clk) begin
        if (baud_cnt == BAUD_DIV - 1) begin
            baud_cnt <= 0;
            clk_en   <= 1;
        end else begin
            baud_cnt <= baud_cnt + 1;
            clk_en   <= 0;
        end
    end

    // -------------------------------------------------
    // Periodic transmit trigger
    // -------------------------------------------------
    reg [23:0] send_cnt = 0;
    reg tx_start = 0;

    always @(posedge clk) begin
        tx_start <= 0;
        send_cnt <= send_cnt + 1;

        // send roughly every 0.2s
        if (send_cnt == 24'd5_000_000) begin
            send_cnt <= 0;
            tx_start <= 1;
        end
    end

    // -------------------------------------------------
    // UART transmitter
    // -------------------------------------------------
    uart_tx uart_tx_inst (
        .clk      (clk),
        .clk_en   (clk_en),
        .tx_start (tx_start),
        .tx_data  (8'h55),     // 'U'
        .tx       (uart_tx),
        .busy     ()
    );

endmodule
