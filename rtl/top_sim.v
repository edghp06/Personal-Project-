`timescale 1ns/1ps

module top_sim;

    reg clk = 0;
    always #50 clk = ~clk;

    reg rst = 1;

    wire tx;
    wire busy;
    wire tx_start;
    wire [7:0] tx_data;

    uart_tx u_tx (
        .clk(clk),
        .rst(rst),
        .start(tx_start),
        .data(tx_data),
        .busy(busy),
        .tx(tx)
    );

    streamer u_stream (
        .clk(clk),
        .rst(rst),
        .tx_busy(busy),
        .tx_start(tx_start),
        .tx_data(tx_data)
    );

    initial begin
        $dumpfile("sim/wave.vcd");
        $dumpvars(0, top_sim);

        #500;
        rst = 0;

        #100000;
        $finish;
    end

endmodule
