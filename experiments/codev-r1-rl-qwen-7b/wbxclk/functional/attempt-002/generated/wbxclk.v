module wbxclk #(
    parameter AW=32,
    DW=32,
    LGFIFO=5
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
    input wire [(DW-1):0] i_xclk_data,
    input wire i_xclk_err
);

    localparam FIFO_DEPTH = 1 << LGFIFO;
    localparam FIFO_WIDTH = 1 + 1 + 1 + AW + DW + (DW/8);

    // Request FIFO in i_wb_clk domain
    reg [LGFIFO:0] req_wr_ptr = 0, req_rd_ptr = 0;
    reg [FIFO_WIDTH-1:0] req_fifo [0:FIFO_DEPTH-1];

    // Response FIFO in i_xclk_clk domain
    reg [LGFIFO:0] resp_wr_ptr = 0, resp_rd_ptr = 0;
    reg [1 + 1 + DW + (DW/8):0] resp_fifo [0:FIFO_DEPTH-1];

    // o_wb_stall calculation
    wire [LGFIFO:0] req_diff = req_wr_ptr - req_rd_ptr;
    assign o_wb_stall = (req_diff >= FIFO_DEPTH);

    // Write to request FIFO
    always @(posedge i_wb_clk) begin
        if (i_reset) begin
            req_wr_ptr <= 0;
        end else if (i_wb_cyc && i_wb_stb && !o_wb_stall) begin
            req_fifo[req_wr_ptr[LGFIFO-1:0]] <= {i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
            req_wr_ptr <= req_wr_ptr + 1;
        end
    end

    // Read from request FIFO in i_xclk_clk domain
    reg [LGFIFO:0] req_rd_ptr_sync1, req_rd_ptr_sync2;
    always @(posedge i_xclk_clk) begin
        req_rd_ptr_sync1 <= req_rd_ptr;
        req_rd_ptr_sync2 <= req_rd_ptr_sync1;
    end

    // Read from FIFO
    always @(posedge i_xclk_clk) begin
        if (i_reset) begin
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
            o_xclk_we <= 0;
            o_xclk_addr <= 0;
            o_xclk_data <= 0;
            o_xclk_sel <= 0;
        end else if (!i_xclk_stall) begin
            if (req_rd_ptr_sync2 < req_wr_ptr) begin
                {o_xclk_cyc, o_xclk_stb, o_xclk_we, o_xclk_addr, o_xclk_data, o_xclk_sel} <= req_fifo[req_rd_ptr_sync2[LGFIFO-1:0]];
                req_rd_ptr <= req_rd_ptr_sync2 + 1;
            end
        end
    end

    // Write response into response FIFO
    always @(posedge i_xclk_clk) begin
        if (i_reset) begin
            resp_wr_ptr <= 0;
        end else if (i_xclk_ack || i_xclk_err) begin
            resp_fifo[resp_wr_ptr[LGFIFO-1:0]] <= {i_xclk_ack, i_xclk_err, i_xclk_data};
            resp_wr_ptr <= resp_wr_ptr + 1;
        end
    end

    // Read response FIFO in i_wb_clk domain
    reg [LGFIFO:0] resp_rd_ptr_sync1, resp_rd_ptr_sync2;
    always @(posedge i_wb_clk) begin
        resp_rd_ptr_sync1 <= resp_wr_ptr;
        resp_rd_ptr_sync2 <= resp_rd_ptr_sync1;
    end

    // Read from response FIFO
    always @(posedge i_wb_clk) begin
        if (i_reset) begin
            o_wb_ack <= 0;
            o_wb_err <= 0;
            o_wb_data <= 0;
        end else if (resp_rd_ptr_sync2 < resp_wr_ptr) begin
            {o_wb_ack, o_wb_err, o_wb_data} <= resp_fifo[resp_rd_ptr_sync2[LGFIFO-1:0]];
            resp_rd_ptr <= resp_rd_ptr_sync2 + 1;
        end
    end

endmodule
