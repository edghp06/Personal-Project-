module uart_tx (
    input  wire       clk,
    input  wire       clk_en,     // baud-rate enable
    input  wire       tx_start,   // pulse to start transmission
    input  wire [7:0] tx_data,    // byte to send
    output reg        tx,         // UART TX line
    output reg        busy
);

    reg [9:0] shift_reg = 10'b1111111111;
    reg [3:0] bit_index = 0;

    initial begin
        tx   = 1'b1;   // UART idle state
        busy = 1'b0;
    end

    always @(posedge clk) begin
        if (tx_start && !busy) begin
            // Load frame: stop bit (1), data (8), start bit (0)
            shift_reg <= {1'b1, tx_data, 1'b0};
            bit_index <= 0;
            busy      <= 1'b1;
        end
        else if (busy && clk_en) begin
            tx        <= shift_reg[0];
            shift_reg <= {1'b1, shift_reg[9:1]};
            bit_index <= bit_index + 1;

            if (bit_index == 4'd9) begin
                busy <= 1'b0;
            end
        end
    end

endmodule
