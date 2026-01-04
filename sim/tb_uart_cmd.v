// sim/tb_uart_cmd.v
`timescale 1ns/1ps

module tb_uart_cmd;

    // -----------------------------
    // Clock
    // -----------------------------
    reg clk = 0;
    always #5 clk = ~clk; // 100 MHz

    // -----------------------------
    // DUT signals
    // -----------------------------
    reg        rst;
    reg        rx_valid;
    reg [7:0]  rx_data;

    wire       tx_valid;
    wire [7:0] tx_data;
    reg        tx_ready;

    // -----------------------------
    // DUT instance
    // -----------------------------
    uart_cmd dut (
        .clk(clk),
        .rst(rst),
        .rx_valid(rx_valid),
        .rx_data(rx_data),
        .tx_valid(tx_valid),
        .tx_data(tx_data),
        .tx_ready(tx_ready)
    );

    // -----------------------------
    // Helpers
    // -----------------------------
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
            rx_valid <= 1'b1;
            rx_data  <= b;
            @(posedge clk);
            rx_valid <= 1'b0;
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

    // -----------------------------
    // Test sequence
    // -----------------------------
    initial begin
        // Dump everything (TB + DUT)
        $dumpfile("tb_uart_cmd.vcd");
        $dumpvars(0, tb_uart_cmd);

        // Init
        rst       = 1'b1;
        rx_valid = 1'b0;
        rx_data  = 8'h00;
        tx_ready = 1'b1;

        // Reset
        repeat (5) @(posedge clk);
        rst = 1'b0;

        // -------------------------
        // Day 16 tests
        // -------------------------

        // PING
        send_frame(8'hA5, 8'h03, 8'h00, 8'h00, 8'h00);

        // Read COUNTER_LO (0x03)
        #100;
        send_frame(8'hA5, 8'h02, 8'h03, 8'h00, 8'h00);

        // Read COUNTER_HI (0x04)
        #100;
        send_frame(8'hA5, 8'h02, 8'h04, 8'h00, 8'h00);

        // Wait, then read COUNTER_LO again (should be larger)
        #500;
        send_frame(8'hA5, 8'h02, 8'h03, 8'h00, 8'h00);

        // End
        #500;
        $finish;
    end

endmodule
