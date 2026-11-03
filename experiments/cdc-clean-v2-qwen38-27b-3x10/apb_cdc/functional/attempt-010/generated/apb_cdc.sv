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
    localparam PTR_W = LOG_DEPTH;

    // Source side state
    reg src_idle;
    reg src_access;
    reg src_wait_dst;

    // Destination side state
    reg dst_idle;
    reg dst_setup;
    reg dst_access;

    // FIFO pointers
    reg [PTR_W-1:0] src_wr_ptr;
    reg [PTR_W-1:0] dst_rd_ptr;

    // FIFO data storage
    reg [DATA_WIDTH-1:0] fifo_data [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] fifo_addr [0:DEPTH-1];
    reg [DATA_WIDTH/8-1:0] fifo_strb [0:DEPTH-1];
    reg [2:0] fifo_prot [0:DEPTH-1];
    reg fifo_write [0:DEPTH-1];

    // FIFO full/empty
    wire src_fifo_full;
    wire dst_fifo_empty;

    assign src_fifo_full = (src_wr_ptr == dst_rd_ptr) && src_wait_dst;
    assign dst_fifo_empty = (src_wr_ptr == dst_rd_ptr) && !src_wait_dst;

    // Source side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_idle <= 1'b1;
            src_access <= 1'b0;
            src_wait_dst <= 1'b0;
            src_wr_ptr <= {PTR_W{1'b0}};
        end else begin
            if (src_idle) begin
                if (src_psel_i && !src_fifo_full) begin
                    src_idle <= 1'b0;
                    src_access <= 1'b1;
                    src_wait_dst <= 1'b1;
                    // Store request in FIFO
                    fifo_data[src_wr_ptr] <= src_pwdata_i;
                    fifo_addr[src_wr_ptr] <= src_paddr_i;
                    fifo_strb[src_wr_ptr] <= src_pstrb_i;
                    fifo_prot[src_wr_ptr] <= src_pprot_i;
                    fifo_write[src_wr_ptr] <= src_pwrite_i;
                    src_wr_ptr <= src_wr_ptr + 1'b1;
                end
            end else if (src_access) begin
                if (src_penable_i && src_pready_o) begin
                    src_access <= 1'b0;
                    src_idle <= 1'b1;
                    src_wait_dst <= 1'b0;
                end
            end
        end
    end

    // Source ready: assert when in access phase and destination has completed
    assign src_pready_o = src_access && !src_wait_dst;

    // Source read data and error: from destination response
    assign src_prdata_o = dst_prdata_i;
    assign src_pslverr_o = dst_pslverr_i;

    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_idle <= 1'b1;
            dst_setup <= 1'b0;
            dst_access <= 1'b0;
            dst_rd_ptr <= {PTR_W{1'b0}};
        end else begin
            if (dst_idle) begin
                if (!dst_fifo_empty) begin
                    dst_idle <= 1'b0;
                    dst_setup <= 1'b1;
                end
            end else if (dst_setup) begin
                dst_setup <= 1'b0;
                dst_access <= 1'b1;
            end else if (dst_access) begin
                if (dst_pready_i) begin
                    dst_access <= 1'b0;
                    dst_idle <= 1'b1;
                    dst_rd_ptr <= dst_rd_ptr + 1'b1;
                end
            end
        end
    end

    // Destination output signals
    assign dst_psel_o = dst_setup || dst_access;
    assign dst_penable_o = dst_access;
    assign dst_pwrite_o = fifo_write[dst_rd_ptr];
    assign dst_paddr_o = fifo_addr[dst_rd_ptr];
    assign dst_pwdata_o = fifo_data[dst_rd_ptr];
    assign dst_pstrb_o = fifo_strb[dst_rd_ptr];
    assign dst_pprot_o = fifo_prot[dst_rd_ptr];

endmodule
