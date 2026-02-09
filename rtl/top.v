module top_fpga_dsp ();

    // clock for simulation only
    reg clk = 0;
    always #50 clk = ~clk; // 10 MHz

    reg rst = 1;

    // UART wires
    reg  uart_rx_i = 1'b1;
    wire uart_tx_o;

    // Sample writer (simulation)
    reg        sample_wr_en = 0;
    reg [15:0] sample_wr_data = 16'd0;

    // Free running counter
    reg [31:0] free_counter;
    always @(posedge clk) begin
        if (rst)
            free_counter <= 0;
        else
            free_counter <= free_counter + 1;
    end

    // UART RX
    wire       rx_valid;
    wire [7:0] rx_data;

    uart_rx u_rx (
        .clk(clk),
        .rst(rst),
        .rx(uart_rx_i),
        .rx_valid(rx_valid),
        .rx_data(rx_data)
    );

    // Sample buffer
    wire [7:0]  stream_rd_addr;
    wire [15:0] stream_sample;

    sample_buffer u_buf (
        .clk(clk),
        .rst(rst),
        .sample_wr_en(sample_wr_en),
        .sample_wr_data(sample_wr_data),
        .rd_addr(stream_rd_addr),
        .rd_data(stream_sample)
    );

    // UART TX
    wire       tx_busy;
    wire       tx_start;
    wire [7:0] tx_data;

    uart_tx u_tx (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_busy(tx_busy),
        .tx(uart_tx_o),
        .tx_done()
    );

    // Command + streamer
    uart_cmd u_cmd (
        .clk(clk),
        .rst(rst),
        .rx_valid(rx_valid),
        .rx_data(rx_data),
        .tx_busy(tx_busy),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .free_counter(free_counter),
        .stream_rd_addr(stream_rd_addr),
        .stream_sample(stream_sample)
    );

    // ---- SIMULATION SEQUENCE ----
    integer i;
    initial begin
        #500;
        rst = 0;

        // Fill buffer with ramp
        for (i = 0; i < 256; i = i + 1) begin
            @(posedge clk);
            sample_wr_en   = 1'b1;
            sample_wr_data = 16'h1000 + i;
        end
        sample_wr_en = 0;

        // Send STREAM command over UART
        send_byte(8'hA5);
        send_byte(8'h04);
        send_byte(8'h00);
        send_byte(8'h00);
        send_byte(8'h00); // checksum

        #5_000_000;
        $finish;
    end

    // UART TX task
    task send_byte(input [7:0] b);
        integer k;
        begin
            uart_rx_i = 0;
            #(8680);
            for (k = 0; k < 8; k = k + 1) begin
                uart_rx_i = b[k];
                #(8680);
            end
            uart_rx_i = 1;
            #(8680);
        end
    endtask

endmodule
