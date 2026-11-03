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
    reg [ADDR_WIDTH-1:0]       src_req_addr;
    reg [DATA_WIDTH-1:0]       src_req_wdata;
    reg [DATA_WIDTH/8-1:0]     src_req_strb;
    reg [2:0]                  src_req_prot;
    reg                        src_req_write;

    // Destination side signals
    reg                        dst_req_valid;
    reg                        dst_req_ready;
    reg [ADDR_WIDTH-1:0]       dst_req_addr;
    reg [DATA_WIDTH-1:0]       dst_req_wdata;
    reg [DATA_WIDTH/8-1:0]     dst_req_strb;
    reg [2:0]                  dst_req_prot;
    reg                        dst_req_write;

    // FIFO write logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            fifo_count <= 0;
            fifo_write <= 0;
        end else begin
            if (src_req_ready && src_req_valid) begin
                fifo_addr[fifo_count] <= src_req_addr;
                fifo_wdata[fifo_count] <= src_req_wdata;
                fifo_strb[fifo_count] <= src_req_strb;
                fifo_prot[fifo_count] <= src_req_prot;
                fifo_write <= 1;
            end else begin
                fifo_write <= 0;
            end

            if (fifo_write && !fifo_read && fifo_count < (1<<LOG_DEPTH)) begin
                fifo_count <= fifo_count + 1;
            end else if (fifo_read && !fifo_write && fifo_count > 0) begin
                fifo_count <= fifo_count - 1;
            end
        end
    end

    // FIFO read logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            fifo_count_sync <= 0;
            fifo_read <= 0;
        end else begin
            if (dst_req_ready && dst_req_valid) begin
                fifo_read <= 1;
            end else begin
                fifo_read <= 0;
            end

            if (fifo_read && !fifo_write && fifo_count_sync > 0) begin
                fifo_count_sync <= fifo_count_sync - 1;
            end else if (fifo_write && !fifo_read && fifo_count_sync < (1<<LOG_DEPTH)) begin
                fifo_count_sync <= fifo_count_sync + 1;
            end
        end
    end

    // Synchronize FIFO count to destination clock domain
    reg [LOG_DEPTH:0]          fifo_count_sync1;
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            fifo_count_sync1 <= 0;
        end else begin
            fifo_count_sync1 <= fifo_count;
        end
    end

    // Source side request handling
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_req_valid <= 0;
            src_req_accepted <= 0;
        end else begin
            if (src_psel_i && src_penable_i && !src_req_valid) begin
                src_req_valid <= 1;
                src_req_addr <= src_paddr_i;
                src_req_wdata <= src_pwdata_i;
                src_req_strb <= src_pstrb_i;
                src_req_prot <= src_pprot_i;
                src_req_write <= src_pwrite_i;
            end else if (src_req_accepted) begin
                src_req_valid <= 0;
                src_req_accepted <= 0;
            end
        end
    end

    // Source side ready signal
    assign src_req_ready = (fifo_count < (1<<LOG_DEPTH)) && !src_req_valid;

    // Source side ready and error signals
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_pready_o <= 0;
            src_prdata_o <= 0;
            src_pslverr_o <= 0;
        end else begin
            if (src_req_accepted && dst_pready_i) begin
                src_pready_o <= 1;
                src_prdata_o <= dst_prdata_i;
                src_pslverr_o <= dst_pslverr_i;
            end else begin
                src_pready_o <= 0;
            end
        end
    end

    // Destination side request handling
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_req_valid <= 0;
        end else begin
            if (fifo_count_sync1 > 0 && !dst_req_valid) begin
                dst_req_valid <= 1;
                dst_req_addr <= fifo_addr[0];
                dst_req_wdata <= fifo_wdata[0];
                dst_req_strb <= fifo_strb[0];
                dst_req_prot <= fifo_prot[0];
                dst_req_write <= fifo_write;
            end else if (dst_req_ready && dst_req_valid) begin
                dst_req_valid <= 0;
            end
        end
    end

    // Destination side ready signal
    assign dst_req_ready = (fifo_count_sync1 > 0) && !dst_req_valid;

    // Destination side output signals
    assign dst_psel_o = dst_req_valid;
    assign dst_penable_o = dst_req_valid;
    assign dst_pwrite_o = dst_req_write;
    assign dst_paddr_o = dst_req_addr;
    assign dst_pwdata_o = dst_req_wdata;
    assign dst_pstrb_o = dst_req_strb;
    assign dst_pprot_o = dst_req_prot;

    // Accept request on source side
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_req_accepted <= 0;
        end else begin
            if (src_req_valid && src_req_ready) begin
                src_req_accepted <= 1;
            end
        end
    end

endmodule
