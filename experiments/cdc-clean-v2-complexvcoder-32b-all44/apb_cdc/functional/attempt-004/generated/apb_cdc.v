module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    // Internal signals
    reg                        req_valid;
    reg                        req_ready;
    wire [ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 + 1 - 1:0] req_data;
    reg                        resp_valid;
    reg                        resp_ready;
    wire [DATA_WIDTH + 1 - 1:0] resp_data;

    // Pack request data
    assign req_data = {src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i, src_pwrite_i};

    // Unpack response data
    assign src_prdata_o = resp_data[DATA_WIDTH-1:0];
    assign src_pslverr_o = resp_data[DATA_WIDTH];

    // FIFO for request data
    async_fifo #(
        .DATA_WIDTH(ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 + 1),
        .LOG_DEPTH(LOG_DEPTH)
    ) req_fifo (
        .clk_wr(src_pclk_i),
        .rst_wr(~src_preset_ni),
        .wr_en(req_valid),
        .wr_rdy(req_ready),
        .wr_data(req_data),
        .clk_rd(dst_pclk_i),
        .rst_rd(~dst_preset_ni),
        .rd_en(resp_ready),
        .rd_rdy(resp_valid),
        .rd_data()
    );

    // FIFO for response data
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH + 1),
        .LOG_DEPTH(LOG_DEPTH)
    ) resp_fifo (
        .clk_wr(dst_pclk_i),
        .rst_wr(~dst_preset_ni),
        .wr_en(resp_valid),
        .wr_rdy(resp_ready),
        .wr_data(resp_data),
        .clk_rd(src_pclk_i),
        .rst_rd(~src_preset_ni),
        .rd_en(req_ready),
        .rd_rdy(req_valid),
        .rd_data()
    );

    // Control logic for source interface
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (~src_preset_ni) begin
            src_pready_o <= 0;
        end else begin
            if (req_ready && src_psel_i && src_penable_i) begin
                src_pready_o <= 1;
            end else if (src_pready_o && dst_pready_i) begin
                src_pready_o <= 0;
            end
        end
    end

    // Control logic for destination interface
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (~dst_preset_ni) begin
            dst_psel_o <= 0;
            dst_penable_o <= 0;
        end else begin
            if (resp_valid && !dst_psel_o) begin
                dst_psel_o <= 1;
                dst_penable_o <= 1;
            end else if (dst_psel_o && dst_pready_i) begin
                dst_psel_o <= 0;
                dst_penable_o <= 0;
            end
        end
    end

    // Assign destination outputs
    assign dst_paddr_o = req_data[ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 + 1 - 1 : DATA_WIDTH + DATA_WIDTH/8 + 3 + 1];
    assign dst_pwdata_o = req_data[DATA_WIDTH + DATA_WIDTH/8 + 3 + 1 - 1 : DATA_WIDTH/8 + 3 + 1];
    assign dst_pstrb_o = req_data[DATA_WIDTH/8 + 3 + 1 - 1 : 3 + 1];
    assign dst_pprot_o = req_data[3 + 1 - 1 : 1];
    assign dst_pwrite_o = req_data[0];

    // Assign response data
    assign resp_data = {dst_prdata_i, dst_pslverr_i};

endmodule

module async_fifo #(
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      clk_wr,
    input                      rst_wr,
    input                      wr_en,
    output reg                 wr_rdy,
    input  [DATA_WIDTH-1:0]    wr_data,
    input                      clk_rd,
    input                      rst_rd,
    input                      rd_en,
    output reg                 rd_rdy,
    output [DATA_WIDTH-1:0]    rd_data
);

    localparam DEPTH = 1 << LOG_DEPTH;
    reg [DATA_WIDTH-1:0]       mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0]    wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0]      cnt;

    // Write pointer and ready signal
    always @(posedge clk_wr or negedge rst_wr) begin
        if (~rst_wr) begin
            wr_ptr <= 0;
            wr_rdy <= 1;
        end else begin
            if (wr_en && wr_rdy) begin
                mem[wr_ptr] <= wr_data;
                wr_ptr <= wr_ptr + 1;
                if (cnt == DEPTH)
                    wr_rdy <= 0;
            end
            if (rd_en && cnt != 0)
                wr_rdy <= 1;
        end
    end

    // Read pointer and ready signal
    always @(posedge clk_rd or negedge rst_rd) begin
        if (~rst_rd) begin
            rd_ptr <= 0;
            rd_rdy <= 0;
        end else begin
            if (rd_en && rd_rdy) begin
                rd_ptr <= rd_ptr + 1;
                if (cnt == 0)
                    rd_rdy <= 0;
            end
            if (wr_en && cnt != DEPTH)
                rd_rdy <= 1;
        end
    end

    // Data output
    always @(posedge clk_rd or negedge rst_rd) begin
        if (~rst_rd) begin
            rd_data <= 0;
        end else begin
            if (rd_en && rd_rdy)
                rd_data <= mem[rd_ptr];
        end
    end

    // Counter for the number of elements in the FIFO
    always @(posedge clk_wr or negedge rst_wr) begin
        if (~rst_wr) begin
            cnt <= 0;
        end else begin
            if (wr_en && wr_rdy && !rd_en)
                cnt <= cnt + 1;
            else if (rd_en && rd_rdy && !wr_en)
                cnt <= cnt - 1;
            else if (wr_en && wr_rdy && rd_en && rd_rdy)
                cnt <= cnt;
        end
    end

endmodule
