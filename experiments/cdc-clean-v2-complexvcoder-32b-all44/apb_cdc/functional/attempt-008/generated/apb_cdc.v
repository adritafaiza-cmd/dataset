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
    reg                        src_req_valid;
    reg                        src_req_ready;
    reg  [ADDR_WIDTH-1:0]      src_req_addr;
    reg  [DATA_WIDTH-1:0]      src_req_data;
    reg  [DATA_WIDTH/8-1:0]    src_req_strb;
    reg  [2:0]                 src_req_prot;
    reg                        src_req_write;

    reg                        dst_req_valid;
    reg                        dst_req_ready;
    reg  [ADDR_WIDTH-1:0]      dst_req_addr;
    reg  [DATA_WIDTH-1:0]      dst_req_data;
    reg  [DATA_WIDTH/8-1:0]    dst_req_strb;
    reg  [2:0]                 dst_req_prot;
    reg                        dst_req_write;

    reg                        dst_resp_valid;
    reg                        dst_resp_ready;
    reg  [DATA_WIDTH-1:0]      dst_resp_data;
    reg                        dst_resp_slverr;

    // FIFO for request signals
    reg  [ADDR_WIDTH-1:0]      fifo_addr [0:(1<<LOG_DEPTH)-1];
    reg  [DATA_WIDTH-1:0]      fifo_data [0:(1<<LOG_DEPTH)-1];
    reg  [DATA_WIDTH/8-1:0]    fifo_strb [0:(1<<LOG_DEPTH)-1];
    reg  [2:0]                 fifo_prot [0:(1<<LOG_DEPTH)-1];
    reg                        fifo_write [0:(1<<LOG_DEPTH)-1];
    reg  [LOG_DEPTH:0]         fifo_wr_ptr;
    reg  [LOG_DEPTH:0]         fifo_rd_ptr;
    reg  [LOG_DEPTH:0]         fifo_count;

    // FIFO control logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            fifo_wr_ptr <= 0;
            fifo_rd_ptr <= 0;
            fifo_count <= 0;
        end else begin
            if (src_req_ready && src_req_valid) begin
                fifo_addr[fifo_wr_ptr] <= src_paddr_i;
                fifo_data[fifo_wr_ptr] <= src_pwdata_i;
                fifo_strb[fifo_wr_ptr] <= src_pstrb_i;
                fifo_prot[fifo_wr_ptr] <= src_pprot_i;
                fifo_write[fifo_wr_ptr] <= src_pwrite_i;
                fifo_wr_ptr <= fifo_wr_ptr + 1;
                fifo_count <= fifo_count + 1;
            end
            if (dst_req_ready && dst_req_valid) begin
                fifo_rd_ptr <= fifo_rd_ptr + 1;
                fifo_count <= fifo_count - 1;
            end
        end
    end

    // FIFO read logic
    always @(*) begin
        dst_req_valid = (fifo_count > 0);
        dst_req_addr = fifo_addr[fifo_rd_ptr];
        dst_req_data = fifo_data[fifo_rd_ptr];
        dst_req_strb = fifo_strb[fifo_rd_ptr];
        dst_req_prot = fifo_prot[fifo_rd_ptr];
        dst_req_write = fifo_write[fifo_rd_ptr];
    end

    // Source domain request ready
    always @(*) begin
        src_req_ready = (fifo_count < (1<<LOG_DEPTH));
    end

    // Source domain request valid
    always @(*) begin
        src_req_valid = src_psel_i && src_penable_i;
    end

    // Source domain handshake
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_pready_o <= 0;
            src_prdata_o <= 0;
            src_pslverr_o <= 0;
        end else begin
            if (dst_resp_valid && dst_resp_ready) begin
                src_pready_o <= 1;
                src_prdata_o <= dst_resp_data;
                src_pslverr_o <= dst_resp_slverr;
            end else if (src_penable_i && !src_pready_o) begin
                src_pready_o <= 0;
            end
        end
    end

    // Destination domain handshake
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_psel_o <= 0;
            dst_penable_o <= 0;
            dst_pready_i <= 0;
            dst_resp_valid <= 0;
        end else begin
            dst_psel_o <= dst_req_valid;
            dst_penable_o <= dst_req_valid;
            if (dst_req_valid && dst_pready_i) begin
                dst_psel_o <= 0;
                dst_penable_o <= 0;
                dst_resp_valid <= 1;
                dst_resp_data <= dst_prdata_i;
                dst_resp_slverr <= dst_pslverr_i;
            end
            if (dst_resp_valid && dst_resp_ready) begin
                dst_resp_valid <= 0;
            end
        end
    end

    // Destination domain request ready
    always @(*) begin
        dst_req_ready = dst_pready_i;
    end

    // Destination domain write signals
    always @(*) begin
        dst_pwrite_o <= dst_req_write;
        dst_paddr_o <= dst_req_addr;
        dst_pwdata_o <= dst_req_data;
        dst_pstrb_o <= dst_req_strb;
        dst_pprot_o <= dst_req_prot;
    end

endmodule
