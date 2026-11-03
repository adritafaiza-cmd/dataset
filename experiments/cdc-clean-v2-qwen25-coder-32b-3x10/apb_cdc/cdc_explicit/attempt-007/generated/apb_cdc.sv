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

    // FIFO signals
    reg [ADDR_WIDTH-1:0]       fifo_addr [0:(1<<LOG_DEPTH)-1];
    reg [DATA_WIDTH-1:0]       fifo_wdata [0:(1<<LOG_DEPTH)-1];
    reg [DATA_WIDTH/8-1:0]     fifo_strb [0:(1<<LOG_DEPTH)-1];
    reg [2:0]                  fifo_prot [0:(1<<LOG_DEPTH)-1];
    reg                        fifo_write;
    reg                        fifo_read;
    reg [$clog2(1<<LOG_DEPTH):0] fifo_wr_ptr;
    reg [$clog2(1<<LOG_DEPTH):0] fifo_rd_ptr;
    reg [$clog2(1<<LOG_DEPTH):0] fifo_wr_ptr_gray;
    reg [$clog2(1<<LOG_DEPTH):0] fifo_rd_ptr_gray;
    reg [$clog2(1<<LOG_DEPTH):0] fifo_wr_ptr_gray_sync;
    reg [$clog2(1<<LOG_DEPTH):0] fifo_rd_ptr_gray_sync;
    reg                        fifo_full;
    reg                        fifo_empty;

    // Source side signals
    reg                        src_req_valid;
    reg                        src_req_ready;
    reg                        src_req_accepted;
    reg                        src_req_done;

    // Destination side signals
    reg                        dst_req_valid;
    reg                        dst_req_ready;
    reg                        dst_req_accepted;
    reg                        dst_req_done;

    // Source side FIFO write logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            fifo_wr_ptr <= 0;
            fifo_wr_ptr_gray <= 0;
            fifo_wr_ptr_gray_sync <= 0;
            fifo_full <= 0;
        end else begin
            if (fifo_write && !fifo_full) begin
                fifo_wr_ptr <= fifo_wr_ptr + 1;
                fifo_wr_ptr_gray <= fifo_wr_ptr + 1 ^ (fifo_wr_ptr + 1) >> 1;
            end
            fifo_wr_ptr_gray_sync <= fifo_wr_ptr_gray;
            fifo_full <= (fifo_wr_ptr_gray_sync == (fifo_rd_ptr_gray + 1) ^ (fifo_rd_ptr_gray + 1) >> 1);
        end
    end

    // Destination side FIFO read logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            fifo_rd_ptr <= 0;
            fifo_rd_ptr_gray <= 0;
            fifo_rd_ptr_gray_sync <= 0;
            fifo_empty <= 1;
        end else begin
            if (fifo_read && !fifo_empty) begin
                fifo_rd_ptr <= fifo_rd_ptr + 1;
                fifo_rd_ptr_gray <= fifo_rd_ptr + 1 ^ (fifo_rd_ptr + 1) >> 1;
            end
            fifo_rd_ptr_gray_sync <= fifo_rd_ptr_gray;
            fifo_empty <= (fifo_wr_ptr_gray_sync == fifo_rd_ptr_gray);
        end
    end

    // FIFO write enable
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            fifo_write <= 0;
        end else begin
            fifo_write <= src_req_valid && src_req_ready && !fifo_full;
        end
    end

    // FIFO read enable
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            fifo_read <= 0;
        end else begin
            fifo_read <= dst_req_valid && dst_req_ready && !fifo_empty;
        end
    end

    // FIFO write data
    always @(posedge src_pclk_i) begin
        if (fifo_write) begin
            fifo_addr[fifo_wr_ptr] <= src_paddr_i;
            fifo_wdata[fifo_wr_ptr] <= src_pwdata_i;
            fifo_strb[fifo_wr_ptr] <= src_pstrb_i;
            fifo_prot[fifo_wr_ptr] <= src_pprot_i;
        end
    end

    // FIFO read data
    reg [ADDR_WIDTH-1:0]       fifo_addr_r;
    reg [DATA_WIDTH-1:0]       fifo_wdata_r;
    reg [DATA_WIDTH/8-1:0]     fifo_strb_r;
    reg [2:0]                  fifo_prot_r;

    always @(posedge dst_pclk_i) begin
        if (fifo_read) begin
            fifo_addr_r <= fifo_addr[fifo_rd_ptr];
            fifo_wdata_r <= fifo_wdata[fifo_rd_ptr];
            fifo_strb_r <= fifo_strb[fifo_rd_ptr];
            fifo_prot_r <= fifo_prot[fifo_rd_ptr];
        end
    end

    // Source side request handling
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_req_valid <= 0;
            src_req_accepted <= 0;
            src_req_done <= 0;
        end else begin
            if (src_psel_i && src_penable_i && !src_req_valid) begin
                src_req_valid <= 1;
            end
            if (src_req_valid && src_req_ready) begin
                src_req_accepted <= 1;
            end
            if (src_req_accepted && dst_pready_i) begin
                src_req_done <= 1;
            end
            if (src_req_done) begin
                src_req_valid <= 0;
                src_req_accepted <= 0;
                src_req_done <= 0;
            end
        end
    end

    // Destination side request handling
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_req_valid <= 0;
            dst_req_accepted <= 0;
            dst_req_done <= 0;
        end else begin
            if (!fifo_empty && !dst_req_valid) begin
                dst_req_valid <= 1;
            end
            if (dst_req_valid && dst_pready_i) begin
                dst_req_accepted <= 1;
            end
            if (dst_req_accepted) begin
                dst_req_done <= 1;
            end
            if (dst_req_done) begin
                dst_req_valid <= 0;
                dst_req_accepted <= 0;
                dst_req_done <= 0;
            end
        end
    end

    // Source side ready signal
    assign src_pready_o = src_req_accepted;

    // Source side data output
    assign src_prdata_o = dst_prdata_i;
    assign src_pslverr_o = dst_pslverr_i;

    // Destination side control signals
    assign dst_psel_o = dst_req_valid;
    assign dst_penable_o = dst_req_valid;
    assign dst_pwrite_o = src_pwrite_i;
    assign dst_paddr_o = fifo_addr_r;
    assign dst_pwdata_o = fifo_wdata_r;
    assign dst_pstrb_o = fifo_strb_r;
    assign dst_pprot_o = fifo_prot_r;

    // Source side request ready signal
    assign src_req_ready = !fifo_full;

    // Destination side request ready signal
    assign dst_req_ready = dst_pready_i;

endmodule
