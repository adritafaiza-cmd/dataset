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
    reg                        request_fifo_wr_en;
    reg                        request_fifo_rd_en;
    wire                       request_fifo_full;
    wire                       request_fifo_empty;
    wire [ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 4 + 3 - 1:0] request_fifo_data_out;

    reg                        response_fifo_wr_en;
    reg                        response_fifo_rd_en;
    wire                       response_fifo_full;
    wire                       response_fifo_empty;
    wire [DATA_WIDTH + 1 - 1:0] response_fifo_data_out;

    reg                        request_accepted;
    reg                        response_received;

    // Request FIFO
    async_fifo #(
        .DATA_WIDTH(ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 4 + 3),
        .LOG_DEPTH(LOG_DEPTH)
    ) request_fifo (
        .clk_wr(src_pclk_i),
        .rst_wr(src_preset_ni),
        .clk_rd(dst_pclk_i),
        .rst_rd(dst_preset_ni),
        .wr_en(request_fifo_wr_en),
        .rd_en(request_fifo_rd_en),
        .full(request_fifo_full),
        .empty(request_fifo_empty),
        .data_in({src_psel_i, src_penable_i, src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i}),
        .data_out(request_fifo_data_out)
    );

    // Response FIFO
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH + 1),
        .LOG_DEPTH(LOG_DEPTH)
    ) response_fifo (
        .clk_wr(dst_pclk_i),
        .rst_wr(dst_preset_ni),
        .clk_rd(src_pclk_i),
        .rst_rd(src_preset_ni),
        .wr_en(response_fifo_wr_en),
        .rd_en(response_fifo_rd_en),
        .full(response_fifo_full),
        .empty(response_fifo_empty),
        .data_in({dst_prdata_i, dst_pslverr_i}),
        .data_out(response_fifo_data_out)
    );

    // Source side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_pready_o <= 0;
            src_prdata_o <= 0;
            src_pslverr_o <= 0;
            request_fifo_wr_en <= 0;
            response_fifo_rd_en <= 0;
        end else begin
            // Accept request
            if (src_psel_i && src_penable_i && !request_fifo_full) begin
                request_fifo_wr_en <= 1;
                request_accepted <= 1;
            end else begin
                request_fifo_wr_en <= 0;
            end

            // Handle response
            if (!response_fifo_empty) begin
                response_fifo_rd_en <= 1;
                response_received <= 1;
            end else begin
                response_fifo_rd_en <= 0;
            end

            // Assert src_pready_o only after response is received
            if (response_received) begin
                src_pready_o <= 1;
                src_prdata_o <= response_fifo_data_out[DATA_WIDTH-1:0];
                src_pslverr_o <= response_fifo_data_out[DATA_WIDTH];
                response_received <= 0;
            end else if (request_accepted && dst_pready_i) begin
                src_pready_o <= 0;
            end
        end
    end

    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_psel_o <= 0;
            dst_penable_o <= 0;
            dst_pwrite_o <= 0;
            dst_paddr_o <= 0;
            dst_pwdata_o <= 0;
            dst_pstrb_o <= 0;
            dst_pprot_o <= 0;
            request_fifo_rd_en <= 0;
        end else begin
            // Forward request
            if (!request_fifo_empty) begin
                request_fifo_rd_en <= 1;
                dst_psel_o <= request_fifo_data_out[ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 4 + 3 - 1];
                dst_penable_o <= request_fifo_data_out[ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 4 + 3 - 2];
                dst_pwrite_o <= request_fifo_data_out[ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 4 + 3 - 3];
                dst_paddr_o <= request_fifo_data_out[ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 4 + 3 - 4 -: ADDR_WIDTH];
                dst_pwdata_o <= request_fifo_data_out[ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 4 + 3 - 4 - DATA_WIDTH -: DATA_WIDTH];
                dst_pstrb_o <= request_fifo_data_out[ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 4 + 3 - 4 - DATA_WIDTH - DATA_WIDTH/8 -: DATA_WIDTH/8];
                dst_pprot_o <= request_fifo_data_out[ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 4 + 3 - 4 - DATA_WIDTH - DATA_WIDTH/8 - 3 -: 3];
            end else begin
                request_fifo_rd_en <= 0;
                dst_psel_o <= 0;
                dst_penable_o <= 0;
                dst_pwrite_o <= 0;
                dst_paddr_o <= 0;
                dst_pwdata_o <= 0;
                dst_pstrb_o <= 0;
                dst_pprot_o <= 0;
            end
        end
    end

endmodule

module async_fifo #(
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      clk_wr,
    input                      rst_wr,
    input                      clk_rd,
    input                      rst_rd,
    input                      wr_en,
    input                      rd_en,
    output reg                 full,
    output reg                 empty,
    input  [DATA_WIDTH-1:0]    data_in,
    output [DATA_WIDTH-1:0]    data_out
);

    localparam DEPTH = 1 << LOG_DEPTH;
    reg [DATA_WIDTH-1:0]       mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0]    wr_ptr;
    reg [$clog2(DEPTH)-1:0]    rd_ptr;
    reg [$clog2(DEPTH):0]      cnt;

    always @(posedge clk_wr or negedge rst_wr) begin
        if (!rst_wr) begin
            wr_ptr <= 0;
            cnt <= 0;
            full <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1;
                cnt <= cnt + 1;
            end
            if (cnt == DEPTH) begin
                full <= 1;
            end else begin
                full <= 0;
            end
        end
    end

    always @(posedge clk_rd or negedge rst_rd) begin
        if (!rst_rd) begin
            rd_ptr <= 0;
            empty <= 1;
        end else begin
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
                cnt <= cnt - 1;
            end
            if (cnt == 0) begin
                empty <= 1;
            end else begin
                empty <= 0;
            end
        end
    end

    always @(posedge clk_rd or negedge rst_rd) begin
        if (!rst_rd) begin
            data_out <= 0;
        end else if (rd_en && !empty) begin
            data_out <= mem[rd_ptr];
        end
    end

endmodule
