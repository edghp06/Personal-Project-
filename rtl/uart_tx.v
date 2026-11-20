module uart_tx (
    input  wire clk,
    input  wire clk_en,        // 1-cycle pulse = baud tick
    input  wire tx_start,      // pulse high to start sending tx_data
    input  wire [7:0] tx_data,
    output reg  tx,            // UART TX line (idle high)
    output reg  busy
);

    reg [3:0] bit_index = 0;
    reg [9:0] shift_reg = 10'b1111111111;

    initial begin
        tx   = 1'b1;
        busy = 1'b0;
    end

    always @(posedge clk) begin
        if (!busy) begin
            tx <= 1'b1; // idle

            if (tx_start) begin
                // Frame: start(0) + data(8 bits LSB first) + stop(1)
                shift_reg <= {1'b1, tx_data, 1'b0};
                bit_index <= 0;
                busy <= 1'b1;
            end

        end else if (clk_en) begin
            // On each baud tick, output next bit
            tx <= shift_reg[0];
            shift_reg <= {1'b1, shift_reg[9:1]};
            bit_index <= bit_index + 1;

            if (bit_index == 9) begin
                busy <= 1'b0;
            end
        end
    end

endmodule
