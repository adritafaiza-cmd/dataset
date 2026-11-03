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

    localparam DEPTH = 1 << LOG_DEPTH;

    reg [ADDR_WIDTH-1:0]       src_addr_ff;
    reg [DATA_WIDTH-1:0]       src_wdata_ff;
    reg [DATA_WIDTH/8-1:0]     src_strb_ff;
    reg [2:0]                  src_prot_ff;
    reg                        src_write_ff;
    reg                        src_valid_ff;
    reg                        src_ready_ff;

    reg [ADDR_WIDTH-1:0]       dst_addr_ff;
    reg [DATA_WIDTH-1:0]       dst_wdata_ff;
    reg [DATA_WIDTH/8-1:0]     dst_strb_ff;
    reg [2:0]                  dst_prot_ff;
    reg                        dst_write_ff;
    reg                        dst_valid_ff;
    reg                        dst_ready_ff;

    reg [DATA_WIDTH-1:0]       src_rdata_ff;
    reg                        src_slverr_ff;

    reg [DATA_WIDTH-1:0]       dst_rdata_ff;
    reg                        dst_slverr_ff;

    // Source side FIFO
    reg [ADDR_WIDTH-1:0]       src_fifo_addr [0:DEPTH-1];
    reg [DATA_WIDTH-1:0]       src_fifo_wdata [0:DEPTH-1];
    reg [DATA_WIDTH/8-1:0]     src_fifo_strb [0:DEPTH-1];
    reg [2:0]                  src_fifo_prot [0:DEPTH-1];
    reg                        src_fifo_write [0:DEPTH-1];
    reg [$clog2(DEPTH):0]      src_fifo_wr_ptr;
    reg [$clog2(DEPTH):0]      src_fifo_rd_ptr;
    reg [$clog2(DEPTH):0]      src_fifo_cnt;

    // Destination side FIFO
    reg [DATA_WIDTH-1:0]       dst_fifo_rdata [0:DEPTH-1];
    reg                        dst_fifo_slverr [0:DEPTH-1];
    reg [$clog2(DEPTH):0]      dst_fifo_wr_ptr;
    reg [$clog2(DEPTH):0]      dst_fifo_rd_ptr;
    reg [$clog2(DEPTH):0]      dst_fifo_cnt;

    // Source side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_addr_ff <= 0;
            src_wdata_ff <= 0;
            src_strb_ff <= 0;
            src_prot_ff <= 0;
            src_write_ff <= 0;
            src_valid_ff <= 0;
            src_ready_ff <= 0;
            src_fifo_wr_ptr <= 0;
            src_fifo_rd_ptr <= 0;
            src_fifo_cnt <= 0;
        end else begin
            if (src_psel_i && src_penable_i && src_ready_ff) begin
                src_addr_ff <= src_paddr_i;
                src_wdata_ff <= src_pwdata_i;
                src_strb_ff <= src_pstrb_i;
                src_prot_ff <= src_pprot_i;
                src_write_ff <= src_pwrite_i;
                src_valid_ff <= 1;
            end else if (dst_pready_i && src_valid_ff) begin
                src_valid_ff <= 0;
            end

            if (src_valid_ff && !src_ready_ff && src_fifo_cnt < DEPTH) begin
                src_fifo_addr[src_fifo_wr_ptr] <= src_addr_ff;
                src_fifo_wdata[src_fifo_wr_ptr] <= src_wdata_ff;
                src_fifo_strb[src_fifo_wr_ptr] <= src_strb_ff;
                src_fifo_prot[src_fifo_wr_ptr] <= src_prot_ff;
                src_fifo_write[src_fifo_wr_ptr] <= src_write_ff;
                src_fifo_wr_ptr <= src_fifo_wr_ptr + 1;
                src_fifo_cnt <= src_fifo_cnt + 1;
            end

            if (src_fifo_cnt > 0 && !src_ready_ff) begin
                src_ready_ff <= 1;
            end else begin
                src_ready_ff <= 0;
            end
        end
    end

    // Cross-domain synchronization for FIFO pointers
    reg [$clog2(DEPTH):0]      src_fifo_wr_ptr_sync;
    reg [$clog2(DEPTH):0]      dst_fifo_wr_ptr_sync;

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            src_fifo_wr_ptr_sync <= 0;
            dst_fifo_wr_ptr_sync <= 0;
        end else begin
            src_fifo_wr_ptr_sync <= src_fifo_wr_ptr;
            dst_fifo_wr_ptr_sync <= dst_fifo_wr_ptr;
        end
    end

    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_addr_ff <= 0;
            dst_wdata_ff <= 0;
            dst_strb_ff <= 0;
            dst_prot_ff <= 0;
            dst_write_ff <= 0;
            dst_valid_ff <= 0;
            dst_ready_ff <= 0;
            dst_fifo_wr_ptr <= 0;
            dst_fifo_rd_ptr <= 0;
            dst_fifo_cnt <= 0;
        end else begin
            if (src_fifo_cnt > 0 && !dst_valid_ff) begin
                dst_addr_ff <= src_fifo_addr[src_fifo_rd_ptr];
                dst_wdata_ff <= src_fifo_wdata[src_fifo_rd_ptr];
                dst_strb_ff <= src_fifo_strb[src_fifo_rd_ptr];
                dst_prot_ff <= src_fifo_prot[src_fifo_rd_ptr];
                dst_write_ff <= src_fifo_write[src_fifo_rd_ptr];
                dst_valid_ff <= 1;
                src_fifo_rd_ptr <= src_fifo_rd_ptr + 1;
                src_fifo_cnt <= src_fifo_cnt - 1;
            end else if (dst_pready_i && dst_valid_ff) begin
                dst_valid_ff <= 0;
            end

            if (dst_pready_i && dst_valid_ff && dst_fifo_cnt < DEPTH) begin
                dst_fifo_rdata[dst_fifo_wr_ptr] <= dst_prdata_i;
                dst_fifo_slverr[dst_fifo_wr_ptr] <= dst_pslverr_i;
                dst_fifo_wr_ptr <= dst_fifo_wr_ptr + 1;
                dst_fifo_cnt <= dst_fifo_cnt + 1;
            end

            if (dst_fifo_cnt > 0 && !dst_ready_ff) begin
                dst_ready_ff <= 1;
            end else begin
                dst_ready_ff <= 0;
            end
        end
    end

    // Cross-domain synchronization for FIFO pointers
    reg [$clog2(DEPTH):0]      dst_fifo_wr_ptr_sync;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            dst_fifo_wr_ptr_sync <= 0;
        end else begin
            dst_fifo_wr_ptr_sync <= dst_fifo_wr_ptr;
        end
    end

    // Output assignments
    assign src_pready_o = src_ready_ff;
    assign src_prdata_o = src_rdata_ff;
    assign src_pslverr_o = src_slverr_ff;

    assign dst_psel_o = dst_valid_ff;
    assign dst_penable_o = dst_valid_ff;
    assign dst_pwrite_o = dst_write_ff;
    assign dst_paddr_o = dst_addr_ff;
    assign dst_pwdata_o = dst_wdata_ff;
    assign dst_pstrb_o = dst_strb_ff;
    assign dst_pprot_o = dst_prot_ff;

    // Cross-domain data transfer
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_rdata_ff <= 0;
            src_slverr_ff <= 0;
        end else begin
            if (dst_fifo_cnt > 0 && !src_ready_ff) begin
                src_rdata_ff <= dst_fifo_rdata[dst_fifo_rd_ptr];
                src_slverr_ff <= dst_fifo_slverr[dst_fifo_rd_ptr];
                dst_fifo_rd_ptr <= dst_fifo_rd_ptr + 1;
                dst_fifo_cnt <= dst_fifo_cnt - 1;
            end
        end
    end

endmodule
