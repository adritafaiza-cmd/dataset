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
    wire [ADDR_WIDTH-1:0]    req_addr;
    wire [DATA_WIDTH-1:0]    req_wdata;
    wire [DATA_WIDTH/8-1:0]  req_strb;
    wire [2:0]               req_prot;
    wire                     req_write;
    wire                     req_valid;
    wire                     req_ready;

    wire [DATA_WIDTH-1:0]    rsp_data;
    wire                     rsp_err;
    wire                     rsp_valid;
    wire                     rsp_ready;

    // Source side state machine
    // States: IDLE, SETUP, ACCESS
    localparam SRC_IDLE   = 2'd0;
    localparam SRC_SETUP  = 2'd1;
    localparam SRC_ACCESS = 2'd2;

    reg [1:0] src_state;
    reg [ADDR_WIDTH-1:0]    src_addr_reg;
    reg [DATA_WIDTH-1:0]    src_wdata_reg;
    reg [DATA_WIDTH/8-1:0]  src_strb_reg;
    reg [2:0]               src_prot_reg;
    reg                     src_write_reg;
    reg [DATA_WIDTH-1:0]    src_rdata_reg;
    reg                     src_err_reg;

    assign src_pready_o = (src_state == SRC_ACCESS) && rsp_valid;
    assign src_prdata_o = src_rdata_reg;
    assign src_pslverr_o = src_err_reg;

    // Request valid/ready for the FIFO
    assign req_valid = (src_state == SRC_SETUP) && src_psel_i && src_penable_i;
    assign req_addr  = src_addr_reg;
    assign req_wdata = src_wdata_reg;
    assign req_strb  = src_strb_reg;
    assign req_prot  = src_prot_reg;
    assign req_write = src_write_reg;

    // Response ready from source side
    assign rsp_ready = (src_state == SRC_ACCESS);

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_state     <= SRC_IDLE;
            src_addr_reg  <= {ADDR_WIDTH{1'b0}};
            src_wdata_reg <= {DATA_WIDTH{1'b0}};
            src_strb_reg  <= {(DATA_WIDTH/8){1'b0}};
            src_prot_reg  <= 3'b000;
            src_write_reg <= 1'b0;
            src_rdata_reg <= {DATA_WIDTH{1'b0}};
            src_err_reg   <= 1'b0;
        end else begin
            case (src_state)
                SRC_IDLE: begin
                    if (src_psel_i) begin
                        src_addr_reg  <= src_paddr_i;
                        src_wdata_reg <= src_pwdata_i;
                        src_strb_reg  <= src_pstrb_i;
                        src_prot_reg  <= src_pprot_i;
                        src_write_reg <= src_pwrite_i;
                        src_state     <= SRC_SETUP;
                    end
                end
                SRC_SETUP: begin
                    if (src_psel_i && src_penable_i) begin
                        src_state <= SRC_ACCESS;
                    end
                end
                SRC_ACCESS: begin
                    if (rsp_valid) begin
                        src_rdata_reg <= rsp_data;
                        src_err_reg   <= rsp_err;
                        src_state     <= SRC_IDLE;
                    end
                end
                default: src_state <= SRC_IDLE;
            endcase
        end
    end

    // Destination side state machine
    // States: IDLE, SETUP, ACCESS
    localparam DST_IDLE   = 2'd0;
    localparam DST_SETUP  = 2'd1;
    localparam DST_ACCESS = 2'd2;

    reg [1:0] dst_state;
    reg [ADDR_WIDTH-1:0]    dst_addr_reg;
    reg [DATA_WIDTH-1:0]    dst_wdata_reg;
    reg [DATA_WIDTH/8-1:0]  dst_strb_reg;
    reg [2:0]               dst_prot_reg;
    reg                     dst_write_reg;
    reg [DATA_WIDTH-1:0]    dst_rdata_reg;
    reg                     dst_err_reg;

    assign dst_psel_o    = (dst_state == DST_SETUP) || (dst_state == DST_ACCESS);
    assign dst_penable_o = (dst_state == DST_ACCESS);
    assign dst_pwrite_o  = dst_write_reg;
    assign dst_paddr_o   = dst_addr_reg;
    assign dst_pwdata_o  = dst_wdata_reg;
    assign dst_pstrb_o   = dst_strb_reg;
    assign dst_pprot_o   = dst_prot_reg;

    // Response valid/ready for the FIFO
    assign rsp_valid = (dst_state == DST_ACCESS) && dst_pready_i;
    assign rsp_data  = dst_rdata_reg;
    assign rsp_err   = dst_err_reg;

    // Request ready from destination side
    assign req_ready = (dst_state == DST_IDLE);

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_state     <= DST_IDLE;
            dst_addr_reg  <= {ADDR_WIDTH{1'b0}};
            dst_wdata_reg <= {DATA_WIDTH{1'b0}};
            dst_strb_reg  <= {(DATA_WIDTH/8){1'b0}};
            dst_prot_reg  <= 3'b000;
            dst_write_reg <= 1'b0;
            dst_rdata_reg <= {DATA_WIDTH{1'b0}};
            dst_err_reg   <= 1'b0;
        end else begin
            case (dst_state)
                DST_IDLE: begin
                    if (req_valid) begin
                        dst_addr_reg  <= req_addr;
                        dst_wdata_reg <= req_wdata;
                        dst_strb_reg  <= req_strb;
                        dst_prot_reg  <= req_prot;
                        dst_write_reg <= req_write;
                        dst_state     <= DST_SETUP;
                    end
                end
                DST_SETUP: begin
                    dst_state <= DST_ACCESS;
                end
                DST_ACCESS: begin
                    if (dst_pready_i) begin
                        dst_rdata_reg <= dst_prdata_i;
                        dst_err_reg   <= dst_pslverr_i;
                        dst_state     <= DST_IDLE;
                    end
                end
                default: dst_state <= DST_IDLE;
            endcase
        end
    end

    // FIFO for request (src -> dst)
    // Simple synchronous FIFO with async reset per clock domain
    // Using a simple shift register based FIFO since LOG_DEPTH is small

    // Request FIFO
    reg [ADDR_WIDTH-1:0]    req_fifo_addr [0:(1<<LOG_DEPTH)-1];
    reg [DATA_WIDTH-1:0]    req_fifo_wdata [0:(1<<LOG_DEPTH)-1];
    reg [DATA_WIDTH/8-1:0]  req_fifo_strb [0:(1<<LOG_DEPTH)-1];
    reg [2:0]               req_fifo_prot [0:(1<<LOG_DEPTH)-1];
    reg                     req_fifo_write [0:(1<<LOG_DEPTH)-1];
    reg [LOG_DEPTH:0]       req_fifo_wr_ptr;
    reg [LOG_DEPTH:0]       req_fifo_rd_ptr;

    // Response FIFO
    reg [DATA_WIDTH-1:0]    rsp_fifo_data [0:(1<<LOG_DEPTH)-1];
    reg                     rsp_fifo_err [0:(1<<LOG_DEPTH)-1];
    reg [LOG_DEPTH:0]       rsp_fifo_wr_ptr;
    reg [LOG_DEPTH:0]       rsp_fifo_rd_ptr;

    // Request FIFO write (src clock domain)
    wire req_fifo_full = (req_fifo_wr_ptr[LOG_DEPTH] != req_fifo_rd_ptr[LOG_DEPTH]) && 
                         (req_fifo_wr_ptr[LOG_DEPTH-1:0] == req_fifo_rd_ptr[LOG_DEPTH-1:0]);
    wire req_fifo_empty = (req_fifo_wr_ptr == req_fifo_rd_ptr);

    // We need to handle the FIFO pointers carefully across clock domains.
    // For simplicity and correctness with small LOG_DEPTH, we'll use a simple approach:
    // The source writes to the FIFO when it has a valid request and the FIFO is not full.
    // The destination reads from the FIFO when it is idle and the FIFO is not empty.

    // Actually, let's use a simpler approach: since we only have one outstanding transaction,
    // we can use a simple handshake with a single entry buffer.

    // Let me redesign with a simpler single-entry buffer approach.

    // Request buffer (src -> dst)
    reg [ADDR_WIDTH-1:0]    req_buf_addr;
    reg [DATA_WIDTH-1:0]    req_buf_wdata;
    reg [DATA_WIDTH/8-1:0]  req_buf_strb;
    reg [2:0]               req_buf_prot;
    reg                     req_buf_write;
    reg                     req_buf_valid_src;  // Valid in src domain
    reg                     req_buf_valid_dst;  // Valid in dst domain
    reg                     req_buf_ready_src;  // Ready in src domain
    reg                     req_buf_ready_dst;  // Ready in dst domain

    // Response buffer (dst -> src)
    reg [DATA_WIDTH-1:0]    rsp_buf_data;
    reg                     rsp_buf_err;
    reg                     rsp_buf_valid_dst;  // Valid in dst domain
    reg                     rsp_buf_valid_src;  // Valid in src domain
    reg                     rsp_buf_ready_dst;  // Ready in dst domain
    reg                     rsp_buf_ready_src;  // Ready in src domain

    // Source side: write to request buffer
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_buf_valid_src <= 1'b0;
            req_buf_ready_src <= 1'b1;
        end else begin
            if (req_buf_valid_src && req_buf_ready_src) begin
                req_buf_valid_src <= 1'b0;
            end
            if (!req_buf_valid_src && req_valid) begin
                req_buf_addr    <= req_addr;
                req_buf_wdata   <= req_wdata;
                req_buf_strb    <= req_strb;
                req_buf_prot    <= req_prot;
                req_buf_write   <= req_write;
                req_buf_valid_src <= 1'b1;
            end
            req_buf_ready_src <= req_buf_ready_dst;
        end
    end

    // Destination side: read from request buffer
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_buf_valid_dst <= 1'b0;
            req_buf_ready_dst <= 1'b1;
        end else begin
            if (req_buf_valid_dst && req_buf_ready_dst) begin
                req_buf_valid_dst <= 1'b0;
            end
            if (!req_buf_valid_dst && req_buf_valid_src) begin
                req_buf_addr    <= req_buf_addr;
                req_buf_wdata   <= req_buf_wdata;
                req_buf_strb    <= req_buf_strb;
                req_buf_prot    <= req_buf_prot;
                req_buf_write   <= req_buf_write;
                req_buf_valid_dst <= 1'b1;
            end
            req_buf_ready_dst <= req_buf_ready_src;
        end
    end

    // Update the request signals from the buffer
    assign req_addr  = req_buf_addr;
    assign req_wdata = req_buf_wdata;
    assign req_strb  = req_buf_strb;
    assign req_prot  = req_buf_prot;
    assign req_write = req_buf_write;
    assign req_valid = req_buf_valid_dst;
    assign req_ready = req_buf_ready_dst;

    // Destination side: write to response buffer
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            rsp_buf_valid_dst <= 1'b0;
            rsp_buf_ready_dst <= 1'b1;
        end else begin
            if (rsp_buf_valid_dst && rsp_buf_ready_dst) begin
                rsp_buf_valid_dst <= 1'b0;
            end
            if (!rsp_buf_valid_dst && rsp_valid) begin
                rsp_buf_data    <= rsp_data;
                rsp_buf_err     <= rsp_err;
                rsp_buf_valid_dst <= 1'b1;
            end
            rsp_buf_ready_dst <= rsp_buf_ready_src;
        end
    end

    // Source side: read from response buffer
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            rsp_buf_valid_src <= 1'b0;
            rsp_buf_ready_src <= 1'b1;
        end else begin
            if (rsp_buf_valid_src && rsp_buf_ready_src) begin
                rsp_buf_valid_src <= 1'b0;
            end
            if (!rsp_buf_valid_src && rsp_buf_valid_dst) begin
                rsp_buf_data    <= rsp_buf_data;
                rsp_buf_err     <= rsp_buf_err;
                rsp_buf_valid_src <= 1'b1;
            end
            rsp_buf_ready_src <= rsp_buf_ready_dst;
        end
    end

    // Update the response signals from the buffer
    assign rsp_data  = rsp_buf_data;
    assign rsp_err   = rsp_buf_err;
    assign rsp_valid = rsp_buf_valid_src;
    assign rsp_ready = rsp_buf_ready_src;

endmodule
