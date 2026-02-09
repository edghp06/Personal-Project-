module streamer (
    input  wire clk,
    input  wire rst,
    input  wire tx_busy,
    output reg  tx_start,
    output reg  [7:0] tx_data
);

    reg [7:0] count;
    reg [2:0] state;

    localparam S_SOF  = 0;
    localparam S_DATA = 1;
    localparam S_EOF  = 2;
    localparam S_DONE = 3;

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_SOF;
            count    <= 0;
            tx_start <= 0;
            tx_data  <= 0;
        end else begin
            tx_start <= 0;

            if (!tx_busy) begin
                case (state)
                    S_SOF: begin
                        tx_data  <= 8'h55;
                        tx_start <= 1;
                        state    <= S_DATA;
                    end

                    S_DATA: begin
                        tx_data  <= count;
                        tx_start <= 1;
                        count    <= count + 1;
                        if (count == 8'hFF)
                            state <= S_EOF;
                    end

                    S_EOF: begin
                        tx_data  <= 8'hAA;
                        tx_start <= 1;
                        state    <= S_DONE;
                    end
                endcase
            end
        end
    end

endmodule
