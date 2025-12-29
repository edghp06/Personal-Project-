module uart_rx (
    input  wire       clk,
    input  wire       clk_en,     // baud-rate enable
    input  wire       rx,         // UART RX line
    output reg [7:0]  rx_data,    // received byte
    output reg        rx_valid    // pulse when byte received
);

    reg [3:0] bit_index = 0;
    reg [7:0] shift_reg = 0;
    reg       busy = 0;

    always @(posedge clk) begin
        rx_valid <= 1'b0;

        // Detect start bit (rx goes low)
        if (!busy && rx == 1'b0) begin
            busy      <= 1'b1;
            bit_index <= 0;
        end

        // Receive bits
        else if (busy && clk_en) begin
            bit_index <= bit_index + 1;

            // Data bits (1–8)
            if (bit_index >= 1 && bit_index <= 8) begin
                shift_reg <= {rx, shift_reg[7:1]};
            end

            // Stop bit
            if (bit_index == 9) begin
                rx_data  <= shift_reg;
                rx_valid <= 1'b1;
                busy     <= 1'b0;
            end
        end
    end

endmodule
