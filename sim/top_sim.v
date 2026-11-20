`timescale 1ns/1ps

module top_sim;

    reg clk = 0;
    always #50 clk = ~clk;

    reg rst = 1;

    wire tx;
    wire busy;
    wire tx_start;
    wire [7:0] tx_data;
    wire baud_tick;

    // 10 MHz / 87 = 114,943 baud (0.2% from 115,200)
    clock_enable #(.DIVIDER(87)) u_baud (
        .clk(clk),
        .clk_en(baud_tick)
    );

    uart_tx u_tx (
        .clk(clk),
        .clk_en(baud_tick),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .busy(busy)
    );

    streamer u_stream (
        .clk(clk),
        .rst(rst),
        .tx_busy(busy),
        .tx_start(tx_start),
        .tx_data(tx_data)
    );

    initial begin
        $dumpfile("top_sim.vcd");
        $dumpvars(0, top_sim);

        #500;
        rst = 0;

        #23_000_000; // about 258 bytes at 115,200 baud
        $finish;
    end

endmodule
