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

    // Source domain state
    reg  [ADDR_WIDTH-1:0]  src_addr_r;
    reg  [DATA_WIDTH-1:0]  src_wdata_r;
    reg  [DATA_WIDTH/8-1:0] src_strb_r;
    reg  [2:0]             src_pprot_r;
    reg                    src_pwrite_r;
    reg                    src_valid_r;
    reg                    src_busy_r;

    // Destination domain state
    reg  [ADDR_WIDTH-1:0]  dst_addr_r;
    reg  [DATA_WIDTH-1:0]  dst_wdata_r;
    reg  [DATA_WIDTH/8-1:0] dst_strb_r;
    reg  [2:0]             dst_pprot_r;
    reg                    dst_pwrite_r;
    reg                    dst_valid_r;
    reg                    dst_busy_r;
    reg                    dst_penable_r;

    // Response path (dst -> src)
    reg  [DATA_WIDTH-1:0]  resp_data_r;
    reg                    resp_err_r;
    reg                    resp_valid_r;

    // Synchronization signals
    // src_valid -> dst: 2-flop sync
    reg src_valid_sync1, src_valid_sync2;
    // dst_done -> src: 2-flop sync
    reg dst_done_sync1, dst_done_sync2;

    // Source domain: capture request on setup->access transition
    wire src_setup = src_psel_i && !src_penable_i;
    wire src_access = src_psel_i && src_penable_i;
    wire src_req = src_setup && !src_busy_r;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_addr_r   <= {ADDR_WIDTH{1'b0}};
            src_wdata_r  <= {DATA_WIDTH{1'b0}};
            src_strb_r   <= {(DATA_WIDTH/8){1'b0}};
            src_pprot_r  <= 3'b000;
            src_pwrite_r <= 1'b0;
            src_valid_r  <= 1'b0;
            src_busy_r   <= 1'b0;
        end else begin
            if (src_req) begin
                src_addr_r   <= src_paddr_i;
                src_wdata_r  <= src_pwdata_i;
                src_strb_r   <= src_pstrb_i;
                src_pprot_r  <= src_pprot_i;
                src_pwrite_r <= src_pwrite_i;
                src_valid_r  <= 1'b1;
                src_busy_r   <= 1'b1;
            end else if (dst_done_sync2) begin
                src_valid_r  <= 1'b0;
                src_busy_r   <= 1'b0;
            end
        end
    end

    // Source outputs
    assign src_pready_o  = !src_busy_r;
    assign src_prdata_o  = resp_data_r;
    assign src_pslverr_o = resp_err_r;

    // Synchronize src_valid to dst domain
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            src_valid_sync1 <= 1'b0;
            src_valid_sync2 <= 1'b0;
        end else begin
            src_valid_sync1 <= src_valid_r;
            src_valid_sync2 <= src_valid_sync1;
        end
    end

    // Synchronize dst_done to src domain
    wire dst_done = dst_busy_r && dst_pready_i;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            dst_done_sync1 <= 1'b0;
            dst_done_sync2 <= 1'b0;
        end else begin
            dst_done_sync1 <= dst_done;
            dst_done_sync2 <= dst_done_sync1;
        end
    end

    // Destination domain: accept request and drive APB
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_addr_r    <= {ADDR_WIDTH{1'b0}};
            dst_wdata_r   <= {DATA_WIDTH{1'b0}};
            dst_strb_r    <= {(DATA_WIDTH/8){1'b0}};
            dst_pprot_r   <= 3'b000;
            dst_pwrite_r  <= 1'b0;
            dst_valid_r   <= 1'b0;
            dst_busy_r    <= 1'b0;
            dst_penable_r <= 1'b0;
        end else begin
            if (!dst_busy_r && src_valid_sync2) begin
                // Accept new request
                dst_addr_r    <= src_addr_r;
                dst_wdata_r   <= src_wdata_r;
                dst_strb_r    <= src_strb_r;
                dst_pprot_r   <= src_pprot_r;
                dst_pwrite_r  <= src_pwrite_r;
                dst_valid_r   <= 1'b1;
                dst_busy_r    <= 1'b1;
                dst_penable_r <= 1'b0;
            end else if (dst_busy_r) begin
                if (!dst_penable_r) begin
                    // Setup phase: move to access
                    dst_penable_r <= 1'b1;
                end else if (dst_pready_i) begin
                    // Access phase complete
                    dst_busy_r    <= 1'b0;
                    dst_valid_r   <= 1'b0;
                    dst_penable_r <= 1'b0;
                end
            end
        end
    end

    // Destination APB outputs
    assign dst_psel_o   = dst_busy_r;
    assign dst_penable_o = dst_penable_r;
    assign dst_pwrite_o = dst_pwrite_r;
    assign dst_paddr_o  = dst_addr_r;
    assign dst_pwdata_o = dst_wdata_r;
    assign dst_pstrb_o  = dst_strb_r;
    assign dst_pprot_o  = dst_pprot_r;

    // Response capture in dst domain
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            resp_data_r  <= {DATA_WIDTH{1'b0}};
            resp_err_r   <= 1'b0;
            resp_valid_r <= 1'b0;
        end else begin
            if (dst_busy_r && dst_penable_r && dst_pready_i) begin
                resp_data_r  <= dst_prdata_i;
                resp_err_r   <= dst_pslverr_i;
                resp_valid_r <= 1'b1;
            end else begin
                resp_valid_r <= 1'b0;
            end
        end
    end

endmodule
