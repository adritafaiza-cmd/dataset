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
    localparam AW = LOG_DEPTH;

    // Request FIFO (src -> dst)
    reg [DATA_WIDTH-1:0] req_fifo [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] req_addr_fifo [0:DEPTH-1];
    reg [DATA_WIDTH/8-1:0] req_strb_fifo [0:DEPTH-1];
    reg [2:0] req_prot_fifo [0:DEPTH-1];
    reg req_write_fifo [0:DEPTH-1];
    reg [AW-1:0] req_wr_ptr, req_rd_ptr;
    reg [AW:0] req_count;

    // Response FIFO (dst -> src)
    reg [DATA_WIDTH-1:0] rsp_data_fifo [0:DEPTH-1];
    reg rsp_err_fifo [0:DEPTH-1];
    reg [AW-1:0] rsp_wr_ptr, rsp_rd_ptr;
    reg [AW:0] rsp_count;

    // CDC synchronizers
    reg [AW:0] req_count_sync1, req_count_sync2;
    reg [AW:0] rsp_count_sync1, rsp_count_sync2;

    // Destination side state
    reg dst_psel_r, dst_penable_r, dst_pwrite_r;
    reg [ADDR_WIDTH-1:0] dst_paddr_r;
    reg [DATA_WIDTH-1:0] dst_pwdata_r;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_r;
    reg [2:0] dst_pprot_r;
    reg dst_active;

    // Source side state
    reg src_pready_r, src_pslverr_r;
    reg [DATA_WIDTH-1:0] src_prdata_r;
    reg src_active;

    // Request FIFO full/empty
    wire req_full = (req_count == DEPTH);
    wire req_empty = (req_count == 0);
    wire rsp_full = (rsp_count == DEPTH);
    wire rsp_empty = (rsp_count == 0);

    // Source side: APB protocol
    // src_pready_o is high when we can accept a new request (setup phase)
    // We accept a request when src_psel_i && !src_penable_i && !src_active && !req_full
    // Then we enter enable phase, and complete when response is available

    wire src_setup = src_psel_i && !src_penable_i;
    wire src_enable = src_psel_i && src_penable_i;
    wire src_accept = src_setup && !src_active && !req_full;
    wire src_complete = src_enable && !rsp_empty;

    // Destination side: APB protocol
    // We issue a request when we have data in req_fifo and are not currently active
    wire dst_setup = dst_psel_r && !dst_penable_r;
    wire dst_enable = dst_psel_r && dst_penable_r;
    wire dst_start = !dst_active && !req_empty;
    wire dst_complete = dst_enable && dst_pready_i;

    // Source clock domain
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_pready_r <= 1'b0;
            src_pslverr_r <= 1'b0;
            src_prdata_r <= {DATA_WIDTH{1'b0}};
            src_active <= 1'b0;
            req_wr_ptr <= {AW{1'b0}};
            req_count <= {(AW+1){1'b0}};
        end else begin
            // src_pready_o: high when we can accept a new request
            // We can accept when not active and request FIFO is not full
            src_pready_r <= !src_active && !req_full;

            if (src_accept) begin
                src_active <= 1'b1;
                req_fifo[req_wr_ptr] <= src_pwdata_i;
                req_addr_fifo[req_wr_ptr] <= src_paddr_i;
                req_strb_fifo[req_wr_ptr] <= src_pstrb_i;
                req_prot_fifo[req_wr_ptr] <= src_pprot_i;
                req_write_fifo[req_wr_ptr] <= src_pwrite_i;
                req_wr_ptr <= req_wr_ptr + 1'b1;
                req_count <= req_count + 1'b1;
            end else if (src_complete) begin
                src_active <= 1'b0;
                src_prdata_r <= rsp_data_fifo[rsp_rd_ptr];
                src_pslverr_r <= rsp_err_fifo[rsp_rd_ptr];
                rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
                rsp_count <= rsp_count - 1'b1;
            end
        end
    end

    assign src_pready_o = src_pready_r;
    assign src_prdata_o = src_prdata_r;
    assign src_pslverr_o = src_pslverr_r;

    // Destination clock domain
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_psel_r <= 1'b0;
            dst_penable_r <= 1'b0;
            dst_pwrite_r <= 1'b0;
            dst_paddr_r <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_r <= {DATA_WIDTH{1'b0}};
            dst_pstrb_r <= {(DATA_WIDTH/8){1'b0}};
            dst_pprot_r <= 3'b0;
            dst_active <= 1'b0;
            rsp_wr_ptr <= {AW{1'b0}};
            rsp_count <= {(AW+1){1'b0}};
            req_rd_ptr <= {AW{1'b0}};
        end else begin
            // Start a new transaction if not active and request available
            if (dst_start) begin
                dst_active <= 1'b1;
                dst_psel_r <= 1'b1;
                dst_penable_r <= 1'b0;
                dst_pwrite_r <= req_write_fifo[req_rd_ptr];
                dst_paddr_r <= req_addr_fifo[req_rd_ptr];
                dst_pwdata_r <= req_fifo[req_rd_ptr];
                dst_pstrb_r <= req_strb_fifo[req_rd_ptr];
                dst_pprot_r <= req_prot_fifo[req_rd_ptr];
            end else if (dst_psel_r && !dst_penable_r) begin
                // Move to enable phase
                dst_penable_r <= 1'b1;
            end else if (dst_complete) begin
                // Complete transaction
                dst_active <= 1'b0;
                dst_psel_r <= 1'b0;
                dst_penable_r <= 1'b0;
                // Write response to FIFO
                rsp_data_fifo[rsp_wr_ptr] <= dst_prdata_i;
                rsp_err_fifo[rsp_wr_ptr] <= dst_pslverr_i;
                rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
                rsp_count <= rsp_count + 1'b1;
                // Read from request FIFO
                req_rd_ptr <= req_rd_ptr + 1'b1;
                req_count <= req_count - 1'b1;
            end
        end
    end

    assign dst_psel_o = dst_psel_r;
    assign dst_penable_o = dst_penable_r;
    assign dst_pwrite_o = dst_pwrite_r;
    assign dst_paddr_o = dst_paddr_r;
    assign dst_pwdata_o = dst_pwdata_r;
    assign dst_pstrb_o = dst_pstrb_r;
    assign dst_pprot_o = dst_pprot_r;

    // CDC: synchronize request count from src to dst
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_count_sync1 <= {(AW+1){1'b0}};
            req_count_sync2 <= {(AW+1){1'b0}};
        end else begin
            req_count_sync1 <= req_count;
            req_count_sync2 <= req_count_sync1;
        end
    end

    // CDC: synchronize response count from dst to src
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            rsp_count_sync1 <= {(AW+1){1'b0}};
            rsp_count_sync2 <= {(AW+1){1'b0}};
        end else begin
            rsp_count_sync1 <= rsp_count;
            rsp_count_sync2 <= rsp_count_sync1;
        end
    end

endmodule
