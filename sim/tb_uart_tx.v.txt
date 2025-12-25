`timescale 1ns/1ps

module tb_uart_tx;

    reg clk = 0;
    reg clk_en = 0;
    reg tx_start = 0;
    reg [7:0] tx_data = 8'h00;

    wire tx;
    wire busy;

    uart_tx dut (
        .clk(clk),
        .clk_en(clk_en),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .busy(busy)
    );

    // 50 MHz system clock (20 ns period)
    always #10 clk = ~clk;

    // Fake baud tick: one pulse = one UART bit
    task baud_tick;
        begin
            clk_en = 1'b1;
            #20;
            clk_en = 1'b0;
            #980;
        end
    endtask

    initial begin
        // Generate waveform file
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);

        // Wait before starting
        #200;

        // Transmit 0x55 (01010101)
        tx_data  = 8'h55;
        tx_start = 1'b1;
        #20;
        tx_start = 1'b0;

        repeat (12) baud_tick();

        // Transmit ASCII 'A' (0x41)
        #2000;
        tx_data  = 8'h41;
        tx_start = 1'b1;
        #20;
        tx_start = 1'b0;

        repeat (12) baud_tick();

        #2000;
        $finish;
    end

endmodule
