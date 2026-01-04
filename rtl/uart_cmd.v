// rtl/uart_cmd.v
// UART command interface with counter readback
// Commands: PING (0x03), READ (0x02)
// Frame: A5 cmd addr d0 d1 chk
// Resp : 5A status addr d0 d1 chk

module uart_cmd (
    input  wire       clk,
    input  wire       rst,

    input  wire       rx_valid,
    input  wire [7:0] rx_data,

    output reg        tx_valid,
    output reg  [7:0] tx_data,
    input  wire       tx_ready
);

    // -----------------------------
    // Internal registers
    // -----------------------------
    reg [2:0] rx_count;
    reg [7:0] b0, b1, b2, b3, b4, b5;

    reg [7:0] last_status;
    reg       parser_error_seen;
    reg       last_cmd_valid;

    reg [7:0] r0, r1, r2, r3, r4, r5;
    reg [2:0] tx_count;
    reg       resp_pending;

    // Day 16: free-running counter
    reg [31:0] cycle_counter;

    // -----------------------------
    // Constants
    // -----------------------------
    localparam [7:0] SOF      = 8'hA5;
    localparam [7:0] SOF_RESP = 8'h5A;

    localparam [7:0] CMD_PING = 8'h03;
    localparam [7:0] CMD_RD   = 8'h02;

    localparam [7:0] ST_OK      = 8'h00;
    localparam [7:0] ST_BADSOF  = 8'hE1;
    localparam [7:0] ST_BADCHK  = 8'hE2;
    localparam [7:0] ST_BADCMD  = 8'hE3;
    localparam [7:0] ST_BADADDR = 8'hE4;

    localparam [15:0] REG_ID      = 16'h4B34;
    localparam [15:0] REG_VERSION = 16'h0016;

    // -----------------------------
    // Helper functions
    // -----------------------------
    function [7:0] chk;
        input [7:0] a,b,c,d,e;
        begin
            chk = a ^ b ^ c ^ d ^ e;
        end
    endfunction

    function addr_ok;
        input [7:0] a;
        begin
            addr_ok = (a == 8'h00) || (a == 8'h01) || (a == 8'h02) ||
                      (a == 8'h03) || (a == 8'h04);
        end
    endfunction

    function [15:0] reg_read;
        input [7:0] a;
        begin
            case (a)
                8'h00: reg_read = REG_ID;
                8'h01: reg_read = REG_VERSION;
                8'h02: reg_read = {14'b0, last_cmd_valid, parser_error_seen};
                8'h03: reg_read = cycle_counter[15:0];
                8'h04: reg_read = cycle_counter[31:16];
                default: reg_read = 16'h0000;
            endcase
        end
    endfunction

    // -----------------------------
    // Main sequential logic
    // -----------------------------
    always @(posedge clk) begin
        if (rst) begin
            rx_count          <= 0;
            tx_count          <= 0;
            resp_pending      <= 0;
            tx_valid          <= 0;
            tx_data           <= 0;
            last_status       <= ST_OK;
            parser_error_seen <= 0;
            last_cmd_valid    <= 0;
            cycle_counter     <= 32'd0;
        end else begin
            // Day 16 counter increments every clock
            cycle_counter <= cycle_counter + 1;

            // -------------------------
            // RX capture
            // -------------------------
            if (rx_valid) begin
                case (rx_count)
                    3'd0: b0 <= rx_data;
                    3'd1: b1 <= rx_data;
                    3'd2: b2 <= rx_data;
                    3'd3: b3 <= rx_data;
                    3'd4: b4 <= rx_data;
                    3'd5: b5 <= rx_data;
                endcase

                if (rx_count == 3'd5) begin
                    rx_count <= 0;
                    last_cmd_valid <= 0;

                    if (b0 != SOF) begin
                        last_status <= ST_BADSOF;
                        parser_error_seen <= 1;
                        r0 <= SOF_RESP; r1 <= ST_BADSOF; r2 <= b2; r3 <= 0; r4 <= 0;
                        r5 <= chk(SOF_RESP, ST_BADSOF, b2, 0, 0);
                        resp_pending <= 1;

                    end else if (rx_data != chk(b0,b1,b2,b3,b4)) begin
                        last_status <= ST_BADCHK;
                        parser_error_seen <= 1;
                        r0 <= SOF_RESP; r1 <= ST_BADCHK; r2 <= b2; r3 <= 0; r4 <= 0;
                        r5 <= chk(SOF_RESP, ST_BADCHK, b2, 0, 0);
                        resp_pending <= 1;

                    end else if (b1 == CMD_PING) begin
                        last_status <= ST_OK;
                        last_cmd_valid <= 1;
                        r0 <= SOF_RESP; r1 <= ST_OK; r2 <= 8'h01;
                        r3 <= REG_VERSION[7:0];
                        r4 <= REG_VERSION[15:8];
                        r5 <= chk(SOF_RESP, ST_OK, 8'h01, r3, r4);
                        resp_pending <= 1;

                    end else if (b1 == CMD_RD) begin
                        if (!addr_ok(b2)) begin
                            last_status <= ST_BADADDR;
                            parser_error_seen <= 1;
                            r0 <= SOF_RESP; r1 <= ST_BADADDR; r2 <= b2; r3 <= 0; r4 <= 0;
                            r5 <= chk(SOF_RESP, ST_BADADDR, b2, 0, 0);
                            resp_pending <= 1;
                        end else begin
                            last_status <= ST_OK;
                            last_cmd_valid <= 1;
                            {r4,r3} <= reg_read(b2);
                            r0 <= SOF_RESP; r1 <= ST_OK; r2 <= b2;
                            r5 <= chk(SOF_RESP, ST_OK, b2, r3, r4);
                            resp_pending <= 1;
                        end

                    end else begin
                        last_status <= ST_BADCMD;
                        parser_error_seen <= 1;
                        r0 <= SOF_RESP; r1 <= ST_BADCMD; r2 <= b2; r3 <= 0; r4 <= 0;
                        r5 <= chk(SOF_RESP, ST_BADCMD, b2, 0, 0);
                        resp_pending <= 1;
                    end
                end else begin
                    rx_count <= rx_count + 1;
                end
            end

            // -------------------------
            // TX send
            // -------------------------
            if (resp_pending && tx_ready) begin
                tx_valid <= 1;
                case (tx_count)
                    3'd0: tx_data <= r0;
                    3'd1: tx_data <= r1;
                    3'd2: tx_data <= r2;
                    3'd3: tx_data <= r3;
                    3'd4: tx_data <= r4;
                    3'd5: tx_data <= r5;
                endcase

                if (tx_count == 3'd5) begin
                    tx_count <= 0;
                    resp_pending <= 0;
                    tx_valid <= 0;
                end else begin
                    tx_count <= tx_count + 1;
                end
            end
        end
    end

endmodule
