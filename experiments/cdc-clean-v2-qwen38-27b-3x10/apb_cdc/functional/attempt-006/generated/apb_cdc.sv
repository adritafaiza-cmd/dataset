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

    localparam STRB_WIDTH = DATA_WIDTH/8;
    localparam FIFO_DEPTH = 1 << LOG_DEPTH;
    localparam PTR_WIDTH  = LOG_DEPTH;

    // Source-side state
    reg  src_state;
    localparam SRC_IDLE  = 1'b0;
    localparam SRC_WAIT  = 1'b1;

    // Destination-side state
    reg  dst_state;
    localparam DST_IDLE  = 1'b0;
    localparam DST_SETUP = 1'b1;
    localparam DST_ACC   = 1'b10;

    // FIFO pointers
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [PTR_WIDTH-1:0] dst_rd_ptr;

    // FIFO storage
    reg [DATA_WIDTH-1:0] fifo_data [0:FIFO_DEPTH-1];
    reg [ADDR_WIDTH-1:0] fifo_addr [0:FIFO_DEPTH-1];
    reg [STRB_WIDTH-1:0] fifo_strb [0:FIFO_DEPTH-1];
    reg [2:0]            fifo_prot [0:FIFO_DEPTH-1];
    reg                  fifo_write [0:FIFO_DEPTH-1];

    // Synchronization signals
    reg  src_wr_valid;
    reg  dst_rd_valid;
    reg  src_done_sync1, src_done_sync2;
    reg  dst_req_sync1, dst_req_sync2;

    // Destination output registers
    reg  dst_psel_r;
    reg  dst_penable_r;
    reg  dst_pwrite_r;
    reg [ADDR_WIDTH-1:0] dst_paddr_r;
    reg [DATA_WIDTH-1:0] dst_pwdata_r;
    reg [STRB_WIDTH-1:0] dst_pstrb_r;
    reg [2:0]            dst_pprot_r;

    // Source output registers
    reg  src_pready_r;
    reg [DATA_WIDTH-1:0] src_prdata_r;
    reg  src_pslverr_r;

    // FIFO full/empty
    wire fifo_full  = (src_wr_ptr == dst_rd_ptr) && src_wr_valid;
    wire fifo_empty = (src_wr_ptr == dst_rd_ptr) && !src_wr_valid;

    // Source clock domain
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_state    <= SRC_IDLE;
            src_wr_ptr   <= {PTR_WIDTH{1'b0}};
            src_pready_r <= 1'b0;
            src_prdata_r <= {DATA_WIDTH{1'b0}};
            src_pslverr_r<= 1'b0;
            src_wr_valid <= 1'b0;
            src_done_sync1 <= 1'b0;
            src_done_sync2 <= 1'b0;
        end else begin
            // Synchronize dst completion signal
            src_done_sync1 <= dst_req_sync2;
            src_done_sync2 <= src_done_sync1;

            case (src_state)
                SRC_IDLE: begin
                    src_pready_r <= 1'b0;
                    if (src_psel_i && !src_penable_i && !fifo_full) begin
                        // Setup phase: capture request
                        src_state    <= SRC_WAIT;
                        src_pready_r <= 1'b1;
                        // Write to FIFO
                        fifo_data[src_wr_ptr]  <= src_pwdata_i;
                        fifo_addr[src_wr_ptr]  <= src_paddr_i;
                        fifo_strb[src_wr_ptr]  <= src_pstrb_i;
                        fifo_prot[src_wr_ptr]  <= src_pprot_i;
                        fifo_write[src_wr_ptr] <= src_pwrite_i;
                        src_wr_ptr   <= src_wr_ptr + 1'b1;
                        src_wr_valid <= 1'b1;
                    end
                end
                SRC_WAIT: begin
                    src_pready_r <= 1'b0;
                    if (src_psel_i && src_penable_i) begin
                        // Access phase: wait for dst completion
                        if (src_done_sync2) begin
                            src_state <= SRC_IDLE;
                        end
                    end
                end
                default: begin
                    src_state <= SRC_IDLE;
                end
            endcase
        end
    end

    // Destination clock domain
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_state     <= DST_IDLE;
            dst_rd_ptr    <= {PTR_WIDTH{1'b0}};
            dst_psel_r    <= 1'b0;
            dst_penable_r <= 1'b0;
            dst_pwrite_r  <= 1'b0;
            dst_paddr_r   <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_r  <= {DATA_WIDTH{1'b0}};
            dst_pstrb_r   <= {STRB_WIDTH{1'b0}};
            dst_pprot_r   <= 3'b0;
            dst_rd_valid  <= 1'b0;
            dst_req_sync1 <= 1'b0;
            dst_req_sync2 <= 1'b0;
        end else begin
            // Synchronize src write valid
            dst_req_sync1 <= src_wr_valid;
            dst_req_sync2 <= dst_req_sync1;

            case (dst_state)
                DST_IDLE: begin
                    dst_psel_r    <= 1'b0;
                    dst_penable_r <= 1'b0;
                    if (dst_req_sync2 && !fifo_empty) begin
                        // Read from FIFO
                        dst_state     <= DST_SETUP;
                        dst_psel_r    <= 1'b1;
                        dst_penable_r <= 1'b0;
                        dst_pwrite_r  <= fifo_write[dst_rd_ptr];
                        dst_paddr_r   <= fifo_addr[dst_rd_ptr];
                        dst_pwdata_r  <= fifo_data[dst_rd_ptr];
                        dst_pstrb_r   <= fifo_strb[dst_rd_ptr];
                        dst_pprot_r   <= fifo_prot[dst_rd_ptr];
                        dst_rd_ptr    <= dst_rd_ptr + 1'b1;
                        dst_rd_valid  <= 1'b0;
                    end
                end
                DST_SETUP: begin
                    dst_psel_r    <= 1'b1;
                    dst_penable_r <= 1'b1;
                    dst_state     <= DST_ACC;
                end
                DST_ACC: begin
                    dst_psel_r    <= 1'b1;
                    dst_penable_r <= 1'b1;
                    if (dst_pready_i) begin
                        dst_state     <= DST_IDLE;
                        dst_psel_r    <= 1'b0;
                        dst_penable_r <= 1'b0;
                        dst_rd_valid  <= 1'b1;
                    end
                end
                default: begin
                    dst_state     <= DST_IDLE;
                    dst_psel_r    <= 1'b0;
                    dst_penable_r <= 1'b0;
                end
            endcase
        end
    end

    // Source outputs
    assign src_pready_o  = src_pready_r;
    assign src_prdata_o  = src_prdata_r;
    assign src_pslverr_o = src_pslverr_r;

    // Destination outputs
    assign dst_psel_o    = dst_psel_r;
    assign dst_penable_o = dst_penable_r;
    assign dst_pwrite_o  = dst_pwrite_r;
    assign dst_paddr_o   = dst_paddr_r;
    assign dst_pwdata_o  = dst_pwdata_r;
    assign dst_pstrb_o   = dst_pstrb_r;
    assign dst_pprot_o   = dst_pprot_r;

    // Capture read data and error back to source
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_prdata_r  <= {DATA_WIDTH{1'b0}};
            src_pslverr_r <= 1'b0;
        end else begin
            if (dst_rd_valid) begin
                src_prdata_r  <= dst_prdata_i;
                src_pslverr_r <= dst_pslverr_i;
            end
        end
    end

    // Synchronize dst_rd_valid to source domain
    reg dst_rd_valid_sync1, dst_rd_valid_sync2;
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            dst_rd_valid_sync1 <= 1'b0;
            dst_rd_valid_sync2 <= 1'b0;
        end else begin
            dst_rd_valid_sync1 <= dst_rd_valid;
            dst_rd_valid_sync2 <= dst_rd_valid_sync1;
        end
    end

    // Use synchronized valid to update source outputs
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_prdata_r  <= {DATA_WIDTH{1'b0}};
            src_pslverr_r <= 1'b0;
        end else begin
            if (dst_rd_valid_sync2) begin
                src_prdata_r  <= dst_prdata_i;
                src_pslverr_r <= dst_pslverr_i;
            end
        end
    end

endmodule
