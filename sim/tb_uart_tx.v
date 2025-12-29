`timescale 1ns/1ps

module tb_uart_tx;

    reg clk = 0;
    reg clk_en = 0;
    reg tx_start = 0;
    reg [7:0] tx_data = 8'h00;

    wire tx;
    wire busy;

    // Clock: 50 MHz (arbitrary for simulation)
    always #10 clk = ~clk;

    // Baud tick generator (every 16 clocks)
    reg [3:0] baud_cnt = 0;
    always @(posedge clk) begin
        if (baud_cnt == 15) begin
            baud_cnt <= 0;
            clk_en   <= 1;
        end else begin
            baud_cnt <= baud_cnt + 1;
            clk_en   <= 0;
        end
    end

    uart_tx dut (
        .clk(clk),
        .clk_en(clk_en),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .busy(busy)
    );

    initial begin
        $dumpfile("uart_tx_sim.vcd");
        $dumpvars(0, tb_uart_tx);

        #100;
        tx_data  = 8'h55;
        tx_start = 1;
        #20;
        tx_start = 0;

        #3000;
        tx_data  = 8'hA3;
        tx_start = 1;
        #20;
        tx_start = 0;

        #5000;
        $finish;
    end

endmodule
