`timescale 1ns/1ps

module tb_uart_echo;

    reg clk = 0;
    reg clk_en = 0;
    reg rx = 1;

    wire tx;

    // 50 MHz clock
    always #10 clk = ~clk;

    // Baud clock enable (every 16 clocks)
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

    uart_echo dut (
        .clk(clk),
        .clk_en(clk_en),
        .rx(rx),
        .tx(tx)
    );

    // Task to send UART byte on RX
    task send_byte(input [7:0] data);
        integer i;
        begin
            rx <= 0; // start bit
            repeat (16) @(posedge clk);

            for (i = 0; i < 8; i = i + 1) begin
                rx <= data[i];
                repeat (16) @(posedge clk);
            end

            rx <= 1; // stop bit
            repeat (16) @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("uart_echo_sim.vcd");
        $dumpvars(0, tb_uart_echo);

        #100;
        send_byte(8'h3C);
        #2000;
        send_byte(8'hA5);
        #3000;

        $finish;
    end

endmodule
