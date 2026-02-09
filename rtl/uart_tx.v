module uart_tx (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire [7:0] data,
    output reg  busy,
    output reg  tx
);

    integer i;
    initial begin
        tx   = 1;
        busy = 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            tx   <= 1;
            busy <= 0;
        end else if (start && !busy) begin
            busy <= 1;

            // START bit
            tx <= 0;

            // send data bits (very slow, for visibility)
            for (i = 0; i < 8; i = i + 1)
                tx <= data[i];

            // STOP bit
            tx <= 1;
            busy <= 0;
        end
    end

endmodule
