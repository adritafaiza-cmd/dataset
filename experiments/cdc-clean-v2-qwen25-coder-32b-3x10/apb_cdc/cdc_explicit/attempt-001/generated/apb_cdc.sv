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
    reg [LOG_DEPTH:0]          fifo_count;
    reg [LOG_DEPTH:0]          fifo_count_sync;

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

    // FIFO write logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            fifo_count <= 0;
            fifo_write <= 0;
        end else if (src_req_valid && src_req_ready) begin
            fifo_addr[fifo_count] <= src_paddr_i;
            fifo_wdata[fifo_count] <= src_pwdata_i;
            fifo_strb[fifo_count] <= src_pstrb_i;
            fifo_prot[fifo_count] <= src_pprot_i;
            fifo_count <= fifo_count + 1;
            fifo_write <= 1;
        end else begin
            fifo_write <= 0;
        end
    end

    // FIFO read logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            fifo_count_sync <= 0;
            fifo_read <= 0;
        end else if (dst_req_valid && dst_req_ready) begin
            fifo_count_sync <= fifo_count_sync - 1;
            fifo_read <= 1;
        end else begin
            fifo_read <= 0;
        end
    end

    // FIFO count synchronization
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            fifo_count_sync <= 0;
        end else begin
            fifo_count_sync <= fifo_count;
        end
    end

    // Source side request logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_req_valid <= 0;
            src_req_accepted <= 0;
            src_req_done <= 0;
        end else begin
            if (src_psel_i && src_penable_i && !src_req_valid) begin
                src_req_valid <= 1;
            end else if (src_req_accepted) begin
                src_req_valid <= 0;
                src_req_accepted <= 0;
            end

            if (fifo_write && fifo_count < (1<<LOG_DEPTH)) begin
                src_req_accepted <= 1;
            end

            if (src_req_valid && !src_req_done && dst_pready_i) begin
                src_req_done <= 1;
            end else if (!src_req_valid) begin
                src_req_done <= 0;
            end
        end
    end

    // Destination side request logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_req_valid <= 0;
            dst_req_accepted <= 0;
            dst_req_done <= 0;
        end else begin
            if (fifo_count_sync > 0 && !dst_req_valid) begin
                dst_req_valid <= 1;
            end else if (dst_req_accepted) begin
                dst_req_valid <= 0;
                dst_req_accepted <= 0;
            end

            if (dst_req_valid && !dst_req_done && dst_pready_i) begin
                dst_req_done <= 1;
            end else if (!dst_req_valid) begin
                dst_req_done <= 0;
            end

            if (dst_req_valid && !dst_req_accepted && dst_pready_i) begin
                dst_req_accepted <= 1;
            end
        end
    end

    // Source side outputs
    assign src_pready_o = src_req_done;
    assign src_prdata_o = dst_prdata_i;
    assign src_pslverr_o = dst_pslverr_i;

    // Destination side outputs
    assign dst_psel_o = dst_req_valid;
    assign dst_penable_o = dst_req_valid;
    assign dst_pwrite_o = src_pwrite_i;
    assign dst_paddr_o = fifo_addr[fifo_count_sync - 1];
    assign dst_pwdata_o = fifo_wdata[fifo_count_sync - 1];
    assign dst_pstrb_o = fifo_strb[fifo_count_sync - 1];
    assign dst_pprot_o = fifo_prot[fifo_count_sync - 1];

endmodule
