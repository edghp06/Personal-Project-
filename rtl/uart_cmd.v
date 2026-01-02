// rtl/uart_cmd.v
// Simple UART command interface: PING / RD (and optional WR stub)
// Frame: A5 cmd addr d0 d1 chk
// Resp : 5A status addr d0 d1 chk

module uart_cmd #(
    parameter [15:0] REG_ID      = 16'h4B34,
    parameter [15:0] REG_VERSION = 16'h0015
)(
    input  wire       clk,
    input  wire       rst,          // synchronous reset preferred; ok if async if your design uses it

    // Byte stream in from UART RX
    input  wire       rx_valid,
    input  wire [7:0] rx_data,

    // Byte stream out to UART TX (handshake: tx_ready tells us when we can push next byte)
    output reg        tx_valid,
    output reg  [7:0] tx_data,
    input  wire       tx_ready
);

    // ----------------------------
    // Frame capture (6 bytes)
    // ----------------------------
    reg [2:0]  rx_count;
    reg [7:0]  f0, f1, f2, f3, f4, f5;

    // Status flags (simple, useful in sim)
    reg parser_error_seen;
    reg last_cmd_valid;

    // Last error/status code to report
    reg [7:0] last_status;

    // Response packet bytes
    reg [7:0] r0, r1, r2, r3, r4, r5;

    // TX FSM to send 6 bytes when we have a response ready
    reg [2:0] tx_count;
    reg       resp_pending;

    // Helper: compute XOR checksum
    function [7:0] xor5;
        input [7:0] a,b,c,d,e;
        begin
            xor5 = a ^ b ^ c ^ d ^ e;
        end
    endfunction

    // Register read function
    function [15:0] reg_read;
        input [7:0] addr;
        begin
            case (addr)
                8'h00: reg_read = REG_ID;
                8'h01: reg_read = REG_VERSION;
                8'h02: reg_read = {14'b0, last_cmd_valid, parser_error_seen}; // STATUS
                default: reg_read = 16'h0000; // will be treated as bad addr
            endcase
        end
    endfunction

    // Check if address is valid
    function addr_valid;
        input [7:0] addr;
        begin
            case (addr)
                8'h00, 8'h01, 8'h02: addr_valid = 1'b1;
                default: addr_valid = 1'b0;
            endcase
        end
    endfunction

    // CMD values
    localparam [7:0] CMD_WR   = 8'h01;
    localparam [7:0] CMD_RD   = 8'h02;
    localparam [7:0] CMD_PING = 8'h03;

    // Status codes
    localparam [7:0] ST_OK      = 8'h00;
    localparam [7:0] ST_BADSOF  = 8'hE1;
    localparam [7:0] ST_BADCHK  = 8'hE2;
    localparam [7:0] ST_BADCMD  = 8'hE3;
    localparam [7:0] ST_BADADDR = 8'hE4;

    // ----------------------------
    // RX capture
    // ----------------------------
    always @(posedge clk) begin
        if (rst) begin
            rx_count          <= 3'd0;
            f0 <= 8'd0; f1 <= 8'd0; f2 <= 8'd0; f3 <= 8'd0; f4 <= 8'd0; f5 <= 8'd0;

            parser_error_seen <= 1'b0;
            last_cmd_valid    <= 1'b0;
            last_status       <= ST_OK;

            // TX/response
            tx_valid      <= 1'b0;
            tx_data       <= 8'd0;
            tx_count      <= 3'd0;
            resp_pending  <= 1'b0;

            r0 <= 8'd0; r1 <= 8'd0; r2 <= 8'd0; r3 <= 8'd0; r4 <= 8'd0; r5 <= 8'd0;
        end else begin
            // Default: tx_valid deassert unless we're actively sending
            if (!resp_pending) begin
                tx_valid <= 1'b0;
            end

            // Capture incoming bytes into frame buffer
            if (rx_valid) begin
                case (rx_count)
                    3'd0: f0 <= rx_data;
                    3'd1: f1 <= rx_data;
                    3'd2: f2 <= rx_data;
                    3'd3: f3 <= rx_data;
                    3'd4: f4 <= rx_data;
                    3'd5: f5 <= rx_data;
                endcase

                if (rx_count == 3'd5) begin
                    rx_count <= 3'd0;

                    // We have a full frame now: f0..f4 are previous, f5 is last captured this cycle.
                    // But note: f5 is updated nonblocking above. Use rx_data for the 6th byte.
                    // So reconstruct local wires:
                    //   b0=f0, b1=f1, b2=f2, b3=f3, b4=f4, b5=rx_data

                    // Validate + build response (only if we are not already sending a response)
                    if (!resp_pending) begin
                        // Clear valid flag for this new frame (set if OK)
                        last_cmd_valid <= 1'b0;

                        // Basic checks
                        if (f0 != 8'hA5) begin
                            last_status       <= ST_BADSOF;
                            parser_error_seen <= 1'b1;
                            // Response: error, echo addr if we can (use f2)
                            r0 <= 8'h5A;
                            r1 <= ST_BADSOF;
                            r2 <= f2;
                            r3 <= 8'h00;
                            r4 <= 8'h00;
                            r5 <= xor5(8'h5A, ST_BADSOF, f2, 8'h00, 8'h00);
                            resp_pending <= 1'b1;
                            tx_count <= 3'd0;
                        end else if (rx_data != xor5(f0, f1, f2, f3, f4)) begin
                            last_status       <= ST_BADCHK;
                            parser_error_seen <= 1'b1;
                            r0 <= 8'h5A;
                            r1 <= ST_BADCHK;
                            r2 <= f2;
                            r3 <= 8'h00;
                            r4 <= 8'h00;
                            r5 <= xor5(8'h5A, ST_BADCHK, f2, 8'h00, 8'h00);
                            resp_pending <= 1'b1;
                            tx_count <= 3'd0;
                        end else begin
                            // Command decode
                            if (f1 == CMD_PING) begin
                                last_status    <= ST_OK;
                                last_cmd_valid <= 1'b1;

                                // For PING: return VERSION in data
                                r0 <= 8'h5A;
                                r1 <= ST_OK;
                                r2 <= 8'h01; // pretend "addr=VERSION"
                                r3 <= REG_VERSION[7:0];
                                r4 <= REG_VERSION[15:8];
                                r5 <= xor5(8'h5A, ST_OK, 8'h01, REG_VERSION[7:0], REG_VERSION[15:8]);
                                resp_pending <= 1'b1;
                                tx_count <= 3'd0;

                            end else if (f1 == CMD_RD) begin
                                if (!addr_valid(f2)) begin
                                    last_status       <= ST_BADADDR;
                                    parser_error_seen <= 1'b1;

                                    r0 <= 8'h5A;
                                    r1 <= ST_BADADDR;
                                    r2 <= f2;
                                    r3 <= 8'h00;
                                    r4 <= 8'h00;
                                    r5 <= xor5(8'h5A, ST_BADADDR, f2, 8'h00, 8'h00);
                                    resp_pending <= 1'b1;
                                    tx_count <= 3'd0;
                                end else begin
                                    // read value
                                    begin : rdblk
                                        reg [15:0] v;
                                        v = reg_read(f2);
                                        last_status    <= ST_OK;
                                        last_cmd_valid <= 1'b1;

                                        r0 <= 8'h5A;
                                        r1 <= ST_OK;
                                        r2 <= f2;
                                        r3 <= v[7:0];
                                        r4 <= v[15:8];
                                        r5 <= xor5(8'h5A, ST_OK, f2, v[7:0], v[15:8]);
                                        resp_pending <= 1'b1;
                                        tx_count <= 3'd0;
                                    end
                                end

                            end else if (f1 == CMD_WR) begin
                                // Optional today: treat all WR as bad addr (or later add CONTROL reg)
                                // For Day 15: simplest is reject with BADADDR unless you want CONTROL.
                                last_status       <= ST_BADADDR;
                                parser_error_seen <= 1'b1;

                                r0 <= 8'h5A;
                                r1 <= ST_BADADDR;
                                r2 <= f2;
                                r3 <= 8'h00;
                                r4 <= 8'h00;
                                r5 <= xor5(8'h5A, ST_BADADDR, f2, 8'h00, 8'h00);
                                resp_pending <= 1'b1;
                                tx_count <= 3'd0;

                            end else begin
                                last_status       <= ST_BADCMD;
                                parser_error_seen <= 1'b1;

                                r0 <= 8'h5A;
                                r1 <= ST_BADCMD;
                                r2 <= f2;
                                r3 <= 8'h00;
                                r4 <= 8'h00;
                                r5 <= xor5(8'h5A, ST_BADCMD, f2, 8'h00, 8'h00);
                                resp_pending <= 1'b1;
                                tx_count <= 3'd0;
                            end
                        end
                    end
                end else begin
                    rx_count <= rx_count + 3'd1;
                end
            end

            // ----------------------------
            // TX response sender
            // ----------------------------
            if (resp_pending) begin
                // Only drive tx_valid when we actually have a byte to present
                tx_valid <= 1'b1;

                case (tx_count)
                    3'd0: tx_data <= r0;
                    3'd1: tx_data <= r1;
                    3'd2: tx_data <= r2;
                    3'd3: tx_data <= r3;
                    3'd4: tx_data <= r4;
                    3'd5: tx_data <= r5;
                    default: tx_data <= 8'h00;
                endcase

                // Advance when UART TX accepts the byte
                if (tx_ready) begin
                    if (tx_count == 3'd5) begin
                        tx_count     <= 3'd0;
                        resp_pending <= 1'b0;
                        tx_valid     <= 1'b0;
                    end else begin
                        tx_count <= tx_count + 3'd1;
                    end
                end
            end
        end
    end

endmodule
