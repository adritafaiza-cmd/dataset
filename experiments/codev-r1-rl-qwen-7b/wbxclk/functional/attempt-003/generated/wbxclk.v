module wbxclk #(
    parameter AW = 32,
    DW = 32,
    LGFIFO = 5
) (
    input wire i_wb_clk, i_reset,
    input wire i_wb_cyc, i_wb_stb, i_wb_we,
    input wire [(AW-1):0] i_wb_addr,
    input wire [(DW-1):0] i_wb_data,
    input wire [(DW/8-1):0] i_wb_sel,
    output wire o_wb_stall,
    output reg o_wb_ack,
    output reg [(DW-1):0] o_wb_data,
    output reg o_wb_err,
    input wire i_xclk_clk,
    output reg o_xclk_cyc,
    output reg o_xclk_stb,
    output reg o_xclk_we,
    output reg [(AW-1):0] o_xclk_addr,
    output reg [(DW-1):0] o_xclk_data,
    output reg [(DW/8-1):0] o_xclk_sel,
    input wire i_xclk_stall,
    input wire i_xclk_ack,
    input wire i_xclk_err,
    input wire [(DW-1):0] i_xclk_data
);

    localparam FIFO_DEPTH = 2 ** LGFIFO;

    // Request FIFO in i_wb_clk domain
    reg [LGFIFO:0] wr_ptr, rd_ptr;
    reg [ (3 + AW + DW + (DW/8)) -1 :0 ] req_fifo [0:FIFO_DEPTH-1];
    wire fifo_full = (wr_ptr - rd_ptr) >= FIFO_DEPTH;

    // Response FIFO in i_xclk_clk domain
    reg [LGFIFO:0] resp_wr_ptr, resp_rd_ptr;
    reg [ (1 + 1 + DW) -1 :0 ] resp_fifo [0:FIFO_DEPTH-1]; // ack, err, data

    // Wishbone side
    assign o_wb_stall = fifo_full;

    // Write to request FIFO when transaction is accepted
    always @(posedge i_wb_clk) begin
        if (i_reset) begin
            wr_ptr <= 0;
        end else begin
            if (i_wb_cyc && i_wb_stb && !o_wb_stall) begin
                req_fifo[wr_ptr] <= {i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
                wr_ptr <= wr_ptr + 1;
            end
        end
    end

    // X clock side
    reg [ (3 + AW + DW + (DW/8)) -1 :0 ] x_req;
    reg x_req_valid;

    // Read from request FIFO
    always @(posedge i_xclk_clk) begin
        if (i_reset) begin
            rd_ptr <= 0;
            x_req_valid <= 0;
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
            o_xclk_we <= 0;
            o_xclk_addr <= 0;
            o_xclk_data <= 0;
            o_xclk_sel <= 0;
        end else begin
            if (!x_req_valid) begin
                if (rd_ptr != wr_ptr) begin
                    x_req <= req_fifo[rd_ptr];
                    rd_ptr <= rd_ptr + 1;
                    x_req_valid <= 1;
                    // Drive o_xclk signals
                    o_xclk_cyc <= 1;
                    o_xclk_stb <= 1;
                    o_xclk_we <= x_req[3 + AW + DW + (DW/8) +: 1];
                    o_xclk_addr <= x_req[2 + AW + DW + (DW/8) +: AW];
                    o_xclk_data <= x_req[1 + DW + (DW/8) +: DW];
                    o_xclk_sel <= x_req[(DW/8) +: (DW/8)];
                end
            end

            // Wait for ack/err
            if (i_xclk_ack || i_xclk_err) begin
                // Write response to response FIFO
                resp_fifo[resp_wr_ptr] <= {i_xclk_ack, i_xclk_err, i_xclk_data};
                resp_wr_ptr <= resp_wr_ptr + 1;
                // Lower o_xclk signals
                o_xclk_cyc <= 0;
                o_xclk_stb <= 0;
                x_req_valid <= 0;
            end
        end
    end

    // Read from response FIFO in i_wb_clk domain
    always @(posedge i_wb_clk) begin
        if (i_reset) begin
            resp_rd_ptr <= 0;
            o_wb_ack <= 0;
            o_wb_err <= 0;
            o_wb_data <= 0;
        end else begin
            if (resp_rd_ptr != resp_wr_ptr) begin
                {o_wb_ack, o_wb_err, o_wb_data} <= resp_fifo[resp_rd_ptr];
                resp_rd_ptr <= resp_rd_ptr + 1;
            end
        end
    end

endmodule
