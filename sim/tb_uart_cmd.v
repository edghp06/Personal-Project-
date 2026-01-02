// sim/tb_uart_cmd.v
`timescale 1ns/1ps

module tb_uart_cmd;

    reg clk = 0;
    always #5 clk = ~clk; // 100 MHz

    reg rst;

    reg       rx_valid;
    reg [7:0] rx_data;

    wire      tx_valid;
    wire [7:0] tx_data;
    reg       tx_ready;

    // DUT (ONLY instance, no extra modules)
    uart_cmd dut (
        .clk(clk),
        .rst(rst),
        .rx_valid(rx_valid),
        .rx_data(rx_data),
        .tx_valid(tx_valid),
        .tx_data(tx_data),
        .tx_ready(tx_ready)
    );

    // checksum helper (TB ONLY, NOT a module)
    function [7:0] chk;
        input [7:0] a,b,c,d,e;
        begin
            chk = a ^ b ^ c ^ d ^ e;
        end
    endfunction

    task send_byte;
        input [7:0] b;
        begin
            @(posedge clk);
            rx_valid <= 1;
            rx_data  <= b;
            @(posedge clk);
            rx_valid <= 0;
            rx_data  <= 8'h00;
        end
    endtask

    task send_frame;
        input [7:0] sof, cmd, addr, d0, d1;
        begin
            send_byte(sof);
            send_byte(cmd);
            send_byte(addr);
            send_byte(d0);
            send_byte(d1);
            send_byte(chk(sof,cmd,addr,d0,d1));
        end
    endtask

    initial begin
        $dumpfile("tb_uart_cmd.vcd");
        $dumpvars(0, tb_uart_cmd);

        rst = 1;
        rx_valid = 0;
        rx_data  = 0;
        tx_ready = 1;

        repeat (5) @(posedge clk);
        rst = 0;

        // PING
        send_frame(8'hA5, 8'h03, 8'h00, 8'h00, 8'h00);

        // READ VERSION (0x01)
        send_frame(8'hA5, 8'h02, 8'h01, 8'h00, 8'h00);

        // BAD CHECKSUM
        send_byte(8'hA5);
        send_byte(8'h02);
        send_byte(8'h01);
        send_byte(8'h00);
        send_byte(8'h00);
        send_byte(8'hFF);

        #200;
        $finish;
    end

endmodule
