// uart_tx.v
// ---------
// 8N1 UART transmitter.
// Transmits data LSB-first using an external clock-enable (baud tick).
// Idle state is logic high.

module uart_tx (
    input  wire clk,
    input  wire clk_en,        // one-cycle baud tick
    input  wire tx_start,      // pulse to start transmission
    input  wire [7:0] tx_data, // byte to transmit
    output reg  tx,            // UART TX line
    output reg  busy            // high while transmitting
);

    reg [3:0] bit_index = 0;
    reg [9:0] shift_reg = 10'b1111111111;

    initial begin
        tx   = 1'b1; // idle high
        busy = 1'b0;
    end

    always @(posedge clk) begin
        if (!busy) begin
            tx <= 1'b1;

            if (tx_start) begin
                // Frame format: start(0), data[7:0], stop(1)
                shift_reg <= {1'b1, tx_data, 1'b0};
                bit_index <= 0;
                busy <= 1'b1;
            end

        end else if (clk_en) begin
            tx <= shift_reg[0];
            shift_reg <= {1'b1, shift_reg[9:1]};
            bit_index <= bit_index + 1;

            if (bit_index == 9) begin
                busy <= 1'b0;
            end
        end
    end

endmodule
