`timescale 1ns/1ps
`include "apb/typedef.svh"

module apb_regs_enhanced_tb;
    localparam int unsigned NO_REGS = 2;
    localparam logic [31:0] BASE_ADDR = 32'h0000_0100;
    localparam bit [NO_REGS-1:0] READ_ONLY = 2'b10;

    typedef logic [31:0] addr_t;
    typedef logic [31:0] data_t;
    typedef logic [3:0]  strb_t;
    typedef logic [15:0] reg_data_t;
    `APB_TYPEDEF_REQ_T(apb_req_t, addr_t, data_t, strb_t)
    `APB_TYPEDEF_RESP_T(apb_resp_t, data_t)

    logic clk = 1'b0;
    logic rst_n = 1'b0;
    apb_req_t req;
    apb_resp_t resp;
    reg_data_t [NO_REGS-1:0] reg_init;
    reg_data_t [NO_REGS-1:0] regs;
    integer errors = 0;

    always #5 clk = ~clk;

    apb_regs #(
        .NoApbRegs    (NO_REGS),
        .ApbAddrWidth (32),
        .AddrOffset   (4),
        .ApbDataWidth (32),
        .RegDataWidth (16),
        .ReadOnly     (READ_ONLY),
        .req_t        (apb_req_t),
        .resp_t       (apb_resp_t),
        .apb_addr_t   (addr_t),
        .reg_data_t   (reg_data_t)
    ) dut (
        .pclk_i      (clk),
        .preset_ni   (rst_n),
        .req_i       (req),
        .resp_o      (resp),
        .base_addr_i (BASE_ADDR),
        .reg_init_i  (reg_init),
        .reg_q_o     (regs)
    );

    task automatic fail(input string rule_id, input string message);
        begin
            $display("PROTOCOL VIOLATION [%0s]: %0s", rule_id, message);
            errors = errors + 1;
        end
    endtask

    task automatic fail_reset(input string rule_id, input string message);
        begin
            $display("CDC/RESET VIOLATION [%0s]: %0s", rule_id, message);
            errors = errors + 1;
        end
    endtask

    task automatic check_equal(
        input string rule_id,
        input string message,
        input data_t actual,
        input data_t expected
    );
        begin
            if (actual !== expected) begin
                $display(
                    "PROTOCOL VIOLATION [%0s]: %0s actual=%h expected=%h",
                    rule_id, message, actual, expected
                );
                errors = errors + 1;
            end
        end
    endtask

    task automatic check_reset_equal(
        input string rule_id,
        input string message,
        input data_t actual,
        input data_t expected
    );
        begin
            if (actual !== expected) begin
                $display(
                    "CDC/RESET VIOLATION [%0s]: %0s actual=%h expected=%h",
                    rule_id, message, actual, expected
                );
                errors = errors + 1;
            end
        end
    endtask

    task automatic apb_access(
        input  logic  write,
        input  addr_t address,
        input  data_t write_data,
        input  strb_t strobes,
        input  logic  expected_error,
        output data_t read_data
    );
        begin
            @(negedge clk);
            req = '{
                paddr: address,
                pprot: 3'b000,
                psel: 1'b1,
                penable: 1'b0,
                pwrite: write,
                pwdata: write_data,
                pstrb: strobes
            };
            #1;
            if (resp.pready !== 1'b0)
                fail("APB_SETUP_READY", "PREADY asserted in APB setup phase");

            @(negedge clk);
            req.penable = 1'b1;
            #1;
            if ($isunknown({resp.pready, resp.pslverr, resp.prdata}))
                fail("APB_RESPONSE_KNOWN", "X/Z observed on APB response during access");
            if (resp.pready !== 1'b1)
                fail("APB_ACCESS_READY", "single-cycle APB access did not become ready");
            if (resp.pslverr !== expected_error)
                fail("APB_ERROR_RESPONSE", "unexpected PSLVERR value");
            read_data = resp.prdata;

            @(negedge clk);
            req = '0;
            #1;
            if (resp.pready !== 1'b0)
                fail("APB_RESPONSE_RELEASE", "PREADY remained asserted after APB access");
        end
    endtask

    task automatic apb_write(
        input addr_t address,
        input data_t write_data,
        input strb_t strobes,
        input logic expected_error
    );
        data_t ignored;
        begin
            apb_access(
                1'b1, address, write_data, strobes, expected_error, ignored
            );
        end
    endtask

    task automatic apb_read(
        input addr_t address,
        input logic expected_error,
        output data_t read_data
    );
        begin
            apb_access(
                1'b0, address, 32'b0, 4'b0, expected_error, read_data
            );
        end
    endtask

    always @(posedge clk) begin
        if (rst_n && req.penable && !req.psel)
            fail("APB_ENABLE_WITHOUT_SELECT", "PENABLE asserted without PSEL");
        if (rst_n && req.psel && req.penable) begin
            if ($isunknown({resp.pready, resp.pslverr, resp.prdata}))
                fail("APB_RESPONSE_KNOWN", "response contains X/Z in APB access phase");
            if (resp.pready !== 1'b1)
                fail("APB_ACCESS_READY", "PREADY low in APB access phase");
        end
    end

    data_t rdata;
    initial begin
        req = '0;
        reg_init[0] = 16'h0000;
        reg_init[1] = 16'hC33C;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);
        check_reset_equal("RESET_REGISTER_STATE", "RW register did not clear on reset", regs[0], 16'h0000);
        check_reset_equal("RESET_REGISTER_STATE", "RO register did not reflect init value", regs[1], 16'hC33C);

        apb_write(BASE_ADDR, 32'h0000_1122, 4'b1111, 1'b0);
        apb_read(BASE_ADDR, 1'b0, rdata);
        check_equal("APB_WRITE_READBACK", "full write/readback", rdata, 32'h0000_1122);

        apb_write(BASE_ADDR, 32'h0000_00AA, 4'b0001, 1'b0);
        apb_read(BASE_ADDR, 1'b0, rdata);
        check_equal("APB_STROBE", "low-byte strobe", rdata, 32'h0000_11AA);

        apb_write(BASE_ADDR, 32'h0000_BB00, 4'b0010, 1'b0);
        apb_read(BASE_ADDR, 1'b0, rdata);
        check_equal("APB_STROBE", "high-byte strobe", rdata, 32'h0000_BBAA);

        apb_write(BASE_ADDR, 32'hFFFF_0000, 4'b1100, 1'b0);
        apb_read(BASE_ADDR, 1'b0, rdata);
        check_equal("APB_STROBE", "out-of-register strobes changed data", rdata, 32'h0000_BBAA);

        apb_read(BASE_ADDR + 4, 1'b0, rdata);
        check_equal("APB_READ_ONLY", "read-only register value", rdata, 32'h0000_C33C);
        apb_write(BASE_ADDR + 4, 32'h0000_DEAD, 4'b1111, 1'b1);
        apb_read(BASE_ADDR + 4, 1'b0, rdata);
        check_equal("APB_READ_ONLY", "read-only register changed after write", rdata, 32'h0000_C33C);

        apb_read(BASE_ADDR + 8, 1'b1, rdata);
        apb_write(BASE_ADDR + 8, 32'h1234_5678, 4'b1111, 1'b1);

        // Assert reset in the middle of an access.  The reference design's
        // response is combinational, so only state recovery is constrained.
        @(negedge clk);
        req = '{
            paddr: BASE_ADDR,
            pprot: 3'b000,
            psel: 1'b1,
            penable: 1'b0,
            pwrite: 1'b1,
            pwdata: 32'h0000_5A5A,
            pstrb: 4'b1111
        };
        @(negedge clk);
        req.penable = 1'b1;
        #2 rst_n = 1'b0;
        #1;
        if ($isunknown({resp.pready, resp.pslverr, resp.prdata}))
            fail_reset("RESET_RESPONSE_KNOWN", "X/Z response when reset asserted during access");
        @(negedge clk);
        req = '0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);
        apb_read(BASE_ADDR, 1'b0, rdata);
        check_reset_equal("RESET_RECOVERY", "reset-during-access did not clear state", rdata, 32'h0000_0000);

        if (errors == 0)
            $display("APB_REGS_ENHANCED: ENHANCED PASS");
        else
            $display("APB_REGS_ENHANCED: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("APB_REGS_ENHANCED: TIMEOUT");
        $finish;
    end
endmodule
