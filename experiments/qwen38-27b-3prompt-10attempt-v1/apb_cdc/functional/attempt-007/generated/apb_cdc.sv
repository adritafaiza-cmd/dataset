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
    wire [DATA_WIDTH-1:0] fifo_din;
    wire                   fifo_wr_en;
    wire                   fifo_rd_en;
    wire                   fifo_empty;
    wire                   fifo_full;
    wire [DATA_WIDTH-1:0] fifo_dout;
    wire                   fifo_dout_valid;

    // Source side state
    reg  src_state;
    localparam SRC_IDLE = 1'b0;
    localparam SRC_BUSY = 1'b1;

    // Destination side state
    reg  dst_state;
    localparam DST_IDLE = 1'b0;
    localparam DST_SETUP = 1'b1;
    localparam DST_ACCESS = 1'b2;

    // FIFO implementation (simple synchronous FIFO with async reset)
    // Since LOG_DEPTH is small, we implement a basic FIFO
    // For simplicity, we use a single-entry FIFO when LOG_DEPTH=1
    // General implementation for arbitrary LOG_DEPTH

    // FIFO registers
    reg [DATA_WIDTH-1:0] fifo_mem [0:(1<<LOG_DEPTH)-1];
    reg [LOG_DEPTH:0]    fifo_wr_ptr;
    reg [LOG_DEPTH:0]    fifo_rd_ptr;

    // FIFO control signals
    assign fifo_wr_en = src_state == SRC_IDLE && src_psel_i && src_penable_i && src_pready_o;
    assign fifo_rd_en = dst_state == DST_ACCESS && dst_pready_i;

    // FIFO full/empty
    wire fifo_full  = (fifo_wr_ptr[LOG_DEPTH] != fifo_rd_ptr[LOG_DEPTH]) && 
                      (fifo_wr_ptr[LOG_DEPTH-1:0] == fifo_rd_ptr[LOG_DEPTH-1:0]);
    wire fifo_empty = (fifo_wr_ptr == fifo_rd_ptr);

    assign fifo_din = {src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i};
    assign fifo_dout = fifo_mem[fifo_rd_ptr[LOG_DEPTH-1:0]];
    assign fifo_dout_valid = !fifo_empty;

    // FIFO write
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            fifo_wr_ptr <= 0;
        end else if (fifo_wr_en) begin
            fifo_mem[fifo_wr_ptr[LOG_DEPTH-1:0]] <= fifo_din;
            fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
        end
    end

    // FIFO read
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            fifo_rd_ptr <= 0;
        end else if (fifo_rd_en) begin
            fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
        end
    end

    // Source side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_state <= SRC_IDLE;
            src_pready_o <= 1'b0;
            src_prdata_o <= {DATA_WIDTH{1'b0}};
            src_pslverr_o <= 1'b0;
        end else begin
            case (src_state)
                SRC_IDLE: begin
                    src_pready_o <= 1'b1;
                    if (src_psel_i && src_penable_i) begin
                        src_state <= SRC_BUSY;
                        src_pready_o <= 1'b0;
                    end
                end
                SRC_BUSY: begin
                    src_pready_o <= 1'b0;
                    // Wait for destination to complete and return data
                    // We need to detect when the destination transfer is complete
                    // This is signaled by the FIFO becoming empty after a read
                    // But we need to know when the specific transaction we sent is done
                    // For simplicity with one outstanding transaction, we can use a flag
                    // Actually, let's use a different approach:
                    // When we enter SRC_BUSY, we wait until the FIFO is empty again
                    // (meaning our transaction has been read out and completed)
                    // But we also need to capture the response data
                    // Let's add a response capture mechanism
                    if (fifo_empty) begin
                        src_state <= SRC_IDLE;
                        src_pready_o <= 1'b1;
                    end
                end
                default: begin
                    src_state <= SRC_IDLE;
                    src_pready_o <= 1'b1;
                end
            endcase
        end
    end

    // Capture response data from destination
    reg [DATA_WIDTH-1:0] resp_data;
    reg                  resp_err;
    reg                  resp_valid;

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            resp_data <= {DATA_WIDTH{1'b0}};
            resp_err <= 1'b0;
            resp_valid <= 1'b0;
        end else begin
            if (dst_state == DST_ACCESS && dst_pready_i) begin
                resp_data <= dst_prdata_i;
                resp_err <= dst_pslverr_i;
                resp_valid <= 1'b1;
            end else begin
                resp_valid <= 1'b0;
            end
        end
    end

    // Update source response when destination completes
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_prdata_o <= {DATA_WIDTH{1'b0}};
            src_pslverr_o <= 1'b0;
        end else if (resp_valid) begin
            src_prdata_o <= resp_data;
            src_pslverr_o <= resp_err;
        end
    end

    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_state <= DST_IDLE;
            dst_psel_o <= 1'b0;
            dst_penable_o <= 1'b0;
            dst_pwrite_o <= 1'b0;
            dst_paddr_o <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_o <= {DATA_WIDTH{1'b0}};
            dst_pstrb_o <= {(DATA_WIDTH/8){1'b0}};
            dst_pprot_o <= 3'b000;
        end else begin
            case (dst_state)
                DST_IDLE: begin
                    dst_psel_o <= 1'b0;
                    dst_penable_o <= 1'b0;
                    if (!fifo_empty) begin
                        dst_state <= DST_SETUP;
                        dst_psel_o <= 1'b1;
                        dst_penable_o <= 1'b0;
                        // Decode FIFO data
                        dst_pwrite_o <= fifo_dout[DATA_WIDTH + ADDR_WIDTH + DATA_WIDTH/8 + 3 +: 1];
                        dst_paddr_o <= fifo_dout[DATA_WIDTH + DATA_WIDTH/8 + 3 +: ADDR_WIDTH];
                        dst_pwdata_o <= fifo_dout[DATA_WIDTH/8 + 3 +: DATA_WIDTH];
                        dst_pstrb_o <= fifo_dout[3 +: DATA_WIDTH/8];
                        dst_pprot_o <= fifo_dout[0:2];
                    end
                end
                DST_SETUP: begin
                    dst_psel_o <= 1'b1;
                    dst_penable_o <= 1'b1;
                    dst_state <= DST_ACCESS;
                end
                DST_ACCESS: begin
                    dst_psel_o <= 1'b1;
                    dst_penable_o <= 1'b1;
                    if (dst_pready_i) begin
                        dst_state <= DST_IDLE;
                        dst_psel_o <= 1'b0;
                        dst_penable_o <= 1'b0;
                    end
                end
                default: begin
                    dst_state <= DST_IDLE;
                    dst_psel_o <= 1'b0;
                    dst_penable_o <= 1'b0;
                end
            endcase
        end
    end

endmodule
